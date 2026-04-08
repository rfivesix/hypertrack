import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/adaptive_diet_phase.dart';
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

    test('phase ramp uses 3000 kcalPerKg in confirmed phase week 1', () {
      final week1 = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2400,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.2,
          windowDays: 21,
          weightLogCount: 8,
          intakeLoggedDays: 8,
        ),
        dueWeekKey: '2026-04-06',
        phaseContext: _phaseContext(confirmedPhaseAgeDays: 1),
      );

      expect(_debugDouble(week1.estimate, 'effectiveKcalPerKg'),
          closeTo(3000, 0.0001));
    });

    test('phase ramp increases linearly and monotonically with phase age', () {
      final week1 = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2400,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.2,
          windowDays: 14,
          weightLogCount: 8,
          intakeLoggedDays: 8,
        ),
        dueWeekKey: '2026-04-06',
        phaseContext: _phaseContext(confirmedPhaseAgeDays: 1),
      );
      final week5 = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2400,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.2,
          windowDays: 14,
          weightLogCount: 8,
          intakeLoggedDays: 8,
        ),
        dueWeekKey: '2026-04-06',
        phaseContext: _phaseContext(confirmedPhaseAgeDays: 29),
      );
      final week8 = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2400,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.2,
          windowDays: 14,
          weightLogCount: 8,
          intakeLoggedDays: 8,
        ),
        dueWeekKey: '2026-04-06',
        phaseContext: _phaseContext(confirmedPhaseAgeDays: 50),
      );

      final week1Kcal = _debugDouble(week1.estimate, 'effectiveKcalPerKg');
      final week5Kcal = _debugDouble(week5.estimate, 'effectiveKcalPerKg');
      final week8Kcal = _debugDouble(week8.estimate, 'effectiveKcalPerKg');

      expect(week1Kcal, closeTo(3000, 0.0001));
      expect(week5Kcal, closeTo(5350, 0.0001));
      expect(week8Kcal, closeTo(7112.5, 0.001));
      expect(week5Kcal, greaterThan(week1Kcal));
      expect(week8Kcal, greaterThan(week5Kcal));
    });

    test('phase ramp reaches 7700 by week 9 and stays there', () {
      final week9 = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2400,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.2,
          windowDays: 21,
          weightLogCount: 8,
          intakeLoggedDays: 8,
        ),
        dueWeekKey: '2026-04-06',
        phaseContext: _phaseContext(confirmedPhaseAgeDays: 57),
      );
      final week14 = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2400,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.2,
          windowDays: 21,
          weightLogCount: 8,
          intakeLoggedDays: 8,
        ),
        dueWeekKey: '2026-04-06',
        phaseContext: _phaseContext(confirmedPhaseAgeDays: 99),
      );

      expect(_debugDouble(week9.estimate, 'effectiveKcalPerKg'),
          closeTo(7700, 0.0001));
      expect(_debugDouble(week14.estimate, 'effectiveKcalPerKg'),
          closeTo(7700, 0.0001));
    });

    test('phase ramp depends on confirmed phase age, not window length', () {
      final shortWindow = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2400,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.2,
          windowDays: 7,
          weightLogCount: 8,
          intakeLoggedDays: 8,
        ),
        dueWeekKey: '2026-04-06',
        phaseContext: _phaseContext(confirmedPhaseAgeDays: 29),
      );
      final longWindow = estimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2400,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.2,
          windowDays: 35,
          weightLogCount: 8,
          intakeLoggedDays: 8,
        ),
        dueWeekKey: '2026-04-06',
        phaseContext: _phaseContext(confirmedPhaseAgeDays: 29),
      );

      final shortKcal =
          _debugDouble(shortWindow.estimate, 'effectiveKcalPerKg');
      final longKcal = _debugDouble(longWindow.estimate, 'effectiveKcalPerKg');
      expect(shortKcal, closeTo(longKcal, 0.0001));
      expect(shortKcal, closeTo(5350, 0.0001));
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

    test(
        'history-calibrated R is higher for noisy residual histories and widens interval',
        () {
      const calibratedEstimator = BayesianTdeeEstimator(
        config: BayesianEstimatorConfig(
          minimumHistorySamplesForCalibration: 3,
          residualHistoryInfluenceOnR: 1.0,
          posteriorDriftHistoryInfluenceOnQ: 0.0,
        ),
      );
      const stableState = BayesianEstimatorState(
        posteriorMeanCalories: 2475,
        posteriorVarianceCalories2: 42000,
        lastDueWeekKey: '2026-04-06',
        lastPriorMeanCalories: 2460,
        lastPriorVarianceCalories2: 45000,
        lastPriorSource: BayesianPriorSource.chainedPosterior,
        lastObservationUsed: true,
        recentPosteriorMeansCalories: <double>[2460, 2470, 2472, 2475],
        recentObservationResidualsCalories: <double>[12, -10, 15, -8],
      );
      const noisyState = BayesianEstimatorState(
        posteriorMeanCalories: 2475,
        posteriorVarianceCalories2: 42000,
        lastDueWeekKey: '2026-04-06',
        lastPriorMeanCalories: 2460,
        lastPriorVarianceCalories2: 45000,
        lastPriorSource: BayesianPriorSource.chainedPosterior,
        lastObservationUsed: true,
        recentPosteriorMeansCalories: <double>[2460, 2470, 2472, 2475],
        recentObservationResidualsCalories: <double>[520, -510, 540, -530],
      );

      final stable = calibratedEstimator
          .estimate(
            input: _input(
              priorMaintenanceCalories: 2500,
              avgLoggedCalories: 2300,
              smoothedWeightSlopeKgPerWeek: -0.06,
              windowDays: 28,
              weightLogCount: 12,
              intakeLoggedDays: 20,
            ),
            recursiveState: stableState,
            dueWeekKey: '2026-04-13',
          )
          .estimate;
      final noisy = calibratedEstimator
          .estimate(
            input: _input(
              priorMaintenanceCalories: 2500,
              avgLoggedCalories: 2300,
              smoothedWeightSlopeKgPerWeek: -0.06,
              windowDays: 28,
              weightLogCount: 12,
              intakeLoggedDays: 20,
            ),
            recursiveState: noisyState,
            dueWeekKey: '2026-04-13',
          )
          .estimate;

      expect(
          stable.qualityFlags, contains('bayesian_r_calibrated_from_history'));
      expect(
          noisy.qualityFlags, contains('bayesian_r_calibrated_from_history'));
      expect(
        _debugDouble(noisy, 'rCalibrationScaleFromHistory'),
        greaterThan(_debugDouble(stable, 'rCalibrationScaleFromHistory')),
      );
      expect(
        _debugDouble(noisy, 'rVarianceCalories2'),
        greaterThan(_debugDouble(stable, 'rVarianceCalories2')),
      );
      expect(
        noisy.credibleIntervalWidthCalories(),
        greaterThan(stable.credibleIntervalWidthCalories()),
      );
    });

    test('history-calibrated Q reacts to drift and remains bounded', () {
      const config = BayesianEstimatorConfig(
        minimumHistorySamplesForCalibration: 3,
        residualHistoryInfluenceOnR: 0.0,
        posteriorDriftHistoryInfluenceOnQ: 1.0,
      );
      const qEstimator = BayesianTdeeEstimator(config: config);
      const stableState = BayesianEstimatorState(
        posteriorMeanCalories: 2410,
        posteriorVarianceCalories2: 42000,
        lastDueWeekKey: '2026-04-06',
        lastPriorMeanCalories: 2400,
        lastPriorVarianceCalories2: 45000,
        lastPriorSource: BayesianPriorSource.chainedPosterior,
        lastObservationUsed: true,
        recentPosteriorMeansCalories: <double>[2400, 2410, 2405, 2408, 2409],
      );
      const driftingState = BayesianEstimatorState(
        posteriorMeanCalories: 2800,
        posteriorVarianceCalories2: 42000,
        lastDueWeekKey: '2026-04-06',
        lastPriorMeanCalories: 2600,
        lastPriorVarianceCalories2: 45000,
        lastPriorSource: BayesianPriorSource.chainedPosterior,
        lastObservationUsed: true,
        recentPosteriorMeansCalories: <double>[2200, 2420, 2650, 2850, 3050],
      );

      final stable = qEstimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2500,
          avgLoggedCalories: 2300,
          smoothedWeightSlopeKgPerWeek: -0.05,
          windowDays: 28,
          weightLogCount: 12,
          intakeLoggedDays: 20,
        ),
        recursiveState: stableState,
        dueWeekKey: '2026-04-13',
      );
      final drifting = qEstimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2500,
          avgLoggedCalories: 2300,
          smoothedWeightSlopeKgPerWeek: -0.05,
          windowDays: 28,
          weightLogCount: 12,
          intakeLoggedDays: 20,
        ),
        recursiveState: driftingState,
        dueWeekKey: '2026-04-13',
      );

      final stableScale =
          _debugDouble(stable.estimate, 'qCalibrationScaleFromHistory');
      final driftingScale =
          _debugDouble(drifting.estimate, 'qCalibrationScaleFromHistory');
      expect(stable.estimate.qualityFlags,
          contains('bayesian_q_calibrated_from_history'));
      expect(
        drifting.estimate.qualityFlags,
        contains('bayesian_q_calibrated_from_history'),
      );
      expect(stableScale, greaterThanOrEqualTo(config.minimumHistoricalQScale));
      expect(driftingScale, lessThanOrEqualTo(config.maximumHistoricalQScale));
      expect(driftingScale, greaterThan(stableScale));
      expect(
        _debugDouble(drifting.estimate, 'qVarianceCalories2'),
        greaterThan(_debugDouble(stable.estimate, 'qVarianceCalories2')),
      );
    });

    test('calibration falls back safely when history is insufficient', () {
      const fallbackEstimator = BayesianTdeeEstimator(
        config: BayesianEstimatorConfig(
          minimumHistorySamplesForCalibration: 6,
        ),
      );
      const sparseState = BayesianEstimatorState(
        posteriorMeanCalories: 2450,
        posteriorVarianceCalories2: 45000,
        lastDueWeekKey: '2026-04-06',
        lastPriorMeanCalories: 2440,
        lastPriorVarianceCalories2: 50000,
        lastPriorSource: BayesianPriorSource.chainedPosterior,
        lastObservationUsed: true,
        recentPosteriorMeansCalories: <double>[2440, 2450],
        recentObservationResidualsCalories: <double>[20, -15],
      );

      final run = fallbackEstimator.estimate(
        input: _input(
          priorMaintenanceCalories: 2450,
          avgLoggedCalories: 2325,
          smoothedWeightSlopeKgPerWeek: -0.05,
          windowDays: 21,
          weightLogCount: 8,
          intakeLoggedDays: 10,
        ),
        recursiveState: sparseState,
        dueWeekKey: '2026-04-13',
      );

      expect(
          run.estimate.qualityFlags, contains('bayesian_q_default_fallback'));
      expect(
          run.estimate.qualityFlags, contains('bayesian_r_default_fallback'));
      expect(_debugDouble(run.estimate, 'qCalibrationScaleFromHistory'), 1.0);
      expect(_debugDouble(run.estimate, 'rCalibrationScaleFromHistory'), 1.0);
    });

    test('stabilization quality flag is raised for noisy transient regimes',
        () {
      const estimatorWithNoisyHistory = BayesianTdeeEstimator(
        config: BayesianEstimatorConfig(
          minimumHistorySamplesForCalibration: 3,
          residualHistoryInfluenceOnR: 1.0,
        ),
      );
      const priorState = BayesianEstimatorState(
        posteriorMeanCalories: 2480,
        posteriorVarianceCalories2: 60000,
        lastDueWeekKey: '2026-04-06',
        lastPriorMeanCalories: 2460,
        lastPriorVarianceCalories2: 62000,
        lastPriorSource: BayesianPriorSource.chainedPosterior,
        lastObservationUsed: true,
        recentPosteriorMeansCalories: <double>[2440, 2470, 2490, 2500],
        recentObservationResidualsCalories: <double>[
          -520,
          510,
          -540,
          530,
        ],
      );

      final run = estimatorWithNoisyHistory.estimate(
        input: _input(
          priorMaintenanceCalories: 2500,
          avgLoggedCalories: 2200,
          smoothedWeightSlopeKgPerWeek: -0.08,
          windowDays: 21,
          weightLogCount: 8,
          intakeLoggedDays: 8,
        ),
        recursiveState: priorState,
        dueWeekKey: '2026-04-13',
      );

      expect(run.estimate.isStillStabilizing, isTrue);
      expect(
        run.estimate.qualityFlags,
        anyOf(
          contains('bayesian_stabilizing_noisy_regime'),
          contains('bayesian_stabilizing_high_gain'),
          contains('bayesian_stabilizing_high_variance'),
        ),
      );
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

    test('residual bias diagnostics are deterministic and neutral in band', () {
      final summaryA = BayesianResidualBiasDiagnostics.summarize(
        residuals: const <double>[20, -10, 25, -15, 5],
      );
      final summaryB = BayesianResidualBiasDiagnostics.summarize(
        residuals: const <double>[20, -10, 25, -15, 5],
      );

      expect(summaryA.meanResidualCalories,
          closeTo(summaryB.meanResidualCalories, 0.000001));
      expect(summaryA.observationCount, summaryB.observationCount);
      expect(summaryA.status, BayesianResidualBiasStatus.neutral);
    });

    test('residual bias diagnostics detect positive and negative bias', () {
      final positive = BayesianResidualBiasDiagnostics.summarize(
        residuals: const <double>[140, 120, 110, 130],
      );
      final negative = BayesianResidualBiasDiagnostics.summarize(
        residuals: const <double>[-150, -120, -140, -130],
      );

      expect(
        positive.status,
        BayesianResidualBiasStatus.likelyOverestimatingEnergyDensity,
      );
      expect(
        negative.status,
        BayesianResidualBiasStatus.likelyUnderestimatingEnergyDensity,
      );
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

BayesianObservationPhaseContext _phaseContext({
  AdaptiveDietPhase confirmedPhase = AdaptiveDietPhase.cut,
  required int confirmedPhaseAgeDays,
  AdaptiveDietPhase? pendingPhase,
  int? pendingPhaseAgeDays,
}) {
  return BayesianObservationPhaseContext(
    confirmedPhase: confirmedPhase,
    confirmedPhaseAgeDays: confirmedPhaseAgeDays,
    pendingPhase: pendingPhase,
    pendingPhaseAgeDays: pendingPhaseAgeDays,
  );
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
