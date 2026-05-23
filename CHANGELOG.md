# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.9.13] - 2026-05-xx

### Added
- **UI Modularization Milestone**: Completed an epic, 11-phase modularization of the core presentation layer. 
  - Decomposed massive screen files (Onboarding, Edit Routine, Steps, Sleep, Settings, AI Review, Live Workout, and Statistics Hub) into isolated, highly reusable components within `presentation/widgets/`.
  - Established a dedicated widget library for the Statistics Hub, isolating dashboard cards (Pulse, Sleep, Performance, etc.) for better maintainability.
- **Enhanced Data Layer Architecture**:
  - Decomposed the monolithic 3,100+ LOC `WorkoutLocalDataSource` into specialized part-files: `exercises_queries.dart`, `routines_queries.dart`, `workout_logging_queries.dart`, and `workout_stats_queries.dart`.
  - Isolated the mathematical engine of the Bayesian TDEE estimator into dedicated domain models (`estimator_models.dart`, `observation_model.dart`, `regression_engine.dart`).
- **Advanced Sleep Diagnostics**:
  - Deployed a continuous, on-device Sleep Continuity fallback architecture ($S_{C, fallback}$) for commercial smartwatches that do not supply explicit SE/WASO (Efficiency/Awake minutes) data, leveraging light sleep distribution ($90\%$) and total duration ($10\%$).
  - Added `multiplierBottleneck` diagnostics to `SleepScoringResult` to pinpoint the exact physiological domain limiting the sleep health index.
  - Upgraded the UI Clinical Protection Banner to dynamically fetch the bottleneck key and display precise, contextual biological explanations (tailored warnings for REM, N3, TST, or Circadian delays).

### Changed
- **Service Decomposition**: Successfully decoupled `AiService` and its validation logic into focused modules (`ai_network.dart`, `ai_parsing.dart`, `ai_prompts.dart`), improving testability and scalability.
- **Architecture Hardening**: Achieved a massive technical debt reduction by auditing ~132k total lines of code.
- **UI Code Optimization**: Relocated over 15,000 lines of inline UI code into structured sub-widgets, reducing core file sizes by up to 68% in critical performance paths.
- **Sleep Health Score v3.5 (SHS v3.5)**:
  - Shifted from a rigid, binary hard-cap framework (forcing scores to a flat 60/40) to the continuous, multi-domain **Sleep Health Score v3.5 (SHS v3.5)** using dynamic soft-cap multipliers (`_linear` interpolation maps).
  - Calibrated the Light Sleep Percentage Penalty ($P_{light}$) curve to real-world smartwatch limitations (blending N1 and N2) by shifting the optimal threshold to $\le 65\%$ with a precision decay standard deviation of $7.0\%$.
  - Smoothed out the Sleep Duration ($S_D$) low-end clipping boundary by completely removing the artificial $4.0\text{h}$ hard-zero floor, allowing continuous Gaussian calculation across the entire short-sleep spectrum.
- **UI Layout Cleanups**: Removed the restrictive nested Card containers from the Detail-Analyse section, turning it into a clean native Section Header with edge-to-edge, full-width `GlassProgressBar` fields.

### Fixed
- **Zero-Warning Compliance**: Resolved all remaining lint warnings and static analysis issues across the entire codebase, reaching 100% compile-time safety.
- **Code Verification**: Validated all architectural changes against the full suite of 610+ regression tests, ensuring 100% green status.
- **Memory & Persistence Optimization**:
  - Eliminated native Android Out-Of-Memory (OOM) memory exhaustion crashes inside the Health Connect / Kotlin ingestion lines through an intelligent downsampling mechanism that aggregates raw, high-frequency data streams into dense 1-minute epoch segments before channel transfer.
  - Resolved critical local SQLite persistence conflicts and foreign key failures across Drift schema migrations (v19 to v20) by enforcing proper table recreation and non-nullable column defaults.

### Documentation & Testing
- **Mathematical Architecture Disclosure**: Created `documentation/features/sleep_scoring_engine.md` detailing the entire mathematical architecture of SHS v3.5 using explicit, publication-grade LaTeX formulas.
- **Test Suite Synchronization**: Synchronized the test suite to match the refined curves, pushing the project past 610+ verified, green unit and repository tests.

## [0.9.12] - 2026-05-22

### Fixed
- **iOS Barcode Recognition & Xcode Strip Style (#399)**: Resolved a critical issue where the barcode scanner ran smoothly but failed to recognize any barcodes on iOS release builds.
  - Corrected Xcode **Strip Style** from `All Symbols` to `Non-Global Symbols` in Build Settings, preventing the aggressive compilation pipeline from stripping the essential C++ (`zxing-cpp`) native function symbols required by Dart FFI.
  - Retained the optimized `ReaderWidget` configuration (720p `ResolutionPreset.high` and `0.55` crop factor), drastically increasing the scan frame decoding speed and reducing data processing overhead over the FFI bridge without losing scanning accuracy.

## [0.9.11] - 2026-05-22

### Added
- **Optional Colorful Macro Badges (#397)**: Introduced a vibrant new visualization for macronutrients to improve data readability at a glance.
  - Added the dynamic `MacroBadgeRow` theme extension for high-contrast nutritional summaries.
  - Integrated a global preference toggle in Appearance Settings (defaulting to ON for all users).
  - Implemented smart-hiding logic that automatically cleans up the UI by suppressing zero-value badges for fluids and beverages.
- **Unified Search & Scan UX (#401/#402)**: Completely refactored the search interface in `AddFoodScreen` and `GeneralFoodSelectionScreen`.
  - Implemented a smart toggle mechanic that displays the barcode viewfinder when the field is empty and switches to a 'clear' cross icon during active typing.
  - Streamlined the layout to eliminate icon clutter and improve one-handed navigation efficiency.

### Privacy & Security
- **Android Ghost Permission Removal (#405)**: Hardened the application's privacy profile by explicitly stripping third-party injected microphone permissions.
  - Added `tools:node="remove"` for `RECORD_AUDIO` and `MODIFY_AUDIO_SETTINGS` in the `AndroidManifest.xml`.
  - Guarantees 100% privacy compliance by ensuring the app cannot access the microphone even if required by transitive dependencies.

### Changed
- **Statistics UI Refinements**: Polished the layout and data visualization in the Statistics module, including improvements to the normalized trend charts for better readability.
- **Theme Service Optimization**: Refactored `ThemeService` to persist and manage the new macro badge preferences across app sessions.
- **Localization Updates**: Synchronized and expanded localized strings (DE/EN) to support the new UI components and privacy disclosures.

## [0.9.10] - 2026-05-21

### Added
- **Next-Gen AI Meal Capture**: Completely overhauled the analytical AI capture pipeline. Recognition is now backed by an advanced "Top-N Fuzzy Alternatives" Jaro-Winkler candidate selection loop, ensuring zero hallucinations by strictly matching against the local food database.
- **Holistic Calorie Anchors**: Integrated a `mealContext` calorie anchor that cross-checks AI weight estimations against expected dish-type benchmarks to prevent extreme outlier errors.
- **AI Validation Logic (C1-C4)**: Implemented multi-dimensional cross-check validation rules to automatically verify ingredient compatibility, portion density, and logical consistency.
- **Macro Badges & Deep Inspection**: Added compact P/C/F macro badges to ingredient result cards and a read-only deep inspection view for granular verification of matched database entries.
- **Resource Monitoring**: Integrated a token cost indicator for transparency on API consumption and an isolated `AiMatchingLanguageService` to decouple AI matching from the app's UI locale.

### Removed
- **Generative AI Coach**: Deprecated and removed the generative AI Meal Recommendation/Coach pipeline to focus exclusively on local-first analytical accuracy.
- **Global Custom Prompts**: Excised custom prompt settings and dead localization strings to streamline the AI configuration flow.

### Changed
- **UX Layout Optimization**: Relocated the meal-type selector to the bottom navigation save bar, reclaiming vertical screen real estate for ingredient lists.
- **UI Refinements**: Fixed overlapping layout margins in the AI settings dialog and improved the visual hierarchy of the AI capture review screen.
- **Privacy Policy v1.3**: Upgraded the global Privacy Policy to version 1.3 to reflect the new analytical-only hybrid matching engine and local-first data integrity.

## [0.9.9] - 2026-05-20

### Added
- **Reactive UI Architecture**: Completed a multi-phase migration (Phase 1-3) of the core feature layers (Supplements, Diary/Nutrition, Workouts) to a stream-based reactive architecture using Drift watchers, eliminating manual UI refresh cycles.
- **Workout Set & Exercise Notes**: Extended the training domain models and database schema (`SetLogs`, `RoutineSetTemplates`, `WorkoutExerciseLogs`) to support granular text observations with direct tap-to-edit interactions in `LiveWorkoutScreen`.
- **Unsaved Changes Interceptor**: Implemented a navigation guardian in `EditRoutineScreen` with a `showGlassBottomMenu` confirmation dialog to prevent data loss during complex template modifications.
- **Algorithmic Transparency Matrix**: Integrated technical disclosure matrices into the documentation and in-app views, detailing Bayesian TDEE estimation and local deterministic AI matching invariants.
- **LaTeX Math Integration**: Integrated KaTeX (`docs/katex.min.css`, `docs/script.js`) for high-precision rendering of metabolic and statistical formulas across documentation and technical UI views.
- **Technical Documentation Overhaul**: Completely restructured the `documentation/` directory to align with Pure Clean Architecture, separating developer-facing architectural guides from feature overviews.
- **Attribution Inventory**: Added a comprehensive license and attribution inventory to the `AboutScreen` for bundled open-source dependencies.

### Fixed
- **Fluid Deduplication**: Resolved a critical analytics error in `BodyNutritionAnalyticsDataAdapter` where fluid logs linked to food entries were double-counted in daily totals.
- **Supplement Tracking Stability**: Fixed a mapping regression in `SupplementRepositoryImpl` that caused tracking status and daily goal visibility to be lost during reactive state transitions.
- **Android SAF Target Resolution**: Corrected `BackupManager` logic for Android Storage Access Framework (SAF) to ensure reliable archive writing to secure, user-selected external directories.
- **Haptic Preference Enforcement**: Hardened `HapticFeedbackService` to strictly respect `AppConfig` settings, preventing unrequested vibration events during graph and chart interactions.

### Security & Compliance
- **Privacy Policy v1.2**: Synchronized localized (DE/EN) GDPR/DSGVO compliant policies across the mobile `LegalScreen` and web documentation.
- **Secure Storage Hardening**: Improved data isolation and reset logic in `LocalAppDataResetService` to ensure the complete erasure of sensitive AI provider credentials and model selections.

## [0.9.8] - 2026-05-19

### Fixed
- Fixed mapping regression where supplements lost tracking status and daily goals, disappearing from the Diary screen and Supplement Hub.
- Fixed database-level fluid food double-counting across the analytics compilation pipeline and correlation charts.
- Fixed failing auto-backup process by resolving target directory structures through secure application documents paths.
- Fixed haptic feedback on graph screens to strictly respect the app-wide disabled setting configuration.
- Fixed exercise notes UI layout flaws by removing duplicate edit action buttons and eliminating emoji assets from text wrappers.

### Added
- Added direct tap-to-edit interactions to exercise note display cards across live tracking and history screens.
- Added explicit note deletion capabilities to easily clear text values and update database rows back to null.

## [0.9.7] - 2026-05-18
### Added
- **Reps-in-Reserve (RIR) Enhancement**: Improved RIR data propagation and null-safety during workout logging.
- **Rep Range Fallback**: Implemented mathematical average calculation for rep ranges (e.g., "8-12" defaults to 10 reps) in workout templates and live logging.
- **Global TimeRangeFilter**: Extracted a reusable horizontal ChoiceChip-based filter for consistent timeframe selection across Analytics and Steps modules.

### Changed
- **Diary Summary Harmonization**: Refined summary cards for Sleep, Pulse, and Workouts to use a consistent, emoji-free design with improved typography and spacing.
- **Progress Bar Readability**: Implemented dual-layer clipping and contrast-aware text rendering in `GlassProgressBar` to ensure legibility across all progress levels.

### Fixed
- **Analytics Layout**: Fixed various UI issues in analytics dashboards, including legend shape consistency, edge clipping in horizontal scrolls, and proper current-day filtering in body/nutrition trends.
- **Navigation**: Resolved inconsistencies in exercise selection routing within routine and live workout editors.

## [0.9.7-alpha.2] (90020) - 2026-05-18
### Added
- **Localized feature-bound DataSources**: DiaryLocalDataSource, WorkoutLocalDataSource, SupplementLocalDataSource, ProfileLocalDataSource, StepsLocalDataSource communicating directly with the core Drift database client.

### Refactored
- **The Great Migration**: Complete dissolution of the monolithic product_database_helper.dart and workout_database_helper.dart files. Moved architectural infrastructure utilities (backup, seeding, import/export managers) into a unified lib/core/infrastructure/ grid.
- **Pure Domain Models**: Established total Domain Purity by removing Drift database model leaks (e.g., db.DailyGoalsHistoryData) from repository contracts and use cases, mapping them cleanly to pure Dart entities (like DailyGoal) within the Data layer.

### Fixed
- **Runtime & Testing**: Eliminated the critical Drift multiple-instances database runtime warning by enforcing a strict single-instance initialization with constructor dependency injection via Provider. Adjusted timestamp delays to 1.1s to accommodate SQLite's CURRENT_TIMESTAMP clock resolution. Fixed day-inclusive range selections for diary queries.

### Removed
- **Dead Code Pruning**: Permanently deleted 3 obsolete legacy screens (home.dart, nutrition_screen.dart, measurement_session_detail_screen.dart) with zero remaining active layout compiler links. Relocated health_export to the local feature scope folder.

## [0.9.7-alpha.1] - 2026-05-17
### Added
- **Open Food Facts (OFF) Enrichment**: Significantly expanded food data with Caffeine content, Vegan/Vegetarian/Palm-oil tags, and full Ingredients lists.
- **Smart Database Sync**: New offline-first strategy where the product database is synced during app updates or manually via settings, reducing background overhead.
- **Auto-Fluid Detection**: Intelligent classification of products as fluids for easier hydration tracking.
- **Adaptive Calorie UI**: Improved calorie recommendation UI with new fields for actual calorie density visualization.

### Changed
- **Dietary Badges**: Added visual indicators for vegan, vegetarian, and palm-oil-free products in the food detail screen.
- **Database Architecture**: Migrated core product storage to Drift for better performance and type safety.
- **Settings Overhaul**: Added manual database sync trigger and improved OFF region settings.

### Fixed
- **App Tour Stability**: Fixed edge cases where the app tour could crash on specific navigation flows.
- **Health Export**: Resolved minor synchronization issues with third-party health platforms.

## [0.9.7-alpha] - 2026-05-17
### Added
- **Isolate Offloading**: Performance-intensive tasks like sleep pipeline processing, CSV/Excel decoding, and muscle analytics are now offloaded to background threads (isolates) using `compute()`, ensuring a butter-smooth UI.
- **Global AI Instructions**: Added a persistent text field in settings for custom AI behavioral instructions, replacing the previous 7-day history transfer for better privacy and performance.
- **Unified AI Ingredient Cards**: New visual representation for ingredients in AI-generated meals for better clarity.
- **Legal Information**: Integrated Impressum and Privacy Policy directly into the app.

### Changed
- **3-Tier Diary Loading**: Optimized the diary screen with a 3-tier loading strategy: Tier 1 (instant macro/workout summary), Tier 2 (deferred exercise/meal lists), and Tier 3 (background health data sync).
- **AI Prompt Hardening**: Improved strict constraint adherence for AI recommendations, fixing issues with dietary preferences (e.g., Skyr/dairy exclusion).
- **Workout UI**: Major overhaul of the live workout and workout history screens for better usability and performance.
- **Design Language**: Updated "Liquid Glass" theme as the standard and improved text visibility across various UI elements.

### Fixed
- **Navigation Stability**: Hardened navigation lifecycle with strict `if (!mounted)` guards to prevent crashes during rapid screen transitions.
- **Metric/Imperial System**: Fixed unit system inconsistencies in onboarding and various screens (#337).
- **Database Hardening**: Fixed multiple SQL issues in the OFF database and improved batch processing stability.
- **Supplement Tracking**: Fixed default time for supplement entries in the diary (#354).
- **Scanner Reliability**: Improved barcode scanner logic and permission handling.
- Numerous bug fixes (Issues #322, #323, #334, #335, #338, #339, #340, #341, #342, #343, #344, #345, #347, #348, #349, #352, #353, #356, #357, #358, #361).

## [0.9.6] - 2026-05-15
### Added

* **Imperial Units Support:** Full support for Imperial units (lbs, inches) across the app, including height and weight tracking during onboarding and in settings.
* **External App Import:** Enhanced universal CSV and Excel import functionality with automatic unit conversion and improved data mapping.
* **PR & Achievement Tracking:** Integrated Personal Record (PR) badges and achievement banners in the Live Workout and Workout History screens.
* **e1RM Analytics:** Real-time Estimated 1RM (e1RM) calculation and visualization integrated into workout tracking.
* **Usage-Based Search Ranking:** Exercise and nutrition search results are now intelligently ranked based on individual usage patterns for faster access.

### Changed

* **Diary Screen Optimization:** Decoupled Pulse and Sleep data loading from the main Diary view. Primary nutrition and workout data now load instantly while health data populates in the background.
* **Refined Workout Interface:** Updated the Live Workout and History screens for better interaction and visual clarity.
* **Visual Style Improvements:** Adjusted spacing, chart defaults, and text visibility across the Liquid Glass theme.

### Fixed

* **Database Hardening:** Optimized SQLite operations and strengthened reload logic to prevent data inconsistencies during concurrent actions.
* **Supplement Default Time:** Fixed an issue where the Supplement Diary FAB defaulted to 00:00 instead of the current time.
* **Initialization Flow:** Improved the app initialization sequence to reduce startup latency.

## [0.9.5] - 2026-05-13
### Added

* **Linked Nutrition Logic:** Integrated a system to link fluid entries with nutrition logs. The `DatabaseHelper` now resolves UUIDs to local IDs, ensuring that calories and macros are not double-counted when a drink is part of a tracked meal.
* **Refined Progress Bars:** Replaced standard indicators in `CompactNutritionBar` with the custom `GlassProgressBar` for a more consistent visual language across the dashboard.

### Changed

* **UI Performance Optimization:** Removed `BackdropFilter` and `ImageFilter.blur` from several core widgets, including `SummaryCard`, `FrostedContainer`, and `GlassProgressBar`. These now use high-opacity solid surfaces to reduce GPU strain and improve frame rates.
* **Visual Polish:** * Updated `GlassBottomNavBar` and `GlassFab` to use refined background colors (`summaryCardDarkMode`/`summaryCardWhiteMode`) and adjusted rim borders for better visibility.
* Simplified background decorations in `LegalScreen` by replacing gradients with solid surface colors.


* **Scanner Enhancements:** Optimized `ScannerScreen` by restricting barcode formats to **EAN-8** and **EAN-13**. Increased resolution to `veryHigh` while adjusting scan delays to balance detection speed and thermal impact.
* **Default Settings:** The default `visualStyle` has been updated to `1` in `ThemeService`.

### Fixed

* **Calorie Calculation:** Fixed a bug where liquid calories were duplicated; the app now filters out fluid entries linked to food logs when calculating total daily intake.
* **Test Stability:** Updated `SleepSettingsScreen` tests to include the explicit confirmation step required by the glass bottom menu and fixed locale-dependent string matching.
* **Dark Mode Accessibility:** Adjusted contrast and shadow depths in `FrostedContainer` and `SummaryCard` to ensure elements remain distinct from the background in dark mode.

### Removed

* Unused `dart:ui` imports across multiple widget files to clean up the codebase.

## [0.9.4] - 2026-05-13
### Added
- Integrated legal information (Imprint and Privacy Policy) directly into the app for better transparency and accessibility.
- Introduced the "Liquid Glass" theme as the new default visual style, providing a modern and premium look.
- Added a "Supplement Tracker" to the daily overview, supporting both daily goals (checkmark style) and daily limits (progress bar style).

### Changed
- Improved visual clarity and text visibility on progress bars when using glass-inspired themes.
- Enhanced database stability and reload performance for a smoother user experience.
- Refined food and exercise mapping logic for better accuracy.

### Fixed
- Fixed Issue #323: Improved deletion logic for water and drinks to prevent orphaned database entries and enabled direct editing.
- Fixed Issue #322: Resolved a crash occurring during certain nutrition summary updates.
- Fixed barcode scanner issues and added necessary network permissions for catalog refreshes.
- Hardened database actions to prevent potential data inconsistencies during concurrent operations.

## [0.9.3] - 2026-05-10
### Added
- Replaced the barcode scanner with a FLOSS-compatible ZXing-based implementation, improving privacy and removing dependencies on proprietary Google Play Services.

### Changed
- Simplified the onboarding nutrition recommendation flow: generated targets are now automatically applied when continuing through setup.
- Improved localized display names for exercises and food items where translations are available.
- Updated screenshots and README/website documentation to reflect the latest design and privacy-first positioning.
- Refined the primary color in light mode for a more polished visual experience.
- Set scanner resolution to maximum to improve barcode detection reliability across devices.

### Fixed
- Fixed a crash when manually adding food items during AI meal review.
- Fixed inconsistent border radius for uploaded images in the AI recommendation screen.
- Improved layout and input handling on the onboarding calorie recommendation page.

### Internal
- Removed Google ML Kit / Google Play Services from the barcode scanner dependency path.
- Updated website and README wording to clarify Train Libre’s privacy-first, offline-first positioning.

## [0.9.2] - 2026-05-09
### Added
- Added a macro and caffeine summary to the Water & Drinks section in the Diary.
- Added comprehensive localization for missing user-facing strings across workout, nutrition, and settings screens.

### Changed
- Redesigned "Today in Focus" layout with improved spacing, better visual hierarchy, and polished macro/micro nutrient rendering.
- Minor UI polish and accessibility improvements across Nutrition and Statistics screens.
- Improved offline catalog import resilience for certain published SQLite artifacts.
- Performance improvements for Statistics and Pulse aggregate queries.
- Deferred non-critical startup initialization to reduce first-frame work.
- Removed unused microphone and speech recognition permission declarations and documentation references.

### Fixed
- Fixed several layout overflows on small screens and compact devices.
- Fixed backup restore edge cases for some legacy backup variants.
- Fixed hydration and caffeine totals not updating correctly after editing tracked foods/drinks.
- Fixed the edit dialog not correctly restoring liquid toggle, caffeine, and sugar states.
- Fixed kcal missing in the Water & Drinks section for food-derived liquid entries.
- Fixed default entry time being incorrectly set to 00:00 for new entries.
- Miscellaneous bug fixes and stability improvements.

### Internal
- Documentation audit and cleanup: removed outdated behavioral statements, fixed broken links, and updated privacy policy.
- Permission metadata audit: verified iOS and Android manifests for accuracy and removed obsolete entries.
- Dependency updates and additional test coverage.

## [0.9.1] - 2026-05-06
### Changed
- Redesigned the Nutrition Recommendation UI: improved layout, clearer action affordances, and more consistent responsive behavior across device sizes.
- Fixed visual overflow and alignment issues on small screens.
- Improved accessibility and localization support for the nutrition recommendation controls.

### Fixed
- Minor bug fixes and performance improvements in the nutrition recommendation flow.

## [0.9.0] - 2026-05-05
### Added
- Initial Train Libre release with offline-first workout logging, reusable routines, nutrition tracking, hydration, supplements, body measurements, statistics, and local backups.
- Integrated Open Food Facts and wger-based catalog sources for food and exercise data.
- Added optional AI meal features using the user's own API key.
- Added one-way export of supported app-recorded data to Google Health Connect.
- Added native sharing for completed workouts and routines, including localized text exports and branded image share cards.

### Changed
- Renamed the app and repository branding from Hypertrack to Train Libre across Flutter, Android, iOS, widgets, documentation, package metadata, and local catalog filenames.
- Improved Statistics, Pulse, Diary, Add Food, workout history, and backup import/export performance for larger local datasets.
- Refined recovery, sleep, pulse, and nutrition analytics to make training guidance more transparent and robust.

### Fixed
- Preserved compatibility for legacy Hypertrack backups and catalog files while migrating new installs to Train Libre naming.
- Hardened loading and error handling across Statistics, Diary, Sleep, Pulse, AI meal save, feedback-report, and active workout flows.
- Reduced Android UI stalls and ANR risk by moving production Drift database work to a background isolate and reducing repeated database lookups.

## [0.9.0-beta.6] - 2026-05-05
### Fixed
- Fixed severe Pulse loading lag in Statistics by caching hourly heart-rate aggregates instead of repeatedly reprocessing large raw sample histories.
- Hardened Pulse aggregate cache coverage so small recent caches cannot be mistaken for complete older or larger ranges.

### Changed
- Pulse Hub summaries now use cached aggregate rows for range, average pulse, and resting-pulse estimates.
- Pulse detail charts now render from capped aggregate chart points while preserving the selected time range.

### Internal
- Added Drift persistence for hourly Pulse aggregates and aggregate metadata.
- Added regression coverage for large Pulse histories, incremental refresh, leading backfill, weighted aggregate metrics, chart point caps, and disabled tracking behavior.

## [0.9.0-beta.5] - 2025-05-05
### Fixed
- Renamed bundled and remote catalog database artifacts to Train Libre filenames while preserving legacy Hypertrack fallback compatibility.
- Added English iOS permission usage descriptions for camera, microphone, speech recognition, photo library, and Apple Health access, with German InfoPlist localization kept alongside them.
- Fixed Sleep day overview week/month loading helper wiring so analyzer, tests, and debug builds compile cleanly.
- Fixed a Diary water logging refresh issue where adding water after a refresh could trigger broad app reloads, causing lag or persistent loading states across tabs.
- Kept the selected Diary date stable when adding water from the Diary action path.

### Changed
- New installs now use Train Libre catalog database filenames by default, including `train_libre_training.db`, `train_libre_base_foods.db`, `train_libre_off_<country>.db`, and `train_libre_prep_<country>.db`.
- WGER and Open Food Facts refresh workflows/scripts now publish Train Libre database artifact filenames.
- Base-food sharing/export subjects now use the Train Libre database filename.
- activated minification so the size of the app shrinks

### Compatibility
- Existing local Hypertrack-named catalog files are migrated by copying to the Train Libre filename, verifying the copied size, and removing the old file only after verification.
- Remote catalog refresh prefers Train Libre artifact URLs and falls back to legacy Hypertrack artifact URLs when needed.
- Backup restore compatibility for legacy Hypertrack metadata and filenames remains intact.

### Internal
- Added regression coverage for Train Libre default filenames, explicit legacy fallback constants, local legacy file migration, remote fallback resolution, iOS InfoPlist permission strings, and legacy backup restore compatibility.
- Documented canonical Train Libre catalog filenames and legacy fallback behavior.

## [0.9.0-beta.4] - 2025-05-05
### Fixed
- Improved Statistics hub loading so slow or failing sections no longer block the entire tab.
- Replaced shared Statistics loading behavior with section-level stale-while-refresh state.
- Kept existing Statistics section data visible while range changes refresh in the background.
- Prevented stale async Statistics results from overwriting newer section data after rapid range changes.
- Fixed Statistics section error handling so failures remain local to the affected card instead of causing endless global loading.
- Fixed Sleep card visibility after Sleep tracking is disabled.
- Prevented in-flight Sleep and Pulse loads from re-rendering stale cards after their tracking features are disabled.
- Added missing cleanup/error handling for selected AI meal save and feedback-report actions to avoid stuck loading states.
- Improved Diary and Add Food performance by reducing repeated product and meal-total lookups.
- Fixed a Live Workout listener cleanup issue.

### Changed
- Statistics hub now loads Steps, Recovery, Sleep, Pulse, Consistency, Performance Records, Volume/Muscles, and Body/Nutrition independently.
- Added debug-only per-section performance timing logs for Statistics and related database/helper calls.
- Preserved Recovery as a fixed current-state metric while improving Statistics reload behavior.

### Internal
- Added regression coverage for section-level Statistics loading, stale result protection, gated Sleep/Pulse visibility, and failed load cleanup.
- Added performance diagnosis documentation for issue #313.
- Expanded focused performance/stability tests around Statistics, Add Food meal totals, product batch lookup, backup JSON processing, and save-flow loading cleanup.

## [0.9.0-beta.3] - 2025-05-05

### Fixed
- Fixed redundant Add Food meal-card refetching by caching meal total futures and using batched product lookup.
- Fixed repeated Diary product lookups by batch-loading products for the selected day.
- Fixed possible stale Statistics range results when switching range chips quickly.
- Fixed additional startup blocking by deferring non-critical initialization until after the first initializer frame.
- Moved Backup JSON encode/decode work off the main isolate to reduce UI stalls during import/export.

### Improved
- Improved Add Food meal performance during scrolling, rebuilds, and meal edits.
- Improved Diary loading performance for days with many food entries.
- Improved startup responsiveness while preserving ongoing workout restoration.
- Improved backup import/export responsiveness for larger backup files.

### Internal
- Added regression coverage for Add Food meal totals.
- Added batch product lookup coverage.
- Added backup isolate helper coverage.
- Added Statistics stale overlapping-load coverage.
- Full Flutter test suite passed with 509 tests.
- Android debug build completed successfully.

## [0.9.0-beta.2] - 2026-05-05
### Added
- Added native share-sheet support for completed workouts and routines.
- Added text exports with localized workout/routine summaries, set-type handling, workout volume, Train Libre branding, and the project GitHub link.
- Added branded image share cards for workouts and routines, including multiple workout layouts for summary, exercises, muscle focus, and minimal stats.

### Changed
- Redesigned workout text sharing to use readable per-set lines with localized special set-type suffixes.
- Redesigned routine image sharing to use compact set-type codes and two-column exercise cards with truncation and `+ X more` handling.
- Improved share-card branding by using the current Train Libre SVG logo.

### Fixed
- Moved the production Drift SQLite connection onto a background isolate to prevent database work from blocking touch handling and causing Android ANRs.
- Reduced workout-history database load by fetching completed workout sets in bulk instead of issuing one set query per workout log.
- Removed redundant food-search controller rebuilds while typing in Add Food, Food Explorer, and the general food picker.
- Prevented the Diary weight chart from reloading its database query on unrelated parent rebuilds.
- Preserved the selected Diary date after adding or logging food, meals, fluids, supplements, caffeine, measurements, AI meals, or workouts from a non-today Diary view.
- Removed a Live Workout session-manager listener on screen disposal to reduce memory-leak risk after leaving active workouts.
- Prevented dense workout and routine share cards from clipping long labels or overflowing the image canvas.
- Fixed muscle-focus share cards so high-exercise workouts keep the radar, top muscle-volume values, and footer inside the exported image.

## [0.9.0-beta.1] - 2025-05-02
### Changed
- Renamed the app and repository branding from Hypertrack to Train Libre across Flutter, Android, iOS, widgets, documentation, and package metadata.

### Fixed
- Preserved restore compatibility for legacy Hypertrack backups while creating new backups under the Train Libre name.

## [0.9.0-alpha.4] - 2026-05-02
### Fixed
- Hardened Sleep Health Score handling for ambiguous and missing stage data.
- Prevented `unknown` and ambiguous `inBedOnly` stages from inflating wake duration, WASO, interruptions, and sleep-efficiency penalties.
- Improved REM-missing and low-fidelity stage guardrails so scores do not imply unsupported certainty.
- Made Sleep Regularity Index availability depend on valid consecutive comparison pairs, not just raw valid-day count.
- Marked synthesized duration-only sleep windows as estimated instead of treating them like observed session bounds.
- Added targeted regression tests for missing-stage handling, stage guardrails, SRI coverage, and sleep-window fallback behavior.
- Improved Muscle Recovery readiness semantics with bodyweight strength support, explicit cardio exclusion, and centralized significant-load handling.
- Recalibrated recovery pressure so equivalent-set load no longer saturates after very small stimuli.
- Added muscle-specific recovery windows plus load- and intensity-based recovery extensions.
- Made RIR/RPE fatigue detection more robust and fixed inclusive recovery-state boundary behavior.
- Added robust recovery timestamp parsing and clarified fixed current-state recovery lookback behavior.
- Fixed remote OFF catalog import for currently published single-file SQLite artifacts that still use WAL header mode.
- Prevented remote catalog normalization from truncating downloaded DB files before import validation.
- Added startup retry behavior so failed remote refresh attempts bypass the normal minimum check interval on the next app launch.

### Changed
- Refined muscle recovery analytics by separating current readiness from last-load pressure in the Recovery Tracker.
- Updated recovery UI copy to show actual effective recovery windows and localized load-pressure levels.
- Improved recovery heuristic documentation for muscle-specific windows, readiness scoring, and load-pressure semantics.
- Startup loading status now reflects remote catalog preparation details during OFF/training refresh checks.

### Internal
- Expanded recovery regression coverage for equivalent-set pressure, bodyweight/cardio filtering, RIR/RPE fatigue thresholds, muscle-specific windows, boundary behavior, timestamp parsing, and recovery range policy.
- Updated statistics/recovery documentation to frame readiness as a transparent training-log heuristic rather than a clinical recovery prediction.
- Hardened remote catalog refresh services with WAL-header normalization, size-integrity guards, and focused regression coverage for OFF refresh edge cases.
- Updated OFF/WGER catalog refresh docs and generator scripts to enforce portable published SQLite artifacts (`journal_mode=DELETE`).

## [0.9.0-alpha.3] - 2026-04-26
### Internal
- updated the base nutrition database

## [0.9.0-alpha.2] - 2026-04-25

### Fixed
- Fixed Pulse day-scope handling so the current day is now included as a partial-day window (`start of day -> now`) instead of behaving like a fully completed 24-hour period.
- Added a small guard against zero-length Pulse day windows around local midnight rollover.
- Improved sleep heart-rate fallback behavior on Android / Health Connect setups by deriving sleep HR from the general heart-rate stream when strict sleep-session-linked heart-rate samples are unavailable.
- Improved robustness for vendor/device combinations such as Xiaomi Band setups where valid heart-rate samples may exist but are not reliably linked to sleep-session records.

### Changed
- Sleep heart-rate fallback now intersects general heart-rate samples with imported sleep-session time windows and remaps matched samples to the corresponding sleep session before use.
- The fallback path is still conservative: strict session-linked sleep HR remains preferred, and derived-by-window HR is only used when that stricter result is empty.

### Internal
- Added focused regression tests for:
  - Pulse current-day partial-window behavior
  - Health Connect sleep-HR derivation from general HR samples filtered by sleep windows

### Notes
- This release is a targeted reliability follow-up to `0.9.0-alpha.1`.
- Real-device validation remains especially important for Xiaomi Band / Health Connect combinations and for edge cases such as overlapping or adjacent sleep sessions.

## [0.9.0-alpha.1] - 2026-04-25

### Added
- Added opt-in Pulse analysis with a Settings toggle, heart-rate permission request, and a Statistics hub entry that appears only when enabled.
- Added a dedicated Pulse analysis screen with day/week/month period controls, pulse range, time-weighted average pulse, conservative resting-pulse estimate, and the existing line-chart pattern.
- Added a shared deterministic AI meal validation engine for capture and recommendations, including local DB matching quality, local nutrition recomputation, target-fit checks, visible warnings, and bounded repair orchestration.
- Added a separate opt-in setting for sending recent meal context to AI meal recommendations. It defaults off and recommendations still work without it.

### Fixed
- Improved Android sleep heart-rate retrieval for Health Connect providers that store valid in-session samples inside longer heart-rate records whose record window can sit outside the strict sleep/import window.
- Made AI meal save behavior explicit when some recognized/recommended items are unmatched, so partial saves no longer look like all AI items were saved.

### Changed
- Updated Apple Health usage copy to mention enabled health views that read steps, sleep, and heart-rate data.
- AI meal recommendations now locally verify kcal/protein/carbs/fat fit against the intended remaining meal target before acceptance, with up to three automatic repair passes.
- AI meal capture now validates recognized quantities, DB matches, and recomputed nutrition before showing the review screen, with up to three automatic repair passes.

### Internal
- Modernized the Android app module Java/Kotlin compile target from 8 to 17 to match the current Gradle/AGP/JDK toolchain and reduce app-owned build warnings.
- Replaced the foreground rest-timer sound cue with Flutter's built-in system alert sound and removed the `flutter_ringtone_player` dependency to eliminate its Android Java 8/deprecated API build warnings.
- Documented the Pulse MVP boundaries and the Health Connect sleep HR fallback behavior.
- Documented the AI meal capture/recommendation validation architecture and added focused validation/repair tests.

### Notes
- The former `flutter_ringtone_player` warning source was reviewed: version 4.0.0+4 still declares Java 8 compatibility and uses the deprecated Android `Ringtone.setStreamType(...)` API. The app only used it for the foreground rest-timer notification sound, so replacing that single call was lower-risk than keeping or suppressing the plugin warning.

## [0.8.11] - 2026-04-23

### Fixed
- Improved workout heart-rate retrieval reliability for vendor-originated Health Connect data by adding a safe fallback query window when the strict workout window returns no records.
- Restored the missing Measurements shortcut on the Statistics hub so body measurements are reachable again from the Body section.

### Changed
- Continued the Settings IA cleanup with a conservative extraction pass:
  - moved Appearance settings into a dedicated sub-screen
  - moved Steps settings into a dedicated sub-screen
  - moved Sleep settings into a dedicated sub-screen
  - kept Health export in its dedicated sub-screen for consistent structure
- Reorganized top-level Settings into broader sections for better scanability:
  - App
  - Health & Tracking
  - Nutrition & Data
  - Support / About
- Moved “Restart app tour” to the bottom of the App section.
- Refined a few Settings entry icons for better visual consistency.

### Notes
- This release focuses on low-risk UX structure improvements and targeted compatibility fixes without changing settings persistence semantics.

## [0.8.10] - 2026-04-15

### Fixed
- Improved backup/restore robustness so malformed or legacy-shaped payload rows no longer abort the full import as easily.
- Hardened supplement settings/history restore handling for legacy ID mappings and more tolerant type parsing.
- Improved body/nutrition trend loading stability so outdated async responses no longer overwrite newer range selections.
- Prevented malformed analytics chart inputs from causing unstable rendering in normalized trend charts.
- Reduced small-screen layout issues in the body/nutrition trend legend by switching to a wrapping layout.
- Reduced the risk of synthetic workout-session ID collisions in edge cases.

### Improved
- Polished the body/nutrition drill-down fallback state with clearer empty/error messaging.
- Improved resilience of health-step-segment restore by sanitizing malformed rows before database upsert.
- Replaced remaining raw debug print behavior in workout session restore with safer debug logging.

### Notes
- This release focuses on stability, restore safety, analytics robustness, and small UI polish improvements.

## [0.8.9] - 2026-04-15

### Changed
- Reworked the **Bodyweight ↔ Calorie analytics feature** from a simple correlation approach to a more robust **trend-summary model**.
- Replaced correlation-style interpretation with clearer classification of observed patterns:
  - cut-like (lower intake + falling weight)
  - bulk-like (higher intake + rising weight)
  - maintenance-like (stable/stable)
  - mixed or unclear signals
- Improved wording and interpretation to avoid overconfident or misleading conclusions and emphasize non-causality.
- Reused the weekly sleep-window chart pattern in the Sleep regularity detail view for more consistent sleep-timing visualization and reduced duplicated chart logic.

### Added
- Introduced a **normalized dual-line trend chart** (weight + calories) where both series start at the same baseline, making relative trend comparison significantly clearer.
- Added explicit **confidence levels** (`high`, `moderate`, `low`, `insufficient`) based on data quality.
- Added **data-quality diagnostics**, including coverage, overlap, and gap awareness, to support more honest insights.
- Added workout heart-rate summaries and charts to make already recorded heart-rate data visible after training.
- Added basic workout heart-rate metrics including average, maximum, and minimum heart rate where data is available.
- Added a dedicated heart-rate section to the workout detail screen with a session heart-rate line chart.
- Added a compact heart-rate summary block to the post-workout summary screen.

### Improved
- Significantly strengthened **data sufficiency and quality gating**:
  - minimum time span and data coverage requirements
  - overlap validation between weight and calorie logs
  - gap penalties and noise handling
- Redesigned the **Statistics hub Body & Nutrition card**:
  - clearer quick-scan summary
  - compact trend labels and relationship classification
  - embedded normalized mini chart
  - explicit confidence and data basis indicators (e.g. number of weigh-ins and logged days)
- Reworked the **Body & Nutrition detail screen**:
  - replaced separate charts with a single combined normalized comparison chart
  - simplified and clarified the interpretation section
  - removed the body-measurements shortcut to reduce visual noise and improve focus
- Added workout heart-rate data-quality handling with clearer fallback states for missing, sparse, or limited samples.
- Reused existing health-platform data flows with lightweight workout-window matching instead of introducing a heavier persistence layer for the MVP.

### Fixed
- Eliminated misleading or weak “correlation” outputs in sparse or noisy datasets.
- Reduced risk of overinterpreting incomplete or low-quality data by enforcing stricter gating and clearer fallback states.

### Notes
- This feature focuses on **trend context, not causal inference**.  
  Observed relationships between calorie intake and bodyweight should be interpreted as patterns, not direct cause-effect conclusions.

## [0.8.8] - 2026-04-15

### Changed
- Completed a repo-wide UI consistency pass for app-owned alerts by migrating remaining standard `AlertDialog` flows to the existing Hypertrack glass action-sheet/dialog component.
- Migrated save/confirm/action dialogs in key flows:
  - onboarding restore password prompt
  - post-onboarding app-tour offer
  - AI key-missing prompts (capture + recommendation)
  - nutrition edit dialogs (food + fluid) and fluid delete confirmation
  - settings OFF region picker and attribution/licenses dialog
  - data import success acknowledgment in Data Management
- Extended the shared custom dialog helper with optional strict modal behavior (`isDismissible` / `enableDrag`) for critical confirmation flows.

### Fixed
- Removed remaining app-level default alert style mismatches in migrated screens so action dialogs now follow one consistent Hypertrack UI pattern.
- Preserved existing action semantics and async handling across migrated flows (confirm/cancel/save/delete outcomes unchanged).

### Internal
- Cleaned up remaining analyzer issues, including widget constructor keys, naming consistency, model API cleanup, and minor test/dev code refactors.

### Notes
- Intentionally kept native-style blocking loading overlays (spinner dialogs used during workout-start operations) unchanged, since these are progress overlays rather than app decision dialogs.

## [0.8.7] - 2026-04-15

### Added
- Added a short optional post-onboarding app tour with spotlight/coach-mark guidance through the main app structure.
- Added a Settings entry to restart the app tour at any time.

### Changed
- Polished app-tour coach-mark positioning to keep the explanation panel clear of the bottom navigation area while preserving anchor context.
- Refreshed the app icon for this release.

## [0.8.6] - 2026-04-13

### Added
- Added an optional, user-triggered feedback/diagnostic report flow in Settings:
  - local report generation only (no automatic upload or hidden submission)
  - explicit preview before any sharing action
  - explicit actions: copy, save temporary `.txt`, share via native sheet, or open prefilled email draft to `feedback@schotte.me`
  - optional section toggles for adaptive nutrition diagnostics, backup/restore diagnostics, and user note

### Changed
- Reordered top-level Settings sections for a clearer flow:
  - Appearance
  - Diary
  - AI Meal Capture
  - Steps
  - Sleep
  - Health export
  - Data backup & import
  - Food database
  - Support
  - About & legal

## [0.8.5] - 2026-04-13

### Added
- Added Open Food Facts multi-country refresh/distribution infrastructure with dedicated country channels:
  - `off-foods-de-stable`
  - `off-foods-us-stable`
  - `off-foods-uk-stable`
- Added country-specific OFF release artifacts and metadata pipeline:
  - `hypertrack_off_<country>.db`
  - `off_build_report_<country>.json`
  - `off_catalog_manifest_<country>.json`
  - `off_diff_report_<country>.json`
  - `off_release_notes_<country>.md`
- Added OFF helper scripts for workflow robustness and maintainability:
  - `off_catalog_diff.py`
  - `resolve_off_reference_manifest.py`
  - `build_off_catalog_manifest.py`
  - `build_off_release_notes.py`
  - `publish_off_run_summary.py`
- Added OFF country-aware remote adoption service and startup integration:
  - `OffCatalogRefreshService`
  - `BasisDataManager` OFF remote-candidate adoption with safe fallback behavior
- Added user-facing settings UI for selecting the active food database region:
  - Germany (DE)
  - United States (US)
  - United Kingdom (UK)

### Changed
- OFF catalog generation is now explicitly country-parameterized and bulk-parquet based (`create_off_food_db.py` CLI).
- OFF manifest contract was formalized with integrity + safety fields:
  - `source_id`, `country_code`, `channel`, `version`
  - `db_sha256`
  - `product_count` (informational)
  - `min_product_count` (hard validation floor)
- OFF diff baseline strategy now compares against previous published release assets per country channel (not repository baseline files).
- OFF installed-version tracking moved to country-scoped keys (`installed_off_version_<country>`), with legacy migration safety for existing DE installs.
- Settings flow now clearly communicates that OFF region changes are applied through the existing next refresh/import cycle.

### Fixed
- Hardened OFF startup safety when bundle and remote are unavailable for a selected country: imports are skipped safely without destructive side effects.
- Preserved historical nutrition continuity under OFF region/catalog changes by keeping `off` + `off_retained` semantics intact.

### Notes
- The bundled DE OFF database fallback remains intentionally included for staged rollout safety.
- Supported OFF app regions in this release are DE, US, and UK.

## [0.8.4] - 2026-04-13

### Added
- Added end-to-end remote exercise catalog refresh channel using release assets (`wger-catalog-stable`) with app-side adoption flow.
- Added dedicated catalog artifacts and supporting reports (`wger_build_report.json`, `wger_diff_report.json`, manifest).
- Added helper scripts for workflow robustness:
  - `build_wger_catalog_manifest.py`
  - `resolve_wger_reference_manifest.py`
  - `build_wger_release_notes.py`
  - `publish_wger_run_summary.py`
- Added regression tests for exercise catalog ID-upsert semantics and historical workout restoration under catalog drift.

### Changed
- Catalog refresh now uses stricter manifest contract and validation rules (source/channel/version/url checks).
- Threshold semantics were clarified and enforced:
  - `expected_exercise_count` is informational
  - `min_exercise_count` / minimum rows is the hard validation floor.
- Diff baseline logic now compares against the previously published release asset DB (not the committed repository DB baseline).
- Workflow hardening for scheduled/manual refresh + channel publication, including safer gating and artifact handling.
- App-side exercise base import now uses non-destructive `ON CONFLICT(id) DO UPDATE` behavior for catalog rows.
- Workout detail/summary/session restore paths now resolve exercises by stored `exercise_id` first, with graceful fallback.

### Fixed
- Fixed potential aggressive refresh behavior by avoiding replace-style writes for base exercises.
- Fixed a history integrity risk where session restore could lose blocks if exercise names changed after catalog update.
- Fixed set-log update behavior to preserve existing `exercise_id` linkage when name lookup no longer matches.
- Preserved historical usability when exercise rows are missing by preventing silent loss in restore flows.

### Internal / Tooling
- Hardened workflow implementation by moving fragile inline scripting to dedicated Python utilities.
- Improved release-channel publication plumbing and run-summary diagnostics.
- Updated catalog refresh documentation to match current non-destructive import semantics and release-asset distribution model.

### Notes
- Existing workout logs continue to resolve via stable exercise IDs where present; metadata updates for the same ID are reflected.
- Upstream-removed exercises are preserved locally (no hard-delete sweep in refresh path), maintaining history integrity and selector availability for retained rows.

## [0.8.3] - 2026-04-12

### Removed
- Removed the complete home-screen widget feature from MVP scope on all platforms (Flutter, Android, iOS).
- Removed Android app-widget provider/resources and iOS WidgetKit extension target integration.
- Removed widget-specific app startup, deep-link launcher, and shared widget bridge/config plumbing.

### Changed
- Regenerated app localizations after removing widget-only translation keys.
- Cleaned release notes/changelog references tied only to the removed widget rollout.

### Fixed
- Restored reliable iOS simulator install/runtime by removing broken app-extension integration from the app build.
- Preserved and kept active the Measurements deletion persistence fix (including legacy timestamp fallback behavior).

## [0.8.3-alpha.2] - 2026-04-11

### Changed
- Refined **Today in Focus** widget density and spacing on both iOS and Android to reduce wasted space and show more useful data in the same widget area.
- Improved small-widget layout behavior on iOS with tighter typography and padding, allowing more compact metric presentation.
- Improved Android widget row sizing, spacing, and adaptive visibility logic so medium/large widget sizes can display more metrics.

### Fixed
- Fixed measurement deletion persistence in the Measurements screen: swiping to delete now removes the session from storage, not only from the current UI state.
- Hardened measurement-session deletion for legacy records by adding a timestamp-based fallback when legacy session IDs are missing.

## [0.8.3-alpha.1] - 2026-04-10

### Added
- Added a first alpha version of the new **Today in Focus** home-screen widget.
- Widget supports configurable daily metrics such as calories, protein, water, carbohydrates, sugar, fat, caffeine, creatine, supplements, steps, workouts, and sleep.
- Added widget configuration support for visible metric selection and maximum visible item count.
- Added widget tap behavior to open the app directly into the Diary / Tagebuch flow.
- Added a new **Haptic feedback** setting, enabled by default.

### Changed
- Finalized the app’s haptic feedback behavior through a centralized, settings-aware feedback layer.
- Added lightweight confirmation haptics for meaningful completion actions such as saving, adding, applying, starting, and finishing.
- Preserved existing haptic behavior for tab switching, FAB interactions, chart-point dragging, and timer completion flows.
- Added subtle AI waiting haptics during active generation/loading states.

### Fixed
- Fixed missing confirmation haptics on important add/save actions in several key flows.
- Fixed AI waiting haptics so they stop correctly when generation finishes and no longer continue into review/result screens.
- Refined the AI waiting haptic pattern to feel more periodic and less abrupt.

## [0.8.2] - 2026-04-10

### Changed
- Reorganized the Workout, Statistics, and Nutrition hub screens to better separate training actions, analytics, and nutrition tools.
- Updated hub section structure and ordering to reduce overlap and make navigation clearer.
- Workout hub now focuses on starting training, managing routines, and accessing workout history / exercise library.
- Nutrition hub now groups adaptive recommendation, goals, meals, and nutrition tools more clearly.
- Statistics hub now groups content into Steps, Recovery, Training, and Body sections.

### Fixed
- Removed redundant hub entries that added clutter without meaningful functionality.
- Fixed remaining localization regressions from the hub reorganization by replacing hardcoded Statistics UI strings with proper l10n usage.
- Standardized uppercase section-header rendering across the reorganized hub screens.
- Ensured hub entry labels and section names are consistently localized in German and English.
## [0.8.1] - 2026-04-09

### Fixed
- Improved sleep day-view timeline readability with clearer timestamp labels, better spacing, and stronger light/dark-mode contrast.
- Corrected the weekly sleep-window chart so displayed time bounds and axis labels better match actual sleep session timing, including cross-midnight sessions.
- Sleep scoring now applies conservative stage-aware guardrails so mostly-light or REM-missing nights (especially from limited-fidelity sources such as Withings) cannot silently receive near-perfect totals.
- Depth-related sleep feedback now better reflects light-dominant nights instead of relying on deep-sleep percentage alone.

### Changed
- Weekly sleep-window aggregation now prefers canonical session start/end bounds when available, instead of relying only on derived duration placement.
- Sleep scoring pipeline now passes stage mix, timeline confidence, and source metadata into the score calculation.

### Internal
- Added targeted regression coverage for:
  - sleep day-view timeline timestamp rendering
  - weekly sleep-window axis bounds and cross-midnight behavior
  - stage-aware sleep score guardrails
  - limited-source / missing-REM scoring behavior
  - repository propagation of canonical session start/end times

## [0.8.0] - 2026-04-09

### Added
- User-facing maintenance uncertainty range and stabilization hints on adaptive recommendation surfaces.
- Canonical adaptive diet-phase tracking (`cut`/`maintain`/`bulk`) with deterministic 7-day confirmation for phase changes.

### Changed
- Adaptive nutrition recommendation now ships as a canonical Bayesian recursive system with explicit manual apply workflow.
- Adaptive recommendation observation scaling now uses confirmed-phase-age ramping (`3000 -> 7700` kcal/kg through week 9+) instead of window-length scaling.
- Generation semantics remain due-week anchored and deterministic within a due week, including force-recalculation replay behavior.
- Due-notification eligibility is strictly gated by due-week status, generated-state status, and notification-state status.

### Fixed
- Hardened adaptive recommendation persistence with coherent snapshot/state checks, legacy fallback migration handling, and recovery from malformed canonical keys.
- Ensured backup/restore continuity for adaptive recommendation settings and canonical recursive state persistence.

### Internal
- Expanded adaptive nutrition regression coverage across domain/data/presentation/scenario layers, including long-horizon simulations, phase-transition scenarios, and backup/restore continuity validation.

### Acknowledgements
- Thanks to @Whatsonyourmind for thoughtful review and feedback on the adaptive nutrition model, uncertainty presentation, and edge-case framing during the 0.8.0 development cycle.

## [0.8.0-alpha.3-bayesian-preview.3] - 2026-04-08

### Added
- Canonical adaptive diet-phase model (`cut`, `maintain`, `bulk`) with persisted confirmed/pending phase tracking.
- Deterministic 7-day phase-change confirmation flow:
  - pending candidate starts on direction change
  - confirmed phase switches only after 7 stable days
  - reverting before confirmation cancels pending reset
- Lightweight residual-bias diagnostic seam for weekly observation validation:
  - mean residual summary
  - sample count
  - bias direction status (`neutral`, likely over/under-estimating energy density)

### Changed
- Replaced the window-length kcal/kg observation scaling with confirmed-phase-age ramping:
  - week 1 = `3000`
  - linear ramp to week 9 = `7700`
  - week 9+ stays at `7700`
- Exact target-rate changes no longer define new adaptive phases; only goal direction does.
- Adaptive recommendation copy (EN/DE) now uses simpler wording that clearly separates:
  - “still adapting/settling”
  - normal uncertainty around likely maintenance range
- Adaptive nutrition current-state docs updated for confirmed-phase semantics, ramp behavior, and residual diagnostics seam.

### Testing
- Expanded adaptive nutrition scenario-test infrastructure with reusable synthetic-truth and recovery metrics helpers:
  - convergence milestones (initial / week-4 / week-8 / week-12)
  - signed/absolute error progression
  - error half-life and settling-time checks
  - bounded overshoot/undershoot and truth-crossing checks
  - pre/event/post recovery-window summaries for posterior, variance, and confidence
  - bounded weeks-to-recover checks for transient event scenarios
- Strengthened ground-truth scenario assertions to validate quantitative convergence behavior, not only boundedness/stability.
- Strengthened chaotic scenario assertions (weekend spikes, refeed, water jump, illness, logging-quality phases) to validate measurable disruption and recovery behavior.
- Added comparative long-horizon profile validation (8–12 week style horizons) with directional plausibility checks across matched profile pairs:
  - heavier vs lighter
  - lean vs higher body-fat at comparable size
  - high vs low activity
  - male/female/unknown plausibility banding
  - high-steps vs low-steps long-horizon relation

## [0.8.0-alpha.3-bayesian-preview.2] - 2026-04-07

### Added
- Data-calibrated Bayesian noise adaptation for adaptive nutrition:
  - bounded history-informed scaling for `Q` (maintenance drift variance)
  - bounded history-informed scaling for `R` (observation variance)
  - deterministic fallback to conservative defaults when history is insufficient
- User-facing maintenance uncertainty transparency:
  - likely maintenance range derived from posterior uncertainty (`mean ± 1σ`)
  - plain-language uncertainty hints on adaptive recommendation surfaces
  - stabilization hint when the recursive estimate is still settling
- Stabilization sanity-check layer derived from live vs steady-state behavior:
  - quality flags for bootstrap/transient/noisy regimes
  - conservative confidence guard during settling phases
- Expanded Bayesian estimator/service/repository/UI tests for:
  - calibration responsiveness and bounds
  - fallback safety under sparse history
  - stabilization flags and onboarding stabilization copy
  - maintenance estimate/state persistence coherence

### Changed
- Adaptive nutrition current-state docs were updated for production-style clarity, including:
  - data-calibrated `Q/R` semantics
  - credible-interval presentation semantics
  - stabilization/sanity-check behavior
  - user-facing behavior
  - scheduling and stable data-window semantics
  - recursive Bayesian prediction/update chaining
  - apply vs recalculate behavior
  - persistence and due-notification semantics
  - confidence/warning interpretation
- The nutrition recommendation card and onboarding preview now include maintenance range + uncertainty/stabilization copy without changing explicit apply semantics.
- README documentation navigation label was tightened to reflect canonical Bayesian architecture wording.

### Internal
- Adaptive nutrition terminology and inline comments were normalized further around recursive Bayesian, uncertainty, and due-week semantics.

## [0.8.0-alpha.3-bayesian-preview.1] - 2026-04-06

### Added
- Experimental Bayesian/Kalman adaptive nutrition estimation path
- Atomic Bayesian experimental snapshot persistence
- Manual “Recalculate now” action for adaptive recommendations
- Recommendation freshness metadata in UI:
  - calculated at
  - next adaptive recommendation due
  - due now indicator
- Scheduler-based due-notification seam for new adaptive recommendations
- Richer estimator comparison/debug tracing
- Documented Bayesian estimator tuning parameters

### Changed
- Bayesian experimental state now uses atomic snapshot persistence as unified state storage
- Due-notification logic now requires:
  - recommendation is currently due
  - no recommendation has yet been generated for that due week
  - no notification has yet been sent for that due week
- Snapshot generation time is now sourced only from `recommendation.generatedAt`
- German adaptive notification strings now use proper umlauts and cleaner wording
- Manual recalculation now forces immediate regeneration without auto-applying active goals

### Fixed
- Safer handling of incoherent or corrupt Bayesian experimental state
- Safer migration from legacy fragmented Bayesian persistence
- Removed remaining active use of fragmented Bayesian write paths in normal experimental flow

### Internal
- Production heuristic recommendation path remains unchanged and authoritative
- Legacy fragmented Bayesian keys are now migration-only fallback support
- Documentation reviewed and updated to match final enforced behavior
## [0.8.0-alpha.2] - 2026-04-06

This alpha improves the adaptive nutrition recommendation MVP with more conservative sparse-data behavior, more robust trend estimation, better step-prior maintenance inputs, and clearer recommendation transparency.

### Added
- Recommendation transparency copy layer shared across onboarding and nutrition hub surfaces.
- New data-basis hint messaging for:
  - profile/prior-only recommendations
  - sparse recent weight logs
  - sparse recent intake logs
  - sparse weight + intake logs together
- New specific warning copy for macro-constrained recommendations.

### Changed
- `notEnoughData` recommendations are now strictly prior-only:
  - no inferred-maintenance blending
  - no week-over-week maintenance drift against previous recommendations
  - goal-rate calorie adjustment still applies on top of the prior estimate
- Prior maintenance estimation now uses step input with the following precedence:
  1. recent average actual daily steps
  2. configured daily step target
  3. fallback default of `8000`
- Recent actual step averages now use synced step data from the rolling lookback window when available.
- Weight-trend estimation now uses linear regression over EWMA-smoothed bodyweight data instead of endpoint-only delta.
- Recommendation surfaces now frame confidence as **data basis quality** rather than scientific certainty.
- Onboarding adaptive recommendation preview now shows:
  - data basis label
  - data basis counts
  - explicit prior-only messaging when applicable
  - prioritized warning text aligned with the nutrition hub card
- Recommendation warning prioritization is now more explicit:
  - calorie floor applied
  - unresolved food calories
  - large adjustment detected
  - macro distribution constrained
  - generic conservative fallback only when no more specific warning applies
- EN/DE adaptive recommendation wording was revised to match the new semantics and transparency model.

### Fixed
- Prevented sparse-data recommendations from drifting maintenance estimates despite explicitly insufficient adaptive data.
- Reduced sensitivity of weekly trend estimation to noisy start/end bodyweight values.
- Improved recommendation copy so unresolved food-calorie issues are surfaced more clearly before apply.
- Fixed onboarding progress/button logic so the final onboarding page cleanly exposes the finish action.

### Documentation
- Updated the adaptive nutrition recommendation current-state documentation to match implementation truth for:
  - strict prior-only `notEnoughData` behavior
  - regression-based weight slope calculation
  - step-priority precedence (`actual -> target -> default 8000`)
  - compact prioritized basis/warning messaging
  - continued treatment of extra cardio as a coarse manual heuristic

### Testing
- Added and updated automated tests for:
  - strict prior-only engine behavior
  - actual-steps vs target-steps fallback precedence
  - regression-based weight trend calculation
  - prior-only UI messaging
  - unresolved-food warning rendering
  - onboarding preview transparency
  - final onboarding-page finish behavior

### Notes
- Extra cardio remains a manual heuristic input and is not backed by a dedicated cardio-tracking model.
- Recent actual step averages currently use usable logged days only within the lookback window.

## [0.8.0-alpha.1] - 2026-04-06

This alpha introduces the first end-to-end MVP of adaptive nutrition recommendations.

### Added
- Adaptive weekly nutrition recommendation foundation:
  - repository persistence
  - due-week scheduler
  - recommendation input adapter
  - recommendation engine
  - orchestration service
- Nutrition hub recommendation card integration with:
  - confidence + warning display
  - explicit apply action for active targets
- Onboarding adaptive recommendation flow with:
  - dedicated goal/rate/activity/cardio setup
  - dedicated optional body-fat onboarding step
  - body-fat guidance entry point with text-based male/female reference helper
- Goals screen recommendation settings for:
  - bodyweight goal direction
  - weekly target rate
  - baseline daily activity
  - extra cardio/endurance outside the app
- New adaptive recommendation persistence keys in `SharedPreferences` for settings/state snapshots.

### Changed
- Onboarding order is now:
  - Welcome
  - Profile
  - Bodyweight
  - Body fat %
  - Adaptive goal/recommendation settings
  - Calories
  - Macros
  - Water
- Baseline activity model expanded from 3 to 4 levels:
  - low
  - moderate
  - high
  - very high
- Activity-level helper UX is now structured and easier to scan (intro + one line per level), and remains separate from extra-cardio input.
- Prior maintenance estimation is now more personalized for MVP:
  - uses body-fat/lean-mass-aware path when body-fat % is available
  - falls back safely when body-fat is missing
  - applies declared baseline activity + extra-cardio influence conservatively
- Recommendation generation is stable per due week (no in-week drift from Monday vs later-week app-open timing).
- Recommendation-related EN/DE strings were moved/expanded in l10n and regenerated.

### Fixed
- Prevented implausible calorie outputs from being surfaced without explicit constrained/warning handling.
- Hardened calorie-input aggregation paths to reduce systematic undercounting in common logging scenarios.
- Ensured backup/restore explicitly covers adaptive recommendation settings:
  - `adaptive_nutrition_recommendation.prior_activity_level`
  - `adaptive_nutrition_recommendation.extra_cardio_hours`

### Testing
- Added and updated automated tests for:
  - recommendation domain logic
  - recommendation persistence/state behavior
  - due-week stability behavior
  - onboarding/goals recommendation flows
  - backup/restore coverage for adaptive recommendation keys

## [0.7.10] - 2026-04-05

This release includes a fix for Diary refresh behavior after saving meals through the AI meal-recognition flow.

### Fixed
- Fixed a Diary refresh issue after saving meals via the AI meal-recognition flow
  - when a meal was recognized with AI and saved from the Add Food flow, the Diary screen did not always refresh automatically
  - the save result is now propagated correctly so the Diary reloads immediately after the meal is saved
  - no manual pull-to-refresh is needed in that flow anymore

### Notes
- This fix specifically addresses the Diary → Add Food → AI meal recognition path
- The direct AI recommendation save flow already propagated refresh correctly
## [0.7.9] - 2026-04-07

small fixes
## [0.7.8] - 2026-04-05

This release is a maintenance and stability update that prepares Hypertrack for the upcoming 0.8 / TDEE cycle.

### Fixed
- Fixed backup/restore integrity for meal-related data
  - meal templates and meal items are now included in backups
  - meal/nutrition restore behavior is more complete and reliable
- Improved nutrition backup robustness when food entries rely on product references / barcode fallback
- Improved goals/settings restore behavior
  - changed targets are restored correctly
  - fallback restore behavior no longer depends on profile payload always being present
- Improved supplement restore integrity
  - tracked-state and supplement history restore behavior are more reliable
- Improved workout restore fidelity
  - preserves more set metadata and ordering details during restore

### Improved
- Updated project dependencies to current resolvable versions
- Resolved API breakages caused by dependency upgrades
  - notifications
  - file picker
  - CSV handling
- Stabilized the automated test suite
  - fixed outdated expectations
  - reduced brittle widget-test failures
  - improved deterministic test behavior
- Expanded automated test coverage in important low-level areas
  - backup/restore
  - goals and target persistence
  - weight/history foundations
  - statistics data
  - storage/services

### Internal / maintenance
- Better regression protection for backup, restore, and persistence behavior
- Better groundwork for future TDEE development in 0.8
- General cleanup and hardening across data/services/test infrastructure

### Notes
- This is primarily a maintenance/stability release
- The focus of this version is correctness, persistence integrity, and preparation for the next major feature cycle

## [0.7.7] - 2026-04-04

This release focuses on AI provider expansion, AI settings cleanup, and a small Diary improvement.

### Added
- Optional **Sugar** tile for the Diary overview
  - can be enabled in Settings
  - disabled by default
  - uses existing sugar tracking + existing sugar target
  - rendered inside the existing top Diary overview section

- Expanded **AI provider support** for:
  - OpenAI
  - Google Gemini
  - Anthropic / Claude
  - Mistral
  - xAI / Grok

- AI settings improvements
  - dedicated grouped AI settings section
  - master **Enable AI features** toggle
  - AI features now default to **off**
  - provider, model, and API key configuration hidden unless AI is enabled

### Changed
- Reworked AI model selection logic for meal analysis
  - provider-specific curated model handling
  - live provider model APIs used as availability source
  - better ranking of newer/current models
  - improved provider-specific filtering
  - more robust selected-model resolution

- OpenAI integration improvements
  - better handling of model names / aliases
  - fixes for OpenAI request parameter handling
  - improved error reporting

- Gemini integration improvements
  - more robust model normalization and fallback handling
  - improved error reporting
  - better compatibility across Gemini model variants

- Diary overview layout updated
  - optional Sugar tile now appears in the same existing overview area
  - placed at the bottom of the left column when enabled

### Notes
- End-to-end tested providers in this release:
  - OpenAI
  - Gemini

- Implemented but not fully end-to-end verified in this release:
  - Anthropic
  - Mistral
  - xAI

## [0.7.6] - 2026-04-04

This release focuses on a small set of quality-of-life improvements across AI meal capture, measurements, workout logging, iOS navigation behavior, and rest timer alerts.

### Improved

- **AI meal capture UI**
  - Removed the dedicated in-app microphone button from the AI meal recognition screen
  - Moved camera and gallery actions directly into the main text input area for a cleaner and more focused layout
  - Preserved the existing prompt + image-based analysis flow

- **Measurements screen defaults**
  - The measurements chart now defaults to **weight** when weight data is available
  - Existing fallback behavior remains unchanged when weight is not present

- **Workout logging inputs**
  - Reps, weight, and related workout input fields are no longer prefilled with `0`, `0kg`, or similar zero-value defaults when unset
  - Empty fields now remain truly empty until the user enters data, while existing hint/subtext behavior is preserved

- **iOS navigation consistency**
  - Improved swipe-back behavior on iOS for settings-related navigation paths
  - Preserved explicit settings result propagation for cases where values actually changed

- **Pause timer completion alerts**
  - Foreground timer completion continues to trigger an audible/vibration alert
  - Background timer completion now more reliably triggers a notification instead of silently finishing

### Fixed

- Fixed AI meal capture layout/actions so media input controls are placed where users expect them
- Fixed measurement chart default selection logic
- Fixed workout field initialization so unset values are not rendered as actual entered values
- Fixed a settings/navigation path that interfered with native iOS back-swipe behavior
- Fixed the Android/background timer completion path so users are still alerted when the app is not in the foreground

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
- **Health export is one-way only**. Hypertrack remains the authoritative record.
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
- Export remains **one-way only**. Hypertrack is the authoritative record.
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
- Project docs rewritten and consolidated around implementation-first references.

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

This alpha finalizes the Sleep health-score pass. It documents and ships the implemented V1 scoring model, persists additional nightly analysis fields for score completeness and regularity, expands Sleep day/detail messaging and localization, and refreshes core documentation so release notes and docs align with implementation.

### Added
- Sleep Health Score V1 documentation describing the implemented scoring model, component weights, regularity rules, completeness semantics, and known limitations.
- A canonical Sleep current-state document that describes the routed screens, repositories, pipeline flow, persistence layers, and implementation boundaries.
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
- Fixed release/documentation accuracy by replacing stale or historical descriptions with implementation-grounded documentation and clearer boundaries around what is actually implemented.
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
- **Unified goal storage**: User goals (Calories, Macros, Water) migrated from `SharedPreferences` to the SQLite database (`app_settings` table). Changing goals now updates the Dashboard instantly without restart.

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
- **Unified storage:**
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
