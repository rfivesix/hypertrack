enum PulseScope { day, week, month }

enum PulseDataQuality { ready, limited, insufficient, noData }

enum PulseNoDataReason {
  none,
  disabled,
  noSamples,
  permissionDenied,
  platformUnavailable,
  queryFailed,
}

class PulseSamplePoint {
  const PulseSamplePoint({
    required this.sampledAtUtc,
    required this.bpm,
  });

  final DateTime sampledAtUtc;
  final double bpm;
}

class PulseAnalysisWindow {
  const PulseAnalysisWindow({
    required this.startUtc,
    required this.endUtc,
  });

  final DateTime startUtc;
  final DateTime endUtc;

  Duration get duration => endUtc.difference(startUtc);
}

class PulseAnalysisSummary {
  const PulseAnalysisSummary({
    required this.window,
    required this.samples,
    required this.chartSamples,
    required this.sampleCount,
    required this.quality,
    required this.noDataReason,
    this.averageBpm,
    this.minBpm,
    this.maxBpm,
    this.restingBpm,
  });

  final PulseAnalysisWindow window;
  final List<PulseSamplePoint> samples;
  final List<PulseSamplePoint> chartSamples;
  final int sampleCount;
  final PulseDataQuality quality;
  final PulseNoDataReason noDataReason;
  final double? averageBpm;
  final double? minBpm;
  final double? maxBpm;
  final double? restingBpm;

  bool get hasData => sampleCount > 0;

  bool get hasCoreMetrics =>
      averageBpm != null &&
      minBpm != null &&
      maxBpm != null &&
      restingBpm != null;

  bool get canRenderChart =>
      chartSamples.length >= 3 &&
      quality != PulseDataQuality.noData &&
      quality != PulseDataQuality.insufficient;
}
