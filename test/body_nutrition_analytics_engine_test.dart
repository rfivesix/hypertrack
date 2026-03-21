import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/statistics/domain/body_nutrition_analytics_engine.dart';
import 'package:hypertrack/features/statistics/domain/body_nutrition_analytics_models.dart';
import 'package:hypertrack/features/statistics/domain/statistics_data_quality_policy.dart';
import 'package:hypertrack/models/chart_data_point.dart';

void main() {
  group('BodyNutritionAnalyticsEngine', () {
    test('build keeps daily alignment and averages', () {
      final start = DateTime(2026, 1, 1);
      final range = DateTimeRange(start: start, end: DateTime(2026, 1, 3));
      final result = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: [
          ChartDataPoint(date: DateTime(2026, 1, 1, 8), value: 80),
          ChartDataPoint(date: DateTime(2026, 1, 2, 8), value: 79.8),
          ChartDataPoint(date: DateTime(2026, 1, 3, 8), value: 79.6),
        ],
        caloriesByDay: {
          DateTime(2026, 1, 1): 2000,
          DateTime(2026, 1, 2): 2100,
          DateTime(2026, 1, 3): 2200,
        },
      );

      expect(result.totalDays, 3);
      expect(result.weightDays, 3);
      expect(result.loggedCalorieDays, 3);
      expect(result.avgDailyCalories, closeTo(2100.0, 0.0001));
      expect(result.currentWeightKg, closeTo(79.6, 0.0001));
      expect(result.caloriesDaily.map((e) => e.value), [2000, 2100, 2200]);
      expect(result.insightDataQuality.hasSufficientData, isFalse);
    });

    test('deriveInsight returns stableWeightCaloriesUp for matching thresholds',
        () {
      final start = DateTime(2026, 1, 1);
      final range = DateTimeRange(start: start, end: DateTime(2026, 1, 14));
      final calories = List.generate(
        14,
        (i) => DailyValuePoint(
          day: start.add(Duration(days: i)),
          value: i < 7 ? 1800 : 2000,
        ),
      );
      final weights = List.generate(
        14,
        (i) => DailyValuePoint(
          day: start.add(Duration(days: i)),
          value: 80 + (i * 0.01),
        ),
      );

      final insight = BodyNutritionAnalyticsEngine.deriveInsight(
        range: range,
        totalDays: 14,
        weightDaily: weights,
        smoothedWeight: weights,
        caloriesDaily: calories,
        smoothedCalories: calories,
        loggedCalorieDays: 14,
        weightChangeKg: 0.12,
      );

      expect(insight, BodyNutritionInsightType.stableWeightCaloriesUp);
    });

    test('deriveInsight returns weightUpCaloriesUp at threshold boundaries',
        () {
      final start = DateTime(2026, 1, 1);
      final range = DateTimeRange(start: start, end: DateTime(2026, 1, 14));
      final calories = List.generate(
        14,
        (i) => DailyValuePoint(
          day: start.add(Duration(days: i)),
          value: i < 7 ? 1900 : 1980,
        ),
      );
      final weights = List.generate(
        14,
        (i) => DailyValuePoint(
          day: start.add(Duration(days: i)),
          value: 80 + (i * 0.04),
        ),
      );

      final insight = BodyNutritionAnalyticsEngine.deriveInsight(
        range: range,
        totalDays: 14,
        weightDaily: weights,
        smoothedWeight: weights,
        caloriesDaily: calories,
        smoothedCalories: calories,
        loggedCalorieDays: 14,
        weightChangeKg: 0.45,
      );

      expect(insight, BodyNutritionInsightType.weightUpCaloriesUp);
    });

    test('deriveInsight returns caloriesDownWeightNotYetChanged', () {
      final start = DateTime(2026, 1, 1);
      final range = DateTimeRange(start: start, end: DateTime(2026, 1, 14));
      final calories = List.generate(
        14,
        (i) => DailyValuePoint(
          day: start.add(Duration(days: i)),
          value: i < 7 ? 2100 : 1980,
        ),
      );
      final weights = List.generate(
        14,
        (i) => DailyValuePoint(
          day: start.add(Duration(days: i)),
          value: 80 - (i * 0.005),
        ),
      );

      final insight = BodyNutritionAnalyticsEngine.deriveInsight(
        range: range,
        totalDays: 14,
        weightDaily: weights,
        smoothedWeight: weights,
        caloriesDaily: calories,
        smoothedCalories: calories,
        loggedCalorieDays: 14,
        weightChangeKg: -0.1,
      );

      expect(insight, BodyNutritionInsightType.caloriesDownWeightNotYetChanged);
    });

    test('deriveInsight returns weightDownCaloriesDown at thresholds', () {
      final start = DateTime(2026, 1, 1);
      final range = DateTimeRange(start: start, end: DateTime(2026, 1, 14));
      final calories = List.generate(
        14,
        (i) => DailyValuePoint(
          day: start.add(Duration(days: i)),
          value: i < 7 ? 2200 : 2120,
        ),
      );
      final weights = List.generate(
        14,
        (i) => DailyValuePoint(
          day: start.add(Duration(days: i)),
          value: 80 - (i * 0.04),
        ),
      );

      final insight = BodyNutritionAnalyticsEngine.deriveInsight(
        range: range,
        totalDays: 14,
        weightDaily: weights,
        smoothedWeight: weights,
        caloriesDaily: calories,
        smoothedCalories: calories,
        loggedCalorieDays: 14,
        weightChangeKg: -0.45,
      );

      expect(insight, BodyNutritionInsightType.weightDownCaloriesDown);
    });

    test('deriveInsight returns notEnoughData when data quality is low', () {
      final start = DateTime(2026, 1, 1);
      final range = DateTimeRange(start: start, end: DateTime(2026, 1, 10));
      final shortSeries = List.generate(
        7,
        (i) => DailyValuePoint(
          day: start.add(Duration(days: i)),
          value: 1800 + i.toDouble(),
        ),
      );

      final insight = BodyNutritionAnalyticsEngine.deriveInsight(
        range: range,
        totalDays: 10,
        weightDaily: shortSeries,
        smoothedWeight: shortSeries,
        caloriesDaily: shortSeries,
        smoothedCalories: shortSeries,
        loggedCalorieDays: 6,
        weightChangeKg: 0.1,
      );

      expect(insight, BodyNutritionInsightType.notEnoughData);
    });

    test('deriveInsight returns mixed for sufficient but non-matching pattern',
        () {
      final start = DateTime(2026, 1, 1);
      final range = DateTimeRange(start: start, end: DateTime(2026, 1, 14));
      final calories = List.generate(
        14,
        (i) => DailyValuePoint(
          day: start.add(Duration(days: i)),
          value: i < 7 ? 2000 : 2040,
        ),
      );
      final weights = List.generate(
        14,
        (i) => DailyValuePoint(
          day: start.add(Duration(days: i)),
          value: 80 + (i * 0.02),
        ),
      );

      final insight = BodyNutritionAnalyticsEngine.deriveInsight(
        range: range,
        totalDays: 14,
        weightDaily: weights,
        smoothedWeight: weights,
        caloriesDaily: calories,
        smoothedCalories: calories,
        loggedCalorieDays: 14,
        weightChangeKg: 0.28,
      );

      expect(insight, BodyNutritionInsightType.mixed);
    });

    test('seriesHalfDelta returns null for insufficient series length', () {
      final start = DateTime(2026, 1, 1);
      final series = List.generate(
        7,
        (i) => DailyValuePoint(day: start.add(Duration(days: i)), value: i + 1),
      );
      expect(BodyNutritionAnalyticsEngine.seriesHalfDelta(series), isNull);
    });

    test('weightChange uses raw points when smoothed has < 2 points', () {
      final raw = [
        DailyValuePoint(day: DateTime(2026, 1, 1), value: 80),
        DailyValuePoint(day: DateTime(2026, 1, 2), value: 79.5),
      ];
      final delta = BodyNutritionAnalyticsEngine.weightChange(
        const [],
        raw,
      );
      expect(delta, closeTo(-0.5, 0.0001));
    });

    test('normalizedSeries returns 0.5 for flat values', () {
      final series = [
        DailyValuePoint(day: DateTime(2026, 1, 1), value: 42),
        DailyValuePoint(day: DateTime(2026, 1, 2), value: 42),
      ];
      final normalized = BodyNutritionAnalyticsEngine.normalizedSeries(series);
      expect(normalized.map((e) => e.value), [0.5, 0.5]);
    });

    test('data quality policy marks sufficient ranges correctly', () {
      final assessment =
          StatisticsDataQualityPolicy.instance.bodyNutritionInsight(
        spanDays: 30,
        totalDays: 30,
        weightDays: 10,
        loggedCalorieDays: 10,
      );
      expect(assessment.hasSufficientData, isTrue);
    });

    test('build keeps latest weight point per day when duplicates exist', () {
      final day = DateTime(2026, 1, 1);
      final range = DateTimeRange(start: day, end: day);
      final result = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: [
          ChartDataPoint(date: DateTime(2026, 1, 1, 8), value: 80.2),
          ChartDataPoint(date: DateTime(2026, 1, 1, 18), value: 79.9),
        ],
        caloriesByDay: const {},
      );

      expect(result.weightDays, 1);
      expect(result.currentWeightKg, 79.9);
    });
  });
}
