# Data Models & Storage

This document provides a comprehensive reference for all data entities, their relationships, and the storage infrastructure used by Hypertrack.

---

## 📖 Table of Contents

- [Entity Overview](#entity-overview)
- [1. Nutrition & Foods](#1-nutrition--foods)
- [2. Workouts & Exercises](#2-workouts--exercises)
- [3. Set System](#3-set-system)
- [4. Measurements](#4-measurements)
- [5. Supplements](#5-supplements)
- [6. Supporting Models](#6-supporting-models)
- [Database Architecture](#database-architecture)
- [Data Portability](#data-portability)

---

## Entity Overview

The application manages **20 model classes** in `lib/models/`:

```
models/
├── food_item.dart              # Product nutritional data
├── food_entry.dart             # User food consumption log
├── fluid_entry.dart            # User fluid consumption log
├── daily_nutrition.dart        # Aggregated daily nutrient totals
├── tracked_food_item.dart      # Combined food item + entry for display
├── exercise.dart               # Exercise definition with muscle groups
├── routine.dart                # Workout template metadata
├── routine_exercise.dart       # Exercise within a routine (with ordering)
├── workout_log.dart            # Completed workout session record
├── set_log.dart                # Individual set performance data
├── set_template.dart           # Planned set within a routine
├── measurement.dart            # Individual body metric value
├── measurement_session.dart    # Group of measurements taken at once
├── supplement.dart             # Supplement definition
├── supplement_log.dart         # Supplement intake record
├── tracked_supplement.dart     # Supplement enriched with display data
├── water_entry.dart            # Legacy water entry (migrating to FluidEntry)
├── timeline_entry.dart         # Abstract entry for timeline display
├── chart_data_point.dart       # Generic point for chart rendering
└── hypertrack_backup.dart      # Full backup serialization model
```

---

## 1. Nutrition & Foods

### `FoodItem`
Represents a food product with nutritional information **per 100g/ml**.

| Field | Type | Description |
| :--- | :--- | :--- |
| `barcode` | `String` | Unique product identifier (EAN/UPC or custom) |
| `name` | `String` | Display name |
| `calories` | `int` | Energy in kcal |
| `protein` | `double` | Protein in grams |
| `carbs` | `double` | Carbohydrates in grams |
| `fat` | `double` | Fat in grams |
| `sugar` | `double?` | Sugar in grams (optional) |
| `fiber` | `double?` | Fiber in grams (optional) |
| `salt` | `double?` | Salt in grams (optional) |
| `isLiquid` | `bool?` | Whether the product is a beverage |
| `caffeineMgPer100ml` | `double?` | Caffeine density for beverages |
| `imageUrl` | `String?` | Product image URL (Open Food Facts) |

### `FoodEntry`
A log of consuming a specific quantity at a specific time.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int?` | Auto-incremented database ID |
| `barcode` | `String` | Reference to the `FoodItem` |
| `quantityInGrams` | `int` | Amount consumed (g or ml) |
| `timestamp` | `DateTime` | When the food was eaten |
| `mealType` | `String` | Category key (`mealtypeBreakfast`, `mealtypeLunch`, etc.) |

### `FluidEntry`
Specialized entry for beverages with sugar and caffeine tracking.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int?` | Database ID |
| `name` | `String` | Drink name (e.g., "Coffee", "Water") |
| `quantityInMl` | `int` | Volume in ml |
| `kcal` | `int?` | Calculated calories from sugar content |
| `sugarPer100ml` | `double?` | Sugar density |
| `carbsPer100ml` | `double?` | Carbs density (mirrors sugar for drinks) |
| `caffeinePer100ml` | `double?` | Caffeine density |
| `timestamp` | `DateTime` | When consumed |
| `linked_food_entry_id` | `int?` | Optional link to a regular food entry |

### `DailyNutrition`
An in-memory aggregation model (not stored directly). Accumulates totals for display in the `NutritionSummaryWidget`.

### `TrackedFoodItem`
A convenience model combining a `FoodEntry` with its resolved `FoodItem` for UI rendering. Provides `calculatedCalories` as a computed property.

---

## 2. Workouts & Exercises

### `Exercise`
Definition of a physical movement.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int?` | Database ID |
| `name` | `String` | Exercise name |
| `description` | `String?` | Instructions or notes |
| `category` | `String` | Type: `strength`, `cardio`, `stretching` |
| `muscles` | `List<String>` | Targeted muscle groups |
| `secondaryMuscles` | `List<String>` | Supporting muscles |
| `imageUrl` | `String?` | Illustration URL (wger API) |
| `isCustom` | `bool` | Whether user-created |

### `Routine`
A reusable workout template.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int?` | Database ID |
| `name` | `String` | Template name |
| `notes` | `String?` | Optional description |

### `RoutineExercise`
Links an exercise to a routine with ordering.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int?` | Database ID |
| `routineId` | `int` | Parent routine reference |
| `exerciseId` | `int` | Exercise reference |
| `orderIndex` | `int` | Position in routine |
| `restSeconds` | `int` | Rest timer duration (seconds) |

### `WorkoutLog`
A record of a completed workout session.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int?` | Database ID |
| `routineId` | `int?` | Source routine (null for freestyle workouts) |
| `startTime` | `DateTime` | Session start |
| `endTime` | `DateTime?` | Session end |
| `notes` | `String?` | Post-workout notes |
| `durationSeconds` | `int?` | Computed duration |

---

## 3. Set System

### `SetTemplate`
A planned set within a routine (blueprint, not actual performance).

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int?` | Database ID |
| `routineExerciseId` | `int` | Parent routine-exercise link |
| `targetReps` | `int?` | Planned rep count |
| `targetWeight` | `double?` | Planned weight |
| `setType` | `String` | `normal`, `warmup`, `dropset`, `failure` |

### `SetLog`
Actual performance data for a single set during a workout.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int?` | Database ID |
| `workoutLogId` | `int` | Parent workout session |
| `exerciseId` | `int` | Exercise performed |
| `setIndex` | `int` | Order within the exercise |
| `reps` | `int?` | Actual reps completed (null = not yet performed) |
| `weight` | `double?` | Actual weight used |
| `rir` | `int?` | Reps In Reserve |
| `durationSeconds` | `int?` | For time-based exercises (e.g., plank) |
| `setType` | `String` | Set category |
| `isCompleted` | `bool` | Whether the set has been logged |

---

## 4. Measurements

### `MeasurementSession`
Groups measurements taken at the same time.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int?` | Database ID |
| `timestamp` | `DateTime` | When the measurement session occurred |

### `Measurement`
A single body metric within a session.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int?` | Database ID |
| `sessionId` | `int` | Parent session reference |
| `type` | `String` | Metric name (e.g., "Weight", "Chest", "Waist") |
| `value` | `double` | Measured value |
| `unit` | `String` | Unit of measurement (e.g., "kg", "cm") |

---

## 5. Supplements

### `Supplement`
Definition of a supplement in the user's catalog.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int?` | Database ID |
| `name` | `String` | Supplement name |
| `code` | `String?` | Internal code (e.g., `caffeine` for automatic linking) |
| `defaultDose` | `double` | Suggested single dose |
| `unit` | `String` | Dose unit (e.g., `mg`, `g`, `IU`) |
| `goalPerDay` | `double?` | Target daily intake |
| `limitPerDay` | `double?` | Maximum safe daily intake |
| `notes` | `String?` | User-provided notes |
| `isBuiltIn` | `bool` | Whether defined by the app (vs. user-created) |

### `SupplementLog`
A record of taking a supplement.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int?` | Database ID |
| `supplementId` | `int` | Reference to the supplement definition |
| `dose` | `double` | Amount taken |
| `unit` | `String` | Dose unit |
| `timestamp` | `DateTime` | When taken |
| `source_food_entry_id` | `int?` | If auto-created from a food (e.g., caffeine in coffee) |
| `source_fluid_entry_id` | `int?` | If auto-created from a fluid entry |

---

## 6. Supporting Models

| Model | Purpose |
| :--- | :--- |
| `TimelineEntry` | Abstract base class for timeline display (food, fluid, supplement entries). |
| `ChartDataPoint` | Generic `(DateTime, double)` pair for rendering `fl_chart` line charts. |
| `TrackedSupplement` | Enriches a `Supplement` with computed daily progress and log count. |
| `WaterEntry` | Legacy model for basic water logging (being replaced by `FluidEntry`). |
| `HypertrackBackup` | Top-level serialization model for full JSON backup/restore. |

---

## 7. Health Steps (Alpha)

### `health_step_segments`
Raw step records imported from Apple HealthKit (iOS) and Google Health Connect (Android).

| Field | Type | Description |
| :--- | :--- | :--- |
| `provider` | `TEXT` | `apple_healthkit` or `google_health_connect` |
| `source_id` | `TEXT?` | Source bundle id / package name (nullable) |
| `start_at` | `DATETIME (UTC)` | Segment start timestamp in UTC |
| `end_at` | `DATETIME (UTC)` | Segment end timestamp in UTC |
| `step_count` | `INTEGER` | Step count for the segment |
| `external_key` | `TEXT (UNIQUE)` | Cross-sync deduplication key |
| `id` + `local_id` + meta columns | mixed | Follows repository HybridId + MetaColumns pattern |

Deduplication strategy:
- Preferred: `external_key = "<provider>:<nativeId>"` when native record IDs are available.
- Fallback: `external_key = "<provider>:sha1(sourceId|startAtUtcIso|endAtUtcIso|stepCount)"`.

The app supports repeated sync runs safely via `INSERT OR REPLACE` on `external_key`.

---

## Database Architecture

All data is stored in a local SQLite database.

### Database Helpers

| Class | File | Tables Managed |
| :--- | :--- | :--- |
| `DatabaseHelper` | `data/database_helper.dart` | Food entries, fluid entries, meals, supplements, supplement logs, measurements, app settings |
| `WorkoutDatabaseHelper` | `data/workout_database_helper.dart` | Exercises, routines, routine exercises, set templates, workout logs, set logs |
| `ProductDatabaseHelper` | `data/product_database_helper.dart` | Food item catalog (high-volume product data) |

### Supporting Managers

| Class | File | Purpose |
| :--- | :--- | :--- |
| `BackupManager` | `data/backup_manager.dart` | JSON export/import, encrypted backups, CSV export, auto-backup scheduling |
| `ImportManager` | `data/import_manager.dart` | Hevy CSV parser and data migration |
| `BasisDataManager` | `data/basis_data_manager.dart` | Seed data: default exercises, muscle groups, built-in supplements |
| `BaseDbExporter` | `data/base_db_exporter.dart` | Abstract interface for export implementations |

### Drift ORM (Future)

The file `data/drift_database.dart` (and its generated counterpart `drift_database.g.dart`) contain a Drift-based database definition. This is prepared for the upcoming **v0.5 migration** from raw `sqflite` to Drift, which will also introduce UUID-based primary keys.

---

## Data Portability

### JSON Backup
- **Export:** Serializes the entire application state (all tables) into a single JSON structure using the `HypertrackBackup` model.
- **Encrypted Export:** The JSON payload is encrypted with AES using a user-provided passphrase via `encryption_util.dart`.
- **Import:** Automatically detects whether a file is encrypted. If encrypted, prompts for a passphrase before restoring.

### CSV Export
Selective, per-module exports:
- **Nutrition Diary:** All food entries with resolved product names and nutritional values.
- **Measurements:** All sessions with individual metrics.
- **Workouts:** Full workout history with exercise names, sets, and performance data.

### Auto-Backup
Configurable in the Data Management screen:
- User selects a directory via `FilePicker`.
- Backups run automatically at a configurable interval (default: daily).
- Retention policy: keeps the last N backups (default: 7).

### Third-Party Import
- **Hevy:** Parses the Hevy CSV export format. After import, unrecognized exercise names are flagged and can be manually mapped to existing exercises via the `ExerciseMappingScreen`.

---

[← Return to Overview](overview.md) · [System Architecture →](architecture.md)
