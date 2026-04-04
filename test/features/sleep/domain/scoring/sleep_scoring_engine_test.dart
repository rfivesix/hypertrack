import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/domain/scoring/sleep_scoring_engine.dart';

void main() {
  group('component scoring v2', () {
    test('duration keeps broad 7h-9h plateau', () {
      expect(scoreDurationV2(420), 100); // 7.0h
      expect(scoreDurationV2(480), 100); // 8.0h
      expect(scoreDurationV2(540), 100); // 9.0h
    });

    test('duration is clearly worse below 7h', () {
      expect(scoreDurationV2(390), closeTo(80, 0.01)); // 6.5h
      expect(scoreDurationV2(375), closeTo(65, 0.01)); // 6.25h
      expect(scoreDurationV2(360), closeTo(50, 0.01)); // 6.0h
    });

    test('duration strongly penalizes below 6h', () {
      expect(scoreDurationV2(355), closeTo(45, 0.01)); // 5h55m
      expect(scoreDurationV2(330), closeTo(20, 0.01)); // 5.5h
      expect(scoreDurationV2(300), closeTo(5, 0.01)); // 5.0h
      expect(scoreDurationV2(240), 0); // 4.0h
    });

    test('duration applies milder long-sleep penalty', () {
      expect(scoreDurationV2(570), closeTo(95, 0.01)); // 9.5h
      expect(scoreDurationV2(630), closeTo(80, 0.01)); // 10.5h
      expect(scoreDurationV2(690), 50); // > 11h clamp
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
        const SleepScoringInput(sleepEfficiencyPct: 90, wasoMinutes: null),
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
      expect(result.completeness, closeTo(0.75, 0.0001));
      expect(result.regularityUsed, isFalse);
    });

    test('returns unavailable when no top-level components are available', () {
      final result = calculateSleepScore(const SleepScoringInput());
      expect(result.score, isNull);
      expect(result.state, SleepScoreState.unavailable);
      expect(result.completeness, 0);
    });

    test(
      'regularity thresholds: <5 unavailable, 5-6 available, >=7 stable',
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
        expect(available.completeness, closeTo(0.25, 0.0001));

        final stable = calculateSleepScore(
          const SleepScoringInput(regularitySri: 82, regularityValidDays: 7),
        );
        expect(stable.regularityUsed, isTrue);
        expect(stable.regularityStable, isTrue);
        expect(stable.score, closeTo(82, 0.01));
        expect(stable.completeness, closeTo(0.25, 0.0001));
      },
    );

    test('~5h56m night scores meaningfully lower than legacy v1 profile', () {
      const input = SleepScoringInput(
        durationMinutes: 356, // 5h56m
        sleepEfficiencyPct: 95,
        wasoMinutes: 20,
        regularitySri: 90,
        regularityValidDays: 7,
      );
      final v2 = calculateSleepScore(input);
      expect(v2.score, isNotNull);
      expect(v2.score!, lessThan(80));

      final v1Duration = _legacyDurationV1(input.durationMinutes!);
      final v1Score = (0.35 * v1Duration) + (0.35 * 100) + (0.30 * 90);
      expect(v1Score, greaterThan(80));
      expect(v2.score!, lessThan(v1Score - 5));
    });
  });
}

double _legacyDurationV1(int durationMinutes) {
  final hours = durationMinutes / 60.0;
  if (hours < 4.0) return 0;
  if (hours < 5.0) return _legacyLinear(hours, 4.0, 5.0, 0, 30);
  if (hours < 6.0) return _legacyLinear(hours, 5.0, 6.0, 30, 70);
  if (hours < 7.0) return _legacyLinear(hours, 6.0, 7.0, 70, 100);
  if (hours <= 9.0) return 100;
  if (hours <= 10.0) return _legacyLinear(hours, 9.0, 10.0, 100, 85);
  if (hours <= 11.0) return _legacyLinear(hours, 10.0, 11.0, 85, 60);
  return 60;
}

double _legacyLinear(double x, double x0, double x1, double y0, double y1) {
  if (x <= x0) return y0;
  if (x >= x1) return y1;
  final t = (x - x0) / (x1 - x0);
  return y0 + (y1 - y0) * t;
}
