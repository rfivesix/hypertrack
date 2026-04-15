import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/statistics/domain/body_nutrition_analytics_engine.dart';
import 'package:hypertrack/features/statistics/domain/body_nutrition_analytics_models.dart';
import 'package:hypertrack/models/chart_data_point.dart';

void main() {
  group('BodyNutritionAnalyticsEngine trend summary', () {
    test('classifies clear cut-like pattern as aligned', () {
      final start = DateTime(2026, 1, 1);
      final range = DateTimeRange(start: start, end: DateTime(2026, 2, 14));
      final result = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: List.generate(
          18,
          (i) => ChartDataPoint(
            date: start.add(Duration(days: i * 2)),
            value: 84.0 - (i * 0.22),
          ),
        ),
        caloriesByDay: {
          for (var i = 0; i < 45; i++)
            start.add(Duration(days: i)): 2500 - (i * 10.0),
        },
      );

      expect(result.weightTrend.direction, BodyNutritionTrendDirection.falling);
      expect(
          result.calorieTrend.direction, BodyNutritionTrendDirection.falling);
      expect(
        result.relationship,
        BodyNutritionRelationshipType.alignedCutLike,
      );
      expect(
        result.confidence != BodyNutritionConfidence.insufficient,
        isTrue,
      );
    });

    test('classifies stable maintenance-like pattern', () {
      final start = DateTime(2026, 3, 1);
      final range = DateTimeRange(start: start, end: DateTime(2026, 4, 10));
      final result = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: List.generate(
          14,
          (i) => ChartDataPoint(
            date: start.add(Duration(days: i * 3)),
            value: 78.0 + ((i.isEven ? 1 : -1) * 0.05),
          ),
        ),
        caloriesByDay: {
          for (var i = 0; i < 41; i++)
            start.add(Duration(days: i)): 2200 + ((i.isEven ? 1 : -1) * 30),
        },
      );

      expect(result.weightTrend.direction, BodyNutritionTrendDirection.stable);
      expect(result.calorieTrend.direction, BodyNutritionTrendDirection.stable);
      expect(
        result.relationship,
        BodyNutritionRelationshipType.stableMaintenanceLike,
      );
    });

    test('classifies clear bulk-like pattern as aligned', () {
      final start = DateTime(2026, 5, 1);
      final range = DateTimeRange(start: start, end: DateTime(2026, 6, 20));
      final result = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: List.generate(
          17,
          (i) => ChartDataPoint(
            date: start.add(Duration(days: i * 3)),
            value: 72.0 + (i * 0.18),
          ),
        ),
        caloriesByDay: {
          for (var i = 0; i < 51; i++)
            start.add(Duration(days: i)): 2350 + (i * 9.0),
        },
      );

      expect(result.weightTrend.direction, BodyNutritionTrendDirection.rising);
      expect(result.calorieTrend.direction, BodyNutritionTrendDirection.rising);
      expect(
        result.relationship,
        BodyNutritionRelationshipType.alignedBulkLike,
      );
    });

    test('gates sparse data as insufficient', () {
      final start = DateTime(2026, 7, 1);
      final range = DateTimeRange(start: start, end: DateTime(2026, 7, 14));
      final result = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: [
          ChartDataPoint(date: start.add(const Duration(days: 1)), value: 80),
          ChartDataPoint(
              date: start.add(const Duration(days: 12)), value: 79.8),
        ],
        caloriesByDay: {
          start.add(const Duration(days: 2)): 2000,
          start.add(const Duration(days: 10)): 2100,
        },
      );

      expect(result.confidence, BodyNutritionConfidence.insufficient);
      expect(
        result.relationship,
        BodyNutritionRelationshipType.insufficientData,
      );
    });

    test('classifies opposing trends as mixed or unclear', () {
      final start = DateTime(2026, 8, 1);
      final range = DateTimeRange(start: start, end: DateTime(2026, 9, 15));
      final result = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: List.generate(
          18,
          (i) => ChartDataPoint(
            date: start.add(Duration(days: i * 2)),
            value: 80.0 + (i * 0.12),
          ),
        ),
        caloriesByDay: {
          for (var i = 0; i < 46; i++)
            start.add(Duration(days: i)): 2500 - (i * 8.5),
        },
      );

      expect(
        result.relationship,
        BodyNutritionRelationshipType.mixedOrUnclear,
      );
    });

    test('normalized comparison starts both series from same baseline', () {
      final start = DateTime(2026, 10, 1);
      final range = DateTimeRange(start: start, end: DateTime(2026, 10, 30));
      final result = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: List.generate(
          10,
          (i) => ChartDataPoint(
            date: start.add(Duration(days: i * 3)),
            value: 90.0 - (i * 0.15),
          ),
        ),
        caloriesByDay: {
          for (var i = 0; i < 30; i++)
            start.add(Duration(days: i)): 2500 - i * 8,
        },
      );

      expect(result.hasComparableTrend, isTrue);
      expect(result.normalizedWeightTrend.first.value, closeTo(0, 0.0001));
      expect(result.normalizedCaloriesTrend.first.value, closeTo(0, 0.0001));
      expect(result.normalizedTrendRange, isNotNull);
    });
  });
}
