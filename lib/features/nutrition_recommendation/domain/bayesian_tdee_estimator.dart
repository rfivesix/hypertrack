import 'dart:math' as math;

import 'confidence_models.dart';
import 'recommendation_models.dart';

enum BayesianPriorSource {
  profilePriorBootstrap,
  chainedPosterior,
}

class BayesianMaintenancePrior {
  final double meanCalories;
  final double stdDevCalories;
  final BayesianPriorSource source;

  const BayesianMaintenancePrior({
    required this.meanCalories,
    required this.stdDevCalories,
    required this.source,
  });
}

class BayesianEstimatorConfig {
  final double priorStdDevCalories;
  final double processStdDevCalories;
  final double baseObservationStdDevCalories;
  final double intakeDayStdDevCalories;
  final double weightTrendStdDevKgPerWeek;
  final double minimumMaintenanceCalories;
  final double maximumMaintenanceCalories;

  const BayesianEstimatorConfig({
    this.priorStdDevCalories = 420,
    this.processStdDevCalories = 90,
    this.baseObservationStdDevCalories = 140,
    this.intakeDayStdDevCalories = 320,
    this.weightTrendStdDevKgPerWeek = 0.55,
    this.minimumMaintenanceCalories = 1200,
    this.maximumMaintenanceCalories = 5000,
  });
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

class BayesianTdeeEstimator {
  static const double _kcalPerKgPerWeekToDay = 7700 / 7;

  final BayesianEstimatorConfig config;

  const BayesianTdeeEstimator({
    this.config = const BayesianEstimatorConfig(),
  });

  BayesianMaintenanceEstimate estimate({
    required RecommendationGenerationInput input,
    BayesianMaintenancePrior? chainedPrior,
    String? dueWeekKey,
  }) {
    final profilePriorMean = input.priorMaintenanceCalories.toDouble();
    final prior = _resolvePrior(
      profilePriorMeanCalories: profilePriorMean,
      chainedPrior: chainedPrior,
    );

    final priorMean = prior.meanCalories;
    final priorStdDev = prior.stdDevCalories;
    final priorVariance = math.pow(priorStdDev, 2).toDouble();
    final processVariance =
        math.pow(config.processStdDevCalories, 2).toDouble();
    final predictedVariance = priorVariance + processVariance;

    final slope = input.smoothedWeightSlopeKgPerWeek;
    final hasSlope = slope != null;
    final hasIntake = input.intakeLoggedDays > 0;
    final hasObservation = hasSlope && hasIntake;

    final qualityFlags = <String>[
      if (prior.source == BayesianPriorSource.chainedPosterior)
        'bayesian_prior_chained_posterior'
      else
        'bayesian_prior_profile_bootstrap',
    ];

    if (!hasIntake) {
      qualityFlags.add('bayesian_intake_unavailable');
    }
    if (!hasSlope) {
      qualityFlags.add('bayesian_weight_trend_unavailable');
    }
    if (input.qualityFlags.contains('unresolved_food_calories')) {
      qualityFlags.add('unresolved_food_calories');
    }

    final observedMaintenance = hasObservation
        ? input.avgLoggedCalories - (slope! * _kcalPerKgPerWeekToDay)
        : null;

    final effectiveSampleSize = _effectiveSampleSize(
      windowDays: input.windowDays,
      intakeLoggedDays: input.intakeLoggedDays,
      weightLogCount: input.weightLogCount,
      hasObservation: hasObservation,
    );

    final observationStdDev = hasObservation
        ? _observationStdDevCalories(
            input: input,
            effectiveSampleSize: effectiveSampleSize,
          )
        : math.sqrt(predictedVariance);

    final observationVariance = math.pow(observationStdDev, 2).toDouble();

    double kalmanGain;
    double posteriorMean;
    double posteriorVariance;

    if (!hasObservation || observedMaintenance == null) {
      kalmanGain = 0;
      posteriorMean = priorMean;
      posteriorVariance = predictedVariance;
    } else {
      kalmanGain =
          predictedVariance / (predictedVariance + observationVariance);
      posteriorMean =
          priorMean + (kalmanGain * (observedMaintenance - priorMean));
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

    final posteriorStdDev = math.sqrt(posteriorVariance);
    if (effectiveSampleSize < 4 && hasObservation) {
      qualityFlags.add('bayesian_sparse_signal');
    }
    if (kalmanGain < 0.25) {
      qualityFlags.add('bayesian_prior_dominant');
    }
    if (posteriorStdDev >= 320) {
      qualityFlags.add('bayesian_high_uncertainty');
    }

    final confidence = _classifyConfidence(
      hasObservation: hasObservation,
      posteriorStdDevCalories: posteriorStdDev,
      effectiveSampleSize: effectiveSampleSize,
      windowDays: input.windowDays,
    );

    return BayesianMaintenanceEstimate(
      posteriorMaintenanceCalories: posteriorMean,
      posteriorStdDevCalories: posteriorStdDev,
      profilePriorMaintenanceCalories: profilePriorMean,
      priorMeanUsedCalories: priorMean,
      priorStdDevUsedCalories: priorStdDev,
      priorSource: prior.source,
      observedIntakeCalories: hasIntake ? input.avgLoggedCalories : null,
      observedWeightSlopeKgPerWeek: slope,
      observationImpliedMaintenanceCalories: observedMaintenance,
      effectiveSampleSize: effectiveSampleSize,
      confidence: confidence,
      qualityFlags: qualityFlags,
      debugInfo: {
        'priorVarianceCalories2': priorVariance,
        'processVarianceCalories2': processVariance,
        'predictedVarianceCalories2': predictedVariance,
        'observationVarianceCalories2': observationVariance,
        'kalmanGain': kalmanGain,
      },
      dueWeekKey: dueWeekKey,
    );
  }

  BayesianMaintenancePrior _resolvePrior({
    required double profilePriorMeanCalories,
    required BayesianMaintenancePrior? chainedPrior,
  }) {
    if (chainedPrior == null || !_isValidPrior(chainedPrior)) {
      return BayesianMaintenancePrior(
        meanCalories: profilePriorMeanCalories,
        stdDevCalories: config.priorStdDevCalories,
        source: BayesianPriorSource.profilePriorBootstrap,
      );
    }

    final clampedMean = chainedPrior.meanCalories.clamp(
      config.minimumMaintenanceCalories,
      config.maximumMaintenanceCalories,
    );

    return BayesianMaintenancePrior(
      meanCalories: clampedMean,
      stdDevCalories: chainedPrior.stdDevCalories,
      source: chainedPrior.source,
    );
  }

  bool _isValidPrior(BayesianMaintenancePrior prior) {
    if (prior.meanCalories.isNaN || prior.stdDevCalories.isNaN) {
      return false;
    }
    if (!prior.meanCalories.isFinite || !prior.stdDevCalories.isFinite) {
      return false;
    }
    if (prior.stdDevCalories <= 0) {
      return false;
    }
    return true;
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

  double _observationStdDevCalories({
    required RecommendationGenerationInput input,
    required double effectiveSampleSize,
  }) {
    final intakeStdError = config.intakeDayStdDevCalories /
        math.sqrt(math.max(input.intakeLoggedDays, 1));

    final weightSignalDays = math.max(input.weightLogCount - 1, 1);
    final slopeStdErrorCalories =
        (config.weightTrendStdDevKgPerWeek * _kcalPerKgPerWeekToDay) /
            math.sqrt(weightSignalDays);

    final baseCombined = math.sqrt(
      math.pow(config.baseObservationStdDevCalories, 2) +
          math.pow(intakeStdError, 2) +
          math.pow(slopeStdErrorCalories, 2),
    );

    var qualityMultiplier = 1.0;
    if (input.qualityFlags.contains('unresolved_food_calories')) {
      qualityMultiplier *= 1.30;
    }
    if (input.intakeLoggedDays < 5) {
      qualityMultiplier *= 1.10;
    }
    if (input.weightLogCount < 5) {
      qualityMultiplier *= 1.10;
    }

    final sampleMultiplier = 1 + (1 / math.max(effectiveSampleSize, 1));
    return baseCombined * qualityMultiplier * sampleMultiplier;
  }

  RecommendationConfidence _classifyConfidence({
    required bool hasObservation,
    required double posteriorStdDevCalories,
    required double effectiveSampleSize,
    required int windowDays,
  }) {
    if (!hasObservation || effectiveSampleSize < 2.5) {
      return RecommendationConfidence.notEnoughData;
    }

    if (windowDays >= 21 &&
        effectiveSampleSize >= 10 &&
        posteriorStdDevCalories <= 170) {
      return RecommendationConfidence.high;
    }

    if (windowDays >= 14 &&
        effectiveSampleSize >= 7 &&
        posteriorStdDevCalories <= 250) {
      return RecommendationConfidence.medium;
    }

    if (windowDays >= 7 &&
        effectiveSampleSize >= 4 &&
        posteriorStdDevCalories <= 370) {
      return RecommendationConfidence.low;
    }

    return RecommendationConfidence.notEnoughData;
  }
}
