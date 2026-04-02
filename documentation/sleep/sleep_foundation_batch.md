# Sleep Foundation Batch: Persistence, Contracts, and Mapping Foundations

> Status: Historical foundation snapshot.  
> For current implemented behavior, use [sleep_current_state.md](sleep_current_state.md).

## Problem Being Solved

This batch establishes the technical foundation for Sleep ingestion and canonicalization so subsequent work can implement normalization, analytics, and UI on stable contracts. The core problems addressed are:

1. A missing persistence architecture with explicit layering for raw archival, canonicalized records, and derived nightly outputs.
2. No typed persistence access APIs (DAOs) for sleep data boundaries.
3. No canonical pure-Dart sleep domain models and enums independent of platform/DB/UI.
4. No ingestion contracts for platform adapters.
5. No platform permission/availability contract model for HealthKit and Health Connect.
6. No deterministic platform-to-canonical mapping layer for HealthKit/Health Connect ingestion payloads.

## Architecture and Boundaries

### Three-Layer Storage Model (Strict)

Implemented in Drift migration SQL (`lib/data/drift_database.dart`) and exposed via sleep DAOs:

- **Raw layer**: `sleep_raw_imports`
  - Stores raw archival payload JSON intentionally.
  - Stores provenance and import status/error metadata for debugging and replay.
- **Canonical layer**:
  - `sleep_canonical_sessions`
  - `sleep_canonical_stage_segments`
  - `sleep_canonical_heart_rate_samples`
  - Stores deterministic normalized records (no opaque JSON blobs).
  - Includes `normalization_version` and provenance fields.
- **Derived layer**:
  - `sleep_nightly_analyses`
  - Stores analysis outputs keyed to canonical session + versioning (`analysis_version`, `normalization_version`).
  - Uses typed scalar columns for current metrics (`total_sleep_minutes`, `sleep_efficiency_pct`, `resting_heart_rate_bpm`).

### Non-persistence Boundaries

- **Domain (pure Dart only)**: `lib/features/sleep/domain/**`
  - `SleepSession`, `SleepStageSegment`, `HeartRateSample`, `NightlySleepAnalysis`
  - Explicit enums for stage/session/confidence/quality.
  - No Flutter, Drift, or platform SDK imports.
- **Ingestion contracts**: `lib/features/sleep/platform/ingestion/sleep_ingestion_models.dart`
  - Platform-agnostic raw ingestion DTOs for sessions, stage segments, and HR samples.
- **Platform permissions**: `lib/features/sleep/platform/permissions/**`
  - Typed state and outcomes for ready/denied/partial/unavailable/notInstalled/loading/technicalError.
  - HealthKit and Health Connect-specific services remain behind bridge interfaces.
- **Adapters**: `lib/features/sleep/platform/healthkit/`, `lib/features/sleep/platform/health_connect/`
  - Permission-aware import orchestrators returning typed success/failure outcomes.
  - No platform SDK types leak outside adapter-specific boundary interfaces.
- **Mapping (pure Dart)**: `lib/features/sleep/data/mapping/**`
  - Deterministic ingestion -> canonical mapping logic.

## Data Flow and Responsibilities

1. Platform adapter checks permission status through permission service.
2. If ready, adapter queries data source and emits `SleepRawIngestionBatch`.
3. Raw payload can be archived in `sleep_raw_imports` (later orchestration step).
4. Mapper converts ingestion DTOs to canonical domain entities deterministically.
5. Canonical entities can be persisted via canonical DAOs with `normalization_version`.
6. Derived analytics pipeline (deferred) persists to `sleep_nightly_analyses` with `analysis_version`.

## Important Design Decisions and Rationale

### 1) Sleep tables created via explicit migration SQL instead of Drift table classes (for now)

**Decision:** Add sleep schema using `customStatement` migration function `_createSleepPersistenceSchema`.

**Why:**
- Keeps this batch surgical without requiring immediate regeneration of large Drift generated files in this environment.
- Still provides fully queryable tables with constraints and indexes.
- Allows introducing typed DAOs immediately.

**Tradeoff:** Drift auto-generated row/companion classes are not available for these tables yet; temporary hand-typed row/companion models are used.

### 2) Canonical/derived avoid opaque JSON

**Decision:** Derived table stores typed scalar metric columns (and version fields), avoiding generic metrics blobs.

**Why:**
- Aligns with requirement to avoid opaque storage outside raw archival layer.
- Enables indexable/inspectable columns and safer migrations.

### 3) Permission model distinguishes denied/partial/unavailable/notInstalled

**Decision:** Introduced explicit `SleepPermissionState` and platform service error enum.

**Why:**
- Required for robust UX and deterministic provider/UI state handling.
- Avoids stringly-typed or platform-exception-driven UI logic.

### 4) Mapping keeps deterministic stage conversion with explicit unknown fallback

**Decision:** HealthKit/Health Connect mappers use explicit switch-based stage mapping; unknown values map to `unknown`.

**Why:**
- Deterministic behavior across ingestion runs.
- Avoids implicit assumptions and makes edge cases testable.

### 5) Nightly analysis model placed under `domain/derived`

**Decision:** `NightlySleepAnalysis` lives in `lib/features/sleep/domain/derived/`.

**Why:**
- Clarifies it is not canonical ingestion data and will evolve with analysis versions.

### 6) Sleep persistence timestamps use UTC epoch milliseconds end-to-end

**Decision:** Sleep persistence layer stores timestamps as UTC unix epoch milliseconds (`INTEGER`) consistently.

**Why:**
- Raw sqlite `customStatement` bind parameters in Drift custom SQL paths cannot bind `DateTime` directly.
- A single storage unit across schema defaults, DAO writes, query variables, range deletes, and row mapping prevents subtle unit/runtime mismatches.

**Implementation notes:**
- DAO writes convert `DateTime` with `toUtc().millisecondsSinceEpoch`.
- `customSelect` range variables use epoch-millis `Variable<int>`.
- Range-delete statements pass epoch-millis integers.
- Query row mapping reconstructs UTC timestamps with `DateTime.fromMillisecondsSinceEpoch(value, isUtc: true)`.
- Sleep schema defaults for `created_at`/`updated_at` use millisecond SQL defaults (`CAST(strftime('%s','now') AS INTEGER) * 1000`).

## Relationships and Indexing Strategy

### Relationships

- `sleep_canonical_sessions.raw_import_id -> sleep_raw_imports.id` (`SET NULL` on delete)
- `sleep_canonical_stage_segments.session_id -> sleep_canonical_sessions.id` (`CASCADE`)
- `sleep_canonical_heart_rate_samples.session_id -> sleep_canonical_sessions.id` (`CASCADE`)
- `sleep_nightly_analyses.session_id -> sleep_canonical_sessions.id` (`CASCADE`)

### Indexes

- Raw debugging/replay:
  - `idx_sleep_raw_imports_imported_at`
  - `idx_sleep_raw_imports_status_hash`
- Canonical selection/recompute windows:
  - `idx_sleep_sessions_range`
  - `idx_sleep_sessions_hash`
  - `idx_sleep_segments_session`
  - `idx_sleep_segments_range`
  - `idx_sleep_hr_session_sampled`
- Derived date/session lookups:
  - `idx_sleep_analyses_night`
  - `idx_sleep_analyses_session`

## Alternatives Considered

1. **Single-table JSON blob for all sleep data**
   - Rejected: violates layering and observability requirements; poor queryability and migration clarity.
2. **Mix raw + canonical in one table with state columns**
   - Rejected: blurs responsibilities and makes deterministic recompute/debug flows harder.
3. **Domain mapping inside DAOs**
   - Rejected: DAOs should remain persistence-focused; business mapping/orchestration belongs in dedicated mappers/repositories.
4. **Platform SDK types exposed into domain**
   - Rejected: increases coupling and harms testability.

## Edge Cases and Failure Modes

- Unknown sleep stage categories from source: mapped to canonical `unknown`.
- HealthKit in-bed-only nights: mapped to `inBedOnly` stage and downgraded stage confidence.
- Permission partial grants: surfaced explicitly as `partial` (not collapsed into denied).
- Health Connect unavailable vs not installed: surfaced as distinct states.
- Adapter query exceptions: normalized to typed `queryFailed` failures.

## Invariants and Assumptions

- Raw -> canonical -> derived layering is maintained; higher layers do not store raw opaque payloads.
- Canonical and derived records carry provenance (`source_platform`, `source_app_id`, `source_confidence`, `source_record_hash`).
- Canonical writes include `normalization_version`; derived writes include `analysis_version`.
- Mapper outputs are deterministic for identical ingestion inputs.

## Testing Strategy

Added focused tests in:

- `test/features/sleep/data/persistence/dao/sleep_persistence_dao_test.dart`
  - Verifies migration-created table presence.
  - Covers insert/query/delete for raw, canonical, and derived DAO groups.
  - Covers canonical delete-by-range cascade semantics.
- `test/features/sleep/data/mapping/healthkit_mapper_test.dart`
  - in-bed-only, mixed stages, unknown stage mapping.
- `test/features/sleep/data/mapping/health_connect_mapper_test.dart`
  - stage mapping including asleep-unspecified and out-of-bed.
- `test/features/sleep/platform/permissions/sleep_permissions_and_adapters_test.dart`
  - Permission/availability state mappings.
  - Adapter denied/partial/unavailable/not-installed/query-failure handling.

## Known Limitations and Deferred Work

Intentionally deferred in this batch:

- End-to-end ingestion orchestration and DB writes wiring.
- Normalization winner selection, dedup, main sleep classification, and decision logging.
- Stage timeline repair/overlap splitting.
- Nightly analysis/scoring computation.
- User-facing sleep screens beyond permission-state-driven UX foundations.
- Conversion of sleep schema from custom migration SQL to full Drift table declarations with generated row classes.

## Migration Path Forward

1. Current migration introduces schema version 9 and creates sleep tables/indexes safely with `IF NOT EXISTS`.
2. Future migration can increment schema and:
   - Add new typed physiological columns (HRV/SpO₂/resp rate/temp delta) to canonical/derived tables.
   - Backfill derived metrics as algorithms evolve by `analysis_version`.
   - Transition to full Drift table classes once generator workflow is available in CI/local environment.
3. Recomputation strategy:
   - Use raw imports + canonical version fields to rebuild canonical windows.
   - Use canonical + analysis version fields to recompute derived nightly outputs.
