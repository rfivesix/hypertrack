import 'dart:math' as math;
import '../sleep_enums.dart';

class SleepScoringInput {
  const SleepScoringInput({
    this.durationMinutes,
    this.sleepEfficiencyPct,
    this.wasoMinutes,
    this.regularitySri,
    this.regularityValidDays = 0,
    this.regularityValidComparisonPairs,
    this.lightSleepPct,
    this.deepSleepPct,
    this.remSleepPct,
    this.asleepUnspecifiedPct,
    this.stageDataConfidence = SleepStageConfidence.unknown,
    this.sourcePlatform,
    this.sourceAppId,
    this.sleepOnsetHourLocal,
    this.rollingMidSleepSd,
  });

  final int? durationMinutes;
  final double? sleepEfficiencyPct;
  final int? wasoMinutes;

  /// Sleep Regularity Index on a 0..100 scale.
  final double? regularitySri;
  final int regularityValidDays;
  final int? regularityValidComparisonPairs;

  /// Sleep stage composition percentages relative to total sleep time.
  final double? lightSleepPct;
  final double? deepSleepPct;
  final double? remSleepPct;
  final double? asleepUnspecifiedPct;

  /// Stage-data fidelity hint derived from source metadata where available.
  final SleepStageConfidence stageDataConfidence;
  final String? sourcePlatform;
  final String? sourceAppId;

  /// Local clock time of sleep onset (0.0 to 24.0, or >24 for past midnight).
  final double? sleepOnsetHourLocal;

  /// 7-14 day rolling standard deviation of mid-sleep time in hours.
  final double? rollingMidSleepSd;

  double? get remMinutes => (remSleepPct != null && durationMinutes != null)
      ? (remSleepPct! / 100.0) * durationMinutes!
      : null;

  double? get n3Minutes => (deepSleepPct != null && durationMinutes != null)
      ? (deepSleepPct! / 100.0) * durationMinutes!
      : null;
}

class SleepScoringConfig {
  const SleepScoringConfig({
    required this.analysisVersion,
    this.weightDuration = 0.30,
    this.weightContinuity = 0.20,
    this.weightArchitecture = 0.25,
    this.weightTiming = 0.15,
    this.weightRegularity = 0.10,
    this.regularityMinDays = 5,
    this.regularityStableDays = 7,
  });

  final String analysisVersion;
  final double weightDuration;
  final double weightContinuity;
  final double weightArchitecture;
  final double weightTiming;
  final double weightRegularity;
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
    this.architectureScore,
    this.timingScore,
    this.stageScoreCap,
    required this.regularityValidDays,
    required this.regularityUsed,
    required this.regularityStable,
    this.dynamicMultiplier,
    this.multiplierBottleneck,
  });

  final double? score;
  final SleepScoreState state;

  /// Data completeness of the score, not scientific certainty.
  final double completeness;

  final double? durationScore;
  final double? continuityScore;
  final double? seScore;
  final double? wasoScore;
  final double? regularityScore;
  final double? architectureScore;
  final double? timingScore;
  final double? stageScoreCap;
  final int regularityValidDays;
  final bool regularityUsed;
  final bool regularityStable;
  final double? dynamicMultiplier;
  final String? multiplierBottleneck;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'score': score,
        'state': state.name,
        'completeness': completeness,
        'durationScore': durationScore,
        'continuityScore': continuityScore,
        'seScore': seScore,
        'wasoScore': wasoScore,
        'regularityScore': regularityScore,
        'architectureScore': architectureScore,
        'timingScore': timingScore,
        'stageScoreCap': stageScoreCap,
        'regularityValidDays': regularityValidDays,
        'regularityUsed': regularityUsed,
        'regularityStable': regularityStable,
        'dynamicMultiplier': dynamicMultiplier,
        'multiplierBottleneck': multiplierBottleneck,
      };

  factory SleepScoringResult.fromJson(Map<String, dynamic> json) {
    return SleepScoringResult(
      score: (json['score'] as num?)?.toDouble(),
      state: SleepScoreState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => SleepScoreState.unavailable,
      ),
      completeness: (json['completeness'] as num?)?.toDouble() ?? 0.0,
      durationScore: (json['durationScore'] as num?)?.toDouble(),
      continuityScore: (json['continuityScore'] as num?)?.toDouble(),
      seScore: (json['seScore'] as num?)?.toDouble(),
      wasoScore: (json['wasoScore'] as num?)?.toDouble(),
      regularityScore: (json['regularityScore'] as num?)?.toDouble(),
      architectureScore: (json['architectureScore'] as num?)?.toDouble(),
      timingScore: (json['timingScore'] as num?)?.toDouble(),
      stageScoreCap: (json['stageScoreCap'] as num?)?.toDouble(),
      regularityValidDays: json['regularityValidDays'] as int? ?? 0,
      regularityUsed: json['regularityUsed'] as bool? ?? false,
      regularityStable: json['regularityStable'] as bool? ?? false,
      dynamicMultiplier: (json['dynamicMultiplier'] as num?)?.toDouble(),
      multiplierBottleneck: json['multiplierBottleneck'] as String?,
    );
  }
}

/// Calculates the multi-domain Sleep Health Score (SHS v3) based on AASM clinical
/// consensus and commercial standards. Internal sub-scores operate on a [0, 1] scale
/// and are combined to form a final index between [0, 100].
SleepScoringResult calculateSleepScore(
  SleepScoringInput input, {
  SleepScoringConfig config = const SleepScoringConfig(
    analysisVersion: 'sleep-health-score-v3',
  ),
}) {
  // --- Duration Score (D) ---
  final double? durationScore = input.durationMinutes != null
      ? scoreDurationV3(input.durationMinutes!)
      : null;

  // --- Continuity Score (C) ---
  final double? seComponent = input.sleepEfficiencyPct != null
      ? scoreSleepEfficiencyV3(input.sleepEfficiencyPct!)
      : null;
  final double? wasoComponent = input.wasoMinutes != null
      ? scoreWasoV3(input.wasoMinutes!)
      : null;
  
  double? continuityScore;
  if (seComponent != null && wasoComponent != null) {
    continuityScore = 0.5 * seComponent + 0.5 * wasoComponent;
  } else if (seComponent != null) {
    continuityScore = seComponent;
  } else if (wasoComponent != null) {
    continuityScore = wasoComponent;
  } else {
    final double lightSleepPctVal = input.lightSleepPct ?? 0.0;
    double pLight = 1.0;
    if (lightSleepPctVal > 65.0) {
      pLight = math.exp(-math.pow(lightSleepPctVal - 65.0, 2) / (2.0 * math.pow(7.0, 2)));
    }
    final double lightSleepPenalty = 1.0 - pLight;

    continuityScore = 0.9 * (1.0 - lightSleepPenalty) + 0.1 * (durationScore ?? 0.0);
  }

  // --- Architecture Score (A) ---
  final double? architectureScore = scoreArchitectureV3(
    durationMinutes: input.durationMinutes,
    lightSleepPct: input.lightSleepPct,
    deepSleepPct: input.deepSleepPct,
    remSleepPct: input.remSleepPct,
  );

  // --- Timing Score (T_circ) ---
  final double? timingScore = (input.sleepOnsetHourLocal != null && input.durationMinutes != null)
      ? scoreTimingV3(input.sleepOnsetHourLocal!, input.durationMinutes!)
      : null;

  // --- Regularity Score (R) ---
  final regularityUsed = input.rollingMidSleepSd != null &&
      input.regularityValidDays >= config.regularityMinDays;
  final regularityStable = regularityUsed &&
      input.regularityValidDays >= config.regularityStableDays;
  
  final double? regularityScore = regularityUsed 
      ? scoreRegularityV3(input.rollingMidSleepSd!)
      : null;

  // Combine Scores
  final scoredComponents = [
    (config.weightDuration, durationScore),
    (config.weightContinuity, continuityScore),
    (config.weightArchitecture, architectureScore),
    (config.weightTiming, timingScore),
    (config.weightRegularity, regularityScore),
  ];

  final topLevel = _renormalizedWeightedScore(scoredComponents: scoredComponents);
  final activeWeight = _activeWeight(weightedComponents: scoredComponents);

  if (topLevel == null || activeWeight <= 0) {
    return SleepScoringResult(
      score: null,
      state: SleepScoreState.unavailable,
      completeness: 0,
      durationScore: durationScore != null ? durationScore * 100 : null,
      continuityScore: continuityScore * 100,
      seScore: seComponent != null ? seComponent * 100 : null,
      wasoScore: wasoComponent != null ? wasoComponent * 100 : null,
      regularityScore: regularityScore != null ? regularityScore * 100 : null,
      architectureScore: architectureScore != null ? architectureScore * 100 : null,
      timingScore: timingScore != null ? timingScore * 100 : null,
      stageScoreCap: null,
      regularityValidDays: input.regularityValidDays,
      regularityUsed: regularityUsed,
      regularityStable: regularityStable,
    );
  }

  // Base raw score scaled to 100
  double finalScore = topLevel * 100.0;

  double dynamicMultiplier = 1.0;
  String? multiplierBottleneck;

  // 1. Smooth REM Penalty
  // Optimal: >= 60 min (multiplier = 1.0). Suboptimal down to 40 min (multiplier = 0.65).
  if (input.remMinutes != null) {
    final double remM = _linear(input.remMinutes!.toDouble(), 40.0, 60.0, 0.65, 1.0);
    if (remM < dynamicMultiplier) {
      dynamicMultiplier = remM;
      multiplierBottleneck = 'rem';
    }
  }

  // 2. Smooth Deep Sleep (N3) Penalty
  // Optimal: >= 70 min (multiplier = 1.0). Suboptimal down to 40 min (multiplier = 0.60).
  if (input.n3Minutes != null) {
    final double n3M = _linear(input.n3Minutes!.toDouble(), 40.0, 70.0, 0.60, 1.0);
    if (n3M < dynamicMultiplier) {
      dynamicMultiplier = n3M;
      multiplierBottleneck = 'n3';
    }
  }

  // 3. Smooth Sleep Deprivation Penalty (TST)
  // Optimal: >= 6.5 hours (multiplier = 1.0). Suboptimal down to 5.0 hours (multiplier = 0.50).
  if (input.durationMinutes != null) {
    final double tstHours = input.durationMinutes! / 60.0;
    final double durationM = _linear(tstHours, 5.0, 6.5, 0.50, 1.0);
    if (durationM < dynamicMultiplier) {
      dynamicMultiplier = durationM;
      multiplierBottleneck = 'tst';
    }
  }

  // 4. Smooth Circadian Timing Penalty (Mid-Sleep Hour)
  // Optimal: Mid-sleep <= 5.5 (multiplier = 1.0). Late-phase delay up to 7.5 (multiplier = 0.55).
  if (input.sleepOnsetHourLocal != null && input.durationMinutes != null) {
    final double midSleep = _calculateMidSleep(input.sleepOnsetHourLocal!, input.durationMinutes!);
    final double timingM = _linear(midSleep, 7.5, 5.5, 0.55, 1.0);
    if (timingM < dynamicMultiplier) {
      dynamicMultiplier = timingM;
      multiplierBottleneck = 'timing';
    }
  }

  // Apply the dynamic degradation factor directly to the topLevel base score
  finalScore *= dynamicMultiplier;

  final clamped = finalScore.clamp(0.0, 100.0);
  
  return SleepScoringResult(
    score: clamped,
    state: _scoreState(clamped),
    completeness: activeWeight.clamp(0.0, 1.0).toDouble(),
    durationScore: durationScore != null ? durationScore * 100 : null,
    continuityScore: continuityScore * 100,
    seScore: seComponent != null ? seComponent * 100 : null,
    wasoScore: wasoComponent != null ? wasoComponent * 100 : null,
    regularityScore: regularityScore != null ? regularityScore * 100 : null,
    architectureScore: architectureScore != null ? architectureScore * 100 : null,
    timingScore: timingScore != null ? timingScore * 100 : null,
    stageScoreCap: dynamicMultiplier < 1.0 ? clamped : null,
    regularityValidDays: input.regularityValidDays,
    regularityUsed: regularityUsed,
    regularityStable: regularityStable,
    dynamicMultiplier: dynamicMultiplier,
    multiplierBottleneck: multiplierBottleneck,
  );
}

/// Duration Score (D): Gaussian distribution centered around mu_T = 7.5 hours
/// with spread sigma_T = 1.0. Plateaus in the 7-9 hour anabolic sweet spot.
/// Clips extremes (<5h or >10.5h -> 0).
/// Returns a [0, 1] continuous score.
double scoreDurationV3(int durationMinutes) {
  final double hours = durationMinutes / 60.0;
  if (hours > 10.5) return 0.0;
  
  if (hours >= 7.0 && hours <= 9.0) {
    return 1.0; // Plateau
  }
  
  final double mu = hours < 7.0 ? 7.0 : 9.0;
  return math.exp(-math.pow(hours - mu, 2) / (2 * math.pow(1.0, 2)));
}

/// Continuity Score (C_SE): Logistic curve.
/// Returns a [0, 1] continuous score.
double scoreSleepEfficiencyV3(double sleepEfficiencyPct) {
  final double seFraction = sleepEfficiencyPct / 100.0;
  return 1.0 / (1.0 + math.exp(-50.0 * (seFraction - 0.90)));
}

/// Continuity Score (C_WASO): Rational penalty decaying quadratically.
/// Returns a [0, 1] continuous score.
double scoreWasoV3(int wasoMinutes) {
  final double waso = math.max(wasoMinutes - 20.0, 0.0);
  return 1.0 / (1.0 + math.pow(waso / 30.0, 2));
}

/// Architecture Score (A): Based on absolute minutes.
/// Returns a [0, 1] continuous score.
double? scoreArchitectureV3({
  int? durationMinutes,
  double? lightSleepPct,
  double? deepSleepPct,
  double? remSleepPct,
}) {
  if (durationMinutes == null || deepSleepPct == null || remSleepPct == null) {
    return null;
  }
  
  final double n3Min = (deepSleepPct / 100.0) * durationMinutes;
  final double remMin = (remSleepPct / 100.0) * durationMinutes;
  final double lightSleepPctVal = lightSleepPct ?? 0.0;

  final double aN3 = math.min(1.0, n3Min / 90.0) * math.exp(-math.pow(n3Min - 90.0, 2) / (2.0 * math.pow(40.0, 2)));
  final double aRem = math.min(1.0, remMin / 100.0) * math.exp(-math.pow(remMin - 100.0, 2) / (2.0 * math.pow(40.0, 2)));
  
  double pLight = 1.0;
  if (lightSleepPctVal > 65.0) {
    pLight = math.exp(-math.pow(lightSleepPctVal - 65.0, 2) / (2.0 * math.pow(7.0, 2)));
  }

  double score = (0.45 * aN3 + 0.45 * aRem) * pLight + 0.10;
  return score.clamp(0.0, 1.0);
}

/// Timing Score (T_circ): Uses Mid-Sleep clock time.
/// Base Gaussian centered at 03:30 (3.5).
/// Returns a [0, 1] continuous score.
double scoreTimingV3(double onsetHourLocal, int durationMinutes) {
  final double ms = _calculateMidSleep(onsetHourLocal, durationMinutes);
  
  // Gaussian centered at 03:30 (3.5), sigma = 1.0
  double baseScore = math.exp(-math.pow(ms - 3.5, 2) / (2.0 * math.pow(1.0, 2)));
  
  // Exponential late-phase penalty drop
  if (ms > 5.5) {
    double pLate = math.exp(-math.pow(ms - 5.5, 2) / (2.0 * math.pow(0.5, 2)));
    baseScore *= pLate;
  }
  
  return baseScore.clamp(0.0, 1.0);
}

/// Regularity Score (R): Inverse-quadratic decay based on standard deviation.
/// Returns a [0, 1] continuous score.
double scoreRegularityV3(double rollingMidSleepSd) {
  return 1.0 / (1.0 + math.pow(rollingMidSleepSd / 1.0, 2));
}

/// Normalizes mid-sleep time to handle midnight crossing properly.
/// Returns the hour [0-24] typically, shifting into a continuous scale.
double _calculateMidSleep(double onsetHourLocal, int durationMinutes) {
  double onset = onsetHourLocal;
  // If onset is early in the evening (e.g., 20:00), we want mid sleep to cross midnight cleanly.
  // We'll anchor around noon. 
  // If onset is between 12:00 and 24:00, subtract 24 or just treat 00:00 as 24:00.
  if (onset > 12.0) {
    onset -= 24.0; 
  }
  // Now onset is usually negative (e.g., 23:00 -> -1.0) or early morning (01:00 -> 1.0)
  
  double ms = onset + ((durationMinutes / 60.0) / 2.0);
  
  // Shift back if needed so 03:30 is 3.5
  while (ms < 0) {
    ms += 24.0;
  }
  while (ms >= 24.0) {
    ms -= 24.0;
  }
  return ms;
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

SleepScoreState _scoreState(double score) {
  if (score >= 80) return SleepScoreState.good;
  if (score >= 60) return SleepScoreState.average;
  return SleepScoreState.poor;
}

double _linear(double value, double xMin, double xMax, double yMin, double yMax) {
  if (xMin == xMax) return yMax;
  final bool isIncreasing = xMin < xMax;
  final double clampedX = isIncreasing
      ? value.clamp(xMin, xMax)
      : value.clamp(xMax, xMin);
  final double t = (clampedX - xMin) / (xMax - xMin);
  return yMin + t * (yMax - yMin);
}
