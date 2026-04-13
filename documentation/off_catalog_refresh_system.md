# OFF Catalog Refresh & Distribution (Multi-Country Release Channels)

This document describes the v0.8.5 Open Food Facts (OFF) infrastructure wave.

Implemented scope:

- bulk parquet based OFF catalog generation (not API-based)
- GitHub Actions automation
- release-style per-country artifact publication
- manifest-driven distribution contract
- previous-published-release baseline diffing
- app-side country selection groundwork
- retained-history compatibility (`off` vs `off_retained`)

## Source of truth

OFF generation is driven from the official bulk export parquet source:

- canonical repository page:
  - `https://huggingface.co/datasets/openfoodfacts/product-database/blob/main/food.parquet`
- workflow download URL (raw/resolve form):
  - `https://huggingface.co/datasets/openfoodfacts/product-database/resolve/main/food.parquet?download=true`

No OFF runtime API import flow is used for catalog generation.

## Workflow

Workflow file:

- `.github/workflows/off-foods-refresh.yml`

Triggers:

- manual (`workflow_dispatch`)
- scheduled (`cron`)

Country matrix:

- `de`
- `us`
- `uk`

Key behavior per country run:

1. download parquet source
2. generate country-specific OFF DB + build report
3. resolve previous published release manifest for the same country channel
4. download previous published DB baseline if available
5. run DB diff (`off_catalog_diff.py`) against previous published baseline
6. generate country-specific manifest + release notes
7. upload artifacts
8. publish/update country-specific release tag assets
9. publish run summary and enforce optional safety gate

## Country release channels

Each OFF country is isolated in its own stable release tag/channel:

- `off-foods-de-stable`
- `off-foods-us-stable`
- `off-foods-uk-stable`

Countries are not mixed into one shared mega-release asset set.

## Artifact naming

Assets are country-specific and collision-safe, for example:

- `hypertrack_off_de.db`
- `off_build_report_de.json`
- `off_catalog_manifest_de.json`
- `off_diff_report_de.json`
- `off_release_notes_de.md`

Equivalent naming is used for `us` and `uk`.

## Helper scripts

The workflow uses dedicated helper scripts only (no inline python heredocs):

- `skript/create_off_food_db.py`
- `skript/off_catalog_diff.py`
- `skript/resolve_off_reference_manifest.py`
- `skript/build_off_catalog_manifest.py`
- `skript/build_off_release_notes.py`
- `skript/publish_off_run_summary.py`

### Country-parameterized generator

`skript/create_off_food_db.py` now accepts explicit country/source/output arguments:

- `--country-code de|us|uk`
- `--parquet-path <local parquet path>`
- `--source-url <report metadata source url>`
- `--db-out <sqlite output path>`
- `--report-json-out <build report path>`
- `--batch-size <rows>`
- `--min-product-count <hard floor>`

Country selection is explicit and reproducible.

## Manifest contract (OFF)

`source_id` is fixed to:

- `off_food_catalog`

Manifest required fields:

- `source_id`
- `channel`
- `country_code`
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
- `build_report_sha256`
- `product_count`
- `min_product_count`

When baseline diff is available and not skipped:

- `diff_report_file`
- `diff_report_url`
- `diff_report_sha256`

Semantics:

- `product_count` is informational (observability/debugging)
- `min_product_count` is the hard validation floor for safe adoption

## Baseline diff strategy

OFF diffing does not compare against repository files.

It compares against the previous published release asset for the same country channel:

- DE compares against previous DE OFF release assets
- US compares against previous US OFF release assets
- UK compares against previous UK OFF release assets

Resolution flow:

1. fetch previous country manifest from current release channel
2. resolve baseline DB URL from that manifest
3. diff previous published DB vs newly generated DB

If no previous manifest/DB exists, diff is marked as skipped and reported.

## App-side country foundation

Implemented central country/source config:

- `lib/config/app_data_sources.dart`

Implemented persisted active country selection:

- `lib/services/off_catalog_country_service.dart`
- preference key: `off_catalog_active_country`

Supported OFF countries are centralized as:

- `DE`
- `US`
- `UK`

`BasisDataManager` now resolves OFF import source via the active country config and uses country-scoped OFF version keys for import state.

## Active vs retained semantics

Existing historical continuity behavior is preserved.

`BasisDataManager.retainHistoricallyNeededOffProducts(...)` still enforces:

- imported current rows remain active with `source='off'`
- historically referenced, no-longer-imported rows become `source='off_retained'`
- non-referenced, no-longer-imported OFF rows are pruned

This keeps old logs/favorites/meal references resolvable without keeping all historical rows active in search.

## Adding a future country

1. Add country entry in `AppDataSources.offCatalogs` with release tag, base URL, manifest filename, and bundled fallback path.
2. Add matrix entry in `.github/workflows/off-foods-refresh.yml`.
3. Extend country/tag mapping in `skript/create_off_food_db.py`.
4. Add/ship a matching bundled fallback asset if needed.
5. Optionally add country-specific validation floor (`min_product_count`) in workflow matrix.
6. Verify release artifacts and manifest contract for the new country.
