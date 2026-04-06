import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_repository.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_estimation_mode.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecommendationRepository', () {
    late RecommendationRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = RecommendationRepository();
    });

    test('returns maintain defaults when nothing persisted', () async {
      expect(await repository.getGoal(), BodyweightGoal.maintainWeight);
      expect(await repository.getTargetRateKgPerWeek(), 0);
      expect(
        await repository.getPriorActivityLevel(),
        PriorActivityLevel.moderate,
      );
      expect(
        await repository.getExtraCardioHoursOption(),
        ExtraCardioHoursOption.h0,
      );
      expect(await repository.getLatestGeneratedRecommendation(), isNull);
    });

    test('coerces unsupported rate to goal default', () async {
      await repository.saveGoalAndTargetRate(
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.2,
      );

      expect(await repository.getGoal(), BodyweightGoal.gainWeight);
      expect(await repository.getTargetRateKgPerWeek(), 0.25);
    });

    test('persists and restores generated/applied recommendations', () async {
      final recommendation = _recommendation();
      await repository.savePriorActivityLevel(PriorActivityLevel.veryHigh);
      await repository.saveExtraCardioHoursOption(ExtraCardioHoursOption.h3);

      await repository.saveLatestGeneratedRecommendation(
        recommendation: recommendation,
      );
      await repository.saveLatestAppliedRecommendation(
        recommendation: recommendation,
      );

      final generated = await repository.getLatestGeneratedRecommendation();
      final applied = await repository.getLatestAppliedRecommendation();

      expect(generated, isNotNull);
      expect(applied, isNotNull);
      expect(
          generated!.recommendedCalories, recommendation.recommendedCalories);
      expect(applied!.recommendedFatGrams, recommendation.recommendedFatGrams);
      expect(await repository.getLastGeneratedDueWeekKey(), '2026-03-30');
      expect(
        await repository.getPriorActivityLevel(),
        PriorActivityLevel.veryHigh,
      );
      expect(
        await repository.getExtraCardioHoursOption(),
        ExtraCardioHoursOption.h3,
      );
    });

    test('falls back to default prior activity level on unknown raw value',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'adaptive_nutrition_recommendation.prior_activity_level': 'legacyValue',
      });
      repository = RecommendationRepository();

      expect(
        await repository.getPriorActivityLevel(),
        PriorActivityLevel.moderate,
      );
    });

    test('persists experimental recommendation and estimate separately',
        () async {
      final recommendation = _recommendation();
      final estimate = BayesianMaintenanceEstimate(
        posteriorMaintenanceCalories: 2380,
        posteriorStdDevCalories: 180,
        profilePriorMaintenanceCalories: 2400,
        priorMeanUsedCalories: 2400,
        priorStdDevUsedCalories: 200,
        priorSource: BayesianPriorSource.profilePriorBootstrap,
        observedIntakeCalories: 2300,
        observedWeightSlopeKgPerWeek: -0.1,
        observationImpliedMaintenanceCalories: 2410,
        effectiveSampleSize: 10,
        confidence: RecommendationConfidence.medium,
        qualityFlags: const ['bayesian_prior_dominant'],
        debugInfo: const {'kalmanGain': 0.33},
        dueWeekKey: '2026-04-06',
      );

      await repository.saveLatestGeneratedRecommendationForMode(
        mode: RecommendationEstimationMode.bayesianExperimental,
        recommendation: recommendation,
      );
      await repository.setLastGeneratedDueWeekKeyForMode(
        mode: RecommendationEstimationMode.bayesianExperimental,
        dueWeekKey: '2026-04-06',
      );
      await repository.saveLatestBayesianMaintenanceEstimate(
        estimate: estimate,
      );

      final experimental =
          await repository.getLatestGeneratedRecommendationForMode(
        mode: RecommendationEstimationMode.bayesianExperimental,
      );
      final heuristic = await repository.getLatestGeneratedRecommendation();
      final restoredEstimate =
          await repository.getLatestBayesianMaintenanceEstimate();

      expect(experimental, isNotNull);
      expect(heuristic, isNull);
      expect(
        await repository.getLastGeneratedDueWeekKeyForMode(
          mode: RecommendationEstimationMode.bayesianExperimental,
        ),
        '2026-04-06',
      );
      expect(restoredEstimate, isNotNull);
      expect(
        restoredEstimate!.posteriorMaintenanceCalories,
        closeTo(2380, 0.001),
      );
    });
  });
}

NutritionRecommendation _recommendation() {
  return NutritionRecommendation(
    recommendedCalories: 2400,
    recommendedProteinGrams: 170,
    recommendedCarbsGrams: 270,
    recommendedFatGrams: 70,
    estimatedMaintenanceCalories: 2400,
    goal: BodyweightGoal.maintainWeight,
    targetRateKgPerWeek: 0,
    confidence: RecommendationConfidence.medium,
    warningState: RecommendationWarningState.none,
    generatedAt: DateTime(2026, 4, 5),
    windowStart: DateTime(2026, 3, 15),
    windowEnd: DateTime(2026, 4, 5, 23, 59, 59),
    algorithmVersion: 'test',
    inputSummary: const RecommendationInputSummary(
      windowDays: 21,
      weightLogCount: 9,
      intakeLoggedDays: 15,
      smoothedWeightSlopeKgPerWeek: -0.2,
      avgLoggedCalories: 2300,
    ),
    baselineCalories: 2300,
    dueWeekKey: '2026-03-30',
  );
}
