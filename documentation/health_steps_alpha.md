# Health Steps Alpha

This document describes the alpha implementation of steps integration.

## Providers

- iOS: Apple HealthKit (`HKQuantityTypeIdentifier.stepCount`)
- Android: Google Health Connect (`StepsRecord`)

## Permissions flow

1. User enables "steps tracking" in Settings (default: enabled).
2. On Diary load/date change, background sync is attempted if last sync is older than 6 hours.
3. If permission is not granted, native permission request is triggered.
4. If denied, sync is skipped and no steps card is shown.

## Settings

- `steps_tracking_enabled` (`bool`, default `true`)
  - If disabled: no permission prompts, no sync, no steps card.
- `steps_provider_filter` (`String`, default `all`)
  - Values: `all`, `apple`, `google`.
- `steps_last_sync_at_iso` (`String?`)
  - Last successful sync timestamp in UTC ISO-8601.

## Storage and deduplication

- Raw segments are stored in `health_step_segments`.
- UTC timestamps are stored in DB.
- Dedup key (`external_key`) is:
  - `<provider>:<nativeId>` when available
  - `<provider>:sha1(sourceId|startAtUtcIso|endAtUtcIso|stepCount)` fallback

## Current alpha limitations

- Steps only (no distance, calories, sleep, heart-rate sync yet)
- Sync is foreground-triggered from Diary only
- No background scheduler yet
- UI labels are not localized yet in this alpha pass

