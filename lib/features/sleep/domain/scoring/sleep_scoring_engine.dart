import '../sleep_enums.dart';

class SleepScoringInput {
  const SleepScoringInput({
    this.durationMinutes,
    this.sleepEfficiencyPct,
    this.wasoMinutes,
    this.regularitySri,
    this.regularityValidDays = 0,
    this.lightSleepPct,
    this.deepSleepPct,
    this.remSleepPct,
    this.asleepUnspecifiedPct,
    this.stageDataConfidence = SleepStageConfidence.unknown,
    this.sourcePlatform,
    this.sourceAppId,
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

  /// Sleep stage composition percentages relative to total sleep time.
  ///
  /// Values are expected on a 0..100 scale and are normalized defensively
  /// when the sum deviates due to source quirks.
  final double? lightSleepPct;
  final double? deepSleepPct;
  final double? remSleepPct;
  final double? asleepUnspecifiedPct;

  /// Stage-data fidelity hint derived from source metadata where available.
  final SleepStageConfidence stageDataConfidence;
  final String? sourcePlatform;
  final String? sourceAppId;
}

class SleepScoringConfig {
  const SleepScoringConfig({
    required this.analysisVersion,
    this.weightDuration = 0.40,
    this.weightContinuity = 0.35,
    this.weightRegularity = 0.25,
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
    this.stageDepthScore,
    this.stageScoreCap,
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
  final double? stageDepthScore;
  final double? stageScoreCap;
  final int regularityValidDays;
  final bool regularityUsed;
  final bool regularityStable;
}

SleepScoringResult calculateSleepScore(
  SleepScoringInput input, {
  SleepScoringConfig config = const SleepScoringConfig(
    analysisVersion: 'sleep-health-score-v2',
  ),
}) {
  final durationScore = input.durationMinutes == null
      ? null
      : scoreDurationV2(input.durationMinutes!);
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
  final stageDepthScore = scoreStageDepthQualityV1(
    lightSleepPct: input.lightSleepPct,
    deepSleepPct: input.deepSleepPct,
    remSleepPct: input.remSleepPct,
    asleepUnspecifiedPct: input.asleepUnspecifiedPct,
    stageDataConfidence: input.stageDataConfidence,
    sourcePlatform: input.sourcePlatform,
    sourceAppId: input.sourceAppId,
  );
  final stageScoreCap =
      stageDepthScore == null ? null : scoreStageAwareCapV1(stageDepthScore);

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
      stageDepthScore: stageDepthScore,
      stageScoreCap: stageScoreCap,
      regularityValidDays: input.regularityValidDays,
      regularityUsed: regularityUsed,
      regularityStable: regularityStable,
    );
  }

  final baseScore = topLevel.clamp(0, 100).toDouble();
  final cappedScore = stageScoreCap == null
      ? baseScore
      : (baseScore <= stageScoreCap ? baseScore : stageScoreCap);
  final clamped = cappedScore.clamp(0, 100).toDouble();
  return SleepScoringResult(
    score: clamped,
    state: _scoreState(clamped),
    completeness: activeWeight,
    durationScore: durationScore,
    continuityScore: continuityScore,
    seScore: seScore,
    wasoScore: wasoScore,
    regularityScore: regularityScore,
    stageDepthScore: stageDepthScore,
    stageScoreCap: stageScoreCap,
    regularityValidDays: input.regularityValidDays,
    regularityUsed: regularityUsed,
    regularityStable: regularityStable,
  );
}

/// Stage/depth quality component (0..100).
///
/// This component is conservative by design:
/// - penalizes heavily light-dominant nights
/// - avoids near-perfect quality when REM is missing
/// - degrades confidence when stage fidelity is ambiguous/limited
double? scoreStageDepthQualityV1({
  double? lightSleepPct,
  double? deepSleepPct,
  double? remSleepPct,
  double? asleepUnspecifiedPct,
  SleepStageConfidence stageDataConfidence = SleepStageConfidence.unknown,
  String? sourcePlatform,
  String? sourceAppId,
}) {
  final hasAnyStage = lightSleepPct != null ||
      deepSleepPct != null ||
      remSleepPct != null ||
      asleepUnspecifiedPct != null;
  if (!hasAnyStage) return null;

  final light = (lightSleepPct ?? 0).clamp(0, 100).toDouble();
  final deep = (deepSleepPct ?? 0).clamp(0, 100).toDouble();
  final rem = (remSleepPct ?? 0).clamp(0, 100).toDouble();
  final unspecified = (asleepUnspecifiedPct ?? 0).clamp(0, 100).toDouble();
  final total = light + deep + rem + unspecified;
  if (total <= 0) return null;

  final normalizedLight = (light / total) * 100;
  final normalizedDeep = (deep / total) * 100;
  final normalizedRem = (rem / total) * 100;
  final normalizedUnspecified = (unspecified / total) * 100;
  final fidelity = _stageFidelity(
    stageDataConfidence: stageDataConfidence,
    sourcePlatform: sourcePlatform,
    sourceAppId: sourceAppId,
  );

  final lightDominancePenalty =
      _linear(normalizedLight, 58, 90, 0, 35).clamp(0, 35).toDouble();
  final deepScarcityPenalty = _linear(
    (12 - normalizedDeep).clamp(0, 12).toDouble(),
    0,
    12,
    0,
    16,
  );
  final remMissing = normalizedRem < 1.0;
  final remScarcityPenalty = remMissing
      ? (fidelity < 0.7 ? 10.0 : 16.0)
      : _linear(
          (14 - normalizedRem).clamp(0, 14).toDouble(),
          0,
          14,
          0,
          16,
        );
  final unspecifiedPenalty =
      _linear(normalizedUnspecified, 10, 45, 0, 14).clamp(0, 14).toDouble();
  final restorativeBonus = _linear(
    normalizedDeep + normalizedRem,
    24,
    42,
    0,
    8,
  ).clamp(0, 8).toDouble();
  final confidencePenalty = switch (stageDataConfidence) {
    SleepStageConfidence.high => 0.0,
    SleepStageConfidence.medium => 1.5,
    SleepStageConfidence.unknown => 3.0,
    SleepStageConfidence.low => 6.0,
  };

  var score = 100 -
      lightDominancePenalty -
      deepScarcityPenalty -
      remScarcityPenalty -
      unspecifiedPenalty -
      confidencePenalty +
      restorativeBonus;

  if (remMissing) {
    final remMissingCap = fidelity < 0.7 ? 82.0 : 78.0;
    if (score > remMissingCap) {
      score = remMissingCap;
    }
  }

  return score.clamp(0, 100).toDouble();
}

/// Maximum total score allowed by stage/depth quality.
///
/// Maps stage quality into a conservative cap:
/// - poor depth quality can substantially limit high total scores
/// - high-quality balanced staging keeps near-full score headroom
double scoreStageAwareCapV1(double stageDepthScore) {
  final quality = stageDepthScore.clamp(0, 100).toDouble();
  return (60 + (quality * 0.4)).clamp(60, 100).toDouble();
}

/// Duration component for Sleep Health Score V2 (0..100).
///
/// Evidence-backed direction:
/// - Short sleep is associated with worse outcomes.
/// - Very long sleep can also be associated with higher risk (U-shaped trend).
///
/// Product/heuristic mapping:
/// - Exact breakpoints and slopes in this piecewise function are explicit
///   product design choices, not direct clinical thresholds.
double scoreDurationV2(int durationMinutes) {
  if (durationMinutes <= 0) return 0;
  final hours = durationMinutes / 60.0;
  if (hours <= 4.0) return 0;
  if (hours < 5.0) return _linear(hours, 4.0, 5.0, 0, 5);
  if (hours < 5.5) return _linear(hours, 5.0, 5.5, 5, 20);
  if (hours < 6.0) return _linear(hours, 5.5, 6.0, 20, 50);
  if (hours < 6.5) return _linear(hours, 6.0, 6.5, 50, 80);
  if (hours < 7.0) return _linear(hours, 6.5, 7.0, 80, 100);
  if (hours <= 9.0) return 100;
  if (hours <= 10.0) return _linear(hours, 9.0, 10.0, 100, 90);
  if (hours <= 11.0) return _linear(hours, 10.0, 11.0, 90, 70);
  return 50;
}

/// Sleep efficiency component for Sleep Health Score V2 (0..100).
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

/// WASO component for Sleep Health Score V2 (0..100).
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

double _stageFidelity({
  required SleepStageConfidence stageDataConfidence,
  required String? sourcePlatform,
  required String? sourceAppId,
}) {
  var fidelity = switch (stageDataConfidence) {
    SleepStageConfidence.high => 1.0,
    SleepStageConfidence.medium => 0.8,
    SleepStageConfidence.unknown => 0.6,
    SleepStageConfidence.low => 0.4,
  };
  final source = '${sourcePlatform ?? ''} ${sourceAppId ?? ''}'.toLowerCase();
  if (_isLikelyLimitedStagingSource(source)) {
    fidelity = fidelity.clamp(0.0, 0.5);
  }
  return fidelity.toDouble();
}

bool _isLikelyLimitedStagingSource(String source) {
  return source.contains('withings');
}
