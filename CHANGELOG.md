# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.7.5] - 2026-04-04
### added
- [#200](https://github.com/rfivesix/hypertrack/issues/200) added a consistend app color. Changed the iOS App icon (The white mode icon got the same color as the dark mode icon) for consistency

### fixed
- [#143](https://github.com/rfivesix/hypertrack/issues/143) fixed audio recording in ai_meal_capture_screen.dart. 
- [#203](https://github.com/rfivesix/hypertrack/issues/203) fixed OFF database re-initialization
- [#205](https://github.com/rfivesix/hypertrack/issues/205) fixed german translation

## [0.7.4] - 2026-04-04

This release completes the main **sleep module rollout** and adds the first full version of **one-way health platform export**.

### Added

- **Sleep module** integrated across the app
  - day / week / month sleep views
  - sleep detail screens
  - sleep timeline visualization
  - sleep score overview
  - sleep statistics integration
- **Sleep Health Score V2**
  - duration
  - continuity
  - regularity
  - more conservative and better documented scoring model
- **Sleep localization pass**
  - localized sleep UI strings
  - cleaned up remaining hardcoded sleep text
- **One-way health export** from Hypertrack to:
  - **Apple Health (HealthKit)**
  - **Google Health Connect**
- Export support for:
  - **body measurements**
  - **nutrition aggregates**
  - **hydration**
  - **workout sessions**
- New **Health Export** settings surface with:
  - platform toggles
  - permission handling
  - export status visibility
  - manual export trigger

### Improved

- **Sleep scoring**
  - better weighting and calibration toward duration / continuity / regularity
  - clearer documentation of evidence-based vs heuristic parts
  - cleaner handling of missing data and score completeness
- **Sleep pipeline / persistence**
  - improved nightly analysis flow
  - explicit scoring versioning
  - regularity calculation support
  - more robust persistence and repository integration
- **Sleep documentation**
  - canonical sleep current-state documentation
  - canonical sleep health score documentation
  - cleaned and consolidated sleep docs
- **Sleep UX**
  - better empty states
  - more consistent detail pages
  - improved score/state wording
  - better navigation coverage
- **Workout export quality**
  - workout export now includes title plus notes/summary text where supported
  - improved session-level export payload quality
- **Health export reliability**
  - full-history initial export
  - incremental follow-up export
  - per-domain checkpoint behavior
  - retry-safe idempotent export bookkeeping
  - chunked export handling for larger histories
- **Timezone handling**
  - export uses source event offsets where available instead of forcing UTC everywhere
- **Diagnostics**
  - clearer export failure summaries
  - better distinction between app-side write problems and downstream platform display limitations

### Fixed

- Removed the previous effective **30-day export cap** for initial health export flows
- Fixed multiple **Health Connect write-path issues**, including:
  - invalid equal start/end intervals
  - body-fat export handling
  - nutrition/hydration write stability
  - quota-related write behavior through safer batching
- Fixed incremental export behavior so a failed domain does not unnecessarily force all other domains back into broad reload behavior
- Fixed remaining sleep-module localization gaps
- Fixed several sleep navigation / presentation rough edges found during beta testing

### Documentation

- Added / updated:
  - sleep current-state documentation
  - sleep health score v2 documentation
  - one-way health export documentation
  - overview / architecture / storage references
  - README links and module references
- Reduced outdated or duplicate sleep documentation in favor of clearer canonical sources

### Notes

- **Sleep export/import scope remains unchanged**: the sleep module is about processing and analytics inside Hypertrack, not external sleep write-back.
- **Health export is one-way only**. Hypertrack remains the source of truth.
- **Nutrition export is aggregate-based only**. No ingredient or individual food-item reconstruction is exported.
- **Workout export is session-level only**. Internal workout structure is not exported as structured native workout data.
- Some downstream behavior, especially in **Google Fit**, may differ from what is actually stored in **Health Connect**. If a field is written correctly but not surfaced there, that is a downstream display limitation rather than a Hypertrack write failure.

## [0.7.4-beta.1] - 2026-04-04

This beta focuses on **one-way health platform export** and the final stabilization work around that integration.

### Added
- **One-way health export** from Hypertrack to:
  - **Apple Health (HealthKit)**
  - **Google Health Connect**
- Export support for:
  - **Body measurements** (for example weight, body fat where supported)
  - **Nutrition aggregates** (calories, protein, carbs, fat, fiber, sugar, salt/sodium mapping)
  - **Hydration**
  - **Workout sessions**
- New **Health Export** settings section with:
  - per-platform enable/disable
  - permission handling
  - export status visibility
  - manual export trigger

### Improved
- **Health export reliability**
  - initial export can backfill the full history
  - follow-up exports are incremental
  - idempotent export tracking prevents duplicate writes
  - export runs are chunked for safer large-history syncs
- **Workout export quality**
  - improved workout title handling
  - workout export now includes description text plus a compact plain-text set summary where supported
- **Timezone handling**
  - export now uses source event offsets where available instead of forcing UTC in all cases
- **Diagnostics**
  - more accurate domain-level export failure summaries
  - better distinction between app-side export problems and downstream platform display limitations

### Fixed
- Removed the previous effective **30-day export limit** for initial export flows
- Fixed multiple **Health Connect write-path issues** around:
  - invalid record intervals
  - body-fat export handling
  - nutrition/hydration export stability
  - quota-related write behavior via safer batching
- Fixed incremental export behavior so one failed domain does not force unnecessary full-history reloads for all other domains

### Notes
- Export remains **one-way only**. Hypertrack is the source of truth.
- Nutrition export remains **aggregate-based only**. No ingredient- or food-item reconstruction is exported.
- Workout export remains **session-level only**. Internal workout structure is not exported as native structured workout content.
- Some downstream display behavior, especially in **Google Fit**, may differ from what is stored in Health Connect. If a field is written correctly but not shown in Google Fit, this is a platform display limitation rather than a Hypertrack write failure.

### Documentation
- Added and updated implementation-focused documentation for the one-way health export module
- Updated project docs and overview references to reflect the current health export behavior
## [0.7.4-alpha.1] - 2026-04-03

This alpha focuses on one-way health export hardening for Android Health Connect and adds richer session context for workout exports without expanding structured workout scope.

### Added
- Workout export note-summary text built from logged exercises/sets and attached to exported workout sessions.
- Standardized set-line note formatting for export summaries:
  - one line per exercise,
  - set entries as `<setType> <weight>kg x <reps>`,
  - set-type abbreviations `W` (warm-up), `S` (standard), `F` (failure), `D` (dropset).
- Android Health Connect workout export now writes the summary to `ExerciseSessionRecord.notes`.
- Apple Health workout export now persists the summary in workout metadata (`hypertrack_workout_summary`).

### Changed
- Health export workout payload model now includes an optional notes field for platform writers.
- Workout export data loading now includes associated set logs to build ordered note summaries.
- Nutrition/Hydration grouped export flow now records split diagnostics so failures can indicate whether nutrition and hydration failed independently.

### Fixed
- Android body-fat export mapping now recognizes real stored measurement type variants (including `fat_percent`) so body-fat entries are no longer dropped before write.
- Android body-fat export normalization/range handling aligned to Health Connect `BodyFatRecord` percent expectations (`0..100`).
- Android nutrition export reliability improved:
  - strict interval validation now respected (`startTime < endTime`),
  - defensive per-field sanitization for calories/macros/fiber/sugar/sodium,
  - optional-field fallback retry to isolate problematic nutrition fields.
- Android hydration export interval validation fixed (`startTime < endTime`) to prevent rejected writes.
- Android BMI export no longer reports false-success when unsupported by the current Health Connect writer path.

### Tests
- Expanded health-export data source tests to validate workout summary note formatting and ordering across multiple exercises/sets.
- Maintained passing targeted export tests for data source, service orchestration, and adapters.

## [0.7.3] - 2026-04-03

This stable release includes all `0.7.3-alpha.*` and `0.7.3-beta.1` changes since `0.7.2`, with Sleep moved from early alpha foundations to a release-ready implementation baseline.

### Added
- End-to-end Sleep tracking across iOS (HealthKit) and Android (Health Connect), including sessions, stages, and overnight heart-rate ingestion.
- Sleep Day experience (timeline, score, and key metric tiles) plus detail pages for Duration, Heart rate, Regularity, Depth, and Interruptions.
- Sleep week/month scoped overview support and broader period navigation behavior.
- Sleep entry points from Statistics Hub and Settings.
- Sleep settings controls for tracking toggle, permissions/access flow, import actions, and raw-import visibility.
- Persisted nightly analysis metadata for score completeness and regularity outputs (SRI, valid-day count, stability).
- Sleep Health Score V2 (`sleep-health-score-v2`) as canonical score model with updated documentation and regression coverage.
- Automatic throttled sleep import orchestration (`importRecentIfDue`) for periodic sync checks.
- Expanded localized Sleep copy across setup, status, empty states, timeline/status labels, and detail messaging.

### Changed
- Sleep scoring evolved from V1 to V2:
  - top-level weights now Duration `40%`, Continuity `35%`, Regularity `25%`
  - stricter duration mapping with stronger short-sleep penalties
  - continuity remains SE + WASO with internal renormalization
  - regularity remains SRI with lower top-level compensation weight
- Sleep pipeline default analysis version set to `sleep-health-score-v2`.
- Sleep navigation and overview flow refined across day/week/month scopes.
- Sleep settings and status UX refined to better separate setup/access/data state.
- Sleep timeline presentation redesigned into staged bar-style rendering with clearer legend/axis behavior.
- Sleep benchmark bars (duration/heart-rate detail views) updated for better contrast in light/dark mode.
- Statistics-to-Sleep integration refined while preserving clear feature ownership boundaries.
- Settings section labels updated to release wording (`Sleep/Schlaf`, `Steps/Schritte`).
- Project docs rewritten and consolidated around implementation-first “current source of truth” references.

### Fixed
- Manual `Import sleep data now` now performs full-history backfill import.
- Automatic/periodic sleep import remains incremental (30-day lookback), preserving prior history while refreshing recent windows.
- Sleep score pipeline issues that previously left scores missing/uncomputed on live import.
- Interruption detection and wake-duration gaps in nightly outputs.
- Sleep heart-rate handling issues affecting import completeness, baseline/delta behavior, and display consistency.
- Health Connect stage-mapping issues that could misclassify wake-related segments.
- Nightly analysis persistence and derived-field propagation gaps.
- Forced recompute cleanup now removes raw/canonical/derived records consistently for the affected window.
- Diary and Statistics refresh flows now trigger periodic sleep sync checks.
- Removal of temporary hardcoded sleep debug data from day-overview presentation.
- Remaining key localization inconsistencies and hardcoded Sleep UI text in primary surfaces.
- Release-readiness documentation/comment drift (broken links, stale wording, ambiguous notes) aligned to current implementation.

### Tests
- Added/expanded targeted coverage for:
  - sleep mapping and persistence DAOs
  - permissions/adapters and sync service behavior
  - navigation and settings flows
  - sleep scoring engine and regularity index
  - nightly-analysis persistence and pipeline processing
  - heart-rate baseline chronology
  - forced recompute behavior
  - automatic import throttling behavior

## [0.7.3-beta.1] - 2026-04-03

This release promotes the current Sleep feature set from alpha toward beta by finalizing score behavior, settings labeling, timeline presentation, and import orchestration. Sleep scoring is now stricter for short duration nights (V2), settings labels are language-correct and no longer marked as alpha/batch, and sleep import now supports both all-time manual backfill and recurring incremental sync behavior.

### Added
- Sleep Health Score V2 as the new canonical scoring model (`sleep-health-score-v2`) with updated documentation and regression coverage.
- Automatic throttled sleep import orchestration (`importRecentIfDue`) to check for new data regularly without excessive repeated imports.
- New sync-service test coverage for automatic import throttling behavior.

### Changed
- Sleep score model updated from V1 to V2:
  - top-level weights now Duration `40%`, Continuity `35%`, Regularity `25%`
  - stricter duration piecewise mapping with stronger penalties below 7h (especially below 6h)
  - continuity remains SE + WASO only, with internal renormalization
  - regularity remains SRI, with reduced top-level compensation weight
- Sleep pipeline default analysis version changed to `sleep-health-score-v2`.
- Sleep settings section title changed from `Sleep/Schlaf (Batch 2)` to `Sleep/Schlaf`.
- Steps settings section title changed from `Health Steps (Alpha)` to `Steps/Schritte` based on selected language.
- Sleep timeline card was redesigned to a staged bar-style timeline with cleaner legend and axis behavior.
- Sleep benchmark bars (duration/heart-rate details) received contrast adjustments for dark and light mode readability.

### Fixed
- Manual `Import sleep data now` now performs all-time backfill import instead of a 30-day test-only import.
- Automatic/sequential sleep import remains incremental (30-day lookback), preserving previously imported historical data while adding/updating newer records.
- Diary and Statistics refresh flows now trigger periodic sleep sync checks similarly to existing steps refresh behavior.
- Removed temporary hardcoded sleep debug data from day overview presentation.

## [0.7.3-alpha.4] - 2026-04-02

This alpha finalizes the current Sleep health-score pass in the working copy. It documents and ships the implemented V1 scoring model, persists additional nightly analysis fields for score completeness and regularity, expands Sleep day/detail messaging and localization, and refreshes core documentation so release notes and docs align with the current source of truth.

### Added
- Sleep Health Score V1 documentation describing the implemented scoring model, component weights, regularity rules, completeness semantics, and known limitations.
- A canonical Sleep current-state document that describes the routed screens, repositories, pipeline flow, persistence layers, and implementation boundaries in the current working copy.
- Persisted nightly-analysis fields for score completeness and regularity outputs, including SRI, valid-day count, and stable/preliminary state.
- Additional localized Sleep copy for empty states, timeline/status labels, sleep-score messaging, regularity messaging, heart-rate messaging, and raw-import metadata in English and German.
- Targeted regression coverage for the updated sleep scoring engine, nightly analysis persistence, pipeline processing, navigation, settings, and regularity index calculation.

### Changed
- Updated the Sleep scoring engine to the implemented `sleep-health-score-v1` model using top-level Duration, Continuity, and Regularity components with renormalization when component data is missing.
- Sleep pipeline analysis now computes nightly regularity history from persisted sessions/stages, carries score completeness and regularity metadata forward, and writes those values into derived nightly analyses.
- Sleep repositories and day-overview composition now expose persisted score-completeness, regularity, and heart-rate sample data to presentation surfaces.
- Sleep day/detail presentation was refined to better communicate unavailable data, import/setup actions, score-quality state, regularity maturity, and heart-rate baseline/sample availability.
- Project documentation was rewritten to be implementation-focused and current-state-first across the README, architecture, data/storage, overview, statistics, and sleep technical references.

### Fixed
- Fixed release/documentation accuracy by replacing stale or historical descriptions with working-copy-based documentation and clearer boundaries around what is actually implemented.
- Fixed nightly-analysis persistence gaps so newly computed score completeness and regularity fields round-trip through schema migration, DAO writes, and repository mapping.
- Fixed score-model consistency by aligning the pipeline, persisted analysis version, and documentation around the same Sleep Health Score V1 behavior.
## [0.7.3-alpha.3] - 2026-04-01

This alpha significantly expands the Sleep module from early foundation work into a usable end-to-end feature set for testing. It adds broader Sleep navigation and overview coverage, improves setup and sync flows, strengthens Health Connect ingestion, and fixes key issues in scoring, heart-rate handling, and interruption detection, alongside localization, stability, and test coverage improvements.

### Added
- Sleep module progression from initial day-only flow toward connected day, week, and month experiences
- Sleep week and month overview support for broader period-based navigation and summaries
- Statistics tab entry points into Sleep flows
- Expanded Sleep settings surfaces for permissions, sync, and debug/import visibility
- Additional Sleep localization coverage across screens, labels, and state messaging
- Additional automated coverage for Sleep aggregation, pipeline, persistence, and presentation paths

### Changed
- Refined Sleep navigation structure and routing across day, week, and month scopes
- Improved Sleep settings, permission, and sync UX to better distinguish setup state, access state, and data state
- Updated Sleep data flow to rely more consistently on derived and repository-backed outputs
- Improved Health Connect ingestion behavior and mapping for sleep-stage and heart-rate records
- Refined Sleep overview and detail screen behavior, layout consistency, and fallback handling
- Improved Statistics-to-Sleep integration while keeping Sleep logic owned by the Sleep feature
- Updated repository and aggregation layers to support broader Sleep summaries and derived period views

### Fixed
- Fixed Sleep score pipeline issues that caused scores to remain missing or uncomputed on the live import path
- Fixed interruption detection gaps that caused wake/interruption results to be missing or unavailable
- Fixed Sleep heart-rate handling issues affecting import completeness, baseline/delta availability, and display
- Fixed Health Connect stage-mapping gaps that could incorrectly classify wake-related segments
- Fixed issues in nightly analysis persistence and derived field propagation
- Fixed localization inconsistencies and remaining hardcoded Sleep UI text in key surfaces
- Fixed several Sleep-related stability problems across sync, repository, and overview flows
- Improved regression protection with targeted test additions and updates for recent Sleep fixes
## [0.7.3-alpha.2] - 2026-03-31

### App Icon
- updated the app icon

### Sleep module
- Corrected sleep heart-rate baseline calculation to use the **last 30 nights in chronological order** before computing the median.
- Added regression coverage for the HR baseline chronology behavior.

### Sleep pipeline / recompute
- Fixed forced recompute so raw, canonical, and derived sleep data are removed **consistently for the affected session time window**.
- Raw imports are now cleared via the associated session IDs instead of broad imported-at behavior.
- Derived nightly analyses are now cleared via the affected night-date range.
- Added test coverage for forced recompute behavior.

### Documentation
- Updated the sleep issue audit document to reflect implementation status more accurately.
- Adjusted claims for issues **#166, #170, #173, and #175** to match the actual implementation state more honestly.
- Explicitly documented remaining missing wiring and limitations.

### Tests
- Added/updated targeted tests for:
  - heart-rate baseline chronology
  - sleep pipeline forced recompute behavior

## [0.7.3-alpha.1] - 2026-03-31

### Added
- **Sleep tracking (alpha) across iOS and Android:** Added HealthKit and Health Connect ingestion for sleep sessions, stages, and overnight heart rate with new native method-channel bridges and permissions.
- **Sleep Day experience (Batch 2):** Added the Sleep Day overview (timeline, score, and key tiles) plus dedicated detail screens for Duration, Heart rate, Regularity, Depth, and Interruptions, with shared navigation routing.
- **Sleep controls in Settings:** Added a Sleep section to enable tracking, request permissions, run a manual 30‑day import, and view raw import payloads.
- **Statistics Hub entry:** Added a Sleep card to launch the new Sleep Day overview.

### Changed
- **Sleep data persistence:** Added canonical sleep tables and raw import storage to power the day experience and detail views.
- **Summary card layout:** Added an optional margin configuration to support sleep UI layouts.

### Tests
- Added coverage for sleep mapping, persistence DAOs, permissions/adapters, sync service behavior, navigation, settings UI, and regularity chart math.

## [0.7.2] - 2026-03-31

### Fixed
- **Duplicate caffeine logging for fluid entries:** Fixed an issue where saving caffeinated drinks could create duplicate caffeine supplement logs, leading to inflated caffeine totals.

### Tests
- Added regression coverage to ensure fluid entries no longer create duplicate caffeine supplement logs.

## [0.7.1] - 2026-03-27

### Added
- **Native health steps tracking across iOS and Android:** Added Apple HealthKit and Google Health Connect integration for reading and syncing step data into Hypertrack, including the platform bridge, persisted segment storage, and daily step goal support.
- **Dedicated Steps experience:** Added a dedicated steps detail screen with Day/Week/Month views, period navigation, richer trend context, and tighter integration into Diary, Statistics Hub, Settings, Goals, and onboarding.
- **Steps source controls:** Added provider selection and source-policy controls, including `Auto (dominant source)` and `Merge (max per hour)` to better handle overlapping multi-source health data.
- **Regression coverage for the new steps flow:** Added tests for sync idempotency, source aggregation behavior, steps hub visibility, backup fallback handling, onboarding flow, and steps module behavior.

### Changed
- **Smarter steps sync behavior:** Permissions are now requested when tracking is enabled instead of on every sync, refresh behavior is more resilient, and step-related UI updates propagate more reliably across diary and statistics surfaces.
- **Steps charts and summaries:** Refined weekly/monthly trend rendering, baseline behavior, goal labeling, and statistics-card presentation for clearer interpretation of step progress.

### Fixed
- **Android Health Connect completeness:** Fixed paginated `readRecords` ingestion so all result pages are processed, resolving missing or undercounted daily totals on Android.
- **Duplicate and inflated step totals:** Fixed overlap handling after disabling and re-enabling tracking, and improved multi-source aggregation to avoid double counting.
- **Statistics steps visibility:** Steps are now shown on the statistics screen only when tracking is enabled, with live updates after settings changes.
- **Backup destination reliability:** Fixed auto-backup failures for invalid or unwritable folders and added SAF-backed writing to the exact user-selected external folder on Android.
- **Workout and AI polish:** Localized cardio set-row headers and improved Android speech-recognition availability and retry handling in AI meal capture.

## 0.7.1-beta.1 - 2026-03-27

### Fixed
- **Cardio set-row header localization (#75):** Localized cardio header labels (`Distance`, `Time`, `Intensity`) in workout set rows.
- **Statistics steps visibility (#150):** Steps metric is now shown on the statistics screen only when step tracking is enabled in settings, with live UI updates when toggled.
- **Auto backup reliability (#151):** Fixed auto-backup failures for invalid/unwritable selected folders by validating writability and falling back to a safe app backup directory.
- **Android auto-backup folder targeting (#151):** Added SAF-based folder access so backups can be written to the exact user-selected external folder path on Android.
- **AI meal voice capture on Android (#143):** Improved speech recognition initialization/retry flow and Android-specific availability handling; fixed platform guidance text (no more incorrect iOS-only prompt on Android).
## 0.7.1-alpha.4 — 2026-03-26

### Fixed
- **Android Health Connect paging:** Fixed `readRecords` ingestion to read all pages instead of only the first result page.
- **Missing steps on Android:** Resolved undercounted daily totals caused by incomplete Health Connect imports (especially visible when comparing Hypertrack vs Google Fit / Withings).

## 0.7.1-alpha.3 — 2026-03-26

### Fixed
- **Steps inflation after re-enabling tracking:** Resolved an issue where daily totals could jump too high after disabling and re-enabling step tracking.
- **Idempotent refresh pipeline:** Force refresh and incremental refresh now safely replace overlapping sync windows to prevent duplicate counting.
- **Safer multi-source aggregation:** Improved handling for overlapping sources (e.g. smartwatch + phone / Withings + system) to avoid double counting.

### Added
- **Steps source policy (Settings):**
  - `Auto (dominant source)` (default, recommended)
  - `Merge (max per hour)`
- **Debug diagnostics for sync:** Added debug logging of sync window/fetch stats plus per-source daily totals to speed up troubleshooting.

### Tests
- Added coverage for:
  - disable -> re-enable -> overlapping sync window (no inflation),
  - multi-source overlap behavior for both source policies.
## [0.7.1-alpha.2+70006] - 2026-03-26

### Added
- **Steps Module UX (Day/Week/Month):** Expanded the dedicated steps screen with clear Day/Week/Month views and period navigation for date/week/month switching.
- **Richer Step Trend Context:** Added compact insight chips in trend cards (total, active hours, peak hour, average/day, goal-hit days) for faster interpretation.

### Changed
- **Weekly & Monthly Steps Visualization:** Reworked bars/labels to better match the intended visual style (clean baseline, target reference line, improved spacing and readability).
- **Statistics Hub Steps Card:** Refined the reusable steps card rendering and alignment so it visually matches the redesigned steps module.

### Fixed
- **Bar Baseline Consistency:** Step bars now correctly grow from zero baseline in trend charts instead of appearing visually offset.
- **Goal Label Alignment:** Goal labels (for example `8k`) are now positioned directly at line height instead of drifting above the dashed target line.
- **Week Chart Scaling Accuracy:** Goal check markers no longer affect bar-height calculations, preventing subtly shortened bars.
- **Day Histogram Scaling:** Hourly bars now scale against the actual drawable chart height, fixing incorrect visual heights in the daily timeline.

## [0.7.1-alpha.1] - 2026-03-26

### Added
- **Health Steps Integration (Alpha):** Read and sync daily step data from native health providers directly into the diary.
  - **Android – Health Connect:** Full integration with Health Connect on Android 14+ (API 34+). Includes all required manifest declarations (`READ_STEPS` permission, `ACTION_SHOW_PERMISSIONS_RATIONALE` intent-filter, `VIEW_PERMISSION_USAGE` activity-alias, and `health_permissions` resource).
  - **iOS – HealthKit:** Native Swift implementation using `HKSampleQuery` to read `stepCount` data. Configured with `NSHealthShareUsageDescription` and HealthKit entitlement.
  - **Platform Bridge:** New `MethodChannel` (`hypertrack.health/steps`) with three methods: `getAvailability`, `requestPermissions`, `readStepSegments`.
  - **Sync Service:** Automatic background sync with 48h overlap window, SHA1-based deduplication, and configurable provider filter (All / Apple / Google).
  - **Steps Goal:** Users can set a daily steps goal during onboarding and in the goals screen, with historical goal tracking via `daily_goals_history`.
- **Settings – Health Steps Section:** New settings section to enable/disable step tracking and select the preferred health data provider.
- **Database:** Added `health_step_segments` table with `ON CONFLICT` upsert logic and `target_steps` column in `app_settings` and `daily_goals_history`.

### Changed
- **Smarter Permission Flow:** Permissions are now requested only once when the user enables step tracking in Settings (not on every sync cycle), reducing permission dialog fatigue.
- **Diary Refresh on Return:** The diary screen now automatically refreshes its data when returning from Settings or Profile, ensuring step tracking changes are immediately visible.

### Fixed
- **"App Update Required" on Android 14+:** Added the missing `<activity-alias>` for `VIEW_PERMISSION_USAGE` with `HEALTH_PERMISSIONS` category, which Android 14+ requires to recognize the app as Health Connect-compatible.
- **Sync Error Handling:** `StepsSyncService.sync()` now gracefully catches `PlatformException` when permissions are missing, instead of crashing or repeatedly prompting the user.

## [0.7.0] - 2026-03-25

### Added
- **Statistics & Analytics Hub:** Fully integrated central overview for consistency, PR progress, muscle distribution, recovery readiness, and body/nutrition trends.
- **Deep-Dive Analytics Screens:** Dedicated dashboards accessible from the hub for PRs, consistency tracking, recovery analysis, muscle-group trends, and body/nutrition correlation.
- **Universal Sharing Workflows:** Export and share app-generated content (including text summaries and exported files) through native OS share sheets for faster collaboration or coach feedback.

### Changed
- **Smarter Analytics Architecture:** Refactored statistics to use clearer feature boundaries (domain/data/presentation), making analytics behavior more consistent and maintainable.
- **Reliable Range Logic:** Standardized time-range handling across the hub and drill-down views so metrics remain easier to interpret.
- **Improved Analytics Readability:** Unified labels, chart defaults, and numeric formatting across statistics screens for cleaner trend reading.
- **Data-Quality-Aware Insights:** Body/nutrition and muscle analytics now apply clearer confidence and sufficiency rules before presenting stronger guidance.

### Fixed
- **Refined Statistics Behavior:** Addressed several v0.7 alpha rough edges regarding analytics state handling and presentation consistency.
- **Core Tracking Polish:** Targeted reliability and UX refinements for workout and nutrition logging during the v0.7 stabilization cycle.

### Security (Privacy)
- **Offline-First Analytics:** Ensured all insights are computed strictly on-device from existing logs, requiring no cloud dependency and maintaining the default privacy-first approach.

## [0.7.0-alpha.3+70003] - 2026-03-21

### 📊 Statistics Module (Architecture)
- Introduced a dedicated Statistics feature module under `lib/features/statistics/` with explicit domain/data/presentation boundaries.
- Added centralized range-resolution semantics via `StatisticsRangePolicyService` for mixed selected/fixed/capped/dynamic-all behavior across hub and drill-down analytics.
- Added centralized data-quality semantics via `StatisticsDataQualityPolicy` for body/nutrition insight confidence and muscle-distribution sufficiency checks.
- Expanded typed analytics payload usage (`TrainingStatsPayload`, `WeeklyConsistencyMetricPayload`, `RecoveryAnalyticsPayload`, `BodyNutritionAnalyticsResult`, `StatisticsHubPayload`) to reduce reliance on untyped map access in core statistics flows.
- Added hub/data composition adapters (`StatisticsHubDataAdapter`, `BodyNutritionAnalyticsDataAdapter`) to consolidate multi-source analytics loading.

### 🧭 Statistics UX (User-visible)
- Statistics Hub now acts as the primary analytics portal with compact summaries and drill-down routing for:
  - Performance (PR and notable improvement context)
  - Consistency (weekly trend signal)
  - Muscle analytics (distribution emphasis)
  - Recovery readiness
  - Body/Nutrition correlation
- Improved consistency of analytics labels, numeric formatting, and state display behavior through shared presentation formatter and chart defaults.
- Preserved intentional fixed-window semantics where applicable (for example hub 6-week consistency context and tracker calendar windows), with UI chips still available for metrics that follow selected-range behavior.

### 📝 Notes
- This release continues to treat analytics as on-device, read-only derived views over existing workout, nutrition, fluid, and measurement logs.

## [0.7.0-alpha.2] - 2026-03-10

### 📊 Analytics Polish
- **Consistency metrics expansion**: Added `getWeeklyConsistencyMetrics()` in `WorkoutDatabaseHelper` to provide weekly frequency, duration, and tonnage in one dataset.
- **Consistency Tracker upgrades**: Introduced metric toggle (Volume, Duration, Frequency), improved axis labeling, and switched charts to use richer weekly metric data.
- **Statistics Hub improvements**: Added the same consistency metric toggle to the hub cards for a faster top-level overview.
- **Muscle Group Analytics radar**: Added a new radar visualization for relative muscle volume distribution, including compact top-group aggregation.
- **Recovery Tracker radar + context**: Added heuristic radar pressure view and expanded per-muscle context (recent load amount and heuristic window hints).
- **Body/Nutrition analytics readability**: Improved section hierarchy and chart labeling for trend interpretation.

### 🧩 UI Consistency
- Added shared analytics UI primitives:
    - `AnalyticsSectionHeader` for consistent section titling.
    - `AnalyticsChartDefaults` for standardized chart setup (titles, line behavior).
- Standardized selected line charts to straight-line rendering for clearer trend reading.

### 🌍 Localization
- Added new localization keys for radar/caption and recovery heuristic details (EN/DE).
- Refined German copy quality by replacing legacy ASCII spellings (e.g. `ae/oe/ue`) with proper umlauts where applicable.

### 🧪 Notes
- This release focuses on post-alpha analytics UX clarity and interpretation support, without changing the core training log workflow.

## [0.7.0-alpha] - 2026-03-09

_Note: This is an alpha release, heavily focusing on the new deep-dive Analytics engine. Some areas, UI patterns, and data visualizations may still evolve based on feedback._

### 🚀 Analytics
- **Data Hub Redesign**: Introduced a comprehensive new Statistics Hub replacing the basic overview.
- **Deep-Dive Dashboards**: 
  - **PR Dashboard**: Tracks Personal Records and progressive overload.
  - **Recovery Tracker**: Assesses muscle fatigue and readiness.
  - **Consistency Tracker**: Monitors workout adherence over time.
  - **Muscle Group Analytics**: Visualizes training volume and intensity per body part.
- **Exercise-Level Analytics**: Integrated workout trends and PR summaries directly into individual `ExerciseDetailScreen` sections.
- **Advanced Offline Metrics**: Expanded `workout_database_helper` to calculate complex, multi-variable insights entirely on-device without cloud connectivity.

### 🏋️ Live Workout
- **Background Rest Timers**: Added native local push notifications via `flutter_local_notifications` to reliably alert you when your rest timer is over, even when the app is minimized or the screen is off.

### 🍎 Body / Nutrition
- **Body & Nutrition Correlation**: Introduced algorithms and a new tracking screen to evaluate how your macro and caloric intake impacts long-term body measurement and weight trends.

### 🌍 Localization / Polish
- **Extensive Translations**: Added over 1,000 new localization entries across German and English to cover all complex terminology in the new Analytics tools.
- **UI Refinements**: Polished the Main Screen, Profile Screen, and Add Measurement interfaces to align with the new Data Hub aesthetic.

### 🔧 Stability / Cleanup
- Swept the codebase to remove testing/debug leftovers prior to Alpha release.
- Upgraded Android build configurations (`AndroidManifest.xml` / `build.gradle.kts`) to securely manage exact alarm permissions for the new background timer notifications.

## [0.6.1] - 2026-03-09

### ✨ New Features & Improvements
- **Supplement Tracking History**: Implemented historical tracking for supplement settings (goals, limits, and doses) for accurate long-term analysis and charting.
- **Refined AI Meal Recommendations**: Adjusted macro calculations so meal suggestions dynamically portion out the remaining daily targets based on the specific meal type (Breakfast, Lunch, Dinner, Snack). Added a text box for custom wishes and dietary limitations.
- **Enhanced AI Context**: The AI now correctly utilizes real historical daily goals instead of default app settings when generating recommendations.
- **Performance Boost (Isolates)**: Offloaded AI image processing to a background isolate, significantly improving UI responsiveness and overall performance during photo analysis.

### 🔐 Security & Maintenance
- **Enhanced Encryption**: Updated encryption iterations for improved data-at-rest security while maintaining backward compatibility with older backups.
- **Codebase Polish**: Translated remaining German comments and strings in the database layer to English to maintain codebase consistency.

## [0.6.0] - 2026-03-06

### 🚀 Major Release: The "AI Nutrition Overhaul"

This release fundamentally upgrades how meals can be logged by leveraging on-device and cloud AI, drastically reducing the friction of tracking nutrition. It also adds personalized meal recommendations.

### ✨ Top Features
- **AI Meal Capture Screen**: You can now log complex meals automatically via a single photo, voice dictation, or a quick text description. 
- **AI Recommendations**: Receive personalized meal, snack, and drink recommendations directly within the app, specifically tailored to perfectly fill out your remaining daily macronutrients, while respecting your dietary preferences (Vegan, Quick, etc.).
- **Magical AI Interface**: Brand new, fully animated magical UI for AI features, providing visual feedback during analysis with an elegant gradient design.
- **Smart Ingredient Matching**: AI identifies local database items based on the language of your device, combining and portioning foods intuitively (like merging multiple eggs).
- **Privacy Controls**: Added an "AI Kill-Switch" in settings to globally disable all AI interfaces if preferred. API keys are encrypted at rest using native secure storage (`flutter_secure_storage`).

### 🧠 Logic & Database Overhaul
- **Re-ranked Fuzzy Search**: Implemented dart-side re-ranking to prioritize exact database matches, base foods over user creations, and handle compounding accurately. 
- **AI System Prompts**: Custom system prompts block nutritional hallucinations, enforcing the AI to strictly identify weights and component names.
- **No API Lock-in**: Select between OpenAI (GPT-4o) and Google Gemini (Flash) seamlessly depending on your preferred API key.

### 🎨 UI/UX Refinements
- **Glass Bottom Menus**: Introduced consistent glassmorphism to bottom sheets across the entire app for value editing.
- **Minimalist Aesthetic**: Removed heavy neon backgrounds in favor of targeted gradient accents on UI entry points, maintaining a clean and beautiful design language.


## [0.6.0-alpha.3] - 2026-03-05

### ✨ New Feature: AI Kill-Switch (#85)

- **Global toggle**: Added "Enable AI Features" switch in Settings → AI Meal Capture. Defaults to enabled; persisted via SharedPreferences.
- **Conditional UI**: When disabled, all AI entry points disappear without layout gaps:
  - Speed Dial: "AI Meal" action removed from the action list.
  - Nutrition Explorer: Gradient AI button next to barcode scanner hidden.
  - Settings: AI Settings navigation card conditionally shown only when AI is enabled.
- **Localization**: Added `aiEnableTitle` and `aiEnableSubtitle` strings in both English and German.

### 🎨 UI Improvements

- **AI Review Screen**: Replaced plain `AlertDialog` for quantity editing with the app's custom `showGlassBottomMenu` widget, ensuring visual consistency with the rest of the app (glass styling, keyboard-aware padding, visual style adaptation).

### 🐛 Bug Fixes

- **AI Review Quantity Editor**: Fixed `_dependents.isEmpty` assertion crash when closing the quantity editor. Root cause was disposing a `TextEditingController` while the glass bottom menu's exit animation was still playing.

## [0.6.0-alpha.2] - 2026-03-05

### 🎨 UI Redesign: Minimalist AI Interface (#84)

- **Removed gradient overload**: Stripped animated aura background, glassmorphic segmented toggle, gradient mic button, and glassmorphic action buttons from the AI Meal Capture screen.
- **AI gradient now accents entry points only**: Speed-dial icon, Settings entry icon, and Nutrition Explorer search bar icon use a `ShaderMask` rainbow gradient.
- **Analyze button**: Remains the sole gradient CTA with a smooth, deterministic shimmer animation during loading. Text and spinner are rendered above the gradient background.
- **Inline loading**: Replaced the modal `_AnalyzingOverlay` popup with an in-button animated gradient + spinner.
- **Empty states**: Photo, Voice, and Text tabs now show a centered placeholder with a faded icon and helper text when no input is present.
- **Text field fix**: Replaced broken Container+InputBorder.none with proper `OutlineInputBorder` for clean border radius on the text input tab.
- **New entry point**: Added AI icon with gradient accent next to the barcode scanner in the Nutrition Explorer search bar.

### 🧠 AI Logic Improvements

- **Locale-aware prompts**: `AiService` now accepts `languageCode` — the system prompt explicitly instructs the AI to return food names in the user's app language (e.g., "Apfel" not "Apple" when language is "de").
- **Item consolidation**: System prompt rule prevents duplicate entries — "4 eggs" returns one "Egg" entry with combined weight (240g).
- **No nutritional hallucination**: AI is instructed to return only food names and estimated gram weights. Calorie/macro values are looked up from the local database.
- **Simple base names**: AI returns short, generic food names (e.g., "Banane" not "Reife Banane") to maximize database match rates.

### 🔍 Improved Fuzzy Matching

- **Dart-side re-ranking**: `fuzzyMatchForAi` now fetches 20 candidates from SQL, then re-ranks in Dart with priority: exact match → starts-with → shortest partial match.
- **Source priority preserved**: Base foods still rank above user and Open Food Facts entries within each match tier.
- **Accuracy**: Searching for "Apfel" now correctly returns "Apfel" instead of "Erdapfel" or compound dishes.

### 📦 Code Reduction

- `ai_meal_capture_screen.dart`: ~1264 → ~870 lines (−31%), removed 3 animation controllers, 5 glassmorphic widgets, and the modal overlay.

## [0.6.0-alpha.1] - 2026-03-05

### 🚀 New Feature: AI Meal Capture (#81)

Capture meals faster using photos, voice, or text — powered by AI. Users provide their own API key (stored securely via `flutter_secure_storage`), and the app detects foods with estimated quantities, then lets users review and edit before saving.

### ✨ New Features

- **AI Meal Capture Screen**: New screen accessible from the diary FAB for logging meals via:
  - **Photo input**: Take a photo or pick from gallery (up to 4 images for multi-angle accuracy).
  - **Voice input**: Describe your meal by speaking — speech-to-text with on-device recognition.
  - **Text input**: Type a free-form meal description.
- **AI Meal Review Screen**: Review AI-detected foods before saving — edit quantities, swap items, add/remove entries.
- **AI Settings Screen**: Configure API provider (OpenAI GPT-4o or Google Gemini), enter API key, and test connectivity.
- **Multi-Provider AI Service**: Supports both OpenAI and Gemini APIs with dynamic payload formatting and structured JSON response parsing.
- **Complex Meal Handling**: AI system prompt forces decomposition of composite meals into individual ingredients (e.g., "Burger" → bun, patty, lettuce, cheese, sauce).

### 🎨 UI/UX: "Magical" AI Interface

- **Animated Aura Background**: 5 floating gradient orbs (pink, cyan, orange, purple, emerald) on independent coprime animation cycles (13s / 17s / 23s) — the combined pattern repeats only after ~85 minutes, creating truly organic, non-deterministic motion.
- **Glassmorphic Controls**: Custom frosted-glass segmented toggle for input modes with pastel rainbow gradient indicator.
- **Pastel Rainbow Buttons**: Analyze button and microphone button use a washed-out 5-color spectrum (pink → peach → gold → mint → cyan).
- **Enhanced Analyzing Overlay**: Rotating SweepGradient ring, hue-cycling sparkle icon, and animated gradient progress bar during AI processing.

### 🐛 Bug Fixes

- **Diary Bug (Critical)**: Fixed AI-detected foods not appearing in the diary. Root cause was mismatched meal type keys — the AI review screen used bare values (`'lunch'`) while the diary expected prefixed keys (`'mealtypeLunch'`).
- **Database Prioritization**: `fuzzyMatchForAi` now strictly orders results: base foods first (priority 0), then user foods (1), then Open Food Facts entries (2), followed by name length.

### 🔧 Permissions & Configuration

- **Android**: Added `RECORD_AUDIO` permission to `AndroidManifest.xml` for voice input.
- **iOS**: Fixed `NSMicrophoneUsageDescription` (previously stated "no mic access needed") and added missing `NSSpeechRecognitionUsageDescription`.
- **Speech Recognition**: Configured `speech_to_text` with dictation mode, 60s listen duration, 10s pause tolerance, partial results, locale auto-detection, and `cancelOnError: false`.

### 📦 Dependencies

- `speech_to_text: ^7.0.0`
- `flutter_secure_storage` (for API key storage)
- `image_picker` (for photo capture)

## [0.5.1] - 2026-03-04

### 🐛 Bug Fixes

- **RIR Field Validation (#83)**: Fixed the RIR (Reps in Reserve) field not correctly accepting and persisting values.
  - The field now defaults to empty/null instead of being hardcoded to 2.
  - Clearing the field correctly persists as null (previously reverted to the old value).
  - Target RIR values from routines now appear as placeholder hints in the Live Workout screen.
  - Non-numeric and negative input is now rejected via input validation.

## [0.5.0] - 2026-03-03

### 🚀 Major Release: The "Foundation Overhaul"

This release represents a complete modernization of Hypertrack's core architecture. The database has been rebuilt from the ground up, the onboarding experience has been rewritten, and the app has been fully rebranded. After extensive alpha testing, v0.5.0 is the new stable baseline.

### ✨ New Features

- **Complete Onboarding Wizard**: Replaced the old single-page tutorial with a multi-step setup wizard covering Name/Birthday, Height/Gender, Weight, Calories, Macros, and Water goals — all with precise text input fields.
- **Cardio Exercise Support**: The app now fully supports cardio exercises.
  - Dynamic input fields switch from "Kg / Reps" to "Distance (km) / Time (min)" based on exercise category.
  - Cardio routines default to 1 set and summarize as "Total Distance | Total Duration".
- **RIR (Reps In Reserve) Tracking**: Plan and log training intensity with RIR fields in routines, live workouts, and workout history.
- **Session Restoration**: Active workouts now survive app restarts — all logged sets, exercise order, and in-progress values are automatically recovered.
- **Profile 2.0**: Redesigned Profile Screen displaying Age, Gender, and Height alongside the profile picture, with inline editing.
- **Auto-Caffeine Logging**: Caffeinated drinks automatically create corresponding Supplement Log entries.
- **App Initializer Screen**: Database updates now show a clear progress screen during startup instead of running silently in the background.
- **Portrait Lock**: The app orientation is now locked to portrait for a consistent experience.

### 💾 Database & Architecture

- **Schema v6 Migration**: Major database overhaul adding `height`, `gender`, `birthday` to Profiles, `carbsPer100ml` to FluidLogs, and `rir`/`pauseSeconds` columns for workout tracking.
- **Single Source of Truth**: User goals (Calories, Macros, Water) migrated from `SharedPreferences` to the SQLite database (`app_settings` table). Changing goals now updates the Dashboard instantly without restart.

### 🎨 UI/UX Improvements

- **Edit Routine Overhaul**: Completely refactored to match the Live Workout design with `WorkoutCard`, `SetTypeChip`, and consistent column layout.
- **AppBar Consistency**: Fixed back button visibility in light mode across Live Workout and Scanner screens.
- **Scanner Screen**: Cleaned up AppBar styling and simplified the camera layout.

### 🔧 Branding & Project

- **Full Rebranding**: Completed "Hypertrack" branding across all project names, package/bundle identifiers, class names, localization files, and documentation.
- **Relative Paths**: Converted all internal file paths to relative paths for better portability.
- **Documentation**: Added comprehensive project documentation (architecture, data models, UI components).

### 🐛 Bug Fixes

- Fixed workout exercise reordering not being persisted when saving.
- Fixed base food items being buried in search results — search now prioritizes local 'User' and 'Base' items.
- Fixed trailing spaces in search input causing zero results.
- Fixed incomplete (unchecked) "ghost sets" not being cleaned up when finishing a workout.
- Fixed crash in workout summary from incorrect type casting (`num` vs `int`).
- Fixed backup import crashes caused by `int` vs `string` ID conflicts.
- Fixed Supplements being duplicated upon backup import.
- Fixed sugary drinks showing 0g Carbs in fluid tracking.
- Fixed inconsistent UI styling between routine editing and live tracking.
- Improved pause timer logic to persist changes immediately.

## [0.5.0-alpha.5] - 2026-03-03

### Changed
- **Branding**: Completed the full rebranding to **Hypertrack**. Updated all project names, package/bundle identifiers, class names, and file references across the entire codebase.
- **Project Structure**: Converted all internal file paths to **relative paths** to ensure consistency and easier portability of the project.

## [0.5.0-alpha.3] - 2025-12-29

### Added
- **Cardio Support**: Introduced specialized tracking for cardio exercises.
  - **Dynamic Input Fields**: Based on exercise category ('Cardio'), the input fields in *Live Workout* and *Routine Editor* automatically switch from "Kg / Reps" to "**Distance (km) / Time (min)**".
  - **Routine Logic**: Cardio exercises in routines now default to 1 set (instead of 3) and initialize with empty fields.
  - **Summary & History**: Cardio results are now summarized as "Total Distance | Total Duration" instead of volume.
- **Detailed Database Initialization**:
  - Replaced background database updates with a dedicated **App Initializer Screen**.
  - This screen blocks the UI during startup, displaying a progress bar and detailed status ("Updating base foods: 1500/9000..."), preventing app lag and missing data issues.

### Fixed
- **Workout Reordering**: Fixed a critical bug where reordering exercises during a live workout was not persisted upon saving. The correct order is now saved to the database history.
- **Search Reliability**:
  - Fixed an issue where base food items (e.g., "Apple") were hidden in search results due to the sheer volume of Open Food Facts entries. Search now prioritizes local 'User' and 'Base' items.
  - Fixed a query bug where trailing spaces in search input (often added by keyboards) caused zero results. Input is now trimmed automatically.
- **Ghost Sets**: Finishing a workout now automatically cleans up incomplete (unchecked) sets from the database.
- **Type Safety**: Resolved a crash in the workout summary screen caused by incorrect type casting (`num` vs `int`) for duration calculations.

## [0.5.0-alpha.2] - 2025-12-28

### Added
- **RIR (Reps In Reserve) Support**:
  - Added `rir` column to `SetLogs` database table for tracking actual exertion.
  - Added `target_rir` column to `RoutineSetTemplates` database table for planning intensity.
  - Integrated RIR input fields into `LiveWorkoutScreen`.
  - Integrated RIR display and editing into `WorkoutLogDetailScreen`.
  - Integrated Target RIR configuration into `EditRoutineScreen`.
- **Session Restoration**: Added `tryRestoreSession()` to `WorkoutSessionManager` to recover ongoing workouts after app restarts.

### Changed
- **UI Overhaul (Edit Routine)**: Refactored `EditRoutineScreen` to align with the design of `LiveWorkoutScreen`.
  - Now uses `WorkoutCard` and `SetTypeChip` widgets.
  - Consistent column layout (Set, Kg, Reps, RIR).
- **Database**: Reset schema version to 1 to accommodate new RIR columns cleanly.
- **Pause Timer**: Improved logic to persist pause time changes immediately to the routine definition.

### Fixed
- Fixed inconsistent UI styling between routine editing and live tracking.

## [0.5.0-alpha.1] - 2025-12-27

### 🚀 Major Features & Onboarding
- **New Onboarding Wizard:** Completely rewrote the initial setup process.
    - Replaced single-page tutorial with a multi-step wizard.
    - Added dedicated pages for: Name/Birthday, Height/Gender, Weight, Calories, Macros (Protein/Carbs/Fat), and Water.
    - Replaced sliders with precise text input fields.
- **Profile 2.0:** Redesigned the Profile Screen.
    - Now displays calculated Age, Gender, and Height alongside the profile picture.
    - Added logic to edit these stats directly.
- **Auto-Caffeine Logging:** Adding a drink with caffeine (e.g., Coffee/Energy Drink) now automatically creates a corresponding entry in the Supplement Logs.

### 💾 Database & Architecture (Drift v6)
- **Schema Migration (v1 -> v6):** Massive database update.
    - Added `height` (int) and `gender` (string) to `Profiles`.
    - Added `birthday` (datetime) to `Profiles`.
    - Added `carbsPer100ml` to `FluidLogs`.
    - Added `rir` (Reps in Reserve) and `pauseSeconds` columns (backend preparation).
- **Single Source of Truth:**
    - Migrated user goals (Calories, Macros, Water) from `SharedPreferences` to the local SQLite database (`app_settings` table).
    - Enabled "Live Updates": Changing goals in Settings or Onboarding now updates the Dashboard immediately without a restart.

### 🐛 Fixes & Improvements
- **Backup System:**
    - Fixed critical bug where importing backups caused crashes due to `int` vs `string` ID conflicts.
    - Fixed issue where Supplements were duplicated upon import.
    - Implemented robust `clearAllUserData` to ensure a clean state before importing.
- **Fluid Tracking:** Fixed logic where sugary drinks showed 0g Carbs. Sugar content is now automatically treated as Carbs for the daily summary.
- **Stability:** Added `ensureStandardSupplements()` on app start to prevent crashes if "Caffeine" is missing from the database.
## [0.4.0] - 2025-12-03

### 🚀 Major Release: The "Glass & Fluid" Update

This release marks a significant milestone, introducing a complete UI overhaul, advanced meal tracking, and fluid intake management.

### ✨ Top Features
- **Meals (Mahlzeiten):** Create, edit, and log meals composed of multiple ingredients. Diary entries are now grouped by meal type (Breakfast, Lunch, Dinner, Snack).
- **Fluid & Caffeine Tracking:** dedicated tracking for water and other liquids. Automatic caffeine logging based on beverage intake.
- **Glass UI Design:** A completely new visual language featuring glassmorphism, unified bottom sheets, and an optional "Liquid Glass" visual style.
- **Onboarding:** A brand new onboarding experience for new users.
- **Hypertrack:** Official rebranding and new App Icon.

### 🎨 UI/UX
- **Unified Menu System:** Replaced system dialogs with consistent **Glass Bottom Menus** for a smoother experience.
- **Predictive Back:** Enabled support for Android 14+ predictive back gestures.
- **Haptic Feedback:** Enhanced tactile feedback across the app (Charts, Navigation, FAB).

### 🛠 Technical & Stability
- **Database Architecture:** Robust versioning for internal asset databases and improved backup/restore logic (including supplements).
- **Performance:** Optimized workout session handling and state management.
- **Localization:** Full German and English support across all new features.


## [0.4.0-beta.9] - 2025-11-25

### Bug Fixes
- **Datensicherung**: Ein Fehler wurde behoben, durch den Supplements und Supplement-Logs beim Wiederherstellen eines Backups ignoriert wurden. Diese werden nun korrekt in die Datenbank importiert (#70).
- **UI / Design**: Die AppBar im Mahlzeiten-Editor (`MealScreen`) wurde korrigiert. Sie verwendet nun die globale `GlobalAppBar` für ein einheitliches Design (Glassmorphismus), insbesondere im Light Mode (#68).

## [0.4.0-beta.8] - 2025-11-25
### UI/UX Improvements
- **Unified Design:** Replaced the native `AlertDialog`s with the custom **Glass Bottom Menu** for a consistent look and feel.
  - Applied to: Delete discard workout from main_screen.dart
### fix(l10n): localize remaining hardcoded UI strings for v0.6

- Added missing translation keys to `app_de.arb` and `app_en.arb` (Settings, Onboarding, Data Hub, Workout Bar).
- Replaced hardcoded strings in `SettingsScreen` (Visual Style selection).
- Localized search hints and empty states in `AddFoodScreen`.
- Localized app bar title in `DataManagementScreen`.
- Updated `OnboardingScreen` to use localization keys.

## [0.4.0-beta.7] - 2025-11-24

### Features
- **Android:** Enabled **Predictive Back Gesture** support for Android 14+ devices.

### UI/UX Improvements
- **Unified Design:** Replaced almost all native `AlertDialog`s and standard BottomSheets with the custom **Glass Bottom Menu** for a consistent look and feel.
  - Applied to: Delete confirmations, Supplement logging/editing, Meal ingredient picker, Routine pause/set type editing.
- **Edit Routine:** Aligned the pause timer display style with the Live Workout screen.
- **Food Details:** Fixed layout issue where content overlapped with the transparent app bar.

### Bug Fixes
- **Supplements:** The Supplement Hub and "Log Intake" dialog now correctly respect the date selected in the Diary (instead of always defaulting to "today").
- **Navigation:** Fixed back navigation stack when starting a workout from the Main Screen (back button now correctly returns to the dashboard).
- **Add Food:** Fixed a `RangeError` crash when scrolling to the bottom of the Meals tab.
## [0.4.0-beta.6] - 2025-11-22

### Fixed
*   **Critical: Custom Exercises**
    *   Fixed a database error that prevented users from saving new custom exercises (Issue #58).
    *   Resolved an issue where custom exercises appeared with empty titles when added to a routine.
*   **Critical: Data Restoration**
    *   Improved the backup import logic to strictly preserve original IDs for custom exercises. This prevents routines from breaking or losing exercises after restoring a backup.
*   **Profile Picture**
    *   Fixed a bug where deleting the profile picture did not visually update the app until a restart (Issue #31).
*   **Live Workout Stability**
    *   Fixed a layout crash that occurred when opening the "Change Set Type" menu.
    *   Fixed the "Finish Workout" dialog being inconsistent with the rest of the UI.
*   **Diary & Logging**
    *   Fixed the "Add Ingredient" flow in the Meal Editor which previously closed the menu without adding the item.
    *   Ensured that adding food, fluids, or supplements via the FAB always logs to the **currently selected date** in the diary, rather than defaulting to "now".

### Changed
*   **UI/UX Polish:**
    *   **Bottom Navigation:** Fixed the height of the Glass Bottom Navigation Bar to perfectly align with the Floating Action Button (Issue #61).
    *   **Scroll Padding:** Adjusted bottom spacing across all list screens (Routines, History, Explorer) so the last items are no longer hidden behind the navigation bar (Issue #60).
    *   **Liquid Glass Theme:** Reduced the background opacity and distortion thickness of the "Liquid" visual style to improve content readability.
*   **Modernized Menus:**
    *   Replaced remaining system dialogs (Edit Pause Time, Delete Confirmations, Set Type Picker) with the unified **Glass Bottom Menu**.
    *   Added visual symbols (N, W, F, D) to the Set Type selector for better recognition.

## [0.4.0-beta.5] - 2025-11-07

### Added
* **UI/UX:**
    * Added bottom spacer in the food explorer
    * added glass bottom menu in supplement screen
    * added glass bottom menu in data management screen
* **haptic:**
    * added haptic feedback on the glass navigationbar
### Changed
* haptic
    * increased haptic feedback when hovering on the weight graph
    * increased feedback on glassFAB
* **UI/UX**
    * changed the Appbar to blur
### Fixed
* Fixed an issue where a routine did not loaded.
    

## [0.4.0-beta.4] - 2025-11-07

### Changed
* **UI/UX: Liquid glass**
    * adjusted border intensity
    * adjusted design of the glass bottom menu


## [0.4.0-beta.3] - 2025-11-06

### Added
*   **New Feature: Optional "Liquid Glass" UI Style**
    *   A new, optional visual style can be enabled in `Settings > Appearance` to switch to a rounded, fluid, and translucent UI.
    *   This feature is powered by the `liquid_glass_renderer` package, providing a high-fidelity, cross-platform frosted glass effect on both iOS and Android.
    *   The standard "Glass" UI remains the default.

### Fixed
*   **Critical: Create Food Screen Unusable**
    *   Fixed a critical bug where the "Create Food" screen incorrectly displayed a numeric keyboard for text fields (name, brand), making it impossible to enter non-numeric characters. (Fixes #56)
*   **Critical: Create/Edit Routine Bugs**
    *   Resolved an issue where adding a new exercise to a routine did not visually update the list on the screen until the app was restarted. (Fixes #58)
    *   Fixed a bug where exercises added to a routine were missing their details (name, muscle groups) due to an inconsistent database query.
    *   Addressed a UI state bug where adding, removing, or changing set types in the routine editor would not update the UI in real-time.
*   **Database Stability:**
    *   Prevented crashes when saving custom food items by making the database insertion logic resilient to schema differences between the app model and the asset database.

### Changed
*   **UI/UX Consistency:**
    *   Replaced all standard `AlertDialog` pop-ups in the Supplement tracking feature with the modern `GlassBottomMenu` to provide a consistent and fluid user experience.
*   **Code Refactoring:**
    *   Simplified and stabilized the supplement logging flow by refactoring the UI logic into distinct, reusable widgets, resolving a crash when attempting to log a supplement.
    
## [0.4.0-beta.2] - 2025-10-22
### Added
* **App icon:** Now there is an App icon
### Fixed
* **Backup:** tried to fix the backup
### Changed
* **App Name:** Changed the name from "Hypertrack" to "Hypertrack".


## [0.4.0-beta.1] - 2025-10-19

### Added

*   **New Feature: Onboarding Screen**
    *   Implemented the full, interactive Onboarding process for new users (or when the app is reset).
*   **New Feature: Initial Tab Navigation**
    *   The Main Screen now supports starting on a specific tab, improving navigation flexibility (e.g., deep linking).
*   **Fluid Log Editing**
    *   The "Edit Fluid Entry" dialog now includes fields for the **Name**, **Sugar per 100ml**, and **Caffeine per 100ml**, allowing for precise editing of non-water drinks.

### Fixed

*   **Critical Data Consistency: Fluid/Liquid Food Deletion**
    *   Fixed a critical bug where deleting a **liquid food entry** (e.g., a juice logged via the food tracker) did not correctly remove the linked Fluid Log and Caffeine Log entries, causing orphaned data (Fixes logic in `deleteFluidEntry`).
*   **Modal Display Issue (UX)**
    *   Fixed a bug where the Glass Bottom Menu (and other modals) sometimes failed to display correctly over the main navigation stack.
*   **Live Workout View**
    *   Corrected the padding in the Live Workout screen's exercise list, preventing the final exercise from being obscured by the bottom navigation/content spacer.

### Changed

*   **Major Branding Change: Renamed to "Hypertrack"**
    *   The application has been officially renamed from **"Hypertrack" to "Hypertrack"** across all screens, assets, bundle identifiers, and localization files.
*   **UX Improvement: Modernized Edit Dialogs**
    *   The "Edit Food Entry" and "Edit Fluid Entry" flows in the Diary screen were upgraded from the old `AlertDialog` to the new **Glass Bottom Menu (Bottom Sheet)**, improving mobile UX.
*   **UI Consistency**
    *   Visually updated the buttons and backgrounds in the Floating Action Button (FAB) menu to ensure consistency with the established "Glass FAB" design language.

## [0.4.0-alpha.12] - 2025-10-15

### Added

*   **New Feature: Today's Workout Summary on Diary Screen**
    *   Workout statistics (Duration, Volume, Set Count) for the current day are now displayed directly on the Diary/Nutrition screen (Issue #55).
*   **New Hub UI: Nutrition Hub Overhaul**
    *   The **Nutrition Hub** (`/nutrition-hub` - Issue #53) has been completely redesigned with an improved UI and UX, including new statistical cards and analysis gateways.
*   **Database Asset Versioning**
    *   Implemented a robust versioning system for all internal asset databases (`hypertrack_base_foods.db`, `hypertrack_prep_de.db`, `hypertrack_training.db`). This ensures that core app data is updated when the app version changes, preventing outdated database contents.
*   **Workout History Details**
    *   The Workout History screen now displays the **Total Volume** (in kg) and **Total Sets** for each logged workout, providing more context at a glance.
*   **Automatic Backup Check**
    *   The app now checks for and runs the automated daily backup process upon startup, increasing data security.
*   **New Routine Quick-Create Card**
    *   A new "Create Routine" card has been added to the Workout Hub for quick access.

### Fixed

*   **Critical: Database Name Display**
    *   Fixed a critical bug where localized food names (e.g., German, English) were not correctly retrieved from the product database, leading to the display of wrong or empty names in some parts of the app (Issue #56).
*   **Critical: Backup and Restore Stability**
    *   Fixed multiple critical issues related to the full backup/restore process (Issue #52), ensuring that **Supplements**, **Supplement Logs**, and detailed **Workout Set Logs** are correctly serialized, backed up, and restored.
*   **Workout History Filtering**
    *   Fixed a bug in the workout database helper that caused uncompleted/draft workout logs to be included in the history; only workouts with the status `completed` are now shown.
*   **Exercise Name Localization**
    *   Corrected the logic for displaying exercise names in the Exercise Catalog and Detail screens to correctly prioritize localized names (`name_de`, `name_en`).
*   **Profile Picture Deletion**
    *   Fixed an issue where deleting the profile picture did not work as intended (Issue #31).
*   **Fluid Log Processing**
    *   The calculation for Carbs and Sugar in fluid entries is now correctly scaled by the logged quantity.

### Changed

*   **Reworked Add Menu (FAB)**
    *   The Floating Action Button (FAB) menu on the main screen has been refined for better usability and visual feedback (Issue #50).
*   **Improved Water Section UI/UX**
    *   The Water section in the Diary screen has received general UI/UX enhancements (Issue #54).
*   **Routineless Workout Restoration**
    *   Restoring a workout that was not based on a routine now correctly determines the order of exercises based on the original log order.
*   **Enhanced Swipe-to-Delete Confirmation**
    *   Added explicit confirmation dialogues for the swipe-to-delete actions on Routines, Meals, and Nutrition/Fluid Logs to prevent accidental data loss.
*   **Improved Search Queries**
    *   Product search now searches across `name`, `name_de`, and `name_en` fields, significantly improving discoverability.
*   **UI/UX Refinements**
    *   Numerous minor style adjustments across the app (typography, button padding, list item shadows) for a cleaner, more consistent look.
## Release Notes – 0.4.0-alpha.11+4011

### Added
*   New wger exercise database integrated, providing even more details and laying the groundwork for upcoming advanced analytics features.
*   First set of curated base foods added to the food catalog. More will follow soon.

### Changed
*   Adjusted item labels in the bottom navigation bar to max. 1 line for a cleaner UI.

### Fixed
*   Resolved critical issues with database migration and access, fixing crashes when viewing workout history or adding exercises to routines.
*   Fixed localization issue in the base foods catalog, ensuring food names are displayed in the correct language.

## Release Notes - 0.4.0-alpha.10+4010

### ✨ New Features & Major Improvements

*   **Enhanced Fluid Tracking:**
    *   Any liquid can now be logged with a name, quantity, sugar, and caffeine content via the new "+" menu.
    *   When logging food items, you can now specify that it is a liquid ("Add to water intake"). The quantity is then correctly added to the daily water goal.
*   **Automatic Caffeine Tracking:**
    *   Daily caffeine intake is now automatically calculated and displayed in the nutrition summary.
    *   Caffeine can be specified in "mg per 100ml" for both custom liquids and food items marked as liquid.
    *   A new "Caffeine" entry has been added to the trackable supplements.
*   **Improved Nutrition Analysis:**
    *   Calculations in the nutrition analysis (`nutrition_screen.dart`) and on the dashboard (`diary_screen.dart`) now correctly include calories, carbs, and sugar from all logged fluids.
*   **Expanded "Add" Menu:**
    *   The central speed-dial menu has been expanded with "Add Liquid" and "Log Supplement" options for faster access.

### 🐛 Bugfixes & Improvements

*   **Data Integrity on Deletion:** Fixed a critical bug where deleting fluid or food entries did not remove associated supplement logs (e.g., for caffeine). The deletion logic has been revised to ensure data consistency.
*   **Database Structure:** The database has been updated to version 19 to enable linking between food, fluid, and supplement entries.
*   **UI Improvements in Diary:** Fluids are now displayed in their own section (`Water & Drinks`) on the diary page for better clarity.
*   **Data Backup Fixes:** The backup model (`HypertrackBackup`) has been updated to correctly handle the new `FluidEntry` data.

## Release Notes - 0.4.0-alpha.9+4009

### ✨ New
- Glass-styled bottom sheet menu (blur removed; smooth dimmed backdrop).
- “Add fluid” flow merged into the new bottom sheet (amount + date + time).
- “Start workout” bottom sheet with:
  - **Start empty workout** action on top.
  - List of routines below, each with a **Start** button; tap on the tile opens **Edit Routine**.
- “Track supplement intake” fully inline in the bottom sheet (select supplement → dose & time).
- **Nutrition** tab added to the bottom bar (temporary hub / empty state).
- **Profile** moved from bottom bar to the **right side of the AppBar** as a large avatar (uses user photo when set).

### 🎨 UX / Polish
- Bottom sheet now respects the on-screen keyboard (slides up smoothly).
- Consistent glass styling (rounded corners, straight hard edge around curve).
- Restored instant tab switching on bottom bar tap (no intermediate swipe animation).

### 🐞 Fixes
- Meals: GlassFAB redirection corrected to open meal screen in edit mode.
- Category localization fixed (translated labels show correctly).


## [0.4.0-alpha.8] - 2025-10-05
### Added
- Haptic feedback when selecting chart points and pressing the Glass FAB.
- Meal Screen redesign: consistent typography, SummaryCards for ingredients, contextual FAB.
- Meals list swipe actions consistent with Nutrition screen.

### Changed
- Context-aware FAB in Meals tab (“Create Meal”), removed redundant header button.
- Meal editor visual consistency: non-filled top-right Save button.
- Ingredient layout updated (SummaryCards, editable amounts on right).
- TabBar text no longer changes size on selection.
- Diary meal headers show macro line (kcal · P · C · F) below title.

### Fixed
- Save button tap area and modal layering in Meal Editor.
- Scanner and Add Food refresh logic for recents/favorites.
- Defensive database handling during barcode scan.

### Notes
- No database migration required.
- Final alpha polish before beta.
EOF

## [0.4.0-alpha.7] - 2025-10-03
### Fixed
- Backup import failed with *“no such column is_liquid”* → caused Diary/Stats to hang
- Old backups without password could not be restored (fallback logic improved)
- App stuck in loading when DB initialization or restore failed

### Improved
- Import logic now automatically adapts to schema changes (ignores missing columns)

### Internal
- Defensive DB handling and better logging during import

## [0.4.0-alpha.6] - 2025-10-03
### Fixed
- **Database hotfix**: ensured that all core tables (`food_entries`, `water_entries`, `meals`, `supplement_logs`, etc.) and indices are always created on upgrade, preventing missing-table errors on fresh installs or after updates.
- Fixed `DiaryScreen` and `Statistics` not loading due to missing DB structures.
- Backup/restore flow more robust, no crashes when tables were absent.

### Notes
This is a hotfix release following alpha.4, focused only on database migration stability.  

## [0.4.0-alpha.5+4005] - 2025-10-03

### 🚀 New Features
- **Meals (Beta):**
  - Create and edit meals composed of multiple food items.
  - Add ingredients via search or base food catalog.
  - Adjust ingredient amounts before saving when logging a meal.
  - Select meal type (Breakfast, Lunch, Dinner, Snack) — entries are correctly assigned to the chosen category in the diary.
- **Combined Catalog & Search Tab:**
  - Replaced separate Search and Base Foods tabs with a unified Catalog & Search tab.
  - Expandable base categories visible when no search query is entered.
  - Search results prioritized: base foods first, then OFF/User entries.
  - Barcode scanner button included directly in the search field.
- **Caffeine Auto-Logging:**
  - Automatically log caffeine intake from drinks (liquid products) with a `caffeine_mg_per_100ml` value when added to the diary.
  - Linked directly to the built-in caffeine supplement (non-removable, unit locked to mg).
- **Enhanced Empty States:**
  - Meals tab shows “No meals yet” illustration and action button to create a meal.
  - Improved UI in Favorites & Recents with icons and contextual instructions.

### 🛠 Improvements
- **Base Food Database:**
  - Now ships empty by default (no prefilled, incorrect entries).
  - Completely removed the category “Mass Gainer Bulk”.
- **Database Handling:**
  - Safer `getProductByBarcode` implementation in `ProductDatabaseHelper`: recovers from `database_closed` by reopening databases.
  - Ensures correct handling of base vs. OFF product sources.
- **Diary Screen:**
  - Food entries from meals are now grouped under the correct meal type (Breakfast, Lunch, Dinner, Snack).
  - Macro calculations (calories, protein, carbs, fat) displayed per meal.
- **UI / UX Enhancements:**
  - Consistent use of `SummaryCard` across food lists and meal cards.
  - Added “Add Food” button inside each diary meal card header.
  - Improved barcode scanner integration for a smoother workflow.
  - Caffeine unit locked (mg) and explained via helper text.

### 🐛 Fixes
- Fixed missing meal type in logged meal entries (causing them not to show in Diary, though they appeared in Nutrition overview).
- Fixed ingredient list in meal editor showing barcodes instead of product names.
- Fixed crash when selecting meal type in the bottom sheet (`setSheetState` vs `StatefulBuilder.setState`).
- Fixed null-safety errors in Add Food & Meal logging bottom sheets.
- Fixed duplicated `Expanded`/`TabBarView` layout issues (RenderFlex overflow with unbounded constraints).
- Fixed initialization bug: after Hot Reload, some database migrations were not applied — required Hot Restart (documented).
- Fixed issue with “confirm” translation key missing — replaced with `l10n.save`.

### 🔎 Known Limitations
- **Meals are still in beta:**
  - No drag-and-drop reordering of ingredients yet.
  - No duplication/cloning of meals.
  - No optional photos or icons for meals.
  - Caffeine supplement logs are not yet directly linked to the specific FoodEntry ID (planned).
  - Base Food DB is currently empty — contribution workflow (community-curated entries, moderation, import) planned for future versions.

## 0.4.0-alpha.4 — 2025-10-02
### Added
- DEV-only editor in Food Detail Screen: allows editing base food entries directly on-device
- Export function for `hypertrack_base_foods.db` via share (e.g., AirDrop, Mail, Drive)
- Search & category accordion in "Grundnahrungsmittel" tab with emoji headers

### Changed
- AppBar styling unified: Food Detail, Supplement Hub, and Settings now share large bold title style
- Minor OLED/dark mode polish for nutrient cards

### Fixed
- Database auto-reopen after hot reload (no more `database_closed` errors)
- Edits in base food database now persist correctly across re-entry

## 0.4.0-alpha.3 — 2025-10-01
### Added
- New bottom bar layout with detached GlassFab
- Running workout bar redesign (filled “Continue”, outlined red “Discard”)

### Changed
- Localized screen names (Diary/Workout/Stats/Profile; Heute/Gestern/Vorgestern)
- Weight chart: inline date next to big weight, hover updates value/date, no tooltip popup
- Routine & Measurements screens: swipe actions match Nutrition design

### Fixed
- Back button in Add Food
- “Done” moved to AppBar in add exercise flow
- App version alignment (minSdk 21, targetSdk 36, versionName/Code via local.properties)

### Known
- Play Store signing not configured (debug signing only for GitHub APK)

## [0.2.0] - 2025-09-24

This release focuses on massive stability improvements, UI consistency, and critical bug fixes. The user experience during workouts is now significantly more robust and visually polished.

### ✨ Added
- **Improved "Last Time" Performance Display:** The "Last Time" metric in the live workout screen now accurately shows the weight and reps for each individual set from the previous workout, providing better context for progressive overload.

### 🐛 Fixed
- **CRITICAL: Live Workout Persistence:** An active workout session now correctly persists even if the app is closed by the user or the operating system. All logged sets, exercise order, custom rest times, and in-progress values are restored upon reopening the app, preventing data loss. (Fixes #30)
- **Live Workout UI Bugs:**
    - Correctly highlights completed sets with a subtle green background without obscuring the text fields. (Fixes #29)
    - The alternating background colors for set rows now adapt properly to both light and dark modes. (Fixes #25)
- **State Management Stability:** Resolved `initState` errors by moving context-dependent logic to `didChangeDependencies`, improving app stability.
- **Localization (l10n) Fixes:**
    - The "Delete Profile Picture" button is now fully localized. (Fixes #27)
    - The "Detailed Nutrients" headline in the Goals Screen is now localized. (Fixes #26)

### ♻️ Changed
- **UI Refactoring (`EditRoutineScreen`):** The screen for editing routines has been completely redesigned to match the modern, seamless list-style of the live workout screen, ensuring a consistent user experience across all workout-related views. (Fixes #28)
- **Centralized State Logic:** All logic for managing a live workout session is now consolidated within the `WorkoutSessionManager`. The `LiveWorkoutScreen` is now primarily responsible for displaying the state, leading to cleaner and more maintainable code.
- **Optimized App Startup:** The workout recovery logic was moved from `main.dart` into the `WorkoutSessionManager` to streamline the app's initialization process.
## [0.1.0] - 2025-09-23

This is the first feature-complete, stable pre-release of Hypertrack. It establishes a robust, offline-first foundation for tracking nutrition, workouts, and body measurements.

### ✨ Added
- **Consistency Calendar:** A visual calendar on the Statistics tab now displays days with logged workouts and nutrition entries to motivate users (#22).
- **Macronutrient Calculator:** The Goals screen now features interactive sliders to set macro targets as percentages, which automatically calculate the corresponding gram values (#18).
- **Full Localization:** The entire user interface is now available in both English and German.
- **Encrypted Backups:** Added functionality to create password-protected, encrypted backups for enhanced security.
- **Barcode Scanner:** Integrated a barcode scanner for quick logging of food items.

### 🐛 Fixed
- The app version displayed in the profile screen now correctly reflects the version from `pubspec.yaml` (#24).
- The weight history chart on the Home screen now correctly updates when the date range filter is changed.
- The Backup & Restore system now correctly processes workout routines, preventing data loss.

### ♻️ Changed
- **Database-Powered Exercise Mappings:** Exercise name mappings for imports are now stored robustly in the database instead of SharedPreferences, enabling automatic application during future imports (#23).
- **Unified UI/UX:** The application's design has been polished for a consistent user experience, especially regarding AppBars, dialogs, and buttons.
- **Improved Exercise Creation:** The "Create Exercise" screen now features an intelligent autocomplete field for categories and a chip-based selection for muscle groups, improving data quality and usability.
