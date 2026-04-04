import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/domain/aggregation/sleep_period_aggregations.dart';
import 'package:hypertrack/features/sleep/domain/derived/nightly_sleep_analysis.dart';
import 'package:hypertrack/features/sleep/domain/sleep_enums.dart';

NightlySleepAnalysis _analysis({
  required DateTime date,
  double? score,
  int? totalSleepMinutes,
  DateTime? analyzedAtUtc,
}) {
  return NightlySleepAnalysis(
    id: 'analysis-${date.toIso8601String()}',
    sessionId: 'session-${date.toIso8601String()}',
    nightDate: DateTime(date.year, date.month, date.day),
    analysisVersion: 'v1',
    normalizationVersion: 'n1',
    analyzedAtUtc: analyzedAtUtc ?? DateTime.utc(2026, 1, 1, 8),
    score: score,
    totalSleepMinutes: totalSleepMinutes,
    sleepQuality: score == null
        ? SleepQualityBucket.unavailable
        : score >= 80
            ? SleepQualityBucket.good
            : score >= 60
                ? SleepQualityBucket.average
                : SleepQualityBucket.poor,
  );
}

void main() {
  group('SleepPeriodAggregationEngine.week', () {
    test('computes mean score and weekday/weekend averages', () {
      final weekStart = DateTime(2026, 3, 30); // Monday
      final engine = const SleepPeriodAggregationEngine();
      final result = engine.aggregateWeek(
        weekStart: weekStart,
        analyses: [
          _analysis(date: weekStart, score: 80, totalSleepMinutes: 420),
          _analysis(
            date: weekStart.add(const Duration(days: 1)),
            score: 70,
            totalSleepMinutes: 450,
          ),
          _analysis(
            date: weekStart.add(const Duration(days: 5)),
            score: 60,
            totalSleepMinutes: 480,
          ),
          _analysis(
            date: weekStart.add(const Duration(days: 6)),
            score: 90,
            totalSleepMinutes: 510,
          ),
        ],
      );

      expect(result.days.length, 7);
      expect(result.meanScore, closeTo(75, 0.001));
      expect(result.weekdayAverageDuration, const Duration(minutes: 435));
      expect(result.weekendAverageDuration, const Duration(minutes: 495));
      expect(result.sleepWindows.length, 7);
      expect(result.sleepWindows.first.hasData, isTrue);
      expect(result.sleepWindows[2].hasData, isFalse);
    });

    test('prefers latest analysis for same wake date', () {
      final weekStart = DateTime(2026, 3, 30);
      final engine = const SleepPeriodAggregationEngine();
      final date = weekStart.add(const Duration(days: 2));
      final result = engine.aggregateWeek(
        weekStart: weekStart,
        analyses: [
          _analysis(
            date: date,
            score: 55,
            totalSleepMinutes: 390,
            analyzedAtUtc: DateTime.utc(2026, 4, 2, 5),
          ),
          _analysis(
            date: date,
            score: 85,
            totalSleepMinutes: 450,
            analyzedAtUtc: DateTime.utc(2026, 4, 2, 7),
          ),
        ],
      );

      final day = result.days.firstWhere((item) => item.date == date);
      expect(day.score, 85);
      expect(day.totalSleepMinutes, 450);
    });
  });

  group('SleepPeriodAggregationEngine.month', () {
    test('handles sparse and empty months safely', () {
      final monthStart = DateTime(2026, 2, 1);
      final engine = const SleepPeriodAggregationEngine();
      final sparse = engine.aggregateMonth(
        monthStart: monthStart,
        analyses: [
          _analysis(
            date: DateTime(2026, 2, 3),
            score: 78,
            totalSleepMinutes: 430,
          ),
          _analysis(
            date: DateTime(2026, 2, 28),
            score: 88,
            totalSleepMinutes: 470,
          ),
        ],
      );
      expect(sparse.days.length, 28);
      expect(sparse.meanScore, closeTo(83, 0.001));
      expect(sparse.weekdayAverageDuration, const Duration(minutes: 430));
      expect(sparse.weekendAverageDuration, const Duration(minutes: 470));

      final empty = engine.aggregateMonth(
        monthStart: monthStart,
        analyses: const [],
      );
      expect(empty.days.length, 28);
      expect(empty.meanScore, isNull);
      expect(empty.weekdayAverageDuration, isNull);
      expect(empty.weekendAverageDuration, isNull);
      expect(
        empty.days.every(
          (day) => day.sleepQuality == SleepQualityBucket.unavailable,
        ),
        isTrue,
      );
    });
  });
}
