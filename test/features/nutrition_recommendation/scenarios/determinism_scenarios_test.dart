import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';

import 'scenario_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive nutrition determinism scenarios', () {
    test('same multi-week scenario run twice yields identical outputs/state',
        () async {
      final firstRun = await _runDeterministicScenario();
      final secondRun = await _runDeterministicScenario();

      expect(firstRun.length, secondRun.length);
      expect(
          encodeDeterministicRun(firstRun), encodeDeterministicRun(secondRun));

      for (var i = 0; i < firstRun.length; i++) {
        final first = firstRun[i];
        final second = secondRun[i];

        expect(first.dueWeekKey, second.dueWeekKey);
        expect(first.recommendation.toJson(), second.recommendation.toJson());
        expect(first.recursiveState.toJson(), second.recursiveState.toJson());
        expect(first.maintenanceEstimate.debugInfo,
            second.maintenanceEstimate.debugInfo);
      }
    });
  });
}

Future<List<WeekScenarioOutput>> _runDeterministicScenario() async {
  const weekCount = 12;
  final firstDueWeek = DateTime(2026, 2, 2);
  final historyStart = firstDueWeek.subtract(const Duration(days: 35));
  final historyDays = 35 + (weekCount * 7);

  final harness = await AdaptiveScenarioHarness.create();
  try {
    await harness.seedDailyHistory(
      startDay: historyStart,
      dayCount: historyDays,
      startWeightKg: 86,
      weeklyWeightChangeKg: -0.38,
      averageIntakeCalories: 2320,
    );
    await harness.setGoalForDay(
      goal: BodyweightGoal.loseWeight,
      targetRateKgPerWeek: -0.5,
      day: firstDueWeek,
    );

    final weeks = await harness.runDueWeekSeries(
      firstDueWeekStart: firstDueWeek,
      weekCount: weekCount,
    );
    expectDueWeekAnchorsStable(weeks, firstDueWeekStart: firstDueWeek);
    return weeks;
  } finally {
    await harness.dispose();
  }
}
