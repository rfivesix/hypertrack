import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/statistics/domain/consistency_domain_service.dart';
import 'package:hypertrack/features/statistics/domain/consistency_payload_models.dart';

void main() {
  group('ConsistencyDomainService', () {
    test('formats trend with sign and one decimal', () {
      expect(ConsistencyDomainService.formatTrend(0), '+0.0');
      expect(ConsistencyDomainService.formatTrend(1.25), '+1.3');
      expect(ConsistencyDomainService.formatTrend(-0.25), '-0.3');
    });

    test('computes training days per week for last 4 weeks', () {
      final now = DateTime(2026, 3, 20);
      final result = ConsistencyDomainService.computeTrainingDaysPerWeekLast4(
        now: now,
        workoutDayCounts: {
          now.subtract(const Duration(days: 1)): 1,
          now.subtract(const Duration(days: 7)): 2,
          now.subtract(const Duration(days: 20)): 1,
          now.subtract(const Duration(days: 28)): 1,
          now.subtract(const Duration(days: 29)): 1, // outside
          now.subtract(const Duration(days: 3)): 0, // not active
        },
      );

      expect(result, 1.0); // 4 active days / 4 weeks
    });

    test('computes rhythm delta from recent 4 vs prior 4 weeks', () {
      final result = ConsistencyDomainService.computeRhythmDelta(
        weeklyMetrics: [
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 1, 6),
            weekLabel: '6.1.',
            count: 1,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 1, 13),
            weekLabel: '13.1.',
            count: 2,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 1, 20),
            weekLabel: '20.1.',
            count: 1,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 1, 27),
            weekLabel: '27.1.',
            count: 2,
            durationMinutes: 0,
            tonnage: 0,
          ), // prior avg 1.5
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 2, 3),
            weekLabel: '3.2.',
            count: 3,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 2, 10),
            weekLabel: '10.2.',
            count: 2,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 2, 17),
            weekLabel: '17.2.',
            count: 4,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 2, 24),
            weekLabel: '24.2.',
            count: 3,
            durationMinutes: 0,
            tonnage: 0,
          ), // recent avg 3.0
        ],
      );

      expect(result, 1.5);
    });

    test('returns zero rhythm delta when less than 8 weeks', () {
      final result = ConsistencyDomainService.computeRhythmDelta(
        weeklyMetrics: [
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 1, 6),
            weekLabel: '6.1.',
            count: 1,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 1, 13),
            weekLabel: '13.1.',
            count: 2,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 1, 20),
            weekLabel: '20.1.',
            count: 1,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 1, 27),
            weekLabel: '27.1.',
            count: 2,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 2, 3),
            weekLabel: '3.2.',
            count: 3,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 2, 10),
            weekLabel: '10.2.',
            count: 2,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 2, 17),
            weekLabel: '17.2.',
            count: 4,
            durationMinutes: 0,
            tonnage: 0,
          ),
        ],
      );

      expect(result, 0);
    });

    test('computes rolling consistency over capped recent 8 weeks', () {
      final result = ConsistencyDomainService.rollingConsistencyPercent(
        weeklyMetrics: [
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 1, 6),
            weekLabel: '6.1.',
            count: 0,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 1, 13),
            weekLabel: '13.1.',
            count: 2,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 1, 20),
            weekLabel: '20.1.',
            count: 1,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 1, 27),
            weekLabel: '27.1.',
            count: 2,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 2, 3),
            weekLabel: '3.2.',
            count: 2,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 2, 10),
            weekLabel: '10.2.',
            count: 3,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 2, 17),
            weekLabel: '17.2.',
            count: 1,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 2, 24),
            weekLabel: '24.2.',
            count: 2,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 3, 3),
            weekLabel: '3.3.',
            count: 2,
            durationMinutes: 0,
            tonnage: 0,
          ),
          WeeklyConsistencyMetricPayload(
            weekStart: DateTime(2026, 3, 10),
            weekLabel: '10.3.',
            count: 0,
            durationMinutes: 0,
            tonnage: 0,
          ),
        ],
      );

      expect(result, 62.5); // last 8 weeks: 5/8 have count >= 2
    });

    test('returns zero rolling consistency for empty weekly metrics', () {
      final result = ConsistencyDomainService.rollingConsistencyPercent(
        weeklyMetrics: const [],
      );

      expect(result, 0);
    });

    test('maps training stats payload from dynamic map with defaults', () {
      final payload = TrainingStatsPayload.fromMap({
        'totalWorkouts': 42,
        'thisWeekCount': 3,
        'avgPerWeek': 2.25,
        'streakWeeks': 5,
      });

      expect(payload.totalWorkouts, 42);
      expect(payload.thisWeekCount, 3);
      expect(payload.avgPerWeek, 2.25);
      expect(payload.streakWeeks, 5);

      final fallback = TrainingStatsPayload.fromMap(const {});
      expect(fallback.totalWorkouts, 0);
      expect(fallback.thisWeekCount, 0);
      expect(fallback.avgPerWeek, 0.0);
      expect(fallback.streakWeeks, 0);
    });

    test('maps weekly consistency payload from dynamic map with defaults', () {
      final payload = WeeklyConsistencyMetricPayload.fromMap({
        'weekStart': DateTime(2026, 3, 16),
        'weekLabel': '16.3.',
        'count': 4,
        'durationMinutes': 195.5,
        'tonnage': 12345.0,
      });

      expect(payload.weekStart, DateTime(2026, 3, 16));
      expect(payload.weekLabel, '16.3.');
      expect(payload.count, 4);
      expect(payload.durationMinutes, 195.5);
      expect(payload.tonnage, 12345.0);

      final fallback = WeeklyConsistencyMetricPayload.fromMap(const {});
      expect(fallback.weekStart, DateTime.fromMillisecondsSinceEpoch(0));
      expect(fallback.weekLabel, '');
      expect(fallback.count, 0);
      expect(fallback.durationMinutes, 0.0);
      expect(fallback.tonnage, 0.0);
    });
  });
}
