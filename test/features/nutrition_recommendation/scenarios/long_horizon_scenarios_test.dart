import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/adaptive_diet_phase.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';

import 'scenario_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive nutrition long-horizon scenarios', () {
    const weekCount = 12;
    final firstDueWeek = DateTime(2026, 2, 2); // Monday
    final historyStart = firstDueWeek.subtract(const Duration(days: 35));
    final historyDays = 35 + (weekCount * 7);

    test('long clean cut remains stable and follows phase ramp', () async {
      final harness = await AdaptiveScenarioHarness.create(
        profile: ScenarioProfile(
          name: 'Clean Cut',
          birthday: DateTime(1993, 8, 1),
          heightCm: 182,
          gender: 'male',
          initialWeightKg: 92,
          bodyFatPercent: 22,
          declaredActivityLevel: PriorActivityLevel.moderate,
          extraCardioHoursOption: ExtraCardioHoursOption.h1,
          targetSteps: 9000,
        ),
      );
      addTearDown(harness.dispose);

      await harness.seedDailyHistory(
        startDay: historyStart,
        dayCount: historyDays,
        startWeightKg: 92,
        weeklyWeightChangeKg: -0.48,
        averageIntakeCalories: 2360,
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
      expectVarianceBoundedByCap(weeks);
      expectNoAbsurdMaintenanceJumps(weeks, maxJumpCalories: 560);
      expectPhaseRampProgression(weeks);

      expect(
        weeks.every(
            (week) => week.phaseState.confirmedPhase == AdaptiveDietPhase.cut),
        isTrue,
      );
      expect(
        weeks.every((week) => week.phaseState.pendingPhase == null),
        isTrue,
      );

      final earlyVariances = weeks
          .take(4)
          .map((week) => week.debugValue('posteriorVarianceCalories2'))
          .toList(growable: false);
      final lateVariances = weeks
          .skip(8)
          .map((week) => week.debugValue('posteriorVarianceCalories2'))
          .toList(growable: false);
      expect(median(lateVariances), lessThanOrEqualTo(median(earlyVariances)));

      final earlyConfidence = averageConfidenceRank(weeks.take(4).toList());
      final lateConfidence = averageConfidenceRank(weeks.skip(8).toList());
      expect(lateConfidence, greaterThanOrEqualTo(earlyConfidence));
      expect(
        weeks
            .skip(8)
            .any((week) => confidenceRank(week.recommendation.confidence) >= 2),
        isTrue,
      );
    });

    test('long clean bulk remains stable with mature phase behavior', () async {
      final harness = await AdaptiveScenarioHarness.create(
        profile: ScenarioProfile(
          name: 'Clean Bulk',
          birthday: DateTime(1998, 3, 12),
          heightCm: 176,
          gender: 'female',
          initialWeightKg: 67,
          bodyFatPercent: 19,
          declaredActivityLevel: PriorActivityLevel.high,
          extraCardioHoursOption: ExtraCardioHoursOption.h2,
          targetSteps: 9800,
        ),
      );
      addTearDown(harness.dispose);

      await harness.seedDailyHistory(
        startDay: historyStart,
        dayCount: historyDays,
        startWeightKg: 67,
        weeklyWeightChangeKg: 0.29,
        averageIntakeCalories: 2980,
      );
      await harness.setGoalForDay(
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.25,
        day: firstDueWeek,
      );

      final weeks = await harness.runDueWeekSeries(
        firstDueWeekStart: firstDueWeek,
        weekCount: weekCount,
      );

      expectDueWeekAnchorsStable(weeks, firstDueWeekStart: firstDueWeek);
      expectVarianceBoundedByCap(weeks);
      expectNoAbsurdMaintenanceJumps(weeks, maxJumpCalories: 560);
      expectPhaseRampProgression(weeks);

      expect(
        weeks.every(
            (week) => week.phaseState.confirmedPhase == AdaptiveDietPhase.bulk),
        isTrue,
      );
      expect(
        weeks.every((week) => week.phaseState.pendingPhase == null),
        isTrue,
      );

      final maxPosterior = weeks
          .map((week) => week.maintenanceEstimate.posteriorMaintenanceCalories)
          .reduce(math.max);
      final minPosterior = weeks
          .map((week) => week.maintenanceEstimate.posteriorMaintenanceCalories)
          .reduce(math.min);
      expect(maxPosterior, lessThanOrEqualTo(5000));
      expect(minPosterior, greaterThanOrEqualTo(1200));
    });

    test('long maintain converges without unnecessary phase resets', () async {
      final harness = await AdaptiveScenarioHarness.create(
        profile: ScenarioProfile(
          name: 'Clean Maintain',
          birthday: DateTime(1989, 11, 3),
          heightCm: 171,
          gender: 'female',
          initialWeightKg: 70,
          bodyFatPercent: 26,
          declaredActivityLevel: PriorActivityLevel.moderate,
          extraCardioHoursOption: ExtraCardioHoursOption.h0,
          targetSteps: 8200,
        ),
      );
      addTearDown(harness.dispose);

      await harness.seedDailyHistory(
        startDay: historyStart,
        dayCount: historyDays,
        startWeightKg: 70,
        weeklyWeightChangeKg: 0.01,
        averageIntakeCalories: 2440,
      );
      await harness.setGoalForDay(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        day: firstDueWeek,
      );

      final weeks = await harness.runDueWeekSeries(
        firstDueWeekStart: firstDueWeek,
        weekCount: weekCount,
      );

      expectDueWeekAnchorsStable(weeks, firstDueWeekStart: firstDueWeek);
      expectVarianceBoundedByCap(weeks);
      expectNoAbsurdMaintenanceJumps(weeks, maxJumpCalories: 460);

      expect(
        weeks.every((week) =>
            week.phaseState.confirmedPhase == AdaptiveDietPhase.maintain),
        isTrue,
      );
      expect(
        weeks.every(
            (week) => week.phaseState.confirmedPhaseStartDay == firstDueWeek),
        isTrue,
      );
      expect(
        weeks.every((week) => week.phaseState.pendingPhase == null),
        isTrue,
      );

      final firstVariance =
          weeks.first.debugValue('posteriorVarianceCalories2');
      final lastVariance = weeks.last.debugValue('posteriorVarianceCalories2');
      expect(lastVariance, lessThanOrEqualTo(firstVariance * 1.20));

      final trailingCalories = weeks
          .skip(8)
          .map((week) => week.recommendation.recommendedCalories)
          .toList(growable: false);
      final trailingRange =
          trailingCalories.reduce(math.max) - trailingCalories.reduce(math.min);
      expect(trailingRange, lessThanOrEqualTo(240));

      expect(
        weeks
            .skip(8)
            .any((week) => confidenceRank(week.recommendation.confidence) >= 2),
        isTrue,
      );
    });

    final sparseScenarios = <_SparseScenarioSpec>[
      _SparseScenarioSpec(
        name: 'sparse weight logs only',
        shouldLogWeight: (dayIndex) => dayIndex % 14 == 0,
        shouldLogIntake: (dayIndex) => true,
        expectedInputFlags: const <String>{'sparse_weight_logs'},
        expectPredictionOnlyWeeks: true,
      ),
      _SparseScenarioSpec(
        name: 'sparse intake logs only',
        shouldLogWeight: (dayIndex) => true,
        shouldLogIntake: (dayIndex) => dayIndex % 7 == 0,
        expectedInputFlags: const <String>{'sparse_intake_logs'},
        expectPredictionOnlyWeeks: false,
      ),
      _SparseScenarioSpec(
        name: 'both sparse weight and intake logs',
        shouldLogWeight: (dayIndex) => dayIndex % 14 == 0,
        shouldLogIntake: (dayIndex) => dayIndex % 7 == 0,
        expectedInputFlags: const <String>{
          'sparse_weight_logs',
          'sparse_intake_logs',
        },
        expectPredictionOnlyWeeks: true,
      ),
      _SparseScenarioSpec(
        name: '2-4 week no-log gap',
        shouldLogWeight: (dayIndex) => true,
        shouldLogIntake: (dayIndex) => true,
        expectedInputFlags: const <String>{
          'sparse_weight_logs',
          'sparse_intake_logs',
          'weight_trend_unavailable',
        },
        expectPredictionOnlyWeeks: true,
        noLogGap: _NoLogGap(startOffsetDays: 56, lengthDays: 28),
      ),
    ];

    for (final scenario in sparseScenarios) {
      test('sparse logging: ${scenario.name}', () async {
        final harness = await AdaptiveScenarioHarness.create();
        addTearDown(harness.dispose);

        final blockedDays =
            scenario.noLogGap?.expand(historyStart) ?? <DateTime>{};

        await harness.seedDailyHistory(
          startDay: historyStart,
          dayCount: historyDays,
          startWeightKg: 85,
          weeklyWeightChangeKg: -0.30,
          averageIntakeCalories: 2300,
          shouldLogWeight: (dayIndex, _) => scenario.shouldLogWeight(dayIndex),
          shouldLogIntake: (dayIndex, _) => scenario.shouldLogIntake(dayIndex),
          noLogDays: blockedDays,
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

        expectVarianceBoundedByCap(weeks);
        expectNoAbsurdMaintenanceJumps(weeks, maxJumpCalories: 760);

        final allInputFlags = weeks
            .expand((week) => week.recommendation.inputSummary.qualityFlags)
            .toSet();
        for (final expected in scenario.expectedInputFlags) {
          expect(allInputFlags, contains(expected));
        }

        final lowOrNotEnoughWeeks = weeks
            .where(
                (week) => confidenceRank(week.recommendation.confidence) <= 1)
            .length;
        expect(lowOrNotEnoughWeeks, greaterThanOrEqualTo(4));

        final predictionOnlyWeeks = weeks
            .where(
              (week) => week.maintenanceEstimate.qualityFlags
                  .contains('bayesian_prediction_only_no_observation'),
            )
            .toList(growable: false);

        if (scenario.expectPredictionOnlyWeeks) {
          expect(predictionOnlyWeeks, isNotEmpty);
          expect(
            predictionOnlyWeeks.every(
              (week) =>
                  week.recommendation.confidence ==
                  RecommendationConfidence.notEnoughData,
            ),
            isTrue,
          );

          final firstPredictionWeek = predictionOnlyWeeks.first;
          final index = weeks.indexOf(firstPredictionWeek);
          if (index > 0) {
            final previousVariance =
                weeks[index - 1].debugValue('posteriorVarianceCalories2');
            final predictionVariance =
                firstPredictionWeek.debugValue('posteriorVarianceCalories2');
            expect(predictionVariance, greaterThanOrEqualTo(previousVariance));
          }
        } else {
          expect(predictionOnlyWeeks, isEmpty);
        }
      });
    }

    test('same-week force refresh remains deterministic and due-week anchored',
        () async {
      final harness = await AdaptiveScenarioHarness.create();
      addTearDown(harness.dispose);

      await harness.seedDailyHistory(
        startDay: historyStart,
        dayCount: historyDays,
        startWeightKg: 88,
        weeklyWeightChangeKg: -0.40,
        averageIntakeCalories: 2320,
      );
      await harness.setGoalForDay(
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -0.5,
        day: firstDueWeek,
      );

      final replay = await harness.generateAndReplaySameDueWeek(
        dueWeekStart: firstDueWeek,
        onBeforeReplay: () async {
          final inWeekDay = firstDueWeek.add(const Duration(days: 2));
          await harness.logWeight(day: inWeekDay, weightKg: 63);
          await harness.logIntakeCalories(day: inWeekDay, calories: 4300);
        },
      );

      expect(replay.initial.dueWeekKey, replay.replay.dueWeekKey);
      expect(replay.initial.dueWeekKey, dueWeekKeyFor(firstDueWeek));
      expect(replay.replay.recommendation.windowEnd,
          replay.initial.recommendation.windowEnd);
      expect(
        replay.replay.recommendation.estimatedMaintenanceCalories,
        replay.initial.recommendation.estimatedMaintenanceCalories,
      );
      expect(
        replay.replay.recommendation.recommendedCalories,
        replay.initial.recommendation.recommendedCalories,
      );
      expect(
        replay.replay.recursiveState.toJson(),
        replay.initial.recursiveState.toJson(),
      );
    });
  });
}

class _SparseScenarioSpec {
  final String name;
  final bool Function(int dayIndex) shouldLogWeight;
  final bool Function(int dayIndex) shouldLogIntake;
  final Set<String> expectedInputFlags;
  final bool expectPredictionOnlyWeeks;
  final _NoLogGap? noLogGap;

  const _SparseScenarioSpec({
    required this.name,
    required this.shouldLogWeight,
    required this.shouldLogIntake,
    required this.expectedInputFlags,
    required this.expectPredictionOnlyWeeks,
    this.noLogGap,
  });
}

class _NoLogGap {
  final int startOffsetDays;
  final int lengthDays;

  const _NoLogGap({
    required this.startOffsetDays,
    required this.lengthDays,
  });

  Set<DateTime> expand(DateTime historyStart) {
    return List<DateTime>.generate(
      lengthDays,
      (index) => normalizeDay(
        historyStart.add(Duration(days: startOffsetDays + index)),
      ),
      growable: false,
    ).toSet();
  }
}
