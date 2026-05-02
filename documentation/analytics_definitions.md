# Shared Analytics Logic & Definitions

> Status: Legacy heuristic reference.  
> This file is **not** the canonical source of truth for current Statistics implementation details.  
> Use [statistics_module.md](statistics_module.md) for current code-audited behavior.

This document preserves historical analytics heuristics and terminology that may still be partially reflected in code.
If statements here differ from implementation, code (and `statistics_module.md`) is authoritative.

## Versioning Note

The definitions below represent a historical v1 rule set. Some heuristics may still apply, while others may have diverged in implementation over time.

---

## 1. Set Classifications

### What counts as a "Work Set"?
A set is considered a **Work Set** (also known as a "Hard Set") and included in volume, PR, and muscle frequency calculations *only if* it meets all the following criteria:
*(Note: Field names map exactly to the `SetLog` database model properties: `isCompleted`, `setType`, `weightKg`, `reps`, `distanceKm`, `durationSeconds`, `rir`, `rpe`.)*
- `isCompleted == true` (has actually been performed).
- `setType` is **not** `"warmup"` (must be `"normal"`, `"failure"`, `"dropset"`, etc.).
- For tonnage/PR metrics, `weightKg` is not null and `> 0`.
- For muscle recovery equivalent-set stimulus, completed rep-based strength
  work can count even when `weightKg` is null or `0` (bodyweight strength work).
  Obvious cardio categories/names are excluded from muscle recovery even when
  they carry muscle mappings.
- `reps` is not null and `> 0` (or `durationSeconds > 0` for cardio or isometric).

### Handling of Specific Set Types
- **Warm-up Sets:** Ignored for all volume, PR, and muscle group tracking. Only considered for total workout duration and session analysis in the backend.
- **Failure Sets:** Counted as standard work sets. Assumed to have `RIR = 0`. Used to track failure frequency heuristics over time.
- **Dropsets:** Counted as standard work sets. Their volume (weight × reps) is fully added to the total. If grouped with a parent set, they contribute to the parent exercise's total volume.

---

## 2. Volume Calculations

Volume can be tracked in two primary ways: **Total Tonnage** (Weight × Reps) and **Hard Set Count**. The standard is context-dependent:

- **Exercise Volume (Tonnage):** 
  `Σ (weightKg * reps)` across all **Work Sets** for that specific exercise in a given session.
- **Muscle Group Volume (Hard Sets):** 
  Hypertrophy research favors tracking the *number of hard sets* rather than raw tonnage. 
  Muscle volume = `Σ Work Sets` targeting that muscle.
- **Session Volume (Total Tonnage):** 
  The sum of all Exercise Volumes within a single `WorkoutLog`.

---

## 3. PR (Personal Record) Logic

PRs are evaluated on two fronts: **Estimated 1RM** and **Repetition Maxes**.

### Estimated 1RM Formula
Calculated using the **Brzycki formula**: `Weight * (36 / (37 - Reps))`
*Constraint:* To ensure data quality, Estimated 1RM is only calculated for sets with **≤ 10 reps**. Sets with > 10 reps skew the math and should not generate new 1RM PRs.

### Rep Ranges for Rep-Max PRs
Instead of tracking a PR for every arbitrary rep count, rep ranges are grouped into "brackets" for trend analysis:
- **1 RM** (True Max)
- **2-3 RM** (Heavy Strength)
- **4-6 RM** (Strength / Hypertrophy)
- **7-10 RM** (Hypertrophy)
- **11-15 RM** (Endurance / Hypertrophy)
- **15+ RM** (Endurance)

The highest weight lifted within a bracket establishes the PR for that bracket.

---

## 4. Muscle Group Weighting & Frequency

*(Note: These are v1 heuristics for baseline functionality.)*

Exercises often engage multiple muscles. To prevent over-calculating volume, we use a fractional distribution method.

**Volume / Hard Set Distribution:**
- **Primary Muscles:** Receive **100%** of the set's value (1.0).
- **Secondary Muscles:** Receive **50%** of the set's value (0.5).

*Example:* 3 sets of Bench Press (Primary: Chest, Secondary: Triceps, Shoulders).  
*Result:* Chest = 3.0 sets, Triceps = 1.5 sets, Shoulders = 1.5 sets.

**Frequency Counting:**
Muscle frequency evaluates how often a muscle is trained per week. A muscle is counted as "trained" on a given day if the user accumulates at least **1.0 equivalent hard sets** (e.g., 1 primary exercise set or 2 secondary exercise sets) for that muscle on that calendar day.

---

## 5. Smoothing Methods for Trend Charts

Raw fitness data is highly volatile. Trend charts (e.g., Estimated 1RM over time, Bodyweight, Volume per week) will use a **7-Day Rolling Average** or a **14-Day Rolling Average** depending on the selected time window (1 month view vs. 6 month view).

- **< 3 months view:** 7-Day Rolling Average.
- **> 3 months view:** 14-Day Rolling Average.

---

## 6. Recovery Heuristics

*(Note: Current recovery remains a consumer training-log heuristic for planning.
It is not a physiological diagnosis or clinical prediction.)*

Recovery is calculated from recent significant equivalent-set loading per
muscle. It should be interpreted alongside subjective readiness, soreness,
sleep, injury status, and coaching judgment.

Current rules:

- Recovery uses a fixed recent lookback (`RecoveryDomainService.recoveryLookbackDays`,
  currently 14 days), not the selected Statistics time-range chip.
- Significant load threshold:
  `RecoveryDomainService.minimumSignificantEquivalentSets = 1.0`.
- Primary muscle set contribution: `1.0` equivalent set.
- Secondary muscle set contribution: `0.5` equivalent sets.
- Completed non-warmup strength sets with `reps > 0` count for recovery,
  including bodyweight work with null/zero `weightKg`.
- Pure cardio is excluded from muscle recovery stimulus. Distance/duration does
  not reset a muscle's recovery clock.
- High fatigue is detected when average `RIR <= 0.5` or average `RPE >= 8.5`;
  high fatigue extends both boundaries by +24 hours.
- Load-based extension by last-session equivalent sets:
  `1.0-2.99: +0h`, `3.0-4.99: +6h`, `5.0-7.99: +12h`,
  `8.0-10.99: +24h`, `>= 11.0: +36h`.
- Base windows are muscle-specific product heuristics:
  delts/biceps/triceps/forearms/calves `36h/60h`; chest/lats/upper back/traps/
  abs/core `48h/72h`; quads/hamstrings/glutes/adductors `60h/96h`; lower back/
  spinal erectors `72h/120h`; unknown labels fall back to `48h/72h`.
- Final state uses inclusive boundaries:
  `<= recoveringUpperHours` -> `recovering`,
  `<= readyUpperHours` -> `ready`, otherwise `fresh`.
- The status badge is the primary current readiness state.
- The visible per-muscle readiness score is current-state progress through the
  effective window. It is low near `0h`, around `60` at the recovering boundary,
  around `85` at the ready boundary, and approaches `100` after the ready window
  has passed. Longer effective windows lower readiness at the same elapsed time.
- Last-load pressure is a separate recent stimulus/recovery-demand label. It
  uses the piecewise load curve for equivalent sets per muscle per session:
  `0 -> 0`, `1 -> 10`, `2 -> 18`, `3 -> 26`, `4 -> 34`, `5 -> 41`,
  `6 -> 47`, `8 -> 55`, `10 -> 60`, `12+ -> 65`, plus a small high-fatigue
  component.
- Displayed effective windows include the muscle profile, load-based extension,
  and intensity/RIR/RPE extension.

Known limitations:

- Secondary muscles still use coarse mapping unless a future patch introduces
  per-exercise coefficients.
- No systemic fatigue, sleep debt, soreness, pain, injury, deload, or training
  age model is included.
- Exercise mapping changes may affect history unless historical muscle mappings
  are snapshotted in a future schema.

---

## 7. Data Quality & Insight Suppression

To prevent the analytics tab from showing flawed or meaningless charts (e.g., a "trend" based on only two workouts), dynamic insights apply a suppression rule:

- **Minimum Data Requirement:** Trend lines and PR extrapolations for a specific exercise or muscle group will **only** render if there are at least **3 distinct data points** spread across **a minimum of 14 days**.
- If data quality is too low, the UI will display a placeholder state: *"Keep tracking to unlock insights."*
