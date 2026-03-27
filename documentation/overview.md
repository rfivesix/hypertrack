# Hypertrack: Project Overview

Hypertrack is a comprehensive, **offline-first** health and fitness tracking application built with [Flutter](https://flutter.dev). It centralizes nutrition logging, workout management, body measurements, and supplement tracking into a single, privacy-focused platform.

> **Status:** v0.7 foundation with active v0.7.1 alpha iterations. Core architecture (Drift + UUIDs + modular analytics + AI integration) is solidified; Health Steps UX is currently being refined.

---

## 📖 Table of Contents

- [Key Modules](#key-modules)
- [Application Flow](#application-flow)
- [Screens Reference](#screens-reference)
- [Related Documentation](#related-documentation)

---

## Key Modules

### 🍎 Nutrition Tracking
Manage daily food and fluid intake with a searchable product database powered by [Open Food Facts](https://world.openfoodfacts.org/).

- **Food Logging:** Search by name or scan barcodes. Entries are categorized by meal type (Breakfast, Lunch, Dinner, Snack).
- **Fluid Tracking:** Dedicated logging for water, coffee, and beverages with automatic caffeine and sugar tracking per 100ml.
- **Meal Templates:** Create reusable meals from frequently eaten food combinations.
- **Macro & Micro Targets:** Track daily goals for Calories, Protein, Carbs, Fat, Fiber, Sugar, Salt, and Water.
- **Nutrition Analysis:** Time-range based reports (1 day, 7 days, 30 days, all time) with expandable/collapsible summaries.
- **🤖 AI Meal Capture (v0.6+):** Log meals instantly via photo, voice, or text description. AI detects individual foods with estimated quantities — review and edit before saving. Supports OpenAI GPT-4o and Google Gemini (BYOK — bring your own key).

*Data model details → [Data Models: Nutrition & Foods](data_models_and_storage.md#1-nutrition--foods)*

### 🏋️ Workout Management
Build routines, track live sessions, and review performance history.

- **Routine Builder:** Compose workouts from an exercise catalog with planned sets, rep targets, and rest times.
- **Live Workout:** Real-time logging with set types (Normal, Warmup, Dropset, Failure), integrated rest timer, and reference to previous performance.
- **Exercise Catalog:** Filterable by category and muscle group. Custom exercises can be created.
- **Workout History:** Browse past sessions with detailed breakdowns of volume, tonnage, and personal records.

*Data model details → [Data Models: Workouts & Exercises](data_models_and_storage.md#2-workouts--exercises)*

### 📊 Statistics & Analytics
Analyze training quality and trends through a hub + drill-down analytics system.

- **Statistics Hub:** Compact overview cards for consistency, performance, muscle distribution, recovery, and body/nutrition trends.
- **Performance Analytics:** PR-focused dashboard with recent/all-time records, rep-bracket bests, and notable e1RM improvements.
- **Consistency Analytics:** Weekly KPI and trend views with fixed-window consistency charting and calendar density.
- **Muscle & Recovery Analytics:** Equivalent-set distribution/frequency views and per-muscle recovery readiness interpretation.
- **Body/Nutrition Correlation:** Weight and calorie trend comparison with data-quality-aware insight labels.

### 📐 Body Measurements
Track your body composition and physical dimensions over time.

- **Session-Based Logging:** Record multiple measurements (weight, chest, waist, arms, legs, etc.) in a single session.
- **Trend Charts:** Interactive charts powered by `fl_chart` to visualize progress.

*Data model details → [Data Models: Measurements](data_models_and_storage.md#4-measurements)*

### 💊 Supplement Tracking
Log supplement intake and monitor consistency.

- **Supplement Catalog:** Define your supplement stack with default doses, units, and daily limits.
- **Daily Logging:** Track intake with dose and timestamp. Caffeine supplements are automatically aggregated with fluid entries.
- **Progress Dashboard:** Visual overview of daily supplement completion.

*Data model details → [Data Models: Supplements](data_models_and_storage.md#5-supplements)*

### 👣 Health Steps (Alpha)
Read-only step import from mobile health providers with provider filtering.

- **iOS:** Apple HealthKit step samples.
- **Android:** Google Health Connect step records.
- **Storage:** Raw UTC step segments with strong deduplication keys for safe repeated sync.
- **Diary:** Steps card appears when data exists and tracking is enabled.
- **Steps Detail Screen:** Dedicated `Steps` module screen with Day/Week/Month views and period navigation.
- **Settings:** Global tracking toggle and provider filter (`All`, `Apple Health`, `Health Connect`).

### 🔒 Data Management & Privacy
Full control over your data with comprehensive import/export tools.

- **JSON Backup:** Full application state export with optional AES encryption.
- **CSV Export:** Selective export of nutrition diary, measurements, or workout history.
- **Third-Party Import:** Migration tool for [Hevy](https://hevyapp.com) CSV workout data with exercise name mapping.
- **Auto-Backup:** Configurable automatic backup to a user-selected directory.

---

## Application Flow

```
AppInitializerScreen
├── ❓ First launch → OnboardingScreen → MainScreen
└── ✅ Returning user → MainScreen
                          ├── Tab 0: DiaryScreen (Nutrition Timeline)
                          ├── Tab 1: WorkoutHubScreen
                          ├── Tab 2: Home (Dashboard)
                          ├── Tab 3: StatisticsHubScreen
                          └── Tab 4: NutritionHubScreen
```

The `MainScreen` uses a `PageView` with a `BottomNavigationBar` to switch between the five core tabs. A persistent floating action button provides quick-add options, and an overlay bar appears during active workout sessions.

---

## Screens Reference

The application contains **44 screens** in `lib/screens/`. Here is a categorized breakdown:

### App Shell & Navigation
| Screen | File | Purpose |
| :--- | :--- | :--- |
| App Initializer | `app_initializer_screen.dart` | Startup checks, DB migration, routing |
| Onboarding | `onboarding_screen.dart` | First-run setup (name, DOB, goals) |
| Main Screen | `main_screen.dart` | Root scaffold with bottom navigation |
| Home Dashboard | `home.dart` | Today's summary across all modules |
| Profile | `profile_screen.dart` | User identity and avatar management |
| Settings | `settings_screen.dart` | Theme, visual style, data access |
| Goals | `goals_screen.dart` | Daily nutritional and hydration targets |

### Nutrition
| Screen | File | Purpose |
| :--- | :--- | :--- |
| Nutrition Hub | `nutrition_hub_screen.dart` | Portal for nutrition features |
| Nutrition Screen | `nutrition_screen.dart` | Detailed daily/weekly nutrition log |
| Diary | `diary_screen.dart` | Timeline of all food & fluid entries |
| Add Food | `add_food_screen.dart` | Search, scan, and log food items |
| Food Detail | `food_detail_screen.dart` | Full nutritional breakdown of a product |
| Food Explorer | `food_explorer_screen.dart` | Browse the product database |
| Create Food | `create_food_screen.dart` | Add custom food products |
| Scanner | `scanner_screen.dart` | Barcode scanning camera view |
| Meals | `meals_screen.dart` | List of saved meal templates |
| Meal Screen | `meal_screen.dart` | Detailed meal view and editor |
| Meal Editor | `meal_editor_screen.dart` | Create/edit meal compositions |

### AI (v0.6+)
| Screen | File | Purpose |
| :--- | :--- | :--- |
| AI Meal Capture | `ai_meal_capture_screen.dart` | Photo/voice/text meal input with animated AI UI |
| AI Meal Review | `ai_meal_review_screen.dart` | Review & edit AI-detected foods before saving |
| AI Recommendation | `ai_recommendation_screen.dart` | AI-generated meal suggestions tailored to remaining macros |
| AI Settings | `ai_settings_screen.dart` | API provider selection, key management, connectivity test |

### Workouts
| Screen | File | Purpose |
| :--- | :--- | :--- |
| Workout Hub | `workout_hub_screen.dart` | Portal for workout features |
| Routines | `routines_screen.dart` | List and manage workout templates |
| Edit Routine | `edit_routine_screen.dart` | Build/modify a routine |
| Live Workout | `live_workout_screen.dart` | Active session tracking |
| Workout Summary | `workout_summary_screen.dart` | Post-workout results |
| Workout History | `workout_history_screen.dart` | Past session list |
| Workout Log Detail | `workout_log_detail_screen.dart` | Detailed past session review |
| Exercise Catalog | `exercise_catalog_screen.dart` | Browse/search exercises |
| Exercise Detail | `exercise_detail_screen.dart` | Exercise info and images |
| Create Exercise | `create_exercise_screen.dart` | Add custom exercises |
| Exercise Mapping | `exercise_mapping_screen.dart` | Map imported exercise names |

### Measurements & Statistics
| Screen | File | Purpose |
| :--- | :--- | :--- |
| Statistics Hub | `statistics_hub_screen.dart` | Analytics hub with summary cards and drill-down navigation |
| PR Dashboard | `analytics/pr_dashboard_screen.dart` | PR records, rep brackets, and notable e1RM improvements |
| Consistency Tracker | `analytics/consistency_tracker_screen.dart` | Weekly consistency KPIs, trend bars, and calendar density |
| Muscle Group Analytics | `analytics/muscle_group_analytics_screen.dart` | Equivalent-set distribution, frequency, and guidance |
| Body/Nutrition Correlation | `analytics/body_nutrition_correlation_screen.dart` | Weight/calorie trend correlation with insight confidence |
| Recovery Tracker | `analytics/recovery_tracker_screen.dart` | Per-muscle recovery readiness and pressure overview |
| Measurements | `measurements_screen.dart` | Measurement history and charts |
| Add Measurement | `add_measurement_screen.dart` | Log new body metrics |
| Measurement Detail | `measurement_session_detail_screen.dart` | Single session detail |

### Supplements
| Screen | File | Purpose |
| :--- | :--- | :--- |
| Supplement Hub | `supplement_hub_screen.dart` | Supplement dashboard |
| Supplement Track | `supplement_track_screen.dart` | Daily intake logging |
| Manage Supplements | `manage_supplements_screen.dart` | Catalog management |
| Create Supplement | `create_supplement_screen.dart` | Add/edit supplement definitions |

### Data
| Screen | File | Purpose |
| :--- | :--- | :--- |
| Data Management | `data_management_screen.dart` | Backup, export, import tools |

---

## Related Documentation

- **[System Architecture](architecture.md):** Layered design, directory structure, and technical stack.
- **[Data Models & Storage](data_models_and_storage.md):** All database entities, helpers, and portability features.
- **[UI & Widgets](ui_and_widgets.md):** Design philosophy, custom widget catalog, and layout patterns.
- **[Statistics Module](statistics_module.md):** Current source-of-truth reference for Statistics architecture, range policy, payloads, and screen responsibilities.
- **[Sleep Module Roadmap Tracker](sleep_module_roadmap_tracker.md):** Parent/tracker checklist for Sleep Module child issues 1–31, sequencing, and milestone grouping.
