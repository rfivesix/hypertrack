# Sleep Module Final Product-Completion Batch (#182–#187)

> Status: Historical batch snapshot.  
> For current implemented behavior, use [sleep_current_state.md](sleep_current_state.md).

## What was implemented

This batch completes the remaining user-facing Sleep module product work for alpha readiness:

- Real **Week** overview screen (`/sleep/week`) with:
  - weekly mean score,
  - weekday vs weekend average duration,
  - vertical sleep-window visualization per day,
  - daily score strip with day tap-through to Day view.
- Real **Month** overview screen (`/sleep/month`) with:
  - monthly mean score,
  - weekday vs weekend average duration,
  - calendar grid with score-state chips,
  - day tap-through to Day view.
- Statistics integration widened from a single day-only entry to explicit Day/Week/Month entry points, while keeping business logic in `features/sleep`.
- Settings/permission/sync UX copy and state labels localized and clarified for:
  - no permission,
  - partial permission,
  - unavailable/not-installed,
  - granted-but-no-data-yet guidance.
- New aggregation tests and expanded presentation tests for week/month rendering and navigation.

## Week/Month architecture

### Data ownership and boundaries

- UI consumes only sleep-owned outputs:
  - `SleepQueryRepository.getAnalysesInRange(...)` (derived nightly analyses),
  - domain aggregation outputs in `features/sleep/domain/aggregation`.
- Week/month presentation does **not** access canonical/raw tables directly.
- Statistics screen only links to Sleep routes and does not compute sleep business logic.

### Aggregation layer

- Added `SleepPeriodAggregationEngine` to compute:
  - period mean score,
  - weekday/weekend average durations,
  - day buckets with score + quality + duration,
  - week vertical-window geometry from derived nightly duration.
- Added thin wrappers:
  - `weekly_aggregation.dart`
  - `monthly_aggregation.dart`

## Settings / sync / permission UX flow

- Sleep settings section now uses localized copy for all visible Sleep controls and state labels.
- Status guidance explicitly distinguishes:
  - **No permission** (denied/partial),
  - **Feature unavailable** (unavailable/not installed),
  - **Data status** when permissions are ready but imports may still be needed.
- Manual import and raw import viewer remain available; raw/debug affordances remain secondary to primary flow.

## Provider/repository/derived outputs consumed

- `SleepQueryRepository` (derived-only query surface) is the source for week/month analyses.
- `NightlySleepAnalysis` now includes `totalSleepMinutes` for derived-duration aggregation.
- Week/month pages aggregate and render only derived outputs.

## Shared navigation design

- `SleepNavigation` now supports date-anchored deep links:
  - `openDayForDate(...)`
  - `openWeekForDate(...)`
  - `openMonthForDate(...)`
- Day segmented scope now navigates to real week/month routes.
- Week/month segmented scope switches route consistently between day/week/month.

## Fallback states handled

- Sparse weeks/months render safely with missing days.
- Empty weeks/months render summary and explicit unavailable cards.
- Missing score/duration values are rendered with neutral placeholders (`--`) and neutral chip colors.
- Settings status still handles denied/partial/unavailable/not-installed/technical-error states.

## Localization and UI consistency decisions

- Added localized Sleep strings to `app_en.arb` and `app_de.arb`.
- Wired these into:
  - statistics sleep section,
  - week/month screens,
  - shared period scope controls,
  - sleep settings/sync/permission section,
  - sleep state placeholder routes.
- Reused existing app patterns:
  - `GlobalAppBar`
  - `SummaryCard`
  - existing spacing/radius tokens from `DesignConstants`

## Tests added/expanded

- `test/features/sleep/domain/aggregation/sleep_period_aggregations_test.dart`
  - weekly mean + weekday/weekend duration aggregation,
  - sparse/empty month behavior,
  - latest-derived-row selection for duplicate wake dates.
- `test/features/sleep/presentation/sleep_day_navigation_test.dart` (expanded)
  - day -> week/month scope navigation,
  - sparse week/month screen rendering safety.

## Remaining deferred (post-alpha)

- Further visual polish for week sleep-window semantics if/when additional derived timing fields become available.
- Additional localization sweep for older hardcoded copy in legacy day/detail screens not directly part of this batch’s core completion path.
