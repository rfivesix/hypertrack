import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/statistics/domain/recovery_domain_service.dart';

void main() {
  group('RecoveryDomainService', () {
    test('detects high session fatigue from avgRir and avgRpe', () {
      expect(
        RecoveryDomainService.hasHighSessionFatigue(avgRir: 0, avgRpe: null),
        isTrue,
      );
      expect(
        RecoveryDomainService.hasHighSessionFatigue(avgRir: null, avgRpe: 9),
        isTrue,
      );
      expect(
        RecoveryDomainService.hasHighSessionFatigue(avgRir: 1, avgRpe: 8.5),
        isFalse,
      );
    });

    test('computes fatigue-adjusted thresholds identically', () {
      expect(
        RecoveryDomainService.recoveringUpperHours(highSessionFatigue: false),
        48,
      );
      expect(
        RecoveryDomainService.readyUpperHours(highSessionFatigue: false),
        72,
      );
      expect(
        RecoveryDomainService.recoveringUpperHours(highSessionFatigue: true),
        72,
      );
      expect(
        RecoveryDomainService.readyUpperHours(highSessionFatigue: true),
        96,
      );
    });

    test('classifies muscle state identically at boundaries', () {
      expect(
        RecoveryDomainService.muscleState(
          hoursSinceLastSignificantLoad: 47.9,
          highSessionFatigue: false,
        ),
        RecoveryDomainService.stateRecovering,
      );
      expect(
        RecoveryDomainService.muscleState(
          hoursSinceLastSignificantLoad: 48,
          highSessionFatigue: false,
        ),
        RecoveryDomainService.stateReady,
      );
      expect(
        RecoveryDomainService.muscleState(
          hoursSinceLastSignificantLoad: 72.1,
          highSessionFatigue: false,
        ),
        RecoveryDomainService.stateFresh,
      );
    });

    test('classifies overall state identically', () {
      expect(
        RecoveryDomainService.overallState(
          totalTrackedMuscles: 0,
          recoveringCount: 0,
        ),
        RecoveryDomainService.overallInsufficientData,
      );
      expect(
        RecoveryDomainService.overallState(
          totalTrackedMuscles: 5,
          recoveringCount: 0,
        ),
        RecoveryDomainService.overallMostlyRecovered,
      );
      expect(
        RecoveryDomainService.overallState(
          totalTrackedMuscles: 5,
          recoveringCount: 2,
        ),
        RecoveryDomainService.overallSeveralRecovering,
      );
      expect(
        RecoveryDomainService.overallState(
          totalTrackedMuscles: 5,
          recoveringCount: 1,
        ),
        RecoveryDomainService.overallMixedRecovery,
      );
    });

    test('computes recovery pressure score identically and clamps range', () {
      final low = RecoveryDomainService.recoveryPressureScore(const {
        'lastEquivalentSets': 0,
        'hoursSinceLastSignificantLoad': 120,
        'highSessionFatigue': false,
      });
      final high = RecoveryDomainService.recoveryPressureScore(const {
        'lastEquivalentSets': 5,
        'hoursSinceLastSignificantLoad': 0,
        'highSessionFatigue': true,
      });

      expect(low, 0);
      expect(high, 100);
    });

    test('hides brachialis muscle only', () {
      expect(RecoveryDomainService.shouldHideMuscle('brachialis'), isTrue);
      expect(RecoveryDomainService.shouldHideMuscle(' Brachialis '), isTrue);
      expect(RecoveryDomainService.shouldHideMuscle('chest'), isFalse);
    });
  });
}
