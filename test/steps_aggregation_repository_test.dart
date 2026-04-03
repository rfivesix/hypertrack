import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/steps/data/steps_aggregation_repository.dart';

void main() {
  group('InMemoryStepsAggregationRepository', () {
    const repository = InMemoryStepsAggregationRepository();

    test(
      'day aggregation returns 24 hourly buckets and correct total',
      () async {
        final targetDate = DateTime(2026, 3, 26, 14, 30);
        final day = await repository.getDayAggregation(targetDate);

        expect(day.hourlyBuckets.length, 24);
        expect(day.date, DateTime(2026, 3, 26));
        expect(
          day.totalSteps,
          day.hourlyBuckets.fold<int>(0, (sum, bucket) => sum + bucket.steps),
        );
        expect(day.hourlyBuckets.first.start, DateTime(2026, 3, 26, 0));
        expect(day.hourlyBuckets.last.start, DateTime(2026, 3, 26, 23));
      },
    );

    test('week aggregation starts on Monday and returns 7 days', () async {
      final targetDate = DateTime(2026, 3, 26); // Thursday
      final week = await repository.getWeekAggregation(targetDate);

      expect(week.weekStart.weekday, DateTime.monday);
      expect(week.dailyTotals.length, 7);
      expect(week.dailyTotals.first.start, week.weekStart);
      expect(
        week.dailyTotals.last.start,
        week.weekStart.add(const Duration(days: 6)),
      );
      expect(
        week.totalSteps,
        week.dailyTotals.fold<int>(0, (sum, bucket) => sum + bucket.steps),
      );
      expect(week.averageDailySteps, closeTo(week.totalSteps / 7, 0.000001));
    });

    test('month aggregation covers all days in target month', () async {
      final month = await repository.getMonthAggregation(DateTime(2026, 2, 17));

      expect(month.monthStart, DateTime(2026, 2, 1));
      expect(month.dailyTotals.length, 28);
      expect(month.dailyTotals.first.start, DateTime(2026, 2, 1));
      expect(month.dailyTotals.last.start, DateTime(2026, 2, 28));
      expect(
        month.totalSteps,
        month.dailyTotals.fold<int>(0, (sum, bucket) => sum + bucket.steps),
      );
    });
  });
}
