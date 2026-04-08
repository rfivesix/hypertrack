import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/adaptive_diet_phase.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';

import '../scenario_test_harness.dart';
import '../support/scenario_metrics.dart';
import '../support/synthetic_truth_simulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive nutrition ground-truth simulation scenarios', () {
    test('posterior approaches latent truth under clean maintain data',
        () async {
      final scenario = SyntheticTruthScenario(
        name: 'clean_maintain_truth',
        profile: ScenarioProfile.defaultProfile(),
        firstDueWeekStart: DateTime(2026, 3, 2),
        weekCount: 12,
        warmupDays: 35,
        initialWeightKg: 82,
        initialTrueMaintenanceCalories: 2620,
        weeklyMaintenanceDriftCalories: 0,
        goalTimeline: const <GoalPhaseSegment>[
          GoalPhaseSegment(
            dayOffset: 0,
            goal: BodyweightGoal.maintainWeight,
            targetRateKgPerWeek: 0,
          ),
        ],
        intakeNoisePatternCalories: const <int>[0, 12, -10, 8, -9, 14, -7],
        weightNoisePatternKg: const <double>[
          0.0,
          0.02,
          -0.01,
          0.015,
          -0.01,
          0.01,
          -0.005
        ],
      );

      final weeks = await runSyntheticTruthScenario(scenario);
      final model = modelWeeks(weeks);

      final errors = posteriorAbsoluteErrorSeries(weeks);
      final week4 = milestoneAtWeek(weeks, weekIndex: 3);
      final week8 = milestoneAtWeek(weeks, weekIndex: 7);
      final week12 = milestoneAtWeek(weeks, weekIndex: 11);
      final earlyErrorMedian = median(errors.take(4).toList(growable: false));
      final lateErrorMedian = medianAbsoluteError(weeks, startWeek: 8);
      final settlingWeek =
          settlingWeekIndex(weeks, toleranceCalories: 300, startWeek: 2);
      final halfLifeWeek = errorHalfLifeWeekIndex(weeks);

      expect(errors.last, lessThanOrEqualTo(errors.first));
      expect(week8.absoluteErrorCalories,
          lessThanOrEqualTo(week4.absoluteErrorCalories));
      expect(
        week12.absoluteErrorCalories,
        lessThanOrEqualTo(week4.absoluteErrorCalories),
      );
      expect(errorImprovementRatio(weeks, weekIndex: 7),
          greaterThanOrEqualTo(0.20));
      expect(errorImprovementRatio(weeks, weekIndex: 11),
          greaterThanOrEqualTo(0.30));
      expect(lateErrorMedian, lessThanOrEqualTo(earlyErrorMedian));
      expect(didConvergeByWeek(weeks, weekIndex: 7, maxAbsErrorCalories: 340),
          isTrue);
      expect(settlingWeek, isNotNull);
      expect(settlingWeek!, lessThanOrEqualTo(10));
      expect(halfLifeWeek, isNotNull);
      expect(halfLifeWeek!, lessThanOrEqualTo(9));

      final earlyVariance = medianPosteriorVariance(weeks, startWeek: 0);
      final lateVariance = medianPosteriorVariance(weeks, startWeek: 8);
      expect(lateVariance, lessThanOrEqualTo(earlyVariance));

      final earlyConfidence = averageConfidenceScore(weeks, startWeek: 0);
      final lateConfidence = averageConfidenceScore(weeks, startWeek: 8);
      expect(lateConfidence, greaterThanOrEqualTo(earlyConfidence));

      expectVarianceBoundedByCap(model);
      expectNoAbsurdMaintenanceJumps(model, maxJumpCalories: 500);
    });

    test('adaptation speed is neither stuck nor unrealistically instant',
        () async {
      final scenario = SyntheticTruthScenario(
        name: 'speed_reasonable_wrong_prior',
        profile: ScenarioProfile(
          name: 'Likely low-prior profile',
          birthday: DateTime(1998, 7, 1),
          heightCm: 161,
          gender: 'female',
          initialWeightKg: 57,
          bodyFatPercent: 24,
          declaredActivityLevel: PriorActivityLevel.low,
          extraCardioHoursOption: ExtraCardioHoursOption.h0,
          targetSteps: 4500,
        ),
        firstDueWeekStart: DateTime(2026, 4, 6),
        weekCount: 12,
        warmupDays: 7,
        initialWeightKg: 57,
        initialTrueMaintenanceCalories: 2740,
        weeklyMaintenanceDriftCalories: 0,
        goalTimeline: const <GoalPhaseSegment>[
          GoalPhaseSegment(
            dayOffset: 0,
            goal: BodyweightGoal.maintainWeight,
            targetRateKgPerWeek: 0,
          ),
        ],
        intakeNoisePatternCalories: const <int>[0, 30, -20, 26, -25, 18, -10],
        weightNoisePatternKg: const <double>[
          0.0,
          0.04,
          -0.03,
          0.05,
          -0.02,
          0.02,
          -0.01
        ],
      );

      final weeks = await runSyntheticTruthScenario(scenario);
      final errors = posteriorAbsoluteErrorSeries(weeks);
      final initial = initialAbsoluteError(weeks);
      final week4Error = absoluteErrorAtWeek(weeks, 3);
      final week8Error = absoluteErrorAtWeek(weeks, 7);
      final halfLifeWeek = errorHalfLifeWeekIndex(weeks);
      final settlingWeek =
          settlingWeekIndex(weeks, toleranceCalories: 420, startWeek: 2);

      expect(errors[3], lessThan(errors[0]));
      expect(week4Error, lessThan(initial));
      expect(week8Error, lessThanOrEqualTo(week4Error));
      expect(didConvergeByWeek(weeks, weekIndex: 3, maxAbsErrorCalories: 620),
          isTrue);
      expect(didConvergeByWeek(weeks, weekIndex: 7, maxAbsErrorCalories: 380),
          isTrue);

      // Guardrails: avoid teleporting to truth in one update, but also avoid
      // staying frozen near prior.
      final week0To1Delta = (weeks[1]
                  .model
                  .maintenanceEstimate
                  .posteriorMaintenanceCalories -
              weeks[0].model.maintenanceEstimate.posteriorMaintenanceCalories)
          .abs();
      expect(week0To1Delta, lessThanOrEqualTo(850));
      final week1ImprovementRatio = errorImprovementRatio(weeks, weekIndex: 1);
      expect(week1ImprovementRatio, lessThanOrEqualTo(0.90));
      expect(week1ImprovementRatio, greaterThanOrEqualTo(0.05));

      final week0To8ErrorImprovement = errors[0] - errors[8];
      expect(week0To8ErrorImprovement, greaterThanOrEqualTo(60));
      expect(halfLifeWeek, isNotNull);
      expect(halfLifeWeek!, lessThanOrEqualTo(9));
      expect(settlingWeek, isNotNull);
      expect(settlingWeek!, lessThanOrEqualTo(10));
    });

    test(
        'wrong-prior convergence remains bounded without oscillatory overshoot',
        () async {
      final scenario = SyntheticTruthScenario(
        name: 'overshoot_bounded',
        profile: ScenarioProfile(
          name: 'Likely high-prior profile',
          birthday: DateTime(1988, 9, 2),
          heightCm: 189,
          gender: 'male',
          initialWeightKg: 116,
          bodyFatPercent: 33,
          declaredActivityLevel: PriorActivityLevel.veryHigh,
          extraCardioHoursOption: ExtraCardioHoursOption.h5,
          targetSteps: 14500,
        ),
        firstDueWeekStart: DateTime(2026, 5, 4),
        weekCount: 12,
        warmupDays: 7,
        initialWeightKg: 116,
        initialTrueMaintenanceCalories: 2280,
        weeklyMaintenanceDriftCalories: 0,
        goalTimeline: const <GoalPhaseSegment>[
          GoalPhaseSegment(
            dayOffset: 0,
            goal: BodyweightGoal.maintainWeight,
            targetRateKgPerWeek: 0,
          ),
        ],
      );

      final weeks = await runSyntheticTruthScenario(scenario);
      final settlingWeek =
          settlingWeekIndex(weeks, toleranceCalories: 340, startWeek: 2);
      final halfLifeWeek = errorHalfLifeWeekIndex(weeks);

      expect(didConvergeByWeek(weeks, weekIndex: 9, maxAbsErrorCalories: 360),
          isTrue);
      expect(maxOvershootCalories(weeks, startWeek: 4), lessThanOrEqualTo(420));
      expect(
          maxUndershootCalories(weeks, startWeek: 4), lessThanOrEqualTo(420));
      expect(countTruthCrossings(weeks, deadbandCalories: 70),
          lessThanOrEqualTo(3));
      expect(maxAbsoluteWeeklyDelta(weeks, startDeltaIndex: 1),
          lessThanOrEqualTo(560));
      expect(settlingWeek, isNotNull);
      expect(settlingWeek!, lessThanOrEqualTo(10));
      expect(halfLifeWeek, isNotNull);
      expect(halfLifeWeek!, lessThanOrEqualTo(9));
    });

    test(
        'phase changes preserve convergence direction and deterministic ramping',
        () async {
      final scenario = SyntheticTruthScenario(
        name: 'cut_maintain_bulk_truth',
        profile: ScenarioProfile.defaultProfile(),
        firstDueWeekStart: DateTime(2026, 5, 4),
        weekCount: 12,
        warmupDays: 28,
        initialWeightKg: 84,
        initialTrueMaintenanceCalories: 2550,
        weeklyMaintenanceDriftCalories: 10,
        goalTimeline: const <GoalPhaseSegment>[
          GoalPhaseSegment(
            dayOffset: 0,
            goal: BodyweightGoal.loseWeight,
            targetRateKgPerWeek: -0.5,
          ),
          GoalPhaseSegment(
            dayOffset: 42,
            goal: BodyweightGoal.maintainWeight,
            targetRateKgPerWeek: 0,
          ),
          GoalPhaseSegment(
            dayOffset: 77,
            goal: BodyweightGoal.gainWeight,
            targetRateKgPerWeek: 0.25,
          ),
        ],
      );

      final weeks = await runSyntheticTruthScenario(scenario);
      final model = modelWeeks(weeks);

      expect(
          model
              .any((w) => w.phaseState.confirmedPhase == AdaptiveDietPhase.cut),
          isTrue);
      expect(
        model.any(
            (w) => w.phaseState.confirmedPhase == AdaptiveDietPhase.maintain),
        isTrue,
      );
      expect(
        model.any((w) => w.phaseState.confirmedPhase == AdaptiveDietPhase.bulk),
        isTrue,
      );

      final cutWeeks = model
          .where((w) => w.phaseState.confirmedPhase == AdaptiveDietPhase.cut)
          .map((w) => w.recommendation.recommendedCalories.toDouble())
          .toList(growable: false);
      final maintainWeeks = model
          .where(
              (w) => w.phaseState.confirmedPhase == AdaptiveDietPhase.maintain)
          .map((w) => w.recommendation.recommendedCalories.toDouble())
          .toList(growable: false);
      final bulkWeeks = model
          .where((w) => w.phaseState.confirmedPhase == AdaptiveDietPhase.bulk)
          .map((w) => w.recommendation.recommendedCalories.toDouble())
          .toList(growable: false);

      expect(cutWeeks, isNotEmpty);
      expect(maintainWeeks, isNotEmpty);
      expect(bulkWeeks, isNotEmpty);

      expect(median(maintainWeeks), greaterThan(median(cutWeeks) + 120));
      expect(median(bulkWeeks), greaterThan(median(maintainWeeks) + 90));

      final firstMaintain = model.firstWhere(
        (w) => w.phaseState.confirmedPhase == AdaptiveDietPhase.maintain,
      );
      final laterMaintain = model.lastWhere(
        (w) =>
            w.phaseState.confirmedPhase == AdaptiveDietPhase.maintain &&
            w.debugValue('confirmedPhaseAgeDays') >= 8,
        orElse: () => firstMaintain,
      );
      expect(firstMaintain.debugValue('effectiveKcalPerKg'),
          lessThanOrEqualTo(4200));
      expect(
        laterMaintain.debugValue('effectiveKcalPerKg'),
        greaterThanOrEqualTo(firstMaintain.debugValue('effectiveKcalPerKg')),
      );

      expectNoAbsurdMaintenanceJumps(model, maxJumpCalories: 620);

      // Convergence continuity check: later stage should not regress into
      // early-level absolute error despite phase changes.
      final earlyMedianError = median(
          posteriorAbsoluteErrorSeries(weeks).take(4).toList(growable: false));
      final lateMedianError = medianAbsoluteError(weeks, startWeek: 8);
      expect(lateMedianError, lessThanOrEqualTo(earlyMedianError * 1.1));
    });
  });
}
