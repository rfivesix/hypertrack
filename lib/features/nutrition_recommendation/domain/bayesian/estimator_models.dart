part of '../bayesian_tdee_estimator.dart';

enum BayesianPriorSource {
  profilePriorBootstrap,
  chainedPosterior,
}

class BayesianEstimatorConfig {
  /// Bootstrap prior uncertainty (kcal/day, standard deviation).
  final double priorStdDevCalories;

  /// Expected week-to-week latent maintenance drift (kcal/day).
  final double weeklyMaintenanceDriftCalories;

  /// Baseline observation noise floor (kcal/day, standard deviation).
  final double baseObservationStdDevCalories;

  /// Intake day-to-day variability (kcal/day, standard deviation).
  final double intakeDayStdDevCalories;

  /// Weight-slope uncertainty (kg/week, standard deviation).
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
}

class BayesianEstimatorRunResult {
  final BayesianMaintenanceEstimate estimate;
  final BayesianEstimatorState nextState;

  const BayesianEstimatorRunResult({
    required this.estimate,
    required this.nextState,
  });
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
