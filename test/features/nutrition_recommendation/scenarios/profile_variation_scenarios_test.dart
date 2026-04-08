import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_models.dart';

import 'scenario_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive nutrition profile variation scenarios', () {
    test('onboarding bootstrap remains numerically stable across profiles',
        () async {
      final harness = await AdaptiveScenarioHarness.create();
      addTearDown(harness.dispose);

      final now = DateTime(2026, 6, 15, 9);

      final lighter = await harness.service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 62,
        heightCm: 172,
        birthday: DateTime(1996, 2, 15),
        gender: 'female',
        bodyFatPercent: 24,
        declaredActivityLevel: PriorActivityLevel.moderate,
        extraCardioHoursOption: ExtraCardioHoursOption.h1,
        now: now,
      );
      final heavier = await harness.service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 104,
        heightCm: 182,
        birthday: DateTime(1992, 9, 10),
        gender: 'male',
        bodyFatPercent: 24,
        declaredActivityLevel: PriorActivityLevel.moderate,
        extraCardioHoursOption: ExtraCardioHoursOption.h1,
        now: now,
      );

      final lowerBodyFat =
          await harness.service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 88,
        heightCm: 182,
        birthday: DateTime(1994, 5, 12),
        gender: 'male',
        bodyFatPercent: 12,
        declaredActivityLevel: PriorActivityLevel.moderate,
        extraCardioHoursOption: ExtraCardioHoursOption.h0,
        now: now,
      );
      final higherBodyFat =
          await harness.service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 88,
        heightCm: 182,
        birthday: DateTime(1994, 5, 12),
        gender: 'male',
        bodyFatPercent: 33,
        declaredActivityLevel: PriorActivityLevel.moderate,
        extraCardioHoursOption: ExtraCardioHoursOption.h0,
        now: now,
      );

      final male = await harness.service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 80,
        heightCm: 180,
        birthday: DateTime(1993, 1, 8),
        gender: 'male',
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.moderate,
        extraCardioHoursOption: ExtraCardioHoursOption.h0,
        now: now,
      );
      final female = await harness.service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 80,
        heightCm: 180,
        birthday: DateTime(1993, 1, 8),
        gender: 'female',
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.moderate,
        extraCardioHoursOption: ExtraCardioHoursOption.h0,
        now: now,
      );
      final unknownGender =
          await harness.service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 80,
        heightCm: 180,
        birthday: DateTime(1993, 1, 8),
        gender: null,
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.moderate,
        extraCardioHoursOption: ExtraCardioHoursOption.h0,
        now: now,
      );

      final lowActivity =
          await harness.service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 80,
        heightCm: 180,
        birthday: DateTime(1993, 1, 8),
        gender: 'male',
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.low,
        extraCardioHoursOption: ExtraCardioHoursOption.h0,
        now: now,
      );
      final highActivity =
          await harness.service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 80,
        heightCm: 180,
        birthday: DateTime(1993, 1, 8),
        gender: 'male',
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.veryHigh,
        extraCardioHoursOption: ExtraCardioHoursOption.h5,
        now: now,
      );

      final outputs = [
        lighter,
        heavier,
        lowerBodyFat,
        higherBodyFat,
        male,
        female,
        unknownGender,
        lowActivity,
        highActivity,
      ];

      for (final recommendation in outputs) {
        expect(
            recommendation.recommendedCalories, inInclusiveRange(1200, 5000));
        expect(
          recommendation.estimatedMaintenanceCalories,
          inInclusiveRange(1200, 5000),
        );
      }

      expect(
        heavier.estimatedMaintenanceCalories,
        greaterThan(lighter.estimatedMaintenanceCalories),
      );
      expect(
        lowerBodyFat.estimatedMaintenanceCalories,
        greaterThan(higherBodyFat.estimatedMaintenanceCalories),
      );
      expect(
        male.estimatedMaintenanceCalories,
        greaterThanOrEqualTo(unknownGender.estimatedMaintenanceCalories),
      );
      expect(
        unknownGender.estimatedMaintenanceCalories,
        greaterThanOrEqualTo(female.estimatedMaintenanceCalories),
      );
      expect(
        highActivity.estimatedMaintenanceCalories,
        greaterThan(lowActivity.estimatedMaintenanceCalories),
      );
    });

    test('low steps vs high steps shifts onboarding maintenance prior safely',
        () async {
      final now = DateTime(2026, 6, 30, 9);
      final stepsStart = now.subtract(const Duration(days: 20));

      final lowSteps = await _runStepsOnboardingPreview(
        stepsStart: stepsStart,
        dailySteps: 4200,
        now: now,
      );
      final highSteps = await _runStepsOnboardingPreview(
        stepsStart: stepsStart,
        dailySteps: 15200,
        now: now,
      );

      expect(
        highSteps.estimatedMaintenanceCalories,
        greaterThan(lowSteps.estimatedMaintenanceCalories),
      );
      expect(highSteps.recommendedCalories, inInclusiveRange(1200, 5000));
      expect(lowSteps.recommendedCalories, inInclusiveRange(1200, 5000));
    });

    test('missing optional profile inputs still yields safe bootstrap outputs',
        () async {
      final harness = await AdaptiveScenarioHarness.create(
        profile: ScenarioProfile(
          name: 'Missing Optional Fields',
          birthday: null,
          heightCm: null,
          gender: null,
          initialWeightKg: 75,
          bodyFatPercent: null,
          declaredActivityLevel: PriorActivityLevel.moderate,
          extraCardioHoursOption: ExtraCardioHoursOption.h0,
          targetSteps: 8000,
        ),
      );
      addTearDown(harness.dispose);

      final recommendation =
          await harness.service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: null,
        heightCm: null,
        birthday: null,
        gender: null,
        bodyFatPercent: null,
        declaredActivityLevel: null,
        extraCardioHoursOption: null,
        now: DateTime(2026, 7, 2, 9),
      );

      expect(recommendation.recommendedCalories, inInclusiveRange(1200, 5000));
      expect(
        recommendation.estimatedMaintenanceCalories,
        inInclusiveRange(1200, 5000),
      );
      expect(recommendation.dueWeekKey, isNotNull);
    });
  });
}

Future<NutritionRecommendation> _runStepsOnboardingPreview({
  required DateTime stepsStart,
  required int dailySteps,
  required DateTime now,
}) async {
  final harness = await AdaptiveScenarioHarness.create();
  try {
    await harness.seedDailySteps(
      startDay: stepsStart,
      dayCount: 21,
      dailySteps: dailySteps,
    );

    return await harness.service.generateOnboardingRecommendation(
      goal: BodyweightGoal.maintainWeight,
      targetRateKgPerWeek: 0,
      weightKg: 80,
      heightCm: 180,
      birthday: DateTime(1993, 1, 8),
      gender: 'male',
      bodyFatPercent: null,
      declaredActivityLevel: PriorActivityLevel.moderate,
      extraCardioHoursOption: ExtraCardioHoursOption.h0,
      now: now,
    );
  } finally {
    await harness.dispose();
  }
}
