import 'models/daily_goal.dart';
import 'models/daily_nutrition.dart';
import 'models/fluid_entry.dart';
import 'models/food_entry.dart';
import 'models/food_item.dart';
import 'models/tracked_food_item.dart';
import '../../supplements/domain/models/supplement.dart';
import '../../supplements/domain/models/supplement_log.dart';
import '../../supplements/domain/models/tracked_supplement.dart';
import '../../workout/domain/models/workout_log.dart';

class DailyNutritionState {
  final DailyNutrition summary;
  final Map<String, List<TrackedFoodItem>> entriesByMeal;
  final List<TrackedSupplement> trackedSupplements;
  final Map<String, dynamic>? workoutSummary;

  DailyNutritionState({
    required this.summary,
    required this.entriesByMeal,
    required this.trackedSupplements,
    this.workoutSummary,
  });
}

class CalculateDailyNutritionUseCase {
  DailyNutritionState execute({
    required DailyGoal? goals,
    required int targetSugar,
    required int targetCaffeine,
    required List<FoodEntry> foodEntries,
    required List<FluidEntry> fluidEntries,
    required List<FoodItem> foodProducts,
    required List<WorkoutLog> workoutLogs,
    required List<Supplement> supplementsForDate,
    required List<Supplement> allSupplements,
    required List<SupplementLog> todaysSupplementLogs,
  }) {
    final targetCalories = goals?.targetCalories ?? 2500;
    final targetProtein = goals?.targetProtein ?? 180;
    final targetCarbs = goals?.targetCarbs ?? 250;
    final targetFat = goals?.targetFat ?? 80;
    final targetWater = goals?.targetWater ?? 3000;

    final summary = DailyNutrition(
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetCarbs: targetCarbs,
      targetFat: targetFat,
      targetWater: targetWater,
      targetSugar: targetSugar,
      targetCaffeine: targetCaffeine,
    );

    // Workout Summary
    final completedLogs =
        workoutLogs.where((log) => log.endTime != null).toList();
    Map<String, dynamic>? workoutSummary;
    if (completedLogs.isNotEmpty) {
      Duration totalDuration = Duration.zero;
      double totalVolume = 0.0;
      int totalSets = 0;
      for (final log in completedLogs) {
        totalDuration += log.endTime!.difference(log.startTime);
        totalSets += log.sets.length;
        for (final set in log.sets) {
          totalVolume += (set.weightKg ?? 0) * (set.reps ?? 0);
        }
      }
      workoutSummary = {
        'duration': totalDuration,
        'volume': totalVolume,
        'sets': totalSets,
        'count': completedLogs.length,
      };
    }

    final foodProductsByBarcode = {
      for (final product in foodProducts) product.barcode: product,
    };

    // Fluids
    summary.water =
        fluidEntries.fold<int>(0, (sum, entry) => sum + entry.quantityInMl);
    for (final entry in fluidEntries) {
      final isLinked = entry.linkedFoodEntryId != null;
      final isDuplicateOfFood = foodEntries.any((food) {
        final foodItem = foodProductsByBarcode[food.barcode];
        final isFluidFood = foodItem != null &&
            (foodItem.isFluid || (foodItem.isLiquid ?? false));
        if (!isFluidFood) return false;

        // Match by linked ID
        if (entry.linkedFoodEntryId == food.id) return true;

        // Defensive match: same day/time and similar quantity
        final timeDiff =
            entry.timestamp.difference(food.timestamp).inSeconds.abs();
        if (timeDiff < 2 && entry.quantityInMl == food.quantityInGrams) {
          return true;
        }
        return false;
      });

      if (isLinked || isDuplicateOfFood) {
        continue;
      }

      summary.calories += entry.kcal ?? 0;
      final factor = entry.quantityInMl / 100.0;
      summary.sugar += (entry.sugarPer100ml ?? 0) * factor;
      summary.carbs += ((entry.carbsPer100ml ?? 0) * factor).round();
    }

    // Food

    final Map<String, List<TrackedFoodItem>> groupedEntries = {
      'mealtypeBreakfast': [],
      'mealtypeLunch': [],
      'mealtypeDinner': [],
      'mealtypeSnack': [],
    };

    for (final entry in foodEntries) {
      final foodItem = foodProductsByBarcode[entry.barcode];
      if (foodItem != null) {
        summary.calories +=
            (foodItem.calories / 100 * entry.quantityInGrams).round();
        summary.protein +=
            (foodItem.protein / 100 * entry.quantityInGrams).round();
        summary.carbs += (foodItem.carbs / 100 * entry.quantityInGrams).round();
        summary.fat += (foodItem.fat / 100 * entry.quantityInGrams).round();
        summary.sugar +=
            (foodItem.sugar ?? 0) * (entry.quantityInGrams / 100.0);

        final trackedItem = TrackedFoodItem(entry: entry, item: foodItem);
        groupedEntries[entry.mealType]?.add(trackedItem);
      }
    }

    for (var meal in groupedEntries.values) {
      meal.sort((a, b) => b.entry.timestamp.compareTo(a.entry.timestamp));
    }

    // Supplements
    final Map<int, double> todaysDoses = {};
    for (final log in todaysSupplementLogs) {
      todaysDoses.update(
        log.supplementId,
        (value) => value + log.dose,
        ifAbsent: () => log.dose,
      );
    }

    Supplement? caffeineSupplement;
    try {
      caffeineSupplement =
          allSupplements.firstWhere((s) => s.code == 'caffeine');
    } catch (e) {
      caffeineSupplement = null;
    }

    if (caffeineSupplement != null && caffeineSupplement.id != null) {
      summary.caffeine = todaysDoses[caffeineSupplement.id] ?? 0.0;
    }

    final Map<int, Supplement> byId = {
      for (final s in allSupplements)
        if (s.id != null) s.id!: s,
    };

    final List<TrackedSupplement> trackedSupps = [];
    for (final s in supplementsForDate) {
      final hasLog = todaysDoses.containsKey(s.id);
      if (s.isTracked || hasLog) {
        trackedSupps.add(
          TrackedSupplement(
            supplement: s,
            totalDosedToday: todaysDoses[s.id] ?? 0.0,
          ),
        );
      }
    }
    for (final id in todaysDoses.keys) {
      if (!trackedSupps.any((ts) => ts.supplement.id == id)) {
        if (byId.containsKey(id)) {
          trackedSupps.add(
            TrackedSupplement(
              supplement: byId[id]!,
              totalDosedToday: todaysDoses[id]!,
            ),
          );
        }
      }
    }

    return DailyNutritionState(
      summary: summary,
      entriesByMeal: groupedEntries,
      trackedSupplements: trackedSupps,
      workoutSummary: workoutSummary,
    );
  }
}
