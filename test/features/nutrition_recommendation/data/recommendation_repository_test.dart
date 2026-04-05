import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_repository.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
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
