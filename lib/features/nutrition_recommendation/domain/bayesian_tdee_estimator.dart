import 'dart:math' as math;

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

  /// Horizon-dependent effective kcal/kg settings for short windows.
  final double shortWindowKcalPerKg;
  final double matureWindowKcalPerKg;
  final int shortWindowUpperBoundDays;
  final int matureWindowLowerBoundDays;

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
    this.shortWindowKcalPerKg = 5500,
    this.matureWindowKcalPerKg = 7700,
    this.shortWindowUpperBoundDays = 14,
    this.matureWindowLowerBoundDays = 28,
    this.minimumMaintenanceCalories = 1200,
    this.maximumMaintenanceCalories = 5000,
  });
}

class BayesianEstimatorState {
  static const int currentStateVersion = 1;

  final double posteriorMeanCalories;
  final double posteriorVarianceCalories2;
  final String lastDueWeekKey;
  final double? lastPriorMeanCalories;
  final double? lastPriorVarianceCalories2;
  final BayesianPriorSource? lastPriorSource;
  final bool lastObservationUsed;
  final int stateVersion;

  const BayesianEstimatorState({
    required this.posteriorMeanCalories,
    required this.posteriorVarianceCalories2,
    required this.lastDueWeekKey,
    required this.lastPriorMeanCalories,
    required this.lastPriorVarianceCalories2,
    required this.lastPriorSource,
    required this.lastObservationUsed,
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
        lastDueWeekKey.trim().isNotEmpty;
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
      stateVersion: json['stateVersion'] as int? ?? currentStateVersion,
    );
  }
}

class BayesianMaintenanceEstimate {
  static const double _legacyDefaultPriorStdDevCalories = 420;

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
  }) {
    final profilePriorMean = input.priorMaintenanceCalories.toDouble();
    final normalizedDueWeekKey = _normalizeDueWeekKey(dueWeekKey);
    final qualityFlags = <String>[
      'bayesian_recursive_filter',
    ];
    final qVariance =
        math.pow(config.weeklyMaintenanceDriftCalories, 2).toDouble();

    final observationModel = _buildObservationModel(input: input);
    if (!observationModel.hasIntake) {
      qualityFlags.add('bayesian_intake_unavailable');
    }
    if (!observationModel.hasSlope) {
      qualityFlags.add('bayesian_weight_trend_unavailable');
    }
    if (input.qualityFlags.contains('unresolved_food_calories')) {
      qualityFlags.add('unresolved_food_calories');
    }

    final priorStep = _resolvePriorStep(
      profilePriorMeanCalories: profilePriorMean,
      dueWeekKey: normalizedDueWeekKey,
      recursiveState: recursiveState,
      qVariance: qVariance,
      referenceObservationVariance: observationModel.referenceVariance,
      qualityFlags: qualityFlags,
    );

    final priorMean = priorStep.priorMeanBeforePrediction;
    final priorVariance = priorStep.priorVarianceBeforePrediction;
    final predictedMean = priorStep.predictedMean;
    final predictedVariance = priorStep.predictedVariance;
    final varianceCap = priorStep.varianceCap;
    final hasObservation = observationModel.hasObservation;
    final observedMaintenance = observationModel.observedMaintenance;
    final observationVariance = hasObservation
        ? observationModel.observationVariance
        : observationModel.referenceVariance;
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

    final confidence = _classifyConfidence(
      hasObservation: hasObservation,
      posteriorVarianceCalories2: posteriorVariance,
      varianceCapCalories2: varianceCap,
      effectiveSampleSize: effectiveSampleSize,
      windowDays: input.windowDays,
    );

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
        'qVarianceCalories2': qVariance,
        'rVarianceCalories2': observationVariance,
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
        'effectiveKcalPerKg': observationModel.kcalPerKg,
        'effectiveKcalPerKgMode': observationModel.kcalPerKgMode,
        'varianceCapCalories2': varianceCap,
        'predictionWeeksElapsed': priorStep.elapsedDueWeeks,
        'appliedPredictionSteps': priorStep.appliedPredictionSteps,
        'observationBaseVarianceCalories2': observationModel.baseVariance,
        'observationIntakeVarianceCalories2': observationModel.intakeVariance,
        'observationSlopeVarianceCalories2': observationModel.slopeVariance,
        'observationCompletenessMultiplier':
            observationModel.completenessMultiplier,
        'observationQualityMultiplier': observationModel.qualityMultiplier,
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
    );
  }

  _ObservationModel _buildObservationModel({
    required RecommendationGenerationInput input,
  }) {
    final hasSlope = input.smoothedWeightSlopeKgPerWeek != null;
    final hasIntake = input.intakeLoggedDays > 0;
    final hasObservation = hasSlope && hasIntake;
    final kcalPerKgSelection = _resolveKcalPerKg(
      windowDays: input.windowDays,
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
    );
  }

  _KcalPerKgSelection _resolveKcalPerKg({
    required int windowDays,
  }) {
    final usableDays = math.max(windowDays, 0);
    final shortUpper = math.max(config.shortWindowUpperBoundDays, 1);
    final matureLower = math.max(config.matureWindowLowerBoundDays, shortUpper);

    if (usableDays < shortUpper) {
      return _KcalPerKgSelection(
        kcalPerKg: config.shortWindowKcalPerKg,
        mode: 'short_window',
      );
    }

    if (usableDays >= matureLower) {
      return _KcalPerKgSelection(
        kcalPerKg: config.matureWindowKcalPerKg,
        mode: 'mature_window',
      );
    }

    final interpolationWindow = math.max(matureLower - shortUpper, 1);
    final ratio =
        ((usableDays - shortUpper) / interpolationWindow).clamp(0.0, 1.0);
    // Transition smoothly between short-horizon conservative scaling and
    // mature-horizon 7700 kcal/kg scaling.
    return _KcalPerKgSelection(
      kcalPerKg: config.shortWindowKcalPerKg +
          ((config.matureWindowKcalPerKg - config.shortWindowKcalPerKg) *
              ratio),
      mode: 'transition_window',
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
