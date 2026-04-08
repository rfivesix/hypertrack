import 'dart:math' as math;

import 'adaptive_diet_phase.dart';
import 'confidence_models.dart';
import 'recommendation_models.dart';

enum BayesianPriorSource {
  profilePriorBootstrap,
  chainedPosterior,
}

class BayesianEstimatorConfig {
  /// Bootstrap prior uncertainty (kcal/day, standard deviation).
  ///
  /// Retained for backward compatibility and migration fallback.
  final double priorStdDevCalories;

  /// Expected week-to-week latent maintenance drift (kcal/day).
  ///
  /// `Q = weeklyMaintenanceDriftCalories^2`.
  /// Defaults to ~40 kcal/week (inside the requested 30-50 range).
  final double weeklyMaintenanceDriftCalories;

  /// Baseline observation noise floor (kcal/day, standard deviation).
  ///
  /// Represents residual model mismatch even with mature, dense logs.
  final double baseObservationStdDevCalories;

  /// Intake day-to-day variability (kcal/day, standard deviation).
  ///
  /// Reduced by sqrt(intake logged days) inside observation variance.
  final double intakeDayStdDevCalories;

  /// Weight-slope uncertainty (kg/week, standard deviation).
  ///
  /// Converted into kcal/day uncertainty via effective `kcalPerKg / 7`
  /// and reduced by sqrt(weight signal samples).
  final double weightTrendStdDevKgPerWeek;

  /// Observation-variance multipliers for data quality penalties.
  final double unresolvedFoodVarianceMultiplier;
  final double sparseIntakeVarianceMultiplier;
  final double sparseWeightVarianceMultiplier;

  /// Initialization/cap multipliers against observation reference variance.
  final double initialVarianceMultiplier;
  final double varianceCapMultiplier;

  /// History-based noise calibration settings.
  final int calibrationHistoryWindowWeeks;
  final int minimumHistorySamplesForCalibration;
  final double residualHistoryInfluenceOnR;
  final double posteriorDriftHistoryInfluenceOnQ;
  final double minimumHistoricalRScale;
  final double maximumHistoricalRScale;
  final double minimumHistoricalQScale;
  final double maximumHistoricalQScale;

  /// Confirmed-phase kcal/kg ramp settings for the weekly observation model.
  ///
  /// Week 1 starts at [phaseRampStartKcalPerKg], then ramps linearly to
  /// [phaseRampMatureKcalPerKg] by [phaseRampMatureWeek], and stays there.
  final double phaseRampStartKcalPerKg;
  final double phaseRampMatureKcalPerKg;
  final int phaseRampMatureWeek;

  final double minimumMaintenanceCalories;
  final double maximumMaintenanceCalories;

  /// Conservative defaults tuned for stability in sparse/noisy weekly logs.
  const BayesianEstimatorConfig({
    this.priorStdDevCalories = 420,
    this.weeklyMaintenanceDriftCalories = 40,
    this.baseObservationStdDevCalories = 120,
    this.intakeDayStdDevCalories = 320,
    this.weightTrendStdDevKgPerWeek = 0.55,
    this.unresolvedFoodVarianceMultiplier = 1.30,
    this.sparseIntakeVarianceMultiplier = 1.12,
    this.sparseWeightVarianceMultiplier = 1.10,
    this.initialVarianceMultiplier = 10,
    this.varianceCapMultiplier = 10,
    this.calibrationHistoryWindowWeeks = 8,
    this.minimumHistorySamplesForCalibration = 4,
    this.residualHistoryInfluenceOnR = 0.45,
    this.posteriorDriftHistoryInfluenceOnQ = 0.40,
    this.minimumHistoricalRScale = 0.50,
    this.maximumHistoricalRScale = 2.60,
    this.minimumHistoricalQScale = 0.60,
    this.maximumHistoricalQScale = 1.90,
    this.phaseRampStartKcalPerKg = 3000,
    this.phaseRampMatureKcalPerKg = 7700,
    this.phaseRampMatureWeek = 9,
    this.minimumMaintenanceCalories = 1200,
    this.maximumMaintenanceCalories = 5000,
  });
}

class BayesianEstimatorState {
  static const int currentStateVersion = 2;

  final double posteriorMeanCalories;
  final double posteriorVarianceCalories2;
  final String lastDueWeekKey;
  final double? lastPriorMeanCalories;
  final double? lastPriorVarianceCalories2;
  final BayesianPriorSource? lastPriorSource;
  final bool lastObservationUsed;
  final List<double> recentPosteriorMeansCalories;
  final List<double> recentObservationResidualsCalories;
  final List<double> recentObservationImpliedMaintenanceCalories;
  final int stateVersion;

  const BayesianEstimatorState({
    required this.posteriorMeanCalories,
    required this.posteriorVarianceCalories2,
    required this.lastDueWeekKey,
    required this.lastPriorMeanCalories,
    required this.lastPriorVarianceCalories2,
    required this.lastPriorSource,
    required this.lastObservationUsed,
    this.recentPosteriorMeansCalories = const [],
    this.recentObservationResidualsCalories = const [],
    this.recentObservationImpliedMaintenanceCalories = const [],
    this.stateVersion = currentStateVersion,
  });

  double get posteriorStdDevCalories {
    return math.sqrt(math.max(posteriorVarianceCalories2, 1.0));
  }

  bool get hasReplayPrior {
    return lastPriorMeanCalories != null &&
        lastPriorVarianceCalories2 != null &&
        lastPriorSource != null &&
        lastPriorVarianceCalories2! > 0;
  }

  bool get isValid {
    return posteriorMeanCalories.isFinite &&
        posteriorVarianceCalories2.isFinite &&
        posteriorVarianceCalories2 > 0 &&
        lastDueWeekKey.trim().isNotEmpty &&
        _allFinite(recentPosteriorMeansCalories) &&
        _allFinite(recentObservationResidualsCalories) &&
        _allFinite(recentObservationImpliedMaintenanceCalories);
  }

  Map<String, dynamic> toJson() {
    return {
      'stateVersion': stateVersion,
      'posteriorMeanCalories': posteriorMeanCalories,
      'posteriorVarianceCalories2': posteriorVarianceCalories2,
      'lastDueWeekKey': lastDueWeekKey,
      'lastPriorMeanCalories': lastPriorMeanCalories,
      'lastPriorVarianceCalories2': lastPriorVarianceCalories2,
      'lastPriorSource': lastPriorSource?.name,
      'lastObservationUsed': lastObservationUsed,
      'recentPosteriorMeansCalories': recentPosteriorMeansCalories,
      'recentObservationResidualsCalories': recentObservationResidualsCalories,
      'recentObservationImpliedMaintenanceCalories':
          recentObservationImpliedMaintenanceCalories,
    };
  }

  factory BayesianEstimatorState.fromJson(Map<String, dynamic> json) {
    final rawPriorSource = json['lastPriorSource'] as String?;

    return BayesianEstimatorState(
      posteriorMeanCalories: _asDouble(json['posteriorMeanCalories']) ?? 0,
      posteriorVarianceCalories2:
          _asDouble(json['posteriorVarianceCalories2']) ?? 0,
      lastDueWeekKey: (json['lastDueWeekKey'] as String? ?? '').trim(),
      lastPriorMeanCalories: _asDouble(json['lastPriorMeanCalories']),
      lastPriorVarianceCalories2: _asDouble(json['lastPriorVarianceCalories2']),
      lastPriorSource: rawPriorSource == null
          ? null
          : BayesianPriorSource.values.firstWhere(
              (candidate) => candidate.name == rawPriorSource,
              orElse: () => BayesianPriorSource.chainedPosterior,
            ),
      lastObservationUsed: json['lastObservationUsed'] as bool? ?? false,
      recentPosteriorMeansCalories:
          _asDoubleList(json['recentPosteriorMeansCalories']),
      recentObservationResidualsCalories:
          _asDoubleList(json['recentObservationResidualsCalories']),
      recentObservationImpliedMaintenanceCalories:
          _asDoubleList(json['recentObservationImpliedMaintenanceCalories']),
      stateVersion: json['stateVersion'] as int? ?? currentStateVersion,
    );
  }

  static bool _allFinite(List<double> values) {
    for (final value in values) {
      if (!value.isFinite) {
        return false;
      }
    }
    return true;
  }

  static List<double> _asDoubleList(Object? value) {
    final list = value as List?;
    if (list == null) {
      return const [];
    }
    return list
        .map((item) => _asDouble(item))
        .whereType<double>()
        .where((item) => item.isFinite)
        .toList(growable: false);
  }
}

class BayesianMaintenanceEstimate {
  static const double _legacyDefaultPriorStdDevCalories = 420;
  static const double defaultCredibleIntervalZScore = 1.0;

  final double posteriorMaintenanceCalories;
  final double posteriorStdDevCalories;
  final double profilePriorMaintenanceCalories;
  final double priorMeanUsedCalories;
  final double priorStdDevUsedCalories;
  final BayesianPriorSource priorSource;
  final double? observedIntakeCalories;
  final double? observedWeightSlopeKgPerWeek;
  final double? observationImpliedMaintenanceCalories;
  final double effectiveSampleSize;
  final RecommendationConfidence confidence;
  final List<String> qualityFlags;
  final Map<String, Object> debugInfo;
  final String? dueWeekKey;

  const BayesianMaintenanceEstimate({
    required this.posteriorMaintenanceCalories,
    required this.posteriorStdDevCalories,
    required this.profilePriorMaintenanceCalories,
    required this.priorMeanUsedCalories,
    required this.priorStdDevUsedCalories,
    required this.priorSource,
    required this.observedIntakeCalories,
    required this.observedWeightSlopeKgPerWeek,
    required this.observationImpliedMaintenanceCalories,
    required this.effectiveSampleSize,
    required this.confidence,
    required this.qualityFlags,
    required this.debugInfo,
    required this.dueWeekKey,
  });

  // Legacy alias for older tests/integrations that referred to a single prior.
  double get priorMaintenanceCalories => priorMeanUsedCalories;

  bool get usedChainedPosteriorPrior {
    return priorSource == BayesianPriorSource.chainedPosterior;
  }

  int credibleIntervalLowerCalories({
    double zScore = defaultCredibleIntervalZScore,
  }) {
    final spread = zScore * posteriorStdDevCalories;
    return (posteriorMaintenanceCalories - spread).round();
  }

  int credibleIntervalUpperCalories({
    double zScore = defaultCredibleIntervalZScore,
  }) {
    final spread = zScore * posteriorStdDevCalories;
    return (posteriorMaintenanceCalories + spread).round();
  }

  int credibleIntervalWidthCalories({
    double zScore = defaultCredibleIntervalZScore,
  }) {
    return (2 * zScore * posteriorStdDevCalories).round();
  }

  bool get isStillStabilizing {
    return qualityFlags.contains('bayesian_estimate_still_stabilizing');
  }

  Map<String, dynamic> toJson() {
    return {
      'posteriorMaintenanceCalories': posteriorMaintenanceCalories,
      'posteriorStdDevCalories': posteriorStdDevCalories,
      'profilePriorMaintenanceCalories': profilePriorMaintenanceCalories,
      'priorMeanUsedCalories': priorMeanUsedCalories,
      'priorStdDevUsedCalories': priorStdDevUsedCalories,
      'priorSource': priorSource.name,
      // Legacy key for backward compatibility while reading old payloads.
      'priorMaintenanceCalories': priorMeanUsedCalories,
      'observedIntakeCalories': observedIntakeCalories,
      'observedWeightSlopeKgPerWeek': observedWeightSlopeKgPerWeek,
      'observationImpliedMaintenanceCalories':
          observationImpliedMaintenanceCalories,
      'effectiveSampleSize': effectiveSampleSize,
      'confidence': confidence.name,
      'qualityFlags': qualityFlags,
      'debugInfo': debugInfo,
      'dueWeekKey': dueWeekKey,
    };
  }

  factory BayesianMaintenanceEstimate.fromJson(Map<String, dynamic> json) {
    final debugInfoRaw =
        ((json['debugInfo'] as Map?) ?? const <String, Object>{})
            .cast<String, Object>();
    final confidenceRaw = json['confidence'] as String?;
    final priorSourceRaw = json['priorSource'] as String?;

    final priorMeanUsed = _asDouble(json['priorMeanUsedCalories']) ??
        _asDouble(json['priorMaintenanceCalories']) ??
        0;

    final priorVarianceFromDebug =
        _asDouble(debugInfoRaw['priorVarianceCalories2']);
    final priorStdFromDebug = priorVarianceFromDebug == null ||
            priorVarianceFromDebug.isNaN ||
            priorVarianceFromDebug <= 0
        ? null
        : math.sqrt(priorVarianceFromDebug);

    final priorStdUsed = _asDouble(json['priorStdDevUsedCalories']) ??
        priorStdFromDebug ??
        _legacyDefaultPriorStdDevCalories;

    final profilePrior =
        _asDouble(json['profilePriorMaintenanceCalories']) ?? priorMeanUsed;

    return BayesianMaintenanceEstimate(
      posteriorMaintenanceCalories:
          _asDouble(json['posteriorMaintenanceCalories']) ?? 0,
      posteriorStdDevCalories: _asDouble(json['posteriorStdDevCalories']) ?? 0,
      profilePriorMaintenanceCalories: profilePrior,
      priorMeanUsedCalories: priorMeanUsed,
      priorStdDevUsedCalories: priorStdUsed,
      priorSource: BayesianPriorSource.values.firstWhere(
        (candidate) => candidate.name == priorSourceRaw,
        orElse: () => BayesianPriorSource.profilePriorBootstrap,
      ),
      observedIntakeCalories: _asDouble(json['observedIntakeCalories']),
      observedWeightSlopeKgPerWeek:
          _asDouble(json['observedWeightSlopeKgPerWeek']),
      observationImpliedMaintenanceCalories:
          _asDouble(json['observationImpliedMaintenanceCalories']),
      effectiveSampleSize: _asDouble(json['effectiveSampleSize']) ?? 0,
      confidence: RecommendationConfidence.values.firstWhere(
        (candidate) => candidate.name == confidenceRaw,
        orElse: () => RecommendationConfidence.notEnoughData,
      ),
      qualityFlags: ((json['qualityFlags'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      debugInfo: debugInfoRaw,
      dueWeekKey: json['dueWeekKey'] as String?,
    );
  }

  static double? _asDouble(Object? value) {
    return switch (value) {
      num() => value.toDouble(),
      _ => null,
    };
  }
}

class BayesianEstimatorRunResult {
  final BayesianMaintenanceEstimate estimate;
  final BayesianEstimatorState nextState;

  const BayesianEstimatorRunResult({
    required this.estimate,
    required this.nextState,
  });
}

class BayesianTdeeEstimator {
  final BayesianEstimatorConfig config;

  const BayesianTdeeEstimator({
    this.config = const BayesianEstimatorConfig(),
  });

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
      // Prediction-only week: mean stays at prediction, uncertainty still
      // evolves through the process model (already applied in priorStep).
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

    // Same-week replay should be idempotent: do not append duplicate history
    // points when force-refresh reuses the same due-week prior.
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

  _NoiseCalibration _calibrateNoiseModel({
    required double baseQVariance,
    required double baseObservationVariance,
    required double baseReferenceObservationVariance,
    required BayesianEstimatorState? recursiveState,
  }) {
    final residualHistory =
        recursiveState?.recentObservationResidualsCalories ?? const <double>[];
    final posteriorHistory =
        recursiveState?.recentPosteriorMeansCalories ?? const <double>[];
    final minSamples = config.minimumHistorySamplesForCalibration;

    var qScaleFromHistory = 1.0;
    var rScaleFromHistory = 1.0;
    var usedHistoryForQ = false;
    var usedHistoryForR = false;

    if (residualHistory.length >= minSamples) {
      final residualVariance = _sampleVariance(residualHistory);
      if (residualVariance != null && residualVariance.isFinite) {
        final rawScale =
            residualVariance / math.max(baseObservationVariance, 1);
        rScaleFromHistory = rawScale.clamp(
          config.minimumHistoricalRScale,
          config.maximumHistoricalRScale,
        );
        usedHistoryForR = true;
      }
    }

    if (posteriorHistory.length >= minSamples) {
      final weeklyDeltaRms = _rmsDelta(posteriorHistory);
      if (weeklyDeltaRms != null && weeklyDeltaRms.isFinite) {
        final rawScale = math.pow(
          weeklyDeltaRms / math.max(config.weeklyMaintenanceDriftCalories, 1),
          2,
        );
        qScaleFromHistory = rawScale.toDouble().clamp(
              config.minimumHistoricalQScale,
              config.maximumHistoricalQScale,
            );
        usedHistoryForQ = true;
      }
    }

    final calibratedQVariance = baseQVariance *
        ((1 - config.posteriorDriftHistoryInfluenceOnQ) +
            (config.posteriorDriftHistoryInfluenceOnQ * qScaleFromHistory));
    final calibratedObservationVariance = baseObservationVariance *
        ((1 - config.residualHistoryInfluenceOnR) +
            (config.residualHistoryInfluenceOnR * rScaleFromHistory));
    final calibratedReferenceVariance = baseReferenceObservationVariance *
        ((1 - config.residualHistoryInfluenceOnR) +
            (config.residualHistoryInfluenceOnR * rScaleFromHistory));

    return _NoiseCalibration(
      qVariance: math.max(calibratedQVariance, 1),
      observationVariance: math.max(calibratedObservationVariance, 1),
      referenceObservationVariance: math.max(calibratedReferenceVariance, 1),
      qScaleFromHistory: qScaleFromHistory,
      rScaleFromHistory: rScaleFromHistory,
      usedHistoryForQ: usedHistoryForQ,
      usedHistoryForR: usedHistoryForR,
    );
  }

  _StabilizationAssessment _assessStabilization({
    required _PriorStep priorStep,
    required BayesianEstimatorState? recursiveState,
    required bool hasObservation,
    required double effectiveSampleSize,
    required double kalmanGain,
    required double steadyStateGain,
    required double predictedVariance,
    required double steadyStateVariance,
    required double rScaleFromHistory,
  }) {
    final qualityFlags = <String>[];
    final posteriorHistoryCount =
        recursiveState?.recentPosteriorMeansCalories.length ?? 0;
    final bootstrapPhase =
        priorStep.initializedThisRun || posteriorHistoryCount < 3;

    if (bootstrapPhase) {
      qualityFlags.add('bayesian_stabilizing_bootstrap');
    }

    final gainToSteadyRatio = !hasObservation || steadyStateGain <= 0
        ? 0.0
        : kalmanGain / steadyStateGain;
    if (hasObservation &&
        gainToSteadyRatio > 1.75 &&
        effectiveSampleSize < 12) {
      qualityFlags.add('bayesian_stabilizing_high_gain');
    }

    final varianceToSteadyRatio =
        predictedVariance / math.max(steadyStateVariance, 1);
    if (varianceToSteadyRatio > 2.25) {
      qualityFlags.add('bayesian_stabilizing_high_variance');
    }

    if (rScaleFromHistory > 1.45) {
      qualityFlags.add('bayesian_stabilizing_noisy_regime');
    }

    return _StabilizationAssessment(
      isStillStabilizing: qualityFlags.isNotEmpty,
      bootstrapPhase: bootstrapPhase,
      qualityFlags: qualityFlags,
    );
  }

  RecommendationConfidence _applyStabilizationConfidenceGuard({
    required RecommendationConfidence baseConfidence,
    required _StabilizationAssessment stabilization,
  }) {
    if (!stabilization.isStillStabilizing) {
      return baseConfidence;
    }
    // Keep stabilization conservative without collapsing strong observational
    // runs into "not enough data" too aggressively during normal bootstrap.
    return _downgradeConfidence(baseConfidence);
  }

  RecommendationConfidence _downgradeConfidence(
    RecommendationConfidence confidence,
  ) {
    switch (confidence) {
      case RecommendationConfidence.high:
        return RecommendationConfidence.medium;
      case RecommendationConfidence.medium:
        return RecommendationConfidence.low;
      case RecommendationConfidence.low:
      case RecommendationConfidence.notEnoughData:
        return RecommendationConfidence.notEnoughData;
    }
  }

  List<double> _appendRollingHistory({
    required List<double> existing,
    required double value,
    required int maxLength,
  }) {
    if (!value.isFinite) {
      return existing;
    }
    final normalizedMaxLength = math.max(maxLength, 1);
    final next = <double>[...existing, value];
    if (next.length <= normalizedMaxLength) {
      return next;
    }
    return next.sublist(next.length - normalizedMaxLength);
  }

  double? _sampleVariance(List<double> values) {
    if (values.length < 2) {
      return null;
    }
    final mean = values.reduce((a, b) => a + b) / values.length;
    var sumSquares = 0.0;
    for (final value in values) {
      final delta = value - mean;
      sumSquares += delta * delta;
    }
    return sumSquares / (values.length - 1);
  }

  double? _rmsDelta(List<double> values) {
    if (values.length < 2) {
      return null;
    }
    var sumSquares = 0.0;
    var count = 0;
    for (var i = 1; i < values.length; i++) {
      final delta = values[i] - values[i - 1];
      sumSquares += delta * delta;
      count++;
    }
    if (count == 0) {
      return null;
    }
    return math.sqrt(sumSquares / count);
  }

  _PriorStep _resolvePriorStep({
    required double profilePriorMeanCalories,
    required String? dueWeekKey,
    required BayesianEstimatorState? recursiveState,
    required double qVariance,
    required double referenceObservationVariance,
    required List<String> qualityFlags,
  }) {
    final varianceCap = math.max(
      config.varianceCapMultiplier * referenceObservationVariance,
      1.0,
    );

    if (recursiveState != null && recursiveState.isValid) {
      final normalizedLastDueWeekKey = _normalizeDueWeekKey(
        recursiveState.lastDueWeekKey,
      );
      final sameDueWeek = dueWeekKey != null &&
          normalizedLastDueWeekKey == dueWeekKey &&
          dueWeekKey.isNotEmpty;

      // Same due-week force refresh should replay that week's pre-update prior
      // so repeated in-week runs remain deterministic.
      final priorMean = sameDueWeek && recursiveState.hasReplayPrior
          ? recursiveState.lastPriorMeanCalories!
          : recursiveState.posteriorMeanCalories;
      final rawPriorVariance = sameDueWeek && recursiveState.hasReplayPrior
          ? recursiveState.lastPriorVarianceCalories2!
          : recursiveState.posteriorVarianceCalories2;
      final priorVariance = _clampVariance(
        rawPriorVariance,
        maxVariance: varianceCap,
      );
      final priorSource = sameDueWeek && recursiveState.hasReplayPrior
          ? recursiveState.lastPriorSource!
          : BayesianPriorSource.chainedPosterior;
      final elapsedDueWeeks = sameDueWeek
          ? 0
          : _elapsedDueWeeksBetween(
              fromDueWeekKey: normalizedLastDueWeekKey,
              toDueWeekKey: dueWeekKey,
            );

      var predictedVariance = priorVariance;
      // Apply one prediction step per elapsed due week to chain uncertainty
      // growth while retaining memory via the variance cap.
      for (var i = 0; i < elapsedDueWeeks; i++) {
        predictedVariance =
            math.min(predictedVariance + qVariance, varianceCap);
      }

      if (!sameDueWeek && dueWeekKey != null && dueWeekKey.isNotEmpty) {
        qualityFlags.add('bayesian_prediction_step_applied');
      }

      return _PriorStep(
        priorMeanBeforePrediction: priorMean,
        priorVarianceBeforePrediction: priorVariance,
        predictedMean: priorMean,
        predictedVariance: predictedVariance,
        priorSource: priorSource,
        appliedPredictionSteps: elapsedDueWeeks,
        elapsedDueWeeks: elapsedDueWeeks,
        varianceCap: varianceCap,
        initializedThisRun: false,
        replayedSameWeekPrior: sameDueWeek && recursiveState.hasReplayPrior,
        sameDueWeek: sameDueWeek,
      );
    }

    final clampedProfileMean = profilePriorMeanCalories.clamp(
      config.minimumMaintenanceCalories,
      config.maximumMaintenanceCalories,
    );
    final initialVariance = _clampVariance(
      config.initialVarianceMultiplier * referenceObservationVariance,
      maxVariance: varianceCap,
    );

    return _PriorStep(
      priorMeanBeforePrediction: clampedProfileMean,
      priorVarianceBeforePrediction: initialVariance,
      predictedMean: clampedProfileMean,
      predictedVariance: initialVariance,
      priorSource: BayesianPriorSource.profilePriorBootstrap,
      appliedPredictionSteps: 0,
      elapsedDueWeeks: 0,
      varianceCap: varianceCap,
      initializedThisRun: true,
      replayedSameWeekPrior: false,
      sameDueWeek: false,
    );
  }

  _ObservationModel _buildObservationModel({
    required RecommendationGenerationInput input,
    required BayesianObservationPhaseContext phaseContext,
  }) {
    final hasSlope = input.smoothedWeightSlopeKgPerWeek != null;
    final hasIntake = input.intakeLoggedDays > 0;
    final hasObservation = hasSlope && hasIntake;
    final kcalPerKgSelection = _resolveKcalPerKg(
      phaseContext: phaseContext,
    );
    final kcalPerKgPerDay = kcalPerKgSelection.kcalPerKg / 7;

    final baseVariance =
        math.pow(config.baseObservationStdDevCalories, 2).toDouble();
    final intakeStdError = config.intakeDayStdDevCalories /
        math.sqrt(math.max(input.intakeLoggedDays, 1));
    final intakeVariance = math.pow(intakeStdError, 2).toDouble();

    final weightSignalDays = math.max(input.weightLogCount - 1, 1);
    final slopeStdErrorCalories =
        (config.weightTrendStdDevKgPerWeek * kcalPerKgPerDay) /
            math.sqrt(weightSignalDays);
    final slopeVariance = math.pow(slopeStdErrorCalories, 2).toDouble();

    final referenceVariance = math.max(
      baseVariance + intakeVariance + slopeVariance,
      1.0,
    );

    final usableWindowDays = math.max(input.windowDays, 1);
    final intakeCompleteness =
        (input.intakeLoggedDays / usableWindowDays).clamp(0.05, 1.0);
    final weightCompleteness = ((math.max(input.weightLogCount - 1, 0)) /
            math.max(usableWindowDays - 1, 1))
        .clamp(0.05, 1.0);
    final completenessMultiplier =
        1 / math.sqrt(intakeCompleteness * weightCompleteness);

    var qualityMultiplier = 1.0;
    if (input.intakeLoggedDays < 5) {
      qualityMultiplier *= config.sparseIntakeVarianceMultiplier;
    }
    if (input.weightLogCount < 5) {
      qualityMultiplier *= config.sparseWeightVarianceMultiplier;
    }
    if (input.qualityFlags.contains('unresolved_food_calories')) {
      qualityMultiplier *= config.unresolvedFoodVarianceMultiplier;
    }

    final observationVariance = math.max(
      referenceVariance *
          completenessMultiplier *
          completenessMultiplier *
          qualityMultiplier *
          qualityMultiplier,
      1.0,
    );

    final observedMaintenance = hasObservation
        ? input.avgLoggedCalories -
            (input.smoothedWeightSlopeKgPerWeek! * kcalPerKgPerDay)
        : null;

    final confirmedPhaseAgeDays =
        math.max(phaseContext.confirmedPhaseAgeDays, 0);
    final confirmedPhaseAgeWeeks = confirmedPhaseAgeDays <= 0
        ? 0.0
        : ((confirmedPhaseAgeDays - 1) / 7) + 1;
    final confirmedPhaseWeekIndex =
        confirmedPhaseAgeDays <= 0 ? 0 : ((confirmedPhaseAgeDays - 1) ~/ 7) + 1;
    final pendingPhaseAgeDaysRaw = phaseContext.pendingPhaseAgeDays;
    final pendingPhaseAgeDays = pendingPhaseAgeDaysRaw == null
        ? null
        : math.max(pendingPhaseAgeDaysRaw, 0);
    final pendingPhaseAgeWeeks = pendingPhaseAgeDays == null
        ? null
        : pendingPhaseAgeDays <= 0
            ? 0.0
            : ((pendingPhaseAgeDays - 1) / 7) + 1;

    return _ObservationModel(
      hasSlope: hasSlope,
      hasIntake: hasIntake,
      hasObservation: hasObservation,
      observedMaintenance: observedMaintenance,
      observationVariance: observationVariance,
      referenceVariance: referenceVariance,
      effectiveSampleSize: _effectiveSampleSize(
        windowDays: input.windowDays,
        intakeLoggedDays: input.intakeLoggedDays,
        weightLogCount: input.weightLogCount,
        hasObservation: hasObservation,
      ),
      kcalPerKg: kcalPerKgSelection.kcalPerKg,
      kcalPerKgMode: kcalPerKgSelection.mode,
      baseVariance: baseVariance,
      intakeVariance: intakeVariance,
      slopeVariance: slopeVariance,
      completenessMultiplier: completenessMultiplier,
      qualityMultiplier: qualityMultiplier,
      confirmedPhase: phaseContext.confirmedPhase,
      confirmedPhaseAgeDays: confirmedPhaseAgeDays,
      confirmedPhaseAgeWeeks: confirmedPhaseAgeWeeks,
      confirmedPhaseWeekIndex: confirmedPhaseWeekIndex,
      pendingPhase: phaseContext.pendingPhase,
      pendingPhaseAgeDays: pendingPhaseAgeDays,
      pendingPhaseAgeWeeks: pendingPhaseAgeWeeks,
    );
  }

  _KcalPerKgSelection _resolveKcalPerKg({
    required BayesianObservationPhaseContext phaseContext,
  }) {
    final confirmedAgeDays = math.max(phaseContext.confirmedPhaseAgeDays, 1);
    final matureWeek = math.max(config.phaseRampMatureWeek, 2);
    final matureAtAgeDays = 1 + ((matureWeek - 1) * 7);
    final currentWeekIndex = ((confirmedAgeDays - 1) ~/ 7) + 1;

    if (confirmedAgeDays >= matureAtAgeDays) {
      return _KcalPerKgSelection(
        kcalPerKg: config.phaseRampMatureKcalPerKg,
        mode: 'phase_ramp_mature',
      );
    }

    if (currentWeekIndex <= 1) {
      return _KcalPerKgSelection(
        kcalPerKg: config.phaseRampStartKcalPerKg,
        mode: 'phase_ramp_week_1',
      );
    }

    final rampWeeks = math.max(matureWeek - 1, 1);
    final elapsedRampWeeks = ((confirmedAgeDays - 1) / 7)
        .clamp(0.0, rampWeeks.toDouble())
        .toDouble();
    final ratio = (elapsedRampWeeks / rampWeeks).clamp(0.0, 1.0).toDouble();
    return _KcalPerKgSelection(
      kcalPerKg: config.phaseRampStartKcalPerKg +
          ((config.phaseRampMatureKcalPerKg - config.phaseRampStartKcalPerKg) *
              ratio),
      mode: 'phase_ramp_transition',
    );
  }

  String? _normalizeDueWeekKey(String? dueWeekKey) {
    if (dueWeekKey == null) {
      return null;
    }
    final normalized = dueWeekKey.trim();
    return normalized.isEmpty ? null : normalized;
  }

  int _elapsedDueWeeksBetween({
    required String? fromDueWeekKey,
    required String? toDueWeekKey,
  }) {
    if (fromDueWeekKey == null ||
        fromDueWeekKey.isEmpty ||
        toDueWeekKey == null ||
        toDueWeekKey.isEmpty) {
      return 1;
    }
    final fromDate = DateTime.tryParse(fromDueWeekKey);
    final toDate = DateTime.tryParse(toDueWeekKey);
    if (fromDate == null || toDate == null) {
      return 1;
    }
    final dayDiff = toDate.difference(fromDate).inDays;
    if (dayDiff <= 0) {
      return 0;
    }
    return math.max(dayDiff ~/ 7, 1);
  }

  double _clampVariance(
    double variance, {
    required double maxVariance,
  }) {
    if (!variance.isFinite || variance <= 0) {
      return 1.0;
    }
    return variance.clamp(1.0, maxVariance);
  }

  double _effectiveSampleSize({
    required int windowDays,
    required int intakeLoggedDays,
    required int weightLogCount,
    required bool hasObservation,
  }) {
    if (!hasObservation) {
      return 0;
    }

    final intakeSamples = math.max(intakeLoggedDays, 0).toDouble();
    final weightSamples = math.max(weightLogCount - 1, 0).toDouble();
    final usableWindowDays = math.max(windowDays, 0).toDouble();

    if (intakeSamples <= 0 || weightSamples <= 0 || usableWindowDays <= 0) {
      return 0;
    }

    final pairedSignalSamples = math.sqrt(intakeSamples * weightSamples);
    return math.min(usableWindowDays, pairedSignalSamples);
  }

  RecommendationConfidence _classifyConfidence({
    required bool hasObservation,
    required double posteriorVarianceCalories2,
    required double varianceCapCalories2,
    required double effectiveSampleSize,
    required int windowDays,
  }) {
    if (!hasObservation || effectiveSampleSize < 2.5) {
      return RecommendationConfidence.notEnoughData;
    }

    final uncertaintyRatio =
        (posteriorVarianceCalories2 / math.max(varianceCapCalories2, 1.0))
            .clamp(0.0, 1.0);

    if (windowDays >= 21 &&
        effectiveSampleSize >= 10 &&
        uncertaintyRatio <= 0.25) {
      return RecommendationConfidence.high;
    }

    if (windowDays >= 14 &&
        effectiveSampleSize >= 7 &&
        uncertaintyRatio <= 0.45) {
      return RecommendationConfidence.medium;
    }

    if (windowDays >= 7 &&
        effectiveSampleSize >= 4 &&
        uncertaintyRatio <= 0.70) {
      return RecommendationConfidence.low;
    }

    return RecommendationConfidence.notEnoughData;
  }
}

enum BayesianResidualBiasStatus {
  neutral,
  likelyOverestimatingEnergyDensity,
  likelyUnderestimatingEnergyDensity,
}

class BayesianResidualBiasSummary {
  final double meanResidualCalories;
  final int observationCount;
  final BayesianResidualBiasStatus status;

  const BayesianResidualBiasSummary({
    required this.meanResidualCalories,
    required this.observationCount,
    required this.status,
  });
}

class BayesianResidualBiasDiagnostics {
  static const int defaultMinimumObservations = 3;
  static const double defaultNeutralBandCalories = 40;

  const BayesianResidualBiasDiagnostics._();

  static BayesianResidualBiasSummary summarize({
    required List<double> residuals,
    int minimumObservations = defaultMinimumObservations,
    double neutralBandCalories = defaultNeutralBandCalories,
  }) {
    final usableResiduals = residuals.where((value) => value.isFinite).toList(
          growable: false,
        );
    final count = usableResiduals.length;
    if (count < minimumObservations) {
      return BayesianResidualBiasSummary(
        meanResidualCalories: 0,
        observationCount: count,
        status: BayesianResidualBiasStatus.neutral,
      );
    }

    final meanResidual =
        usableResiduals.reduce((a, b) => a + b) / usableResiduals.length;
    final neutralBand = neutralBandCalories.abs();
    final status = meanResidual > neutralBand
        ? BayesianResidualBiasStatus.likelyOverestimatingEnergyDensity
        : meanResidual < -neutralBand
            ? BayesianResidualBiasStatus.likelyUnderestimatingEnergyDensity
            : BayesianResidualBiasStatus.neutral;

    return BayesianResidualBiasSummary(
      meanResidualCalories: meanResidual,
      observationCount: count,
      status: status,
    );
  }
}

class _NoiseCalibration {
  final double qVariance;
  final double observationVariance;
  final double referenceObservationVariance;
  final double qScaleFromHistory;
  final double rScaleFromHistory;
  final bool usedHistoryForQ;
  final bool usedHistoryForR;

  const _NoiseCalibration({
    required this.qVariance,
    required this.observationVariance,
    required this.referenceObservationVariance,
    required this.qScaleFromHistory,
    required this.rScaleFromHistory,
    required this.usedHistoryForQ,
    required this.usedHistoryForR,
  });
}

class _StabilizationAssessment {
  final bool isStillStabilizing;
  final bool bootstrapPhase;
  final List<String> qualityFlags;

  const _StabilizationAssessment({
    required this.isStillStabilizing,
    required this.bootstrapPhase,
    required this.qualityFlags,
  });
}

class _PriorStep {
  final double priorMeanBeforePrediction;
  final double priorVarianceBeforePrediction;
  final double predictedMean;
  final double predictedVariance;
  final BayesianPriorSource priorSource;
  final int appliedPredictionSteps;
  final int elapsedDueWeeks;
  final double varianceCap;
  final bool initializedThisRun;
  final bool replayedSameWeekPrior;
  final bool sameDueWeek;

  const _PriorStep({
    required this.priorMeanBeforePrediction,
    required this.priorVarianceBeforePrediction,
    required this.predictedMean,
    required this.predictedVariance,
    required this.priorSource,
    required this.appliedPredictionSteps,
    required this.elapsedDueWeeks,
    required this.varianceCap,
    required this.initializedThisRun,
    required this.replayedSameWeekPrior,
    required this.sameDueWeek,
  });
}

class _ObservationModel {
  final bool hasSlope;
  final bool hasIntake;
  final bool hasObservation;
  final double? observedMaintenance;
  final double observationVariance;
  final double referenceVariance;
  final double effectiveSampleSize;
  final double kcalPerKg;
  final String kcalPerKgMode;
  final double baseVariance;
  final double intakeVariance;
  final double slopeVariance;
  final double completenessMultiplier;
  final double qualityMultiplier;
  final AdaptiveDietPhase confirmedPhase;
  final int confirmedPhaseAgeDays;
  final double confirmedPhaseAgeWeeks;
  final int confirmedPhaseWeekIndex;
  final AdaptiveDietPhase? pendingPhase;
  final int? pendingPhaseAgeDays;
  final double? pendingPhaseAgeWeeks;

  const _ObservationModel({
    required this.hasSlope,
    required this.hasIntake,
    required this.hasObservation,
    required this.observedMaintenance,
    required this.observationVariance,
    required this.referenceVariance,
    required this.effectiveSampleSize,
    required this.kcalPerKg,
    required this.kcalPerKgMode,
    required this.baseVariance,
    required this.intakeVariance,
    required this.slopeVariance,
    required this.completenessMultiplier,
    required this.qualityMultiplier,
    required this.confirmedPhase,
    required this.confirmedPhaseAgeDays,
    required this.confirmedPhaseAgeWeeks,
    required this.confirmedPhaseWeekIndex,
    required this.pendingPhase,
    required this.pendingPhaseAgeDays,
    required this.pendingPhaseAgeWeeks,
  });
}

class _KcalPerKgSelection {
  final double kcalPerKg;
  final String mode;

  const _KcalPerKgSelection({
    required this.kcalPerKg,
    required this.mode,
  });
}

double? _asDouble(Object? value) {
  return switch (value) {
    num() => value.toDouble(),
    _ => null,
  };
}
