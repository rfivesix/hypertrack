import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart';
import '../../../services/health/health_platform_heart_rate.dart';
import '../../../util/perf_debug_timer.dart';
import '../application/pulse_tracking_service.dart';
import '../domain/pulse_analysis_engine.dart';
import '../domain/pulse_models.dart';
import 'pulse_aggregate_store.dart';

abstract class PulseAnalysisRepository {
  Future<bool> isTrackingEnabled();
  Future<PulseAnalysisSummary> getAnalysis({
    required PulseAnalysisWindow window,
  });
}

class HealthPulseAnalysisRepository implements PulseAnalysisRepository {
  HealthPulseAnalysisRepository({
    HealthHeartRateDataSource? dataSource,
    PulseTrackingSettingsService? trackingService,
    PulseAnalysisEngine engine = const PulseAnalysisEngine(),
    AppDatabase? database,
    PulseAggregateStore? aggregateStore,
    this.queryPadding = const Duration(hours: 24),
  })  : _dataSource = dataSource ?? const HealthPlatformHeartRate(),
        _trackingService = trackingService ?? PulseTrackingService(),
        _engine = engine,
        _database = database,
        _aggregateStore = aggregateStore;

  final HealthHeartRateDataSource _dataSource;
  final PulseTrackingSettingsService _trackingService;
  final PulseAnalysisEngine _engine;
  final AppDatabase? _database;
  PulseAggregateStore? _aggregateStore;
  final Duration queryPadding;
  static const Duration _coverageTolerance = PulseAggregateStore.bucketSize;

  @override
  Future<bool> isTrackingEnabled() => _trackingService.isTrackingEnabled();

  @override
  Future<PulseAnalysisSummary> getAnalysis({
    required PulseAnalysisWindow window,
  }) async {
    final stopwatch = Stopwatch()..start();
    final enabled = await _trackingService.isTrackingEnabled();
    if (!enabled) {
      final result = _engine.analyze(
        window: window,
        rawSamples: const <PulseSamplePoint>[],
        emptyReason: PulseNoDataReason.disabled,
      );
      PerfDebugTimer.logDuration(
        area: 'statistics',
        label: 'pulseAnalysisQuery',
        elapsed: stopwatch.elapsed,
        fields: {'samples': 0, 'enabled': false},
      );
      return result;
    }

    try {
      final store = await _store();
      var coverage = await store.coverageForWindow(window);
      var decision = _coverageDecision(window, coverage);
      var leadingBackfillRan = false;
      var trailingBackgroundRefreshRan = false;
      _logCoverageDecision(
        window: window,
        coverage: coverage,
        decision: decision,
        leadingBackfillRan: leadingBackfillRan,
        trailingBackgroundRefreshRan: trailingBackgroundRefreshRan,
      );

      if (decision == _PulseCacheCoverageDecision.leadingMissing) {
        await _refreshAggregatesForRange(
          store,
          fromUtc: window.startUtc.subtract(queryPadding),
          toUtc: coverage.earliestBucketStartUtc!,
        );
        leadingBackfillRan = true;
        coverage = await store.coverageForWindow(window);
        decision = _coverageDecision(window, coverage);
        if (decision == _PulseCacheCoverageDecision.leadingMissing &&
            coverage.hasRows) {
          decision = _hasTrailingGap(window, coverage)
              ? _PulseCacheCoverageDecision.trailingMissing
              : _PulseCacheCoverageDecision.covered;
        }
        _logCoverageDecision(
          window: window,
          coverage: coverage,
          decision: decision,
          leadingBackfillRan: leadingBackfillRan,
          trailingBackgroundRefreshRan: trailingBackgroundRefreshRan,
        );
      }

      if (coverage.hasRows &&
          decision != _PulseCacheCoverageDecision.empty &&
          decision != _PulseCacheCoverageDecision.leadingMissing) {
        final cachedBuckets = await store.readBuckets(window);
        if (decision == _PulseCacheCoverageDecision.trailingMissing) {
          trailingBackgroundRefreshRan = true;
          unawaited(_refreshTrailingAggregatesInBackground(
            store: store,
            window: window,
            coverage: coverage,
          ));
          _logCoverageDecision(
            window: window,
            coverage: coverage,
            decision: decision,
            leadingBackfillRan: leadingBackfillRan,
            trailingBackgroundRefreshRan: trailingBackgroundRefreshRan,
          );
        }
        final result = _summaryFromBuckets(
          window: window,
          buckets: cachedBuckets,
        );
        stopwatch.stop();
        PerfDebugTimer.logDuration(
          area: 'statistics',
          label: 'pulseHubSummary',
          elapsed: stopwatch.elapsed,
          fields: {
            'cacheHit': true,
            'aggregateRows': cachedBuckets.length,
            'coverageDecision': decision.name,
            'leadingBackfill': leadingBackfillRan,
            'trailingBackgroundRefresh': trailingBackgroundRefreshRan,
            'rawFallback': false,
          },
        );
        return result;
      }

      final imported = await _refreshAggregatesForRange(
        store,
        fromUtc: window.startUtc.subtract(queryPadding),
        toUtc: window.endUtc.add(queryPadding),
      );
      final buckets = await store.readBuckets(window);
      final result = buckets.isEmpty
          ? _engine.analyze(
              window: window,
              rawSamples: const <PulseSamplePoint>[],
            )
          : _summaryFromBuckets(window: window, buckets: buckets);
      PerfDebugTimer.logDuration(
        area: 'statistics',
        label: 'pulseHubSummary',
        elapsed: stopwatch.elapsed,
        fields: {
          'cacheHit': false,
          'aggregateRows': buckets.length,
          'newRawSamples': imported.rawSampleCount,
          'updatedBuckets': imported.updatedBucketCount,
          'coverageDecision': decision.name,
          'leadingBackfill': leadingBackfillRan,
          'trailingBackgroundRefresh': trailingBackgroundRefreshRan,
          'rawFallback': false,
        },
      );
      return result;
    } on MissingPluginException {
      return _empty(window, PulseNoDataReason.platformUnavailable);
    } on PlatformException catch (error) {
      if (error.code == 'permission_denied') {
        return _empty(window, PulseNoDataReason.permissionDenied);
      }
      if (error.code == 'not_available') {
        return _empty(window, PulseNoDataReason.platformUnavailable);
      }
      return _empty(window, PulseNoDataReason.queryFailed);
    } catch (_) {
      return _empty(window, PulseNoDataReason.queryFailed);
    }
  }

  Future<PulseAggregateStore> _store() async {
    final existing = _aggregateStore;
    if (existing != null) return existing;
    final db = _database ?? await DatabaseHelper.instance.database;
    return _aggregateStore = PulseAggregateStore(db);
  }

  Future<void> _refreshTrailingAggregatesInBackground({
    required PulseAggregateStore store,
    required PulseAnalysisWindow window,
    required PulseAggregateCoverage coverage,
  }) async {
    try {
      final fromUtc = coverage.latestBucketEndUtc == null
          ? window.startUtc.subtract(queryPadding)
          : PulseAggregateStore.floorToBucket(coverage.latestBucketEndUtc!);
      final result = await _refreshAggregatesForRange(
        store,
        fromUtc: fromUtc,
        toUtc: window.endUtc.add(queryPadding),
      );
      PerfDebugTimer.logDuration(
        area: 'statistics',
        label: 'pulseAggregateBackgroundRefresh',
        elapsed: Duration.zero,
        fields: {
          'newRawSamples': result.rawSampleCount,
          'updatedBuckets': result.updatedBucketCount,
        },
      );
    } catch (_) {
      PerfDebugTimer.logDuration(
        area: 'statistics',
        label: 'pulseAggregateBackgroundRefresh',
        elapsed: Duration.zero,
        fields: {'failed': true},
      );
    }
  }

  Future<PulseAggregateWriteResult> _refreshAggregatesForRange(
    PulseAggregateStore store, {
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    if (!toUtc.isAfter(fromUtc)) {
      return const PulseAggregateWriteResult(
        rawSampleCount: 0,
        updatedBucketCount: 0,
      );
    }
    final rows = await _dataSource.readHeartRateSamples(
      fromUtc: fromUtc,
      toUtc: toUtc,
    );
    return store.replaceBucketsFromSamples(
      fromUtc: fromUtc,
      toUtc: toUtc,
      samples: rows,
    );
  }

  _PulseCacheCoverageDecision _coverageDecision(
    PulseAnalysisWindow window,
    PulseAggregateCoverage coverage,
  ) {
    if (!coverage.hasRows) return _PulseCacheCoverageDecision.empty;

    final earliest = coverage.earliestBucketStartUtc!;
    final latest = coverage.latestBucketEndUtc!;
    final leadingGap = earliest.difference(window.startUtc);
    if (leadingGap > _coverageTolerance) {
      return _PulseCacheCoverageDecision.leadingMissing;
    }

    final trailingGap = window.endUtc.difference(latest);
    if (trailingGap > _coverageTolerance) {
      return _PulseCacheCoverageDecision.trailingMissing;
    }

    return _PulseCacheCoverageDecision.covered;
  }

  bool _hasTrailingGap(
    PulseAnalysisWindow window,
    PulseAggregateCoverage coverage,
  ) {
    final latest = coverage.latestBucketEndUtc;
    return latest == null ||
        window.endUtc.difference(latest) > _coverageTolerance;
  }

  void _logCoverageDecision({
    required PulseAnalysisWindow window,
    required PulseAggregateCoverage coverage,
    required _PulseCacheCoverageDecision decision,
    required bool leadingBackfillRan,
    required bool trailingBackgroundRefreshRan,
  }) {
    PerfDebugTimer.logDuration(
      area: 'statistics',
      label: 'pulseAggregateCoverage',
      elapsed: Duration.zero,
      fields: {
        'decision': decision.name,
        'rows': coverage.rowCount,
        'windowStart': window.startUtc.toIso8601String(),
        'windowEnd': window.endUtc.toIso8601String(),
        'earliestBucket': coverage.earliestBucketStartUtc?.toIso8601String(),
        'latestBucketEnd': coverage.latestBucketEndUtc?.toIso8601String(),
        'leadingBackfill': leadingBackfillRan,
        'trailingBackgroundRefresh': trailingBackgroundRefreshRan,
      },
    );
  }

  PulseAnalysisSummary _summaryFromBuckets({
    required PulseAnalysisWindow window,
    required List<PulseAggregateBucket> buckets,
  }) {
    final overlapping = buckets
        .where(
          (bucket) =>
              bucket.bucketEndUtc.isAfter(window.startUtc) &&
              bucket.bucketStartUtc.isBefore(window.endUtc) &&
              bucket.sampleCount > 0,
        )
        .toList(growable: false);
    if (overlapping.isEmpty) {
      return _engine.analyze(
        window: window,
        rawSamples: const <PulseSamplePoint>[],
      );
    }

    final sampleCount = overlapping.fold<int>(
      0,
      (sum, bucket) => sum + bucket.sampleCount,
    );
    final sumBpm = overlapping.fold<double>(
      0,
      (sum, bucket) => sum + bucket.sumBpm,
    );
    final minBpm = overlapping
        .map((bucket) => bucket.minBpm)
        .reduce((a, b) => math.min(a, b));
    final maxBpm = overlapping
        .map((bucket) => bucket.maxBpm)
        .reduce((a, b) => math.max(a, b));
    final first = overlapping
        .map((bucket) => bucket.firstSampleUtc)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final last = overlapping
        .map((bucket) => bucket.lastSampleUtc)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final chartSamples = _chartSamplesFromBuckets(overlapping);

    PerfDebugTimer.logDuration(
      area: 'statistics',
      label: 'pulseDetailChart',
      elapsed: Duration.zero,
      fields: {
        'points': chartSamples.length,
        'aggregateRows': overlapping.length,
        'rawFallback': false,
      },
    );

    return PulseAnalysisSummary(
      window: window,
      samples: const <PulseSamplePoint>[],
      chartSamples: chartSamples,
      sampleCount: sampleCount,
      averageBpm: sumBpm / sampleCount,
      minBpm: minBpm,
      maxBpm: maxBpm,
      restingBpm: _restingFromAggregateBuckets(overlapping),
      quality: _classifyAggregateQuality(
        sampleCount: sampleCount,
        windowDuration: window.duration,
        coverageSpan: last.difference(first),
      ),
      noDataReason: PulseNoDataReason.none,
    );
  }

  List<PulseSamplePoint> _chartSamplesFromBuckets(
    List<PulseAggregateBucket> buckets,
  ) {
    if (buckets.length <= PulseAggregateStore.maxChartPoints) {
      return buckets
          .map(
            (bucket) => PulseSamplePoint(
              sampledAtUtc: bucket.bucketStartUtc.add(
                const Duration(minutes: 30),
              ),
              bpm: bucket.averageBpm,
            ),
          )
          .toList(growable: false);
    }

    final pointCount = PulseAggregateStore.maxChartPoints;
    final groupSize = (buckets.length / pointCount).ceil();
    final points = <PulseSamplePoint>[];
    for (var i = 0; i < buckets.length; i += groupSize) {
      final group = buckets.skip(i).take(groupSize);
      var sampleCount = 0;
      var sumBpm = 0.0;
      DateTime? firstBucketStart;
      for (final bucket in group) {
        firstBucketStart ??= bucket.bucketStartUtc;
        sampleCount += bucket.sampleCount;
        sumBpm += bucket.sumBpm;
      }
      if (sampleCount == 0 || firstBucketStart == null) continue;
      points.add(
        PulseSamplePoint(
          sampledAtUtc: firstBucketStart.add(const Duration(minutes: 30)),
          bpm: sumBpm / sampleCount,
        ),
      );
    }
    return points.take(PulseAggregateStore.maxChartPoints).toList();
  }

  double _restingFromAggregateBuckets(List<PulseAggregateBucket> buckets) {
    final sorted = buckets.map((bucket) => bucket.averageBpm).toList()..sort();
    final count = math.max(1, (sorted.length * 0.2).ceil());
    final lowWindow = sorted.take(count).toList(growable: false);
    final middle = lowWindow.length ~/ 2;
    if (lowWindow.length.isOdd) return lowWindow[middle];
    return (lowWindow[middle - 1] + lowWindow[middle]) / 2;
  }

  PulseDataQuality _classifyAggregateQuality({
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

  PulseAnalysisSummary _empty(
    PulseAnalysisWindow window,
    PulseNoDataReason reason,
  ) {
    return _engine.analyze(
      window: window,
      rawSamples: const <PulseSamplePoint>[],
      emptyReason: reason,
    );
  }
}

enum _PulseCacheCoverageDecision {
  empty,
  covered,
  leadingMissing,
  trailingMissing,
}
