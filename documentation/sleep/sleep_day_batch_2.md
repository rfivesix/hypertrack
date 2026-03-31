# Sleep Module Batch 2 — Day Experience Vertical Slice

## What was implemented (refinement pass)

This batch delivers a cohesive Day sleep UX vertical slice:

- Day Overview hub screen with:
  - segmented control (day/week/month toggle shell; day behavior implemented),
  - stage timeline block,
  - sleep quality score card (ring + status label + subtitle),
  - metric tile grid (Duration, Heart rate, Regularity, Depth, Interruptions).
- Full detail-screen set:
  - Duration detail with benchmark visualization and explanatory copy.
  - Heart-rate detail with baseline-relative context and neutral baseline-missing behavior.
  - Interruptions detail with count + total wake duration.
  - Depth detail with stage distribution and confidence-aware fallback.
  - Regularity detail with 7-night range chart and midnight-wrap handling utilities.
- Centralized Sleep navigation helper using named routes.
- Provider-style state management for the day screen using `SleepDayViewModel`.
- Real in-app reachability entry from Statistics Hub.

## Real app reachability

The Sleep Day screen is now reachable in normal app flow:

1. Open the app
2. Go to the **Stats** tab (bottom navigation)
3. In **Statistics Hub**, tap the **Sleep** card section
4. This opens the Sleep Day overview (`/sleep/day`)

## Screen architecture and navigation flow

### Day hub

- `SleepDayOverviewPage` owns Day UX composition.
- It is backed by `SleepDayViewModel` (`ChangeNotifier`) which calls a repository interface (`SleepDayDataRepository`).
- The page gracefully handles loading and empty states.
- Week/Month segmented choices explicitly show “not implemented in this batch” fallback messaging.
- Tile taps route through `SleepNavigation` helper to named routes:
  - `/sleep/day/duration`
  - `/sleep/day/heart-rate`
  - `/sleep/day/regularity`
  - `/sleep/day/depth`
  - `/sleep/day/interruptions`

### Detail screens

All detail pages use one shared shell:

- `SleepDetailPageShell` provides:
  - shared header hierarchy (title/value/status/subtitle),
  - consistent padding/section spacing.
- Shared fallback pattern:
  - `SleepDataUnavailableCard` is used for missing/insufficient data states.

## Reuse of existing app widgets/patterns

Refinement replaced ad-hoc containers with existing app primitives:

- `SummaryCard` used for overview cards/tiles, detail sections, and regularity chart container.
- `GlobalAppBar` used in shared detail shell and day overview for app-wide visual consistency.
- `DesignConstants.cardPadding` and existing spacing tokens reused for layout.
- Existing Statistics Hub section/tile pattern reused for the new Sleep entry card.

## Data dependencies and ownership boundaries

### Repository-facing Day model

- `SleepDayRepository` composes `SleepDayOverviewData` from:
  - `SleepNightlyAnalysesDao` (derived analysis records),
  - canonical session/stage DAOs.
- UI consumes only the Day repository output (`SleepDayOverviewData`) through the view model.

### Derived model usage

- `NightlySleepAnalysis` was cleaned back to core nightly derived semantics.
- Presentation-facing data is carried by `SleepDayOverviewData` instead of bloating core domain entities.

### Ownership discipline

- UI/presentation does **not** implement canonical repair, scoring, baseline derivation policy definitions, interruption qualification rules, or regularity semantics as source-of-truth logic.
- The UI reads repository/derived outputs and only formats for display.
- Fallback rendering paths are explicit and safe for absent/partial outputs.

### Logic removed from UI-facing repository layer

The refinement intentionally removed business-logic recreation from `SleepDayRepository`:

- Removed custom HR baseline derivation heuristics.
- Removed custom interruption qualification/counting logic.
- Removed recreated baseline establishment policy logic.
- Removed stage-sufficiency policy recreation beyond conservative confidence mapping.

When data is not explicitly available from current derived outputs, UI now shows conservative unavailable/limited states.

## Lifecycle / resource ownership semantics

- `SleepDayRepository` now tracks whether `AppDatabase` is owned internally.
- If DB is injected externally, repository **does not** close it on dispose.
- If repository creates DB itself, it owns and closes it.
- This behavior is explicit and testable.

## Why each UI structure/fallback was chosen

- **Segmented control:** keeps UX aligned with target IA while deferring non-Day rendering scope.
- **Timeline block:** compact visual of stage sequencing; reads canonical-derived segments only.
- **Score card with semantic color:** maps good/average/poor/unavailable to clear statuses.
- **Metric tiles:** high-scannability and explicit drill-down affordance.
- **Shared detail shell:** enforces cohesion and avoids one-off page structure drift.
- **Data unavailable card:** reusable neutral fallback pattern for low-confidence/missing data without crashes.

## Edge cases handled

- Day with no analysis row → empty card state.
- Detail routes without overview payload → unavailable fallback card.
- Missing HR baseline or sparse history → neutral baseline-not-established messaging.
- Missing/low-confidence stage data for depth → confidence fallback UI.
- Missing interruptions-derived outputs → explicit unavailable fallback.
- Regularity chart midnight wrap handled via utility:
  - `unwrapWakeMinutes()`
  - plus circular average for summary rows.
- Unknown timeline confidence is preserved as unknown (not upgraded to high).
- Week/month segmented choices are explicitly marked unavailable in this batch.

## Shared detail-shell design decisions

- Single shell widget enforces:
  - shared section hierarchy,
  - consistent status indicator treatment,
  - uniform spacing.
- Benchmark visualization (`SleepBenchmarkBar`) is reusable for duration and heart-rate details.

## Tests added

- `test/features/sleep/presentation/sleep_day_navigation_test.dart`
  - day overview tile navigation to detail screens,
  - empty-state rendering safety.
- `test/statistics_hub_steps_card_test.dart` (updated)
  - verifies in-app Statistics Hub Sleep entry navigates to Sleep Day screen.
- `test/features/sleep/presentation/sleep_day_navigation_test.dart` (expanded)
  - overview → each detail route navigation coverage,
  - baseline-missing heart-rate fallback state,
  - low-confidence depth fallback state.
- `test/features/sleep/presentation/regularity_chart_math_test.dart`
  - midnight-wrap utility behavior,
  - circular average around midnight.

## Limitations / deferred work

- Week/month UI content remains deferred (segmented control shell only).
- Full localization pass intentionally deferred; copy uses inline strings for now.
- Statistics-tab integration is intentionally minimal (single Sleep entry card only).
- End-to-end UI tests beyond focused widget/unit coverage are deferred.
- Repository baseline/regularity heuristics are intentionally conservative and may be refined in later analysis-specific issues.

## Follow-up dependencies

- Week/month sleep overview implementations.
- Broader statistics and app-shell integration work.
- Localization issue for all Sleep copy.
- E2E test expansion and visual-regression snapshots.

## Exact files changed in refinement pass

- `lib/screens/statistics_hub_screen.dart`
- `lib/features/sleep/data/sleep_day_repository.dart`
- `lib/features/sleep/domain/derived/nightly_sleep_analysis.dart`
- `lib/features/sleep/presentation/day/sleep_day_overview_page.dart`
- `lib/features/sleep/presentation/day/sleep_day_view_model.dart`
- `lib/features/sleep/presentation/details/sleep_detail_page_shell.dart`
- `lib/features/sleep/presentation/details/sleep_data_unavailable_card.dart`
- `lib/features/sleep/presentation/details/duration_detail_page.dart`
- `lib/features/sleep/presentation/details/heart_rate_detail_page.dart`
- `lib/features/sleep/presentation/details/interruptions_detail_page.dart`
- `lib/features/sleep/presentation/details/depth_detail_page.dart`
- `lib/features/sleep/presentation/details/regularity_detail_page.dart`
- `lib/features/sleep/presentation/details/widgets/sleep_benchmark_bar.dart`
- `test/statistics_hub_steps_card_test.dart`
- `test/features/sleep/presentation/sleep_day_navigation_test.dart`
- `documentation/sleep/sleep_day_batch_2.md`
