import 'package:flutter/material.dart';

import '../../../data/database_helper.dart';
import '../../diary/data/sources/product_local_data_source.dart';
import '../../analytics/domain/models/chart_data_point.dart';
import '../../diary/domain/models/food_entry.dart';
import '../../diary/domain/models/fluid_entry.dart';
import '../../diary/domain/models/food_item.dart';
import '../../../util/perf_debug_timer.dart';
import '../domain/statistics_range_policy.dart';

class BodyNutritionAnalyticsRawData {
  final DateTimeRange range;
  final List<ChartDataPoint> weightPoints;
  final Map<DateTime, double> caloriesByDay;

  const BodyNutritionAnalyticsRawData({
    required this.range,
    required this.weightPoints,
    required this.caloriesByDay,
  });
}

class BodyNutritionAnalyticsDataAdapter {
  final DatabaseHelper _databaseHelper;
  final ProductLocalDataSource _productDatabaseHelper;
  final StatisticsRangePolicyService _rangePolicy;

  const BodyNutritionAnalyticsDataAdapter({
    required DatabaseHelper databaseHelper,
    required ProductLocalDataSource productDatabaseHelper,
    StatisticsRangePolicyService rangePolicy =
        StatisticsRangePolicyService.instance,
  })  : _databaseHelper = databaseHelper,
        _productDatabaseHelper = productDatabaseHelper,
        _rangePolicy = rangePolicy;

  static DateTime normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  static int daysFromRangeIndex(int index) {
    switch (index) {
      case 0:
        return 7;
      case 1:
        return 30;
      case 2:
        return 90;
      case 3:
        return 180;
      default:
        return 30;
    }
  }

  Future<BodyNutritionAnalyticsRawData> fetch({
    required int rangeIndex,
    DateTime? now,
  }) async {
    return PerfDebugTimer.time(
      area: 'statistics',
      label: 'bodyNutritionFetchRaw',
      action: () async {
        final normalizedNow = normalizeDay(now ?? DateTime.now());
        final earliest = await PerfDebugTimer.time(
          area: 'statistics',
          label: 'bodyNutritionEarliest',
          action: _earliestRelevantDate,
        );
        final range = await _resolveRange(
          rangeIndex: rangeIndex,
          now: normalizedNow,
          earliestRelevantDate: earliest,
        );

        final results = await Future.wait([
          _databaseHelper.getChartDataForTypeAndRange('weight', range),
          _databaseHelper.getEntriesForDateRange(range.start, range.end),
          _databaseHelper.getFluidEntriesForDateRange(range.start, range.end),
        ]);

        final weightPoints = (results[0] as List<ChartDataPoint>);
        final foodEntries = results[1] as List<FoodEntry>;
        final fluidEntries = (results[2] as List<FluidEntry>);
        final caloriesByDay = await PerfDebugTimer.time(
          area: 'statistics',
          label: 'bodyNutritionDailyCalories',
          action: () => _dailyCaloriesMap(
            foodEntries: foodEntries,
            fluidEntries: fluidEntries,
          ),
          fields: {
            'foodRows': foodEntries.length,
            'fluidRows': fluidEntries.length,
          },
        );

        return BodyNutritionAnalyticsRawData(
          range: range,
          weightPoints: weightPoints,
          caloriesByDay: caloriesByDay,
        );
      },
    );
  }

  Future<DateTimeRange> _resolveRange({
    required int rangeIndex,
    required DateTime now,
    required DateTime? earliestRelevantDate,
  }) async {
    final resolved = _rangePolicy.resolve(
      metricId: StatisticsMetricId.bodyNutritionTrend,
      selectedRangeIndex: rangeIndex,
      now: now,
      earliestAvailableDay: earliestRelevantDate,
    );
    return resolved.dateRange ?? DateTimeRange(start: now, end: endOfDay(now));
  }

  Future<DateTime?> _earliestRelevantDate() async {
    final results = await Future.wait<DateTime?>([
      _databaseHelper.getEarliestMeasurementDate(),
      _databaseHelper.getEarliestFoodEntryDate(),
      _databaseHelper.getEarliestFluidEntryDate(),
    ]);

    final dates = results.whereType<DateTime>().map(normalizeDay).toList();
    if (dates.isEmpty) return null;

    dates.sort();
    return dates.first;
  }

  // Audit Log Summary: Resolution for Issue #380 & Issue #356 - Prevent fluid double-counting
  // Fluids that are linked to food entries (e.g., juices tracked as food items)
  // are already aggregated in the food loop below. We filter out any fluid entry
  // that possesses a valid linkedNutritionLogId or is defensively matched to a food entry.
  Future<Map<DateTime, double>> _dailyCaloriesMap({
    required List<FoodEntry> foodEntries,
    required List<FluidEntry> fluidEntries,
  }) async {
    final map = <DateTime, double>{};
    final foodProductsByBarcode = await _hydrateProductsByBarcode(
      foodEntries,
    );

    for (final entry in foodEntries) {
      final day = DateTime.utc(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      final barcode = entry.barcode;
      final product = foodProductsByBarcode[barcode];
      final caloriesPer100g = product?.calories ?? 0;
      final amountGrams = entry.quantityInGrams.toDouble();
      final added = caloriesPer100g * (amountGrams / 100.0);
      map[day] = (map[day] ?? 0.0) + added;
    }

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

      final day = DateTime.utc(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      final added = (entry.kcal ?? 0).toDouble();
      map[day] = (map[day] ?? 0.0) + added;
    }

    return map;
  }

  Future<Map<String, FoodItem>> _hydrateProductsByBarcode(
    List<FoodEntry> foodEntries,
  ) async {
    final uniqueBarcodes = foodEntries
        .map((e) => e.barcode)
        .where((barcode) => barcode.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (uniqueBarcodes.isEmpty) {
      return const {};
    }

    final products = await _productDatabaseHelper.getProductsByBarcodes(
      uniqueBarcodes,
    );
    return {
      for (final product in products) product.barcode: product,
    };
  }
}
