import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';

import '../scenario_test_harness.dart';
import '../support/scenario_metrics.dart';
import '../support/synthetic_truth_simulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive nutrition chaotic realistic scenarios', () {
    test('weekend intake spikes remain stable without confidence collapse',
        () async {
      final scenario = SyntheticTruthScenario(
        name: 'weekend_spikes',
        profile: ScenarioProfile.defaultProfile(),
        firstDueWeekStart: DateTime(2026, 2, 2),
        weekCount: 11,
        warmupDays: 35,
        initialWeightKg: 83,
        initialTrueMaintenanceCalories: 2620,
        weeklyMaintenanceDriftCalories: 4,
        goalTimeline: const <GoalPhaseSegment>[
          GoalPhaseSegment(
            dayOffset: 0,
            goal: BodyweightGoal.maintainWeight,
            targetRateKgPerWeek: 0,
          ),
        ],
        intakeForDay: (ctx) {
          final dayBias = ctx.isWeekend ? 420 : -120;
          return ctx.trueMaintenanceCalories + dayBias;
        },
        waterOffsetKgForDay: (ctx) {
          if (ctx.day.weekday == DateTime.monday) {
            return 0.20;
          }
          return 0.0;
        },
      );

      final weeks = await runSyntheticTruthScenario(scenario);
      final model = modelWeeks(weeks);
      final trailingSignedErrorMedian = median(
        posteriorSignedErrorSeries(weeks).skip(7).toList(growable: false),
      );

      final trailingPosterior = model
          .skip(7)
          .map((week) => week.maintenanceEstimate.posteriorMaintenanceCalories)
          .toList(growable: false);
      final trailingRange = trailingPosterior.reduce(math.max) -
          trailingPosterior.reduce(math.min);

      expectNoAbsurdMaintenanceJumps(model, maxJumpCalories: 420);
      expect(trailingRange, lessThanOrEqualTo(260));
      expect(averageConfidenceScore(weeks, startWeek: 7),
          greaterThanOrEqualTo(1.0));
      expect(trailingSignedErrorMedian.abs(), lessThanOrEqualTo(180));
    });

    test('short refeed block does not permanently bias posterior upward',
        () async {
      final scenario = SyntheticTruthScenario(
        name: 'refeed_block',
        profile: ScenarioProfile.defaultProfile(),
        firstDueWeekStart: DateTime(2026, 3, 2),
        weekCount: 12,
        warmupDays: 28,
        initialWeightKg: 90,
        initialTrueMaintenanceCalories: 2760,
        weeklyMaintenanceDriftCalories: 0,
        goalTimeline: const <GoalPhaseSegment>[
          GoalPhaseSegment(
            dayOffset: 0,
            goal: BodyweightGoal.loseWeight,
            targetRateKgPerWeek: -0.5,
          ),
        ],
        intakeForDay: (ctx) {
          final inRefeed = ctx.dayIndex >= 49 && ctx.dayIndex <= 55;
          final base = ctx.trueMaintenanceCalories - (0.5 * 7700 / 7.0);
          return inRefeed ? base + 700 : base;
        },
        waterOffsetKgForDay: (ctx) {
          final inRefeed = ctx.dayIndex >= 49 && ctx.dayIndex <= 55;
          return inRefeed ? 0.75 : 0.0;
        },
      );

      final weeks = await runSyntheticTruthScenario(scenario);
      final model = modelWeeks(weeks);

      final summary = summarizeRecoveryWindows(
        weeks: weeks,
        preStart: 4,
        preEnd: 6,
        eventStart: 7,
        eventEnd: 9,
        postStart: 9,
        postEnd: 12,
      );
      final recoveryWeeks = weeksUntilPosteriorRecoversToBand(
        weeks: model,
        baselineMedian: summary.preEventPosteriorMedian,
        toleranceCalories: 180,
        searchStartWeek: 9,
        sustainedWeeks: 2,
      );

      expect(
        (summary.postEventPosteriorMedian - summary.preEventPosteriorMedian)
            .abs(),
        lessThanOrEqualTo(220),
      );
      expect(
        (summary.eventPosteriorMedian - summary.preEventPosteriorMedian).abs(),
        lessThanOrEqualTo(260),
      );
      expect(
        summary.eventVarianceMedian,
        lessThanOrEqualTo(summary.preEventVarianceMedian * 1.45),
      );
      expect(
        summary.postEventVarianceMedian,
        lessThanOrEqualTo(
          math.max(
                  summary.preEventVarianceMedian, summary.eventVarianceMedian) *
              1.25,
        ),
      );
      expect(recoveryWeeks, isNotNull);
      expect(recoveryWeeks!, lessThanOrEqualTo(2));
      expectNoAbsurdMaintenanceJumps(model, maxJumpCalories: 520);
    });

    test('temporary water jump does not induce absurd maintenance shift',
        () async {
      final scenario = SyntheticTruthScenario(
        name: 'water_jump',
        profile: ScenarioProfile.defaultProfile(),
        firstDueWeekStart: DateTime(2026, 4, 6),
        weekCount: 11,
        warmupDays: 28,
        initialWeightKg: 79,
        initialTrueMaintenanceCalories: 2480,
        weeklyMaintenanceDriftCalories: 0,
        goalTimeline: const <GoalPhaseSegment>[
          GoalPhaseSegment(
            dayOffset: 0,
            goal: BodyweightGoal.maintainWeight,
            targetRateKgPerWeek: 0,
          ),
        ],
        waterOffsetKgForDay: (ctx) {
          if (ctx.dayIndex >= 45 && ctx.dayIndex <= 50) {
            return 1.35;
          }
          if (ctx.dayIndex >= 51 && ctx.dayIndex <= 54) {
            return 0.25;
          }
          return 0;
        },
      );

      final weeks = await runSyntheticTruthScenario(scenario);
      final model = modelWeeks(weeks);

      final summary = summarizeRecoveryWindows(
        weeks: weeks,
        preStart: 3,
        preEnd: 5,
        eventStart: 6,
        eventEnd: 8,
        postStart: 8,
        postEnd: 11,
      );
      final recoveryWeeks = weeksUntilPosteriorRecoversToBand(
        weeks: model,
        baselineMedian: summary.preEventPosteriorMedian,
        toleranceCalories: 170,
        searchStartWeek: 8,
        sustainedWeeks: 2,
      );

      expect(maxAbsoluteWeeklyDelta(weeks), lessThanOrEqualTo(460));
      expect(
        (summary.postEventPosteriorMedian - summary.preEventPosteriorMedian)
            .abs(),
        lessThanOrEqualTo(220),
      );
      expect(recoveryWeeks, isNotNull);
      expect(recoveryWeeks!, lessThanOrEqualTo(2));
      expectNoAbsurdMaintenanceJumps(model, maxJumpCalories: 480);
    });

    test('two-week illness period increases uncertainty then restabilizes',
        () async {
      final scenario = SyntheticTruthScenario(
        name: 'illness_two_weeks',
        profile: ScenarioProfile.defaultProfile(),
        firstDueWeekStart: DateTime(2026, 5, 4),
        weekCount: 12,
        warmupDays: 28,
        initialWeightKg: 86,
        initialTrueMaintenanceCalories: 2680,
        weeklyMaintenanceDriftCalories: 0,
        goalTimeline: const <GoalPhaseSegment>[
          GoalPhaseSegment(
            dayOffset: 0,
            goal: BodyweightGoal.maintainWeight,
            targetRateKgPerWeek: 0,
          ),
        ],
        intakeForDay: (ctx) {
          final inIllness = ctx.dayIndex >= 42 && ctx.dayIndex <= 55;
          return inIllness
              ? ctx.trueMaintenanceCalories - 260
              : ctx.trueMaintenanceCalories - 40;
        },
        stepsForDay: (ctx) {
          final inIllness = ctx.dayIndex >= 42 && ctx.dayIndex <= 55;
          return inIllness ? 2500 : 9800;
        },
        weightNoisePatternKg: const <double>[
          0.0,
          0.08,
          -0.07,
          0.09,
          -0.06,
          0.04,
          -0.03
        ],
        shouldLogWeight: (ctx) {
          final inIllness = ctx.dayIndex >= 42 && ctx.dayIndex <= 55;
          if (!inIllness) {
            return true;
          }
          return ctx.dayIndex % 4 == 0;
        },
        shouldLogIntake: (ctx) {
          final inIllness = ctx.dayIndex >= 42 && ctx.dayIndex <= 55;
          if (!inIllness) {
            return true;
          }
          return ctx.dayIndex % 5 == 0;
        },
      );

      final weeks = await runSyntheticTruthScenario(scenario);
      final model = modelWeeks(weeks);

      final summary = summarizeRecoveryWindows(
        weeks: weeks,
        preStart: 2,
        preEnd: 5,
        eventStart: 6,
        eventEnd: 8,
        postStart: 9,
        postEnd: 12,
      );
      final recoveryWeeks = weeksUntilPosteriorRecoversToBand(
        weeks: model,
        baselineMedian: summary.preEventPosteriorMedian,
        toleranceCalories: 220,
        searchStartWeek: 9,
        sustainedWeeks: 2,
      );

      expect(
        summary.eventVarianceMedian,
        greaterThanOrEqualTo(summary.preEventVarianceMedian * 0.70),
      );
      expect(
        summary.postEventVarianceMedian,
        lessThanOrEqualTo(summary.eventVarianceMedian * 1.2),
      );
      expect(
        summary.eventConfidenceAverage,
        lessThanOrEqualTo(summary.preEventConfidenceAverage + 0.25),
      );
      expect(
        summary.postEventConfidenceAverage,
        greaterThanOrEqualTo(summary.eventConfidenceAverage),
      );
      expect(recoveryWeeks, isNotNull);
      expect(recoveryWeeks!, lessThanOrEqualTo(3));
      expectNoAbsurdMaintenanceJumps(model, maxJumpCalories: 620);
    });

    test(
        'alternating high and low step weeks stay bounded and directionally sane',
        () async {
      final scenario = SyntheticTruthScenario(
        name: 'alternating_steps',
        profile: ScenarioProfile.defaultProfile(),
        firstDueWeekStart: DateTime(2026, 6, 1),
        weekCount: 10,
        warmupDays: 28,
        initialWeightKg: 78,
        initialTrueMaintenanceCalories: 2520,
        weeklyMaintenanceDriftCalories: 0,
        goalTimeline: const <GoalPhaseSegment>[
          GoalPhaseSegment(
            dayOffset: 0,
            goal: BodyweightGoal.maintainWeight,
            targetRateKgPerWeek: 0,
          ),
        ],
        intakeForDay: (ctx) {
          final weekIndex = ctx.dayIndex ~/ 7;
          final highWeek = weekIndex.isEven;
          return highWeek
              ? ctx.trueMaintenanceCalories + 140
              : ctx.trueMaintenanceCalories - 140;
        },
        stepsForDay: (ctx) {
          final weekIndex = ctx.dayIndex ~/ 7;
          return weekIndex.isEven ? 16000 : 3200;
        },
      );

      final weeks = await runSyntheticTruthScenario(scenario);
      final model = modelWeeks(weeks);

      final evenWeeks = <double>[];
      final oddWeeks = <double>[];
      for (var i = 0; i < model.length; i++) {
        final posterior =
            model[i].maintenanceEstimate.posteriorMaintenanceCalories;
        if (i.isEven) {
          evenWeeks.add(posterior);
        } else {
          oddWeeks.add(posterior);
        }
      }

      final evenMean = evenWeeks.reduce((a, b) => a + b) / evenWeeks.length;
      final oddMean = oddWeeks.reduce((a, b) => a + b) / oddWeeks.length;

      expectVarianceBoundedByCap(model);
      expectNoAbsurdMaintenanceJumps(model, maxJumpCalories: 520);
      // Directional sanity check: high-step blocks should not systematically
      // produce much lower maintenance than low-step blocks.
      expect(evenMean, greaterThanOrEqualTo(oddMean - 50));
    });

    test('good->poor->good logging quality degrades then recovers confidence',
        () async {
      final scenario = SyntheticTruthScenario(
        name: 'logging_quality_phases',
        profile: ScenarioProfile.defaultProfile(),
        firstDueWeekStart: DateTime(2026, 7, 6),
        weekCount: 11,
        warmupDays: 28,
        initialWeightKg: 84,
        initialTrueMaintenanceCalories: 2590,
        weeklyMaintenanceDriftCalories: 0,
        goalTimeline: const <GoalPhaseSegment>[
          GoalPhaseSegment(
            dayOffset: 0,
            goal: BodyweightGoal.loseWeight,
            targetRateKgPerWeek: -0.3,
          ),
        ],
        shouldLogWeight: (ctx) {
          if (ctx.dayIndex < 28) {
            return true;
          }
          if (ctx.dayIndex < 56) {
            return ctx.dayIndex % 6 == 0;
          }
          return true;
        },
        shouldLogIntake: (ctx) {
          if (ctx.dayIndex < 28) {
            return true;
          }
          if (ctx.dayIndex < 56) {
            return ctx.dayIndex % 7 == 0;
          }
          return true;
        },
      );

      final weeks = await runSyntheticTruthScenario(scenario);
      final model = modelWeeks(weeks);

      final summary = summarizeRecoveryWindows(
        weeks: weeks,
        preStart: 0,
        preEnd: 4,
        eventStart: 4,
        eventEnd: 7,
        postStart: 7,
        postEnd: 11,
      );
      final poorMedianAbsError = median(
        posteriorAbsoluteErrorSeries(weeks).sublist(4, 7),
      );
      final recoveredMedianAbsError = median(
        posteriorAbsoluteErrorSeries(weeks).sublist(7, 11),
      );

      final allQualityFlags = model
          .expand((week) => week.recommendation.inputSummary.qualityFlags)
          .toSet();

      expect(
        summary.eventConfidenceAverage,
        lessThanOrEqualTo(summary.preEventConfidenceAverage + 0.5),
      );
      expect(
        summary.postEventConfidenceAverage,
        greaterThanOrEqualTo(summary.eventConfidenceAverage),
      );
      expect(
        summary.eventVarianceMedian,
        greaterThanOrEqualTo(summary.preEventVarianceMedian * 0.85),
      );
      expect(
        summary.postEventVarianceMedian,
        lessThanOrEqualTo(summary.eventVarianceMedian * 1.7),
      );
      expect(recoveredMedianAbsError,
          lessThanOrEqualTo(poorMedianAbsError * 1.10));
      expect(
        allQualityFlags.contains('sparse_weight_logs') ||
            allQualityFlags.contains('sparse_intake_logs'),
        isTrue,
      );

      expectNoAbsurdMaintenanceJumps(model, maxJumpCalories: 700);
    });
  });
}
