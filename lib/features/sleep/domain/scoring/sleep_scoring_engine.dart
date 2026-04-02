class SleepScoringInput {
  const SleepScoringInput({
    this.durationMinutes,
    this.sleepEfficiencyPct,
    this.wasoMinutes,
    this.regularitySri,
    this.regularityValidDays = 0,
  });

  final int? durationMinutes;
  final double? sleepEfficiencyPct;
  final int? wasoMinutes;

  /// Sleep Regularity Index on a 0..100 scale.
  ///
  /// This score is only used when [regularityValidDays] meets the configured
  /// minimum threshold.
  final double? regularitySri;
  final int regularityValidDays;
}

class SleepScoringConfig {
  const SleepScoringConfig({
    required this.analysisVersion,
    this.weightDuration = 0.35,
    this.weightContinuity = 0.35,
    this.weightRegularity = 0.30,
    this.weightSeWithinContinuity = 0.50,
    this.weightWasoWithinContinuity = 0.50,
    this.regularityMinDays = 5,
    this.regularityStableDays = 7,
  });

  final String analysisVersion;
  final double weightDuration;
  final double weightContinuity;
  final double weightRegularity;
  final double weightSeWithinContinuity;
  final double weightWasoWithinContinuity;
  final int regularityMinDays;
  final int regularityStableDays;
}

enum SleepScoreState { good, average, poor, unavailable }

class SleepScoringResult {
  const SleepScoringResult({
    required this.score,
    required this.state,
    required this.completeness,
    this.durationScore,
    this.continuityScore,
    this.seScore,
    this.wasoScore,
    this.regularityScore,
    required this.regularityValidDays,
    required this.regularityUsed,
    required this.regularityStable,
  });

  final double? score;
  final SleepScoreState state;

  /// Data completeness of the score, not scientific certainty.
  ///
  /// 1.0 means all top-level components were available.
  /// 0.0 means no top-level component was available.
  final double completeness;

  final double? durationScore;
  final double? continuityScore;
  final double? seScore;
  final double? wasoScore;
  final double? regularityScore;
  final int regularityValidDays;
  final bool regularityUsed;
  final bool regularityStable;
}

SleepScoringResult calculateSleepScore(
  SleepScoringInput input, {
  SleepScoringConfig config = const SleepScoringConfig(
    analysisVersion: 'sleep-health-score-v1',
  ),
}) {
  final durationScore = input.durationMinutes == null
      ? null
      : scoreDurationV1(input.durationMinutes!);
  final seScore = input.sleepEfficiencyPct == null
      ? null
      : scoreSleepEfficiencyV1(input.sleepEfficiencyPct!);
  final wasoScore =
      input.wasoMinutes == null ? null : scoreWasoV1(input.wasoMinutes!);
  final continuityScore = _renormalizedWeightedScore(
    scoredComponents: [
      (config.weightSeWithinContinuity, seScore),
      (config.weightWasoWithinContinuity, wasoScore),
    ],
  );

  // Do not impute/fake regularity: SRI contributes only when minimum valid
  // day requirements are satisfied.
  final regularityUsed = input.regularitySri != null &&
      input.regularityValidDays >= config.regularityMinDays;
  final regularityStable = regularityUsed &&
      input.regularityValidDays >= config.regularityStableDays;
  final regularityScore =
      regularityUsed ? input.regularitySri!.clamp(0, 100).toDouble() : null;

  final topLevel = _renormalizedWeightedScore(
    scoredComponents: [
      (config.weightDuration, durationScore),
      (config.weightContinuity, continuityScore),
      (config.weightRegularity, regularityScore),
    ],
  );

  final activeWeight = _activeWeight(
    weightedComponents: [
      (config.weightDuration, durationScore),
      (config.weightContinuity, continuityScore),
      (config.weightRegularity, regularityScore),
    ],
  );
  if (topLevel == null || activeWeight <= 0) {
    return SleepScoringResult(
      score: null,
      state: SleepScoreState.unavailable,
      completeness: 0,
      durationScore: durationScore,
      continuityScore: continuityScore,
      seScore: seScore,
      wasoScore: wasoScore,
      regularityScore: regularityScore,
      regularityValidDays: input.regularityValidDays,
      regularityUsed: regularityUsed,
      regularityStable: regularityStable,
    );
  }

  final clamped = topLevel.clamp(0, 100).toDouble();
  return SleepScoringResult(
    score: clamped,
    state: _scoreState(clamped),
    completeness: activeWeight,
    durationScore: durationScore,
    continuityScore: continuityScore,
    seScore: seScore,
    wasoScore: wasoScore,
    regularityScore: regularityScore,
    regularityValidDays: input.regularityValidDays,
    regularityUsed: regularityUsed,
    regularityStable: regularityStable,
  );
}

/// Duration component for Sleep Health Score V1 (0..100).
///
/// Evidence-backed direction:
/// - Short sleep is associated with worse outcomes.
/// - Very long sleep can also be associated with higher risk (U-shaped trend).
///
/// Product/heuristic mapping:
/// - Exact breakpoints and slopes in this piecewise function are conservative
///   product design choices, not direct clinical thresholds.
double scoreDurationV1(int durationMinutes) {
  if (durationMinutes <= 0) return 0;
  final hours = durationMinutes / 60.0;
  if (hours < 4.0) return 0;
  if (hours < 5.0) return _linear(hours, 4.0, 5.0, 0, 30);
  if (hours < 6.0) return _linear(hours, 5.0, 6.0, 30, 70);
  if (hours < 7.0) return _linear(hours, 6.0, 7.0, 70, 100);
  if (hours <= 9.0) return 100;
  if (hours <= 10.0) return _linear(hours, 9.0, 10.0, 100, 85);
  if (hours <= 11.0) return _linear(hours, 10.0, 11.0, 85, 60);
  return 60;
}

/// Sleep efficiency component for Sleep Health Score V1 (0..100).
///
/// Evidence-backed direction:
/// - Lower sleep efficiency reflects more fragmented/incomplete sleep and is
///   associated with poorer sleep health.
///
/// Product/heuristic mapping:
/// - Exact score bands are conservative approximations.
double scoreSleepEfficiencyV1(double sleepEfficiencyPct) {
  final se = sleepEfficiencyPct.clamp(0, 100).toDouble();
  if (se >= 90) return 100;
  if (se >= 85) return _linear(se, 85, 90, 85, 100);
  if (se >= 80) return _linear(se, 80, 85, 65, 85);
  if (se >= 70) return _linear(se, 70, 80, 25, 65);
  return _linear(se, 0, 70, 0, 25).clamp(0, 25).toDouble();
}

/// WASO component for Sleep Health Score V1 (0..100).
///
/// Evidence-backed direction:
/// - Higher wake-after-sleep-onset is generally worse for continuity.
///
/// Product/heuristic mapping:
/// - Minute bands and linear slopes are conservative conventions.
double scoreWasoV1(int wasoMinutes) {
  final double waso = wasoMinutes < 0 ? 0.0 : wasoMinutes.toDouble();
  if (waso <= 30) return 100;
  if (waso <= 60) return _linear(waso, 30, 60, 100, 70);
  if (waso <= 120) return _linear(waso, 60, 120, 70, 30);
  return _linear(waso, 120, 240, 30, 0).clamp(0, 30).toDouble();
}

double? _renormalizedWeightedScore({
  required List<(double weight, double? score)> scoredComponents,
}) {
  var activeWeight = 0.0;
  var weightedSum = 0.0;
  for (final entry in scoredComponents) {
    final score = entry.$2;
    if (score == null) continue;
    activeWeight += entry.$1;
    weightedSum += entry.$1 * score;
  }
  if (activeWeight <= 0) return null;
  return weightedSum / activeWeight;
}

double _activeWeight({
  required List<(double weight, double? score)> weightedComponents,
}) {
  var weight = 0.0;
  for (final entry in weightedComponents) {
    if (entry.$2 == null) continue;
    weight += entry.$1;
  }
  return weight;
}

double _linear(double x, double x0, double x1, double y0, double y1) {
  if (x <= x0) return y0;
  if (x >= x1) return y1;
  final t = (x - x0) / (x1 - x0);
  return y0 + (y1 - y0) * t;
}

SleepScoreState _scoreState(double score) {
  if (score >= 80) return SleepScoreState.good;
  if (score >= 60) return SleepScoreState.average;
  return SleepScoreState.poor;
}
