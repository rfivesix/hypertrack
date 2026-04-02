# Health Steps Module (Current Implementation Notes)

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
- `lib/screens/diary_screen.dart`

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

## Current limitations

- Steps is integrated as read-only import/aggregation (no write-back to platform health stores).
- Background scheduler integration is not implemented; sync is foreground-triggered by app flows (Diary/repository refresh).

