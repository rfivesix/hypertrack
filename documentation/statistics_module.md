# Statistics Module

This document is implementation-grounded and reflects current behavior.

## Module boundaries

Statistics currently spans two kinds of behavior:

1. Workout/body analytics (core statistics domains)
2. Integration cards for Steps, Sleep, and opt-in Pulse inside the hub

Boundaries in code:

- Statistics owns workout/body analytics composition and drill-down navigation.
- Steps logic is owned by the Steps feature and services.
- Sleep logic is owned by the Sleep feature and services.
- Pulse logic is owned by the Pulse feature and platform heart-rate service.

## Entry points and navigation

Primary entry point:

- Main tab index 2 in `lib/screens/main_screen.dart` -> `StatisticsHubScreen`

Hub screen:

- `lib/screens/statistics_hub_screen.dart`

Drill-down routes pushed from hub:

- Consistency -> `lib/screens/analytics/consistency_tracker_screen.dart`
- PR dashboard -> `lib/screens/analytics/pr_dashboard_screen.dart`
- Muscle analytics -> `lib/screens/analytics/muscle_group_analytics_screen.dart`
- Recovery tracker -> `lib/screens/analytics/recovery_tracker_screen.dart`
- Body/nutrition correlation -> `lib/screens/analytics/body_nutrition_correlation_screen.dart`

Cross-feature links from hub:

- Steps card tap -> `StepsModuleScreen` (`lib/features/steps/presentation/steps_module_screen.dart`)
- Sleep card tap -> `SleepNavigation.openDay(context)` -> `/sleep/day`
- Pulse card tap -> `PulseAnalysisScreen` (`lib/features/pulse/presentation/pulse_analysis_screen.dart`)

## Hub sections currently implemented

`StatisticsHubScreen` renders sections in this order:

1. Time-range chips (`7d`, `30d`, `3m`, `6m`, `All`)
2. Steps (only if steps tracking enabled)
3. Recovery
4. Sleep (only if sleep tracking enabled)
5. Pulse (only if pulse analysis is enabled)
6. Consistency
7. Performance records
8. Volume/muscles
9. Body/nutrition

## Data sources actually used

### Core statistics payloads

- Adapter: `lib/features/statistics/data/statistics_hub_data_adapter.dart`
- Primary persistence source: `lib/data/workout_database_helper.dart`
- Body/nutrition builder path: `BodyNutritionAnalyticsUtils.build(...)` in `lib/util/body_nutrition_analytics_utils.dart`

### Steps card integration

- Repo: `lib/features/steps/data/steps_aggregation_repository.dart`
- Tracking/provider settings: `lib/services/health/steps_sync_service.dart`
- Daily goal source: `DatabaseHelper.getCurrentTargetStepsOrDefault()` in `lib/data/database_helper.dart`

### Sleep card integration

- Summary repo: `lib/features/sleep/data/sleep_hub_summary_repository.dart`
- Tracking setting source: `SleepSyncService.isTrackingEnabled()`

### Pulse card integration

- Settings/source: `lib/features/pulse/application/pulse_tracking_service.dart`
- Analysis repo: `lib/features/pulse/data/pulse_repository.dart`
- Engine: `lib/features/pulse/domain/pulse_analysis_engine.dart`
- Platform HR bridge: `lib/services/health/health_platform_heart_rate.dart`

## Range handling (implemented)

Policy service:

- `lib/features/statistics/domain/statistics_range_policy.dart`

Supported semantics:

- `selected`, `fixed`, `capped`, `dynamicAll`

Metric windows currently configured:

- Hub weekly volume: fixed 6 weeks
- Hub workouts/week: fixed 6 weeks
- Hub consistency metrics: fixed 6 weeks
- Hub recovery/readiness: fixed 14-day current-state lookback
- Consistency weekly metrics: fixed 12 weeks
- Consistency calendar: fixed 120 days
- Hub notable PR improvements: capped to 90 days
- PR notable improvements: selected range (`7/30/90` in PR screen)
- Muscle analytics: selected days; weeks resolved via policy (`4..16` clamp)
- Body/nutrition trend + insight KPI: `dynamicAll`

### Recovery range behavior

Recovery is intentionally treated as a current-state metric, not a normal
historical chart. The hub and recovery tracker use
`RecoveryDomainService.recoveryLookbackDays` (currently 14 days) to find recent
significant muscle loads. Selecting `6m` or `All` in the Statistics hub must not
make readiness depend on stale historical workouts.

Disclosure hook: `range:fixed-current-recovery-14d`.

## Recovery/readiness heuristic

Recovery is a transparent training-log heuristic for planning. It is not a
physiological diagnosis, clinical recovery prediction, injury assessment, or a
replacement for subjective readiness, soreness, sleep, injury status, or
coaching judgment.

Current implementation:

- Significant muscle load threshold:
  `RecoveryDomainService.minimumSignificantEquivalentSets = 1.0`.
- Completed, non-warmup, rep-based strength sets count for muscle recovery even
  when `weight` is null or `0`, so bodyweight work such as push-ups, pull-ups,
  dips, squats, lunges, rows, and calisthenics can affect readiness.
- Added-weight bodyweight sets count normally.
- Obvious cardio set/exercise categories and names are excluded from muscle
  recovery stimulus, even when a catalog entry has muscle mappings.
- Equivalent sets use the existing coarse mapping: primary muscles receive
  `1.0`, secondary muscles receive `0.5`.
- A muscle session below `1.0` equivalent sets does not reset the recovery
  clock.
- High session fatigue is detected when average `RIR <= 0.5` or average
  `RPE >= 8.5`; this currently adds 24 hours to both recovery boundaries.
- Load-based boundary extension uses last-session equivalent sets:
  `1.0-2.99: +0h`, `3.0-4.99: +6h`, `5.0-7.99: +12h`,
  `8.0-10.99: +24h`, `>= 11.0: +36h`.
- Muscle-specific base windows are simple product heuristics:
  fast groups such as delts, biceps, triceps, forearms, and calves use
  `36h/60h`; default groups such as chest, lats, upper back, traps, abs, and
  core use `48h/72h`; larger lower-body groups such as quads, hamstrings,
  glutes, and adductors use `60h/96h`; lower back/spinal erectors use
  `72h/120h`.
- State boundaries are inclusive: at exactly the recovering upper boundary the
  muscle is still `recovering`; at exactly the ready upper boundary it is still
  `ready`.
- The status badge is the primary current readiness state.
- The visible per-muscle readiness score is current-state progress through the
  effective window: low while recovering, around `60` at the recovering
  boundary, around `85` at the ready boundary, and approaching `100` after the
  ready window has passed.
- Last-load pressure is shown separately as recent stimulus/recovery demand. It
  uses the equivalent-set load curve calibrated for a single muscle in a
  session: `0 -> 0`, `1 -> 10`, `2 -> 18`, `3 -> 26`, `4 -> 34`,
  `5 -> 41`, `6 -> 47`, `8 -> 55`, `10 -> 60`, `12+ -> 65`, plus a small
  high-fatigue component. Pressure labels are intentionally separate from
  readiness labels.
- Effective windows displayed in the UI include the muscle profile, load-based
  extension, and intensity/RIR/RPE extension.

Known limitations:

- Secondary muscles still use coarse `0.5` mapping.
- No systemic fatigue, sleep debt, soreness, pain, injury, stress, deload, or
  training-age model is included.
- Exercise mapping changes can still affect analytics history unless historical
  mappings are explicitly snapshotted in a future schema.
- Logged set quality matters. Missing RIR/RPE, incorrect muscle mappings, or
  mislabeled cardio/strength categories can change the heuristic output.

### Steps + Sleep hub range behavior

Implemented behavior in `StatisticsHubScreen._loadHubAnalytics()`:

- Selected chip index is resolved with `StatisticsMetricId.bodyNutritionTrend`.
- `earliestAvailableDay` passed to that resolve call comes from **steps** repository (`_stepsRepository.getEarliestAvailableDate()`).
- Resulting `daysBack` is used for both:
  - steps range aggregation
  - sleep hub summary fetch
- Hub sections use independent stale-while-refresh state. Range chip changes keep existing card data visible while each section reloads, and stale section results are ignored if a newer range request has already started.
- Section-level errors are local to the affected card. A failing body/nutrition, sleep, pulse, recovery, consistency, performance, volume/muscle, or steps load should not block the rest of the hub.

Implication:

- For `All`, Steps and Sleep cards currently use a range length anchored by Steps earliest date, not Sleep earliest date.
- This is **implemented behavior**, not inferred design intent.

## Steps coverage inside Statistics

Current Steps support in Statistics includes:

- Optional section gated by steps tracking flag
- Fallback summary card when no data
- Trend card with per-day bars and goal line when data exists
- Provider label rendering (`All/Apple/Health Connect` mapped to display names)
- Tap-through into dedicated Steps module screen

No Steps drill-down is implemented inside `lib/screens/analytics/*`; it is delegated to `StepsModuleScreen`.

## Sleep coverage inside Statistics

Current Sleep support in Statistics includes:

- Optional section gated by sleep tracking flag
- Hub summary card showing:
  - mean score
  - average duration
  - average bedtime
  - average interruptions + wake duration summary when available
- Tap-through to Sleep day route (`/sleep/day`)

No Sleep calculations are performed in Statistics UI; values come from `SleepHubSummaryRepository`.
Score values consumed by Statistics are produced in the Sleep pipeline (`Sleep Health Score V2` in current implementation).

## Pulse coverage inside Statistics

Current Pulse support in Statistics includes:

- Optional section gated by `pulse_tracking_enabled` (default off)
- Tap-through to a dedicated day/week/month Pulse analysis screen
- The Pulse screen reuses the existing period switcher/navigation pattern and `MeasurementChartWidget.fromData(...)`
- Metrics shown:
  - pulse range
  - time-weighted average pulse
  - conservative resting-pulse estimate from the lowest 20% of samples

Pulse analysis reads platform heart-rate samples on demand and does not persist a new canonical pulse table in the current MVP.

## Integration boundaries (explicit)

Statistics does **not** own or compute:

- Sleep timeline repair
- Sleep nightly metrics
- Sleep score algorithm
- Sleep permission/import orchestration
- Steps sync/import orchestration
- Pulse permission/settings state
- Pulse sample aggregation

Those are owned by feature modules/services under:

- Sleep: `lib/features/sleep/**`
- Steps: `lib/features/steps/**` and `lib/services/health/**`
- Pulse: `lib/features/pulse/**` and `lib/services/health/health_platform_heart_rate.dart`

## Current limitations and ambiguities

### Implemented limitations

- Hub and drill-down analytics screens fetch separately; no shared runtime cache is wired.
- `StatisticsStateContainer` exists but is currently a structural stub (`lib/features/statistics/statistics_state_container.dart`).
- Sleep integration in Statistics is hub-card-only; no dedicated Sleep analytics drill-down inside `lib/screens/analytics/*`.

### Currently ambiguous from code

- `StatisticsHubScreen` contains provider display-name branches for `withings`, `garmin`, and `fitbit`, but the active `StepsProviderFilter` enum currently exposes only `all`, `apple`, `google`. These branches are not treated as settled architecture.

## File map

- Hub: `lib/screens/statistics_hub_screen.dart`
- Drill-down analytics: `lib/screens/analytics/*`
- Range policy: `lib/features/statistics/domain/statistics_range_policy.dart`
- Hub adapter: `lib/features/statistics/data/statistics_hub_data_adapter.dart`
- Steps integration repo: `lib/features/steps/data/steps_aggregation_repository.dart`
- Sleep integration repo: `lib/features/sleep/data/sleep_hub_summary_repository.dart`
