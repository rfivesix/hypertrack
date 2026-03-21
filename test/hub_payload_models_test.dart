import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/statistics/domain/consistency_payload_models.dart';
import 'package:hypertrack/features/statistics/domain/hub_payload_models.dart';
import 'package:hypertrack/features/statistics/domain/recovery_payload_models.dart';

void main() {
  group('StatisticsHubPayload', () {
    test('stores typed contract parts without shape changes', () {
      final training = TrainingStatsPayload.fromMap(const {
        'totalWorkouts': 20,
        'thisWeekCount': 3,
        'avgPerWeek': 2.0,
        'streakWeeks': 4,
      });
      final recovery = RecoveryAnalyticsPayload.fromMap(const {
        'hasData': true,
        'overallState': 'mostlyRecovered',
        'totals': {'recovering': 1, 'ready': 2, 'fresh': 3, 'tracked': 6},
      });
      final consistency = WeeklyConsistencyMetricPayload.fromMap({
        'weekStart': DateTime(2026, 3, 16),
        'weekLabel': '16.3.',
        'count': 3,
        'durationMinutes': 150,
        'tonnage': 8000,
      });

      final payload = StatisticsHubPayload(
        recentPrs: const [
          {'exercise': 'Squat'}
        ],
        weeklyVolume: const [
          {'week': 'W1', 'volume': 1000}
        ],
        workoutsPerWeek: const [
          {'week': 'W1', 'count': 3}
        ],
        weeklyConsistencyMetrics: [consistency],
        muscleAnalytics: const {'score': 78},
        trainingStats: training,
        recoveryAnalytics: recovery,
        notableImprovements: const [
          {'exercise': 'Bench Press', 'delta': 5}
        ],
      );

      expect(payload.trainingStats.totalWorkouts, 20);
      expect(payload.recoveryAnalytics.totals.tracked, 6);
      expect(payload.weeklyConsistencyMetrics.single.count, 3);
      expect(payload.recentPrs.single['exercise'], 'Squat');
      expect(payload.muscleAnalytics['score'], 78);
    });
  });
}
