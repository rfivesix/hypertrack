# Train Libre - Architecture Audit & Refactoring Blueprint

## 1. UI Layer Leakage (Views vs. ViewModels)

### Diary Screen (`diary_screen.dart`)
- **Business Logic Leakage:** The view acts as a monolithic controller. Methods like `_loadDataForDateOnce` contain multi-tiered data aggregation logic (Tier 1: SQL totals, Tier 2: Product macro calculation, Tier 3: Health syncs).
- **Data Transformation:** The view manually calculates caloric and macro summaries by looping over `foodEntries` and `fluidEntries` and applying multiplication and division formulas directly in the `setState` closure context.
- **Direct Infrastructure Access:** The UI directly instantiates and queries `SharedPreferences.getInstance()` for `targetSugar` and `targetCaffeine`. It executes raw DB helper methods (`DatabaseHelper.instance.getGoalsForDate`, `WorkoutDatabaseHelper.instance.getWorkoutLogsForDateRange`).

### Live Workout Screen (`live_workout_screen.dart`)
- **Direct DB Access:** Despite using a `WorkoutSessionManager`, the view directly calls `WorkoutDatabaseHelper.instance.getLastSetsForExercise()` during initialization and when adding new exercises.
- **Presentation Logic Leakage:** Intricate UI formatting and string concatenations for Personal Records (PRs) and record types are tightly coupled inside the widget tree (`_buildPRCelebrationBanner`, `_getLocalizedRecordType`).

### Statistics Hub Screen (`statistics_hub_screen.dart`)
- **Orchestration Overload:** While it uses Adapters/Repositories, the widget directly orchestrates complex concurrent loading states (`_loadStepsSection`, `_loadSleepSection`, etc.) managing `SectionLoadState` instances manually. It directly accesses `DatabaseHelper.instance.getCurrentTargetStepsOrDefault()`.

## 2. Data Layer Cohesion (Repositories vs. Services)

### `BasisDataManager`
- **Violation of Single Responsibility:** It acts as an active orchestrator, a shared preferences caching layer, and a raw database migration script. It mixes remote API concepts (Open Food Facts catalogs) with raw SQLite `Sqflite.firstIntValue` execution. 
- **Hidden Repository Tasks:** It holds complex domain state orchestration, such as `retainHistoricallyNeededOffProducts`, which applies business rules for retaining OFF barcodes historically referenced in nutrition logs.

### `ProductDatabaseHelper`
- **Clean Boundary Status:** It partially achieves a clean boundary. It successfully maps raw SQLite companions (`db.Product`) into pure immutable Domain Models (`FoodItem`) before returning them to the caller via `_mapRowToFoodItem`. 
- **Service Leakage:** However, it takes on complex domain logic. The `fuzzyMatchForAi` method contains hardcoded business rules (scoring names, prioritizing `base` and `user` sources over `off`) which belong in a Domain Service or Use Case rather than a Database Helper.

## 3. Optional Domain Layer (Use Cases / Interactors)

Currently, complex business rules are embedded in UI controllers or data helpers. Creating standalone Use Cases would prevent ViewModels from becoming bloated.

- **Macro Tracking Aggregations:** 
  The calculation of daily nutritional balances (calories, macros, sugar, caffeine) across multiple logged meal types and fluids is currently computed in `DiaryScreen`. This should be extracted into a `CalculateDailyNutritionUseCase` which takes a Date, aggregates meals/fluids via Repositories, calculates macros, and returns a pure immutable state object.
- **Live Workout State Synchronization:** 
  The `WorkoutSessionManager` is a massive God Object. Logic like `_checkAndApplyPRs` (which calculates 1-Rep Maxes and compares against historical bests) and `updateSet` (which recalibrates total volume dynamically) should be abstracted into a `LogWorkoutSetUseCase` and a `DetectPersonalRecordUseCase`.

## 4. Blueprint & Incremental Migration Roadmap

### Summary of Architectural Deviations
1. **Views acting as Controllers:** UI widgets handle DB queries, SharedPreferences, and data aggregation directly.
2. **Missing ViewModels:** State is held entirely in `StatefulWidget` fields (`setState`) and God Object Managers (`WorkoutSessionManager`).
3. **Overloaded Data Helpers:** Database helpers contain complex fuzzy-search and AI matching domain logic instead of just CRUD.
4. **Lack of Use Cases:** Aggregation formulas and PR detection are not isolated, making them untestable without the UI or DB context.

### Incremental Refactoring Proposal: The Diary Module

**Goal:** Migrate `diary_screen.dart` to a clean MVVM structure without breaking existing features.

**Step 1: Create `nutrition_repository.dart` (Data Layer)**
- Extract all SQLite queries (`DatabaseHelper.instance.getGoalsForDate`, `getEntriesForDate`, `getFluidEntriesForDate`) into a `NutritionRepository`.
- Extract SharedPreferences logic (`targetSugar`, `targetCaffeine`) into a `UserPreferencesRepository`.
- The repositories must map internal data layers to return domain objects (`DailyNutrition`, `FluidEntry`, `TrackedFoodItem`), ensuring the ViewModel never sees raw SQL or SharedPreferences keys.

**Step 2: Extract `CalculateDailyNutritionUseCase` (Domain Layer)**
- Move the multi-tiered aggregation logic (Tier 1/Tier 2 loops) from `diary_screen.dart` into this Use Case. It will accept the daily entries and output a unified `DailyNutrition` state.

**Step 3: Create `diary_view_model.dart` (Presentation/UI Layer)**
- Create a `DiaryViewModel` extending `ChangeNotifier` (or using the Provider patterns already in the app).
- Move the `DiaryLoadCoordinator` logic and all loading states (`_isLoading`, `_isStepsWidgetLoading`) into this ViewModel.
- Expose observables/streams that the View can listen to.

**Step 4: Refactor `diary_view.dart` (UI Layer)**
- Strip `diary_screen.dart` of all data fetching, DB Helper calls, and calculation formulas.
- Convert it to listen to the `DiaryViewModel`.
- User actions like `_deleteFoodEntry` will now call `viewModel.deleteFoodEntry(id)`, and the ViewModel will coordinate with the Repository and refresh the state.
