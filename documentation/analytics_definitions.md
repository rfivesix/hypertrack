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
- `weightKg` is not null and `> 0` (or `distanceKm > 0` for cardio).
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

*(Note: These are v1 heuristics for baseline functionality.)*

Recovery is calculated as a high-level heuristic based on the time elapsed since a muscle group was last trained with significant volume:

- **< 48 hours:** Categorized as "Recovering" (High Fatigue).
- **48 - 72 hours:** Categorized as "Ready/Recovered" (Moderate Fatigue).
- **> 72 hours:** Categorized as "Fresh" (Low Fatigue).

*Modifiers:* If average `RIR` for the session was `0` (high exhaustion) or average `RPE` was `≥ 9`, recovery thresholds are extended by +24 hours.

---

## 7. Data Quality & Insight Suppression

To prevent the analytics tab from showing flawed or meaningless charts (e.g., a "trend" based on only two workouts), dynamic insights apply a suppression rule:

- **Minimum Data Requirement:** Trend lines and PR extrapolations for a specific exercise or muscle group will **only** render if there are at least **3 distinct data points** spread across **a minimum of 14 days**.
- If data quality is too low, the UI will display a placeholder state: *"Keep tracking to unlock insights."*
