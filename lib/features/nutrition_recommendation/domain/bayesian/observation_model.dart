part of '../bayesian_tdee_estimator.dart';

extension ObservationModelBuilding on BayesianTdeeEstimator {
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
