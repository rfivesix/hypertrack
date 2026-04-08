import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/adaptive_diet_phase.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';

import 'scenario_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive nutrition phase transition scenarios', () {
    test('cut -> maintain -> cut requires 7 consecutive confirmation days',
        () async {
      final harness = await AdaptiveScenarioHarness.create();
      addTearDown(harness.dispose);

      final cutStart = DateTime(2026, 1, 5);
      await harness.setGoalForDay(
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -0.5,
        day: cutStart,
      );

      var state = await harness.repository.getDietPhaseTrackingState();
      expect(state, isNotNull);
      expect(state!.confirmedPhase, AdaptiveDietPhase.cut);
      expect(state.confirmedPhaseStartDay, cutStart);
      expect(state.pendingPhase, isNull);

      final maintainSwitchDay = DateTime(2026, 1, 12);
      await harness.setGoalForDay(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        day: maintainSwitchDay,
      );

      state = await harness.repository.getDietPhaseTrackingState();
      expect(state, isNotNull);
      expect(state!.confirmedPhase, AdaptiveDietPhase.cut);
      expect(state.pendingPhase, AdaptiveDietPhase.maintain);
      expect(state.pendingPhaseFirstSeenDay, maintainSwitchDay);

      for (var offset = 1; offset <= 5; offset++) {
        await harness.setGoalForDay(
          goal: BodyweightGoal.maintainWeight,
          targetRateKgPerWeek: 0,
          day: maintainSwitchDay.add(Duration(days: offset)),
        );
      }

      state = await harness.repository.getDietPhaseTrackingState();
      expect(state, isNotNull);
      expect(state!.confirmedPhase, AdaptiveDietPhase.cut);
      expect(state.pendingPhase, AdaptiveDietPhase.maintain);

      final maintainConfirmationDay = DateTime(2026, 1, 18);
      await harness.setGoalForDay(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        day: maintainConfirmationDay,
      );

      state = await harness.repository.getDietPhaseTrackingState();
      expect(state, isNotNull);
      expect(state!.confirmedPhase, AdaptiveDietPhase.maintain);
      expect(state.confirmedPhaseStartDay, maintainConfirmationDay);
      expect(state.pendingPhase, isNull);
      expect(state.pendingPhaseFirstSeenDay, isNull);

      final cutReturnDay = DateTime(2026, 2, 1);
      await harness.setGoalForDay(
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -0.5,
        day: cutReturnDay,
      );

      state = await harness.repository.getDietPhaseTrackingState();
      expect(state, isNotNull);
      expect(state!.confirmedPhase, AdaptiveDietPhase.maintain);
      expect(state.pendingPhase, AdaptiveDietPhase.cut);
      expect(state.pendingPhaseFirstSeenDay, cutReturnDay);

      for (var offset = 1; offset <= 5; offset++) {
        await harness.setGoalForDay(
          goal: BodyweightGoal.loseWeight,
          targetRateKgPerWeek: -0.5,
          day: cutReturnDay.add(Duration(days: offset)),
        );
      }

      state = await harness.repository.getDietPhaseTrackingState();
      expect(state, isNotNull);
      expect(state!.confirmedPhase, AdaptiveDietPhase.maintain);
      expect(state.pendingPhase, AdaptiveDietPhase.cut);

      final cutReconfirmationDay = DateTime(2026, 2, 7);
      await harness.setGoalForDay(
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -0.5,
        day: cutReconfirmationDay,
      );

      state = await harness.repository.getDietPhaseTrackingState();
      expect(state, isNotNull);
      expect(state!.confirmedPhase, AdaptiveDietPhase.cut);
      expect(state.confirmedPhaseStartDay, cutReconfirmationDay);
      expect(state.pendingPhase, isNull);
    });

    test(
        'short accidental direction change cancels pending; target-rate-only changes do not reset phase',
        () async {
      final harness = await AdaptiveScenarioHarness.create();
      addTearDown(harness.dispose);

      final cutStart = DateTime(2026, 3, 2);
      await harness.setGoalForDay(
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -0.5,
        day: cutStart,
      );

      final initialState = await harness.repository.getDietPhaseTrackingState();
      expect(initialState, isNotNull);
      expect(initialState!.confirmedPhase, AdaptiveDietPhase.cut);
      expect(initialState.confirmedPhaseStartDay, cutStart);

      await harness.setGoalForDay(
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.25,
        day: DateTime(2026, 3, 3),
      );
      var state = await harness.repository.getDietPhaseTrackingState();
      expect(state, isNotNull);
      expect(state!.pendingPhase, AdaptiveDietPhase.bulk);

      await harness.setGoalForDay(
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -0.5,
        day: DateTime(2026, 3, 6),
      );

      state = await harness.repository.getDietPhaseTrackingState();
      expect(state, isNotNull);
      expect(state!.confirmedPhase, AdaptiveDietPhase.cut);
      expect(state.confirmedPhaseStartDay, cutStart);
      expect(state.pendingPhase, isNull);

      await harness.setGoalForDay(
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -0.25,
        day: DateTime(2026, 3, 7),
      );
      await harness.setGoalForDay(
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -1.0,
        day: DateTime(2026, 3, 8),
      );

      state = await harness.repository.getDietPhaseTrackingState();
      expect(state, isNotNull);
      expect(state!.confirmedPhase, AdaptiveDietPhase.cut);
      expect(state.confirmedPhaseStartDay, cutStart);
      expect(state.pendingPhase, isNull);

      final bulkSwitch = DateTime(2026, 3, 10);
      await harness.setGoalForDay(
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.25,
        day: bulkSwitch,
      );
      for (var offset = 1; offset <= 6; offset++) {
        await harness.setGoalForDay(
          goal: BodyweightGoal.gainWeight,
          targetRateKgPerWeek: 0.25,
          day: bulkSwitch.add(Duration(days: offset)),
        );
      }

      state = await harness.repository.getDietPhaseTrackingState();
      expect(state, isNotNull);
      expect(state!.confirmedPhase, AdaptiveDietPhase.bulk);
      expect(state.confirmedPhaseStartDay, DateTime(2026, 3, 16));
      expect(state.pendingPhase, isNull);
    });

    test('bulk -> maintain transition keeps deterministic confirmed phase age',
        () async {
      final harness = await AdaptiveScenarioHarness.create();
      addTearDown(harness.dispose);

      final firstDueWeek = DateTime(2026, 4, 20);
      final historyStart = firstDueWeek.subtract(const Duration(days: 42));
      await harness.seedDailyHistory(
        startDay: historyStart,
        dayCount: 90,
        startWeightKg: 79,
        weeklyWeightChangeKg: 0.16,
        averageIntakeCalories: 2780,
      );

      final bulkStart = DateTime(2026, 4, 6);
      await harness.setGoalForDay(
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.25,
        day: bulkStart,
      );

      final maintainSwitch = DateTime(2026, 4, 14);
      await harness.setGoalForDay(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        day: maintainSwitch,
      );

      for (var offset = 1; offset <= 5; offset++) {
        await harness.setGoalForDay(
          goal: BodyweightGoal.maintainWeight,
          targetRateKgPerWeek: 0,
          day: maintainSwitch.add(Duration(days: offset)),
        );
      }

      var state = await harness.repository.getDietPhaseTrackingState();
      expect(state, isNotNull);
      expect(state!.confirmedPhase, AdaptiveDietPhase.bulk);
      expect(state.pendingPhase, AdaptiveDietPhase.maintain);
      expect(state.pendingPhaseFirstSeenDay, maintainSwitch);

      await harness.setGoalForDay(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        day: firstDueWeek,
      );

      state = await harness.repository.getDietPhaseTrackingState();
      expect(state, isNotNull);
      expect(state!.confirmedPhase, AdaptiveDietPhase.maintain);
      expect(state.confirmedPhaseStartDay, firstDueWeek);
      expect(state.pendingPhase, isNull);

      final week1 =
          await harness.generateForDueWeek(dueWeekStart: firstDueWeek);
      final week2 = await harness.generateForDueWeek(
        dueWeekStart: firstDueWeek.add(const Duration(days: 7)),
      );

      expect(week1.debugValue('confirmedPhaseAgeDays'), 1);
      expect(week2.debugValue('confirmedPhaseAgeDays'), 8);
      expect(week1.phaseState.confirmedPhase, AdaptiveDietPhase.maintain);
      expect(week2.phaseState.confirmedPhase, AdaptiveDietPhase.maintain);
    });
  });
}
