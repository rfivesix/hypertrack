import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/statistics/domain/consistency_domain_service.dart';

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
        weeklyMetrics: const [
          {'count': 1},
          {'count': 2},
          {'count': 1},
          {'count': 2}, // prior avg 1.5
          {'count': 3},
          {'count': 2},
          {'count': 4},
          {'count': 3}, // recent avg 3.0
        ],
      );

      expect(result, 1.5);
    });

    test('returns zero rhythm delta when less than 8 weeks', () {
      final result = ConsistencyDomainService.computeRhythmDelta(
        weeklyMetrics: const [
          {'count': 1},
          {'count': 2},
          {'count': 1},
          {'count': 2},
          {'count': 3},
          {'count': 2},
          {'count': 4},
        ],
      );

      expect(result, 0);
    });

    test('computes rolling consistency over capped recent 8 weeks', () {
      final result = ConsistencyDomainService.rollingConsistencyPercent(
        weeklyMetrics: const [
          {'count': 0},
          {'count': 2},
          {'count': 1},
          {'count': 2},
          {'count': 2},
          {'count': 3},
          {'count': 1},
          {'count': 2},
          {'count': 2},
          {'count': 0},
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
  });
}
