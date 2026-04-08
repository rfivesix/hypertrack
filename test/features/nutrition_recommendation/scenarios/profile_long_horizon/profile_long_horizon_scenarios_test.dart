import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';

import '../scenario_test_harness.dart';
import '../support/scenario_metrics.dart';
import '../support/synthetic_truth_simulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive nutrition long-horizon profile matrix scenarios', () {
    final profiles = <_LongHorizonProfileScenario>[
      _LongHorizonProfileScenario(
        name: 'very_light_lean_female_moderate_activity',
        profile: ScenarioProfile(
          name: 'Very Light Lean Female',
          birthday: DateTime(1999, 6, 20),
          heightCm: 163,
          gender: 'female',
          initialWeightKg: 49,
          bodyFatPercent: 18,
          declaredActivityLevel: PriorActivityLevel.moderate,
          extraCardioHoursOption: ExtraCardioHoursOption.h1,
          targetSteps: 9000,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 2060,
        weeklyMaintenanceDriftCalories: 2,
        dailySteps: 9500,
      ),
      _LongHorizonProfileScenario(
        name: 'very_heavy_high_bodyfat_male_low_activity',
        profile: ScenarioProfile(
          name: 'Very Heavy High BF Male',
          birthday: DateTime(1986, 3, 1),
          heightCm: 182,
          gender: 'male',
          initialWeightKg: 142,
          bodyFatPercent: 38,
          declaredActivityLevel: PriorActivityLevel.low,
          extraCardioHoursOption: ExtraCardioHoursOption.h0,
          targetSteps: 4500,
        ),
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -0.35,
        initialTrueMaintenanceCalories: 3070,
        weeklyMaintenanceDriftCalories: -6,
        dailySteps: 4600,
      ),
      _LongHorizonProfileScenario(
        name: 'medium_lean_male_high_activity',
        profile: ScenarioProfile(
          name: 'Medium Lean Male High Activity',
          birthday: DateTime(1994, 9, 14),
          heightCm: 180,
          gender: 'male',
          initialWeightKg: 77,
          bodyFatPercent: 12,
          declaredActivityLevel: PriorActivityLevel.veryHigh,
          extraCardioHoursOption: ExtraCardioHoursOption.h5,
          targetSteps: 13500,
        ),
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.2,
        initialTrueMaintenanceCalories: 3140,
        weeklyMaintenanceDriftCalories: 5,
        dailySteps: 14000,
      ),
      _LongHorizonProfileScenario(
        name: 'medium_heavier_high_bodyfat_female_low_activity',
        profile: ScenarioProfile(
          name: 'Medium Heavier Female High BF',
          birthday: DateTime(1992, 2, 11),
          heightCm: 168,
          gender: 'female',
          initialWeightKg: 91,
          bodyFatPercent: 34,
          declaredActivityLevel: PriorActivityLevel.low,
          extraCardioHoursOption: ExtraCardioHoursOption.h0,
          targetSteps: 5000,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 2280,
        weeklyMaintenanceDriftCalories: 0,
        dailySteps: 5200,
      ),
      _LongHorizonProfileScenario(
        name: 'unknown_gender_missing_optional_fields',
        profile: ScenarioProfile(
          name: 'Unknown Optional Inputs',
          birthday: null,
          heightCm: null,
          gender: null,
          initialWeightKg: 80,
          bodyFatPercent: null,
          declaredActivityLevel: PriorActivityLevel.moderate,
          extraCardioHoursOption: ExtraCardioHoursOption.h0,
          targetSteps: 8000,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 2520,
        weeklyMaintenanceDriftCalories: 0,
        dailySteps: 8200,
      ),
      _LongHorizonProfileScenario(
        name: 'edge_tall_lean_high_activity_profile',
        profile: ScenarioProfile(
          name: 'Tall Lean Edge',
          birthday: DateTime(1997, 11, 28),
          heightCm: 201,
          gender: 'male',
          initialWeightKg: 92,
          bodyFatPercent: 9,
          declaredActivityLevel: PriorActivityLevel.veryHigh,
          extraCardioHoursOption: ExtraCardioHoursOption.h5,
          targetSteps: 18000,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 3540,
        weeklyMaintenanceDriftCalories: 8,
        dailySteps: 18000,
      ),
    ];

    for (final scenario in profiles) {
      test('profile remains stable over 10-week horizon: ${scenario.name}',
          () async {
        final weeks = await _runProfileScenario(scenario);

        final model = modelWeeks(weeks);

        for (final week in model) {
          expect(week.recommendation.recommendedCalories,
              inInclusiveRange(1100, 5200));
          expect(
            week.maintenanceEstimate.posteriorMaintenanceCalories,
            inInclusiveRange(1100, 5200),
          );
          expect(week.recommendation.recommendedCalories.isFinite, isTrue);
          expect(
            week.maintenanceEstimate.posteriorMaintenanceCalories.isFinite,
            isTrue,
          );
          expect(
              week.debugValue('posteriorVarianceCalories2').isFinite, isTrue);
        }

        expectVarianceBoundedByCap(model);
        expectNoAbsurdMaintenanceJumps(model, maxJumpCalories: 620);

        // Conservative convergence guardrail: all curated profiles should reach a
        // usable posterior error band by week 8 with good logging quality.
        expect(
          didConvergeByWeek(weeks, weekIndex: 8, maxAbsErrorCalories: 560),
          isTrue,
        );
        expect(
            medianAbsoluteError(weeks, startWeek: 6), lessThanOrEqualTo(520));

        final deltas = posteriorWeeklyDeltaSeries(weeks)
            .map((delta) => delta.abs())
            .toList(growable: false);
        final maxDelta = deltas.isEmpty ? 0 : deltas.reduce(math.max);
        expect(maxDelta, lessThanOrEqualTo(620));

        expect(averageConfidenceScore(weeks, startWeek: 6),
            greaterThanOrEqualTo(0.9));
      });
    }

    test('comparative profiles stay directionally plausible over long horizon',
        () async {
      final lighterFemale = _LongHorizonProfileScenario(
        name: 'lighter_female',
        profile: ScenarioProfile(
          name: 'Lighter Female Compare',
          birthday: DateTime(1995, 4, 7),
          heightCm: 166,
          gender: 'female',
          initialWeightKg: 57,
          bodyFatPercent: 24,
          declaredActivityLevel: PriorActivityLevel.moderate,
          extraCardioHoursOption: ExtraCardioHoursOption.h1,
          targetSteps: 9000,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 2160,
        weeklyMaintenanceDriftCalories: 0,
        dailySteps: 9000,
      );
      final heavierMale = _LongHorizonProfileScenario(
        name: 'heavier_male',
        profile: ScenarioProfile(
          name: 'Heavier Male Compare',
          birthday: DateTime(1995, 4, 7),
          heightCm: 182,
          gender: 'male',
          initialWeightKg: 105,
          bodyFatPercent: 30,
          declaredActivityLevel: PriorActivityLevel.moderate,
          extraCardioHoursOption: ExtraCardioHoursOption.h1,
          targetSteps: 9000,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 2920,
        weeklyMaintenanceDriftCalories: 0,
        dailySteps: 9000,
      );

      final leanMale = _LongHorizonProfileScenario(
        name: 'lean_male_compare',
        profile: ScenarioProfile(
          name: 'Lean Male Compare',
          birthday: DateTime(1991, 10, 10),
          heightCm: 180,
          gender: 'male',
          initialWeightKg: 88,
          bodyFatPercent: 12,
          declaredActivityLevel: PriorActivityLevel.moderate,
          extraCardioHoursOption: ExtraCardioHoursOption.h0,
          targetSteps: 8000,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 2740,
        weeklyMaintenanceDriftCalories: 0,
        dailySteps: 8000,
      );
      final higherBfMale = _LongHorizonProfileScenario(
        name: 'higher_bf_male_compare',
        profile: ScenarioProfile(
          name: 'Higher BF Male Compare',
          birthday: DateTime(1991, 10, 10),
          heightCm: 180,
          gender: 'male',
          initialWeightKg: 88,
          bodyFatPercent: 32,
          declaredActivityLevel: PriorActivityLevel.moderate,
          extraCardioHoursOption: ExtraCardioHoursOption.h0,
          targetSteps: 8000,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 2460,
        weeklyMaintenanceDriftCalories: 0,
        dailySteps: 8000,
      );

      final lowActivityMale = _LongHorizonProfileScenario(
        name: 'low_activity_compare',
        profile: ScenarioProfile(
          name: 'Low Activity Compare',
          birthday: DateTime(1993, 8, 12),
          heightCm: 178,
          gender: 'male',
          initialWeightKg: 82,
          bodyFatPercent: 18,
          declaredActivityLevel: PriorActivityLevel.low,
          extraCardioHoursOption: ExtraCardioHoursOption.h0,
          targetSteps: 5000,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 2360,
        weeklyMaintenanceDriftCalories: 0,
        dailySteps: 5200,
      );
      final highActivityMale = _LongHorizonProfileScenario(
        name: 'high_activity_compare',
        profile: ScenarioProfile(
          name: 'High Activity Compare',
          birthday: DateTime(1993, 8, 12),
          heightCm: 178,
          gender: 'male',
          initialWeightKg: 82,
          bodyFatPercent: 18,
          declaredActivityLevel: PriorActivityLevel.veryHigh,
          extraCardioHoursOption: ExtraCardioHoursOption.h5,
          targetSteps: 15000,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 2880,
        weeklyMaintenanceDriftCalories: 0,
        dailySteps: 15000,
      );

      final maleKnown = _LongHorizonProfileScenario(
        name: 'male_known_compare',
        profile: ScenarioProfile(
          name: 'Male Known Compare',
          birthday: DateTime(1994, 6, 1),
          heightCm: 176,
          gender: 'male',
          initialWeightKg: 80,
          bodyFatPercent: null,
          declaredActivityLevel: PriorActivityLevel.moderate,
          extraCardioHoursOption: ExtraCardioHoursOption.h0,
          targetSteps: 8500,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 2580,
        weeklyMaintenanceDriftCalories: 0,
        dailySteps: 8500,
      );
      final femaleKnown = _LongHorizonProfileScenario(
        name: 'female_known_compare',
        profile: ScenarioProfile(
          name: 'Female Known Compare',
          birthday: DateTime(1994, 6, 1),
          heightCm: 176,
          gender: 'female',
          initialWeightKg: 80,
          bodyFatPercent: null,
          declaredActivityLevel: PriorActivityLevel.moderate,
          extraCardioHoursOption: ExtraCardioHoursOption.h0,
          targetSteps: 8500,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 2420,
        weeklyMaintenanceDriftCalories: 0,
        dailySteps: 8500,
      );
      final unknownGender = _LongHorizonProfileScenario(
        name: 'unknown_gender_compare',
        profile: ScenarioProfile(
          name: 'Unknown Gender Compare',
          birthday: DateTime(1994, 6, 1),
          heightCm: 176,
          gender: null,
          initialWeightKg: 80,
          bodyFatPercent: null,
          declaredActivityLevel: PriorActivityLevel.moderate,
          extraCardioHoursOption: ExtraCardioHoursOption.h0,
          targetSteps: 8500,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 2500,
        weeklyMaintenanceDriftCalories: 0,
        dailySteps: 8500,
      );

      final lowSteps = _LongHorizonProfileScenario(
        name: 'low_steps_compare',
        profile: ScenarioProfile.defaultProfile(),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 2380,
        weeklyMaintenanceDriftCalories: 0,
        dailySteps: 3800,
      );
      final highSteps = _LongHorizonProfileScenario(
        name: 'high_steps_compare',
        profile: ScenarioProfile.defaultProfile(),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        initialTrueMaintenanceCalories: 2740,
        weeklyMaintenanceDriftCalories: 0,
        dailySteps: 16000,
      );

      final lighterWeeks = await _runProfileScenario(lighterFemale);
      final heavierWeeks = await _runProfileScenario(heavierMale);
      final leanWeeks = await _runProfileScenario(leanMale);
      final highBfWeeks = await _runProfileScenario(higherBfMale);
      final lowActivityWeeks = await _runProfileScenario(lowActivityMale);
      final highActivityWeeks = await _runProfileScenario(highActivityMale);
      final maleKnownWeeks = await _runProfileScenario(maleKnown);
      final femaleKnownWeeks = await _runProfileScenario(femaleKnown);
      final unknownGenderWeeks = await _runProfileScenario(unknownGender);
      final lowStepsWeeks = await _runProfileScenario(lowSteps);
      final highStepsWeeks = await _runProfileScenario(highSteps);

      final lighterTail = medianPosteriorCaloriesForWeeks(
        modelWeeks(lighterWeeks),
        startInclusive: 7,
        endExclusive: 10,
      );
      final heavierTail = medianPosteriorCaloriesForWeeks(
        modelWeeks(heavierWeeks),
        startInclusive: 7,
        endExclusive: 10,
      );
      expect(heavierTail, greaterThan(lighterTail + 200));

      final leanTail = medianPosteriorCaloriesForWeeks(
        modelWeeks(leanWeeks),
        startInclusive: 7,
        endExclusive: 10,
      );
      final highBfTail = medianPosteriorCaloriesForWeeks(
        modelWeeks(highBfWeeks),
        startInclusive: 7,
        endExclusive: 10,
      );
      expect(leanTail, greaterThan(highBfTail + 80));

      final lowActivityTail = medianPosteriorCaloriesForWeeks(
        modelWeeks(lowActivityWeeks),
        startInclusive: 7,
        endExclusive: 10,
      );
      final highActivityTail = medianPosteriorCaloriesForWeeks(
        modelWeeks(highActivityWeeks),
        startInclusive: 7,
        endExclusive: 10,
      );
      expect(highActivityTail, greaterThan(lowActivityTail + 120));

      final maleTail = medianPosteriorCaloriesForWeeks(
        modelWeeks(maleKnownWeeks),
        startInclusive: 7,
        endExclusive: 10,
      );
      final femaleTail = medianPosteriorCaloriesForWeeks(
        modelWeeks(femaleKnownWeeks),
        startInclusive: 7,
        endExclusive: 10,
      );
      final unknownTail = medianPosteriorCaloriesForWeeks(
        modelWeeks(unknownGenderWeeks),
        startInclusive: 7,
        endExclusive: 10,
      );
      expect(maleTail, greaterThanOrEqualTo(femaleTail - 50));
      expect(unknownTail, inInclusiveRange(femaleTail - 180, maleTail + 180));

      final lowStepsTail = medianPosteriorCaloriesForWeeks(
        modelWeeks(lowStepsWeeks),
        startInclusive: 7,
        endExclusive: 10,
      );
      final highStepsTail = medianPosteriorCaloriesForWeeks(
        modelWeeks(highStepsWeeks),
        startInclusive: 7,
        endExclusive: 10,
      );
      expect(highStepsTail, greaterThan(lowStepsTail + 120));
    });
  });
}

Future<List<SyntheticWeekResult>> _runProfileScenario(
  _LongHorizonProfileScenario scenario,
) {
  return runSyntheticTruthScenario(
    SyntheticTruthScenario(
      name: scenario.name,
      profile: scenario.profile,
      firstDueWeekStart: DateTime(2026, 2, 2),
      weekCount: 10,
      warmupDays: 28,
      initialWeightKg: scenario.profile.initialWeightKg,
      initialTrueMaintenanceCalories: scenario.initialTrueMaintenanceCalories,
      weeklyMaintenanceDriftCalories: scenario.weeklyMaintenanceDriftCalories,
      goalTimeline: <GoalPhaseSegment>[
        GoalPhaseSegment(
          dayOffset: 0,
          goal: scenario.goal,
          targetRateKgPerWeek: scenario.targetRateKgPerWeek,
        ),
      ],
      stepsForDay: (_) => scenario.dailySteps,
      intakeForDay: (ctx) {
        final targetAdjustment = scenario.targetRateKgPerWeek * 7700 / 7.0;
        return ctx.trueMaintenanceCalories + targetAdjustment;
      },
      intakeNoisePatternCalories: const <int>[0, 35, -22, 28, -24, 18, -12],
      weightNoisePatternKg: const <double>[
        0.0,
        0.05,
        -0.04,
        0.06,
        -0.03,
        0.02,
        -0.02
      ],
    ),
  );
}

class _LongHorizonProfileScenario {
  final String name;
  final ScenarioProfile profile;
  final BodyweightGoal goal;
  final double targetRateKgPerWeek;
  final double initialTrueMaintenanceCalories;
  final double weeklyMaintenanceDriftCalories;
  final int dailySteps;

  const _LongHorizonProfileScenario({
    required this.name,
    required this.profile,
    required this.goal,
    required this.targetRateKgPerWeek,
    required this.initialTrueMaintenanceCalories,
    required this.weeklyMaintenanceDriftCalories,
    required this.dailySteps,
  });
}
