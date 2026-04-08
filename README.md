# Hypertrack

Hypertrack is an offline-first Flutter app for workout, nutrition, measurements, steps, sleep, supplements, and one-way health-platform export.

This README is intentionally implementation-focused and reflects the **current working copy** of the codebase. Planned work toward `1.0` is listed separately and is **not** described as implemented behavior.

> **Note:** Hypertrack is built with heavy AI assistance across implementation, refactoring, and documentation. I’m very happy with the result, but as with any fast-moving AI-assisted codebase, I cannot guarantee that every detail is perfect.
## Install

[![Get it on Obtainium](https://raw.githubusercontent.com/ImranR98/Obtainium/main/assets/graphics/badge_obtainium.png)](http://apps.obtainium.imranr.dev/redirect.html?r=obtainium://add/https://github.com/rfivesix/hypertrack/releases)
## Documentation

- [Project Overview](documentation/overview.md)
- [Adaptive Nutrition Recommendation (Current Bayesian Architecture)](docs/adaptive_nutrition_recommendation_current_state.md)
- [Statistics Module (Current Implementation)](documentation/statistics_module.md)
- [Sleep Module (Current Source of Truth)](documentation/sleep/sleep_current_state.md)
- [Sleep Health Score V2 (Current Canonical)](documentation/sleep/sleep_health_score_v2.md)
- [System Architecture](documentation/architecture.md)
- [Data Models & Storage](documentation/data_models_and_storage.md)
- [UI & Widgets](documentation/ui_and_widgets.md)
- [Health Steps Module (Current Implementation)](documentation/health_steps_alpha.md)
- [One-way Health Export (Current Implementation)](documentation/health_export_one_way.md)
- [Shared Analytics Definitions (Legacy Reference)](documentation/analytics_definitions.md)

## What Hypertrack currently supports

### Workout tracking
- Logging full workout sessions
- Exercise-by-exercise set tracking
- Support for set types such as warm-up, normal, failure, and dropset
- Tracking of reps, weight, and RIR
- Workout history and session review
- Session-level export to Apple Health and Google Health Connect

### Nutrition tracking
- Logging foods and nutrition entries
- Tracking calories and core macros
- Tracking additional nutrition fields such as fiber, sugar, and salt/sodium where available
- Optional AI-assisted meal tracking
  - BYOK (bring your own API key) only
  - user-controlled provider + model setup
  - providers: OpenAI, Gemini, Anthropic/Claude, Mistral, xAI/Grok
  - test status in current working copy: OpenAI + Gemini tested; Anthropic, Mistral, and xAI not yet end-to-end verified in this environment
  - provider-native login/billing is intentionally not implemented
- Aggregate nutrition export to Apple Health and Google Health Connect

### Measurements
- Logging body measurements and body-weight-related entries
- Tracking values over time in charts
- Export of supported measurements to Apple Health and Google Health Connect

### Supplements
- Tracking caffeine and creatine
- Support for user-defined custom supplements
- Supplement logging over time

### Steps and sleep
- Step data import and aggregation
- Sleep data import, processing, scoring, and visualization
- Sleep day/week/month views and detail screens
- Sleep statistics integration

### Statistics and analysis
- Workout and body analytics
- Performance and consistency views
- Muscle-volume-related analysis
- Body/nutrition analysis
- Sleep and steps integration in the statistics area

### Sync, export, and safety
- One-way health-platform sync/export to Apple Health and Google Health Connect
- Export of app-recorded measurements, aggregate nutrition, hydration, and session-level workouts
- CSV export
- Automatic backups
- Offline-first local data handling

## Current product boundaries

### Implemented
- Workout tracking
- Nutrition tracking
- Measurement tracking
- Supplement tracking
- Steps import and aggregation
- Sleep import, processing, and scoring
- One-way export to Apple Health / Google Health Connect
- Automatic backups
- CSV export
- Export/sync of supported app-recorded health data
- Optional AI-assisted meal tracking with user-provided API key

### Explicit non-goals of the current health-platform integration
- No back-sync/import from Apple Health or Google Health Connect into Hypertrack
- No bidirectional merge/conflict handling
- No ingredient-level meal export
- No detailed workout-structure export (sets/exercises/RIR/supersets as structured health-platform data)

## Statistics / Sleep integration (implemented)

- Statistics hub includes:
  - steps
  - sleep
  - recovery
  - consistency
  - performance
  - muscle volume
  - body/nutrition analytics

## Current defaults

- Sleep tracking defaults to disabled in settings (`sleep_tracking_enabled` default `false`)
- Steps tracking defaults to enabled (`steps_tracking_enabled` default `true`)

## Near-term work toward 1.0 (planned, not yet guaranteed in current working copy)

- Adaptive calorie target / TDEE guidance
  - goal selection
  - weekly target rate
  - recommendation from intake + weight trend
- Onboarding (including TDEE guidance) and tutorial
- Widgets
- App Store release
- Google Play release

## Credits

- **[Open Food Facts](https://openfoodfacts.org/)** for food database coverage
- **[wger](https://github.com/wger-project/wger)** for the workout database foundation

## License

[MIT](LICENSE)
