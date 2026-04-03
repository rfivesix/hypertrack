# Statistics Module — Current Implementation (Code-Audited)

This document is implementation-grounded and reflects the **current working copy**.

## Module boundaries

Statistics currently spans two kinds of behavior:

1. Workout/body analytics (core statistics domains)
2. Integration cards for Steps and Sleep inside the hub

Boundaries in code:

- Statistics owns workout/body analytics composition and drill-down navigation.
- Steps logic is owned by the Steps feature and services.
- Sleep logic is owned by the Sleep feature and services.

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

## Hub sections currently implemented

`StatisticsHubScreen` renders sections in this order:

1. Time-range chips (`7d`, `30d`, `3m`, `6m`, `All`)
2. Steps (only if steps tracking enabled)
3. Recovery
4. Sleep (only if sleep tracking enabled)
5. Consistency
6. Performance records
7. Volume/muscles
8. Body/nutrition

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

## Range handling (implemented)

Policy service:

- `lib/features/statistics/domain/statistics_range_policy.dart`

Supported semantics:

- `selected`, `fixed`, `capped`, `dynamicAll`

Metric windows currently configured:

- Hub weekly volume: fixed 6 weeks
- Hub workouts/week: fixed 6 weeks
- Hub consistency metrics: fixed 6 weeks
- Consistency weekly metrics: fixed 12 weeks
- Consistency calendar: fixed 120 days
- Hub notable PR improvements: capped to 90 days
- PR notable improvements: selected range (`7/30/90` in PR screen)
- Muscle analytics: selected days; weeks resolved via policy (`4..16` clamp)
- Body/nutrition trend + insight KPI: `dynamicAll`

### Steps + Sleep hub range behavior

Implemented behavior in `StatisticsHubScreen._loadHubAnalytics()`:

- Selected chip index is resolved with `StatisticsMetricId.bodyNutritionTrend`.
- `earliestAvailableDay` passed to that resolve call comes from **steps** repository (`_stepsRepository.getEarliestAvailableDate()`).
- Resulting `daysBack` is used for both:
  - steps range aggregation
  - sleep hub summary fetch

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

## Integration boundaries (explicit)

Statistics does **not** own or compute:

- Sleep timeline repair
- Sleep nightly metrics
- Sleep score algorithm
- Sleep permission/import orchestration
- Steps sync/import orchestration

Those are owned by feature modules/services under:

- Sleep: `lib/features/sleep/**`
- Steps: `lib/features/steps/**` and `lib/services/health/**`

## Current limitations and ambiguities

### Implemented limitations

- Hub and drill-down analytics screens fetch separately; no shared runtime cache is wired.
- `StatisticsStateContainer` exists but is currently a structural stub (`lib/features/statistics/statistics_state_container.dart`).
- Sleep integration in Statistics is hub-card-only; no dedicated Sleep analytics drill-down inside `lib/screens/analytics/*`.

### Implemented-in-current-working-copy notes

- Sleep detail behavior referenced by Statistics entry is impacted by local working-copy changes in sleep presentation/repository files; this documentation treats that as current truth for this audit.

### Currently ambiguous from code

- `StatisticsHubScreen` contains provider display-name branches for `withings`, `garmin`, and `fitbit`, but the active `StepsProviderFilter` enum currently exposes only `all`, `apple`, `google`. This appears transitional and is ambiguous as settled architecture.

## File map

- Hub: `lib/screens/statistics_hub_screen.dart`
- Drill-down analytics: `lib/screens/analytics/*`
- Range policy: `lib/features/statistics/domain/statistics_range_policy.dart`
- Hub adapter: `lib/features/statistics/data/statistics_hub_data_adapter.dart`
- Steps integration repo: `lib/features/steps/data/steps_aggregation_repository.dart`
- Sleep integration repo: `lib/features/sleep/data/sleep_hub_summary_repository.dart`
