# Adaptive weekly calorie + macro recommendation (0.8 / issue #210)

This document defines the intended implementation scope for Hypertrack’s adaptive nutrition recommendation feature from issue #210.

This is an internal implementation specification, not shipped behavior in the current working copy.

---

## Overview

This feature is a full adaptive weekly nutrition recommendation flow, not just a hidden TDEE formula.

It includes:

- goal selection (lose / maintain / gain)
- weekly target-rate selection
- onboarding initial recommendation
- recurring weekly recommendation generation (planned Monday `00:00`)
- recommended calories + macros (protein, carbs, fat)
- confidence / data-quality state
- large-adjustment warning behavior
- explicit manual apply/adopt flow
- separation of active targets vs generated recommendation

The feature should be transparent, conservative under uncertainty, and useful early (including onboarding and early post-onboarding periods).

---

## Product goal

Hypertrack should move from pure nutrition tracking toward practical guidance by generating adaptive weekly calorie and macro recommendations anchored to observed intake and smoothed bodyweight trend.

Primary product goals:

- provide actionable recommendations early, not only after long history accumulation
- avoid overreaction to short-term bodyweight noise
- expose confidence and warning states explicitly
- preserve user control via manual apply/adopt
- avoid false precision and hidden hard caps

## Weekly target-rate options and defaults

The recommendation system should support a small, explicit set of user-selectable weekly target rates.

### Supported options

#### Lose
- `-0.25 kg/week`
- `-0.50 kg/week`
- `-0.75 kg/week`
- `-1.00 kg/week`

#### Maintain
- `0.00 kg/week`

#### Gain
- `+0.10 kg/week`
- `+0.25 kg/week`
- `+0.50 kg/week`

### MVP defaults

- lose default: `-0.50 kg/week`
- maintain default: `0.00 kg/week`
- gain default: `+0.25 kg/week`

### Product notes

- These values are intentional product options, not dynamically generated free-form inputs in MVP.
- They should remain simple and understandable for onboarding and settings UX.
- The underlying kcal/day mapping should be treated as an approximation, not as an exact physiological law.
- Future versions may refine labels or present these rates additionally as `% bodyweight/week`, but MVP can keep `kg/week` as the primary user-facing format.

---

## User flow

## 1) Onboarding initial recommendation

After user profile inputs and goal + weekly target-rate selection during onboarding, the app should generate an immediate recommendation:

- calories
- protein
- carbs
- fat

The recommendation can be applied during onboarding, but should not be silently forced.

Onboarding recommendation uses stronger prior-based estimation with limited adaptation when history is sparse.

## 2) Early adaptive path (week 2+)

The app should support adaptive recommendations as early as week 2 when minimum data thresholds are met, even if confidence is low/medium.

This avoids a design where users wait months before the feature becomes useful.

## 3) Weekly recommendation cadence

- Recommendation refresh cadence: every 7 days.
- Planned refresh anchor: Monday `00:00`.
- Internal estimation window: rolling multi-week data window (preferred MVP: 21 days).

## 4) Manual apply/adopt flow

- New recommendation is displayed in nutrition surfaces.
- Active targets remain unchanged until user explicitly applies/adopts.
- Applied targets become current active goals for diary/nutrition usage.

---

## Recommendation lifecycle

Conceptual lifecycle:

1. Persist goal and weekly target-rate.
2. Generate onboarding recommendation (prior-heavy).
3. Optional onboarding apply/adopt.
4. Weekly scheduler attempts generation on cadence.
5. System evaluates data quality/confidence.
6. System generates recommendation payload (or not-enough-data state).
7. Recommendation is stored as latest generated recommendation.
8. User manually applies/adopts if desired.
9. Active nutrition targets are updated only on apply/adopt.

Required lifecycle metadata:

- generation timestamp
- effective window start/end
- cadence anchor / due-week key
- confidence state + quality summary
- warning flags (including large-adjustment warning)
- previous recommendation linkage/snapshot for explainability

---

## Weekly scheduler / due-week semantics

The recommendation feature is product-defined as a **weekly update system** with a planned user-facing anchor of **Monday `00:00`**.

However, implementation should treat this as a **week-key / due-window concept**, not as a requirement for exact background execution at that precise timestamp.

### Intended behavior

- Each calendar week has one conceptual recommendation generation slot.
- The planned anchor is Monday `00:00`.
- The system should generate **at most one recommendation per due week**.
- If the app is not running exactly at Monday `00:00`, generation should occur the next time the app has a valid opportunity (for example app startup, foreground resume, or another supported execution path).

### Practical implementation intent

The scheduler should be designed around something like:

- `dueWeekKey`
- `lastGeneratedWeekKey`

Where:
- `dueWeekKey` identifies the current recommendation week
- generation runs only if `lastGeneratedWeekKey != dueWeekKey`

### Why this matters

This keeps behavior stable across platform limitations:

- iOS and Android may not guarantee exact background execution timing
- app lifecycle interruptions should not cause duplicate or missed recommendation states
- recommendation cadence remains predictable without requiring exact scheduler precision

### MVP expectation

For MVP, the important invariant is:

- **one recommendation per due week**
- not exact millisecond execution at Monday `00:00`

This should be reflected in both implementation and tests.

---

## Calculation model / design intent (MVP proposal)

## Scientific framing and approximation policy

MVP should treat body-mass change estimation as approximate dynamic energy balance, not an exact linear conversion.

Design policy:

- no claim of exact “true TDEE”
- expose estimate + confidence
- reflect uncertainty from intake logging noise and short-term weight variability

Rationale references:

- Dynamic energy balance and limits of fixed linear conversion framing:  
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC3859816/  
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC3810417/  
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC6513301/  
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC4035446/  
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC2980958/  
  - https://pmc.ncbi.nlm.nih.gov/articles/PMC3127505/

## Cadence + estimation window

- Refresh cadence remains weekly (7-day).
- Estimation should use a rolling multi-week window.
- Preferred current MVP proposal: **21-day rolling window**.

Reasoning:

- weekly UX rhythm remains simple and understandable
- multi-week window improves noise resistance and reduces overreaction

Weight-variability and smoothing context:

- https://pmc.ncbi.nlm.nih.gov/articles/PMC10653631/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC7519428/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC7192384/

## Smoothed weight trend

Preferred MVP direction:

- derive trend from **EWMA-based smoothed bodyweight** rather than raw daily values
- reuse existing trend infrastructure where already available and compatible (for example body/nutrition analytics smoothing paths)

Implementation note:

- trend method and parameters are tunable assumptions in MVP, not immutable scientific constants

## TDEE/maintenance estimate (MVP structure)

Preferred MVP structure:

1. Profile-based prior (onboarding / cold-start estimate).
2. Data-informed update using logged intake + smoothed trend over rolling window.
3. Adaptive estimate with shrinkage/damping toward prior or previous stable estimate when data quality is weak.

Interpretation intent:

- down-trending weight at given intake implies higher maintenance than intake
- up-trending weight at given intake implies lower maintenance than intake

Onboarding-prior context (RMR equation variability and practical use as starting priors):

- https://linkinghub.elsevier.com/retrieve/pii/S2212267216301071
- https://pmc.ncbi.nlm.nih.gov/articles/PMC7299486/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC9960966/
- https://cdnsciencepub.com/doi/10.1139/apnm-2020-0887

Intake misreporting and quality caveat context:

- https://www.frontiersin.org/articles/10.3389/fendo.2019.00850/full
- https://pmc.ncbi.nlm.nih.gov/articles/PMC6928130/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC1662510/
- https://www.scielo.br/j/csp/a/tZxsC44dwF8z7nJb6FQSNwP/?lang=en
- https://pmc.ncbi.nlm.nih.gov/articles/PMC2803049/

## Calorie recommendation derivation

High-level derivation:

1. estimate maintenance/TDEE
2. map selected weekly target-rate to approximate calorie adjustment
3. compute final recommendation:
   - `recommended_calories = estimated_maintenance + rate_adjustment`

Direction semantics:

- lose: maintenance minus deficit
- maintain: maintenance
- gain: maintenance plus surplus

This mapping should remain explicit and auditable in-domain, not hidden in UI.

---

## Confidence and warning logic

## Confidence states (proposed MVP)

Proposed enum-like staged states:

- `not_enough_data`
- `low_confidence`
- `medium_confidence`
- `high_confidence`

These are proposed MVP thresholds and may be tuned later.

## Proposed MVP gating thresholds

Proposed practical thresholds:

- earliest adaptive generation attempt: from week 2 onward
- minimum observation window for adaptive estimate:
  - low confidence: ~7+ days usable data
  - medium confidence: ~14+ days usable data
  - high confidence target: ~21 days usable data
- minimum weight logs:
  - low: >= 3
  - medium: >= 6
  - high: >= 9
- minimum intake-logged days:
  - low: >= 5
  - medium: >= 10
  - high: >= 15

If thresholds fail, return explicit `not_enough_data` or downgraded confidence output.

## Stabilization / anti-overreaction design

Proposed stabilization stack:

- weekly refresh cadence
- 21-day rolling estimation window
- shrinkage toward prior/previous estimate when quality weak
- damping on weekly estimate movement (transparent, explainable)
- warning state for unusually large recommendation changes

Important:

- stabilization must not be documented as silent hard cap behavior
- user-facing messaging should indicate that uncertainty and data quality influenced the recommendation

## Large-adjustment warning (proposed MVP)

A warning should be triggered when recommendation change magnitude versus prior stable recommendation exceeds defined threshold(s).

Proposed threshold framing (tunable):

- moderate warning band (review suggested)
- high warning band (strong review suggested before apply)

Warning copy principles:

- state that change is unusually large
- recommend reviewing logging completeness and bodyweight entries
- note short-term water/noise possibility
- preserve user agency (manual apply)

Possible causes surfaced in explanatory copy:

- incomplete intake logging
- transient water retention/drop
- unusual week behavior
- adherence shift
- real change in energy needs

General practical weekly-adjustment/coaching rationale:

- https://www.mdpi.com/2227-9032/6/3/73/pdf
- https://pmc.ncbi.nlm.nih.gov/articles/PMC8017325/

---

## Macro recommendation logic (training-oriented MVP defaults)

MVP should use training-oriented defaults appropriate for Hypertrack’s user base.

## Protein defaults (proposed)

- cut: **~2.0 g/kg**
- maintain: **~1.8 g/kg**
- gain: **~1.8 g/kg**

Rationale:

- general-population guidance can support lower ranges
- Hypertrack default should target active/lifting/body-composition users conservatively

Training-oriented protein evidence context:

- https://pmc.ncbi.nlm.nih.gov/articles/PMC5477153/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC5470183/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC10210857/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC5867436/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC8978023/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC7727026/
- https://www.mdpi.com/2072-6643/13/9/3255/pdf
- https://bjsm.bmj.com/lookup/doi/10.1136/bjsports-2017-097608

Additional sports/body-composition context:

- https://pmc.ncbi.nlm.nih.gov/articles/PMC5596471/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC11206787/

## Fat floor and carbs remainder (proposed)

Proposed macro sequence:

1. set calorie target
2. set protein from bodyweight + goal default
3. enforce minimum fat floor
4. assign remaining calories to carbs

Rationale references:

- https://foodandnutritionresearch.net/index.php/fnr/article/download/232/232
- https://pmc.ncbi.nlm.nih.gov/articles/PMC6033587/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC10661909/

MVP notes:

- exact fat floor value and fallback handling are tunable
- if calculated remainder becomes too low/negative, recommendation should degrade with explicit warning/explanation rather than silently producing implausible macros

---

## Proposed models / state objects

The following are proposed conceptual models for implementation planning.

## Goal and target models

- `BodyweightGoal`
  - values: `loseWeight`, `maintainWeight`, `gainWeight`

- `WeeklyTargetRate`
  - fields: `goal`, `kgPerWeek`, `isDefault`
  - supported values:
    - lose: `-0.25`, `-0.50`, `-0.75`, `-1.00`
    - maintain: `0.00`
    - gain: `+0.10`, `+0.25`, `+0.50`

## Confidence and warning models

- `RecommendationConfidence`
  - values: `notEnoughData`, `low`, `medium`, `high`

- `RecommendationWarningState`
  - fields:
    - `hasLargeAdjustmentWarning`
    - `warningLevel` (`none|moderate|high`)
    - `warningReasons` (list of machine-readable reason codes)

## Recommendation payload models

- `NutritionRecommendation`
  - fields:
    - `recommendedCalories`
    - `recommendedProteinGrams`
    - `recommendedCarbsGrams`
    - `recommendedFatGrams`
    - `estimatedMaintenanceCalories`
    - `goal`
    - `targetRateKgPerWeek`
    - `confidence`
    - `warningState`
    - `generatedAt`
    - `windowStart`
    - `windowEnd`
    - `algorithmVersion`

- `RecommendationInputSummary`
  - fields:
    - `windowDays`
    - `weightLogCount`
    - `intakeLoggedDays`
    - `smoothedWeightSlopeKgPerWeek`
    - `avgLoggedCalories`
    - `qualityFlags`

## Active vs generated target models

- `ActiveNutritionTargets`
  - currently effective calorie/macro targets used by nutrition flows

- `LatestGeneratedRecommendationState`
  - latest generated recommendation pending user apply/adopt

- `LatestAppliedRecommendationSnapshot`
  - recommendation snapshot last adopted into active targets

- `RecommendationHistorySnapshot` (optional MVP+)
  - historical generated recommendations for explainability/audit

---

## Proposed file/folder structure (implementation planning)

This is a proposed target layout aligned with current repository style and boundaries.

```text
lib/features/nutrition_recommendation/
  domain/
    recommendation_models.dart
    confidence_models.dart
    goal_models.dart
    tdee_estimator.dart
    calorie_target_calculator.dart
    macro_target_calculator.dart
    recommendation_engine.dart
    data_quality_evaluator.dart
    recommendation_stabilizer.dart
  data/
    recommendation_repository.dart
    recommendation_persistence_models.dart
    recommendation_scheduler.dart
    recommendation_input_adapter.dart
  presentation/
    nutrition_recommendation_card.dart
    recommendation_explanation_sheet.dart
    recommendation_confidence_badge.dart
    recommendation_warning_banner.dart
```

Likely integration touchpoints in existing app structure:

- `lib/screens/onboarding_screen.dart`
- `lib/screens/nutrition_hub_screen.dart`
- `lib/screens/goals_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/features/statistics/domain/body_nutrition_analytics_models.dart` (for trend input reuse/interface alignment)

Note:

- exact folder name can be `nutrition_recommendation` or `nutrition` submodule depending on maintainability choice; keep recommendation domain logic isolated from widget screens.

---

## Proposed screen changes / UI integration points

The following are implementation-planning proposals mapped to current screens.

## Onboarding

File: `lib/screens/onboarding_screen.dart`

Proposed conceptual changes:

- add goal + weekly target-rate selection step (or expand existing nutrition-goal step)
- generate onboarding recommendation after profile + target-rate input
- show recommendation summary (calories/protein/carbs/fat + confidence note)
- add explicit apply/adopt action before onboarding completion

## Nutrition hub

File: `lib/screens/nutrition_hub_screen.dart`

Proposed conceptual changes:

- add recommendation card section for latest generated recommendation
- show:
  - goal + target rate
  - estimated maintenance
  - recommended calories/macros
  - confidence badge
  - warning banner when applicable
- add explicit apply/adopt button
- add “not enough data yet” / low-confidence states

## Goals and profile surfaces

Files:

- `lib/screens/goals_screen.dart`
- `lib/screens/profile_screen.dart`

Proposed conceptual changes:

- persist goal direction + weekly target rate alongside nutrition targets
- optionally expose recommendation settings/help text
- keep manual goals editable while preserving distinction from generated recommendation

## Settings / operational controls

File: `lib/screens/settings_screen.dart`

Possible conceptual changes:

- optional recommendation debug/status section (last generated at, confidence state, next due)
- optional manual “refresh recommendation now” trigger for troubleshooting (if consistent with product direction)

## Optional analytics surface

File: `lib/screens/analytics/body_nutrition_correlation_screen.dart`

Possible conceptual changes:

- expose lightweight “recommendation basis” cues (window quality/trend context) if needed for explainability
- keep recommendation decisioning in recommendation domain, not analytics UI

---

## Persistence / restore / lifecycle expectations

Persistent entities (conceptual):

- selected bodyweight goal
- selected weekly target-rate
- active nutrition targets (calories/macros)
- latest generated recommendation payload
- latest applied recommendation snapshot (if separate)
- generation metadata (timestamps, window, confidence/warnings, algorithm version)
- scheduler metadata (`lastGeneratedAt`, `lastDueWeekKey`)

Behavior expectations:

- recommendation generation is cadence-aware and idempotent per due window
- generated recommendation never silently overwrites active targets
- apply/adopt creates explicit state transition
- restored backups should restore:
  - selected goal/target-rate
  - active targets
  - latest recommendation state
  - relevant generation timestamps and metadata needed for predictable next refresh

Backup/restore note:

- recommendation state should be restored consistently with existing backup model so post-restore UI does not show contradictory active vs latest recommendation state.

---
## Manual override semantics and active-vs-generated target behavior

The recommendation system must keep a strict conceptual distinction between:

- **active nutrition targets**
- **latest generated recommendation**
- **latest applied/adopted recommendation**

This distinction remains important even after the user has manually edited targets.

### Core rule

A generated recommendation must never silently overwrite the user’s active targets.

Only an explicit user action should promote a recommendation into the active target set.

### Manual override scenarios

After a recommendation has been applied, the user may still manually edit calories/macros later.

In that case:

- active targets may diverge from the latest generated recommendation
- the last generated recommendation remains part of recommendation state/history
- the app must not assume that active targets always equal latest recommendation
- the app should preserve this distinction across app restarts and backup/restore

### Important conceptual states

#### 1) Active targets
The targets currently used by diary/nutrition flows.

#### 2) Latest generated recommendation
The newest recommendation computed by the recommendation engine, whether applied or not.

#### 3) Latest applied recommendation snapshot
The recommendation snapshot that was last explicitly adopted by the user, if tracked separately.

### Comparison baseline for future updates

This must be defined explicitly during implementation.

A future weekly recommendation may need comparison against one or more of:

- current active targets
- previous generated recommendation
- previous applied recommendation
- previous stable recommendation baseline

### Current MVP recommendation

For MVP, document the intended comparison logic as:

- **warning / delta-to-user impact** should primarily compare against **current active targets**
- **historical explanation / recommendation drift** may compare against **previous generated recommendation** or **previous applied recommendation**, depending on implementation simplicity

### Why this matters

Without this distinction, the app can become confusing in cases where:

- a recommendation is generated but not applied
- a recommendation is applied and then manually edited
- a later recommendation appears and the app needs to explain “what changed” and “relative to what”

This behavior should be covered explicitly in persistence logic, backup/restore expectations, and future tests.

---

## Weekly scheduling / generation flow (proposed)

Conceptual scheduler flow:

1. Determine current weekly due key (Monday `00:00` anchored).
2. If recommendation for due key already generated, skip (idempotent).
3. Build rolling window (preferred 21 days).
4. Gather and validate inputs (intake logs, weight logs, trend).
5. Evaluate confidence/gating.
6. Generate recommendation (or not-enough-data state payload).
7. Compare to prior stable recommendation for warning logic.
8. Persist latest generated recommendation + metadata.
9. Surface update in nutrition UI for manual apply.

---

## Tests (implementation-phase plan)

Proposed future test focus and likely test locations:

## Domain tests

Likely path:

- `test/features/nutrition_recommendation/domain/*`

Coverage:

- TDEE estimate behavior under representative synthetic scenarios
- EWMA trend handling and slope interpretation
- rate-to-calorie adjustment mapping
- stabilization/shrinkage behavior under weak data
- confidence classification and gating thresholds
- warning trigger behavior across recommendation deltas
- macro derivation (protein defaults, fat floor, carbs remainder)

## Data/persistence tests

Likely path:

- `test/features/nutrition_recommendation/data/*`

Coverage:

- recommendation persistence/read-back integrity
- active vs generated recommendation separation
- due-key idempotency / scheduler state handling
- backup/restore serialization integrity for recommendation state

## Presentation/UI flow tests

Likely path:

- `test/features/nutrition_recommendation/presentation/*`
- and targeted tests around:
  - `test/screens/onboarding_*`
  - `test/screens/nutrition_hub_*`
  - `test/screens/goals_*`

Coverage:

- onboarding recommendation generation and apply flow
- nutrition hub recommendation rendering and apply action
- confidence and warning display states
- not-enough-data state rendering
- no silent overwrite behavior across reload/navigation

---

## Non-goals (this batch)

- no meal-plan generation
- no macro periodization
- no training/rest-day cycling
- no diet break/refeed logic
- no advanced ML/Bayesian forecasting system in MVP
- no silent hard cap on recommendation changes
- no broad unrelated nutrition refactor

---

## Open questions

Key open questions to finalize before coding:

1. Exact EWMA parameterization and fallback when sparse daily weight points exist.
2. Final numeric threshold values for confidence bands and warning tiers.
3. Exact shrinkage/damping formula and explainability copy.
4. Final mapping constants from weekly kg target-rate to calorie adjustment.
5. Fat floor default and edge handling when calorie target is very low.
6. Whether recommendation history snapshots ship in MVP or MVP+.
7. Final scheduler trigger mechanism in app lifecycle (startup, foreground sync, periodic timer, explicit manual refresh).
8. Localization/copy strategy for confidence and warning explanations.
9. Exact placement and UX details of onboarding recommendation step in current 6-page onboarding flow.

---

## Sources / references

All links below are intentionally retained as direct source references for implementation planning and future scientific refinement.

## Dynamic energy balance / fixed-rule caveats

- https://pmc.ncbi.nlm.nih.gov/articles/PMC3859816/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC3810417/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC6513301/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC4035446/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC2980958/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC3127505/

## Intake misreporting / usual intake estimation

- https://www.frontiersin.org/articles/10.3389/fendo.2019.00850/full
- https://pmc.ncbi.nlm.nih.gov/articles/PMC6928130/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC1662510/
- https://www.scielo.br/j/csp/a/tZxsC44dwF8z7nJb6FQSNwP/?lang=en
- https://pmc.ncbi.nlm.nih.gov/articles/PMC2803049/

## RMR prediction equations / onboarding priors

- https://linkinghub.elsevier.com/retrieve/pii/S2212267216301071
- https://pmc.ncbi.nlm.nih.gov/articles/PMC7299486/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC9960966/
- https://cdnsciencepub.com/doi/10.1139/apnm-2020-0887

## Weight variability / smoothing / rolling trend rationale

- https://pmc.ncbi.nlm.nih.gov/articles/PMC10653631/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC7519428/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC7192384/

## Protein recommendations / training-oriented defaults

- https://pmc.ncbi.nlm.nih.gov/articles/PMC5477153/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC5470183/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC10210857/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC5867436/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC8978023/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC7727026/
- https://www.mdpi.com/2072-6643/13/9/3255/pdf
- https://bjsm.bmj.com/lookup/doi/10.1136/bjsports-2017-097608

## Fat/macro-distribution guidance context

- https://foodandnutritionresearch.net/index.php/fnr/article/download/232/232
- https://pmc.ncbi.nlm.nih.gov/articles/PMC6033587/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC10661909/

## Practical weekly adjustment/coaching framing

- https://www.mdpi.com/2227-9032/6/3/73/pdf
- https://pmc.ncbi.nlm.nih.gov/articles/PMC8017325/

## Additional sports/body-composition context

- https://pmc.ncbi.nlm.nih.gov/articles/PMC5596471/
- https://pmc.ncbi.nlm.nih.gov/articles/PMC11206787/

---

## Scientific refinement and integration note

Further scientific refinement of thresholds and exact equation details is planned before implementation.

Accordingly, this document distinguishes:

- intended MVP product behavior
- scientific rationale and approximation limits
- proposed implementation thresholds/models (tunable)
- open questions pending final integration decisions
