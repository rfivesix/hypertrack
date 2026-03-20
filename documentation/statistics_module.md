# Statistics Module — Source of Truth (v0.7 Pre-Refactor)

This document provides a complete technical reference for the Statistics module as it exists before the v0.7 overhaul. It covers every screen, chart, data query, and utility involved in analytics. Use it as a stable baseline when planning and executing the refactor.

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
- [Technical Debt & Observations](#technical-debt--observations)

---

## Functional Overview

The Statistics module is a read-only analytics layer sitting above the workout, nutrition, and body-measurement data. It has no write operations of its own — every screen queries the `WorkoutDatabaseHelper` or `DatabaseHelper` (nutrition/body), transforms the results in-memory, and renders charts or summary cards.

### What it does

| Category | Description |
| :--- | :--- |
| **Performance tracking** | Surfaces personal records (PRs) per exercise, by rep bracket, and as trending e1RM improvements |
| **Training consistency** | Visualises weekly volume, duration, and frequency; provides a heatmap calendar and streak/rhythm KPIs |
| **Muscle group analysis** | Aggregates equivalent sets per muscle using primary (1.0×) and secondary (0.5×) weighting; shows distribution, frequency, and weekly breakdown |
| **Recovery estimation** | Infers readiness per muscle from time-since-last-significant-load and RPE/RIR fatigue context |
| **Body & nutrition trends** | Plots smoothed weight and calorie series side-by-side; classifies the macro-trend via a rule-based insight engine |

### High-level data flow

```
SQLite (Drift)
  └── WorkoutDatabaseHelper  ──►  pr_dashboard_screen
  └── WorkoutDatabaseHelper  ──►  consistency_tracker_screen
  └── WorkoutDatabaseHelper  ──►  muscle_group_analytics_screen
  └── WorkoutDatabaseHelper  ──►  recovery_tracker_screen
  └── DatabaseHelper         ──►  body_nutrition_correlation_screen
  └── MuscleAnalyticsUtils   ──►  muscle_group_analytics_screen (post-processing)
  └── BodyNutritionAnalyticsUtils ──► body_nutrition_correlation_screen (post-processing)
                                        │
                                 statistics_hub_screen
                                 (inline summaries of all five)
```

All screens are **StatefulWidget** classes that load data once in `initState` via `Future.wait()` for parallelism. State management is purely local (`setState`). There is no shared analytics provider or cache layer.

---

## Module Entry Point: Statistics Hub

**File:** `lib/screens/statistics_hub_screen.dart`

The hub is a single scrollable screen that renders abbreviated summaries of all five sub-modules and provides navigation buttons to each full screen. It owns its own full data-load (it does not share data with child screens).

### Time-range selector

A row of five chips at the top governs every query on the page:

| Index | Label | `daysBack` | `weeksBack` |
| :---: | :---: | :---: | :---: |
| 0 | 7 d | 7 | 1 |
| 1 | 30 d | 30 | 4 |
| 2 | 90 d | 90 | 13 |
| 3 | 180 d | 180 | 26 |
| 4 | All | 3,650 | 520 |

> **Note:** The 3,650-day (10-year) window for "All" is a practical upper bound chosen so that the query remains bounded. It is not expected to return meaningful data for all users; it simply ensures no records are excluded for active users with multi-year histories. This large constant is a candidate for replacement with a true "no lower-date filter" SQL clause during the v0.7 refactor.

Tapping a chip calls `_loadData()`, which fires all queries in parallel.

### Hub state variables

```dart
int _selectedTimeRangeIndex = 1;
List<Map<String, dynamic>> _recentPRs            = [];
List<Map<String, dynamic>> _weeklyVolume          = [];
List<Map<String, dynamic>> _workoutsPerWeek       = [];
List<Map<String, dynamic>> _weeklyConsistencyMetrics = [];
Map<String, dynamic>       _muscleAnalytics       = const {};
List<Map<String, dynamic>> _notableImprovements   = [];
Map<String, dynamic>       _trainingStats         = const {};
Map<String, dynamic>       _recoveryAnalytics     = const {};
BodyNutritionAnalyticsResult? _bodyNutrition;
_HubConsistencyMetric      _hubConsistencyMetric  = _HubConsistencyMetric.volume;
```

### Hub sections (inline summaries)

| Section | Mini-visualisation | Data source |
| :--- | :--- | :--- |
| **Consistency** | Mini bar chart (volume / duration / frequency toggle) | `getWeeklyConsistencyMetrics` |
| **Muscle Volume** | Horizontal progress bars — top 5 muscles + share % | `getMuscleGroupAnalytics` |
| **Performance** | Recent PRs list + weekly tonnage number | `getRecentGlobalPRs`, `getWeeklyVolumeData` |
| **Recovery** | Radar chart + overall readiness label | `getRecoveryAnalytics` |
| **Body / Nutrition** | Dual-line chart (normalised weight + calories) | `BodyNutritionAnalyticsUtils.build` |

---

## Feature Breakdown

### 1. PR Dashboard

**File:** `lib/screens/analytics/pr_dashboard_screen.dart`

#### Purpose

Tracks the heaviest and most-recent lifts, organises them by rep bracket, and highlights the exercises showing the strongest recent momentum.

#### Sections & components

| Section | UI widget | Data method | Description |
| :--- | :--- | :--- | :--- |
| Recent Records | Scrollable list of `ListTile` rows | `getRecentGlobalPRs(limit: 8)` | Latest PR (most recent by `start_time`) per exercise |
| All-Time Records | Same list format | `getAllTimeGlobalPRs(limit: 10)` | Heaviest weight ever recorded per exercise |
| PRs by Rep Range | 2-column `Wrap` of badge tiles | `getAllTimePRsByRepBracket()` | Best weight per rep bracket (1 RM / 2–3 / 4–6 / 7–10 / 11–15 / 15+) |
| Notable Improvements | Chip-filtered list with green % badge | `getNotablePrImprovements(daysWindow, limit: 6)` | Exercises with the largest recent e1RM gain |

#### Notable Improvements — time window chips

Three chips (7 d / 30 d / 90 d) set `_daysWindow` and re-fetch data. The method compares the *recent window* (last N days) against the *prior window* (N–2N days ago) using the Epley e1RM formula:

```
e1RM = weight × (1 + reps / 30)
```

If `recentBestE1rm > previousBestE1rm`, the improvement percentage is computed and shown as a green badge.

#### Weight formatting

```dart
weight == weight.truncateToDouble()
    ? weight.toInt().toString()   // "25"
    : weight.toStringAsFixed(1);  // "25.5"
```

---

### 2. Consistency Tracker

**File:** `lib/screens/analytics/consistency_tracker_screen.dart`

#### Purpose

Gives a longitudinal view of training regularity through KPI cards, a bar chart with a three-metric toggle, and a calendar heatmap.

#### KPI cards (top row — 2 × 3 grid)

| Card | Calculation | Data source |
| :--- | :--- | :--- |
| Workouts This Week | Count from Monday of current week | `getTrainingStats()` → `thisWeekCount` |
| Training Days / Week (last 4 wks) | Unique calendar days with ≥1 workout ÷ 4 | `getWeeklyConsistencyMetrics` |
| Avg Per Week | Workouts in last 28 d ÷ 4 | `getTrainingStats()` → `avgPerWeek` |
| Current Streak | Consecutive weeks backwards from now with ≥1 workout | `getTrainingStats()` → `streakWeeks` |
| Rhythm | Recent 4-wk avg minus prior 4-wk avg of workout counts | Derived from `getWeeklyConsistencyMetrics` |
| Rolling Consistency | % of last 8 weeks with ≥2 workouts | Derived from `getWeeklyConsistencyMetrics` |

#### Weekly metric bar chart

- **Data:** `getWeeklyConsistencyMetrics(weeksBack: 12)` — 12 weeks pre-filled (0-value weeks included)
- **Toggle chips:** Volume (tonnage, kg), Duration (minutes), Frequency (workouts)
- **Y-axis labels:** Compact formatting — values ≥1 000 displayed as `"1.2k"`
- **X-axis labels:** Week start date formatted as `"DD.MM."`
- **Library:** `fl_chart` `BarChart`

#### Training calendar heatmap

- **Component:** `TableCalendar` (package `table_calendar`)
- **Data:** `getWorkoutDayCounts(daysBack: 120)` — returns `Map<DateTime, int>` (normalised to midnight)
- **Visual intensity:**
  - 1 workout → primary colour at alpha `0.18`
  - 2 workouts → alpha `0.40`
  - 3+ workouts → alpha `0.65`
- **Tap interaction:** Displays "You logged N workouts on DD.MM.YYYY" below the calendar
- **Marker:** Small count badge rendered at the bottom of the cell

#### Total sessions card

A plain `ListTile` showing `getTrainingStats()` → `totalWorkouts` as an all-time count.

---

### 3. Muscle Group Analytics

**File:** `lib/screens/analytics/muscle_group_analytics_screen.dart`

#### Purpose

Shows how training volume and frequency are distributed across muscle groups, flags potential imbalances, and breaks down effort week by week.

#### Period filter chips

| Chip | `daysBack` | Calculated `weeksBack` (`daysBack / 7`) |
| :---: | :---: | :---: |
| 7 d | 7 | 1 |
| 30 d | 30 | 4 |
| 90 d | 90 | 13 |
| 180 d | 180 | 26 |

`weeksBack = daysBack / 7` (integer division).

#### Sections & components

| Section | UI component | Data source | Metric |
| :--- | :--- | :--- | :--- |
| Equivalent Sets explainer | Static text card | — | Describes 1.0 / 0.5 weighting |
| Radar overview | `MuscleRadarChart` widget | `getMuscleGroupAnalytics` → `muscles` | Top 8 muscles by equivalent sets; 9th axis = average of the rest |
| Weekly sets by muscle | `fl_chart` `HorizontalBarChart` | `getMuscleGroupAnalytics` → `weekly[selectedWeek]` | Equivalent sets per muscle for the selected week |
| Frequency by muscle | `fl_chart` `HorizontalBarChart` | `getMuscleGroupAnalytics` → `muscles[].frequencyPerWeek` | Trained days per muscle ÷ total weeks |
| Distribution heatmap | Stacked `LinearProgressIndicator` rows | `getMuscleGroupAnalytics` → `muscles[].distributionShare` | % of total sets per muscle |
| Guidance card | Dynamic text card | `getMuscleGroupAnalytics` → `undertrained`, `dataQualityOk` | Flags muscles in the bottom 3 with <60 % of average share |

#### Data quality gate

```dart
bool dataQualityOk = dataPointDays >= 3 && spanDays >= 14;
```

- **`dataPointDays`** — the number of *unique calendar days* on which at least one set was logged within the selected period. Used as a proxy for "how much data do we actually have?"
- **`spanDays`** — the number of calendar days from the earliest logged workout in the period to the most recent one. A span of fewer than 14 days means there is not enough temporal spread to derive meaningful frequency or trend data.

#### Equivalent sets weighting

| Role | Weight |
| :--- | :---: |
| Primary muscle | 1.0 |
| Secondary muscle | 0.5 |

A "trained day" for frequency purposes is a day where a muscle accumulates ≥1.0 equivalent sets.

---

### 4. Body / Nutrition Correlation

**File:** `lib/screens/analytics/body_nutrition_correlation_screen.dart`

#### Purpose

Overlays smoothed weight and calorie trends to reveal whether intake changes are tracking with bodyweight changes.

#### Time range filter

Five chips (7 d / 30 d / 90 d / 180 d / All) map to `rangeIndex` 0–4 passed to `BodyNutritionAnalyticsUtils.build`.

#### Key metric cards (top row)

| Card | Value | Sub-label |
| :--- | :--- | :--- |
| Current Weight | Latest logged weight or "—" | "N days with weight data" |
| Weight Change | Last − first (within range), prefixed "+" or "−" | Time-range label |
| Avg Daily Calories | Σ logged kcal ÷ days in range | "kcal per day" |

#### Charts

| Chart | Smoothing | Y-axis | Colour |
| :--- | :--- | :--- | :--- |
| Weight trend | 5-point MA if `weightDays >= 14`, else 3-point | kg | Primary theme colour |
| Calories trend | 7-point MA if `loggedCalorieDays >= 30`, else 3-point | kcal | Secondary theme colour |

Both charts share the same sparse X-axis date labels (every ~4 data points) and use horizontal-only grid lines via `AnalyticsChartDefaults.compactGrid`.

#### Insight engine

`BodyNutritionAnalyticsUtils._deriveInsight()` classifies results into one of six `BodyNutritionInsightType` values:

| Type | Trigger condition | Displayed message |
| :--- | :--- | :--- |
| `stableWeightCaloriesUp` | Weight Δ ≤ ±0.35 kg AND calorie half-delta > +120 | "Body composition maintained despite increased intake" |
| `weightUpCaloriesUp` | Weight Δ ≥ +0.45 kg AND calorie half-delta > +80 | "Gaining while eating more — monitor for desired progress" |
| `caloriesDownWeightNotYetChanged` | Calorie half-delta < −120 AND weight Δ > −0.2 kg | "Calorie reduction hasn't yet impacted weight" |
| `weightDownCaloriesDown` | Weight Δ ≤ −0.45 kg AND calorie half-delta < −80 | "Successfully reducing calorie intake with weight loss" |
| `mixed` | None of the above | "Inconsistent pattern — track longer for clarity" |
| `notEnoughData` | Quality thresholds not met | "Insufficient data to derive insight" |

**Data quality thresholds:**

```dart
spanDays >= 14 && totalDays >= 14 && weightDays >= 5 && loggedCalorieDays >= 7
```

- **`spanDays`** — calendar days from the earliest data point in the selected range to the most recent (weight *or* calorie entry). Ensures the analysis covers a meaningful time window.
- **`totalDays`** — total number of days in the selected range that have *any* data (weight or calories). Prevents insights from very sparse datasets.
- **`weightDays`** — days within the range that have at least one weight measurement logged.
- **`loggedCalorieDays`** — days within the range that have at least one food or fluid entry.

#### Data sources

- **Weight:** `DatabaseHelper.getChartDataForTypeAndRange('weight', range)`
- **Food calories:** `DatabaseHelper.getEntriesForDateRange()`
- **Fluid calories:** `DatabaseHelper.getFluidEntriesForDateRange()`

All processing (moving averages, deduplication, normalization) is performed in `BodyNutritionAnalyticsUtils`, not in the screen.

---

### 5. Recovery Tracker

**File:** `lib/screens/analytics/recovery_tracker_screen.dart`

#### Purpose

Estimates per-muscle readiness using a time-based heuristic adjusted for session fatigue (RPE/RIR).

#### Overall readiness card

Displays one of four states derived from `getRecoveryAnalytics()` → `overallState`:

| State value | Display label | Condition |
| :--- | :--- | :--- |
| `mostlyRecovered` | "Mostly Recovered" | All or most muscles fresh/ready |
| `mixedRecovery` | "Mixed Recovery" | Mix of recovering and ready |
| `severalRecovering` | "Several Recovering" | ≥3 muscles or ≥40 % in recovering state |
| `insufficientData` | "Insufficient Data" | No significant loading recorded |

Below the state label, a summary count line ("N recovering, M ready, K fresh") is shown.

A disclaimer beneath the card reads: *"Based on time-since-load heuristic; not a replacement for professional advice."*

#### Recovery pressure radar chart

- **Component:** `MuscleRadarChart` — top 8 muscles + "Other" (average of remaining)
- **Score formula (0–100 scale, pseudocode):**

```
// All variables are Dart doubles; clamp() is Dart's num.clamp
loadComponent    = (lastEquivalentSets * 24).clamp(0, 45)
freshnessPenalty = ((96 - hoursSinceLoad).clamp(0, 96) / 96) * 45
fatiguePenalty   = highSessionFatigue ? 10 : 0
pressureScore    = (loadComponent + freshnessPenalty + fatiguePenalty).clamp(0, 100)
```

#### Per-muscle recovery cards

One card per tracked muscle (muscle "Brachialis" is filtered out as too granular).

| Field | Value |
| :--- | :--- |
| Status badge | `recovering` (orange) / `ready` (blue) / `fresh` (green) |
| Recent load | `lastEquivalentSets` formatted to 1 d.p. |
| Last loaded | `hoursSinceLastSignificantLoad` in hours |
| Fatigue context | "High" if `avgRIR == 0 OR avgRPE >= 9`, else "Baseline" |
| Recovery window label | "0–48 h", "48–72 h", or ">72 h" (thresholds shift by +24 h when high fatigue) |

**State thresholds:**

| Fatigue | Recovering | Ready | Fresh |
| :--- | :---: | :---: | :---: |
| Baseline | < 48 h | 48–72 h | > 72 h |
| High | < 72 h | 72–96 h | > 96 h |

**Significant load threshold:** ≥1.0 equivalent sets in a single session.

---

## Function Mapping Table

Maps visible UI elements to the corresponding screen files, database methods, and utility helpers.

| UI Element | Screen file | Database method | Utility / post-processing |
| :--- | :--- | :--- | :--- |
| Time-range chip bar (hub) | `statistics_hub_screen.dart` | All queries re-fired on tap | — |
| Hub — Consistency mini bars | `statistics_hub_screen.dart` | `getWeeklyConsistencyMetrics(weeksBack)` | Inline normalisation to relative bar heights |
| Hub — Muscle volume heatmap | `statistics_hub_screen.dart` | `getMuscleGroupAnalytics(daysBack, weeksBack)` | Top-5 slice from `muscles[]` |
| Hub — Recent PRs list | `statistics_hub_screen.dart` | `getRecentGlobalPRs(limit: 3)` | — |
| Hub — Weekly tonnage number | `statistics_hub_screen.dart` | `getWeeklyVolumeData(weeksBack: 6)` | Sum of latest week |
| Hub — Recovery radar chart | `statistics_hub_screen.dart` | `getRecoveryAnalytics()` | `MuscleRadarChart` widget |
| Hub — Body / nutrition dual-line chart | `statistics_hub_screen.dart` | (multiple via `BodyNutritionAnalyticsUtils`) | `BodyNutritionAnalyticsUtils.build(rangeIndex)` |
| PR — Recent Records list | `pr_dashboard_screen.dart` | `getRecentGlobalPRs(limit: 8)` | — |
| PR — All-Time Records list | `pr_dashboard_screen.dart` | `getAllTimeGlobalPRs(limit: 10)` | — |
| PR — Rep bracket badges | `pr_dashboard_screen.dart` | `getAllTimePRsByRepBracket()` | — |
| PR — Notable Improvements list | `pr_dashboard_screen.dart` | `getNotablePrImprovements(daysWindow, limit: 6)` | Epley e1RM formula inline |
| Consistency — KPI cards (6) | `consistency_tracker_screen.dart` | `getTrainingStats()`, `getWeeklyConsistencyMetrics(weeksBack: 12)` | Rhythm / rolling-consistency derived in screen |
| Consistency — Weekly bar chart | `consistency_tracker_screen.dart` | `getWeeklyConsistencyMetrics(weeksBack: 12)` | Metric toggle (volume / duration / frequency) |
| Consistency — Calendar heatmap | `consistency_tracker_screen.dart` | `getWorkoutDayCounts(daysBack: 120)` | Alpha intensity mapping in cell builder |
| Consistency — Total sessions tile | `consistency_tracker_screen.dart` | `getTrainingStats()` → `totalWorkouts` | — |
| Muscle — Radar chart | `muscle_group_analytics_screen.dart` | `getMuscleGroupAnalytics(daysBack, weeksBack)` | `MuscleRadarChart` widget; 9th axis = averaged remainder |
| Muscle — Weekly sets bar chart | `muscle_group_analytics_screen.dart` | `getMuscleGroupAnalytics` → `weekly[]` | Selected-week slice; chip selector |
| Muscle — Frequency bar chart | `muscle_group_analytics_screen.dart` | `getMuscleGroupAnalytics` → `muscles[].frequencyPerWeek` | — |
| Muscle — Distribution heatmap | `muscle_group_analytics_screen.dart` | `getMuscleGroupAnalytics` → `muscles[].distributionShare` | Top-10 slice |
| Muscle — Guidance card | `muscle_group_analytics_screen.dart` | `getMuscleGroupAnalytics` → `undertrained`, `dataQualityOk` | `MuscleAnalyticsUtils.buildSummary` |
| Body — Key metric cards | `body_nutrition_correlation_screen.dart` | (via `BodyNutritionAnalyticsUtils`) | `currentWeightKg`, `weightChangeKg`, `avgDailyCalories` fields |
| Body — Weight trend line chart | `body_nutrition_correlation_screen.dart` | `DatabaseHelper.getChartDataForTypeAndRange` | `BodyNutritionAnalyticsUtils._movingAverage` |
| Body — Calories trend line chart | `body_nutrition_correlation_screen.dart` | `DatabaseHelper.getEntriesForDateRange`, `getFluidEntriesForDateRange` | `BodyNutritionAnalyticsUtils._movingAverage` |
| Body — Insight text | `body_nutrition_correlation_screen.dart` | — | `BodyNutritionAnalyticsUtils._deriveInsight()` |
| Recovery — Readiness card | `recovery_tracker_screen.dart` | `getRecoveryAnalytics()` → `overallState`, `totals` | — |
| Recovery — Radar chart | `recovery_tracker_screen.dart` | `getRecoveryAnalytics()` → `muscles[].pressureScore` | `MuscleRadarChart` widget |
| Recovery — Per-muscle cards | `recovery_tracker_screen.dart` | `getRecoveryAnalytics()` → `muscles[]` | State/threshold logic in `WorkoutDatabaseHelper` |

---

## Shared Widgets & Utilities

### Widgets

| Widget | File | Purpose |
| :--- | :--- | :--- |
| `AnalyticsSectionHeader` | `lib/widgets/analytics_section_header.dart` | Labelled section divider — `labelLarge`, bold, 0.2 letter spacing |
| `AnalyticsChartDefaults` | `lib/widgets/analytics_chart_defaults.dart` | Shared `FlGridData` (horizontal lines only) and `straightLine()` factory |
| `MuscleRadarChart` | `lib/widgets/muscle_radar_chart.dart` | Custom radar chart; accepts `List<MuscleRadarDatum>` + `maxValue` + `centerLabel` |
| `SummaryCard` | `lib/widgets/summary_card.dart` | Reusable card container used across metric-card layouts |

### Utility classes

| Class | File | Responsibilities |
| :--- | :--- | :--- |
| `MuscleAnalyticsUtils` | `lib/util/muscle_analytics_utils.dart` | Aggregates raw set contributions into weekly buckets, calculates distribution and frequency, identifies undertrained muscles |
| `BodyNutritionAnalyticsUtils` | `lib/util/body_nutrition_analytics_utils.dart` | Fetches weight and calorie data, applies moving averages, derives insight classification, exposes `BodyNutritionAnalyticsResult` |

### Chart library summary

| Chart type | Library | Used in |
| :--- | :--- | :--- |
| Line chart | `fl_chart ^1.1.0` | Weight trend, calorie trend |
| Bar chart (vertical) | `fl_chart ^1.1.0` | Weekly consistency |
| Bar chart (horizontal) | `fl_chart ^1.1.0` | Weekly sets by muscle, frequency by muscle |
| Radar chart | Custom `MuscleRadarChart` | Muscle distribution, recovery pressure |
| Calendar heatmap | `table_calendar ^3.2.0` | Training calendar |
| Progress bars | Flutter built-in | Muscle distribution share |
| Mini bars | Custom `Container` rows | Hub consistency summary |

---

## Technical Debt & Observations

The following issues were identified by comparing the UI states against the source code. They are prioritised roughly by impact.

---

### 1. No shared data layer — hub re-loads everything independently

**Problem:** `StatisticsHubScreen` fires its own full parallel data load. Each drill-down screen then repeats the same queries from scratch. There is no cache, provider, or shared ViewModel. On slow devices or large databases, the user experiences reload delays every time they navigate in and out of a sub-screen.

**Impact:** High — performance, redundant DB reads, increased perceived latency.

**Suggested fix:** Extract a `StatisticsAnalyticsProvider` (or equivalent `ChangeNotifier` / `Riverpod` pod) that caches the last-loaded results keyed by time-range index. Screens observe the provider and only re-load when the selected range changes.

---

### 2. Recovery pressure score is assembled inline in the database helper

**Problem:** `getRecoveryAnalytics()` in `workout_database_helper.dart` performs the pressure-score arithmetic (load component, freshness penalty, fatigue penalty) directly inside the database query method. Business logic and data-access are mixed in the same class.

**Impact:** Medium — makes unit testing the heuristic difficult; any change to the formula requires touching the data layer.

**Suggested fix:** Move the pressure-score calculation to a dedicated `RecoveryAnalyticsUtils` class (parallel to `MuscleAnalyticsUtils` and `BodyNutritionAnalyticsUtils`), and have the DB helper return raw per-muscle facts (last load, hours since load, fatigue flags) only.

---

### 3. `getTrainingStats()` returns mixed-granularity data in a single map

**Problem:** `getTrainingStats()` returns `totalWorkouts`, `thisWeekCount`, `avgPerWeek`, and `streakWeeks` as a single `Map<String, dynamic>`. These four metrics require four separate SQL queries with different aggregation logic (all-time count, week-to-date count, 28-day average, consecutive-week streak). Bundling them silently makes the method unpredictable regarding which fields are present and adds unnecessary load when only one is needed.

**Impact:** Medium — callers in both `statistics_hub_screen` and `consistency_tracker_screen` access the same map but use different subsets. If any query inside the method fails, all fields are lost.

**Suggested fix:** Either split into separate methods (`getTotalWorkoutCount()`, `getThisWeekCount()`, `getAvgPerWeek()`, `getCurrentStreakWeeks()`) or define a typed `TrainingStats` data class so field presence is guaranteed at compile time.

---

### 4. `BodyNutritionAnalyticsUtils` and `MuscleAnalyticsUtils` are standalone classes, not services

**Problem:** Both utilities carry out their own database access by accepting or calling `DatabaseHelper`/`WorkoutDatabaseHelper` directly. They are pure utility classes but they perform async I/O, making them hard to test without a real database.

**Impact:** Medium — unit tests require database setup; mocking is not straightforward.

**Suggested fix:** Accept pre-fetched data lists as constructor arguments (or parameters to `build()`/`buildSummary()`) rather than fetching internally. This makes both classes pure transformation units and trivially testable.

---

### 5. Hub inline summaries duplicate chart-rendering logic from sub-screens

**Problem:** The hub's mini bar chart, dual-line chart, and muscle heatmap are all custom-rendered inline. The same `fl_chart` setup (axes, colours, spot construction) is partially duplicated from the full sub-screens.

**Impact:** Medium — two code paths to maintain; visual inconsistencies are possible if one is updated and the other is not.

**Suggested fix:** Extract small reusable chart widgets (e.g., `ConsistencyMiniChart`, `BodyNutritionMiniChart`) that accept pre-computed data and accept a `compact: true` parameter to switch between hub summary and full-screen layouts.

---

### 6. Calendar heatmap range is hardcoded to 120 days regardless of selected time range

**Problem:** `getWorkoutDayCounts(daysBack: 120)` is called with a fixed constant in `consistency_tracker_screen.dart`. The screen has no time-range selector of its own, but 120 days is an arbitrary cutoff that is inconsistent with the hub's configurable range.

**Impact:** Low — users cannot see heatmap data beyond 4 months even if they have years of history.

**Suggested fix:** Either make `daysBack` configurable via a filter chip consistent with other screens, or at minimum increase the default to match the "All" range window.

---

### 7. Undertrained muscle logic uses a fixed bottom-3 heuristic

**Problem:** `MuscleAnalyticsUtils.buildSummary()` flags the bottom 3 muscles whose `distributionShare` is <60 % of the average share. The "bottom 3" cutoff is a magic number; for athletes training fewer than 4 muscle groups the entire tracked set could be flagged.

**Impact:** Low — guidance card may show misleading recommendations for minimalist programmes.

**Suggested fix:** Replace the fixed-count approach with a relative threshold check only (e.g., flag any muscle below 40 % of the average and add a minimum muscle count guard).

---

### 8. `getNotablePrImprovements` uses a raw Dart list loop in Dart rather than SQL aggregation

**Problem:** The method fetches all relevant sets for the combined 2× window, then performs the window-split, e1RM computation, and comparison entirely in Dart. For users with large datasets (thousands of sets) this can be slow.

**Impact:** Low for typical users; noticeable for power users with multi-year histories.

**Suggested fix:** Push the window aggregation into SQL using conditional aggregation (`CASE WHEN start_time >= threshold THEN ... END`) and compute the max e1RM approximation in SQL to reduce the in-memory dataset size.

---

### 9. Localisation key namespace is flat and unsorted

**Problem:** All analytics localisation keys (100+) live in the same flat namespace in the ARB files without a consistent prefix scheme. Keys like `analyticsKpisHeader`, `recoveryTrackerTitle`, and `metricsVolumeLifted` use three different prefix conventions.

**Impact:** Low — developer ergonomics only; no runtime impact.

**Suggested fix:** Adopt a two-segment prefix convention (`screen.key`) for all new keys added in v0.7, e.g., `consistency.totalSessions`, `recovery.stateRecovering`, `pr.repBracket1rm`.

---

*Last updated: pre-v0.7 refactor baseline. This document should be archived once the refactor is complete and replaced by updated architecture documentation.*
