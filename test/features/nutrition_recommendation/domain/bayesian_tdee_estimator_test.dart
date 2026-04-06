import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_models.dart';

void main() {
  group('BayesianTdeeEstimator', () {
    const estimator = BayesianTdeeEstimator();

    test('no data keeps posterior near prior and uncertainty high', () {
      final input = _input(
        priorMaintenanceCalories: 2500,
        avgLoggedCalories: 0,
        smoothedWeightSlopeKgPerWeek: null,
        windowDays: 0,
        weightLogCount: 0,
        intakeLoggedDays: 0,
      );

      final estimate = estimator.estimate(input: input);

      expect(estimate.posteriorMaintenanceCalories, closeTo(2500, 0.001));
      expect(estimate.posteriorStdDevCalories, greaterThan(400));
      expect(estimate.effectiveSampleSize, 0);
      expect(estimate.confidence, RecommendationConfidence.notEnoughData);
      expect(estimate.priorSource, BayesianPriorSource.profilePriorBootstrap);
      expect(estimate.priorMeanUsedCalories, closeTo(2500, 0.001));
      expect(estimate.priorStdDevUsedCalories, closeTo(420, 0.001));
    });

    test('sparse data produces only a small update from prior', () {
      final input = _input(
        priorMaintenanceCalories: 2400,
        avgLoggedCalories: 2100,
        smoothedWeightSlopeKgPerWeek: -0.25,
        windowDays: 7,
        weightLogCount: 3,
        intakeLoggedDays: 3,
      );

      final estimate = estimator.estimate(input: input);

      expect(
        (estimate.posteriorMaintenanceCalories - 2400).abs(),
        lessThan(140),
      );
      expect(estimate.posteriorStdDevCalories, greaterThan(220));
    });

    test('consistent signal can move posterior maintenance lower than prior',
        () {
      final input = _input(
        priorMaintenanceCalories: 2800,
        avgLoggedCalories: 2150,
        smoothedWeightSlopeKgPerWeek: -0.10,
        windowDays: 21,
        weightLogCount: 10,
        intakeLoggedDays: 16,
      );

      final estimate = estimator.estimate(input: input);

      expect(estimate.observationImpliedMaintenanceCalories, lessThan(2800));
      expect(estimate.posteriorMaintenanceCalories, lessThan(2800));
    });

    test('consistent surplus-style signal can move posterior above prior', () {
      final input = _input(
        priorMaintenanceCalories: 2200,
        avgLoggedCalories: 2750,
        smoothedWeightSlopeKgPerWeek: 0.10,
        windowDays: 21,
        weightLogCount: 10,
        intakeLoggedDays: 16,
      );

      final estimate = estimator.estimate(input: input);

      expect(estimate.observationImpliedMaintenanceCalories, greaterThan(2200));
      expect(estimate.posteriorMaintenanceCalories, greaterThan(2200));
    });

    test('noisy weights with stable intake remain reasonably stable', () {
      final common = _input(
        priorMaintenanceCalories: 2400,
        avgLoggedCalories: 2400,
        smoothedWeightSlopeKgPerWeek: 0.15,
        windowDays: 21,
        weightLogCount: 12,
        intakeLoggedDays: 17,
      );
      final mirrorNoise = _input(
        priorMaintenanceCalories: 2400,
        avgLoggedCalories: 2400,
        smoothedWeightSlopeKgPerWeek: -0.15,
        windowDays: 21,
        weightLogCount: 12,
        intakeLoggedDays: 17,
      );

      final first = estimator.estimate(input: common);
      final second = estimator.estimate(input: mirrorNoise);

      expect(
        (first.posteriorMaintenanceCalories -
                second.posteriorMaintenanceCalories)
            .abs(),
        lessThan(260),
      );
    });

    test('estimation is deterministic for identical inputs', () {
      final input = _input(
        priorMaintenanceCalories: 2350,
        avgLoggedCalories: 2250,
        smoothedWeightSlopeKgPerWeek: -0.05,
        windowDays: 14,
        weightLogCount: 7,
        intakeLoggedDays: 11,
      );

      final first = estimator.estimate(input: input);
      final second = estimator.estimate(input: input);

      expect(
        second.posteriorMaintenanceCalories,
        closeTo(first.posteriorMaintenanceCalories, 0.000001),
      );
      expect(
        second.posteriorStdDevCalories,
        closeTo(first.posteriorStdDevCalories, 0.000001),
      );
      expect(second.confidence, first.confidence);
      expect(second.qualityFlags, first.qualityFlags);
    });

    test('chained prior overrides profile prior when provided', () {
      final input = _input(
        priorMaintenanceCalories: 2600,
        avgLoggedCalories: 2400,
        smoothedWeightSlopeKgPerWeek: -0.05,
        windowDays: 14,
        weightLogCount: 7,
        intakeLoggedDays: 11,
      );
      const chainedPrior = BayesianMaintenancePrior(
        meanCalories: 2200,
        stdDevCalories: 150,
        source: BayesianPriorSource.chainedPosterior,
      );

      final estimate = estimator.estimate(
        input: input,
        chainedPrior: chainedPrior,
      );

      expect(estimate.profilePriorMaintenanceCalories, 2600);
      expect(estimate.priorMeanUsedCalories, closeTo(2200, 0.001));
      expect(estimate.priorStdDevUsedCalories, closeTo(150, 0.001));
      expect(estimate.priorSource, BayesianPriorSource.chainedPosterior);
    });

    test('uncertainty narrows with better data quality and volume', () {
      final sparse = _input(
        priorMaintenanceCalories: 2400,
        avgLoggedCalories: 2350,
        smoothedWeightSlopeKgPerWeek: -0.05,
        windowDays: 7,
        weightLogCount: 3,
        intakeLoggedDays: 3,
      );
      final dense = _input(
        priorMaintenanceCalories: 2400,
        avgLoggedCalories: 2350,
        smoothedWeightSlopeKgPerWeek: -0.05,
        windowDays: 21,
        weightLogCount: 12,
        intakeLoggedDays: 18,
      );

      final sparseEstimate = estimator.estimate(input: sparse);
      final denseEstimate = estimator.estimate(input: dense);

      expect(
        denseEstimate.posteriorStdDevCalories,
        lessThan(sparseEstimate.posteriorStdDevCalories),
      );
      expect(
        denseEstimate.effectiveSampleSize,
        greaterThan(sparseEstimate.effectiveSampleSize),
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
