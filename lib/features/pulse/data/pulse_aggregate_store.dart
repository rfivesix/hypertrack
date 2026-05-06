import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../../data/drift_database.dart';
import '../../../services/health/health_platform_heart_rate.dart';
import '../../../util/perf_debug_timer.dart';
import '../domain/pulse_models.dart';

class PulseAggregateBucket {
  const PulseAggregateBucket({
    required this.bucketStartUtc,
    required this.bucketEndUtc,
    required this.sampleCount,
    required this.minBpm,
    required this.maxBpm,
    required this.sumBpm,
    required this.firstSampleUtc,
    required this.lastSampleUtc,
  });

  final DateTime bucketStartUtc;
  final DateTime bucketEndUtc;
  final int sampleCount;
  final double minBpm;
  final double maxBpm;
  final double sumBpm;
  final DateTime firstSampleUtc;
  final DateTime lastSampleUtc;

  double get averageBpm => sumBpm / sampleCount;
}

class PulseAggregateWriteResult {
  const PulseAggregateWriteResult({
    required this.rawSampleCount,
    required this.updatedBucketCount,
  });

  final int rawSampleCount;
  final int updatedBucketCount;
}

class PulseAggregateCoverage {
  const PulseAggregateCoverage({
    required this.rowCount,
    required this.earliestBucketStartUtc,
    required this.latestBucketEndUtc,
  });

  final int rowCount;
  final DateTime? earliestBucketStartUtc;
  final DateTime? latestBucketEndUtc;

  bool get hasRows =>
      rowCount > 0 &&
      earliestBucketStartUtc != null &&
      latestBucketEndUtc != null;
}

class PulseAggregateStore {
  PulseAggregateStore(this._db);

  static const int aggregationVersion = 1;
  static const int maxChartPoints = 2000;
  static const String _lastAggregatedSampleAtKey =
      'last_aggregated_sample_at_ms';
  static const Duration bucketSize = Duration(hours: 1);

  final AppDatabase _db;

  Future<void> ensureSchema() => _createPulsePersistenceSchema(_db);

  Future<DateTime?> lastAggregatedSampleAt() async {
    await ensureSchema();
    final row = await _db.customSelect(
      'SELECT value FROM pulse_aggregate_metadata WHERE key = ?',
      variables: [const Variable<String>(_lastAggregatedSampleAtKey)],
      readsFrom: const {},
    ).getSingleOrNull();
    final value = row?.read<String>('value');
    final millis = value == null ? null : int.tryParse(value);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  Future<List<PulseAggregateBucket>> readBuckets(
    PulseAnalysisWindow window,
  ) async {
    await ensureSchema();
    final rows = await _db.customSelect(
      '''
      SELECT * FROM pulse_hourly_aggregates
      WHERE bucket_end_ms > ? AND bucket_start_ms < ?
        AND aggregation_version = ?
      ORDER BY bucket_start_ms
      ''',
      variables: [
        Variable<int>(window.startUtc.millisecondsSinceEpoch),
        Variable<int>(window.endUtc.millisecondsSinceEpoch),
        const Variable<int>(aggregationVersion),
      ],
      readsFrom: const {},
    ).get();
    final buckets = rows.map(_bucketFromRow).toList(growable: false);
    PerfDebugTimer.logDuration(
      area: 'statistics',
      label: 'pulseAggregateRead',
      elapsed: Duration.zero,
      fields: {'rows': buckets.length},
    );
    return buckets;
  }

  Future<PulseAggregateCoverage> coverageForWindow(
    PulseAnalysisWindow window,
  ) async {
    await ensureSchema();
    final row = await _db.customSelect(
      '''
      SELECT
        COUNT(*) AS row_count,
        MIN(bucket_start_ms) AS earliest_bucket_start_ms,
        MAX(bucket_end_ms) AS latest_bucket_end_ms
      FROM pulse_hourly_aggregates
      WHERE bucket_end_ms > ? AND bucket_start_ms < ?
        AND aggregation_version = ?
      ''',
      variables: [
        Variable<int>(window.startUtc.millisecondsSinceEpoch),
        Variable<int>(window.endUtc.millisecondsSinceEpoch),
        const Variable<int>(aggregationVersion),
      ],
      readsFrom: const {},
    ).getSingle();
    final earliestMs = row.readNullable<int>('earliest_bucket_start_ms');
    final latestMs = row.readNullable<int>('latest_bucket_end_ms');
    return PulseAggregateCoverage(
      rowCount: row.read<int>('row_count'),
      earliestBucketStartUtc: earliestMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(earliestMs, isUtc: true),
      latestBucketEndUtc: latestMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(latestMs, isUtc: true),
    );
  }

  Future<PulseAggregateWriteResult> replaceBucketsFromSamples({
    required DateTime fromUtc,
    required DateTime toUtc,
    required List<HealthHeartRateSampleDto> samples,
  }) async {
    await ensureSchema();
    final stopwatch = Stopwatch()..start();
    final bucketStart = floorToBucket(fromUtc);
    final bucketEnd = ceilToBucket(toUtc);
    final aggregates = _aggregate(samples);
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final previousLastMs =
        (await lastAggregatedSampleAt())?.toUtc().millisecondsSinceEpoch;

    await _db.transaction(() async {
      await _db.customStatement(
        '''
        DELETE FROM pulse_hourly_aggregates
        WHERE bucket_start_ms >= ? AND bucket_start_ms < ?
        ''',
        [
          bucketStart.millisecondsSinceEpoch,
          bucketEnd.millisecondsSinceEpoch,
        ],
      );

      for (final bucket in aggregates) {
        await _db.customStatement(
          '''
          INSERT OR REPLACE INTO pulse_hourly_aggregates (
            bucket_start_ms,
            bucket_end_ms,
            sample_count,
            min_bpm,
            max_bpm,
            sum_bpm,
            first_sample_ms,
            last_sample_ms,
            source,
            aggregation_version,
            updated_at_ms
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            bucket.bucketStartUtc.millisecondsSinceEpoch,
            bucket.bucketEndUtc.millisecondsSinceEpoch,
            bucket.sampleCount,
            bucket.minBpm,
            bucket.maxBpm,
            bucket.sumBpm,
            bucket.firstSampleUtc.millisecondsSinceEpoch,
            bucket.lastSampleUtc.millisecondsSinceEpoch,
            'platform',
            aggregationVersion,
            nowMs,
          ],
        );
      }

      final rawLastSampleMs = _lastSampleMillis(samples);
      final lastSampleMs = rawLastSampleMs == null
          ? null
          : previousLastMs == null
              ? rawLastSampleMs
              : math.max(previousLastMs, rawLastSampleMs);
      if (lastSampleMs != null) {
        await _db.customStatement(
          '''
          INSERT OR REPLACE INTO pulse_aggregate_metadata
            (key, value, updated_at_ms)
          VALUES (?, ?, ?)
          ''',
          [_lastAggregatedSampleAtKey, '$lastSampleMs', nowMs],
        );
      }
    });

    stopwatch.stop();
    PerfDebugTimer.logDuration(
      area: 'statistics',
      label: 'pulseAggregateWrite',
      elapsed: stopwatch.elapsed,
      fields: {
        'newRawSamples': samples.length,
        'updatedBuckets': aggregates.length,
      },
    );
    return PulseAggregateWriteResult(
      rawSampleCount: samples.length,
      updatedBucketCount: aggregates.length,
    );
  }

  Future<int> countBuckets(PulseAnalysisWindow window) async {
    await ensureSchema();
    final row = await _db.customSelect(
      '''
      SELECT COUNT(*) AS row_count FROM pulse_hourly_aggregates
      WHERE bucket_end_ms > ? AND bucket_start_ms < ?
        AND aggregation_version = ?
      ''',
      variables: [
        Variable<int>(window.startUtc.millisecondsSinceEpoch),
        Variable<int>(window.endUtc.millisecondsSinceEpoch),
        const Variable<int>(aggregationVersion),
      ],
      readsFrom: const {},
    ).getSingle();
    return row.read<int>('row_count');
  }

  static DateTime floorToBucket(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day, utc.hour);
  }

  static DateTime ceilToBucket(DateTime value) {
    final floored = floorToBucket(value);
    return floored == value.toUtc() ? floored : floored.add(bucketSize);
  }

  List<PulseAggregateBucket> _aggregate(
    List<HealthHeartRateSampleDto> samples,
  ) {
    final builders = <int, _PulseBucketBuilder>{};
    for (final sample in samples) {
      final sampledAt = sample.sampledAtUtc.toUtc();
      if (!sample.bpm.isFinite || sample.bpm < 25 || sample.bpm > 240) {
        continue;
      }
      final bucketStart = floorToBucket(sampledAt);
      builders
          .putIfAbsent(
            bucketStart.millisecondsSinceEpoch,
            () => _PulseBucketBuilder(bucketStart),
          )
          .add(sampledAt, sample.bpm);
    }
    final keys = builders.keys.toList()..sort();
    return keys.map((key) => builders[key]!.build()).toList(growable: false);
  }

  PulseAggregateBucket _bucketFromRow(QueryRow row) {
    DateTime fromMs(String column) => DateTime.fromMillisecondsSinceEpoch(
          row.read<int>(column),
          isUtc: true,
        );
    return PulseAggregateBucket(
      bucketStartUtc: fromMs('bucket_start_ms'),
      bucketEndUtc: fromMs('bucket_end_ms'),
      sampleCount: row.read<int>('sample_count'),
      minBpm: row.read<double>('min_bpm'),
      maxBpm: row.read<double>('max_bpm'),
      sumBpm: row.read<double>('sum_bpm'),
      firstSampleUtc: fromMs('first_sample_ms'),
      lastSampleUtc: fromMs('last_sample_ms'),
    );
  }

  int? _lastSampleMillis(List<HealthHeartRateSampleDto> samples) {
    int? result;
    for (final sample in samples) {
      final millis = sample.sampledAtUtc.toUtc().millisecondsSinceEpoch;
      result = result == null ? millis : math.max(result, millis);
    }
    return result;
  }
}

class _PulseBucketBuilder {
  _PulseBucketBuilder(this.bucketStartUtc);

  final DateTime bucketStartUtc;
  var sampleCount = 0;
  var minBpm = double.infinity;
  var maxBpm = double.negativeInfinity;
  var sumBpm = 0.0;
  DateTime? firstSampleUtc;
  DateTime? lastSampleUtc;

  void add(DateTime sampledAtUtc, double bpm) {
    sampleCount += 1;
    minBpm = math.min(minBpm, bpm);
    maxBpm = math.max(maxBpm, bpm);
    sumBpm += bpm;
    if (firstSampleUtc == null || sampledAtUtc.isBefore(firstSampleUtc!)) {
      firstSampleUtc = sampledAtUtc;
    }
    if (lastSampleUtc == null || sampledAtUtc.isAfter(lastSampleUtc!)) {
      lastSampleUtc = sampledAtUtc;
    }
  }

  PulseAggregateBucket build() {
    return PulseAggregateBucket(
      bucketStartUtc: bucketStartUtc,
      bucketEndUtc: bucketStartUtc.add(PulseAggregateStore.bucketSize),
      sampleCount: sampleCount,
      minBpm: minBpm,
      maxBpm: maxBpm,
      sumBpm: sumBpm,
      firstSampleUtc: firstSampleUtc!,
      lastSampleUtc: lastSampleUtc!,
    );
  }
}

Future<void> _createPulsePersistenceSchema(GeneratedDatabase db) async {
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS pulse_hourly_aggregates (
      bucket_start_ms INTEGER NOT NULL PRIMARY KEY,
      bucket_end_ms INTEGER NOT NULL,
      sample_count INTEGER NOT NULL,
      min_bpm REAL NOT NULL,
      max_bpm REAL NOT NULL,
      sum_bpm REAL NOT NULL,
      first_sample_ms INTEGER NOT NULL,
      last_sample_ms INTEGER NOT NULL,
      source TEXT NOT NULL DEFAULT 'platform',
      aggregation_version INTEGER NOT NULL DEFAULT 1,
      updated_at_ms INTEGER NOT NULL
    )
  ''');
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_pulse_hourly_range ON pulse_hourly_aggregates(bucket_start_ms, bucket_end_ms)',
  );
  await db.customStatement('''
    CREATE TABLE IF NOT EXISTS pulse_aggregate_metadata (
      key TEXT NOT NULL PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at_ms INTEGER NOT NULL
    )
  ''');
}
