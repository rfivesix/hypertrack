# Data Models & Storage (Current Implementation)

This document summarizes the active persistence model in the current working copy.

## Storage architecture

Persistence is Drift-backed through `AppDatabase` in `lib/data/drift_database.dart`.

Main access paths currently in use:

- `lib/data/database_helper.dart`
- `lib/data/workout_database_helper.dart`
- `lib/data/product_database_helper.dart`
- Sleep DAOs in `lib/features/sleep/data/persistence/dao/*`

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
