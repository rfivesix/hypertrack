import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/bayesian_recommendation_engine.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_engine.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_models.dart';

void main() {
  group('Heuristic vs Bayesian estimator comparison', () {
    const bayesianEngine = BayesianNutritionRecommendationEngine();

    test('Bayesian sparse windows carry higher uncertainty than dense windows',
        () {
      final sparseInput = _input(
        priorMaintenanceCalories: 2700,
        avgLoggedCalories: 1800,
        smoothedWeightSlopeKgPerWeek: 0.05,
        windowDays: 7,
        weightLogCount: 3,
        intakeLoggedDays: 5,
      );
      final denseInput = _input(
        priorMaintenanceCalories: 2700,
        avgLoggedCalories: 1800,
        smoothedWeightSlopeKgPerWeek: 0.05,
        windowDays: 28,
        weightLogCount: 12,
        intakeLoggedDays: 20,
      );

      final sparseBayesian = bayesianEngine.generate(
        input: sparseInput,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 6, 10, 0),
        algorithmVersion: 'bayesian_test',
      );
      final denseBayesian = bayesianEngine.generate(
        input: denseInput,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 6, 10, 0),
        algorithmVersion: 'bayesian_test',
      );

      final sparseGain =
          sparseBayesian.maintenanceEstimate.debugInfo['kalmanGain'] as num;
      final denseGain =
          denseBayesian.maintenanceEstimate.debugInfo['kalmanGain'] as num;

      expect(
        sparseBayesian.maintenanceEstimate.posteriorStdDevCalories,
        greaterThan(denseBayesian.maintenanceEstimate.posteriorStdDevCalories),
      );
      expect(sparseGain.toDouble(), lessThan(denseGain.toDouble()));
    });

    test('Bayesian is more stable under mirrored noisy weight slopes', () {
      final positiveNoise = _input(
        priorMaintenanceCalories: 2400,
        avgLoggedCalories: 2400,
        smoothedWeightSlopeKgPerWeek: 0.30,
        windowDays: 21,
        weightLogCount: 10,
        intakeLoggedDays: 16,
      );
      final negativeNoise = _input(
        priorMaintenanceCalories: 2400,
        avgLoggedCalories: 2400,
        smoothedWeightSlopeKgPerWeek: -0.30,
        windowDays: 21,
        weightLogCount: 10,
        intakeLoggedDays: 16,
      );

      final heuristicPositive = AdaptiveNutritionRecommendationEngine.generate(
        input: positiveNoise,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 6, 10, 0),
        algorithmVersion: 'heuristic_test',
      );
      final heuristicNegative = AdaptiveNutritionRecommendationEngine.generate(
        input: negativeNoise,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 6, 10, 0),
        algorithmVersion: 'heuristic_test',
      );

      final bayesianPositive = bayesianEngine.generate(
        input: positiveNoise,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 6, 10, 0),
        algorithmVersion: 'bayesian_test',
      );
      final bayesianNegative = bayesianEngine.generate(
        input: negativeNoise,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 6, 10, 0),
        algorithmVersion: 'bayesian_test',
      );

      final heuristicSpread = (heuristicPositive.estimatedMaintenanceCalories -
              heuristicNegative.estimatedMaintenanceCalories)
          .abs();
      final bayesianSpread =
          (bayesianPositive.recommendation.estimatedMaintenanceCalories -
                  bayesianNegative.recommendation.estimatedMaintenanceCalories)
              .abs();

      expect(bayesianSpread, lessThan(heuristicSpread));
    });

    test('Bayesian does not produce absurd maintenance jumps from one window',
        () {
      final input = _input(
        priorMaintenanceCalories: 2500,
        avgLoggedCalories: 3400,
        smoothedWeightSlopeKgPerWeek: -0.60,
        windowDays: 21,
        weightLogCount: 10,
        intakeLoggedDays: 16,
      );

      final bayesian = bayesianEngine.generate(
        input: input,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 6, 10, 0),
        algorithmVersion: 'bayesian_test',
      );

      final delta =
          (bayesian.recommendation.estimatedMaintenanceCalories - 2500).abs();

      expect(
        bayesian.recommendation.estimatedMaintenanceCalories,
        inInclusiveRange(1200, 5000),
      );
      expect(delta, lessThan(1200));
      expect(
        bayesian.maintenanceEstimate.posteriorStdDevCalories,
        greaterThan(0),
      );
    });
  });
}

RecommendationGenerationInput _input({
  required int priorMaintenanceCalories,
  required double avgLoggedCalories,
  required double? smoothedWeightSlopeKgPerWeek,
  required int windowDays,
  required int weightLogCount,
  required int intakeLoggedDays,
}) {
  return RecommendationGenerationInput(
    windowStart: DateTime(2026, 3, 15),
    windowEnd: DateTime(2026, 4, 5, 23, 59, 59),
    windowDays: windowDays,
    weightLogCount: weightLogCount,
    intakeLoggedDays: intakeLoggedDays,
    smoothedWeightSlopeKgPerWeek: smoothedWeightSlopeKgPerWeek,
    avgLoggedCalories: avgLoggedCalories,
    currentWeightKg: 82,
    priorMaintenanceCalories: priorMaintenanceCalories,
    activeTargetCalories: null,
    qualityFlags: const [],
  );
}
