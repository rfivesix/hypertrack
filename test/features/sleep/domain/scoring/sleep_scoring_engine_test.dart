import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/domain/scoring/sleep_scoring_engine.dart';

void main() {
  test('scores with complete data', () {
    final result = calculateSleepScore(
      const SleepScoringInput(
        durationMinutes: 450,
        sleepEfficiencyPct: 92,
        interruptionsCount: 1,
        regularityMinutes: 20,
        hrDeltaBpm: -1,
        depthScore: 75,
      ),
    );
    expect(result.score, isNotNull);
    expect(result.state, isNot(SleepScoreState.unavailable));
  });

  test('reweights when HR/depth data is missing', () {
    final result = calculateSleepScore(
      const SleepScoringInput(
        durationMinutes: 450,
        sleepEfficiencyPct: 92,
        interruptionsCount: 1,
        regularityMinutes: 20,
        hrDeltaBpm: null,
        depthScore: null,
      ),
    );
    expect(result.score, isNotNull);
    expect(result.state, isNot(SleepScoreState.unavailable));
  });
}

