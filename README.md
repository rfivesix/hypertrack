# Hypertrack

Hypertrack is an offline-first Flutter app for workout, nutrition, measurements, steps, and sleep tracking.

This README is intentionally implementation-focused and reflects the **current working copy** of the codebase.

## Documentation

- [Project Overview](documentation/overview.md)
- [Statistics Module (Current Implementation)](documentation/statistics_module.md)
- [Sleep Module (Current Source of Truth)](documentation/sleep/sleep_current_state.md)
- [Sleep Health Score V1](documentation/sleep/sleep_health_score_v1.md)
- [System Architecture](documentation/architecture.md)
- [Data Models & Storage](documentation/data_models_and_storage.md)
- [UI & Widgets](documentation/ui_and_widgets.md)

Historical sleep implementation notes (not canonical for current behavior):
- [Sleep Foundation Batch](documentation/sleep/sleep_foundation_batch.md)
- [Sleep Day Batch 2](documentation/sleep/sleep_day_batch_2.md)
- [Sleep Final Product Batch](documentation/sleep/sleep_final_product_batch.md)
- [Sleep Issue Audit #156–#175](documentation/sleep/sleep_issue_audit_156_175.md)

## Current app shell (implemented)

- Entry: `lib/main.dart` -> `AppInitializerScreen`
- Main tabs (`lib/screens/main_screen.dart`):
1. Diary
2. Workout
3. Statistics
4. Nutrition
- Sleep named routes are registered via `MaterialApp.onGenerateRoute = SleepNavigation.onGenerateRoute` in `lib/main.dart`.

## Current health integrations (implemented)

- Steps:
  - Settings + sync: `lib/services/health/steps_sync_service.dart`
  - Aggregation repo: `lib/features/steps/data/steps_aggregation_repository.dart`
  - UI: Statistics hub card, Diary summary card, dedicated screen `lib/features/steps/presentation/steps_module_screen.dart`
- Sleep:
  - Settings + permissions + sync: `lib/features/sleep/platform/sleep_sync_service.dart`
  - Pipeline: `lib/features/sleep/data/processing/sleep_pipeline_service.dart`
  - UI: Statistics hub sleep card, Diary sleep summary card, Sleep day/week/month scoped page + detail pages

## Statistics/Sleep integration (implemented)

- Statistics hub (`lib/screens/statistics_hub_screen.dart`) includes:
  - Steps section (gated by steps tracking enabled)
  - Sleep section (gated by sleep tracking enabled)
  - Core workout/body analytics sections (recovery, consistency, performance, muscle volume, body/nutrition)
- Sleep card in Statistics opens `/sleep/day`.
- Steps card in Statistics opens `StepsModuleScreen`.

## Notes

- Sleep tracking defaults to disabled in settings (`sleep_tracking_enabled` default `false`).
- Steps tracking defaults to enabled (`steps_tracking_enabled` default `true`).

## License

[MIT](LICENSE)
