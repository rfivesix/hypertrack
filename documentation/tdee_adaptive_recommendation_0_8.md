# Adaptive weekly calorie + macro recommendation (0.8 / issue #210)

This document defines the intended implementation scope for Hypertrack’s upcoming adaptive nutrition recommendation feature from issue #210.

This is an **implementation-ready internal specification**, not shipped behavior in the current working copy.

## Overview

Hypertrack should generate actionable nutrition recommendations by combining logged intake, smoothed bodyweight trend, and explicit user goal settings.

This feature covers:

- persistent goal and weekly target-rate selection
- onboarding-time initial recommendation
- recurring weekly adaptive recommendation generation
- maintenance/TDEE estimation intent
- calorie and macro recommendation output
- data-quality/confidence gating
- large-adjustment warning behavior
- manual apply/adopt flow (no silent overwrite)
- recommendation persistence/lifecycle
- UI integration surfaces

This feature is intended to move nutrition guidance from passive tracking toward transparent, conservative recommendations.

## Goals

### Product goals

- Provide a practical calorie target recommendation grounded in user data.
- Keep recommendation behavior transparent and confidence-aware.
- Require explicit user adoption before changing active nutrition targets.
- Reuse existing bodyweight/nutrition trend infrastructure where it fits.

### Persistent goal model

The feature must support and persist:

- `lose_weight`
- `maintain_weight`
- `gain_weight`

### Weekly target-rate model

Supported weekly target-rate options:

#### Lose

- `-0.25 kg/week`
- `-0.50 kg/week`
- `-0.75 kg/week`
- `-1.00 kg/week`

Default lose rate:

- `-0.50 kg/week`

#### Maintain

- `0.00 kg/week`

Default maintain rate:

- `0.00 kg/week`

#### Gain

- `+0.10 kg/week`
- `+0.25 kg/week`
- `+0.50 kg/week`

Default gain rate:

- `+0.25 kg/week`

## User flow

### 1) Onboarding initial recommendation

After relevant onboarding inputs are completed and the user selects goal + weekly target rate, Hypertrack should generate an immediate initial recommendation containing:

- recommended calories
- recommended protein
- recommended carbs
- recommended fat

The onboarding flow should allow explicit user adoption of this recommendation during onboarding.

Implementation intent:

- Initial onboarding recommendation may rely more on profile/basic data when historical adaptive data is insufficient.

### 2) Post-onboarding weekly adaptive recommendation

After onboarding, Hypertrack should generate a fresh adaptive recommendation every 7 days, targeting Monday `00:00` cadence.

Weekly generation should consider:

- logged calorie intake
- smoothed bodyweight trend
- selected goal
- selected weekly target rate
- data-quality/confidence gating

### 3) Manual apply/adopt behavior

Recommendations must not silently overwrite active targets.

Expected interaction:

- recommendation appears in Nutrition tab
- user reviews context/confidence/warnings
- user explicitly taps apply/adopt
- only then active targets update

## Data inputs

Primary inputs:

- logged calorie intake (observation window)
- bodyweight logs (used as smoothed trend, not raw day-to-day noise)
- selected goal
- selected weekly target rate
- historical recommendation state (for warning/change comparison)

Secondary inputs (especially onboarding fallback path):

- user profile/basic setup values as available in onboarding

Input-quality expectations:

- recommendation confidence must reflect sufficiency and consistency of available data
- missing/noisy data should produce conservative output behavior (suppressed, downgraded, or low-confidence state)

## Recommendation lifecycle

Recommended lifecycle model:

1. Goal + target-rate are persisted.
2. Initial recommendation may be generated during onboarding.
3. User may adopt initial recommendation explicitly.
4. Weekly adaptive job generates new recommendation on cadence.
5. New recommendation is stored as latest generated recommendation.
6. User may apply latest recommendation explicitly.
7. Active targets remain unchanged until explicit apply.

Lifecycle timestamps/state should include:

- latest recommendation generation timestamp
- latest recommendation period/window metadata
- latest accepted/applied recommendation timestamp (if tracked separately)
- cadence anchor (weekly Monday 00:00 intent)

## Algorithm and design intent

## 1) Maintenance/TDEE estimation intent

Design intent: estimate effective maintenance calories from observed intake and weight trend over a defined window with quality gating.

Core concept:

- if bodyweight trend is down at a given intake, inferred maintenance is higher than intake
- if bodyweight trend is up at a given intake, inferred maintenance is lower than intake

Guardrails:

- use smoothed weight trend, not raw daily fluctuations
- reuse existing bodyweight/nutrition trend infrastructure where appropriate
- prefer transparency over false precision

This spec intentionally avoids overcommitting final formula details before scientific refinement.

## 2) Recommended calorie target derivation

High-level derivation:

- estimate maintenance
- map selected weekly target rate to calorie adjustment
- `recommended_calories = estimated_maintenance + rate_adjustment`

Direction semantics:

- lose: maintenance minus deficit
- maintain: maintenance (near-zero adjustment)
- gain: maintenance plus surplus

## 3) Recommended macro target derivation (MVP intent)

MVP architecture assumption:

- calories are computed adaptively first
- macros are then derived from calorie target via rule-based logic / existing target logic / conservative defaults
- macros do not require a separate advanced adaptive engine in first implementation

Recommendation output should include:

- protein target
- carbs target
- fat target

## Persistence and state model

Conceptual persisted entities/state distinctions:

- persisted bodyweight goal
- persisted weekly target rate
- active nutrition targets (currently in effect)
- latest generated recommendation (pending user action unless applied)
- latest applied/accepted recommendation (if tracked separately)
- generation metadata (timestamp, observation window summary, confidence/warning state)

Important boundary:

- active targets and latest recommendation are separate concepts
- recommendation generation must be idempotent relative to cadence window and persistence rules

## UI integration points

Expected surfaces:

- onboarding recommendation step/screen (initial recommendation + apply/adopt action)
- Nutrition tab recommendation card/section (latest weekly recommendation)
- explicit apply/adopt control
- confidence state display
- large-adjustment warning display
- concise explanation copy (goal, weekly target, estimated maintenance, recommended calories, macro summary)

UI intent:

- user can understand what changed and why
- uncertainty is visible (not hidden)
- warnings prompt manual review, not silent behavior changes

## Warnings and confidence behavior

## Data-quality gating

Recommendation should be suppressed, downgraded, or labeled low-confidence when data is insufficient.

Likely gating dimensions:

- minimum observation window length
- minimum bodyweight logs
- minimum calorie-logged days
- completeness/consistency checks on the observation window

Low-data state should be explicit (for example: “not enough data yet”).

## Large-adjustment warning

No silent hard cap should be applied to strong recommendation changes.

If recommendation shifts unusually strongly versus prior stable recommendation, show warning-oriented UX:

- recommendation changed strongly
- verify logging completeness/accuracy
- recent bodyweight may reflect water/noise
- review manually before applying

## Architecture and boundaries

Intended module boundaries:

- domain engine/calculator (maintenance + calorie recommendation)
- data-quality evaluator
- recommendation model (domain + persistence representation)
- persistence/state layer (goal, target rate, generated/applied recommendation state)
- presentation model layer (confidence/warning/explanation copy payload)
- UI surfaces (onboarding + nutrition tab)

Boundary rules:

- keep recommendation logic out of presentation widgets
- keep platform/data-access concerns out of core recommendation calculations
- reuse existing bodyweight/nutrition trend infrastructure rather than duplicating trend logic

## Explicit non-goals (this batch)

- no meal-plan generation
- no macro periodization
- no training/rest-day calorie cycling
- no diet break/refeed logic
- no advanced ML/Bayesian forecasting system in first implementation
- no silent hard cap on recommendation changes

## Planned tests for implementation phase

When implementation begins, planned coverage should include:

- maintenance estimation behavior under representative trend/intake scenarios
- weekly target-rate to calorie-adjustment mapping correctness
- calorie recommendation derivation correctness
- macro derivation correctness for MVP rules/defaults
- data-quality gating thresholds and low-confidence/suppressed states
- large-adjustment warning trigger behavior
- persistence/restore behavior for goal, target rate, recommendation state
- onboarding initial recommendation generation and apply flow
- weekly recommendation generation cadence flow
- manual apply/adopt flow preserving separation from active targets

## Open questions and assumptions

## Intended behavior (committed direction)

- Feature provides adaptive calorie + macro recommendation flow.
- Weekly cadence target is Monday 00:00.
- Apply/adopt is explicit; no silent overwrite of active targets.
- Recommendation quality is data-quality-aware.
- Large changes are warned, not silently capped.

## Current assumptions (implementation placeholders)

- Initial onboarding recommendation may depend more on profile/basic inputs before enough history exists.
- MVP macro recommendation can be derived after calories via conservative rule-based logic.
- Confidence can be modeled from observation sufficiency + consistency checks.
- Existing weight/calorie trend infrastructure can provide most smoothing/trend primitives.

## Open design questions (to finalize before coding)

- Final observation window length defaults and fallback windows.
- Exact smoothing/trend method and parameterization for maintenance estimation.
- Exact conversion/mapping constants from weekly rate to calorie adjustment.
- Confidence scoring rubric and user-facing confidence tiers/copy.
- Large-adjustment warning threshold definition and comparison baseline.
- Recommendation versioning/schema decisions for future algorithm iteration.
- Exact onboarding UI placement and copy details relative to current onboarding flow.

## Scientific refinement and integration note

Further scientific review/refinement of the exact recommendation approach is expected shortly.

The final integration plan may be adjusted before implementation.

Accordingly, this document explicitly distinguishes:

- intended product behavior
- current assumptions used for MVP planning
- open design questions requiring final alignment
