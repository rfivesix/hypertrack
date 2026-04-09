import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_engine.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_models.dart';

void main() {
  group('AdaptiveNutritionRecommendationEngine projection', () {
    test('rateAdjustmentKcalPerDay maps weekly kg target to kcal/day', () {
      expect(
        AdaptiveNutritionRecommendationEngine.rateAdjustmentKcalPerDay(-0.50),
        -550,
      );
      expect(
        AdaptiveNutritionRecommendationEngine.rateAdjustmentKcalPerDay(0.25),
        275,
      );
    });

    test('uses active targets as warning baseline for large adjustments', () {
      final recommendation =
          AdaptiveNutritionRecommendationEngine.generateFromMaintenanceEstimate(
        input: _input(activeTargetCalories: 2000),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
        estimatedMaintenanceCalories: 2550,
        confidence: RecommendationConfidence.medium,
        dueWeekKey: '2026-04-06',
      );

      expect(recommendation.recommendedCalories, 2550);
      expect(recommendation.baselineCalories, 2000);
      expect(recommendation.warningState.hasLargeAdjustmentWarning, isTrue);
      expect(
        recommendation.warningState.warningReasons,
        contains('large_adjustment_high'),
      );
      expect(recommendation.dueWeekKey, '2026-04-06');
    });

    test(
        'falls back to previous recommendation baseline when active target is missing',
        () {
      final previous = NutritionRecommendation(
        recommendedCalories: 2350,
        recommendedProteinGrams: 170,
        recommendedCarbsGrams: 250,
        recommendedFatGrams: 70,
        estimatedMaintenanceCalories: 2350,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        confidence: RecommendationConfidence.medium,
        warningState: RecommendationWarningState.none,
        generatedAt: DateTime(2026, 3, 29),
        windowStart: DateTime(2026, 3, 9),
        windowEnd: DateTime(2026, 3, 29, 23, 59, 59),
        algorithmVersion: 'test',
        inputSummary: const RecommendationInputSummary(
          windowDays: 21,
          weightLogCount: 9,
          intakeLoggedDays: 15,
          smoothedWeightSlopeKgPerWeek: -0.1,
          avgLoggedCalories: 2300,
        ),
        baselineCalories: 2350,
        dueWeekKey: '2026-03-23',
      );

      final recommendation =
          AdaptiveNutritionRecommendationEngine.generateFromMaintenanceEstimate(
        input: _input(activeTargetCalories: null),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
        estimatedMaintenanceCalories: 2500,
        confidence: RecommendationConfidence.medium,
        previousRecommendation: previous,
      );

      expect(recommendation.baselineCalories, 2350);
      expect(recommendation.warningState.hasLargeAdjustmentWarning, isFalse);
    });

    test('applies calorie floor and degrades confidence conservatively', () {
      final recommendation =
          AdaptiveNutritionRecommendationEngine.generateFromMaintenanceEstimate(
        input: _input(currentWeightKg: 95),
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -1.0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
        estimatedMaintenanceCalories: 1200,
        confidence: RecommendationConfidence.high,
      );

      expect(recommendation.recommendedCalories, 1200);
      expect(recommendation.confidence, RecommendationConfidence.low);
      expect(
        recommendation.warningState.warningReasons,
        contains('calorie_floor_applied'),
      );
      expect(
        recommendation.warningState.warningLevel,
        RecommendationWarningLevel.high,
      );
    });

    test('surfaces unresolved calorie inputs as warning reason', () {
      final recommendation =
          AdaptiveNutritionRecommendationEngine.generateFromMaintenanceEstimate(
        input: _input(
          qualityFlags: const ['unresolved_food_calories'],
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
        estimatedMaintenanceCalories: 2400,
        confidence: RecommendationConfidence.medium,
      );

      expect(
        recommendation.warningState.warningReasons,
        contains('unresolved_food_calories'),
      );
      expect(
        recommendation.warningState.warningLevel,
        RecommendationWarningLevel.moderate,
      );
    });

    test('appends additional warning reasons for estimator context', () {
      final recommendation =
          AdaptiveNutritionRecommendationEngine.generateFromMaintenanceEstimate(
        input: _input(),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
        estimatedMaintenanceCalories: 2400,
        confidence: RecommendationConfidence.medium,
        additionalWarningReasons: const [
          'bayesian_prediction_only_no_observation'
        ],
      );

      expect(
        recommendation.warningState.warningReasons,
        contains('bayesian_prediction_only_no_observation'),
      );
    });
  });
}

RecommendationGenerationInput _input({
  int? activeTargetCalories,
  List<String> qualityFlags = const [],
  double currentWeightKg = 82,
}) {
  return RecommendationGenerationInput(
    windowStart: DateTime(2026, 3, 15),
    windowEnd: DateTime(2026, 4, 5, 23, 59, 59),
    windowDays: 14,
    weightLogCount: 6,
    intakeLoggedDays: 10,
    smoothedWeightSlopeKgPerWeek: -0.2,
    avgLoggedCalories: 2300,
    currentWeightKg: currentWeightKg,
    priorMaintenanceCalories: 2400,
    activeTargetCalories: activeTargetCalories,
    qualityFlags: qualityFlags,
  );
}
