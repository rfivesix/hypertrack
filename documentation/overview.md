# Hypertrack: Project Overview (Current Implementation)

This document describes the app as implemented in the **current working copy**.

## Scope

Hypertrack currently implements:

- Workout tracking and analytics
- Exercise catalog refresh via release-distributed wger data artifacts
- Open Food Facts country-aware catalog refresh foundation (DE/US/UK channels)
- Nutrition/fluid logging
- Adaptive nutrition recommendation generation (weekly due-week model with explicit manual apply)
- Measurements
- Supplements
- Health steps import + aggregation
- Sleep import + derived nightly analysis + day/week/month scoped sleep UI

## App shell and navigation

Primary app flow:

```
main.dart
└── AppInitializerScreen
    ├── first launch -> OnboardingScreen -> MainScreen
    └── returning user -> MainScreen
                       ├── Tab 0: DiaryScreen
                       ├── Tab 1: WorkoutHubScreen
                       ├── Tab 2: StatisticsHubScreen
                       └── Tab 3: NutritionHubScreen
```

Implementation paths:

- App entry and route registration: `lib/main.dart`
- Main tab shell and `PageView`: `lib/screens/main_screen.dart`
- Sleep named-route generation is handled by `SleepNavigation.onGenerateRoute` in `lib/features/sleep/presentation/sleep_navigation.dart`.

## Statistics module (implemented)

Main hub: `lib/screens/statistics_hub_screen.dart`

Hub sections currently rendered (in order):

1. Time-range chips (`7d`, `30d`, `3m`, `6m`, `All`)
2. Steps (only when steps tracking is enabled)
3. Recovery
4. Sleep (only when sleep tracking is enabled)
5. Consistency
6. Performance records
7. Volume/muscles
8. Body/nutrition

Drill-down screens (all under `lib/screens/analytics/`):

- `consistency_tracker_screen.dart`
- `pr_dashboard_screen.dart`
- `muscle_group_analytics_screen.dart`
- `recovery_tracker_screen.dart`
- `body_nutrition_correlation_screen.dart`

Important boundary:

- Workout/body analytics are fetched from workout + nutrition persistence.
- Steps and Sleep are integrated into hub cards through dedicated feature repositories; Statistics does not own Sleep/Steps business logic.

## Steps module (implemented)

Core files:

- Sync/settings: `lib/services/health/steps_sync_service.dart`
- Platform bridge: `lib/services/health/health_platform_steps.dart`
- Aggregation repository: `lib/features/steps/data/steps_aggregation_repository.dart`
- Dedicated screen: `lib/features/steps/presentation/steps_module_screen.dart`

Current entry points:

- Statistics hub steps card -> `StepsModuleScreen`
- Diary day summary steps bar -> `StepsModuleScreen`

## Sleep module (implemented)

Core files:

- Sync/settings service: `lib/features/sleep/platform/sleep_sync_service.dart`
- Permissions: `lib/features/sleep/platform/permissions/*`
- Pipeline: `lib/features/sleep/data/processing/sleep_pipeline_service.dart`
- Day repository: `lib/features/sleep/data/sleep_day_repository.dart`
- Derived query repository: `lib/features/sleep/data/repository/sleep_query_repository.dart`
- Navigation/routes: `lib/features/sleep/presentation/sleep_navigation.dart`
- Day/week/month scoped UI: `lib/features/sleep/presentation/day/sleep_day_overview_page.dart`
- Detail screens: `lib/features/sleep/presentation/details/*`

Current entry points:

- Statistics hub sleep card -> `/sleep/day`
- Diary sleep summary card -> `/sleep/day` for selected date

Canonical source-of-truth for Sleep implementation details:

- `documentation/sleep/sleep_current_state.md`
- `documentation/sleep/sleep_health_score_v2.md`

## Settings integration (implemented)

Sleep and Steps settings are both in:

- `lib/screens/settings_screen.dart`

Implemented controls include:

- Steps: tracking toggle, provider filter, source policy
- Sleep: tracking toggle, permission status, request access, import now, raw import viewer
- Health export: one-way platform export toggles (Apple Health / Health Connect), permission flow, per-domain status summary, and manual export trigger

## Notes on working-copy state

- This overview follows the current checked-out source tree.

## Related docs

- [Adaptive nutrition recommendation current state](adaptive_nutrition_recommendation_current_state.md)
- [Statistics module](statistics_module.md)
- [Sleep current state](sleep/sleep_current_state.md)
- [Health export one-way](health_export_one_way.md)
- [Wger catalog refresh & distribution](wger_catalog_refresh_system.md)
- [OFF catalog refresh & distribution](off_catalog_refresh_system.md)
- [Architecture](architecture.md)
- [Data models and storage](data_models_and_storage.md)
