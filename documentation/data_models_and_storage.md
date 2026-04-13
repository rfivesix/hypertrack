# Data Models & Storage (Current Implementation)

This document summarizes the active persistence model in the current working copy.

## Storage architecture

Persistence is Drift-backed through `AppDatabase` in `lib/data/drift_database.dart`.

Main access paths currently in use:

- `lib/data/database_helper.dart`
- `lib/data/workout_database_helper.dart`
- `lib/data/product_database_helper.dart`
- Sleep DAOs in `lib/features/sleep/data/persistence/dao/*`

## Exercise catalog source and refresh

Bundled exercise seed data ships as:

- `assets/db/hypertrack_training.db`

Startup import path:

- `lib/screens/app_initializer_screen.dart` -> `BasisDataManager.checkForBasisDataUpdate(...)`

Remote refresh service:

- `lib/services/exercise_catalog_refresh_service.dart`

Remote source configuration is centralized in:

- `lib/config/app_data_sources.dart`

The app checks the release-distributed catalog manifest and can adopt a newer
catalog DB after structural validation. On any remote error, startup falls back
to the bundled asset source.

Tracking state for remote refresh checks is kept in `SharedPreferences` keys
under the `exercise_catalog_*` namespace.

## Open Food Facts country data source foundation

Bundled OFF seed data fallback currently defaults to the DE asset:

- `assets/db/hypertrack_prep_de.db`

Country-aware OFF source/channel configuration is centralized in:

- `lib/config/app_data_sources.dart`

Active OFF country selection persistence:

- `lib/services/off_catalog_country_service.dart`
- `SharedPreferences` key: `off_catalog_active_country`

OFF remote adoption service:

- `lib/services/off_catalog_refresh_service.dart`

Current supported OFF country codes:

- `de`
- `us`
- `uk`

Country-scoped OFF import version tracking keys:

- `installed_off_version_de`
- `installed_off_version_us`
- `installed_off_version_uk`

Legacy migration compatibility:

- existing `installed_off_version` (single-country legacy key) is migrated to the
  DE-scoped key when needed.

Historical continuity semantics remain active in OFF replacement imports:

- active searchable OFF rows use `source='off'`
- historically referenced rows can be retained as `source='off_retained'`
- non-referenced stale OFF rows are pruned

Bundled fallback safety for country rollout:

- if active country bundle is missing and no remote candidate is available, OFF import is skipped safely and existing local products remain usable.

## Core app entities (non-sleep)

The traditional app model classes remain under `lib/models/*` (nutrition, workouts, measurements, supplements, chart/timeline helpers, backup serialization).

## Steps storage

Table: `health_step_segments`

Implemented fields used by code paths:

- `provider`
- `source_id`
- `start_at` (UTC epoch seconds)
- `end_at` (UTC epoch seconds)
- `step_count`
- `external_key` (dedup key)

Read/write code paths:

- Sync/write: `lib/services/health/steps_sync_service.dart`
- Aggregation/read: `lib/features/steps/data/steps_aggregation_repository.dart`
- SQL aggregations: `lib/data/database_helper.dart`

## Sleep storage

Sleep uses a 3-layer schema (custom migration SQL in `drift_database.dart`):

1. Raw archival
- `sleep_raw_imports`

2. Canonical normalized
- `sleep_canonical_sessions`
- `sleep_canonical_stage_segments`
- `sleep_canonical_heart_rate_samples`

3. Derived nightly outputs
- `sleep_nightly_analyses`

Derived score-related fields currently used:

- `score`
- `score_completeness`
- `total_sleep_minutes`
- `sleep_efficiency_pct`
- `interruptions_wake_minutes` (WASO)
- `regularity_sri`
- `regularity_valid_days`
- `regularity_is_stable`

Sleep DAO files:

- `lib/features/sleep/data/persistence/dao/sleep_raw_imports_dao.dart`
- `lib/features/sleep/data/persistence/dao/sleep_canonical_dao.dart`
- `lib/features/sleep/data/persistence/dao/sleep_nightly_analyses_dao.dart`

## Sleep pipeline persistence flow

Current import flow persists in this order:

1. raw import row(s)
2. canonical session/stage/hr rows
3. derived nightly analysis row(s)

Pipeline file:

- `lib/features/sleep/data/processing/sleep_pipeline_service.dart`

## Versioning fields

Sleep canonical/derived rows persist version tags used by recompute logic:

- `normalization_version`
- `analysis_version`

## Portability and backup

Backup/export tooling remains under `lib/data/backup_manager.dart` and related import/export helpers.

Current backup behavior relevant to adaptive nutrition:
- SharedPreferences are exported as a full `userPreferences` map (all keys).
- Import restores supported preference value types from that map after clearing existing prefs.
- Adaptive recommendation persistence keys (`adaptive_nutrition_recommendation.*`) are therefore covered implicitly, including migration-only legacy keys if still present.
