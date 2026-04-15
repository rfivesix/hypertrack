enum WorkoutHeartRateDataQuality {
  ready,
  limited,
  insufficient,
  noData,
}

enum WorkoutHeartRateNoDataReason {
  none,
  noSamples,
  permissionDenied,
  platformUnavailable,
  workoutNotFinished,
  invalidWorkoutWindow,
  queryFailed,
}

class WorkoutHeartRateSamplePoint {
  const WorkoutHeartRateSamplePoint({
    required this.sampledAtUtc,
    required this.bpm,
  });

  final DateTime sampledAtUtc;
  final double bpm;
}

class WorkoutHeartRateSummary {
  const WorkoutHeartRateSummary({
    required this.workoutStartUtc,
    required this.workoutEndUtc,
    required this.workoutDuration,
    required this.samples,
    required this.chartSamples,
    required this.sampleCount,
    required this.quality,
    required this.noDataReason,
    this.averageBpm,
    this.maxBpm,
    this.minBpm,
  });

  final DateTime workoutStartUtc;
  final DateTime workoutEndUtc;
  final Duration workoutDuration;
  final List<WorkoutHeartRateSamplePoint> samples;
  final List<WorkoutHeartRateSamplePoint> chartSamples;
  final int sampleCount;
  final double? averageBpm;
  final double? maxBpm;
  final double? minBpm;
  final WorkoutHeartRateDataQuality quality;
  final WorkoutHeartRateNoDataReason noDataReason;

  bool get hasData => sampleCount > 0;

  bool get hasSummaryMetrics =>
      averageBpm != null && maxBpm != null && minBpm != null;

  bool get canRenderChart =>
      chartSamples.length >= 3 &&
      quality != WorkoutHeartRateDataQuality.noData &&
      quality != WorkoutHeartRateDataQuality.insufficient;
}
