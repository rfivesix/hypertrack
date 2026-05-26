# Clinical Muscle Recovery & Fatigue Modeling Heuristic

The **Muscle Recovery Model** in Train Libre is a piecewise linear decay heuristic designed to estimate readiness scores *R*(*t*) for individual muscle groups. It accounts for non-linear recovery curves, set-weighting based on primary vs. secondary involvement, and failure-induced baseline extensions.

---

## 1. Readiness Score Equation *R*(*t*)

The readiness of a muscle group at time *t* (hours since last load) is modeled as a normalized value between 0.0 (fully fatigued) and 1.0 (fully recovered).

$$R(t) = \text{clamp}\left( \frac{t - \text{offset}}{\text{window}} , 0.0, 1.0 \right)$$

### Recovery Windows
The time window required for full recovery is dynamic based on session volume and intensity:
- **Baseline Window**: 48 hours for standard high-intensity sets.
- **Failure Penalty**: If sets are performed to failure (*RIR* = 0), the baseline is extended by +24 hours.
- **Volume Scaling**: The window expands linearly as cumulative weekly volume increases beyond metabolic clearing thresholds.

---

## 2. Equivalent Set Weighting

To accurately map compound movements to multiple muscle groups, Train Libre uses a weighted contribution ratio:

- **Primary Muscle**: 1.0 equivalent set. (e.g., Chest in a Bench Press).
- **Secondary Muscle**: 0.3 - 0.5 equivalent set. (e.g., Triceps in a Bench Press).

$$V_{total} = \sum (\text{Sets} \cdot \text{Weighting} \cdot \text{IntensityFactor})$$

---

## 3. Failure-Induced Fatigue Extensions

The proximity to failure (Reps-In-Reserve, *RIR*) is the strongest predictor of central and peripheral fatigue duration. Train Libre applies a discrete penalty to the recovery timeline:

| RIR Value | Timeline Adjustment |
| :--- | :--- |
| *RIR* ≥ 3 | 0 hours (Baseline) |
| *RIR* = 2 | +6 hours |
| *RIR* = 1 | +12 hours |
| *RIR* = 0 (Failure) | +24 hours |

This ensures that "training to failure" is mathematically represented as a significant physiological stressor requiring extended downtime.

---

## 4. Heuristic Categories

Readiness is categorized into three discrete states for user presentation:

1.  **Recovering** (*R* < 0.6): High residual fatigue. Performance is likely compromised.
2.  **Ready** (0.6 ≤ *R* < 0.9): Muscle is functional but may have slight remaining soreness or substrate depletion.
3.  **Fresh** (*R* ≥ 0.9): Optimal readiness for high-intensity loading.

---

## 5. Clinical Disclaimer
This model is a directional heuristic based on established sports science literature (NSCA, AASM) regarding muscle protein synthesis and nervous system recovery windows. It does not account for individual genetic variance, nutrition quality, or systemic stressors.
