# Sleep Issue Audit & Completion Report (#156, #157, #158, #166–#175)

## Scope Guardrails Followed

- No Batch-3 week/month product feature implementation was started.
- Week/month were kept as route/page shells only.
- Sleep business logic remains within `lib/features/sleep/**`.
- UI continues to consume repository/provider outputs (not Drift tables directly).

## Issue-by-Issue Audit Status

| Issue | Status Before Audit | What Already Existed | What Was Missing | What Was Added Now |
|---|---|---|---|---|
| #156 Sleep persistence roadmap/schema | **Fully implemented** | 3-layer schema + indices + version/provenance fields in `lib/data/drift_database.dart` | None material | No schema changes required |
| #157 Drift persistence foundations/DAOs + migration tests | **Fully implemented** | DAOs for raw/canonical/derived + migration/basic DAO tests in `test/features/sleep/data/persistence/dao/sleep_persistence_dao_test.dart` | None material | No change required |
| #158 Ingestion contracts/models | **Partially implemented** | Existing raw ingestion models in `lib/features/sleep/platform/ingestion/sleep_ingestion_models.dart` | Missing explicit contract interfaces for pagination/status/error classification | Added `lib/features/sleep/data/ingestion/sleep_ingestion_contracts.dart` |
| #166 Normalization pipeline (selection, dedup, nap/main, versioning) | **Partially implemented** | Mapping + persistence pipeline existed in `SleepSyncService` | Deterministic orchestration entrypoint plus selection/dedup/nap-main logic missing | Added `lib/features/sleep/data/processing/sleep_pipeline_service.dart` for deterministic persistence/recompute; selection/dedup/nap-main still pending |
| #167 Timeline repair/overlap resolution | **Missing** | None | Pure deterministic timeline repair + overlap priority resolution | Added `lib/features/sleep/data/processing/timeline_repair.dart` + tests |
| #168 Nightly metrics calculator | **Missing** | None | Deterministic calculator for TIB/SOL/TST/WASO/SE/interruptions/final-awakening | Added `lib/features/sleep/domain/metrics/nightly_metrics_calculator.dart` + tests |
| #169 Regularity calculator | **Missing** | Only presentation math helper existed | Domain calculator with circular SD, 7-night window, partial/insufficient states | Added `lib/features/sleep/domain/metrics/regularity_calculator.dart` + tests |
| #170 HR nightly metrics + baseline | **Missing** | None | Nightly avg/min(5th percentile), baseline maturity (10 nights), 30-night median, deltas | Added `lib/features/sleep/domain/metrics/heart_rate_metrics.dart` + tests (domain-only; not yet wired into pipeline/derived outputs) |
| #171 Scoring engine | **Missing** | Score display existed, not full scoring engine | Versioned scoring config + pure scoring + missing-data reweighting | Added `lib/features/sleep/domain/scoring/sleep_scoring_engine.dart` + tests |
| #172 Read-only query repository | **Partially implemented** | `SleepDayRepository` existed for day composition | Dedicated read-only derived query repository interface missing | Added `lib/features/sleep/data/repository/sleep_query_repository.dart` + tests |
| #173 Pipeline orchestration + recompute support | **Partially implemented** | Import persisted raw/canonical/derived in sync service | Dedicated orchestration service + explicit forced recompute behavior missing | Added `lib/features/sleep/data/processing/sleep_pipeline_service.dart` + tests (service exists but not yet wired into sync flow) |
| #174 UI shell + routing module setup | **Partially implemented** | Day + 5 detail routes existed | Week/month route placeholders and connect/denied/unavailable route targets missing | Added routes + placeholders in `sleep_navigation.dart` and `sleep_placeholder_pages.dart` |
| #175 Reusable widgets/chart primitives + provider states | **Partially implemented** | Reusable detail shells/cards/benchmark widgets existed | Dedicated provider-facing day/week/month derived state model missing | Added `lib/features/sleep/presentation/providers/sleep_derived_providers.dart` (provider not yet connected to UI) |

## Architectural Decisions and Boundaries

1. **Domain calculators are pure functions**  
   Timeline repair, metrics, regularity, HR baseline, and scoring were added as pure logic without DB or UI access.

2. **Read-only query repository returns domain models**  
   `DriftSleepQueryRepository` maps derived rows into `NightlySleepAnalysis` and does not expose Drift row types to presentation.

3. **Orchestration separated from UI and adapters**  
   `SleepPipelineService` provides deterministic import persistence + canonical timeline repair + derived metric/score persistence + forced recompute path, but is not yet wired into the sync flow.

4. **UI route placeholders remain explicit non-goal for full week/month UX**  
   Added only route shells and unavailable/connect/denied targets per issue scope; no Batch-3 screen buildout.

## Files Added/Changed for This Audit Completion

### Added

- `lib/features/sleep/data/ingestion/sleep_ingestion_contracts.dart`
- `lib/features/sleep/data/processing/timeline_repair.dart`
- `lib/features/sleep/data/processing/sleep_pipeline_service.dart`
- `lib/features/sleep/domain/metrics/nightly_metrics_calculator.dart`
- `lib/features/sleep/domain/metrics/regularity_calculator.dart`
- `lib/features/sleep/domain/metrics/heart_rate_metrics.dart`
- `lib/features/sleep/domain/scoring/sleep_scoring_engine.dart`
- `lib/features/sleep/data/repository/sleep_query_repository.dart`
- `lib/features/sleep/presentation/sleep_placeholder_pages.dart`
- `lib/features/sleep/presentation/providers/sleep_derived_providers.dart`
- `test/features/sleep/data/processing/timeline_repair_test.dart`
- `test/features/sleep/data/processing/sleep_pipeline_service_test.dart`
- `test/features/sleep/data/repository/sleep_query_repository_test.dart`
- `test/features/sleep/domain/metrics/nightly_metrics_calculator_test.dart`
- `test/features/sleep/domain/metrics/regularity_calculator_test.dart`
- `test/features/sleep/domain/metrics/heart_rate_metrics_test.dart`
- `test/features/sleep/domain/scoring/sleep_scoring_engine_test.dart`
- `documentation/sleep/sleep_issue_audit_156_175.md`

### Updated

- `lib/features/sleep/presentation/sleep_navigation.dart`
- `test/features/sleep/presentation/sleep_day_navigation_test.dart`

## Tests Added/Updated

- Timeline repair deterministic overlap/merge coverage.
- Nightly metrics deterministic metric output coverage.
- Regularity partial vs insufficient state coverage and midnight-wrap behavior.
- HR nightly + baseline maturity behavior coverage.
- Scoring engine complete-data and missing-data reweighting behavior coverage.
- Query repository date and range behavior coverage.
- Pipeline orchestration + forced recompute behavior coverage.
- Route placeholder rendering coverage in sleep navigation widget tests.

## Validation Notes

- Local Flutter test execution in this environment is blocked (`flutter: command not found`).
- CI workflow logs were queried through GitHub MCP tools; the historical failure inspected was unrelated to these new changes.

## Intentionally Deferred (Still Not in Scope Here)

- Full week/month sleep product UI and advanced aggregation UX.
- Full platform ingestion adapter redesign beyond current scope.
- Extended scoring curves and medical-grade heuristics refinement.
- Batch-3 feature work.
