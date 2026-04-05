import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/database_helper.dart';
import '../../../data/product_database_helper.dart';
import '../../../models/chart_data_point.dart';
import '../../../models/fluid_entry.dart';
import '../../../models/food_entry.dart';
import '../../../data/drift_database.dart' as db;
import '../domain/recommendation_models.dart';

class RecommendationInputAdapter {
  final DatabaseHelper _databaseHelper;
  final ProductDatabaseHelper _productDatabaseHelper;

  const RecommendationInputAdapter({
    required DatabaseHelper databaseHelper,
    required ProductDatabaseHelper productDatabaseHelper,
  })  : _databaseHelper = databaseHelper,
        _productDatabaseHelper = productDatabaseHelper;

  static DateTime normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  Future<RecommendationGenerationInput> buildInput({
    required DateTime now,
    int rollingWindowDays = 21,
  }) async {
    final windowEndDay = normalizeDay(now);
    final windowStartDay = windowEndDay
        .subtract(Duration(days: math.max(rollingWindowDays, 1) - 1));

    final rangeStart = windowStartDay;
    final rangeEnd = endOfDay(windowEndDay);

    final results = await Future.wait<dynamic>([
      _databaseHelper.getChartDataForTypeAndRange(
        'weight',
        DateTimeRange(start: rangeStart, end: rangeEnd),
      ),
      _databaseHelper.getEntriesForDateRange(rangeStart, rangeEnd),
      _databaseHelper.getFluidEntriesForDateRange(rangeStart, rangeEnd),
      _databaseHelper.getUserProfile(),
      _databaseHelper.getGoalsForDate(now),
    ]);

    final weightPoints = results[0] as List<ChartDataPoint>;
    final foodEntries = results[1] as List<FoodEntry>;
    final fluidEntries = results[2] as List<FluidEntry>;
    final profile = results[3] as db.Profile?;
    final activeGoals = results[4] as db.DailyGoalsHistoryData?;

    final caloriesByDay = await _buildCaloriesByDay(
      foodEntries: foodEntries,
      fluidEntries: fluidEntries,
    );

    final weightByDay = _latestWeightByDay(weightPoints);
    final sortedWeightDays = weightByDay.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    final sortedWeightSeries = sortedWeightDays
        .map((day) => _WeightedDayPoint(day: day, value: weightByDay[day]!))
        .toList(growable: false);

    final smoothedWeightSeries = _ewma(
      sortedWeightSeries,
      alpha: 0.35,
    );
    final weightSlopeKgPerWeek =
        _trendSlopeKgPerWeek(smoothedWeightSeries, sortedWeightSeries);

    final intakeLoggedDays =
        caloriesByDay.values.where((value) => value > 0).length;
    final loggedCaloriesTotal = caloriesByDay.values
        .where((value) => value > 0)
        .fold<double>(0.0, (sum, value) => sum + value);
    final avgLoggedCalories =
        intakeLoggedDays == 0 ? 0.0 : loggedCaloriesTotal / intakeLoggedDays;

    final currentWeightKg =
        sortedWeightSeries.isNotEmpty ? sortedWeightSeries.last.value : 75.0;
    final priorMaintenanceCalories = estimatePriorMaintenanceCalories(
      profile: profile,
      currentWeightKg: currentWeightKg,
      now: now,
    );

    final windowDays = _usableWindowDays(
      weightDays: sortedWeightDays,
      caloriesByDay: caloriesByDay,
    );

    final qualityFlags = <String>[];
    if (weightSlopeKgPerWeek == null) {
      qualityFlags.add('weight_trend_unavailable');
    }
    if (intakeLoggedDays < 5) {
      qualityFlags.add('sparse_intake_logs');
    }
    if (sortedWeightSeries.length < 3) {
      qualityFlags.add('sparse_weight_logs');
    }

    return RecommendationGenerationInput(
      windowStart: windowStartDay,
      windowEnd: rangeEnd,
      windowDays: windowDays,
      weightLogCount: sortedWeightSeries.length,
      intakeLoggedDays: intakeLoggedDays,
      smoothedWeightSlopeKgPerWeek: weightSlopeKgPerWeek,
      avgLoggedCalories: avgLoggedCalories,
      currentWeightKg: currentWeightKg,
      priorMaintenanceCalories: priorMaintenanceCalories,
      activeTargetCalories: activeGoals?.targetCalories,
      qualityFlags: qualityFlags,
    );
  }

  static int estimatePriorMaintenanceCalories({
    required db.Profile? profile,
    required double currentWeightKg,
    required DateTime now,
    int fallbackHeightCm = 175,
  }) {
    final weightKg = currentWeightKg > 0 ? currentWeightKg : 75.0;
    final heightCm = profile?.height ?? fallbackHeightCm;
    final ageYears = _estimateAgeYears(profile?.birthday, now) ?? 30;
    final gender = profile?.gender;

    final baseMifflin = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears);

    double rmr;
    if (gender == 'male') {
      rmr = baseMifflin + 5;
    } else if (gender == 'female') {
      rmr = baseMifflin - 161;
    } else {
      rmr = baseMifflin - 78;
    }

    final maintenance = rmr * 1.45;
    return maintenance.round().clamp(1200, 5000);
  }

  static int? _estimateAgeYears(DateTime? birthday, DateTime now) {
    if (birthday == null) {
      return null;
    }
    var years = now.year - birthday.year;
    final hadBirthdayThisYear = now.month > birthday.month ||
        (now.month == birthday.month && now.day >= birthday.day);
    if (!hadBirthdayThisYear) {
      years -= 1;
    }
    return years < 0 ? null : years;
  }

  int _usableWindowDays({
    required List<DateTime> weightDays,
    required Map<DateTime, double> caloriesByDay,
  }) {
    final intakeDays = caloriesByDay.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList(growable: false);

    final allDataDays = <DateTime>{...weightDays, ...intakeDays}.toList()
      ..sort((a, b) => a.compareTo(b));

    if (allDataDays.isEmpty) {
      return 0;
    }

    final first = allDataDays.first;
    final last = allDataDays.last;
    return normalizeDay(last).difference(normalizeDay(first)).inDays + 1;
  }

  Future<Map<DateTime, double>> _buildCaloriesByDay({
    required List<FoodEntry> foodEntries,
    required List<FluidEntry> fluidEntries,
  }) async {
    final caloriesByDay = <DateTime, double>{};
    final caloriesByBarcode = await _hydrateCaloriesByBarcode(foodEntries);

    for (final entry in foodEntries) {
      final day = normalizeDay(entry.timestamp);
      final caloriesPer100g = caloriesByBarcode[entry.barcode] ?? 0;
      final addedCalories = caloriesPer100g * (entry.quantityInGrams / 100);
      caloriesByDay[day] = (caloriesByDay[day] ?? 0.0) + addedCalories;
    }

    for (final entry in fluidEntries) {
      final day = normalizeDay(entry.timestamp);
      final addedCalories = (entry.kcal ?? 0).toDouble();
      caloriesByDay[day] = (caloriesByDay[day] ?? 0.0) + addedCalories;
    }

    return caloriesByDay;
  }

  Future<Map<String, int>> _hydrateCaloriesByBarcode(
    List<FoodEntry> foodEntries,
  ) async {
    final barcodes = foodEntries
        .map((entry) => entry.barcode)
        .where((barcode) => barcode.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (barcodes.isEmpty) {
      return const {};
    }

    final products =
        await _productDatabaseHelper.getProductsByBarcodes(barcodes);

    final byBarcode = <String, int>{
      for (final product in products) product.barcode: product.calories,
    };

    for (final barcode in barcodes) {
      byBarcode.putIfAbsent(barcode, () => 0);
    }

    return byBarcode;
  }

  Map<DateTime, double> _latestWeightByDay(List<ChartDataPoint> points) {
    final sorted = points.toList()..sort((a, b) => a.date.compareTo(b.date));
    final byDay = <DateTime, double>{};

    for (final point in sorted) {
      byDay[normalizeDay(point.date)] = point.value;
    }

    return byDay;
  }

  List<_WeightedDayPoint> _ewma(
    List<_WeightedDayPoint> source, {
    required double alpha,
  }) {
    if (source.isEmpty) {
      return const [];
    }

    final smoothed = <_WeightedDayPoint>[];
    var previous = source.first.value;

    for (final point in source) {
      final next = (alpha * point.value) + ((1 - alpha) * previous);
      smoothed.add(_WeightedDayPoint(day: point.day, value: next));
      previous = next;
    }

    return smoothed;
  }

  double? _trendSlopeKgPerWeek(
    List<_WeightedDayPoint> smoothed,
    List<_WeightedDayPoint> raw,
  ) {
    final source = smoothed.length >= 2 ? smoothed : raw;
    if (source.length < 2) {
      return null;
    }

    final first = source.first;
    final last = source.last;
    final daySpan =
        normalizeDay(last.day).difference(normalizeDay(first.day)).inDays;
    if (daySpan <= 0) {
      return null;
    }

    final totalDelta = last.value - first.value;
    return (totalDelta / daySpan) * 7;
  }
}

class _WeightedDayPoint {
  final DateTime day;
  final double value;

  const _WeightedDayPoint({
    required this.day,
    required this.value,
  });
}
