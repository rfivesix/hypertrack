import 'dart:math' as math;

import 'pulse_models.dart';

class PulseAnalysisEngine {
  const PulseAnalysisEngine({this.maxChartPoints = 260});

  final int maxChartPoints;

  PulseAnalysisSummary analyze({
    required PulseAnalysisWindow window,
    required List<PulseSamplePoint> rawSamples,
    PulseNoDataReason emptyReason = PulseNoDataReason.noSamples,
  }) {
    final samples = _sanitizeAndSort(rawSamples, window);
    if (samples.isEmpty) {
      return PulseAnalysisSummary(
        window: window,
        samples: const <PulseSamplePoint>[],
        chartSamples: const <PulseSamplePoint>[],
        sampleCount: 0,
        quality: PulseDataQuality.noData,
        noDataReason: emptyReason,
      );
    }

    final bpms = samples.map((sample) => sample.bpm).toList(growable: false);
    final minBpm = bpms.reduce(math.min);
    final maxBpm = bpms.reduce(math.max);
    final averageBpm = _durationWeightedAverage(samples, window);
    final restingBpm = _restingPulse(samples);
    final quality = _classifyQuality(
      sampleCount: samples.length,
      windowDuration: window.duration,
      coverageSpan:
          samples.last.sampledAtUtc.difference(samples.first.sampledAtUtc),
    );

    return PulseAnalysisSummary(
      window: window,
      samples: samples,
      chartSamples: _downsample(samples),
      sampleCount: samples.length,
      averageBpm: averageBpm,
      minBpm: minBpm,
      maxBpm: maxBpm,
      restingBpm: restingBpm,
      quality: quality,
      noDataReason: PulseNoDataReason.none,
    );
  }

  List<PulseSamplePoint> _sanitizeAndSort(
    List<PulseSamplePoint> rawSamples,
    PulseAnalysisWindow window,
  ) {
    final groupedByTimestamp = <int, List<double>>{};
    for (final sample in rawSamples) {
      final sampledAtUtc = sample.sampledAtUtc.toUtc();
      if (sampledAtUtc.isBefore(window.startUtc) ||
          sampledAtUtc.isAfter(window.endUtc)) {
        continue;
      }
      if (!sample.bpm.isFinite || sample.bpm < 25 || sample.bpm > 240) {
        continue;
      }
      groupedByTimestamp
          .putIfAbsent(sampledAtUtc.millisecondsSinceEpoch, () => <double>[])
          .add(sample.bpm);
    }

    final timestamps = groupedByTimestamp.keys.toList()..sort();
    return timestamps.map((timestamp) {
      final values = groupedByTimestamp[timestamp]!;
      final bpm =
          values.fold<double>(0, (sum, value) => sum + value) / values.length;
      return PulseSamplePoint(
        sampledAtUtc: DateTime.fromMillisecondsSinceEpoch(
          timestamp,
          isUtc: true,
        ),
        bpm: bpm,
      );
    }).toList(growable: false);
  }

  double _durationWeightedAverage(
    List<PulseSamplePoint> samples,
    PulseAnalysisWindow window,
  ) {
    if (samples.length == 1) return samples.single.bpm;
    var weightedSum = 0.0;
    var totalSeconds = 0;

    for (var i = 0; i < samples.length; i++) {
      final current = samples[i];
      final previous = i == 0 ? window.startUtc : samples[i - 1].sampledAtUtc;
      final next =
          i == samples.length - 1 ? window.endUtc : samples[i + 1].sampledAtUtc;
      final start = _midpoint(previous, current.sampledAtUtc);
      final end = _midpoint(current.sampledAtUtc, next);
      final seconds = math.max(0, end.difference(start).inSeconds);
      if (seconds == 0) continue;
      weightedSum += current.bpm * seconds;
      totalSeconds += seconds;
    }

    if (totalSeconds <= 0) {
      return samples.fold<double>(0, (sum, sample) => sum + sample.bpm) /
          samples.length;
    }
    return weightedSum / totalSeconds;
  }

  /// MVP resting pulse: the median of the lowest 20% of valid samples.
  ///
  /// This avoids claiming a medically validated resting heart rate while still
  /// surfacing a conservative low-rest estimate from the selected period.
  double _restingPulse(List<PulseSamplePoint> samples) {
    final sorted = samples.map((sample) => sample.bpm).toList()..sort();
    final count = math.max(1, (sorted.length * 0.2).ceil());
    final lowWindow = sorted.take(count).toList(growable: false);
    final middle = lowWindow.length ~/ 2;
    if (lowWindow.length.isOdd) return lowWindow[middle];
    return (lowWindow[middle - 1] + lowWindow[middle]) / 2;
  }

  PulseDataQuality _classifyQuality({
    required int sampleCount,
    required Duration windowDuration,
    required Duration coverageSpan,
  }) {
    if (sampleCount <= 0) return PulseDataQuality.noData;
    if (sampleCount < 3) return PulseDataQuality.insufficient;

    final windowMinutes = math.max(1, windowDuration.inMinutes);
    final coverageMinutes = math.max(0, coverageSpan.inMinutes);
    final density = sampleCount / windowMinutes;
    final poorCoverage = coverageMinutes < math.max(30, windowMinutes ~/ 12);
    if (sampleCount < 8 || density < 0.01 || poorCoverage) {
      return PulseDataQuality.limited;
    }
    return PulseDataQuality.ready;
  }

  DateTime _midpoint(DateTime a, DateTime b) {
    final deltaMicros = b.difference(a).inMicroseconds;
    return a.add(Duration(microseconds: deltaMicros ~/ 2));
  }

  List<PulseSamplePoint> _downsample(List<PulseSamplePoint> points) {
    if (points.length <= maxChartPoints || maxChartPoints < 3) return points;
    final sampled = <PulseSamplePoint>[];
    final step = (points.length - 1) / (maxChartPoints - 1);
    for (var i = 0; i < maxChartPoints; i++) {
      final index = (i * step).round().clamp(0, points.length - 1);
      final point = points[index];
      if (sampled.isEmpty ||
          sampled.last.sampledAtUtc != point.sampledAtUtc ||
          sampled.last.bpm != point.bpm) {
        sampled.add(point);
      }
    }
    final last = points.last;
    if (sampled.isEmpty || sampled.last.sampledAtUtc != last.sampledAtUtc) {
      sampled.add(last);
    }
    return sampled;
  }
}
