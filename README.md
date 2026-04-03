# Hypertrack

Hypertrack is an offline-first Flutter app for workout, nutrition, measurements, steps, sleep, and one-way health-platform export.

This README is intentionally implementation-focused and reflects the **current working copy** of the codebase. Planned work toward `1.0` is listed separately and is **not** described as implemented behavior.

## Documentation

- [Project Overview](documentation/overview.md)
- [Statistics Module (Current Implementation)](documentation/statistics_module.md)
- [Sleep Module (Current Source of Truth)](documentation/sleep/sleep_current_state.md)
- [Sleep Health Score V2 (Current Canonical)](documentation/sleep/sleep_health_score_v2.md)
- [Release Notes 0.7.3](documentation/release_notes_0.7.3.md)
- [System Architecture](documentation/architecture.md)
- [Data Models & Storage](documentation/data_models_and_storage.md)
- [UI & Widgets](documentation/ui_and_widgets.md)
- [Health Steps Module (Current Implementation)](documentation/health_steps_alpha.md)
- [One-way Health Export (Current Implementation)](documentation/health_export_one_way.md)
- [Shared Analytics Definitions (Legacy Reference)](documentation/analytics_definitions.md)

## Current app shell (implemented)

- Entry: `lib/main.dart` -> `AppInitializerScreen`
- Main tabs (`lib/screens/main_screen.dart`):
  1. Diary
  2. Workout
  3. Statistics
  4. Nutrition
- Sleep named routes are registered via `MaterialApp.onGenerateRoute = SleepNavigation.onGenerateRoute` in `lib/main.dart`.

## Current health integrations (implemented)

### Steps
- Settings + sync: `lib/services/health/steps_sync_service.dart`
- Aggregation repo: `lib/features/steps/data/steps_aggregation_repository.dart`
- UI:
  - Statistics hub card
  - Diary summary card
  - Dedicated screen: `lib/features/steps/presentation/steps_module_screen.dart`

### Sleep
- Settings + permissions + sync: `lib/features/sleep/platform/sleep_sync_service.dart`
- Pipeline: `lib/features/sleep/data/processing/sleep_pipeline_service.dart`
- UI:
  - Statistics hub sleep card
  - Diary sleep summary card
  - Sleep day/week/month scoped page
  - Sleep detail pages

### One-way health export
- Export-only integration from Hypertrack to:
  - Apple Health
  - Google Health Connect
- Current supported export domains:
  - measurements
  - aggregate nutrition
  - hydration
  - session-level workouts
- Current module:
  - shared export orchestration: `lib/health_export/`
  - platform bridges:
    - iOS HealthKit export
    - Android Health Connect export
- Current UX:
  - settings toggles
  - permission flows
  - per-domain export status
  - manual export trigger

## Statistics / Sleep integration (implemented)

- Statistics hub (`lib/screens/statistics_hub_screen.dart`) includes:
  - Steps section (gated by steps tracking enabled)
  - Sleep section (gated by sleep tracking enabled)
  - Core workout/body analytics sections:
    - recovery
    - consistency
    - performance
    - muscle volume
    - body/nutrition
- Sleep card in Statistics opens `/sleep/day`
- Steps card in Statistics opens `StepsModuleScreen`

## Current product boundaries

### Implemented
- Workout tracking
- Nutrition tracking
- Measurement tracking
- Steps import and aggregation
- Sleep import, processing, and scoring
- One-way export to Apple Health / Health Connect

### Explicit non-goals of the current health-platform integration
- No back-sync/import from Apple Health or Health Connect into Hypertrack
- No bidirectional merge/conflict handling
- No ingredient-level meal export
- No detailed workout-structure export (sets/exercises/RIR/supersets as structured health-platform data)

## Current defaults

- Sleep tracking defaults to disabled in settings (`sleep_tracking_enabled` default `false`)
- Steps tracking defaults to enabled (`steps_tracking_enabled` default `true`)

## Near-term work toward 1.0 (planned, not yet guaranteed in current working copy)

- Adaptive calorie target / TDEE guidance
  - goal selection
  - weekly target rate
  - recommendation from intake + weight trend
- Further health export hardening / refinement where needed
- Additional nutrition guidance polish and MVP completion work
- Widgets
## License

[MIT](LICENSE)