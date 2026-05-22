part of '../bayesian_tdee_estimator.dart';

extension RegressionEngine on BayesianTdeeEstimator {
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
