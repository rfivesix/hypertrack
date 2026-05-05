# Wger Catalog Refresh & Distribution (Release-Asset Channel)

This document describes the current end-to-end exercise catalog refresh system:

- catalog generation from wger data
- safety validation
- GitHub Actions automation
- GitHub Release asset distribution
- app-side remote refresh/adoption

## Scope and intent

This flow distributes **data artifacts** (exercise catalog DB + metadata), not app binaries.

- It is intentionally separate from app version release publishing.
- It is designed for safe, repeatable catalog refreshes.

## Components

### 1) Generator + build report

Script: `skript/create_wger_exercise_db.py`

Produces:

- `train_libre_training.db`
- build/rejection report JSON (optional via `--report-json-out`)

The build report includes:

- source/build timestamps
- imported/rejected counts
- fallback stats
- rejection reason breakdown

### 2) Catalog diff safety validator

Script: `skript/wger_catalog_diff.py`

Compares old vs new catalog DB and emits:

- metadata/version deltas
- removed/added IDs
- field-level changes
- warning flags
- optional CI-safe nonzero exit via `--fail-on-breaking`

Threshold behavior under `--fail-on-breaking`:

- removals are tolerated up to `--fail-on-removed-threshold`
- safety gate fails when `removed_count > fail_on_removed_threshold`
- severe regressions and suspicious row-drop patterns still fail the safety gate

### 3) GitHub Actions refresh workflow

Workflow: `.github/workflows/wger-catalog-refresh.yml`

Triggers:

- manual (`workflow_dispatch`)
- scheduled weekly refresh

Build outputs:

- `train_libre_training.db`
- `wger_build_report.json`
- `wger_diff_report.json`
- `wger_catalog_manifest.json`

Safety gate:

- diff step can run with `--fail-on-breaking`
- workflow fails on dangerous changes when enabled
- artifacts are still uploaded for inspection

Distribution:

- workflow publishes generated files to a dedicated rolling GitHub Release tag:
  - tag: `wger-catalog-stable`
  - release assets: DB + manifest + reports

## Distribution channel design

Runtime channel is GitHub Release assets, not raw repository files.

Stable release download base:

- `https://github.com/<owner>/<repo>/releases/download/wger-catalog-stable/`

Key assets:

- `wger_catalog_manifest.json` (canonical discovery doc)
- `train_libre_training.db` (catalog payload)
- `wger_build_report.json` (diagnostics)
- `wger_diff_report.json` (safety diagnostics)

`hypertrack_training.db` is retained only as a legacy fallback filename. Runtime
resolution prefers the Train Libre artifact and can fall back to the legacy
asset if the new file has not been published yet.

## Manifest schema (runtime contract)

The manifest is the canonical app discovery document.

Important fields:

- `source_id`
- `channel`
- `release_tag`
- `release_page_url`
- `asset_base_url`
- `version`
- `generated_at`
- `db_file`
- `db_url`
- `db_sha256`
- `build_report_file`
- `build_report_url`
- `diff_report_file`
- `diff_report_url`
- `expected_exercise_count`
- `min_exercise_count`

Validation semantics:

- `expected_exercise_count` is informational metadata (observability/debugging only).
- `min_exercise_count` is the actual hard lower validation floor used by the app.
- The workflow computes `min_exercise_count` conservatively as:
  - `max(50, floor(imported_count * 0.85))`
  - This intentionally allows small legitimate source fluctuations while still
    blocking obviously broken payloads.
- `db_sha256` is required for payload integrity:
  - the app computes SHA-256 of the downloaded DB and rejects mismatches before
    structural DB validation.

Manifest validation hardening (app side):

- `source_id` and `channel` must match configured expected values.
- `version` must be present and non-blank.
- DB location must be resolvable.
- remote URLs must use `https`.
- `min_exercise_count` must be `> 0` if present.
- if both counts are present: `expected_exercise_count >= min_exercise_count`.
- invalid/malformed manifests are rejected with safe fallback.

The app parser supports:

- absolute URLs (`db_url`, `build_report_url`)
- release-style file keys resolved against `asset_base_url` (`db_file`, `build_report_file`)

## App-side integration

Central source config:

- `lib/config/app_data_sources.dart`

Remote refresh service:

- `lib/services/exercise_catalog_refresh_service.dart`

Responsibilities:

- fetch manifest
- decide if remote version is newer
- download DB
- normalize legacy WAL-mode single-file SQLite artifacts after checksum verification
- validate DB file/tables/columns/version/row-count threshold
- cache validated DB + manifest snapshot
- track last-check/last-error/version state in `SharedPreferences`

Failed remote refreshes bypass the normal minimum-check interval on the next
startup so a fixed artifact can be retried without clearing app data.

Published `.db` artifacts should be portable single-file SQLite databases. Build
scripts should checkpoint WAL writes and publish with `journal_mode=DELETE`. For
compatibility with older published artifacts, the app can normalize a downloaded
WAL-mode header after SHA-256 verification and before schema validation/import.

Startup integration:

- `lib/screens/app_initializer_screen.dart` -> `BasisDataManager.checkForBasisDataUpdate(...)`
- `lib/data/basis_data_manager.dart` attempts remote exercise candidate first
- on any remote failure/invalid payload, import falls back to bundled asset DB safely

## Data safety behavior

- Import path is non-destructive for base exercises (`ON CONFLICT(id) DO UPDATE`).
- Existing routine/history links are preserved by avoiding hard delete sweeps of exercise IDs.
- Remote validation is structural/sanity-level, not cryptographic signature verification.
- Payload integrity currently uses SHA-256 checksums from the manifest.
- Digital signature verification is intentionally not implemented yet.

## Release validation

For catalog-channel changes, validate that the workflow publishes the expected
release assets, the manifest points to those assets, startup can adopt a valid
remote catalog, fallback behavior remains stable when the remote channel is
unavailable, and existing routines/history still resolve exercises.

## Changing source/channel configuration

Update only the central config in:

- `lib/config/app_data_sources.dart`

Typical changes:

- move to a different repo/org
- rename release tag/channel
- move to another hosting base URL

Feature logic should not require URL/path edits outside this file.
