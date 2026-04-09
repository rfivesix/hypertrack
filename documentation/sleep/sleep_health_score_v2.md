# Sleep Health Score V2 (Current Canonical Implementation)

This document describes the implemented V2 Sleep Health Score in the current working copy.

## Scope

Implemented in:

- `lib/features/sleep/domain/scoring/sleep_scoring_engine.dart`
- `lib/features/sleep/domain/metrics/sleep_regularity_index.dart`
- `lib/features/sleep/data/processing/sleep_pipeline_service.dart`

Persisted in:

- `sleep_nightly_analyses` (`lib/data/drift_database.dart`)

Analysis version string:

- `sleep-health-score-v2`

## Top-level formula

V2 uses only three top-level components:

- Duration (TST): `40%`
- Continuity (SE + WASO): `35%`
- Regularity (SRI): `25%`

Top-level renormalization over available components:

- `W = sum(weight_i for available components)`
- `score = sum(weight_i * componentScore_i) / W`
- if `W == 0`, score is unavailable (`null`)

## Stage/depth guardrail (implemented)

After computing the renormalized top-level score, V2 applies a conservative
stage-aware cap when stage composition is available:

- Stage depth quality (`0..100`) is estimated from light/deep/REM mix plus
  stage-confidence/source-fidelity hints.
- Nights dominated by light sleep receive lower depth quality.
- Missing REM cannot produce near-perfect depth quality, with additional
  conservatism when source fidelity is limited/ambiguous.
- Final score is capped by: `60 + 0.4 * stageDepthQuality`.

This is a guardrail (confidence-aware ceiling), not a fourth weighted
top-level component.

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

### Duration score (TST) — V2 exact mapping

Input: hours of sleep (`durationMinutes / 60`)

- `7.0 .. 9.0` => `100`
- `6.5 .. <7.0` => linear `80 -> 100`
- `6.0 .. <6.5` => linear `50 -> 80`
- `5.5 .. <6.0` => linear `20 -> 50`
- `5.0 .. <5.5` => linear `5 -> 20`
- `4.0 .. <5.0` => linear `0 -> 5`
- `<=4.0` => `0`
- `>9.0 .. 10.0` => linear `100 -> 90`
- `>10.0 .. 11.0` => linear `90 -> 70`
- `>11.0` => clamped `50`

Interpretation goals encoded by this mapping:

- Broad near-perfect plateau from `7h` to `9h`
- Clearly lower scores for `6h..7h`
- Strong penalty below `6h`
- Milder long-sleep penalty than short-sleep penalty

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
- regularity missing: `0.75`
- continuity missing: `0.65`
- no components: `0.0` (score unavailable)

This is a data completeness indicator, not a certainty metric.

## Explicit exclusions from V2 main score

The following are not used in V2 score computation:

- sleep stage percentages/depth as a weighted top-level component
- SOL
- heart-rate and HRV metrics/deltas
- interruption count as a standalone component (continuity uses WASO directly)

## Persistence fields used by V2

From `sleep_nightly_analyses`:

- `analysis_version` (`sleep-health-score-v2`)
- `score`
- `score_completeness`
- `total_sleep_minutes`
- `sleep_efficiency_pct`
- `interruptions_wake_minutes` (WASO)
- `regularity_sri`
- `regularity_valid_days`
- `regularity_is_stable`

## Evidence-backed vs heuristic

Evidence-backed design direction:

- insufficient sleep is unfavorable
- very long sleep can correlate with risk (U-shape direction)
- lower SE is worse
- higher WASO is worse
- SRI concept as 24h-apart sleep/wake matching probability

Heuristic/product choices (explicit and transparent):

- top-level weights (`40/35/25`)
- exact piecewise breakpoints and slopes for Duration/SE/WASO
- clamping choice for very long sleep (`>11h -> 50`)
- continuity subweighting at `50/50`

## Why stages/HR/HRV remain excluded from main score

V2 intentionally keeps the main score limited to Duration + Continuity + Regularity to preserve:

- clear interpretability
- robust behavior with partial data
- comparability across devices where stage/HR/HRV quality differs

Stage depth and HR signals remain available for detailed drill-down and future model iterations, but are not direct top-level V2 score inputs.

## Known limitations

- SRI depends on available canonical stage timeline coverage; sparse/missing stage days reduce availability.
- `night_date` is UTC-day keyed in current pipeline, while some UI date handling is local-day keyed.
- Statistics hub currently consumes aggregate score outputs only; it does not expose component-level attribution.

## References placeholder

- Add epidemiology and sleep-regularity references here when repository citation style is finalized.
