import 'dart:math' as math;

import 'adaptive_diet_phase.dart';
import 'confidence_models.dart';
import 'recommendation_models.dart';

part 'bayesian/estimator_models.dart';
part 'bayesian/observation_model.dart';
part 'bayesian/regression_engine.dart';

class BayesianTdeeEstimator {
  final BayesianEstimatorConfig config;

  const BayesianTdeeEstimator({
    this.config = const BayesianEstimatorConfig(),
  });

  static double steadyStateKalmanGain({
    required double processVariance,
    required double observationVariance,
  }) {
    if (!processVariance.isFinite ||
        !observationVariance.isFinite ||
        processVariance <= 0 ||
        observationVariance <= 0) {
      return 0;
    }
    final root = math.sqrt(
      (processVariance * processVariance) +
          (4 * processVariance * observationVariance),
    );
    return ((root - processVariance) / (2 * observationVariance))
        .clamp(0.0, 1.0);
  }

  static double steadyStatePosteriorVariance({
    required double processVariance,
    required double observationVariance,
  }) {
    final gain = steadyStateKalmanGain(
      processVariance: processVariance,
      observationVariance: observationVariance,
    );
    return gain * observationVariance;
  }

  BayesianEstimatorRunResult estimate({
    required RecommendationGenerationInput input,
    BayesianEstimatorState? recursiveState,
    String? dueWeekKey,
    BayesianObservationPhaseContext? phaseContext,
  }) {
    final profilePriorMean = input.priorMaintenanceCalories.toDouble();
    final normalizedDueWeekKey = _normalizeDueWeekKey(dueWeekKey);
    final effectivePhaseContext = phaseContext ??
        BayesianObservationPhaseContext.bootstrap(
          phase: AdaptiveDietPhase.maintain,
        );
    final qualityFlags = <String>[
      'bayesian_recursive_filter',
    ];
    final baseQVariance =
        math.pow(config.weeklyMaintenanceDriftCalories, 2).toDouble();

    final observationModel = _buildObservationModel(
      input: input,
      phaseContext: effectivePhaseContext,
    );
    if (!observationModel.hasIntake) {
      qualityFlags.add('bayesian_intake_unavailable');
    }
    if (!observationModel.hasSlope) {
      qualityFlags.add('bayesian_weight_trend_unavailable');
    }
    if (input.qualityFlags.contains('unresolved_food_calories')) {
      qualityFlags.add('unresolved_food_calories');
    }
    if (effectivePhaseContext.hasPendingPhaseChange) {
      qualityFlags.add('bayesian_phase_change_pending_confirmation');
    }

    final hasObservation = observationModel.hasObservation;
    final baseObservationVariance = hasObservation
        ? observationModel.observationVariance
        : observationModel.referenceVariance;
    final noiseCalibration = _calibrateNoiseModel(
      baseQVariance: baseQVariance,
      baseObservationVariance: baseObservationVariance,
      baseReferenceObservationVariance: observationModel.referenceVariance,
      recursiveState: recursiveState,
    );
    final qVariance = noiseCalibration.qVariance;
    final observationVariance = noiseCalibration.observationVariance;

    if (noiseCalibration.usedHistoryForQ) {
      qualityFlags.add('bayesian_q_calibrated_from_history');
    } else {
      qualityFlags.add('bayesian_q_default_fallback');
    }
    if (noiseCalibration.usedHistoryForR) {
      qualityFlags.add('bayesian_r_calibrated_from_history');
    } else {
      qualityFlags.add('bayesian_r_default_fallback');
    }

    final priorStep = _resolvePriorStep(
      profilePriorMeanCalories: profilePriorMean,
      dueWeekKey: normalizedDueWeekKey,
      recursiveState: recursiveState,
      qVariance: qVariance,
      referenceObservationVariance:
          noiseCalibration.referenceObservationVariance,
      qualityFlags: qualityFlags,
    );

    final priorMean = priorStep.priorMeanBeforePrediction;
    final priorVariance = priorStep.priorVarianceBeforePrediction;
    final predictedMean = priorStep.predictedMean;
    final predictedVariance = priorStep.predictedVariance;
    final varianceCap = priorStep.varianceCap;
    final observedMaintenance = observationModel.observedMaintenance;
    final effectiveSampleSize = observationModel.effectiveSampleSize;
    final residualCalories = hasObservation && observedMaintenance != null
        ? observedMaintenance - predictedMean
        : 0.0;

    if (priorStep.priorSource == BayesianPriorSource.chainedPosterior) {
      qualityFlags.add('bayesian_prior_chained_posterior');
    } else {
      qualityFlags.add('bayesian_prior_profile_bootstrap');
    }
    if (priorStep.initializedThisRun) {
      qualityFlags.add('bayesian_filter_initialized');
    }
    if (priorStep.replayedSameWeekPrior) {
      qualityFlags.add('bayesian_prior_replayed_same_due_week');
    }
    if (priorStep.elapsedDueWeeks > 1) {
      qualityFlags.add('bayesian_gap_week_prediction');
    }

    final processVarianceApplied = qVariance * priorStep.appliedPredictionSteps;
    double kalmanGain;
    double posteriorMean;
    double posteriorVariance;

    if (!hasObservation || observedMaintenance == null) {
      kalmanGain = 0;
      posteriorMean = predictedMean;
      posteriorVariance = predictedVariance;
      qualityFlags.add('bayesian_prediction_only_no_observation');
    } else {
      kalmanGain =
          predictedVariance / (predictedVariance + observationVariance);
      posteriorMean =
          predictedMean + (kalmanGain * (observedMaintenance - predictedMean));
      posteriorVariance = (1 - kalmanGain) * predictedVariance;
    }

    final unclampedPosterior = posteriorMean;
    posteriorMean = posteriorMean.clamp(
      config.minimumMaintenanceCalories,
      config.maximumMaintenanceCalories,
    );
    if (posteriorMean != unclampedPosterior) {
      qualityFlags.add('bayesian_posterior_clamped');
    }

    posteriorVariance = posteriorVariance.clamp(1.0, varianceCap);
    final posteriorStdDev = math.sqrt(posteriorVariance);
    if (effectiveSampleSize < 4 && hasObservation) {
      qualityFlags.add('bayesian_sparse_signal');
    }
    if (hasObservation && kalmanGain < 0.25) {
      qualityFlags.add('bayesian_prior_dominant');
    }
    if (posteriorVariance >= varianceCap * 0.85) {
      qualityFlags.add('bayesian_high_uncertainty');
    }

    final steadyStateGain = steadyStateKalmanGain(
      processVariance: qVariance,
      observationVariance: observationVariance,
    );
    final steadyStateVariance = steadyStateGain * observationVariance;

    final rawConfidence = _classifyConfidence(
      hasObservation: hasObservation,
      posteriorVarianceCalories2: posteriorVariance,
      varianceCapCalories2: varianceCap,
      effectiveSampleSize: effectiveSampleSize,
      windowDays: input.windowDays,
    );
    final stabilization = _assessStabilization(
      priorStep: priorStep,
      recursiveState: recursiveState,
      hasObservation: hasObservation,
      effectiveSampleSize: effectiveSampleSize,
      kalmanGain: kalmanGain,
      steadyStateGain: steadyStateGain,
      predictedVariance: predictedVariance,
      steadyStateVariance: steadyStateVariance,
      rScaleFromHistory: noiseCalibration.rScaleFromHistory,
    );
    if (stabilization.isStillStabilizing) {
      qualityFlags.addAll(stabilization.qualityFlags);
      qualityFlags.add('bayesian_estimate_still_stabilizing');
    }
    final confidence = _applyStabilizationConfidenceGuard(
      baseConfidence: rawConfidence,
      stabilization: stabilization,
    );

    final isSameDueWeekReplay = priorStep.sameDueWeek;
    final previousPosteriorHistory =
        recursiveState?.recentPosteriorMeansCalories ?? const <double>[];
    final previousResidualHistory =
        recursiveState?.recentObservationResidualsCalories ?? const <double>[];
    final previousObservationHistory =
        recursiveState?.recentObservationImpliedMaintenanceCalories ??
            const <double>[];

    final nextPosteriorHistory = isSameDueWeekReplay
        ? previousPosteriorHistory
        : _appendRollingHistory(
            existing: previousPosteriorHistory,
            value: posteriorMean,
            maxLength: config.calibrationHistoryWindowWeeks,
          );
    final nextResidualHistory = isSameDueWeekReplay
        ? previousResidualHistory
        : (!hasObservation || observedMaintenance == null)
            ? previousResidualHistory
            : _appendRollingHistory(
                existing: previousResidualHistory,
                value: residualCalories,
                maxLength: config.calibrationHistoryWindowWeeks,
              );
    final nextObservationHistory = isSameDueWeekReplay
        ? previousObservationHistory
        : (!hasObservation || observedMaintenance == null)
            ? previousObservationHistory
            : _appendRollingHistory(
                existing: previousObservationHistory,
                value: observedMaintenance,
                maxLength: config.calibrationHistoryWindowWeeks,
              );

    final residualBiasSummary = BayesianResidualBiasDiagnostics.summarize(
      residuals: nextResidualHistory,
    );
    if (residualBiasSummary.status ==
        BayesianResidualBiasStatus.likelyOverestimatingEnergyDensity) {
      qualityFlags.add(
        'bayesian_residual_bias_likely_overestimating_energy_density',
      );
    }
    if (residualBiasSummary.status ==
        BayesianResidualBiasStatus.likelyUnderestimatingEnergyDensity) {
      qualityFlags.add(
        'bayesian_residual_bias_likely_underestimating_energy_density',
      );
    }

    final estimate = BayesianMaintenanceEstimate(
      posteriorMaintenanceCalories: posteriorMean,
      posteriorStdDevCalories: posteriorStdDev,
      profilePriorMaintenanceCalories: profilePriorMean,
      priorMeanUsedCalories: priorMean,
      priorStdDevUsedCalories: math.sqrt(priorVariance),
      priorSource: priorStep.priorSource,
      observedIntakeCalories:
          observationModel.hasIntake ? input.avgLoggedCalories : null,
      observedWeightSlopeKgPerWeek: input.smoothedWeightSlopeKgPerWeek,
      observationImpliedMaintenanceCalories: observedMaintenance,
      effectiveSampleSize: effectiveSampleSize,
      confidence: confidence,
      qualityFlags: qualityFlags,
      debugInfo: {
        'qBaseVarianceCalories2': baseQVariance,
        'qVarianceCalories2': qVariance,
        'qCalibrationScaleFromHistory': noiseCalibration.qScaleFromHistory,
        'qCalibratedFromHistory': noiseCalibration.usedHistoryForQ,
        'rBaseVarianceCalories2': baseObservationVariance,
        'rVarianceCalories2': observationVariance,
        'rCalibrationScaleFromHistory': noiseCalibration.rScaleFromHistory,
        'rCalibratedFromHistory': noiseCalibration.usedHistoryForR,
        'qOverR': qVariance / math.max(observationVariance, 1.0),
        'priorVarianceCalories2': priorVariance,
        'processVarianceCalories2': processVarianceApplied,
        'predictedVarianceCalories2': predictedVariance,
        'observationVarianceCalories2': observationVariance,
        'posteriorVarianceCalories2': posteriorVariance,
        'kalmanGain': kalmanGain,
        'observationResidualCalories': residualCalories,
        'steadyStateGain': steadyStateGain,
        'steadyStateVarianceCalories2': steadyStateVariance,
        'predictedVsSteadyStateVarianceRatio':
            predictedVariance / math.max(steadyStateVariance, 1.0),
        'liveGainToSteadyStateRatio':
            kalmanGain / math.max(steadyStateGain, 0.000001),
        'effectiveKcalPerKg': observationModel.kcalPerKg,
        'effectiveKcalPerKgMode': observationModel.kcalPerKgMode,
        'confirmedPhase': observationModel.confirmedPhase.name,
        'confirmedPhaseAgeDays': observationModel.confirmedPhaseAgeDays,
        'confirmedPhaseAgeWeeks': observationModel.confirmedPhaseAgeWeeks,
        'confirmedPhaseWeekIndex': observationModel.confirmedPhaseWeekIndex,
        'isPhaseChangePending': observationModel.pendingPhase != null,
        'pendingPhase': observationModel.pendingPhase?.name ?? 'none',
        'pendingPhaseAgeDays': observationModel.pendingPhaseAgeDays ?? 0,
        'pendingPhaseAgeWeeks': observationModel.pendingPhaseAgeWeeks ?? 0.0,
        'varianceCapCalories2': varianceCap,
        'predictionWeeksElapsed': priorStep.elapsedDueWeeks,
        'appliedPredictionSteps': priorStep.appliedPredictionSteps,
        'isSameDueWeekReplay': isSameDueWeekReplay,
        'stabilizationFlags': stabilization.qualityFlags,
        'stabilizationIsActive': stabilization.isStillStabilizing,
        'stabilizationBootstrapPhase': stabilization.bootstrapPhase,
        'observationBaseVarianceCalories2': observationModel.baseVariance,
        'observationIntakeVarianceCalories2': observationModel.intakeVariance,
        'observationSlopeVarianceCalories2': observationModel.slopeVariance,
        'observationCompletenessMultiplier':
            observationModel.completenessMultiplier,
        'observationQualityMultiplier': observationModel.qualityMultiplier,
        'residualBiasMeanCalories': residualBiasSummary.meanResidualCalories,
        'residualBiasObservationCount': residualBiasSummary.observationCount,
        'residualBiasStatus': residualBiasSummary.status.name,
      },
      dueWeekKey: normalizedDueWeekKey,
    );

    final nextState = BayesianEstimatorState(
      posteriorMeanCalories: posteriorMean,
      posteriorVarianceCalories2: posteriorVariance,
      lastDueWeekKey: normalizedDueWeekKey ?? '',
      lastPriorMeanCalories: priorMean,
      lastPriorVarianceCalories2: priorVariance,
      lastPriorSource: priorStep.priorSource,
      lastObservationUsed: hasObservation,
      recentPosteriorMeansCalories: nextPosteriorHistory,
      recentObservationResidualsCalories: nextResidualHistory,
      recentObservationImpliedMaintenanceCalories: nextObservationHistory,
    );

    return BayesianEstimatorRunResult(
      estimate: estimate,
      nextState: nextState,
    );
  }
}
