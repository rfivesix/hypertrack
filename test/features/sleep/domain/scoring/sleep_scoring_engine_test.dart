import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/sleep/domain/scoring/sleep_scoring_engine.dart';

void main() {
  group('SHS v3 Component Scoring', () {
    test('duration (D)', () {
      expect(scoreDurationV3(420), 1.0); // 7.0h
      expect(scoreDurationV3(480), 1.0); // 8.0h
      expect(scoreDurationV3(540), 1.0); // 9.0h
      
      expect(scoreDurationV3(360), closeTo(0.6, 0.01)); // 6h -> exp(-1/2) = 0.606
      expect(scoreDurationV3(240), 0.0); // 4h (<5h clips to 0)
    });

    test('sleep efficiency (C_SE)', () {
      expect(scoreSleepEfficiencyV3(90), 0.5); // 1 / (1 + exp(0)) = 0.5
      expect(scoreSleepEfficiencyV3(100), closeTo(0.99, 0.01));
      expect(scoreSleepEfficiencyV3(80), closeTo(0.006, 0.01));
    });

    test('waso (C_WASO)', () {
      expect(scoreWasoV3(20), 1.0);
      expect(scoreWasoV3(50), 0.5); // (30/30)^2 = 1 -> 1/2 = 0.5
    });

    test('architecture (A)', () {
      // 1. Penalized light sleep: > 60% (e.g., 70% light sleep)
      final penalized = scoreArchitectureV3(
        durationMinutes: 480, // 8h
        lightSleepPct: 70,
        deepSleepPct: 20, // 96min deep -> ~1.0 aN3
        remSleepPct: 25, // 120min rem -> ~1.0 aRem
      );
      expect(penalized, isNotNull);
      // P_N1 = exp(-(70-60)^2 / 200) = exp(-100/200) = exp(-0.5) = 0.606
      // aN3 = 1.0 * exp(-(96-90)^2 / 3200) = 1.0 * exp(-36/3200) = 0.988
      // aRem = 1.0 * exp(-(120-100)^2 / 3200) = 1.0 * exp(-400/3200) = 0.882
      // Score = (0.45 * 0.988 + 0.45 * 0.882) * 0.606 + 0.10 = 0.8415 * 0.606 + 0.1 = 0.61
      expect(penalized!, closeTo(0.61, 0.05));

      // 2. Healthy light sleep: <= 60% (e.g., 44% light sleep) should NOT be penalized (P_N1 = 1.0)
      final healthy = scoreArchitectureV3(
        durationMinutes: 480, // 8h
        lightSleepPct: 44,
        deepSleepPct: 20, // 96min deep -> ~1.0 aN3
        remSleepPct: 25, // 120min rem -> ~1.0 aRem
      );
      expect(healthy, isNotNull);
      // P_N1 = 1.0 (no penalty)
      // Score = (0.45 * 0.988 + 0.45 * 0.882) * 1.0 + 0.10 = 0.8415 * 1.0 + 0.1 = 0.9415
      expect(healthy!, closeTo(0.94, 0.05));
    });

    test('timing (T_circ)', () {
      expect(scoreTimingV3(3.5, 0), 1.0); // Mid-sleep 3.5
      expect(scoreTimingV3(23.5, 480), 1.0); // Onset 23.5 -> MS = 23.5 + 4 = 27.5 -> 3.5. Score = 1.0
      
      final late = scoreTimingV3(3.0, 480); // Onset 03:00 -> MS 07:00 (7.0). MS > 5.5, triggers penalty.
      expect(late, lessThan(0.5));
    });

    test('regularity (R)', () {
      expect(scoreRegularityV3(0.0), 1.0);
      expect(scoreRegularityV3(1.0), 0.5);
      expect(scoreRegularityV3(2.0), 0.2); // 1 / (1 + 4) = 0.2
    });
  });

  group('SHS v3 Soft Caps', () {
    test('TST 4h (Pathological short sleep degradation)', () {
      final res = calculateSleepScore(const SleepScoringInput(
        durationMinutes: 240, // 4h
        sleepEfficiencyPct: 95,
        wasoMinutes: 10,
      ));
      // Base score topLevel ~ 38.48. dynamicMultiplier = 0.50. Score = 19.24.
      expect(res.score, closeTo(19.24, 1.0));
      expect(res.stageScoreCap, closeTo(19.24, 1.0));
      expect(res.dynamicMultiplier, closeTo(0.50, 0.01));
      expect(res.multiplierBottleneck, 'tst');
    });

    test('TST 5.5h (Suboptimal duration degradation)', () {
      final res = calculateSleepScore(const SleepScoringInput(
        durationMinutes: 330, // 5.5h (< 6.5h)
        sleepEfficiencyPct: 95,
        wasoMinutes: 10,
        deepSleepPct: 25,
        remSleepPct: 25,
        sleepOnsetHourLocal: 23.0,
      ));
      // Base score topLevel ~ 59.21. dynamicMultiplier = 0.6667. Score = 39.47.
      expect(res.score, closeTo(39.47, 1.0));
      expect(res.stageScoreCap, closeTo(39.47, 1.0));
      expect(res.dynamicMultiplier, closeTo(0.6667, 0.001));
      expect(res.multiplierBottleneck, 'tst');
    });
    
    test('Late timing MS = 7.0 (Circadian phase delay degradation)', () {
      final res = calculateSleepScore(const SleepScoringInput(
        durationMinutes: 480, // 8h
        sleepEfficiencyPct: 95,
        wasoMinutes: 10,
        deepSleepPct: 25,
        remSleepPct: 25,
        sleepOnsetHourLocal: 3.0, // MS = 7.0 > 5.5
      ));
      // Base score topLevel ~ 77.96. dynamicMultiplier = 0.6625. Score = 51.65.
      expect(res.score, closeTo(51.65, 1.0));
      expect(res.stageScoreCap, closeTo(51.65, 1.0));
      expect(res.dynamicMultiplier, closeTo(0.6625, 0.001));
      expect(res.multiplierBottleneck, 'timing');
    });

    test('Excellent sleep (no caps)', () {
      final res = calculateSleepScore(const SleepScoringInput(
        durationMinutes: 450, // 7.5h
        sleepEfficiencyPct: 95,
        wasoMinutes: 10,
        deepSleepPct: 20,
        remSleepPct: 25,
        lightSleepPct: 5,
        sleepOnsetHourLocal: 23.5, // MS = 3.25
      ));
      expect(res.stageScoreCap, isNull);
      expect(res.score, greaterThan(80.0));
      expect(res.state, SleepScoreState.good);
      expect(res.dynamicMultiplier, 1.0);
      expect(res.multiplierBottleneck, isNull);
    });

    test('REM sleep penalty bottleneck', () {
      final res = calculateSleepScore(const SleepScoringInput(
        durationMinutes: 480, // 8h
        sleepEfficiencyPct: 95,
        wasoMinutes: 10,
        deepSleepPct: 25,
        remSleepPct: 5, // REM = 24 minutes (< 40 min -> max penalty 0.65)
        sleepOnsetHourLocal: 23.0,
      ));
      expect(res.dynamicMultiplier, closeTo(0.65, 0.01));
      expect(res.multiplierBottleneck, 'rem');
    });

    test('N3 sleep penalty bottleneck', () {
      final res = calculateSleepScore(const SleepScoringInput(
        durationMinutes: 480, // 8h
        sleepEfficiencyPct: 95,
        wasoMinutes: 10,
        deepSleepPct: 5, // N3 = 24 minutes (< 40 min -> max penalty 0.60)
        remSleepPct: 25,
        sleepOnsetHourLocal: 23.0,
      ));
      expect(res.dynamicMultiplier, closeTo(0.60, 0.01));
      expect(res.multiplierBottleneck, 'n3');
    });
  });
}
