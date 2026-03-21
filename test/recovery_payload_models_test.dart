import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/statistics/domain/recovery_payload_models.dart';

void main() {
  group('RecoveryAnalyticsPayload', () {
    test('maps complete payload with typed defaults', () {
      final payload = RecoveryAnalyticsPayload.fromMap({
        'hasData': true,
        'overallState': 'mixedRecovery',
        'totals': {
          'recovering': 2,
          'ready': 3,
          'fresh': 1,
          'tracked': 6,
        },
        'muscles': [
          {
            'muscleGroup': 'Chest',
            'state': 'recovering',
            'hoursSinceLastSignificantLoad': 18,
            'lastSignificantLoadAt': DateTime(2026, 1, 1, 12),
            'lastEquivalentSets': 5.5,
            'avgRir': 1.0,
            'avgRpe': 8.0,
            'highSessionFatigue': false,
            'recoveringUpperHours': 48,
            'readyUpperHours': 72,
          },
        ],
      });

      expect(payload.hasData, isTrue);
      expect(payload.overallState, 'mixedRecovery');
      expect(payload.totals.recovering, 2);
      expect(payload.totals.ready, 3);
      expect(payload.totals.fresh, 1);
      expect(payload.totals.tracked, 6);
      expect(payload.muscles, hasLength(1));
      expect(payload.muscles.first.muscleGroup, 'Chest');
      expect(payload.muscles.first.hoursSinceLastSignificantLoad, 18);
      expect(payload.muscles.first.lastEquivalentSets, 5.5);
    });

    test('falls back to parity-safe defaults for missing fields', () {
      final payload = RecoveryAnalyticsPayload.fromMap(const {});

      expect(payload.hasData, isFalse);
      expect(payload.overallState, '');
      expect(payload.totals.recovering, 0);
      expect(payload.totals.ready, 0);
      expect(payload.totals.fresh, 0);
      expect(payload.totals.tracked, 0);
      expect(payload.muscles, isEmpty);
    });
  });
}
