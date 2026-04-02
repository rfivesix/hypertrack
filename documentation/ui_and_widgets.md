# UI & Widgets

This document covers the design system, widget catalog, dialog system, and layout patterns used throughout Hypertrack.
It is a broad UI reference; for current Statistics/Sleep implementation specifics, use [statistics_module.md](statistics_module.md) and [sleep_current_state.md](sleep/sleep_current_state.md).

---

## 📖 Table of Contents

- [Design Philosophy](#design-philosophy)
- [Theme System](#theme-system)
- [Widget Catalog](#widget-catalog)
- [Dialog System](#dialog-system)
- [Screen Layout Patterns](#screen-layout-patterns)
- [Interaction Patterns](#interaction-patterns)
- [Design Tokens](#design-tokens)

---

## Design Philosophy

Hypertrack's visual design is built on four principles:

1. **Glassmorphism:** Semi-transparent surfaces with blurred backgrounds (`BackdropFilter`) create a layered, premium aesthetic. Applied to FABs, bottom menus, and navigation bars.
2. **Card-Based Consistency:** All content sections use `SummaryCard` as a visual container, ensuring uniform shadows, borders, and padding.
3. **Responsive Feedback:** Micro-animations, swipe gestures, and progress indicators provide immediate visual responses to user actions.
4. **Adaptive Theming:** Full Light and Dark mode support with custom color schemes that maintain contrast and readability in both modes.

---

## Theme System

### Theme Configuration (`lib/main.dart`)
The application uses `ThemeService` (a `ChangeNotifier`) to manage theme mode persistence. Themes are constructed with:
- Material 3 `ColorScheme` via `ColorScheme.fromSeed()`
- Custom `ThemeExtension<AppSurfaces>` for app-specific surface colors

### `AppSurfaces` (`lib/theme/app_colors.dart`)
A `ThemeExtension` that provides custom surface colors not available in the standard `ThemeData`:

| Property | Purpose |
| :--- | :--- |
| `summaryCard` | Background color for `SummaryCard` widgets |

### Color Constants (`lib/theme/color_constants.dart`)
Hardcoded color tokens for light and dark modes:

| Constant | Value | Usage |
| :--- | :--- | :--- |
| `summary_card_dark_mode` | `rgb(40, 40, 40)` | Deep gray for dark mode card backgrounds |
| `summary_card_white_mode` | `rgb(235, 235, 235)` | Light gray for light mode card backgrounds |

---

## Widget Catalog

The application provides reusable widgets in `lib/widgets/`. Here is a categorized reference:

### Layout & Containers

| Widget | File | Description |
| :--- | :--- | :--- |
| `SummaryCard` | `summary_card.dart` | Primary container for grouped content. Uses `AppSurfaces` for theming. Supports optional `onTap`. |
| `FrostedContainer` | `frosted_container.dart` | Applies a `BackdropFilter` blur to any child widget for glassmorphism effects. |
| `ShadowContainer` | `shadow_container.dart` | Simple container with elevation shadow. |
| `BottomContentSpacer` | `bottom_content_spacer.dart` | Adds padding at the bottom of scrollable screens to avoid content being hidden behind the FAB or navigation bar. |
| `KeepAlivePage` | `keep_alive_page.dart` | Wraps a page to keep it alive in a `PageView` (prevents rebuilds when swiping between tabs). |

### Navigation & Actions

| Widget | File | Description |
| :--- | :--- | :--- |
| `GlobalAppBar` | `global_app_bar.dart` | Unified top app bar with transparent background, consistent typography, and automatic back button. |
| `GlassFab` | `glass_fab.dart` | Frosted floating action button with animated expand/collapse for multi-action menus. |
| `GlassBottomNavBar` | `glass_bottom_nav_bar.dart` | Main tab bar with glassmorphism background and animated selection indicator. |
| `GlassBottomMenu` | `glass_bottom_menu.dart` | Modal bottom sheet with frosted glass styling. Also exports `showDeleteConfirmation()` helper. |
| `GlassMenu` | `glass_menu.dart` | Popup overlay menu with glass styling for contextual actions. |
| `GlassPillButton` | `glass_pill_button.dart` | Rounded, frosted button used for inline actions and filters. |
| `AddMenuSheet` | `add_menu_sheet.dart` | Quick-add action sheet triggered by the FAB. |

### Data Visualization

| Widget | File | Description |
| :--- | :--- | :--- |
| `NutritionSummaryWidget` | `nutrition_summary_widget.dart` | Complex macro/micro nutrient display with progress bars, expandable detailed view, and color-coded targets. |
| `GlassProgressBar` | `glass_progress_bar.dart` | Animated progress bar with glassmorphism styling. |
| `MeasurementChartWidget` | `measurement_chart_widget.dart` | Interactive line chart for displaying measurement trends using `fl_chart`. |
| `CompactNutritionBar` | `compact_nutrition_bar.dart` | Condensed macro bar for use in list tiles and cards. |
| `WorkoutSummaryBar` | `workout_summary_bar.dart` | Post-workout statistics bar (volume, duration, sets). |
| `SupplementSummaryWidget` | `supplement_summary_widget.dart` | Daily supplement completion overview with progress indicators. |
| `TodaysWorkoutSummaryCard` | `todays_workout_summary_card.dart` | Home dashboard card showing today's workout summary. |
| `WorkoutCard` | `workout_card.dart` | Compact card for workout list items. |
| `StatisticsStepsCard` | `statistics_steps_card.dart` | Reusable steps trend card for diary/statistics contexts with target line, optional average line, and compact period bar rendering. |

### Workout-Specific

| Widget | File | Description |
| :--- | :--- | :--- |
| `EditableSetRow` | `editable_set_row.dart` | Inline editable row for weight, reps, and RIR input during live workouts. |
| `SetTypeChip` | `set_type_chip.dart` | Colored chip indicating set type (Normal, Warmup, Dropset, Failure). |
| `RunningWorkoutBar` | `running_workout_bar.dart` | Persistent overlay bar displayed when a workout session is active. Shows elapsed time and navigates to the live screen. |

### Utility & Attribution

| Widget | File | Description |
| :--- | :--- | :--- |
| `SwipeActionBackground` | `swipe_action_background.dart` | Colored background with icon, displayed behind `Dismissible` items during swipe-to-edit or swipe-to-delete. |
| `OffAttributionWidget` | `off_attribution_widget.dart` | Open Food Facts data attribution notice. |
| `WgerAttributionWidget` | `wger_attribution_widget.dart` | wger exercise database attribution notice. |

---

## Dialog System

Reusable modal content in `lib/dialogs/`:

| Dialog | File | Purpose |
| :--- | :--- | :--- |
| `QuantityDialogContent` | `quantity_dialog_content.dart` | Food logging form: quantity (g/ml), meal type, date/time, optional liquid toggle with sugar/caffeine fields. |
| `FluidDialogContent` | `fluid_dialog_content.dart` | Fluid logging form: name, quantity (ml), sugar per 100ml, caffeine per 100ml, date/time. |
| `WaterDialogContent` | `water_dialog_content.dart` | Streamlined water-only logging with quantity and timestamp. |
| `LogSupplementDialogContent` | `log_supplement_dialog_content.dart` | Supplement dose and timestamp input. |
| `LogSupplementMenu` | `log_supplement_menu.dart` | Supplement selection list with cancel button. |
| `LogSupplementDoseBody` | `log_supplement_menu.dart` | Combined dose input and action buttons for the supplement logging flow. |

### Modal Infrastructure
`water_dialog_content.dart` also exports a unified bottom sheet system:
- **`showAppBottomSheet<T>()`** — Standardized modal launcher with configurable styling.
- **`AppSheetScaffold`** — Consistent modal surface with rounded corners, optional glass effect, and safe area handling.
- **`AppSheetStyle`** — Enum: `plain` (standard surface) or `glass` (blurred, semi-transparent).

---

## Screen Layout Patterns

### Dashboard Hubs
Used by: `Home`, `NutritionHubScreen`, `WorkoutHubScreen`, `SupplementHubScreen`

Structure:
```
Scaffold
└── RefreshIndicator / FutureBuilder
    └── ListView
        ├── Section Title
        ├── SummaryCard (aggregated data)
        ├── Horizontal carousel (e.g., meals, routines)
        └── Navigation cards (ListTile in SummaryCard)
```

### Timeline / Diary
Used by: `DiaryScreen`, `NutritionScreen`

Structure:
```
Scaffold
├── Date navigation header (arrows + date picker)
├── Filter chips (1D, 1W, 1M, All)
├── Collapsible NutritionSummaryWidget
└── ListView.separated
    ├── Date header or Meal type header
    └── Dismissible → SummaryCard → ListTile (swipe to edit/delete)
```

### Editor / Form
Used by: `EditRoutineScreen`, `CreateExerciseScreen`, `CreateFoodScreen`, `CreateSupplementScreen`

Structure:
```
Scaffold
├── GlobalAppBar (with save action)
└── SingleChildScrollView
    └── Column
        ├── TextFormField inputs
        ├── Dropdowns / Chips
        └── Save button
```

### Detail View
Used by: `FoodDetailScreen`, `ExerciseDetailScreen`, `WorkoutLogDetailScreen`

Structure:
```
Scaffold
├── GlobalAppBar
└── SingleChildScrollView
    └── Column
        ├── Hero image (if available)
        ├── SummaryCard (primary data)
        └── SummaryCard (secondary data / lists)
```

---

## Interaction Patterns

### Swipe Gestures
All list items in diary, nutrition, and supplement screens use `Dismissible`:
- **Swipe Right →** Edit (blue `SwipeActionBackground`)
- **Swipe Left ←** Delete (red `SwipeActionBackground` + confirmation dialog via `showDeleteConfirmation()`)

### Quick Actions (FAB)
The `GlassFab` expands to reveal contextual quick-add buttons:
- Add food entry
- Scan barcode
- Log supplement
- Log water

### Pull-to-Refresh
All dashboard hubs implement `RefreshIndicator` to reload data.

### Date Navigation
Screens with chronological data (Diary, Nutrition) use a consistent header:
```
[ ← ]  March 3, 2026  [ → ]
[1D] [1W] [1M] [All]
```
Tapping the date opens a `DateRangePicker`. Arrow buttons navigate single days when in "1D" mode.

---

## Design Tokens

Defined in `lib/util/design_constants.dart`:

| Token | Value | Usage |
| :--- | :--- | :--- |
| `spacingXS` | `4.0` | Tight internal padding |
| `spacingS` | `8.0` | Small gaps between elements |
| `spacingM` | `12.0` | Medium spacing |
| `spacingL` | `16.0` | Standard content padding |
| `spacingXL` | `24.0` | Section spacing |
| `borderRadiusS` | `8.0` | Subtle rounding |
| `borderRadiusM` | `16.0` | Standard card corners |
| `borderRadiusL` | `24.0` | Modal and sheet corners |
| `cardPadding` | `EdgeInsets.all(16.0)` | Standard card internal padding |
| `cardMargin` | `EdgeInsets.all(8.0)` | Standard card external margin |

---

[← Return to Overview](overview.md) · [System Architecture →](architecture.md)
