# Statistics Module — Source of Truth (v0.7 Refactor Complete)

Implementation-grounded reference for the current Statistics module.  
Scope is **what exists now in code**.

---

## Purpose and boundaries

The Statistics module is a read-only analytics layer over workouts, body measurements, and nutrition/fluid logs.

- No analytics data is persisted as its own storage entity.
- Screens load from database helpers/adapters and render derived payloads.
- Hub and drill-down screens are intentionally separate views.

---

## Architecture (implementation facts)

### Layering in use

| Layer | Current components |
| :--- | :--- |
| Presentation | `lib/screens/statistics_hub_screen.dart`, `lib/screens/analytics/*`, shared widgets (`AnalyticsSectionHeader`, `AnalyticsChartDefaults`, `MuscleRadarChart`, `SummaryCard`) |
| Feature domain | `lib/features/statistics/domain/*` (range policy, quality policy, payloads, domain services, analytics state envelope) |
| Feature data adapters | `lib/features/statistics/data/*` (`StatisticsHubDataAdapter`, `BodyNutritionAnalyticsDataAdapter`) |
| Core persistence | `lib/data/workout_database_helper.dart`, `lib/data/database_helper.dart`, `lib/data/product_database_helper.dart` |

### Core flow

`StatisticsHubScreen` delegates hub loading to `StatisticsHubDataAdapter.fetch()`, which composes parallel queries and returns:

- `StatisticsHubPayload` (typed hub aggregate + remaining map-backed slices)
- `BodyNutritionAnalyticsResult`

Drill-down screens still load independently (no shared provider cache yet).

---

## Screen responsibilities (implementation facts)

| Screen | File | Responsibility |
| :--- | :--- | :--- |
| Statistics Hub | `lib/screens/statistics_hub_screen.dart` | Entry portal with compact summaries for consistency, performance, muscle volume, recovery, and body/nutrition + drill-down navigation |
| PR Dashboard | `lib/screens/analytics/pr_dashboard_screen.dart` | Recent PRs, all-time PRs, rep-bracket PRs, notable e1RM improvements |
| Consistency Tracker | `lib/screens/analytics/consistency_tracker_screen.dart` | KPI cards, weekly metric bars (volume/duration/frequency), fixed-window calendar density |
| Muscle Group Analytics | `lib/screens/analytics/muscle_group_analytics_screen.dart` | Equivalent-set distribution/frequency/weekly breakdown and guidance text |
| Body/Nutrition Correlation | `lib/screens/analytics/body_nutrition_correlation_screen.dart` | Weight + calories trend, KPI summary, insight labeling, confidence gating |
| Recovery Tracker | `lib/screens/analytics/recovery_tracker_screen.dart` | Overall readiness state, per-muscle recovery cards, recovery pressure radar |

### Hub philosophy and drill-down roles (UX intent)

- **Hub:** fast orientation and navigation (compact signals, no full analytical depth).
- **Drill-downs:** metric-specific analysis and context.
- The same analytics domain appears at two depths: quick scan on hub, detailed reading on dedicated screens.

---

## Shared range policy semantics

Range behavior is centralized in `StatisticsRangePolicyService` (`lib/features/statistics/domain/statistics_range_policy.dart`).

### Supported semantics

| Semantic | Behavior |
| :--- | :--- |
| `selected` | Uses user-selected range |
| `fixed` | Uses fixed window regardless of chip selection |
| `capped` | Uses selected range capped by metric maximum |
| `dynamicAll` | Uses selected range except “All”, where range expands to earliest data → today |

### Metric windows currently implemented

| Metric ID | Effective behavior |
| :--- | :--- |
| `hubWeeklyVolume` | fixed 6 weeks |
| `hubWorkoutsPerWeek` | fixed 6 weeks |
| `hubConsistencyMetrics` | fixed 6 weeks |
| `consistencyWeeklyMetrics` | fixed 12 weeks |
| `consistencyCalendar` | fixed 120 days |
| `hubNotablePrImprovements` | capped 90 days |
| `prNotableImprovements` | selected 7/30/90 days |
| `hubMuscleAnalytics` | selected days + fixed 8-week context |
| `muscleAnalytics` | selected days, with weeks resolved from days and clamped `4..16` |
| `bodyNutritionTrend` / `bodyNutritionInsightKpi` | `dynamicAll` semantics |

**Contributor note:** this mixed policy is intentional and should be disclosed in UX text where needed (for example fixed 6-week/12-week chips shown in consistency sections).

---

## Data quality semantics (heuristics/rules)

Data sufficiency logic is centralized in `StatisticsDataQualityPolicy` (`lib/features/statistics/domain/statistics_data_quality_policy.dart`).

### Body/Nutrition insight quality

Insight confidence is sufficient only when all are true:

- `spanDays >= 14`
- `totalDays >= 14`
- `weightDays >= 5`
- `loggedCalorieDays >= 7`

Used by `BodyNutritionAnalyticsEngine` and surfaced via `BodyNutritionAnalyticsResult.insightDataQuality`.

### Muscle distribution quality

Quality is sufficient when:

- `dataPointDays >= 3`
- `spanDays >= 14`

Used to soften guidance copy when data is sparse.

---

## Typed payload/model usage (implementation facts)

Current typed models in active use:

- `TrainingStatsPayload`
- `WeeklyConsistencyMetricPayload`
- `RecoveryTotalsPayload`
- `RecoveryMusclePayload`
- `RecoveryAnalyticsPayload`
- `StatisticsHubPayload`
- `DailyValuePoint`
- `BodyNutritionAnalyticsResult`
- `AnalyticsState<T>` (state envelope type)

Remaining map-backed slices are still present for some analytics collections (notably PR and muscle rows), but typed payloads now cover the core consistency/recovery/body-nutrition paths and hub aggregate contract.

---

## Shared presentation and chart conventions

### Shared formatter contract

`StatisticsPresentationFormatter` provides consistent display behavior for:

- weight formatting
- compact number formatting
- recovery labels/colors
- body/nutrition insight labels
- muscle guidance labels
- filtering of synthetic “Other” category labels for user-facing views

### Chart conventions in current implementation

- `fl_chart` for line/bar charts
- `table_calendar` for consistency calendar
- `MuscleRadarChart` for radar visualizations
- horizontal progress bars for distribution summaries
- sparse x-axis labeling and compact y-axis formatting for dense weekly views

Body/nutrition smoothing currently follows:

- weight trend: 5-point moving average when enough data, otherwise 3-point
- calories trend: 7-point moving average when enough data, otherwise 3-point

---

## Known current limitations (implementation facts)

- Hub and drill-down screens still perform independent fetches.
- `StatisticsStateContainer` exists as phase-1 structure, but is not yet wired as shared runtime state.
- Recovery pressure scoring is domain-service driven and presentation-integrated, separate from persistence.
- Some hub mini-views intentionally summarize data differently from full drill-down charts.

---

## File map

- Hub: `lib/screens/statistics_hub_screen.dart`
- Drill-downs: `lib/screens/analytics/*`
- Feature data: `lib/features/statistics/data/*`
- Feature domain: `lib/features/statistics/domain/*`
- Feature presentation formatter: `lib/features/statistics/presentation/statistics_formatter.dart`

---

*Last updated: 2026-03-21 (post-refactor implementation sync).*
