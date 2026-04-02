# Sleep Module — Current Source of Truth (Working-Copy Audit)

This is the canonical technical reference for Sleep as implemented in the **current working copy**.

## Scope and guardrails

- Source of truth: code under `lib/features/sleep/**` plus integration callers in `lib/screens/*`.
- This document describes implemented behavior only.
- Where code appears transitional or mid-refactor, it is labeled explicitly.

## What is implemented now

Implemented Sleep capability currently includes:

- Platform permission/status checks for iOS HealthKit and Android Health Connect
- Manual import flow from Settings (`importRecent`)
- Ingestion -> mapping -> persistence pipeline with derived nightly analysis writes
- Day overview + detail pages
- Week/month scoped overview content (loaded inside day-page scope switch)
- Statistics hub sleep summary card integration
- Diary sleep summary card integration

## Routing and entry points

### Named routes

Defined in `lib/features/sleep/presentation/sleep_navigation.dart`:

- `/sleep/day`
- `/sleep/week`
- `/sleep/month`
- `/sleep/day/duration`
- `/sleep/day/heart-rate`
- `/sleep/day/interruptions`
- `/sleep/day/depth`
- `/sleep/day/regularity`
- `/sleep/state/connect-health-data`
- `/sleep/state/permission-denied`
- `/sleep/state/source-unavailable`

Route registration:

- `MaterialApp.onGenerateRoute = SleepNavigation.onGenerateRoute` in `lib/main.dart`

### User-facing entry points

- Statistics hub sleep card -> `SleepNavigation.openDay(context)` in `lib/screens/statistics_hub_screen.dart`
- Diary sleep summary card -> `SleepNavigation.openDayForDate(context, selectedDate)` in `lib/screens/diary_screen.dart`

### Route implementation detail

- `/sleep/day`, `/sleep/week`, `/sleep/month` currently all build `SleepDayOverviewPage` with different `initialScope` values.
- `SleepWeekOverviewPage` and `SleepMonthOverviewPage` classes exist (`lib/features/sleep/presentation/week/*`, `.../month/*`) and are used in tests, but are not currently wired by `onGenerateRoute`.

Status label:

- **Implemented in current working copy**.

## UI screens and behavior

### Day/Week/Month scope container

- Container page: `lib/features/sleep/presentation/day/sleep_day_overview_page.dart`
- Scope layout shell: `lib/features/sleep/presentation/widgets/sleep_period_scope_layout.dart`

Behavior:

- `day` scope: loads `SleepDayViewModel` overview data
- `week` scope: queries derived analyses in Monday-Sunday range and aggregates with `SleepPeriodAggregationEngine.aggregateWeek(...)`
- `month` scope: queries analyses for month range and aggregates with `aggregateMonth(...)`

### Day overview content

From `sleep_day_overview_page.dart`:

- Timeline card (stage rows)
- Sleep score card
- Metric tiles:
  - Duration
  - Heart rate
  - Regularity
  - Depth
  - Interruptions

Day empty state:

- “Open settings” CTA -> `SettingsScreen`
- “Import now” CTA -> `SleepDayViewModel.importNow()`

### Detail pages

Implemented in `lib/features/sleep/presentation/details/*`:

- `duration_detail_page.dart`
- `heart_rate_detail_page.dart`
- `interruptions_detail_page.dart`
- `depth_detail_page.dart`
- `regularity_detail_page.dart`
- shared shells/cards:
  - `sleep_detail_page_shell.dart`
  - `sleep_data_unavailable_card.dart`

Fallback strategy:

- Each detail page guards for missing overview and missing metric inputs, then shows unavailable cards/pages.

## Repositories and data ownership

### Day composition repository

- Interface + implementation: `lib/features/sleep/data/sleep_day_repository.dart`
- Main method: `fetchOverview(DateTime day)`

Composes day data from:

- `SleepNightlyAnalysesDao`
- `SleepCanonicalSessionsDao`
- `SleepCanonicalStageSegmentsDao`
- `SleepCanonicalHeartRateSamplesDao`

Returns `SleepDayOverviewData` including:

- selected nightly analysis row (latest by `analyzed_at` for day)
- canonical session
- timeline segments
- stage confidence and stage duration summaries
- interruptions fields
- heart-rate avg/baseline/delta
- regularity nights list (up to 7)

### Derived query repository

- `lib/features/sleep/data/repository/sleep_query_repository.dart`
- `DriftSleepQueryRepository` reads `sleep_nightly_analyses` and maps to `NightlySleepAnalysis`
- Used by day-page week/month scope loading

### Statistics summary repository

- `lib/features/sleep/data/sleep_hub_summary_repository.dart`
- Used only for Statistics hub sleep card
- Produces `SleepHubSummary` (mean score, duration, bedtime, interruptions, wake duration)

## Persistence layers currently in use

Schema is defined via migration SQL in `lib/data/drift_database.dart` (`schemaVersion = 11`):

1. Raw layer
- `sleep_raw_imports`

2. Canonical layer
- `sleep_canonical_sessions`
- `sleep_canonical_stage_segments`
- `sleep_canonical_heart_rate_samples`

3. Derived layer
- `sleep_nightly_analyses`

DAOs:

- Raw: `lib/features/sleep/data/persistence/dao/sleep_raw_imports_dao.dart`
- Canonical: `.../sleep_canonical_dao.dart`
- Derived: `.../sleep_nightly_analyses_dao.dart`

## Sync/import pipeline (actual code path)

### Orchestration entry

- `SleepSyncService.importRecent(...)` in `lib/features/sleep/platform/sleep_sync_service.dart`

Flow:

1. Check sleep tracking toggle (`sleep_tracking_enabled`)
2. Refresh permission controller
3. Require permission state `ready`
4. Read last `lookbackDays` window (default 30)
5. Call platform adapter
6. Pass ingestion batch to `SleepPipelineService.runImport(...)`
7. Publish `lastImportAtListenable`

### Platform adapters and channels

- Health Connect adapter: `lib/features/sleep/platform/health_connect/health_connect_sleep_adapter.dart`
- HealthKit adapter: `lib/features/sleep/platform/healthkit/healthkit_sleep_adapter.dart`
- Channel bridges/data sources: `lib/features/sleep/platform/sleep_platform_channel.dart`

### Mapping

- Health Connect mapping: `lib/features/sleep/data/mapping/health_connect_mapper.dart`
- HealthKit mapping: `lib/features/sleep/data/mapping/healthkit_mapper.dart`

### Pipeline service behavior

File: `lib/features/sleep/data/processing/sleep_pipeline_service.dart`

Current `runImport(...)` behavior:

- Upsert raw import rows (`sleep_raw_imports`)
- Upsert canonical session/stage/hr rows
- Repair timeline via `repairSleepTimeline(...)`
- Compute nightly metrics via `calculateNightlySleepMetrics(...)`
- Compute score via `calculateSleepScore(...)`
- Upsert derived row into `sleep_nightly_analyses`

Force recompute support exists in service signature, but `SleepSyncService.importRecent()` currently calls pipeline without `forceRecompute`.

## Score/data pipeline (actual implementation)

### Score computation source

- Engine: `lib/features/sleep/domain/scoring/sleep_scoring_engine.dart`
- Pipeline call site: `SleepPipelineService.runImport(...)`

Current score model:

- `Sleep Health Score V1` with top-level components:
  - Duration (TST): 35%
  - Continuity (SE + WASO): 35%
  - Regularity (SRI): 30%
- Component renormalization is implemented when components are missing.
- Continuity internally renormalizes 50/50 between SE and WASO when one is missing.

Current scoring inputs provided by pipeline:

- `durationMinutes` from nightly metrics (`totalSleepTime`)
- `sleepEfficiencyPct` from nightly metrics
- `wasoMinutes` from nightly metrics (`wakeAfterSleepOnset`)
- `regularitySri` from 1-minute sleep/wake state matching across true 24h pairs (consecutive calendar days only)
- `regularityValidDays` for availability/stability thresholds

Explicitly excluded from V1 main score:

- stage/depth composition
- SOL
- HR/HRV and HR baseline deltas
- interruption count as a standalone component (continuity uses WASO directly)

Detailed formula and scoring bands:

- `documentation/sleep/sleep_health_score_v1.md`

### Score persistence and consumption

- Persisted in `sleep_nightly_analyses`:
  - `score`
  - `score_completeness`
  - `regularity_sri`
  - `regularity_valid_days`
  - `regularity_is_stable`
- Read by:
  - day overview (`SleepDayRepository`)
  - statistics hub summary (`SleepHubSummaryRepository`)
  - week/month aggregations through `SleepQueryRepository`

### Sleep quality bucket mapping

Implemented threshold mapping in repositories:

- `>= 80` -> `good`
- `>= 60` -> `average`
- else -> `poor`
- null score -> `unavailable`

## Interruptions path (actual)

### Domain rules

`lib/features/sleep/domain/metrics/nightly_metrics_calculator.dart`:

- Qualifying wake segment threshold: `>= 3 minutes`
- Distinct interruption requires sleep gap `> 2 minutes` between wake segments
- Interruption counting starts after sleep onset

### Persistence

Pipeline persists:

- `interruptions_count`
- `interruptions_wake_minutes` (from WASO minutes)

### Day fallback behavior

`SleepDayRepository._resolveInterruptions(...)`:

- If derived row has both interruption fields -> use persisted values
- Else -> recompute from repaired timeline metrics

### Statistics summary behavior

`SleepHubSummaryRepository` recomputes interruptions and wake duration from canonical timeline for each selected night before averaging.

Important implementation detail:

- Hub wake duration currently uses `metrics.totalWakeDuration` (all wake stages), while pipeline persistence stores `interruptions_wake_minutes` from `metrics.wakeAfterSleepOnset`.
- This can produce different wake-minute values between hub summary and day/persisted-derived views.

## Heart-rate path (actual)

### Import and canonical persistence

- HR samples are imported with sessions and stages through platform batch
- Persisted to `sleep_canonical_heart_rate_samples`

### Derived nightly HR in pipeline

- Pipeline computes nightly average HR directly from canonical session HR sample list and stores it as `resting_heart_rate_bpm`

### Day-level fallback/baseline

`SleepDayRepository`:

- `sleepHrAvg` uses persisted `restingHeartRateBpm` when present, else nightly HR calculator output
- Baseline built from prior nightly analysis HR values (`_historicalNightlyHeartRatesBefore(day)`)
- Baseline rules (`heart_rate_metrics.dart`):
  - require >= 10 valid nights
  - median of up to last 30 valid nightly averages
- Delta: `nightlyAvg - baseline`

### Working-copy note

- **Implemented in current working copy:** `SleepDayOverviewData` includes `heartRateSamples`, and `HeartRateDetailPage` renders a per-night HR chart from those samples when available.

## Persisted vs derived-on-read

### Persisted outputs

Persisted in `sleep_nightly_analyses` during import pipeline:

- score
- score completeness (`score_completeness`)
- total sleep minutes
- sleep efficiency
- WASO minutes (`interruptions_wake_minutes`)
- resting HR average
- interruptions fields (`interruptions_count`, `interruptions_wake_minutes`)
- regularity metadata (`regularity_sri`, `regularity_valid_days`, `regularity_is_stable`)
- analysis and normalization version tags

### Derived-on-read in repositories/UI

Computed at read time in current implementation:

- timeline repair for hub/day display contexts
- hub mean bedtime via circular mean
- hub interruptions/wake averages
- day baseline and HR delta
- day regularity night list
- week/month aggregate cards/chips/window geometry

## Week/month implementation details

Week/month scope uses `SleepPeriodAggregationEngine` (`lib/features/sleep/domain/aggregation/sleep_period_aggregations.dart`):

- mean score
- weekday/weekend average duration
- per-day score/quality buckets
- week “sleep window” bars from `totalSleepMinutes`

Important implementation detail:

- Week window bars use a synthetic wake anchor at `06:00` and back-calculate bedtime from duration (`_toWindow(...)`), not real bedtime/wake timestamps.

## Statistics integration boundaries

Statistics uses Sleep through `SleepHubSummaryRepository` only:

- file: `lib/screens/statistics_hub_screen.dart`
- card metrics: mean score, mean duration, mean bedtime, interruptions summary
- card tap opens Sleep day route

Statistics does not compute Sleep score/metrics itself.

## Settings integration

File: `lib/screens/settings_screen.dart`

Sleep section currently implements:

- tracking toggle (`sleep_tracking_enabled`)
- connection/permission status tile
- request access action
- import now action
- raw imports viewer (reads `SleepRawImportRecord` and payload JSON)

## Known gaps and limitations visible from code

- No dedicated Sleep drill-down screen inside `lib/screens/analytics/*`; Sleep drill-down is inside Sleep feature routes.
- `SleepPipelineService.forceRecompute` path exists but is not used by `SleepSyncService.importRecent()`.
- `/sleep/state/*` placeholder routes are implemented but not currently linked from main user flow.
- `SleepDerivedProvider` (`lib/features/sleep/presentation/providers/sleep_derived_providers.dart`) exists but is not wired into active UI flow.
- Duplicate `SleepPeriodScope` enums exist in presentation files (`sleep_period_scope_layout.dart` and `sleep_day_view_model.dart`), which signals ongoing refactor potential.
- `night_date` is written from UTC session end (`SleepPipelineService._nightKey(session.endAtUtc)`), while several UI/repository range selections are local-day keyed. Around timezone boundaries, a night may map to an adjacent date from a user-local perspective.
- Regularity component can be unavailable when fewer than 5 valid days are present, or when no consecutive calendar-day pairs exist in available history; score then renormalizes over remaining components.

## Ambiguities and transitional signals

### Currently ambiguous from code

- Standalone pages `SleepWeekOverviewPage` and `SleepMonthOverviewPage` exist but app routing currently resolves week/month through `SleepDayOverviewPage` scope mode.
- Some behavior in sleep detail and day repository paths is influenced by local uncommitted working-copy changes; this document treats those as current truth but not necessarily settled architecture.

## Debugging pointers for score/HR/interruptions issues

When validating nightly score discrepancies, inspect in this order:

1. Raw import presence (`sleep_raw_imports`)
2. Canonical session/stage/hr rows (`sleep_canonical_*`)
3. Repaired timeline behavior (`timeline_repair.dart`)
4. Metrics output (`nightly_metrics_calculator.dart`)
5. Score input subset used by pipeline (`sleep_pipeline_service.dart`)
6. Persisted derived row selected by night/date (`sleep_nightly_analyses` latest by `analyzed_at`)
7. Day repository fallback logic (`SleepDayRepository`)
