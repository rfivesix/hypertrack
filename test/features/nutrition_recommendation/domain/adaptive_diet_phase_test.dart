import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/adaptive_diet_phase.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';

void main() {
  group('AdaptiveDietPhase mapping', () {
    test('maps goal direction to canonical phase', () {
      expect(
        BodyweightGoal.loseWeight.canonicalDietPhase,
        AdaptiveDietPhase.cut,
      );
      expect(
        BodyweightGoal.maintainWeight.canonicalDietPhase,
        AdaptiveDietPhase.maintain,
      );
      expect(
        BodyweightGoal.gainWeight.canonicalDietPhase,
        AdaptiveDietPhase.bulk,
      );
    });
  });

  group('AdaptiveDietPhaseTrackingState', () {
    test('pending phase does not immediately reset confirmed phase', () {
      final start = DateTime(2026, 4, 1);
      final state = AdaptiveDietPhaseTrackingState.bootstrap(
        phase: AdaptiveDietPhase.cut,
        asOfDay: start,
      );

      final pending = state.reconcile(
        observedPhase: AdaptiveDietPhase.bulk,
        asOfDay: DateTime(2026, 4, 2),
      );

      expect(pending.confirmedPhase, AdaptiveDietPhase.cut);
      expect(pending.pendingPhase, AdaptiveDietPhase.bulk);
      expect(
        pending.pendingPhaseFirstSeenDay,
        AdaptiveDietPhaseTrackingState.normalizeDay(DateTime(2026, 4, 2)),
      );
    });

    test('phase switches only after 7 consecutive days', () {
      final start = DateTime(2026, 4, 1);
      final state = AdaptiveDietPhaseTrackingState.bootstrap(
        phase: AdaptiveDietPhase.cut,
        asOfDay: start,
      ).reconcile(
        observedPhase: AdaptiveDietPhase.bulk,
        asOfDay: DateTime(2026, 4, 2),
      );

      final day6 = state.reconcile(
        observedPhase: AdaptiveDietPhase.bulk,
        asOfDay: DateTime(2026, 4, 7),
      );
      final day7 = day6.reconcile(
        observedPhase: AdaptiveDietPhase.bulk,
        asOfDay: DateTime(2026, 4, 8),
      );

      expect(day6.confirmedPhase, AdaptiveDietPhase.cut);
      expect(day6.pendingPhase, AdaptiveDietPhase.bulk);
      expect(day7.confirmedPhase, AdaptiveDietPhase.bulk);
      expect(day7.pendingPhase, isNull);
      expect(
        day7.confirmedPhaseStartDay,
        AdaptiveDietPhaseTrackingState.normalizeDay(DateTime(2026, 4, 8)),
      );
    });

    test('reverting before confirmation cancels pending phase reset', () {
      final state = AdaptiveDietPhaseTrackingState.bootstrap(
        phase: AdaptiveDietPhase.cut,
        asOfDay: DateTime(2026, 4, 1),
      ).reconcile(
        observedPhase: AdaptiveDietPhase.bulk,
        asOfDay: DateTime(2026, 4, 2),
      );

      final reverted = state.reconcile(
        observedPhase: AdaptiveDietPhase.cut,
        asOfDay: DateTime(2026, 4, 4),
      );

      expect(reverted.confirmedPhase, AdaptiveDietPhase.cut);
      expect(reverted.pendingPhase, isNull);
      expect(reverted.pendingPhaseFirstSeenDay, isNull);
    });
  });
}
