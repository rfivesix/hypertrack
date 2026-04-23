import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'health_platform_heart_rate.dart';
import 'workout_heart_rate_models.dart';

class WorkoutHeartRateService {
  const WorkoutHeartRateService({
    HealthHeartRateDataSource? dataSource,
    this.maxChartPoints = 240,
    this.fallbackQueryPadding = const Duration(hours: 24),
  }) : _dataSource = dataSource ?? const HealthPlatformHeartRate();

  final HealthHeartRateDataSource _dataSource;
  final int maxChartPoints;
  final Duration fallbackQueryPadding;

  Future<WorkoutHeartRateSummary> loadForWorkoutWindow({
    required DateTime startTime,
    required DateTime? endTime,
  }) async {
    final startUtc = startTime.toUtc();

    if (endTime == null) {
      return _emptySummary(
        startUtc: startUtc,
        endUtc: startUtc,
        reason: WorkoutHeartRateNoDataReason.workoutNotFinished,
      );
    }

    final endUtc = endTime.toUtc();
    if (!endUtc.isAfter(startUtc)) {
      return _emptySummary(
        startUtc: startUtc,
        endUtc: endUtc,
        reason: WorkoutHeartRateNoDataReason.invalidWorkoutWindow,
      );
    }

    List<HealthHeartRateSampleDto> raw;
    try {
      raw = await _readSamplesWithVendorSafeFallback(
        startUtc: startUtc,
        endUtc: endUtc,
      );
    } on MissingPluginException {
      return _emptySummary(
        startUtc: startUtc,
        endUtc: endUtc,
        reason: WorkoutHeartRateNoDataReason.platformUnavailable,
      );
    } on PlatformException catch (error) {
      if (error.code == 'permission_denied') {
        return _emptySummary(
          startUtc: startUtc,
          endUtc: endUtc,
          reason: WorkoutHeartRateNoDataReason.permissionDenied,
        );
      }
      if (error.code == 'not_available') {
        return _emptySummary(
          startUtc: startUtc,
          endUtc: endUtc,
          reason: WorkoutHeartRateNoDataReason.platformUnavailable,
        );
      }
      return _emptySummary(
        startUtc: startUtc,
        endUtc: endUtc,
        reason: WorkoutHeartRateNoDataReason.queryFailed,
      );
    } catch (_) {
      return _emptySummary(
        startUtc: startUtc,
        endUtc: endUtc,
        reason: WorkoutHeartRateNoDataReason.queryFailed,
      );
    }

    final samples = _sanitizeAndSort(
      rawSamples: raw,
      startUtc: startUtc,
      endUtc: endUtc,
    );

    if (samples.isEmpty) {
      return _emptySummary(
        startUtc: startUtc,
        endUtc: endUtc,
        reason: WorkoutHeartRateNoDataReason.noSamples,
      );
    }

    final bpms = samples.map((sample) => sample.bpm).toList(growable: false);
    final average = bpms.fold<double>(0, (sum, value) => sum + value) /
        math.max(1, bpms.length);
    final minBpm = bpms.reduce(math.min);
    final maxBpm = bpms.reduce(math.max);

    final quality = _classifyQuality(
      sampleCount: samples.length,
      workoutDuration: endUtc.difference(startUtc),
      coverageSpan:
          samples.last.sampledAtUtc.difference(samples.first.sampledAtUtc),
    );

    return WorkoutHeartRateSummary(
      workoutStartUtc: startUtc,
      workoutEndUtc: endUtc,
      workoutDuration: endUtc.difference(startUtc),
      samples: samples,
      chartSamples: _downsample(samples),
      sampleCount: samples.length,
      averageBpm: average,
      maxBpm: maxBpm,
      minBpm: minBpm,
      quality: quality,
      noDataReason: WorkoutHeartRateNoDataReason.none,
    );
  }

  Future<List<HealthHeartRateSampleDto>> _readSamplesWithVendorSafeFallback({
    required DateTime startUtc,
    required DateTime endUtc,
  }) async {
    final direct = await _dataSource.readHeartRateSamples(
      fromUtc: startUtc,
      toUtc: endUtc,
    );
    if (direct.isNotEmpty || fallbackQueryPadding <= Duration.zero) {
      return direct;
    }

    // Some Health Connect providers emit long-interval HR series records where
    // the record boundary can sit outside the workout window although sample
    // timestamps are inside. Retry with a wider read window, then keep strict
    // workout-window filtering in _sanitizeAndSort.
    return _dataSource.readHeartRateSamples(
      fromUtc: startUtc.subtract(fallbackQueryPadding),
      toUtc: endUtc.add(fallbackQueryPadding),
    );
  }

  WorkoutHeartRateSummary _emptySummary({
    required DateTime startUtc,
    required DateTime endUtc,
    required WorkoutHeartRateNoDataReason reason,
  }) {
    return WorkoutHeartRateSummary(
      workoutStartUtc: startUtc,
      workoutEndUtc: endUtc,
      workoutDuration: endUtc.isAfter(startUtc)
          ? endUtc.difference(startUtc)
          : Duration.zero,
      samples: const <WorkoutHeartRateSamplePoint>[],
      chartSamples: const <WorkoutHeartRateSamplePoint>[],
      sampleCount: 0,
      quality: WorkoutHeartRateDataQuality.noData,
      noDataReason: reason,
    );
  }

  List<WorkoutHeartRateSamplePoint> _sanitizeAndSort({
    required List<HealthHeartRateSampleDto> rawSamples,
    required DateTime startUtc,
    required DateTime endUtc,
  }) {
    final groupedByTimestamp = <int, List<double>>{};

    for (final sample in rawSamples) {
      final sampledAtUtc = sample.sampledAtUtc.toUtc();
      final bpm = sample.bpm;
      if (sampledAtUtc.isBefore(startUtc) || sampledAtUtc.isAfter(endUtc)) {
        continue;
      }
      if (!bpm.isFinite || bpm < 25 || bpm > 240) {
        continue;
      }
      groupedByTimestamp
          .putIfAbsent(sampledAtUtc.millisecondsSinceEpoch, () => <double>[])
          .add(bpm);
    }

    final timestamps = groupedByTimestamp.keys.toList()..sort();
    return timestamps.map((timestamp) {
      final values = groupedByTimestamp[timestamp]!;
      final averaged =
          values.fold<double>(0, (sum, value) => sum + value) / values.length;
      return WorkoutHeartRateSamplePoint(
        sampledAtUtc: DateTime.fromMillisecondsSinceEpoch(
          timestamp,
          isUtc: true,
        ),
        bpm: averaged,
      );
    }).toList(growable: false);
  }

  WorkoutHeartRateDataQuality _classifyQuality({
    required int sampleCount,
    required Duration workoutDuration,
    required Duration coverageSpan,
  }) {
    if (sampleCount <= 0) return WorkoutHeartRateDataQuality.noData;

    final durationMinutes = math.max(1, workoutDuration.inMinutes);
    final coverageMinutes = math.max(0, coverageSpan.inMinutes);
    final density = sampleCount / durationMinutes;

    if (sampleCount < 3) {
      return WorkoutHeartRateDataQuality.insufficient;
    }

    final poorCoverage = coverageMinutes < math.max(3, durationMinutes ~/ 5);
    if (sampleCount < 8 || density < 0.06 || poorCoverage) {
      return WorkoutHeartRateDataQuality.limited;
    }

    return WorkoutHeartRateDataQuality.ready;
  }

  List<WorkoutHeartRateSamplePoint> _downsample(
    List<WorkoutHeartRateSamplePoint> points,
  ) {
    if (points.length <= maxChartPoints || maxChartPoints < 3) {
      return points;
    }

    final sampled = <WorkoutHeartRateSamplePoint>[];
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
