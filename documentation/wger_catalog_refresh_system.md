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

- `hypertrack_training.db`
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

### 3) GitHub Actions refresh workflow

Workflow: `.github/workflows/wger-catalog-refresh.yml`

Triggers:

- manual (`workflow_dispatch`)
- scheduled weekly refresh

Build outputs:

- `hypertrack_training.db`
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
- `hypertrack_training.db` (catalog payload)
- `wger_build_report.json` (diagnostics)
- `wger_diff_report.json` (safety diagnostics)

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
- `build_report_file`
- `build_report_url`
- `diff_report_file`
- `diff_report_url`
- `expected_exercise_count`
- `min_exercise_count`

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
- validate DB file/tables/columns/version/row-count threshold
- cache validated DB + manifest snapshot
- track last-check/last-error/version state in `SharedPreferences`

Startup integration:

- `lib/screens/app_initializer_screen.dart` -> `BasisDataManager.checkForBasisDataUpdate(...)`
- `lib/data/basis_data_manager.dart` attempts remote exercise candidate first
- on any remote failure/invalid payload, import falls back to bundled asset DB safely

## Data safety behavior

- Import path is currently non-destructive (`insertOrReplace`) for base exercises.
- Existing routine/history links are preserved by avoiding hard delete sweeps of exercise IDs.
- Remote validation is structural/sanity-level, not cryptographic signature verification.

## Operational testing checklist (before broader rollout)

1. Run workflow manually with `publish_release_assets=true`.
2. Verify release `wger-catalog-stable` assets were replaced.
3. Verify manifest version/URLs match uploaded assets.
4. Install app build using this code.
5. Trigger app startup with network enabled and confirm remote catalog adoption.
6. Confirm startup remains stable with network disabled or manifest fetch failure.
7. Verify routines/history still resolve exercises and analytics remain functional.

## Changing source/channel configuration

Update only the central config in:

- `lib/config/app_data_sources.dart`

Typical changes:

- move to a different repo/org
- rename release tag/channel
- move to another hosting base URL

Feature logic should not require URL/path edits outside this file.
