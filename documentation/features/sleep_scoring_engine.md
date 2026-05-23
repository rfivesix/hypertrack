# Sleep Health Score (SHS v3.5) Architecture

This document defines the production-grade mathematical architecture of the **Sleep Health Score v3.5 (SHS v3.5)** engine. Moving away from rigid, binary hard-cap cutoffs (SHS v3), version 3.5 implements a continuous, multi-domain soft-cap multiplier system that dynamically degrades the composite sleep score based on the single worst-performing biological bottleneck.

---

## 1. Engine Overview

The Sleep Health Score ($SHS$) is constructed in two sequential phases:
1. **Weighted Base Aggregation**: A top-level normalized weighted average of 5 primary clinical domains.
2. **Dynamic Soft-Cap Penalty**: Multiplicative scaling using the single most severe biological penalty (bottleneck).

### Top-Level Weighted Aggregation

The base score $SHS_{base} \in [0, 100]$ aggregates 5 dimensions according to specific clinical weight allocations:

*   **Sleep Duration ($D$)** - **30%**: Evaluates overall sleep volume against homeostatic sleep need.
*   **Sleep Continuity ($C$)** - **20%**: Assesses fragmentation, divided equally ($50/50$) between Sleep Efficiency ($C_{SE}$) and Wake After Sleep Onset ($C_{WASO}$).
*   **Sleep Stage Depth / Architecture ($A$)** - **25%**: Sleep architecture quality, evaluating absolute minutes of Deep (N3) and REM sleep, with high light sleep (N1) penalties.
*   **Circadian Timing ($T_{circ}$)** - **15%**: Synchronization of sleep onset/mid-point with the natural light-dark cycle.
*   **Sleep Regularity ($R$)** - **10%**: Day-to-day stability of the sleep schedule using a rolling mid-sleep standard deviation.

The base aggregation is dynamically renormalized to handle missing or incomplete data streams, ensuring the score remains reliable:

$$SHS_{base} = \left( \frac{\sum_{i \in \mathcal{A}} w_i \cdot S_i}{\sum_{i \in \mathcal{A}} w_i} \right) \cdot 100$$

Where:
*   $\mathcal{A}$ is the set of actively available dimensions.
*   $w_i$ is the weight coefficient for domain $i$ (e.g., $w_D = 0.30, w_C = 0.20, \dots$).
*   $S_i \in [0, 1]$ is the continuous normalized score of domain $i$.

### Final Score Degradation

The final Sleep Health Score ($SHS_{final}$) applies the continuous `dynamicMultiplier` to the base score:

$$SHS_{final} = \text{clamp}\Big( SHS_{base} \cdot \text{dynamicMultiplier}, \; 0.0, \; 100.0 \Big)$$

---

## 2. Dimension Specifications

### 2.1 Sleep Duration ($D$)
Calculated from total sleep time in hours ($h = \text{durationMinutes} / 60$). It utilizes a Gaussian distribution centered around the $7.0 \text{--} 9.0$ hours anabolic plateau. Severe short sleep ($<5.0\text{h}$) or extreme hypersomnia ($>10.5\text{h}$) results in a score of $0.0$.

$$S_D(h) = \begin{cases} 
      0.0 & \text{if } h < 5.0 \text{ or } h > 10.5 \\
      1.0 & \text{if } 7.0 \le h \le 9.0 \\
      \exp\left( -\frac{(h - 7.0)^2}{2 \cdot 1.0^2} \right) & \text{if } 5.0 \le h < 7.0 \\
      \exp\left( -\frac{(h - 9.0)^2}{2 \cdot 1.0^2} \right) & \text{if } 9.0 < h \le 10.5
   \end{cases}$$

### 2.2 Sleep Continuity ($C$)
Composed of two complementary sub-metrics, combined as $S_C = 0.5 \cdot S_{SE} + 0.5 \cdot S_{WASO}$ (renormalized if only one sub-metric is active).

#### Sleep Efficiency ($S_{SE}$)
Uses a steep logistic sigmoid curve centered at a critical threshold of $90\%$ efficiency.

$$S_{SE}(SE) = \frac{1}{1 + \exp\Big( -50.0 \cdot (SE - 0.90) \Big)}$$

Where $SE = \text{sleepEfficiencyPct} / 100.0$.

#### Wake After Sleep Onset ($S_{WASO}$)
Calculated using a quadratic rational penalty decay function starting after a grace period of $20$ minutes.

$$S_{WASO}(W) = \frac{1}{1 + \left( \frac{W_{pen}}{30} \right)^2}$$

Where $W_{pen} = \max(W - 20.0, \; 0.0)$ and $W$ is the WASO duration in minutes.

### 2.3 Sleep Stage Depth / Architecture ($A$)
Evaluates the physiological structure of sleep stages based on absolute minutes of restorative stages, penalized by excessive light sleep.

#### Deep Sleep / N3 ($A_{N3}$)
A joint linear growth and Gaussian decay curve peaking at $90$ minutes:

$$A_{N3}(t_{N3}) = \min\left( 1.0, \; \frac{t_{N3}}{90.0} \right) \cdot \exp\left( -\frac{(t_{N3} - 90.0)^2}{2 \cdot 40.0^2} \right)$$

#### REM Sleep ($A_{REM}$)
Similar joint linear-Gaussian curve optimized for a peak at $100$ minutes:

$$A_{REM}(t_{REM}) = \min\left( 1.0, \; \frac{t_{REM}}{100.0} \right) \cdot \exp\left( -\frac{(t_{REM} - 100.0)^2}{2 \cdot 40.0^2} \right)$$

#### Light Sleep Penalty ($P_{N1}$)
Triggers an exponential penalty decay when light sleep exceeds $60\%$ of total sleep time.

$$P_{N1}(p_{N1}) = \begin{cases}
      1.0 & \text{if } p_{N1} \le 60.0 \\
      \exp\left( -\frac{(p_{N1} - 60.0)^2}{2 \cdot 10.0^2} \right) & \text{if } p_{N1} > 60.0
   \end{cases}$$

Where $p_{N1}$ is the percentage of light sleep.

#### Combined Architecture Score
$$S_A = \text{clamp}\Big( (0.45 \cdot A_{N3} + 0.45 \cdot A_{REM}) \cdot P_{N1} + 0.10, \; 0.0, \; 1.0 \Big)$$

### 2.4 Circadian Timing ($T_{circ}$)
Assesses circadian alignment using the mid-sleep clock hour ($MS$), computed to handle midnight crossings cleanly. The base score is a Gaussian curve centered at $03:30$ ($MS = 3.5$). An exponential late-phase penalty applies if mid-sleep occurs past $05:30$ ($MS > 5.5$).

$$S_{circ, base}(MS) = \exp\left( -\frac{(MS - 3.5)^2}{2 \cdot 1.0^2} \right)$$

$$S_{circ}(MS) = \begin{cases}
      S_{circ, base}(MS) \cdot \exp\left( -\frac{(MS - 5.5)^2}{2 \cdot 0.5^2} \right) & \text{if } MS > 5.5 \\
      S_{circ, base}(MS) & \text{if } MS \le 5.5
   \end{cases}$$

### 2.5 Sleep Regularity ($R$)
Evaluates schedule stability using the standard deviation of mid-sleep clock hours ($SD_{mid}$) over a 7-14 day rolling window. Uses an inverse-quadratic decay function.

$$S_R(SD_{mid}) = \frac{1}{1 + (SD_{mid} / 1.0)^2}$$

---

## 3. The Soft-Cap Multiplier Mechanics

To prevent high scores when a critical physiological sleep domain is dangerously compromised, SHS v3.5 implements a dynamic, continuous soft-cap multiplier. 

The engine computes 4 individual potential multiplier penalties and selects the single lowest (the bottleneck):

$$\text{dynamicMultiplier} = \min\Big( M_{REM}, \; M_{N3}, \; M_{TST}, \; M_{circ} \Big)$$

### Linear Mapping Function

Each multiplier is mapped continuously using the bounded linear interpolation helper function:

$$\_linear(v, x_{min}, x_{max}, y_{min}, y_{max}) = y_{min} + \left( \frac{\text{clamp}(v, x_{min}, x_{max}) - x_{min}}{x_{max} - x_{min}} \right) \cdot (y_{max} - y_{min})$$

Where $\text{clamp}(v, x_{min}, x_{max})$ constrains the input parameter $v$ to the range defined by $[x_{min}, x_{max}]$.

*Note: The function natively supports decreasing mappings where $x_{min} > x_{max}$, allowing higher input values to output lower multipliers.*

### Multiplier Threshold Formulations

#### 1. REM Sleep Multiplier ($M_{REM}$)
Degrades score if REM duration ($t_{REM}$) falls below $60$ minutes:

$$M_{REM} = \_linear(t_{REM}, \; 40.0, \; 60.0, \; 0.65, \; 1.0)$$

#### 2. Deep Sleep (N3) Multiplier ($M_{N3}$)
Degrades score if N3 duration ($t_{N3}$) falls below $70$ minutes:

$$M_{N3} = \_linear(t_{N3}, \; 40.0, \; 70.0, \; 0.60, \; 1.0)$$

#### 3. Total Sleep Time (TST) Multiplier ($M_{TST}$)
Degrades score if sleep volume ($h$ hours) falls below $6.5$ hours:

$$M_{TST} = \_linear(h, \; 5.0, \; 6.5, \; 0.50, \; 1.0)$$

#### 4. Circadian Timing Multiplier ($M_{circ}$)
Degrades score if the mid-sleep clock hour ($MS$) shifts later than $05:30$ ($5.5$):

$$M_{circ} = \_linear(MS, \; 7.5, \; 5.5, \; 0.55, \; 1.0)$$

---

## 4. The Boundary Table

The following table summarizes the boundary conditions of the continuous soft-cap multiplier system:

| Affected Domain | Input Metric ($v$) | Optimal Zone ($M = 1.0$) | Pathological / Max Penalty Zone | Multiplier Range | Clinical biological rationale |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **REM Sleep ($M_{REM}$)** | REM Minutes ($t_{REM}$) | $\ge 60.0\text{ min}$ | $\le 40.0\text{ min}$ | $1.0 \rightarrow 0.65$ | REM deficiency impairs emotional regulation, memory consolidation, and neuronal repair. |
| **Deep Sleep ($M_{N3}$)** | N3 Minutes ($t_{N3}$) | $\ge 70.0\text{ min}$ | $\le 40.0\text{ min}$ | $1.0 \rightarrow 0.60$ | Deep N3 sleep is the primary driver of physical recovery, growth hormone release, and tissue repair. |
| **Sleep Duration ($M_{TST}$)** | TST Hours ($h$) | $\ge 6.5\text{ hours}$ | $\le 5.0\text{ hours}$ | $1.0 \rightarrow 0.50$ | Insufficient sleep duration restricts core metabolic recovery and disrupts homeostatic anabolic processes. |
| **Circadian Timing ($M_{circ}$)** | Mid-Sleep Clock ($MS$) | $\le 05:30\text{ (5.5)}$ | $\ge 07:30\text{ (7.5)}$ | $1.0 \rightarrow 0.55$ | Late phase delay (sleep against the circadian clock) severely reduces insulin sensitivity and sleep architecture quality. |
