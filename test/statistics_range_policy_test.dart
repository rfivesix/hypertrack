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
      expect(
        resolved.dateRange!.end,
        DateTime(2026, 3, 21, 23, 59, 59),
      );
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

    test('dynamic all falls back to 1 day when all selected without earliest', () {
      final resolved = service.resolve(
        metricId: StatisticsMetricId.bodyNutritionTrend,
        selectedRangeIndex: 4,
        now: DateTime(2026, 3, 21),
      );

      expect(resolved.semantics, StatisticsRangeSemantics.dynamicAll);
      expect(resolved.effectiveDays, 1);
      expect(resolved.dateRange!.start, DateTime(2026, 3, 21));
    });

    test('dynamic all uses selected days when selection is not all', () {
      final resolved = service.resolve(
        metricId: StatisticsMetricId.bodyNutritionTrend,
        selectedRangeIndex: 1,
        now: DateTime(2026, 3, 21),
        earliestAvailableDay: DateTime(2025, 1, 1),
      );

      expect(resolved.effectiveDays, 30);
    });

    test('selectedDaysFromIndex falls back to default for invalid index', () {
      expect(service.selectedDaysFromIndex(-1), 30);
      expect(service.selectedDaysFromIndex(999), 30);
    });

    test('muscle weeksBack keeps existing clamp policy', () {
      final weeks = service.resolveWeeksBack(
        metricId: StatisticsMetricId.muscleAnalytics,
        effectiveDays: 180,
      );
      expect(weeks, 16);
    });

    test('resolveWeeksBack keeps lower clamp for muscle analytics', () {
      final weeks = service.resolveWeeksBack(
        metricId: StatisticsMetricId.muscleAnalytics,
        effectiveDays: 7,
      );
      expect(weeks, 4);
    });

    test('resolveWeeksBack returns fixed weeks for fixed policy metrics', () {
      final weeks = service.resolveWeeksBack(
        metricId: StatisticsMetricId.consistencyWeeklyMetrics,
      );
      expect(weeks, 12);
    });
  });
}
