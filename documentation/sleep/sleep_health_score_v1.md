# Sleep Health Score V1 (Current Implementation)

This document describes the implemented V1 Sleep Health Score in the current working copy.

## Scope

Implemented in:

- `lib/features/sleep/domain/scoring/sleep_scoring_engine.dart`
- `lib/features/sleep/domain/metrics/sleep_regularity_index.dart`
- `lib/features/sleep/data/processing/sleep_pipeline_service.dart`

Persisted in:

- `sleep_nightly_analyses` (`lib/data/drift_database.dart`)

## Top-level formula

V1 uses only three top-level components:

- Duration (TST): `35%`
- Continuity (SE + WASO): `35%`
- Regularity (SRI): `30%`

Top-level renormalization over available components:

- `W = sum(weight_i for available components)`
- `score = sum(weight_i * componentScore_i) / W`
- if `W == 0`, score is unavailable (`null`)

## Continuity formula

Continuity combines:

- SE score: `50%`
- WASO score: `50%`

Internal renormalization is applied if one subcomponent is missing.

## Definitions (implemented)

- `TST`: total minutes scored as sleep from nightly repaired sleep timeline (`totalSleepTime`)
- `SE`: `TST / TIB * 100` from nightly metrics
- `WASO`: wake minutes after sleep onset and before final awakening (`wakeAfterSleepOnset`)
- `SRI`: probability (0..100) that sleep/wake state matches at 24h-apart timepoints

## Component scoring rules

### Duration score (TST)

Input: hours of sleep (`durationMinutes / 60`)

- `7.0 .. 9.0` => `100`
- `6.0 .. <7.0` => linear `70 -> 100`
- `5.0 .. <6.0` => linear `30 -> 70`
- `4.0 .. <5.0` => linear `0 -> 30`
- `<4.0` => `0`
- `>9.0 .. 10.0` => linear `100 -> 85`
- `>10.0 .. 11.0` => linear `85 -> 60`
- `>11.0` => clamped `60` (conservative)

### Sleep efficiency score (SE)

- `>=90` => `100`
- `85 .. <90` => linear `85 -> 100`
- `80 .. <85` => linear `65 -> 85`
- `70 .. <80` => linear `25 -> 65`
- `<70` => linear `0 -> 25` (clamped at 0)

### WASO score

- `<=30` min => `100`
- `>30 .. 60` => linear `100 -> 70`
- `>60 .. 120` => linear `70 -> 30`
- `>120` => linear `30 -> 0` with clamp at 0

## SRI implementation details

Implementation path:

- Pipeline builds 1-minute sleep/wake vectors (`0` wake, `1` sleep) per day.
- Vectors are built from repaired canonical stage segments.
- Sleep stages counted as sleep: `light`, `deep`, `rem`, `asleepUnspecified`.
- Minutes not covered by those sleep stages are treated as wake in the binary series.
- SRI is computed from minute-wise equality across matching clock minutes on true 24h pairs (consecutive calendar days).
- Non-consecutive valid days are not compared as SRI pairs.
- Output SRI is a 0..100 probability score.

Current data windowing behavior:

- Per-night regularity uses trailing history available in a 30-day lookback query window.
- Computation uses available consecutive-day pairs inside that history.

Minimum data rules:

- `<5` valid days: regularity unavailable
- `5..6` valid days: regularity available, marked as preliminary (not stable)
- `>=7` valid days: regularity marked stable

If regularity is unavailable, top-level score renormalizes across Duration and Continuity only.

## Score completeness indicator

`score_completeness` is persisted as active top-level weight before renormalization:

- all components available: `1.0`
- regularity missing: `0.70`
- continuity missing: `0.65`
- no components: `0.0` (score unavailable)

This is a data completeness indicator, not a certainty metric.

## Explicit exclusions from V1 main score

The following are not used in V1 score computation:

- sleep stage percentages/depth as direct score input
- SOL
- heart-rate and HRV metrics/deltas
- interruption count as a standalone component (continuity uses WASO directly)

## Persistence fields used by V1

From `sleep_nightly_analyses`:

- `score`
- `score_completeness`
- `total_sleep_minutes`
- `sleep_efficiency_pct`
- `interruptions_wake_minutes` (WASO)
- `regularity_sri`
- `regularity_valid_days`
- `regularity_is_stable`

## Evidence-backed vs heuristic

Evidence-backed directions:

- insufficient sleep is unfavorable
- very long sleep can correlate with risk (U-shape direction)
- lower SE is worse
- higher WASO is worse
- SRI concept as 24h-apart sleep/wake matching probability

Heuristic/product mapping:

- exact piecewise breakpoints and score slopes for Duration/SE/WASO
- clamping choice for very long sleep (`>11h -> 60`)
- continuity subweighting at 50/50

## Known limitations

- SRI depends on available canonical stage timeline coverage; sparse/missing stage days reduce availability.
- `night_date` is UTC-day keyed in current pipeline, while some UI date handling is local-day keyed.
- Statistics hub currently consumes aggregate score outputs only; it does not expose component-level attribution.

## References placeholder

- Add epidemiology and sleep-regularity references here when repository citation style is finalized.
