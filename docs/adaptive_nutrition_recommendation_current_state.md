# Adaptive Nutrition Recommendation — Current State

## 1. Purpose and scope

### Implemented behavior
- This subsystem computes and stores adaptive nutrition recommendations (`kcal`, `protein`, `carbs`, `fat`) using recent logs plus a profile-based maintenance prior.
- Core implementation lives in:
  - `lib/features/nutrition_recommendation/data/recommendation_input_adapter.dart`
  - `lib/features/nutrition_recommendation/domain/recommendation_engine.dart`
  - `lib/features/nutrition_recommendation/data/recommendation_service.dart`
  - `lib/features/nutrition_recommendation/data/recommendation_repository.dart`
  - `lib/features/nutrition_recommendation/data/recommendation_scheduler.dart`
- UI integration is implemented in onboarding, goals, and nutrition hub:
  - `lib/screens/onboarding_screen.dart`
  - `lib/screens/goals_screen.dart`
  - `lib/screens/nutrition_hub_screen.dart`
  - `lib/features/nutrition_recommendation/presentation/nutrition_recommendation_card.dart`

### Inferred behavior from code structure
- Weekly recommendation generation is intended to run when feature state is loaded in the nutrition hub (`loadState(refreshIfDue: true)`), not via a background worker.

### Known limitations / visible gaps
- Recommendation updates are not auto-applied to active goals; explicit apply action is required (`applyLatestRecommendationToActiveTargets`).
- Adaptation currently targets calories and macros only; water/steps are preserved during apply, and sugar/fiber/salt are not part of adaptive generation.

## 2. High-level architecture

### Implemented behavior
- **Repository** (`RecommendationRepository`): persists adaptive settings and recommendation snapshots in `SharedPreferences`.
- **Scheduler** (`RecommendationScheduler`): computes Monday-anchored due week keys and stable window-end day.
- **Input adapter** (`RecommendationInputAdapter`): reads DB logs/profile/settings and builds `RecommendationGenerationInput`.
- **Recommendation engine** (`AdaptiveNutritionRecommendationEngine`): pure computation for confidence, maintenance, calorie target, macros, and warnings.
- **Service** (`AdaptiveNutritionRecommendationService`): orchestration layer combining scheduler + repository + adapter + engine, and apply workflow.
- **UI/presentation**:
  - `OnboardingScreen`: preview generation and optional apply-to-onboarding-goals flow.
  - `GoalsScreen`: user-configurable adaptive settings.
  - `NutritionHubScreen` + `NutritionRecommendationCard`: state load, render, and apply action.
- **Persistence/database helper** (`DatabaseHelper`): supplies weight, food/fluid logs, profile, goals, body-fat, workouts, and app settings to adapter/service.

### Data flow
1. User settings are loaded/saved via `RecommendationRepository` (goal direction, rate, prior activity, extra cardio).
2. `AdaptiveNutritionRecommendationService.refreshRecommendationIfDue()` computes `dueWeekKey` and stable input anchor via `RecommendationScheduler`.
3. `RecommendationInputAdapter.buildInput()` loads and preprocesses historical signals from `DatabaseHelper`.
4. `AdaptiveNutritionRecommendationEngine.generate()` computes recommendation and warning/confidence state.
5. Service persists latest generated recommendation and due week key via repository.
6. Explicit apply writes recommendation values into active DB goals via `DatabaseHelper.saveUserGoals(...)` and persists `latest_applied` snapshot.

## 3. Data model and persisted state

### Domain enums and models
- `BodyweightGoal`: `loseWeight`, `maintainWeight`, `gainWeight`.
- `PriorActivityLevel`: `low`, `moderate`, `high`, `veryHigh`.
- `ExtraCardioHoursOption`: `h0`, `h1`, `h2`, `h3`, `h5`, `h7Plus`.
- `WeeklyTargetRateOption`: `{ goal, kgPerWeek, isDefault }`.
- `WeeklyTargetRateCatalog.supportedOptions`:
  - lose: `-0.25`, `-0.50` (default), `-0.75`, `-1.00`
  - maintain: `0.00` (default)
  - gain: `0.10`, `0.25` (default), `0.50`
  - unsupported values are coerced to `defaultForGoal(...)`.
- `RecommendationConfidence`: `notEnoughData`, `low`, `medium`, `high`.
- `RecommendationWarningLevel`: `none`, `moderate`, `high`.
- `RecommendationWarningState`:
  - `hasLargeAdjustmentWarning`
  - `warningLevel`
  - `warningReasons` (string reason codes)
- `RecommendationGenerationInput`:
  - window/time: `windowStart`, `windowEnd`, `windowDays`
  - signal counts: `weightLogCount`, `intakeLoggedDays`
  - trend/intake: `smoothedWeightSlopeKgPerWeek`, `avgLoggedCalories`
  - profile/prior/baseline: `currentWeightKg`, `priorMaintenanceCalories`, `activeTargetCalories`
  - `qualityFlags`
- `RecommendationInputSummary`: persisted summary subset of generation input.
- `NutritionRecommendation`:
  - outputs: `recommendedCalories`, `recommendedProteinGrams`, `recommendedCarbsGrams`, `recommendedFatGrams`
  - model state: `estimatedMaintenanceCalories`, `goal`, `targetRateKgPerWeek`, `confidence`, `warningState`
  - metadata: `generatedAt`, `windowStart`, `windowEnd`, `algorithmVersion`, `inputSummary`, `baselineCalories`, `dueWeekKey`
- `AdaptiveNutritionRecommendationState`:
  - `goal`, `targetRateKgPerWeek`, `latestGeneratedRecommendation`, `latestAppliedRecommendation`

### SharedPreferences keys used by the feature

#### Adaptive recommendation keys (`RecommendationRepository`)
- `adaptive_nutrition_recommendation.goal_direction`: `BodyweightGoal.name`
- `adaptive_nutrition_recommendation.target_rate_kg_per_week`: `double`
- `adaptive_nutrition_recommendation.prior_activity_level`: `PriorActivityLevel.name`
- `adaptive_nutrition_recommendation.extra_cardio_hours`: `ExtraCardioHoursOption.name`
- `adaptive_nutrition_recommendation.latest_generated`: JSON string of `NutritionRecommendation`
- `adaptive_nutrition_recommendation.latest_applied`: JSON string of `NutritionRecommendation`
- `adaptive_nutrition_recommendation.last_generated_due_week_key`: due-week string (`yyyy-MM-dd` Monday anchor)

#### Adjacent onboarding/goals integration keys touched in related flows
- `userHeight`: fallback cached height (goals/onboarding integration path)
- `targetSugar`, `targetFiber`, `targetSalt`: detailed nutrient targets (currently prefs-based in goals screen)
- `hasSeenOnboarding`: onboarding completion flag

## 4. Recommendation scheduling model

### Implemented behavior
- **Due week concept**: week starts on Monday via `RecommendationScheduler.dueWeekStart(now)`.
- **Due week key**: formatted Monday date string from `dueWeekKeyFor(now)` (`yyyy-MM-dd`).
- **Stable window end day**: `stableWindowEndDayForDueWeek(now)` = previous Sunday (due-week Monday minus 1 day).
- **Duplicate prevention**: generation skipped when `dueWeekKey == lastGeneratedDueWeekKey` unless `force == true`.
- **Force behavior**: `force: true` bypasses duplicate prevention but still uses the same due week key and same stable window end anchor.
- **Persisted scheduling state**:
  - recommendation stores `dueWeekKey`
  - repository stores `last_generated_due_week_key`

### Test-confirmed semantics
- Monday anchoring and weekly key rollover verified in `recommendation_scheduler_test.dart`.
- In-week idempotency and stable-window behavior verified in `recommendation_service_test.dart`.

### Known limitation / ambiguity
- Scheduling is invocation-driven (service call path), not background-triggered.

## 5. Input aggregation and preprocessing

### Implemented behavior (`RecommendationInputAdapter.buildInput`)

#### Rolling window, normalization, and range
- `windowEndDay = normalizeDay(now)`.
- `windowStartDay = windowEndDay - (max(rollingWindowDays, 1) - 1)` (default `rollingWindowDays = 21`).
- Query range:
  - `rangeStart = windowStartDay`
  - `rangeEnd = endOfDay(windowEndDay)` (`23:59:59`)

#### Loaded data sources
- `getChartDataForTypeAndRange('weight', range)`
- `getFoodCaloriesByDayForDateRange(rangeStart, rangeEnd)`
- `getFluidEntriesForDateRange(rangeStart, rangeEnd)`
- `getUserProfile()`
- `getGoalsForDate(now)`
- `getLatestBodyFatPercentageBefore(rangeEnd)`
- `getAverageCompletedWorkoutsPerWeek(now: rangeEnd)`
- `getAppSettings()`

#### Food calorie aggregation and fallback order
- `DatabaseHelper.getFoodCaloriesByDayForDateRange(...)` resolves product calories in order:
  1. `nutrition_logs.product_id -> products.id`
  2. fallback `nutrition_logs.legacy_barcode -> products.barcode`
- If both are present, `product_id` path is used (`productById ?? productByBarcode`).
- Per-row food calories: `product.calories * (log.amount / 100.0)`.
- Unresolved rows are skipped from calorie totals and increment `unresolvedEntryCount`.

#### Unresolved food handling
- Adapter adds `qualityFlags += ['unresolved_food_calories']` when unresolved count > 0.

#### Fluid merge
- `_buildCaloriesByDay(...)` starts from food totals and adds fluid kcal per normalized day:
  - added fluid kcal = `(entry.kcal ?? 0).toDouble()`

#### Weight-by-day extraction
- Raw weight points are sorted ascending by timestamp.
- `_latestWeightByDay(...)` maps by normalized day; later same-day entries overwrite earlier ones.
- `weightLogCount` therefore counts unique days after this dedupe.

#### EWMA smoothing and slope
- EWMA alpha: `0.35`.
- Slope source: smoothed series when length >= 2, else raw.
- Slope formula:
  - `daySpan = (last.day - first.day).inDays`
  - if `daySpan <= 0` => `null`
  - else `((last.value - first.value) / daySpan) * 7` (`kg/week`)

#### Intake-day and calorie summary
- `intakeLoggedDays`: number of days where merged day calories `> 0`.
- `avgLoggedCalories`: sum of merged day calories `> 0` divided by `intakeLoggedDays` (0 when no intake days).

#### Current bodyweight
- `currentWeightKg`: last value of sorted unique-day weight series, else fallback `75.0`.

#### Usable window days
- `_usableWindowDays(...)` uses span between first and last day in union of:
  - all weight days
  - intake days with calories `> 0`
- result = inclusive day span (`last - first + 1`), or `0` if no data days.

#### Quality flags generated
- `weight_trend_unavailable` when slope is `null`
- `sparse_intake_logs` when intake days `< 5`
- `sparse_weight_logs` when weight log count `< 3`
- `unresolved_food_calories` when unresolved food entries exist

### Inferred behavior from code structure
- Because calories are computed from resolved foods only, unresolved food rows bias `avgLoggedCalories` downward; this is partially compensated by warning propagation, not by imputation.

### Known limitation / ambiguity
- No unresolved-calorie estimation is attempted; unresolved rows are counted but not quantified.

## 6. Prior maintenance calorie model

### Implemented behavior (`estimatePriorMaintenanceCalories`)

#### Required/effective inputs and fallbacks
- `currentWeightKg`: uses `75.0` fallback if non-positive.
- `heightCm`: `profile?.height` or fallback `175`.
- `ageYears`: `_estimateAgeYears(profile?.birthday, now)` or fallback `30`.
- `gender`: `profile?.gender` string.
- `bodyFatPercent` path only active when `3 < bodyFatPercent < 70`.

#### Age estimation
- `years = now.year - birthday.year`, minus one if birthday not reached this year.
- negative result => `null` (then fallback age `30`).

#### Body-fat-aware path
- If valid BF%, uses Katch-McArdle RMR:
  - `leanMassKg = weightKg * (1 - bf/100)`
  - `rmr = 370 + 21.6 * leanMassKg`

#### Mifflin fallback path
- If BF% missing/invalid, uses Mifflin-based formula:
  - `base = 10*weight + 6.25*height - 5*age`
  - gender adjustment:
    - `'male'`: `base + 5`
    - `'female'`: `base - 161`
    - other/unknown: `base - 78`

#### Activity factor composition
- Base by `PriorActivityLevel`:
  - `low 1.35`, `moderate 1.50`, `high 1.65`, `veryHigh 1.75`
- Workout adjustment (`averageCompletedWorkoutsPerWeek`):
  - `>=5`: `+0.06`
  - `>=3`: `+0.04`
  - `>=1`: `+0.02`
- Steps adjustment (`targetSteps`, default `8000`):
  - `>=13000`: `+0.05`
  - `>=10000`: `+0.03`
  - `<7000`: `-0.03`
- Extra cardio adjustment (`ExtraCardioHoursOption`):
  - `h0 +0.00`, `h1 +0.01`, `h2 +0.02`, `h3 +0.03`, `h5 +0.05`, `h7Plus +0.07`
- Activity factor clamp: `[1.20, 1.95]`

#### Final maintenance prior and clamp
- `maintenance = rmr * activityFactor`
- return `maintenance.round().clamp(1200, 5000)`

### Same-bodyweight differentiation (implemented)
- Users with same bodyweight can still get different priors due to:
  - BF%-aware vs Mifflin path
  - declared activity bucket
  - workouts/week uplift
  - step-target adjustment
  - extra cardio uplift

## 7. Adaptive recommendation engine

### Implemented behavior (`AdaptiveNutritionRecommendationEngine.generate`)

#### Confidence classification thresholds
- `high`: `windowDays >= 21 && weightLogCount >= 9 && intakeLoggedDays >= 15`
- `medium`: `windowDays >= 14 && weightLogCount >= 6 && intakeLoggedDays >= 10`
- `low`: `windowDays >= 7 && weightLogCount >= 3 && intakeLoggedDays >= 5`
- else `notEnoughData`

#### Inferred maintenance formula
- If slope is missing or intake days <= 0:
  - inferred maintenance = `priorMaintenanceCalories`
- Else:
  - `inferred = avgLoggedCalories - (smoothedWeightSlopeKgPerWeek * 7700/7)`

#### Blend factor by confidence
- `notEnoughData: 0.00`
- `low: 0.35`
- `medium: 0.60`
- `high: 0.80`
- Blended maintenance:
  - `maintenance = prior*(1-blend) + inferred*blend`

#### Weekly maintenance delta damping vs previous recommendation
- If `previousRecommendation` exists, change in maintenance is clamped per confidence:
  - `notEnoughData: ±80`
  - `low: ±110`
  - `medium: ±170`
  - `high: ±240`
- Clamp applies against `previousRecommendation.estimatedMaintenanceCalories`.

#### Calorie target from kg/week goal
- Daily adjustment:
  - `rateAdjustmentKcalPerDay = round(targetRateKgPerWeek * (7700/7))`
- `rawRecommendedCalories = estimatedMaintenanceCalories + adjustment`

#### Calorie floor logic and confidence degradation
- Minimum recommendation floor: `1200` kcal.
- If floor is applied:
  - add warning reason `calorie_floor_applied`
  - degrade confidence from `high`/`medium` to `low` (low/notEnoughData unchanged)

#### Macro computation
- Weight normalization: if `currentWeightKg <= 0`, use `75.0`.
- Protein per kg:
  - `loseWeight: 2.0`
  - `maintainWeight/gainWeight: 1.8`
- `proteinGrams = round(weight * proteinPerKg)`
- Fat floor:
  - `fatFloor = round(weight * 0.60).clamp(35, 130)`
- Initial carbs:
  - `carbs = round((recommendedCalories - protein*4 - fat*9) / 4)`

#### Constrained macro fallback when carbs would go negative
- If carbs `< 0`:
  - set `carbs = 0`
  - recompute fat: `fat = floor((recommendedCalories - protein*4)/9)`
  - if `fat < 25`, set `fat = 25`
  - if remaining calories cannot support protein target, reduce protein:
    - `protein = floor((recommendedCalories - fat*9)/4).clamp(0, 999)`
  - add warning reason `macro_distribution_constrained`
- Final clamp: protein/carbs/fat each clamped to `[0, 999]`.

#### Warning-state generation
- Baseline used for delta comparison:
  - `baselineCalories = input.activeTargetCalories ?? previousRecommendation?.recommendedCalories`
- Large adjustment thresholds (absolute delta vs baseline):
  - `>= 450` => `warningLevel = high`, reason `large_adjustment_high`, `hasLargeAdjustmentWarning = true`
  - `>= 250` => `warningLevel = moderate`, reason `large_adjustment_moderate`, `hasLargeAdjustmentWarning = true`
- Additional precedence:
  - if reasons contain `calorie_floor_applied`, force `warningLevel = high`
  - else if no large-adjustment flag and reasons not empty, set `warningLevel = moderate`
- Unresolved food propagation:
  - if input quality flags include `unresolved_food_calories`, reason is appended to warning reasons.

### Inferred behavior from code structure
- `onboarding_prior_only` quality flag is persisted in input summary but not mapped to a dedicated warning reason or UI warning message.

## 8. Onboarding behavior

### Implemented behavior
- Step order in `PageView`:
  1. welcome
  2. profile
  3. weight
  4. body-fat
  5. adaptive goal
  6. calories
  7. macros
  8. water
- Adaptive inputs in onboarding adaptive page:
  - `BodyweightGoal`
  - `PriorActivityLevel`
  - `ExtraCardioHoursOption`
  - weekly target-rate chips from `WeeklyTargetRateCatalog.optionsForGoal(...)`
- Body-fat handling:
  - optional text input (`_bodyFatPercentController`)
  - saved at finish only if `>0 && <=100` via `saveInitialBodyFatPercentage(...)`
  - recommendation prior model later validates usable BF% range (`>3 && <70`)
- Recommendation preview generation:
  - auto-refresh when entering adaptive page (`onPageChanged` at adaptive index)
  - refresh on adaptive dropdown/chip changes
  - manual refresh button (`adaptiveRecommendationRefresh`)
  - profile DOB changes can trigger refresh if current page index is adaptive or later
- Apply-to-goals preview behavior:
  - preview apply button copies recommendation kcal/protein/carbs/fat into onboarding goals text fields
  - this is local state only until finish
- Finish behavior (`_finishOnboarding`):
  - saves profile (DB), initial weight/body-fat measurements (DB when present)
  - saves adaptive settings (repository)
  - persists generated recommendation snapshot (generated now or previously previewed)
  - sets `markAsApplied` only if current goal inputs exactly match recommendation outputs
  - saves active goals via `saveUserGoals(...)` with steps fixed to `8000`
  - sets `hasSeenOnboarding = true`

### Inferred behavior from code structure
- Height, weight, gender edits reset onboarding “applied preview” marker but do not always trigger immediate preview recomputation; recomputation is guaranteed when entering adaptive page or pressing refresh.

### Known limitations / visible gaps
- Body-fat helper entry point is implemented as a static guidance bottom sheet (`showBodyFatGuidanceSheet`), not an estimator or auto-fill workflow.

## 9. Goals screen behavior

### Implemented behavior
- Current section ordering:
  1. Personal data (`goals_personal_section_title`) with height field
  2. Adaptive bodyweight target (`goals_adaptive_section_title`)
  3. Recommendation settings (`goals_recommendation_settings_section_title`)
  4. Daily goals (`goals_daily_section_title`)
  5. Detailed nutrient goals
- Personal data section currently includes height only.
- Adaptive target section includes:
  - goal direction dropdown
  - weekly target-rate choice chips filtered by selected goal
- Recommendation settings section includes:
  - prior-activity dropdown + help block
  - extra-cardio dropdown + helper text
- Save action (`_saveSettings`) writes:
  - `userHeight` to prefs
  - adaptive settings via recommendation service/repository
  - calories/protein/carbs/fat/water/steps to DB via `saveUserGoals`
  - sugar/fiber/salt to prefs

### Coexistence semantics (implemented)
- Adaptive settings and ordinary goal values coexist.
- Saving goals screen does **not** regenerate recommendations and does **not** auto-apply any recommendation snapshot.

### Known limitation / visible gap
- Sugar/fiber/salt remain prefs-backed (not in `AppSettings` schema per code comments).

## 10. Nutrition hub behavior

### Implemented behavior
- Hub load (`_loadHubData`) reads:
  - active target calories for today from DB goals
  - meals list
  - adaptive state via `loadState(refreshIfDue: true)`
- Refresh triggers:
  - initial first load in `didChangeDependencies`
  - pull-to-refresh (`RefreshIndicator`)
  - after apply action
  - after relevant navigation returns
- Recommendation card displays:
  - empty state when no generated recommendation
  - otherwise goal/rate, maintenance estimate, kcal/macros, confidence, data-basis counts, active target calories, warning banner, apply button
- Apply-to-active-goals:
  - card button -> `applyLatestRecommendationToActiveTargets()`
  - updates DB daily goals (kcal/macros from recommendation, water/steps preserved from current settings/defaults)
  - persists `latest_applied` snapshot
  - shows success/failure snackbar and refreshes hub data

### What does not mutate automatically
- Recommendation refresh does not change active DB goals.
- Only explicit apply mutates active goals.

## 11. Warnings, confidence, and data quality semantics

### Confidence semantics (operational)
- `notEnoughData`: minimum thresholds not met; recommendation still generated but with blend `0` (prior-dominant).
- `low`/`medium`/`high`: progressively stricter data thresholds and higher inferred-maintenance blending.

### Warning-level semantics
- `none`: no large adjustment and no extra warning reasons.
- `moderate`: either medium-sized adjustment (`>=250`) or non-empty reasons without high-severity triggers.
- `high`: large adjustment (`>=450`) or calorie floor application.

### Large-adjustment warnings
- Generated only when baseline calories are available.
- Reason code is explicit: `large_adjustment_moderate` or `large_adjustment_high`.

### Unresolved food warnings
- Unresolved nutrition rows produce input quality flag `unresolved_food_calories`.
- Engine propagates that into warning reasons; UI warning message maps this reason explicitly.

### Data-quality flags
- `sparse_intake_logs`, `sparse_weight_logs`, `weight_trend_unavailable`, `onboarding_prior_only` are persisted in `inputSummary.qualityFlags`.
- UI currently exposes confidence level and data-basis counts, but does not render dedicated messages for all quality flags.

## 12. Backup/restore implications

### Implemented behavior
- Backup manager serializes **all** SharedPreferences keys into `userPreferences` and restores them on import (`backup_manager.dart`).
- Therefore adaptive recommendation prefs state is backup/restore-covered, including:
  - goal direction, target rate, prior activity, extra cardio
  - latest generated/applied recommendation JSON snapshots
  - last generated due week key
- Apply-related goal changes are persisted in the normal DB goal/settings path and are expected to be covered by DB backup payloads, subject to the current backup_manager.dart table export set.

### Test-confirmed coverage
- `backup_restore_integrity_test.dart` explicitly verifies restore for:
  - goal, target rate, prior activity, extra cardio
  - latest generated recommendation JSON
  - last generated due week key

### Inferred coverage from implementation
- `latest_applied` key is not explicitly asserted in the adaptive backup test, but should be covered by the all-keys SharedPreferences export/import loop.

## 13. Current limitations and non-final areas

### Visible in code/tests
- Weekly generation is call-driven from UI/service usage; no background scheduler/job is implemented.
- Activity/cardio priors are bucket-based and deliberately coarse (`PriorActivityLevel`, `ExtraCardioHoursOption`).
- Unresolved food entries are counted and warned, but not calorie-imputed.
- Baseline comparison for warning deltas uses `activeTargetCalories` from adapter input (anchored to stable window-end date in weekly refresh path), which can differ from current-day UI target context.
- Onboarding body-fat helper is informational only (manual lookup sheet).
- Quality flags beyond unresolved-food are not surfaced as specific card warnings.
- Detailed nutrient goals (`targetSugar/targetFiber/targetSalt`) remain prefs-backed integration fields, separate from adaptive model/persistence structures.

## 14. Semantic verification checklist

- [ ] **Scheduling semantics**: due week key is Monday-anchored; stable window-end is previous Sunday; same due week does not regenerate unless forced.
- [ ] **Persistence semantics**: repository writes/reads all adaptive keys and recommendation JSON snapshots (`latest_generated`, `latest_applied`, due week key).
- [ ] **Onboarding semantics**: body-fat step exists after weight; adaptive preview generates from current onboarding inputs; finish persists recommendation/settings/profile/goals as implemented.
- [ ] **Apply semantics**: recommendation refresh alone does not mutate active goals; explicit apply updates DB goals and stores `latest_applied`.
- [ ] **Generation semantics**: confidence thresholds, blend factors, delta damping, calorie floor, and macro fallback paths match engine constants/formulas.
- [ ] **Warning/confidence semantics**: large-adjustment thresholds (`250/450`), floor override to high, unresolved-food propagation, and confidence degradation on floor are intact.
- [ ] **Localization coverage**: adaptive strings used in onboarding/goals/card/hub exist in both `app_en.arb` and `app_de.arb`; card German title has test coverage.
- [ ] **Placeholder acceptance for alpha**: informational body-fat helper sheet (no estimator), coarse activity/cardio buckets, unresolved-food conservative handling, and non-surfaced quality flags are explicitly accepted.
