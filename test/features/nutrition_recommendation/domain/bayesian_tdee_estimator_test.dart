import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_models.dart';

void main() {
  group('BayesianTdeeEstimator recursive filter', () {
    const estimator = BayesianTdeeEstimator();
    const defaultConfig = BayesianEstimatorConfig();

    test('first update initializes with P0 = min(10 * R_initial, P_cap)', () {
      final run = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2500,
          avgLoggedCalories: 2250,
          smoothedWeightSlopeKgPerWeek: -0.15,
          windowDays: 21,
          weightLogCount: 10,
          intakeLoggedDays: 16,
        ),
        dueWeekKey: '2026-04-06',
      );

      final priorVariance = _debugDouble(
        run.estimate,
        'priorVarianceCalories2',
      );
      final referenceR = _debugDouble(
            run.estimate,
            'observationBaseVarianceCalories2',
          ) +
          _debugDouble(run.estimate, 'observationIntakeVarianceCalories2') +
          _debugDouble(run.estimate, 'observationSlopeVarianceCalories2');
      final cap = _debugDouble(run.estimate, 'varianceCapCalories2');
      final expectedP0 = math.min(
        defaultConfig.initialVarianceMultiplier * referenceR,
        cap,
      );

      expect(
        priorVariance,
        closeTo(expectedP0, 0.0001),
      );
      expect(
          run.estimate.priorSource, BayesianPriorSource.profilePriorBootstrap);
      expect(run.estimate.priorMeanUsedCalories, closeTo(2500, 0.0001));
    });

    test('recursive posterior from week N becomes prior for week N+1', () {
      final week1 = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2500,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.20,
          windowDays: 21,
          weightLogCount: 10,
          intakeLoggedDays: 16,
        ),
        dueWeekKey: '2026-04-06',
      );

      final week2 = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2500,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.10,
          windowDays: 21,
          weightLogCount: 10,
          intakeLoggedDays: 16,
        ),
        recursiveState: week1.nextState,
        dueWeekKey: '2026-04-13',
      );

      expect(week2.estimate.priorSource, BayesianPriorSource.chainedPosterior);
      expect(
        week2.estimate.priorMeanUsedCalories,
        closeTo(week1.estimate.posteriorMaintenanceCalories, 0.0001),
      );
      expect(
        week2.estimate.priorStdDevUsedCalories,
        closeTo(week1.nextState.posteriorStdDevCalories, 0.0001),
      );
      expect(
        _debugDouble(week2.estimate, 'predictedVarianceCalories2'),
        greaterThan(_debugDouble(week2.estimate, 'priorVarianceCalories2')),
      );
    });

    test('same due week replay is deterministic and does not drift', () {
      final first = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2400,
          avgLoggedCalories: 2250,
          smoothedWeightSlopeKgPerWeek: -0.05,
          windowDays: 21,
          weightLogCount: 10,
          intakeLoggedDays: 16,
        ),
        dueWeekKey: '2026-04-06',
      );

      final replay = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2400,
          avgLoggedCalories: 2250,
          smoothedWeightSlopeKgPerWeek: -0.05,
          windowDays: 21,
          weightLogCount: 10,
          intakeLoggedDays: 16,
        ),
        recursiveState: first.nextState,
        dueWeekKey: '2026-04-06',
      );

      expect(
        replay.estimate.priorMeanUsedCalories,
        closeTo(first.estimate.priorMeanUsedCalories, 0.0001),
      );
      expect(
        replay.estimate.priorStdDevUsedCalories,
        closeTo(first.estimate.priorStdDevUsedCalories, 0.0001),
      );
      expect(
        replay.estimate.posteriorMaintenanceCalories,
        closeTo(first.estimate.posteriorMaintenanceCalories, 0.0001),
      );
    });

    test('no-observation week performs prediction-only and increases variance',
        () {
      final week1 = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2500,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.2,
          windowDays: 21,
          weightLogCount: 10,
          intakeLoggedDays: 16,
        ),
        dueWeekKey: '2026-04-06',
      );

      final week2NoObs = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2500,
          avgLoggedCalories: 0,
          smoothedWeightSlopeKgPerWeek: null,
          windowDays: 7,
          weightLogCount: 0,
          intakeLoggedDays: 0,
        ),
        recursiveState: week1.nextState,
        dueWeekKey: '2026-04-13',
      );

      final q = _debugDouble(week2NoObs.estimate, 'qVarianceCalories2');
      final priorVar =
          _debugDouble(week2NoObs.estimate, 'priorVarianceCalories2');
      final cap = _debugDouble(week2NoObs.estimate, 'varianceCapCalories2');
      final predictedVar =
          _debugDouble(week2NoObs.estimate, 'predictedVarianceCalories2');

      expect(
        week2NoObs.estimate.observationImpliedMaintenanceCalories,
        isNull,
      );
      expect(_debugDouble(week2NoObs.estimate, 'kalmanGain'), 0);
      expect(
        week2NoObs.estimate.posteriorMaintenanceCalories,
        closeTo(week1.estimate.posteriorMaintenanceCalories, 0.0001),
      );
      expect(predictedVar, closeTo(math.min(priorVar + q, cap), 0.0001));
      expect(
        _debugDouble(week2NoObs.estimate, 'posteriorVarianceCalories2'),
        closeTo(predictedVar, 0.0001),
      );
    });

    test('repeated no-observation weeks are bounded by variance cap', () {
      const cappedEstimator = BayesianTdeeEstimator(
        config: BayesianEstimatorConfig(
          weeklyMaintenanceDriftCalories: 400,
          initialVarianceMultiplier: 1,
          varianceCapMultiplier: 2,
        ),
      );
      var run = cappedEstimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2500,
          avgLoggedCalories: 2250,
          smoothedWeightSlopeKgPerWeek: -0.2,
          windowDays: 21,
          weightLogCount: 10,
          intakeLoggedDays: 16,
        ),
        dueWeekKey: '2026-04-06',
      );

      var due = DateTime(2026, 4, 13);
      for (var i = 0; i < 24; i++) {
        run = cappedEstimator.estimate(
          input: _input(
            priorMaintenanceCalories: 2500,
            avgLoggedCalories: 0,
            smoothedWeightSlopeKgPerWeek: null,
            windowDays: 7,
            weightLogCount: 0,
            intakeLoggedDays: 0,
          ),
          recursiveState: run.nextState,
          dueWeekKey: _dueWeekKey(due),
        );
        due = due.add(const Duration(days: 7));
      }

      final cap = _debugDouble(run.estimate, 'varianceCapCalories2');
      final postVar = _debugDouble(run.estimate, 'posteriorVarianceCalories2');
      expect(postVar, lessThanOrEqualTo(cap + 0.0001));
      expect(postVar, greaterThan(cap * 0.90));
    });

    test('steady-state gain formula matches closed form', () {
      const q = 1600.0;
      const r = 64000.0;
      final expected = (math.sqrt((q * q) + (4 * q * r)) - q) / (2 * r);
      final gain = BayesianTdeeEstimator.steadyStateKalmanGain(
        processVariance: q,
        observationVariance: r,
      );
      final variance = BayesianTdeeEstimator.steadyStatePosteriorVariance(
        processVariance: q,
        observationVariance: r,
      );

      expect(gain, closeTo(expected, 0.0000001));
      expect(variance, closeTo(gain * r, 0.0000001));
    });

    test('effective kcalPerKg scales with window horizon', () {
      final short = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2400,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.2,
          windowDays: 10,
          weightLogCount: 8,
          intakeLoggedDays: 8,
        ),
        dueWeekKey: '2026-04-06',
      );
      final transition = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2400,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.2,
          windowDays: 21,
          weightLogCount: 8,
          intakeLoggedDays: 8,
        ),
        dueWeekKey: '2026-04-06',
      );
      final mature = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2400,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.2,
          windowDays: 35,
          weightLogCount: 8,
          intakeLoggedDays: 8,
        ),
        dueWeekKey: '2026-04-06',
      );

      final shortKcal = _debugDouble(short.estimate, 'effectiveKcalPerKg');
      final transitionKcal =
          _debugDouble(transition.estimate, 'effectiveKcalPerKg');
      final matureKcal = _debugDouble(mature.estimate, 'effectiveKcalPerKg');

      expect(shortKcal, closeTo(5500, 0.0001));
      expect(transitionKcal, greaterThan(5500));
      expect(transitionKcal, lessThan(7700));
      expect(matureKcal, closeTo(7700, 0.0001));
    });

    test('posterior stays closer to prior when R is high (sparse data)', () {
      final stronger = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2600,
          avgLoggedCalories: 2000,
          smoothedWeightSlopeKgPerWeek: -0.1,
          windowDays: 28,
          weightLogCount: 12,
          intakeLoggedDays: 20,
        ),
        dueWeekKey: '2026-04-06',
      );
      final sparse = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2600,
          avgLoggedCalories: 2000,
          smoothedWeightSlopeKgPerWeek: -0.1,
          windowDays: 7,
          weightLogCount: 3,
          intakeLoggedDays: 3,
          qualityFlags: const ['unresolved_food_calories'],
        ),
        dueWeekKey: '2026-04-06',
      );

      final strongMove =
          (stronger.estimate.posteriorMaintenanceCalories - 2600).abs();
      final sparseMove =
          (sparse.estimate.posteriorMaintenanceCalories - 2600).abs();
      final strongR = _debugDouble(stronger.estimate, 'rVarianceCalories2');
      final sparseR = _debugDouble(sparse.estimate, 'rVarianceCalories2');
      final strongK = _debugDouble(stronger.estimate, 'kalmanGain');
      final sparseK = _debugDouble(sparse.estimate, 'kalmanGain');

      expect(sparseR, greaterThan(strongR));
      expect(sparseMove, lessThan(strongMove));
      expect(strongK, greaterThan(sparseK));
    });

    test('deterministic repeated runs with identical weekly sequence', () {
      final weeks =
          <({String dueWeekKey, RecommendationGenerationInput input})>[
        (
          dueWeekKey: '2026-04-06',
          input: _input(
            priorMaintenanceCalories: 2500,
            avgLoggedCalories: 2200,
            smoothedWeightSlopeKgPerWeek: -0.2,
            windowDays: 21,
            weightLogCount: 10,
            intakeLoggedDays: 16,
          ),
        ),
        (
          dueWeekKey: '2026-04-13',
          input: _input(
            priorMaintenanceCalories: 2500,
            avgLoggedCalories: 0,
            smoothedWeightSlopeKgPerWeek: null,
            windowDays: 7,
            weightLogCount: 0,
            intakeLoggedDays: 0,
          ),
        ),
        (
          dueWeekKey: '2026-04-20',
          input: _input(
            priorMaintenanceCalories: 2500,
            avgLoggedCalories: 2300,
            smoothedWeightSlopeKgPerWeek: -0.05,
            windowDays: 21,
            weightLogCount: 9,
            intakeLoggedDays: 14,
          ),
        ),
      ];

      final firstPass = _runSequence(estimator, weeks);
      final secondPass = _runSequence(estimator, weeks);

      for (var i = 0; i < firstPass.length; i++) {
        final first = firstPass[i];
        final second = secondPass[i];
        expect(
          second.estimate.posteriorMaintenanceCalories,
          closeTo(first.estimate.posteriorMaintenanceCalories, 0.000001),
        );
        expect(
          _debugDouble(second.estimate, 'posteriorVarianceCalories2'),
          closeTo(_debugDouble(first.estimate, 'posteriorVarianceCalories2'),
              0.000001),
        );
        expect(second.estimate.confidence, first.estimate.confidence);
      }
    });
  });
}

List<BayesianEstimatorRunResult> _runSequence(
  BayesianTdeeEstimator estimator,
  List<({String dueWeekKey, RecommendationGenerationInput input})> weeks,
) {
  final results = <BayesianEstimatorRunResult>[];
  BayesianEstimatorState? state;
  for (final week in weeks) {
    final result = estimator.estimate(
      input: week.input,
      recursiveState: state,
      dueWeekKey: week.dueWeekKey,
    );
    results.add(result);
    state = result.nextState;
  }
  return results;
}

double _debugDouble(BayesianMaintenanceEstimate estimate, String key) {
  final value = estimate.debugInfo[key];
  if (value is num) {
    return value.toDouble();
  }
  throw StateError('Missing numeric debug key: $key');
}

String _dueWeekKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

RecommendationGenerationInput _input({
  required int priorMaintenanceCalories,
  required double avgLoggedCalories,
  required double? smoothedWeightSlopeKgPerWeek,
  required int windowDays,
  required int weightLogCount,
  required int intakeLoggedDays,
  List<String> qualityFlags = const <String>[],
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
    qualityFlags: qualityFlags,
  );
}
