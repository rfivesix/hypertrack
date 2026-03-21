import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/statistics/domain/consistency_payload_models.dart';

void main() {
  group('Consistency payload models', () {
    test('training payload maps typed values', () {
      final payload = TrainingStatsPayload.fromMap({
        'totalWorkouts': 15,
        'thisWeekCount': 4,
        'avgPerWeek': 2.5,
        'streakWeeks': 6,
      });

      expect(payload.totalWorkouts, 15);
      expect(payload.thisWeekCount, 4);
      expect(payload.avgPerWeek, 2.5);
      expect(payload.streakWeeks, 6);
    });

    test('training payload falls back for missing or invalid values', () {
      final payload = TrainingStatsPayload.fromMap({
        'totalWorkouts': 'invalid',
        'thisWeekCount': null,
      });

      expect(payload.totalWorkouts, 0);
      expect(payload.thisWeekCount, 0);
      expect(payload.avgPerWeek, 0);
      expect(payload.streakWeeks, 0);
    });

    test('weekly metric payload maps and defaults correctly', () {
      final payload = WeeklyConsistencyMetricPayload.fromMap({
        'weekStart': DateTime(2026, 3, 16),
        'weekLabel': '16.3.',
        'count': 3,
        'durationMinutes': 120.5,
        'tonnage': 9500.0,
      });

      expect(payload.weekStart, DateTime(2026, 3, 16));
      expect(payload.weekLabel, '16.3.');
      expect(payload.count, 3);
      expect(payload.durationMinutes, 120.5);
      expect(payload.tonnage, 9500.0);

      final fallback = WeeklyConsistencyMetricPayload.fromMap({
        'weekStart': 'bad',
        'weekLabel': 42,
        'count': 'bad',
        'durationMinutes': null,
        'tonnage': false,
      });
      expect(fallback.weekStart, DateTime.fromMillisecondsSinceEpoch(0));
      expect(fallback.weekLabel, '');
      expect(fallback.count, 0);
      expect(fallback.durationMinutes, 0);
      expect(fallback.tonnage, 0);
    });
  });
}
