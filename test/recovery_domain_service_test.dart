import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/statistics/domain/recovery_domain_service.dart';

void main() {
  group('RecoveryDomainService', () {
    test('detects high session fatigue from RIR and RPE thresholds', () {
      expect(
        RecoveryDomainService.hasHighSessionFatigue(avgRir: 0, avgRpe: null),
        isTrue,
      );
      expect(
        RecoveryDomainService.hasHighSessionFatigue(avgRir: 0.5, avgRpe: null),
        isTrue,
      );
      expect(
        RecoveryDomainService.hasHighSessionFatigue(avgRir: 1, avgRpe: null),
        isFalse,
      );
      expect(
        RecoveryDomainService.hasHighSessionFatigue(avgRir: null, avgRpe: 8.5),
        isTrue,
      );
      expect(
        RecoveryDomainService.hasHighSessionFatigue(avgRir: null, avgRpe: 8.0),
        isFalse,
      );
      expect(
        RecoveryDomainService.hasHighSessionFatigue(avgRir: 1, avgRpe: 8.5),
        isTrue,
      );
      expect(
        RecoveryDomainService.hasHighSessionFatigue(avgRir: null, avgRpe: null),
        isFalse,
      );
    });

    test('computes muscle-specific base windows with normalized labels', () {
      expect(
        RecoveryDomainService.recoveringUpperHours(
          highSessionFatigue: false,
        ),
        48,
      );
      expect(
        RecoveryDomainService.readyUpperHours(highSessionFatigue: false),
        72,
      );
      expect(
        RecoveryDomainService.recoveringUpperHours(
          highSessionFatigue: false,
          muscleGroup: 'front_delts',
        ),
        36,
      );
      expect(
        RecoveryDomainService.readyUpperHours(
          highSessionFatigue: false,
          muscleGroup: 'Biceps',
        ),
        60,
      );
      expect(
        RecoveryDomainService.recoveringUpperHours(
          highSessionFatigue: false,
          muscleGroup: 'quads',
        ),
        60,
      );
      expect(
        RecoveryDomainService.readyUpperHours(
          highSessionFatigue: false,
          muscleGroup: 'lower_back',
        ),
        120,
      );
    });

    test('applies load and intensity extensions to both boundaries', () {
      expect(RecoveryDomainService.loadBasedExtensionHours(0.5), 0);
      expect(RecoveryDomainService.loadBasedExtensionHours(1), 0);
      expect(RecoveryDomainService.loadBasedExtensionHours(3), 6);
      expect(RecoveryDomainService.loadBasedExtensionHours(5), 12);
      expect(RecoveryDomainService.loadBasedExtensionHours(8), 24);
      expect(RecoveryDomainService.loadBasedExtensionHours(11), 36);

      expect(
        RecoveryDomainService.recoveringUpperHours(
          highSessionFatigue: true,
          muscleGroup: 'chest',
          lastEquivalentSets: 8,
        ),
        96,
      );
      expect(
        RecoveryDomainService.readyUpperHours(
          highSessionFatigue: true,
          muscleGroup: 'chest',
          lastEquivalentSets: 8,
        ),
        120,
      );
    });

    test('classifies default muscle state inclusively at boundaries', () {
      expectBoundary(
        muscleGroup: 'chest',
        recoveringUpper: 48,
        readyUpper: 72,
      );
    });

    test('classifies fast muscle state inclusively at boundaries', () {
      expectBoundary(
        muscleGroup: 'biceps',
        recoveringUpper: 36,
        readyUpper: 60,
      );
    });

    test('classifies slow muscle state inclusively at boundaries', () {
      expectBoundary(
        muscleGroup: 'quads',
        recoveringUpper: 60,
        readyUpper: 96,
      );
    });

    test('classifies extended muscle state inclusively at boundaries', () {
      expectBoundary(
        muscleGroup: 'chest',
        recoveringUpper: 96,
        readyUpper: 120,
        highSessionFatigue: true,
        lastEquivalentSets: 8,
      );
    });

    test('classifies overall state by recovering ratio', () {
      expect(
        RecoveryDomainService.overallState(
          totalTrackedMuscles: 0,
          recoveringCount: 0,
        ),
        RecoveryDomainService.overallInsufficientData,
      );
      expect(
        RecoveryDomainService.overallState(
          totalTrackedMuscles: 4,
          recoveringCount: 2,
        ),
        RecoveryDomainService.overallSeveralRecovering,
      );
      expect(
        RecoveryDomainService.overallState(
          totalTrackedMuscles: 10,
          recoveringCount: 3,
        ),
        RecoveryDomainService.overallMixedRecovery,
      );
      expect(
        RecoveryDomainService.overallState(
          totalTrackedMuscles: 10,
          recoveringCount: 4,
        ),
        RecoveryDomainService.overallSeveralRecovering,
      );
      expect(
        RecoveryDomainService.overallState(
          totalTrackedMuscles: 5,
          recoveringCount: 0,
        ),
        RecoveryDomainService.overallMostlyRecovered,
      );
    });

    test('computes realistic load pressure anchors', () {
      expect(loadOnlyPressure(0), closeTo(0, 0.001));
      expect(loadOnlyPressure(1), closeTo(10, 0.001));
      expect(loadOnlyPressure(2), closeTo(18, 0.001));
      expect(loadOnlyPressure(6), closeTo(47, 0.001));
      expect(loadOnlyPressure(10), closeTo(60, 0.001));
      expect(loadOnlyPressure(12), closeTo(65, 0.001));
      expect(loadOnlyPressure(20), closeTo(65, 0.001));
    });

    test('keeps recovery pressure monotonic with equivalent sets', () {
      final samples = [0.0, 1.0, 2.0, 3.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0];
      var previous = -1.0;

      for (final sets in samples) {
        final score = loadOnlyPressure(sets);
        expect(score, greaterThanOrEqualTo(previous));
        previous = score;
      }
    });

    test('separates 2, 6, and 10 equivalent sets meaningfully', () {
      final two = loadOnlyPressure(2);
      final six = loadOnlyPressure(6);
      final ten = loadOnlyPressure(10);

      expect(six - two, greaterThan(20));
      expect(ten - six, greaterThan(10));
      expect(two, lessThan(30));
    });

    test('recovery pressure decreases as time passes', () {
      final freshSession = pressure(equivalentSets: 6, hours: 0);
      final olderSession = pressure(equivalentSets: 6, hours: 48);
      final staleSession = pressure(equivalentSets: 6, hours: 120);

      expect(freshSession, greaterThan(olderSession));
      expect(olderSession, greaterThan(staleSession));
    });

    test('uses parity-safe defaults in recovery pressure score', () {
      final score = RecoveryDomainService.recoveryPressureScore(const {});
      expect(score, 0);
    });

    test('hides brachialis muscle only', () {
      expect(RecoveryDomainService.shouldHideMuscle('brachialis'), isTrue);
      expect(RecoveryDomainService.shouldHideMuscle(' Brachialis '), isTrue);
      expect(RecoveryDomainService.shouldHideMuscle('chest'), isFalse);
    });
  });
}

void expectBoundary({
  required String muscleGroup,
  required double recoveringUpper,
  required double readyUpper,
  bool highSessionFatigue = false,
  double lastEquivalentSets =
      RecoveryDomainService.minimumSignificantEquivalentSets,
}) {
  expect(
    RecoveryDomainService.muscleState(
      hoursSinceLastSignificantLoad: recoveringUpper - 0.1,
      highSessionFatigue: highSessionFatigue,
      muscleGroup: muscleGroup,
      lastEquivalentSets: lastEquivalentSets,
    ),
    RecoveryDomainService.stateRecovering,
  );
  expect(
    RecoveryDomainService.muscleState(
      hoursSinceLastSignificantLoad: recoveringUpper,
      highSessionFatigue: highSessionFatigue,
      muscleGroup: muscleGroup,
      lastEquivalentSets: lastEquivalentSets,
    ),
    RecoveryDomainService.stateRecovering,
  );
  expect(
    RecoveryDomainService.muscleState(
      hoursSinceLastSignificantLoad: recoveringUpper + 0.1,
      highSessionFatigue: highSessionFatigue,
      muscleGroup: muscleGroup,
      lastEquivalentSets: lastEquivalentSets,
    ),
    RecoveryDomainService.stateReady,
  );
  expect(
    RecoveryDomainService.muscleState(
      hoursSinceLastSignificantLoad: readyUpper,
      highSessionFatigue: highSessionFatigue,
      muscleGroup: muscleGroup,
      lastEquivalentSets: lastEquivalentSets,
    ),
    RecoveryDomainService.stateReady,
  );
  expect(
    RecoveryDomainService.muscleState(
      hoursSinceLastSignificantLoad: readyUpper + 0.1,
      highSessionFatigue: highSessionFatigue,
      muscleGroup: muscleGroup,
      lastEquivalentSets: lastEquivalentSets,
    ),
    RecoveryDomainService.stateFresh,
  );
}

double loadOnlyPressure(double equivalentSets) {
  return pressure(equivalentSets: equivalentSets, hours: 999);
}

double pressure({
  required double equivalentSets,
  required double hours,
  bool highSessionFatigue = false,
}) {
  return RecoveryDomainService.recoveryPressureScore({
    'lastEquivalentSets': equivalentSets,
    'hoursSinceLastSignificantLoad': hours,
    'highSessionFatigue': highSessionFatigue,
  });
}
