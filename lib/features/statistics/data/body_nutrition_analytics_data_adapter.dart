import 'package:flutter/material.dart';

import '../../../data/database_helper.dart';
import '../../../data/product_database_helper.dart';
import '../../../models/chart_data_point.dart';
import '../../../models/food_entry.dart';
import '../../../models/fluid_entry.dart';

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
  final ProductDatabaseHelper _productDatabaseHelper;

  const BodyNutritionAnalyticsDataAdapter({
    required DatabaseHelper databaseHelper,
    required ProductDatabaseHelper productDatabaseHelper,
  })  : _databaseHelper = databaseHelper,
        _productDatabaseHelper = productDatabaseHelper;

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
    final normalizedNow = normalizeDay(now ?? DateTime.now());
    final range = await _resolveRange(
      rangeIndex: rangeIndex,
      now: normalizedNow,
    );

    final results = await Future.wait([
      _databaseHelper.getChartDataForTypeAndRange('weight', range),
      _databaseHelper.getEntriesForDateRange(range.start, range.end),
      _databaseHelper.getFluidEntriesForDateRange(range.start, range.end),
    ]);

    final weightPoints = (results[0] as List<ChartDataPoint>);
    final foodEntries = results[1] as List<FoodEntry>;
    final fluidEntries = (results[2] as List<FluidEntry>);
    final caloriesByDay = await _dailyCaloriesMap(
      foodEntries: foodEntries,
      fluidEntries: fluidEntries,
    );

    return BodyNutritionAnalyticsRawData(
      range: range,
      weightPoints: weightPoints,
      caloriesByDay: caloriesByDay,
    );
  }

  Future<DateTimeRange> _resolveRange({
    required int rangeIndex,
    required DateTime now,
  }) async {
    if (rangeIndex == 4) {
      final earliest = await _earliestRelevantDate();
      final start = earliest ?? now;
      return DateTimeRange(start: start, end: endOfDay(now));
    }

    final days = daysFromRangeIndex(rangeIndex);
    final start = now.subtract(Duration(days: days - 1));
    return DateTimeRange(start: start, end: endOfDay(now));
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

  Future<Map<DateTime, double>> _dailyCaloriesMap({
    required List<FoodEntry> foodEntries,
    required List<FluidEntry> fluidEntries,
  }) async {
    final map = <DateTime, double>{};
    final foodCaloriesPer100gCache = await _hydrateCaloriesByBarcode(foodEntries);

    for (final entry in foodEntries) {
      final day = normalizeDay(entry.timestamp);
      final barcode = entry.barcode;
      final caloriesPer100g = foodCaloriesPer100gCache[barcode] ?? 0;
      final amountGrams = entry.quantityInGrams.toDouble();
      final added = caloriesPer100g * (amountGrams / 100.0);
      map[day] = (map[day] ?? 0.0) + added;
    }

    for (final entry in fluidEntries) {
      final day = normalizeDay(entry.timestamp);
      final added = (entry.kcal ?? 0).toDouble();
      map[day] = (map[day] ?? 0.0) + added;
    }

    return map;
  }

  Future<Map<String, int>> _hydrateCaloriesByBarcode(
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

    final products =
        await _productDatabaseHelper.getProductsByBarcodes(uniqueBarcodes);
    final hydrated = <String, int>{
      for (final product in products) product.barcode: product.calories,
    };

    for (final barcode in uniqueBarcodes) {
      hydrated.putIfAbsent(barcode, () => 0);
    }
    return hydrated;
  }
}
