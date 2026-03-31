class SleepScoringInput {
  const SleepScoringInput({
    this.durationMinutes,
    this.sleepEfficiencyPct,
    this.interruptionsCount,
    this.regularityMinutes,
    this.hrDeltaBpm,
    this.depthScore,
    this.depthConfidenceHigh = true,
  });

  final int? durationMinutes;
  final double? sleepEfficiencyPct;
  final int? interruptionsCount;
  final double? regularityMinutes;
  final double? hrDeltaBpm;
  final double? depthScore;
  final bool depthConfidenceHigh;
}

class SleepScoringConfig {
  const SleepScoringConfig({
    required this.analysisVersion,
    this.weightDuration = 0.30,
    this.weightContinuity = 0.25,
    this.weightRegularity = 0.20,
    this.weightHeartRate = 0.15,
    this.weightDepth = 0.10,
  });

  final String analysisVersion;
  final double weightDuration;
  final double weightContinuity;
  final double weightRegularity;
  final double weightHeartRate;
  final double weightDepth;
}

enum SleepScoreState { good, average, poor, unavailable }

class SleepScoringResult {
  const SleepScoringResult({required this.score, required this.state});

  final double? score;
  final SleepScoreState state;
}

SleepScoringResult calculateSleepScore(
  SleepScoringInput input, {
  SleepScoringConfig config = const SleepScoringConfig(
    analysisVersion: 'sleep-analysis-v1',
  ),
}) {
  final componentScores = <String, double>{};
  final componentWeights = <String, double>{};

  if (input.durationMinutes != null) {
    componentScores['duration'] = _durationScore(input.durationMinutes!);
    componentWeights['duration'] = config.weightDuration;
  }

  final continuity = _continuityScore(
    sleepEfficiencyPct: input.sleepEfficiencyPct,
    interruptionsCount: input.interruptionsCount,
  );
  if (continuity != null) {
    componentScores['continuity'] = continuity;
    componentWeights['continuity'] = config.weightContinuity;
  }

  if (input.regularityMinutes != null) {
    componentScores['regularity'] = _regularityScore(input.regularityMinutes!);
    componentWeights['regularity'] = config.weightRegularity;
  }

  if (input.hrDeltaBpm != null) {
    componentScores['heartRate'] = _heartRateScore(input.hrDeltaBpm!);
    componentWeights['heartRate'] = config.weightHeartRate;
  }

  if (input.depthScore != null && input.depthConfidenceHigh) {
    componentScores['depth'] = input.depthScore!.clamp(0, 100).toDouble();
    componentWeights['depth'] = config.weightDepth;
  }

  if (componentScores.isEmpty) {
    return const SleepScoringResult(
      score: null,
      state: SleepScoreState.unavailable,
    );
  }

  final totalWeight = componentWeights.values.fold<double>(0, (a, b) => a + b);
  final weighted = componentScores.entries.fold<double>(0, (sum, entry) {
    final weight = componentWeights[entry.key]!;
    return sum + entry.value * (weight / totalWeight);
  });
  final normalized = weighted.clamp(0, 100).toDouble();
  return SleepScoringResult(score: normalized, state: _scoreState(normalized));
}

double _durationScore(int minutes) {
  if (minutes <= 240 || minutes >= 720) return 0;
  if (minutes <= 480) {
    return ((minutes - 240) / 240) * 100;
  }
  return ((720 - minutes) / 240) * 100;
}

double? _continuityScore({
  required double? sleepEfficiencyPct,
  required int? interruptionsCount,
}) {
  final efficiency = sleepEfficiencyPct?.clamp(0, 100).toDouble();
  final interruptions = interruptionsCount == null
      ? null
      : (100 - interruptionsCount * 10).clamp(0, 100).toDouble();
  return switch ((efficiency, interruptions)) {
    (double e, double i) => 0.6 * e + 0.4 * i,
    (double e, null) => e,
    (null, double i) => i,
    _ => null,
  };
}

double _regularityScore(double regularityMinutes) {
  final clamped = regularityMinutes.clamp(0, 180);
  return (100 - (clamped / 180) * 100).clamp(0, 100).toDouble();
}

double _heartRateScore(double hrDelta) {
  final absoluteDelta = hrDelta.abs();
  if (absoluteDelta >= 12) return 0;
  return (100 - (absoluteDelta / 12) * 100).clamp(0, 100).toDouble();
}

SleepScoreState _scoreState(double score) {
  if (score >= 80) return SleepScoreState.good;
  if (score >= 60) return SleepScoreState.average;
  return SleepScoreState.poor;
}
