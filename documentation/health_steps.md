# Health Steps Module

This file documents the currently implemented steps integration behavior.

## Providers

- iOS: Apple HealthKit (`HKQuantityTypeIdentifier.stepCount`)
- Android: Google Health Connect (`StepsRecord`)

## Permissions and sync flow

1. User controls tracking in Settings (`steps_tracking_enabled`).
2. Diary triggers periodic refresh (`~6h`) via `_syncStepsIfDue(...)`.
3. Repository refresh checks availability, requests permission when needed, and syncs step segments.
4. If tracking is disabled or permission/availability fails, refresh is skipped.

Primary files:

- `lib/services/health/steps_sync_service.dart`
- `lib/features/steps/data/steps_aggregation_repository.dart`
- `lib/features/steps/presentation/steps_module_screen.dart`
- `lib/features/diary/presentation/diary_screen.dart`
- `test/steps_aggregation_repository_test.dart`

## Settings keys used

- `steps_tracking_enabled` (`bool`, default `true`)
- `steps_provider_filter` (`String`, default `all`)
- `steps_source_policy` (`String`, default `auto_dominant`)
- `steps_last_sync_at_iso` (`String?`)

## Storage and deduplication

- Storage table: `health_step_segments`
- Dedup key (`external_key`):
  - preferred: `<provider>:<nativeId>`
  - fallback: `<provider>:sha1(sourceId|startAtUtcIso|endAtUtcIso|stepCount)`

## Reactive Reads push model

To enable immediate updates on manual health syncs or background data modifications, the Steps module implements our reactive push-based architecture contract:
1. **Repository Stream Watcher**: `watchDayAggregation(DateTime date)` in `StepsAggregationRepository` observes changes to the underlying `health_step_segments` table using Drift query stream watchers.
2. **UI Subscription binding**: `StepsModuleScreen` (`lib/features/steps/presentation/steps_module_screen.dart`) establishes `_dayStepsSubscription` inside its scope controller.
3. **Date Switch & Scope recycling**: When shifting active period bounds or switching from Day to Week/Month scopes, any outstanding `_dayStepsSubscription` is synchronously cancelled *before* subscribing to the new stream, preventing asynchronous race conditions.

## Current limitations

- Steps remains integrated as read-only import/aggregation; outbound export is implemented separately in the one-way health export module (`documentation/health_export_one_way.md`) and does not alter steps import behavior.
- Background scheduler integration is not implemented; sync is foreground-triggered by app flows (Diary/repository refresh).

