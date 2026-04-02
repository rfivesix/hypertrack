import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/domain/scoring/sleep_scoring_engine.dart';

void main() {
  group('component scoring', () {
    test('duration piecewise mapping', () {
      expect(scoreDurationV1(210), 0); // < 4h
      expect(scoreDurationV1(270), closeTo(15, 0.01)); // 4.5h
      expect(scoreDurationV1(330), closeTo(50, 0.01)); // 5.5h
      expect(scoreDurationV1(390), closeTo(85, 0.01)); // 6.5h
      expect(scoreDurationV1(480), 100); // 8.0h
      expect(scoreDurationV1(570), closeTo(92.5, 0.01)); // 9.5h
      expect(scoreDurationV1(630), closeTo(72.5, 0.01)); // 10.5h
      expect(scoreDurationV1(690), 60); // > 11h clamp
    });

    test('sleep-efficiency piecewise mapping', () {
      expect(scoreSleepEfficiencyV1(92), 100);
      expect(scoreSleepEfficiencyV1(87.5), closeTo(92.5, 0.01));
      expect(scoreSleepEfficiencyV1(82.5), closeTo(75, 0.01));
      expect(scoreSleepEfficiencyV1(75), closeTo(45, 0.01));
      expect(scoreSleepEfficiencyV1(35), closeTo(12.5, 0.01));
    });

    test('waso piecewise mapping', () {
      expect(scoreWasoV1(20), 100);
      expect(scoreWasoV1(45), closeTo(85, 0.01));
      expect(scoreWasoV1(90), closeTo(50, 0.01));
      expect(scoreWasoV1(180), closeTo(15, 0.01));
      expect(scoreWasoV1(300), 0);
    });
  });

  group('renormalization and availability', () {
    test('renormalizes continuity when only one subcomponent is available', () {
      final result = calculateSleepScore(
        const SleepScoringInput(
          sleepEfficiencyPct: 90,
          wasoMinutes: null,
        ),
      );
      expect(result.continuityScore, 100);
      expect(result.score, 100);
      expect(result.completeness, closeTo(0.35, 0.0001));
    });

    test('renormalizes top-level score when regularity is unavailable', () {
      final result = calculateSleepScore(
        const SleepScoringInput(
          durationMinutes: 420,
          sleepEfficiencyPct: 90,
          wasoMinutes: 30,
        ),
      );
      expect(result.score, 100);
      expect(result.state, SleepScoreState.good);
      expect(result.completeness, closeTo(0.70, 0.0001));
      expect(result.regularityUsed, isFalse);
    });

    test('returns unavailable when no top-level components are available', () {
      final result = calculateSleepScore(const SleepScoringInput());
      expect(result.score, isNull);
      expect(result.state, SleepScoreState.unavailable);
      expect(result.completeness, 0);
    });

    test('regularity thresholds: <5 unavailable, 5-6 available, >=7 stable',
        () {
      final noRegularity = calculateSleepScore(
        const SleepScoringInput(regularitySri: 82, regularityValidDays: 4),
      );
      expect(noRegularity.regularityUsed, isFalse);
      expect(noRegularity.regularityStable, isFalse);
      expect(noRegularity.score, isNull);

      final available = calculateSleepScore(
        const SleepScoringInput(regularitySri: 82, regularityValidDays: 5),
      );
      expect(available.regularityUsed, isTrue);
      expect(available.regularityStable, isFalse);
      expect(available.score, closeTo(82, 0.01));
      expect(available.completeness, closeTo(0.30, 0.0001));

      final stable = calculateSleepScore(
        const SleepScoringInput(regularitySri: 82, regularityValidDays: 7),
      );
      expect(stable.regularityUsed, isTrue);
      expect(stable.regularityStable, isTrue);
      expect(stable.score, closeTo(82, 0.01));
      expect(stable.completeness, closeTo(0.30, 0.0001));
    });
  });
}
