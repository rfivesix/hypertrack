# Sleep Module Batch 2 — Day Experience Vertical Slice

## What was implemented

This batch delivers a cohesive Day sleep UX vertical slice:

- Day Overview hub screen with:
  - segmented control (day/week/month toggle shell; day behavior implemented),
  - stage timeline block,
  - sleep quality score card (ring + status label + subtitle),
  - metric tile grid (Duration, Heart rate, Regularity, Depth, Interruptions).
- Full detail-screen set:
  - Duration detail with benchmark visualization and explanatory copy.
  - Heart-rate detail with baseline-relative context and neutral baseline-missing behavior.
  - Interruptions detail with count + total wake duration.
  - Depth detail with stage distribution and confidence-aware fallback.
  - Regularity detail with 7-night range chart and midnight-wrap handling utilities.
- Centralized Sleep navigation helper using named routes.
- Provider-style state management for the day screen using `SleepDayViewModel`.

## Screen architecture and navigation flow

### Day hub

- `SleepDayOverviewPage` owns Day UX composition.
- It is backed by `SleepDayViewModel` (`ChangeNotifier`) which calls a repository interface (`SleepDayDataRepository`).
- The page gracefully handles loading and empty states.
- Tile taps route through `SleepNavigation` helper to named routes:
  - `/sleep/day/duration`
  - `/sleep/day/heart-rate`
  - `/sleep/day/regularity`
  - `/sleep/day/depth`
  - `/sleep/day/interruptions`

### Detail screens

All detail pages use one shared shell:

- `SleepDetailPageShell` provides:
  - shared header hierarchy (title/value/status/subtitle),
  - consistent padding/section spacing.
- Shared fallback pattern:
  - `SleepDataUnavailableCard` is used for missing/insufficient data states.

## Data dependencies and ownership boundaries

### Repository-facing Day model

- `SleepDayRepository` composes `SleepDayOverviewData` from:
  - `SleepNightlyAnalysesDao` (derived analysis records),
  - canonical session/stage/heart-rate DAOs.
- UI consumes only the Day repository output (`SleepDayOverviewData`) through the view model.

### Derived model usage

- `NightlySleepAnalysis` remains the core derived nightly model and was extended with additional optional fields needed by Day/detail UI:
  - total sleep minutes,
  - HR baseline context,
  - interruptions fields,
  - stage-duration fields,
  - stage sufficiency flag,
  - regularity nights payload.

### Ownership discipline

- UI/presentation does **not** implement canonical repair, scoring, baseline derivation policy definitions, or interruption definitions as source-of-truth logic.
- The UI reads repository/derived outputs and only formats for display.
- Fallback rendering paths are explicit and safe for absent/partial outputs.

## Why each UI structure/fallback was chosen

- **Segmented control:** keeps UX aligned with target IA while deferring non-Day rendering scope.
- **Timeline block:** compact visual of stage sequencing; reads canonical-derived segments only.
- **Score card with semantic color:** maps good/average/poor/unavailable to clear statuses.
- **Metric tiles:** high-scannability and explicit drill-down affordance.
- **Shared detail shell:** enforces cohesion and avoids one-off page structure drift.
- **Data unavailable card:** reusable neutral fallback pattern for low-confidence/missing data without crashes.

## Edge cases handled

- Day with no analysis row → empty card state.
- Detail routes without overview payload → unavailable fallback card.
- Missing HR baseline or sparse history → neutral baseline-not-established messaging.
- Missing/low-confidence stage data for depth → confidence fallback UI.
- Interruptions computed from qualifying wake segments only from repository-composed data.
- Regularity chart midnight wrap handled via utility:
  - `unwrapWakeMinutes()`
  - plus circular average for summary rows.

## Shared detail-shell design decisions

- Single shell widget enforces:
  - shared section hierarchy,
  - consistent status indicator treatment,
  - uniform spacing.
- Benchmark visualization (`SleepBenchmarkBar`) is reusable for duration and heart-rate details.

## Tests added

- `test/features/sleep/presentation/sleep_day_navigation_test.dart`
  - day overview tile navigation to detail screens,
  - empty-state rendering safety.
- `test/features/sleep/presentation/regularity_chart_math_test.dart`
  - midnight-wrap utility behavior,
  - circular average around midnight.

## Limitations / deferred work

- Week/month UI content remains deferred (segmented control shell only).
- Full localization pass intentionally deferred; copy uses inline strings for now.
- Statistics-tab integration entrypoint is not expanded in this batch.
- End-to-end UI tests beyond focused widget/unit coverage are deferred.
- Repository baseline/regularity heuristics are intentionally conservative and may be refined in later analysis-specific issues.

## Follow-up dependencies

- Week/month sleep overview implementations.
- Broader statistics and app-shell integration work.
- Localization issue for all Sleep copy.
- E2E test expansion and visual-regression snapshots.
