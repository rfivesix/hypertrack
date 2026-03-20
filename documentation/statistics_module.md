# Statistics Module — Source of Truth (v0.7 Pre-Refactor, Corrected Current-State Baseline)

This document is the implementation-grounded technical reference for the Statistics module as currently implemented. It reflects actual behavior in code and is intended as the authoritative baseline before v0.7 refactor planning.

---

## 📖 Table of Contents

- [Functional Overview](#functional-overview)
- [Module Entry Point: Statistics Hub](#module-entry-point-statistics-hub)
- [Feature Breakdown](#feature-breakdown)
  - [PR Dashboard](#1-pr-dashboard)
  - [Consistency Tracker](#2-consistency-tracker)
  - [Muscle Group Analytics](#3-muscle-group-analytics)
  - [Body / Nutrition Correlation](#4-body--nutrition-correlation)
  - [Recovery Tracker](#5-recovery-tracker)
- [Function Mapping Table](#function-mapping-table)
- [Shared Widgets & Utilities](#shared-widgets--utilities)
- [Technical Debt & Observations (Current State)](#technical-debt--observations-current-state)

---

## Functional Overview

The Statistics module is a read-only analytics layer over workout, nutrition, and body-measurement data. It does not create/update/delete analytics records; screens query helpers/utilities, transform data in memory, and render cards/charts.

### What it does

| Category | Description |
| :--- | :--- |
| **Performance tracking** | Surfaces PRs per exercise, PRs by rep bracket, and e1RM-based notable improvement trends |
| **Training consistency** | Shows weekly volume/duration/frequency, calendar workout density, and streak/rhythm/rolling consistency KPIs |
| **Muscle group analysis** | Aggregates equivalent sets by muscle (primary 1.0, secondary 0.5), plus distribution/frequency/weekly breakdown |
| **Recovery estimation** | Derives per-muscle recovery state from time-since-significant-load and fatigue context (RIR/RPE) |
| **Body & nutrition trends** | Compares smoothed weight and calorie trends and classifies macro-pattern via rule-based insight logic |

### High-level data flow

```
SQLite (Drift)
  └── WorkoutDatabaseHelper  ──►  pr_dashboard_screen
  └── WorkoutDatabaseHelper  ──►  consistency_tracker_screen
  └── WorkoutDatabaseHelper  ──►  muscle_group_analytics_screen
  └── WorkoutDatabaseHelper  ──►  recovery_tracker_screen
  └── DatabaseHelper         ──►  body_nutrition_correlation_screen (via utility)
  └── MuscleAnalyticsUtils   ──►  muscle_group_analytics_screen (post-processing)
  └── BodyNutritionAnalyticsUtils ──► body_nutrition_correlation_screen + statistics_hub_screen
                                        │
                                 statistics_hub_screen
                                 (inline summaries + navigation)
```

All statistics screens are **StatefulWidget** classes with local `setState` state management. Data loads are initiated in `initState`, but not all screens use `Future.wait`; some run a single async query/utility call.

---

## Module Entry Point: Statistics Hub

**File:** `lib/screens/statistics_hub_screen.dart`

The hub is a scrollable summary screen that shows compact analytics sections and navigates into full drill-down screens. It performs its own independent load and does not share a cache/provider with child analytics screens.

### Time-range selector

Five chips are shown at the top and map to `_selectedDays`:

| Index | Label | `_selectedDays` |
| :---: | :---: | :---: |
| 0 | 7 d | 7 |
| 1 | 30 d | 30 |
| 2 | 90 d | 90 |
| 3 | 180 d | 180 |
| 4 | All | 3,650 |

Tapping a chip updates `_selectedTimeRangeIndex` and calls `_loadHubAnalytics()`.

### Hub query behavior (actual)

`_loadHubAnalytics()` executes the following in parallel via `Future.wait`:

- `getRecentGlobalPRs(limit: 3)`
- `getWeeklyVolumeData(weeksBack: 6)`
- `getWorkoutsPerWeek(weeksBack: 6)`
- `getWeeklyConsistencyMetrics(weeksBack: 6)`
- `getMuscleGroupAnalytics(daysBack: _selectedDays, weeksBack: 8)`
- `getTrainingStats()`
- `getRecoveryAnalytics()`
- `getNotablePrImprovements(daysWindow: _selectedDays > 120 ? 90 : _selectedDays, limit: 3)`
- `BodyNutritionAnalyticsUtils.build(rangeIndex: _selectedTimeRangeIndex)`

> Time-range chips do **not** govern every hub query equally; several hub queries are fixed-window or range-independent.

### Hub state variables

```dart
int _selectedTimeRangeIndex = 1;
List<Map<String, dynamic>> _recentPRs = [];
List<Map<String, dynamic>> _weeklyVolume = [];
List<Map<String, dynamic>> _workoutsPerWeek = [];
List<Map<String, dynamic>> _weeklyConsistencyMetrics = [];
Map<String, dynamic> _muscleAnalytics = const {};
List<Map<String, dynamic>> _notableImprovements = [];
Map<String, dynamic> _trainingStats = const {};
Map<String, dynamic> _recoveryAnalytics = const {};
BodyNutritionAnalyticsResult? _bodyNutrition;
_HubConsistencyMetric _hubConsistencyMetric = _HubConsistencyMetric.volume;
```

### Hub sections (inline summaries)

| Section | Mini-visualisation | Data source |
| :--- | :--- | :--- |
| **Consistency** | Mini bar chart (volume / duration / frequency toggle) | `getWeeklyConsistencyMetrics` (fallback to `getWorkoutsPerWeek`) |
| **Muscle Volume** | Horizontal progress bars (top 5 by distribution share) | `getMuscleGroupAnalytics` |
| **Performance** | Recent PR rows + weekly tonnage + top notable improvement | `getRecentGlobalPRs`, `getWeeklyVolumeData`, `getNotablePrImprovements` |
| **Recovery** | Summary card (overall label + counts), **no hub radar** | `getRecoveryAnalytics` |
| **Body / Nutrition** | Mini dual-line normalized chart + KPI row | `BodyNutritionAnalyticsUtils.build` + `normalizedSeries` |

### Additional hub navigation cards

In addition to the five analytics summaries, the hub also links to:

- `ExerciseCatalogScreen`
- `MeasurementsScreen`

---

## Feature Breakdown

### 1. PR Dashboard

**File:** `lib/screens/analytics/pr_dashboard_screen.dart`

#### Purpose

Tracks recent/all-time PRs, groups PR bests by rep range, and highlights strongest recent e1RM momentum.

#### Sections & components

| Section | UI widget | Data method | Description |
| :--- | :--- | :--- | :--- |
| Recent Records | Ranked row list inside `SummaryCard` | `getRecentGlobalPRs(limit: 8)` | Most recently active max-weight PR per exercise |
| All-Time Records | Ranked row list inside `SummaryCard` | `getAllTimeGlobalPRs(limit: 10)` | Highest weight PR per exercise |
| PRs by Rep Range | 2-column `Wrap` badge tiles | `getAllTimePRsByRepBracket()` | Best set per bracket (1 / 2–3 / 4–6 / 7–10 / 11–15 / 15+) |
| Notable Improvements | List with green percentage | `getNotablePrImprovements(daysWindow, limit: 6)` | Exercises with best recent-vs-prior e1RM improvements |

#### Notable Improvements window

Three chips (7 d / 30 d / 90 d) set `_selectedWindowDays` and trigger reload.

Formula used in helper:

```
e1RM = weight × (1 + reps / 30)
```

Rows are included when `recentBestE1rm > previousBestE1rm`.

#### Weight formatting

```dart
weight == weight.truncateToDouble()
    ? weight.toInt().toString()
    : weight.toStringAsFixed(1);
```

---

### 2. Consistency Tracker

**File:** `lib/screens/analytics/consistency_tracker_screen.dart`

#### Purpose

Shows training regularity via KPI cards, weekly metric bars, and calendar density.

#### KPI cards (2 × 3 grid)

| Card | Calculation | Data source |
| :--- | :--- | :--- |
| Workouts This Week | Count since current week Monday | `getTrainingStats()` → `thisWeekCount` |
| Training Days / Week (last 4 wks) | Unique workout days in last 28 days ÷ 4 | Derived from `_workoutDayCounts` (`getWorkoutDayCounts`) |
| Avg Per Week | Workouts in last 28 days ÷ 4 | `getTrainingStats()` → `avgPerWeek` |
| Current Streak | Consecutive weeks backward with ≥1 workout | `getTrainingStats()` → `streakWeeks` |
| Rhythm | Recent 4-week avg count − prior 4-week avg count | Derived from `getWeeklyConsistencyMetrics` |
| Rolling Consistency | % of recent 8 weeks with ≥2 workouts | Derived from `getWeeklyConsistencyMetrics` |

#### Weekly metric bar chart

- **Data:** `getWeeklyConsistencyMetrics(weeksBack: 12)` (pre-filled weeks, including 0-value)
- **Toggle chips:** Volume (`tonnage`), Duration (`durationMinutes`), Frequency (`count`)
- **Y-axis formatting:** For volume, values ≥1000 shown as `x.xk`
- **X-axis labels:** `weekLabel` (`DD.MM.`)
- **Library:** `fl_chart` `BarChart` (vertical bars)

#### Training calendar heatmap

- **Component:** `TableCalendar<int>`
- **Data:** `getWorkoutDayCounts(daysBack: 120)` → `Map<DateTime, int>` normalized to day
- **Cell intensity:** `0.18 + count * 0.14`, clamped to `[0.18, 0.65]`
- **Tap interaction:** selected-day summary text with day and count
- **Marker:** per-day numeric marker at cell bottom

> Calendar visual window spans wider dates, but populated intensity data is sourced only from the last 120 days query.

#### Total sessions card

A `ListTile` displays all-time `totalWorkouts` from `getTrainingStats()`.

---

### 3. Muscle Group Analytics

**File:** `lib/screens/analytics/muscle_group_analytics_screen.dart`

#### Purpose

Shows muscle distribution/frequency/weekly equivalent sets and highlights potential low-emphasis muscles.

#### Period filter chips

| Chip | `daysBack` | Calculated `weeksBack` in code |
| :---: | :---: | :---: |
| 7 d | 7 | `ceil(7/7)=1` → clamped to **4** |
| 30 d | 30 | `ceil(30/7)=5` |
| 90 d | 90 | `ceil(90/7)=13` |
| 180 d | 180 | `ceil(180/7)=26` → clamped to **16** |

`weeksBack` is computed as `(daysBack / 7).ceil().clamp(4, 16)`.

#### Sections & components

| Section | UI component | Data source | Metric |
| :--- | :--- | :--- | :--- |
| Equivalent Sets explainer | Static text card | — | Explains 1.0 / 0.5 weighting |
| Radar overview | `MuscleRadarChart` | `getMuscleGroupAnalytics` → `muscles` | Top 8 by equivalent sets + “Other” average remainder |
| Weekly sets by muscle | `fl_chart` `BarChart` (vertical) | `getMuscleGroupAnalytics` → `weekly[selectedWeek]` | Equivalent sets per muscle for selected week |
| Frequency by muscle | `fl_chart` `BarChart` (vertical) | `getMuscleGroupAnalytics` → `muscles[].frequencyPerWeek` | Trained days per muscle ÷ total period weeks |
| Distribution heatmap | `LinearProgressIndicator` rows | `getMuscleGroupAnalytics` → `muscles[].distributionShare` | Share of total equivalent sets |
| Guidance card | Dynamic text card | `getMuscleGroupAnalytics` → `undertrained`, `dataQualityOk` | Undertrained list from utility summary logic |

#### Data quality gate

```dart
bool dataQualityOk = dataPointDays >= 3 && spanDays >= 14;
```

- `dataPointDays`: number of unique training dates with logged contributions.
- `spanDays`: day span between earliest and latest contribution date, inclusive.

#### Equivalent set weighting

| Role | Weight |
| :--- | :---: |
| Primary muscle | 1.0 |
| Secondary muscle | 0.5 |

A trained day counts when a muscle accumulates `>= 1.0` equivalent sets for that day.

---

### 4. Body / Nutrition Correlation

**File:** `lib/screens/analytics/body_nutrition_correlation_screen.dart`

#### Purpose

Compares smoothed weight and calorie trends and derives rule-based interpretation labels.

#### Time range filter

Five chips map to `rangeIndex` 0–4 and call `BodyNutritionAnalyticsUtils.build(rangeIndex: ...)`.

Range behavior:

- Index 0–3: fixed windows (7/30/90/180 days)
- Index 4 (“All”): dynamic range from earliest relevant date (`measurement`, `food`, or `fluid`) to today

#### Key metric cards (top row)

| Card | Value | Sub-label |
| :--- | :--- | :--- |
| Current Weight | Latest logged weight or `-` | `${weightDays} days with weight data` |
| Weight Change | Last − first (smoothed if available), signed | `${totalDays} day(s)` |
| Avg Daily Calories | Total calories across range ÷ `totalDays` | per-day label |

#### Charts

| Chart | Smoothing | Y-axis | Colour |
| :--- | :--- | :--- | :--- |
| Weight trend | 5-point MA if `weightDaily.length >= 14`, else 3-point | kg | Primary color |
| Calories trend | 7-point MA if `caloriesDaily.length >= 30`, else 3-point | kcal | Secondary color |

Both charts use sparse bottom-date ticks (roughly 4 intervals) and horizontal grid lines (`FlGridData(show: true, drawVerticalLine: false)`).

#### Insight engine

`BodyNutritionAnalyticsUtils._deriveInsight()` returns one of:

- `stableWeightCaloriesUp`
- `weightUpCaloriesUp`
- `caloriesDownWeightNotYetChanged`
- `weightDownCaloriesDown`
- `mixed`
- `notEnoughData`

Thresholds implemented:

```dart
spanDays >= 14 && totalDays >= 14 && weightDays >= 5 && loggedCalorieDays >= 7
```

- `spanDays`: inclusive span between `range.start` and `range.end`.
- `totalDays`: enumerated number of days in the selected range (not “days containing data”).
- `weightDays`: days with weight measurements.
- `loggedCalorieDays`: days with calories > 0 from food+fluid aggregation.

#### Data sources

- Weight: `DatabaseHelper.getChartDataForTypeAndRange('weight', range)`
- Food entries: `DatabaseHelper.getEntriesForDateRange(start, end)`
- Fluid entries: `DatabaseHelper.getFluidEntriesForDateRange(start, end)`

All aggregation/smoothing/insight logic is inside `BodyNutritionAnalyticsUtils`.

---

### 5. Recovery Tracker

**File:** `lib/screens/analytics/recovery_tracker_screen.dart`

#### Purpose

Shows per-muscle recovery state from DB-derived facts and UI-derived recovery-pressure radar scoring.

#### Overall readiness card

Displays `overallState` from `getRecoveryAnalytics()`:

| State value | Display label | Condition |
| :--- | :--- | :--- |
| `mostlyRecovered` | Mostly Recovered | No recovering muscles |
| `mixedRecovery` | Mixed Recovery | Some recovering, below severe threshold |
| `severalRecovering` | Several Recovering | recovering count ≥3 or recovering share ≥40% |
| `insufficientData` | Insufficient Data | No significant load sessions |

Shows counts (`recovering`, `ready`, `fresh`) and heuristic disclaimer text.

#### Recovery pressure radar chart

- **Component:** `MuscleRadarChart` using top 8 muscles + “Other” average
- **Important location:** pressure score is computed in **screen code**, not in `WorkoutDatabaseHelper`

Formula:

```
loadComponent    = (lastEquivalentSets * 24).clamp(0, 45)
freshnessPenalty = ((96 - hoursSinceLoad).clamp(0, 96) / 96) * 45
fatiguePenalty   = highSessionFatigue ? 10 : 0
pressureScore    = (loadComponent + freshnessPenalty + fatiguePenalty).clamp(0, 100)
```

#### Per-muscle recovery cards

- One card per visible muscle (`Brachialis` is filtered out in UI)
- Status badge by state (`recovering`, `ready`, `fresh`)
- Shows recent equivalent sets, hours since last significant load, fatigue context, and heuristic window text

State windows in DB helper:

| Fatigue | Recovering | Ready | Fresh |
| :--- | :---: | :---: | :---: |
| Baseline | < 48 h | 48–72 h | > 72 h |
| High | < 72 h | 72–96 h | > 96 h |

Significant load threshold is `>= 1.0` equivalent sets per muscle per session.

---

## Function Mapping Table

| UI Element | Screen file | Database method | Utility / post-processing |
| :--- | :--- | :--- | :--- |
| Time-range chip bar (hub) | `statistics_hub_screen.dart` | Triggers `_loadHubAnalytics()` with mixed fixed/range-dependent queries | — |
| Hub — Consistency mini bars | `statistics_hub_screen.dart` | `getWeeklyConsistencyMetrics(weeksBack: 6)` | Fallback to `getWorkoutsPerWeek(weeksBack: 6)`; inline bar normalization |
| Hub — Muscle volume heatmap | `statistics_hub_screen.dart` | `getMuscleGroupAnalytics(daysBack: _selectedDays, weeksBack: 8)` | Top-5 `muscles[]` slice |
| Hub — Recent PRs list | `statistics_hub_screen.dart` | `getRecentGlobalPRs(limit: 3)` | — |
| Hub — Weekly tonnage number | `statistics_hub_screen.dart` | `getWeeklyVolumeData(weeksBack: 6)` | Uses latest week tonnage |
| Hub — Recovery summary | `statistics_hub_screen.dart` | `getRecoveryAnalytics()` | Overall label + counts; no hub radar |
| Hub — Body/Nutrition mini chart | `statistics_hub_screen.dart` | (via utility) | `BodyNutritionAnalyticsUtils.build(rangeIndex)` + `normalizedSeries()` |
| PR — Recent Records | `pr_dashboard_screen.dart` | `getRecentGlobalPRs(limit: 8)` | — |
| PR — All-Time Records | `pr_dashboard_screen.dart` | `getAllTimeGlobalPRs(limit: 10)` | — |
| PR — Rep bracket badges | `pr_dashboard_screen.dart` | `getAllTimePRsByRepBracket()` | — |
| PR — Notable Improvements | `pr_dashboard_screen.dart` | `getNotablePrImprovements(daysWindow, limit: 6)` | Epley e1RM comparison performed in helper |
| Consistency — KPI cards | `consistency_tracker_screen.dart` | `getTrainingStats()`, `getWeeklyConsistencyMetrics(weeksBack: 12)`, `getWorkoutDayCounts(daysBack: 120)` | Rhythm/rolling/training-days-per-week derived in screen |
| Consistency — Weekly bar chart | `consistency_tracker_screen.dart` | `getWeeklyConsistencyMetrics(weeksBack: 12)` | Metric toggle in screen |
| Consistency — Calendar heatmap | `consistency_tracker_screen.dart` | `getWorkoutDayCounts(daysBack: 120)` | Intensity and marker rendering in cell builders |
| Consistency — Total sessions tile | `consistency_tracker_screen.dart` | `getTrainingStats()` → `totalWorkouts` | — |
| Muscle — Radar chart | `muscle_group_analytics_screen.dart` | `getMuscleGroupAnalytics(daysBack, weeksBack)` | Radar data built in screen (top 8 + averaged remainder) |
| Muscle — Weekly sets bar chart | `muscle_group_analytics_screen.dart` | `getMuscleGroupAnalytics` → `weekly[]` | Vertical `BarChart`; selected-week chip |
| Muscle — Frequency bar chart | `muscle_group_analytics_screen.dart` | `getMuscleGroupAnalytics` → `muscles[].frequencyPerWeek` | Vertical `BarChart` |
| Muscle — Distribution heatmap | `muscle_group_analytics_screen.dart` | `getMuscleGroupAnalytics` → `muscles[].distributionShare` | Top-10 slice |
| Muscle — Guidance card | `muscle_group_analytics_screen.dart` | `getMuscleGroupAnalytics` → `undertrained`, `dataQualityOk` | `MuscleAnalyticsUtils.buildSummary()` output |
| Body — Key metric cards | `body_nutrition_correlation_screen.dart` | (via utility) | `BodyNutritionAnalyticsResult` fields |
| Body — Weight trend chart | `body_nutrition_correlation_screen.dart` | `DatabaseHelper.getChartDataForTypeAndRange` | `BodyNutritionAnalyticsUtils._movingAverage()` |
| Body — Calories trend chart | `body_nutrition_correlation_screen.dart` | `DatabaseHelper.getEntriesForDateRange`, `getFluidEntriesForDateRange` | `BodyNutritionAnalyticsUtils._movingAverage()` |
| Body — Insight text | `body_nutrition_correlation_screen.dart` | — | `BodyNutritionAnalyticsUtils._deriveInsight()` |
| Recovery — Readiness card | `recovery_tracker_screen.dart` | `getRecoveryAnalytics()` → `overallState`, `totals` | — |
| Recovery — Radar chart | `recovery_tracker_screen.dart` | `getRecoveryAnalytics()` → `muscles[]` raw fields | Pressure score computed in screen (`_recoveryPressureScore`) |
| Recovery — Per-muscle cards | `recovery_tracker_screen.dart` | `getRecoveryAnalytics()` → `muscles[]` | State/threshold logic computed in `WorkoutDatabaseHelper`; display mapping in screen |

---

## Shared Widgets & Utilities

### Widgets

| Widget | File | Purpose |
| :--- | :--- | :--- |
| `AnalyticsSectionHeader` | `lib/widgets/analytics_section_header.dart` | Section label (`labelLarge`, bold, 0.2 letter spacing) |
| `AnalyticsChartDefaults` | `lib/widgets/analytics_chart_defaults.dart` | Shared hidden titles, compact grid constant, `straightLine()` helper |
| `MuscleRadarChart` | `lib/widgets/muscle_radar_chart.dart` | Custom radar chart (`List<MuscleRadarDatum>`, `maxValue`, `centerLabel`) |
| `SummaryCard` | `lib/widgets/summary_card.dart` | Shared card container with optional tap handling |

### Utility classes

| Class | File | Responsibilities |
| :--- | :--- | :--- |
| `MuscleAnalyticsUtils` | `lib/util/muscle_analytics_utils.dart` | Pure transformation of contributions into weekly/per-muscle summary, quality flags, undertrained list |
| `BodyNutritionAnalyticsUtils` | `lib/util/body_nutrition_analytics_utils.dart` | Data fetch + calorie aggregation + smoothing + insight derivation + `BodyNutritionAnalyticsResult` construction |

### Chart/library summary

| Chart type | Library | Used in |
| :--- | :--- | :--- |
| Line chart | `fl_chart ^1.1.0` | Body/Nutrition charts (full + mini) |
| Bar chart (vertical) | `fl_chart ^1.1.0` | Consistency weekly metrics; Muscle weekly/frequency charts |
| Radar chart | Custom `MuscleRadarChart` | Muscle overview; Recovery pressure |
| Calendar heatmap | `table_calendar ^3.2.0` | Consistency calendar |
| Progress bars | Flutter built-in | Muscle distribution share (hub + muscle screen) |
| Mini bars | Custom `Container` rows | Hub consistency summary |

---

## Technical Debt & Observations (Current State)

The points below describe current implementation characteristics relevant to refactor planning (no target design implied).

### 1. No shared statistics data layer across hub + drill-down screens

`StatisticsHubScreen` loads its own dataset, and each drill-down screen performs separate loads. There is no shared cache/provider for statistics.

**Observed impact:** repeated DB/utility work and potential reload latency across navigation paths.

### 2. Recovery logic is split between data helper and UI

`WorkoutDatabaseHelper.getRecoveryAnalytics()` computes recovery state thresholds and per-muscle recovery metadata. Recovery radar pressure score is computed separately in `recovery_tracker_screen.dart`.

**Observed impact:** heuristic logic is distributed across layers (DB helper + UI).

### 3. `getTrainingStats()` is a mixed metric bundle

`getTrainingStats()` returns a single `Map<String, dynamic>` for `totalWorkouts`, `thisWeekCount`, `avgPerWeek`, and `streakWeeks`.

**Observed impact:** callers depend on dynamic map keys and coupled metric retrieval.

### 4. Utility purity differs by analytics domain

`BodyNutritionAnalyticsUtils` performs async data access directly. `MuscleAnalyticsUtils` is a pure aggregation utility that receives pre-built contributions.

**Observed impact:** body analytics utility has stronger data-layer coupling than muscle utility.

### 5. Hub mini-visuals are independently rendered

Hub mini charts/heatmaps are implemented as compact custom render logic separate from full-screen chart rendering code.

**Observed impact:** parallel rendering logic paths must be kept behaviorally aligned.

### 6. Consistency heatmap uses fixed 120-day data query

`getWorkoutDayCounts(daysBack: 120)` is fixed in consistency tracker.

**Observed impact:** heatmap intensity data reflects last ~4 months regardless of broader history.

### 7. Undertrained heuristic is fixed-threshold + capped list

`MuscleAnalyticsUtils` computes undertrained muscles by relative share threshold (`< 60%` of average active-share) and returns up to 3 candidates.

**Observed impact:** heuristic behavior is deterministic but intentionally coarse.

### 8. Notable PR improvements are computed in Dart post-query

`getNotablePrImprovements()` loads rows for the combined prior+recent window and computes window split, e1RM, and ranking in Dart.

**Observed impact:** runtime work scales with dataset size for the selected windows.

### 9. Localization key namespace is mixed/flat

Analytics-related ARB keys currently use mixed prefixes (`analytics*`, `metrics*`, `recovery*`, etc.) in a shared flat keyspace.

**Observed impact:** naming consistency is low for large-scale localization maintenance.

---

*Last updated: 2026-03-20 (implementation-grounded baseline prior to v0.7 refactor execution).*