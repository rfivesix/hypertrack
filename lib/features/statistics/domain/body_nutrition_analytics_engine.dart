import 'package:flutter/material.dart';

import '../../../models/chart_data_point.dart';
import 'body_nutrition_analytics_models.dart';
import 'statistics_data_quality_policy.dart';

class BodyNutritionAnalyticsEngine {
  const BodyNutritionAnalyticsEngine._();
  static const _dataQualityPolicy = StatisticsDataQualityPolicy.instance;

  static DateTime normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static BodyNutritionAnalyticsResult build({
    required DateTimeRange range,
    required List<ChartDataPoint> weightPoints,
    required Map<DateTime, double> caloriesByDay,
  }) {
    final weightByDay = _latestWeightPerDay(weightPoints);
    final allDays = _enumerateDays(range.start, range.end);

    final weightDaily = <DailyValuePoint>[];
    final caloriesDaily = <DailyValuePoint>[];
    int loggedCalorieDays = 0;

    for (final day in allDays) {
      final calories = caloriesByDay[day] ?? 0.0;
      if (calories > 0) {
        loggedCalorieDays += 1;
      }
      caloriesDaily.add(DailyValuePoint(day: day, value: calories));

      final weight = weightByDay[day];
      if (weight != null) {
        weightDaily.add(DailyValuePoint(day: day, value: weight));
      }
    }

    final smoothedWeight = movingAverage(
      series: weightDaily,
      windowSize: weightDaily.length >= 14 ? 5 : 3,
    );
    final smoothedCalories = movingAverage(
      series: caloriesDaily,
      windowSize: caloriesDaily.length >= 30 ? 7 : 3,
    );

    final totalDays = allDays.length;
    final avgDailyCalories = totalDays <= 0
        ? 0.0
        : caloriesDaily.fold<double>(0.0, (sum, p) => sum + p.value) /
            totalDays;

    final currentWeightKg = weightDaily.isEmpty ? null : weightDaily.last.value;
    final weightChangeKg = weightChange(smoothedWeight, weightDaily);

    final insightDataQuality = _dataQualityPolicy.bodyNutritionInsight(
      spanDays:
          normalizeDay(range.end).difference(normalizeDay(range.start)).inDays +
              1,
      totalDays: totalDays,
      weightDays: weightDaily.length,
      loggedCalorieDays: loggedCalorieDays,
    );

    final insightType = deriveInsight(
      range: range,
      totalDays: totalDays,
      weightDaily: weightDaily,
      smoothedWeight: smoothedWeight,
      caloriesDaily: caloriesDaily,
      smoothedCalories: smoothedCalories,
      loggedCalorieDays: loggedCalorieDays,
      weightChangeKg: weightChangeKg,
      qualityAssessment: insightDataQuality,
    );

    return BodyNutritionAnalyticsResult(
      range: range,
      totalDays: totalDays,
      currentWeightKg: currentWeightKg,
      weightChangeKg: weightChangeKg,
      avgDailyCalories: avgDailyCalories,
      weightDays: weightDaily.length,
      loggedCalorieDays: loggedCalorieDays,
      weightDaily: weightDaily,
      smoothedWeight: smoothedWeight,
      caloriesDaily: caloriesDaily,
      smoothedCalories: smoothedCalories,
      insightType: insightType,
      insightDataQuality: insightDataQuality,
    );
  }

  static List<DailyValuePoint> normalizedSeries(List<DailyValuePoint> points) {
    if (points.isEmpty) return const [];
    final minValue = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxValue = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final span = (maxValue - minValue).abs();
    if (span < 0.0001) {
      return points
          .map((p) => DailyValuePoint(day: p.day, value: 0.5))
          .toList(growable: false);
    }

    return points
        .map(
          (p) =>
              DailyValuePoint(day: p.day, value: (p.value - minValue) / span),
        )
        .toList(growable: false);
  }

  static Map<DateTime, double> _latestWeightPerDay(
    List<ChartDataPoint> points,
  ) {
    final sorted = points.toList()..sort((a, b) => a.date.compareTo(b.date));

    final map = <DateTime, double>{};
    for (final point in sorted) {
      map[normalizeDay(point.date)] = point.value;
    }
    return map;
  }

  static List<DateTime> _enumerateDays(DateTime start, DateTime end) {
    final normalizedStart = normalizeDay(start);
    final normalizedEnd = normalizeDay(end);
    final result = <DateTime>[];
    var cursor = normalizedStart;
    while (!cursor.isAfter(normalizedEnd)) {
      result.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  static List<DailyValuePoint> movingAverage({
    required List<DailyValuePoint> series,
    required int windowSize,
  }) {
    if (series.isEmpty) return const [];
    if (windowSize <= 1) return List<DailyValuePoint>.from(series);

    final values = series.map((p) => p.value).toList(growable: false);
    final result = <DailyValuePoint>[];

    for (var i = 0; i < series.length; i++) {
      final start = (i - windowSize + 1).clamp(0, i);
      final slice = values.sublist(start, i + 1);
      final avg =
          slice.fold<double>(0.0, (sum, value) => sum + value) / slice.length;
      result.add(DailyValuePoint(day: series[i].day, value: avg));
    }

    return result;
  }

  static double? weightChange(
    List<DailyValuePoint> smoothedWeight,
    List<DailyValuePoint> rawWeight,
  ) {
    final source = smoothedWeight.length >= 2 ? smoothedWeight : rawWeight;
    if (source.length < 2) return null;
    return source.last.value - source.first.value;
  }

  static BodyNutritionInsightType deriveInsight({
    required DateTimeRange range,
    required int totalDays,
    required List<DailyValuePoint> weightDaily,
    required List<DailyValuePoint> smoothedWeight,
    required List<DailyValuePoint> caloriesDaily,
    required List<DailyValuePoint> smoothedCalories,
    required int loggedCalorieDays,
    required double? weightChangeKg,
    StatisticsDataQualityAssessment? qualityAssessment,
  }) {
    final hasDataQuality = (qualityAssessment ??
            _dataQualityPolicy.bodyNutritionInsight(
              spanDays: normalizeDay(
                    range.end,
                  ).difference(normalizeDay(range.start)).inDays +
                  1,
              totalDays: totalDays,
              weightDays: weightDaily.length,
              loggedCalorieDays: loggedCalorieDays,
            ))
        .hasSufficientData;

    if (!hasDataQuality || weightChangeKg == null) {
      return BodyNutritionInsightType.notEnoughData;
    }

    final calorieChange = seriesHalfDelta(
      smoothedCalories.isNotEmpty ? smoothedCalories : caloriesDaily,
    );

    if (calorieChange == null) {
      return BodyNutritionInsightType.notEnoughData;
    }

    if (weightChangeKg.abs() < 0.35 && calorieChange >= 120) {
      return BodyNutritionInsightType.stableWeightCaloriesUp;
    }

    if (weightChangeKg >= 0.45 && calorieChange >= 80) {
      return BodyNutritionInsightType.weightUpCaloriesUp;
    }

    if (calorieChange <= -120 && weightChangeKg > -0.2) {
      return BodyNutritionInsightType.caloriesDownWeightNotYetChanged;
    }

    if (weightChangeKg <= -0.45 && calorieChange <= -80) {
      return BodyNutritionInsightType.weightDownCaloriesDown;
    }

    return BodyNutritionInsightType.mixed;
  }

  static double? seriesHalfDelta(List<DailyValuePoint> series) {
    if (series.length < 8) return null;
    final half = (series.length / 2).floor();
    if (half <= 0 || half >= series.length) return null;

    final first = series.sublist(0, half);
    final second = series.sublist(half);

    final firstAvg =
        first.fold<double>(0.0, (sum, p) => sum + p.value) / first.length;
    final secondAvg =
        second.fold<double>(0.0, (sum, p) => sum + p.value) / second.length;

    return secondAvg - firstAvg;
  }
}
