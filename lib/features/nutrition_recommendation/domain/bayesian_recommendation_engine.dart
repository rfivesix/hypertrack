import 'bayesian_tdee_estimator.dart';
import 'goal_models.dart';
import 'recommendation_engine.dart';
import 'recommendation_models.dart';

class BayesianNutritionRecommendationResult {
  final NutritionRecommendation recommendation;
  final BayesianMaintenanceEstimate maintenanceEstimate;

  const BayesianNutritionRecommendationResult({
    required this.recommendation,
    required this.maintenanceEstimate,
  });

  int get maintenanceDeltaFromPriorCalories {
    return recommendation.estimatedMaintenanceCalories -
        maintenanceEstimate.priorMaintenanceCalories.round();
  }
}

class BayesianNutritionRecommendationEngine {
  final BayesianTdeeEstimator _estimator;

  const BayesianNutritionRecommendationEngine({
    BayesianTdeeEstimator estimator = const BayesianTdeeEstimator(),
  }) : _estimator = estimator;

  BayesianNutritionRecommendationResult generate({
    required RecommendationGenerationInput input,
    required BodyweightGoal goal,
    required double targetRateKgPerWeek,
    required DateTime generatedAt,
    required String algorithmVersion,
    String? dueWeekKey,
    BayesianMaintenancePrior? chainedPrior,
    NutritionRecommendation? previousRecommendation,
  }) {
    final maintenanceEstimate = _estimator.estimate(
      input: input,
      chainedPrior: chainedPrior,
      dueWeekKey: dueWeekKey,
    );

    final recommendation =
        AdaptiveNutritionRecommendationEngine.generateFromMaintenanceEstimate(
      input: input,
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      generatedAt: generatedAt,
      algorithmVersion: algorithmVersion,
      estimatedMaintenanceCalories:
          maintenanceEstimate.posteriorMaintenanceCalories.round(),
      confidence: maintenanceEstimate.confidence,
      dueWeekKey: dueWeekKey,
      previousRecommendation: previousRecommendation,
    );

    return BayesianNutritionRecommendationResult(
      recommendation: recommendation,
      maintenanceEstimate: maintenanceEstimate,
    );
  }
}
