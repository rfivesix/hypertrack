import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/bayesian_recommendation_engine.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_models.dart';

void main() {
  group('BayesianNutritionRecommendationEngine', () {
    const engine = BayesianNutritionRecommendationEngine();

    test('sparse windows carry higher uncertainty and lower gain', () {
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

      final sparse = engine.generate(
        input: sparseInput,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 6, 10, 0),
        algorithmVersion: 'bayesian_test',
        dueWeekKey: '2026-04-06',
      );
      final dense = engine.generate(
        input: denseInput,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 6, 10, 0),
        algorithmVersion: 'bayesian_test',
        dueWeekKey: '2026-04-06',
      );

      final sparseGain =
          sparse.maintenanceEstimate.debugInfo['kalmanGain'] as num;
      final denseGain =
          dense.maintenanceEstimate.debugInfo['kalmanGain'] as num;

      expect(
        sparse.maintenanceEstimate.posteriorStdDevCalories,
        greaterThan(dense.maintenanceEstimate.posteriorStdDevCalories),
      );
      expect(sparseGain.toDouble(), lessThan(denseGain.toDouble()));
    });

    test('mirrored noisy slopes are damped versus raw observation spread', () {
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

      final positive = engine.generate(
        input: positiveNoise,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 6, 10, 0),
        algorithmVersion: 'bayesian_test',
        dueWeekKey: '2026-04-06',
      );
      final negative = engine.generate(
        input: negativeNoise,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 6, 10, 0),
        algorithmVersion: 'bayesian_test',
        dueWeekKey: '2026-04-06',
      );

      final posteriorSpread =
          (positive.recommendation.estimatedMaintenanceCalories -
                  negative.recommendation.estimatedMaintenanceCalories)
              .abs();
      final observedSpread =
          (positive.maintenanceEstimate.observationImpliedMaintenanceCalories! -
                  negative.maintenanceEstimate
                      .observationImpliedMaintenanceCalories!)
              .abs();

      expect(posteriorSpread, lessThan(observedSpread));
    });

    test('chains recursive state into next due week', () {
      final week1 = engine.generate(
        input: _input(
          priorMaintenanceCalories: 2500,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.2,
          windowDays: 21,
          weightLogCount: 10,
          intakeLoggedDays: 16,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 6, 10, 0),
        algorithmVersion: 'bayesian_test',
        dueWeekKey: '2026-04-06',
      );

      final week2 = engine.generate(
        input: _input(
          priorMaintenanceCalories: 2500,
          avgLoggedCalories: 2250,
          smoothedWeightSlopeKgPerWeek: -0.1,
          windowDays: 21,
          weightLogCount: 10,
          intakeLoggedDays: 16,
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 13, 10, 0),
        algorithmVersion: 'bayesian_test',
        dueWeekKey: '2026-04-13',
        recursiveState: week1.recursiveState,
      );

      expect(week2.recursiveState, isNotNull);
      expect(week2.recursiveState!.lastDueWeekKey, '2026-04-13');
      expect(
        week2.maintenanceEstimate.priorSource,
        BayesianPriorSource.chainedPosterior,
      );
      expect(
        week2.maintenanceEstimate.priorMeanUsedCalories,
        closeTo(week1.maintenanceEstimate.posteriorMaintenanceCalories, 0.0001),
      );
    });

    test('generated recommendation keeps canonical metadata fields', () {
      final result = engine.generate(
        input: _input(
          priorMaintenanceCalories: 2450,
          avgLoggedCalories: 2350,
          smoothedWeightSlopeKgPerWeek: -0.05,
          windowDays: 21,
          weightLogCount: 9,
          intakeLoggedDays: 14,
        ),
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -0.5,
        generatedAt: DateTime(2026, 4, 6, 10, 0),
        algorithmVersion: 'tdee_adaptive_recommendation_1_0_bayesian_recursive',
        dueWeekKey: '2026-04-06',
      );

      expect(result.recommendation.dueWeekKey, '2026-04-06');
      expect(
        result.recommendation.algorithmVersion,
        'tdee_adaptive_recommendation_1_0_bayesian_recursive',
      );
      expect(result.recommendation.confidence,
          isNot(RecommendationConfidence.notEnoughData));
      expect(result.recursiveState, isNotNull);
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
