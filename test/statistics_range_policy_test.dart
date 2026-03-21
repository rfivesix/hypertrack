import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/statistics/domain/statistics_range_policy.dart';

void main() {
  group('StatisticsRangePolicyService', () {
    const service = StatisticsRangePolicyService.instance;

    test('selected semantics resolves to selected range days', () {
      final resolved = service.resolve(
        metricId: StatisticsMetricId.muscleAnalytics,
        selectedRangeIndex: 2,
        now: DateTime(2026, 3, 21),
      );

      expect(resolved.semantics, StatisticsRangeSemantics.selected);
      expect(resolved.effectiveDays, 90);
      expect(resolved.dateRange, isA<DateTimeRange>());
    });

    test('capped semantics clamps effective days', () {
      final resolved = service.resolve(
        metricId: StatisticsMetricId.hubNotablePrImprovements,
        selectedRangeIndex: 4,
        selectedDays: 3650,
        now: DateTime(2026, 3, 21),
      );

      expect(resolved.semantics, StatisticsRangeSemantics.capped);
      expect(resolved.effectiveDays, 90);
    });

    test('fixed semantics keeps configured weeks', () {
      final resolved = service.resolve(
        metricId: StatisticsMetricId.consistencyWeeklyMetrics,
        now: DateTime(2026, 3, 21),
      );

      expect(resolved.semantics, StatisticsRangeSemantics.fixed);
      expect(resolved.effectiveWeeks, 12);
    });

    test('dynamic all uses earliest day when all is selected', () {
      final resolved = service.resolve(
        metricId: StatisticsMetricId.bodyNutritionTrend,
        selectedRangeIndex: 4,
        now: DateTime(2026, 3, 21),
        earliestAvailableDay: DateTime(2026, 2, 20),
      );

      expect(resolved.semantics, StatisticsRangeSemantics.dynamicAll);
      expect(resolved.effectiveDays, 30);
    });

    test('muscle weeksBack keeps existing clamp policy', () {
      final weeks = service.resolveWeeksBack(
        metricId: StatisticsMetricId.muscleAnalytics,
        effectiveDays: 180,
      );
      expect(weeks, 16);
    });
  });
}
