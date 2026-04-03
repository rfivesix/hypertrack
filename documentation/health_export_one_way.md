# One-way health export architecture

This document describes the export-only health integration shipped for Hypertrack as source-of-truth.

## Scope implemented

Hypertrack exports one-way to:

- Apple Health (HealthKit)
- Google Health Connect

Export domains:

- Measurements: weight, body fat %, BMI (if present)
- Nutrition/Hydration: aggregate nutrient values per timestamped nutrition entry and hydration entries
- Workouts: session-level start/end with coarse workout type fallback to strength/resistance
  - Includes a plain-text set summary in workout notes/metadata when supported by platform APIs

## Explicit non-goals

- No import/back-sync in this module
- No bidirectional merge
- No ingredient-level export
- No meal reconstruction into external meal semantics
- No workout set/exercise structure export

## Architecture

### Shared orchestrator

- `lib/health_export/export_service.dart`
- Handles per-platform enable/disable, permissions, export orchestration, retry-safe status updates.
- Keeps platform logic in adapters.

### Domain extraction and mapping

- `lib/health_export/data/health_export_data_source.dart`
- Reads Hypertrack data from existing DB helpers and maps to explicit export models.
- Normalizes units:
  - weight → kg
  - hydration → liters
  - sodium from product sodium (or salt-derived fallback)

### Platform adapters

- Apple Health adapter: `lib/health_export/adapters/apple_health/apple_health_export_adapter.dart`
- Health Connect adapter: `lib/health_export/adapters/health_connect/health_connect_export_adapter.dart`
- Both implement shared contract: `lib/health_export/contracts/health_export_adapter.dart`

### Native bridges

- iOS: `ios/Runner/AppDelegate.swift` channel `hypertrack.health/export_apple_health`
- Android: `android/app/src/main/kotlin/com/rfivesix/hypertrack/MainActivity.kt` channel `hypertrack.health/export_health_connect`

Note:
- Android Health Connect export currently writes weight and body-fat measurements.
- BMI stays available in the shared model for Apple Health, but is skipped for Android Health Connect.

## Idempotency and retry safety

Stable Hypertrack-owned export keys are used per record:

- measurement: `measurement:<local_id>`
- nutrition: `nutrition_entry:<local_id>`
- hydration: `hydration_entry:<local_id>`
- workout: `workout_session:<local_id>`

Bookkeeping table:

- `health_export_records`
- Unique constraint: `(platform, domain, idempotency_key)`

Behavior:

- Repeated exports skip already exported keys.
- Domain failures only mark that domain as failed, preserving others.
- Retrying after transient failure is safe and does not duplicate prior successful writes.

## Status model

Per platform and per domain states:

- `idle`, `exporting`, `success`, `failed`, `disabled`

Tracked fields:

- last successful export timestamp
- last error message

Stored in shared preferences (status payload) and shown in Settings.

## Settings UX

`lib/screens/settings_screen.dart` includes:

- per-platform enable/disable switches
- permission request on enable
- unsupported/unavailable handling through enable failure and messaging
- per-domain status summary
- manual retry/export action

## Operational limits / follow-ups

- This batch intentionally exports only data that maps cleanly from existing model fields.
- Workout calories are only exported if already present in payload.
- Health platform write metadata is kept minimal for safety and compatibility.
