// lib/features/steps/data/sources/steps_local_data_source.dart

import 'package:drift/drift.dart' as drift;
import '../../../../data/database_helper.dart';
import '../../../../data/drift_database.dart' as db;
import '../../../../util/perf_debug_timer.dart';

class StepsLocalDataSource {
  final db.AppDatabase _dbInstance;

  StepsLocalDataSource(this._dbInstance);
  static StepsLocalDataSource get instance =>
      DatabaseHelper.instance.stepsLocalDataSource;

  static const int _msPerSecond = 1000;

  Future<db.AppDatabase> get database async {
    return _dbInstance;
  }

  Future<void> upsertHealthStepSegments(
    List<db.HealthStepSegmentsCompanion> companionList,
  ) async {
    final dbInstance = await database;
    await dbInstance.batch((batch) {
      for (final companion in companionList) {
        batch.insert(
          dbInstance.healthStepSegments,
          companion,
          mode: drift.InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> deleteHealthStepSegmentsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final dbInstance = await database;
    await (dbInstance.delete(dbInstance.healthStepSegments)
          ..where((tbl) =>
              tbl.startAt.isBiggerOrEqualValue(start) &
              tbl.endAt.isSmallerOrEqualValue(end)))
        .go();
  }

  Future<int?> getDailyStepsTotal({
    required DateTime dayLocal,
    String providerFilter = 'all',
    String sourcePolicy = 'auto_dominant',
  }) async {
    final dbInstance = await database;
    final dayStartLocal = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    final dayEndLocal = dayStartLocal.add(const Duration(days: 1));
    final dayStartUtcMs =
        dayStartLocal.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;
    final dayEndUtcMs =
        dayEndLocal.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;
    var sql = sourcePolicy == 'max_per_hour'
        ? '''
      WITH source_hour AS (
        SELECT
          CAST(strftime('%H', datetime(start_at, 'unixepoch', 'localtime')) AS INTEGER) AS hour_local,
          COALESCE(source_id, '') AS source_key,
          SUM(step_count) AS source_steps
        FROM health_step_segments
        WHERE start_at < ? AND end_at >= ?
    '''
        : '''
      WITH source_totals AS (
        SELECT
          COALESCE(source_id, '') AS source_key,
          SUM(step_count) AS source_total
        FROM health_step_segments
        WHERE start_at < ? AND end_at >= ?
    ''';
    final vars = <int>[dayEndUtcMs, dayStartUtcMs];
    if (providerFilter == 'apple') {
      sql += " AND provider = 'apple_healthkit'";
    } else if (providerFilter == 'google') {
      sql += " AND provider = 'google_health_connect'";
    }
    sql += sourcePolicy == 'max_per_hour'
        ? '''
        GROUP BY hour_local, source_key
      ),
      dedup_hour AS (
        SELECT hour_local, MAX(source_steps) AS hour_steps
        FROM source_hour
        GROUP BY hour_local
      )
      SELECT COALESCE(SUM(hour_steps), 0) AS total_steps
      FROM dedup_hour
    '''
        : '''
        GROUP BY source_key
      ),
      dominant_source AS (
        SELECT source_key
        FROM source_totals
        ORDER BY source_total DESC, source_key ASC
        LIMIT 1
      )
      SELECT COALESCE(SUM(step_count), 0) AS total_steps
      FROM health_step_segments
      WHERE start_at < ? AND end_at >= ?
        AND COALESCE(source_id, '') = (SELECT source_key FROM dominant_source)
    ''';

    final allVars = sourcePolicy == 'max_per_hour'
        ? vars
        : <int>[...vars, dayEndUtcMs, dayStartUtcMs];

    final rows = await dbInstance.customSelect(
      sql,
      variables: [
        for (final variable in allVars) drift.Variable.withInt(variable),
      ],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.read<int?>('total_steps');
  }

  Future<List<Map<String, dynamic>>> getHourlyStepsTotalsForDay({
    required DateTime dayLocal,
    String providerFilter = 'all',
    String sourcePolicy = 'auto_dominant',
  }) async {
    final stopwatch = Stopwatch()..start();
    final dbInstance = await database;
    final startLocal = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    final endLocal = startLocal.add(const Duration(days: 1));
    final startUtc = startLocal.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;
    final endUtc = endLocal.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;

    var sql = sourcePolicy == 'max_per_hour'
        ? '''
      WITH source_hour AS (
        SELECT
          CAST(strftime('%H', datetime(start_at, 'unixepoch', 'localtime')) AS INTEGER) AS hour_local,
          COALESCE(source_id, '') AS source_key,
          SUM(step_count) AS source_steps
        FROM health_step_segments
        WHERE start_at < ? AND end_at >= ?
    '''
        : '''
      WITH source_totals AS (
        SELECT
          COALESCE(source_id, '') AS source_key,
          SUM(step_count) AS source_total
        FROM health_step_segments
        WHERE start_at < ? AND end_at >= ?
    ''';
    final vars = <int>[endUtc, startUtc];
    if (providerFilter == 'apple') {
      sql += " AND provider = 'apple_healthkit'";
    } else if (providerFilter == 'google') {
      sql += " AND provider = 'google_health_connect'";
    }
    sql += sourcePolicy == 'max_per_hour'
        ? '''
        GROUP BY hour_local, source_key
      )
      SELECT hour_local, MAX(source_steps) AS total_steps
      FROM source_hour
      GROUP BY hour_local
      ORDER BY hour_local ASC
    '''
        : '''
        GROUP BY source_key
      ),
      dominant_source AS (
        SELECT source_key
        FROM source_totals
        ORDER BY source_total DESC, source_key ASC
        LIMIT 1
      )
      SELECT
        CAST(strftime('%H', datetime(start_at, 'unixepoch', 'localtime')) AS INTEGER) AS hour_local,
        SUM(step_count) AS total_steps
      FROM health_step_segments
      WHERE start_at < ? AND end_at >= ?
        AND COALESCE(source_id, '') = (SELECT source_key FROM dominant_source)
      GROUP BY hour_local
      ORDER BY hour_local ASC
    ''';

    final allVars = sourcePolicy == 'max_per_hour'
        ? vars
        : <int>[...vars, endUtc, startUtc];

    final rows = await dbInstance.customSelect(
      sql,
      variables: [
        for (final variable in allVars) drift.Variable.withInt(variable),
      ],
    ).get();
    final result = rows
        .map(
          (row) => <String, dynamic>{
            'hour': row.read<int>('hour_local'),
            'totalSteps': row.read<int?>('total_steps') ?? 0,
          },
        )
        .toList(growable: false);
    PerfDebugTimer.logDuration(
      area: 'db',
      label: 'getHourlyStepsTotalsForDay',
      elapsed: stopwatch.elapsed,
      fields: {
        'rows': rows.length,
        'provider': providerFilter,
        'policy': sourcePolicy,
      },
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> getDailyStepsTotalsForRange({
    required DateTime startLocal,
    required DateTime endLocal,
    String providerFilter = 'all',
    String sourcePolicy = 'auto_dominant',
  }) async {
    final stopwatch = Stopwatch()..start();
    final dbInstance = await database;
    final normalizedStart = DateTime(
      startLocal.year,
      startLocal.month,
      startLocal.day,
    );
    final normalizedEnd = DateTime(endLocal.year, endLocal.month, endLocal.day);
    if (normalizedEnd.isBefore(normalizedStart)) {
      PerfDebugTimer.logDuration(
        area: 'db',
        label: 'getDailyStepsTotalsForRange',
        elapsed: stopwatch.elapsed,
        fields: {'rows': 0},
      );
      return const [];
    }

    var sql = sourcePolicy == 'max_per_hour'
        ? '''
      WITH source_hour AS (
        SELECT
          date(datetime(start_at, 'unixepoch', 'localtime')) AS day_local,
          CAST(strftime('%H', datetime(start_at, 'unixepoch', 'localtime')) AS INTEGER) AS hour_local,
          COALESCE(source_id, '') AS source_key,
          SUM(step_count) AS source_steps
        FROM health_step_segments
        WHERE start_at < ? AND end_at >= ?
    '''
        : '''
      WITH source_day AS (
        SELECT
          date(datetime(start_at, 'unixepoch', 'localtime')) AS day_local,
          COALESCE(source_id, '') AS source_key,
          SUM(step_count) AS source_steps
        FROM health_step_segments
        WHERE start_at < ? AND end_at >= ?
    ''';
    final endExclusiveUtc = normalizedEnd
            .add(const Duration(days: 1))
            .toUtc()
            .millisecondsSinceEpoch ~/
        _msPerSecond;
    final startUtc =
        normalizedStart.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;
    final vars = <int>[endExclusiveUtc, startUtc];

    if (providerFilter == 'apple') {
      sql += " AND provider = 'apple_healthkit'";
    } else if (providerFilter == 'google') {
      sql += " AND provider = 'google_health_connect'";
    }

    sql += sourcePolicy == 'max_per_hour'
        ? '''
        GROUP BY day_local, hour_local, source_key
      ),
      dedup_hour AS (
        SELECT day_local, hour_local, MAX(source_steps) AS hour_steps
        FROM source_hour
        GROUP BY day_local, hour_local
      )
      SELECT day_local, SUM(hour_steps) AS total_steps
      FROM dedup_hour
      GROUP BY day_local
      ORDER BY day_local ASC
    '''
        : '''
        GROUP BY day_local, source_key
      ),
      dominant_source_per_day AS (
        SELECT
          day_local,
          source_key
        FROM source_day s
        WHERE source_steps = (
          SELECT MAX(source_steps)
          FROM source_day s2
          WHERE s2.day_local = s.day_local
        )
      ),
      chosen_source_per_day AS (
        SELECT day_local, MIN(source_key) AS source_key
        FROM dominant_source_per_day
        GROUP BY day_local
      )
      SELECT s.day_local, s.source_steps AS total_steps
      FROM source_day s
      INNER JOIN chosen_source_per_day c
        ON c.day_local = s.day_local
       AND c.source_key = s.source_key
      ORDER BY s.day_local ASC
    ''';

    final rows = await dbInstance.customSelect(
      sql,
      variables: [
        for (final variable in vars) drift.Variable.withInt(variable),
      ],
    ).get();

    final result = rows
        .map(
          (row) => <String, dynamic>{
            'dayLocal': row.read<String>('day_local'),
            'totalSteps': row.read<int?>('total_steps') ?? 0,
          },
        )
        .toList(growable: false);
    PerfDebugTimer.logDuration(
      area: 'db',
      label: 'getDailyStepsTotalsForRange',
      elapsed: stopwatch.elapsed,
      fields: {
        'rows': rows.length,
        'provider': providerFilter,
        'policy': sourcePolicy,
      },
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> getDailyStepsTotalsBySource({
    required DateTime dayLocal,
    String providerFilter = 'all',
  }) async {
    final dbInstance = await database;
    final dayStartLocal = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    final dayEndLocal = dayStartLocal.add(const Duration(days: 1));
    final dayStartUtc =
        dayStartLocal.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;
    final dayEndUtc =
        dayEndLocal.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;

    var sql = '''
      SELECT
        COALESCE(source_id, '') AS source_key,
        SUM(step_count) AS total_steps
      FROM health_step_segments
      WHERE start_at < ? AND end_at >= ?
    ''';
    final vars = <int>[dayEndUtc, dayStartUtc];
    if (providerFilter == 'apple') {
      sql += " AND provider = 'apple_healthkit'";
    } else if (providerFilter == 'google') {
      sql += " AND provider = 'google_health_connect'";
    }
    sql += '''
      GROUP BY source_key
      ORDER BY total_steps DESC, source_key ASC
    ''';

    final rows = await dbInstance.customSelect(
      sql,
      variables: [
        for (final variable in vars) drift.Variable.withInt(variable),
      ],
    ).get();

    return rows
        .map(
          (row) => <String, dynamic>{
            'sourceId': row.read<String>('source_key'),
            'totalSteps': row.read<int?>('total_steps') ?? 0,
          },
        )
        .toList(growable: false);
  }

  Future<void> markHealthExported({
    required String platform,
    required String domain,
    required List<String> idempotencyKeys,
  }) async {
    if (idempotencyKeys.isEmpty) return;
    final dbInstance = await database;
    await dbInstance.batch((batch) {
      for (final key in idempotencyKeys) {
        batch.customStatement(
          '''
          INSERT INTO health_export_records
          (id, platform, domain, idempotency_key, exported_at)
          VALUES (lower(hex(randomblob(16))), ?, ?, ?, ?)
          ON CONFLICT(platform, domain, idempotency_key) DO UPDATE SET
            exported_at = excluded.exported_at
          ''',
          [
            platform,
            domain,
            key,
            DateTime.now().toUtc().millisecondsSinceEpoch ~/ _msPerSecond,
          ],
        );
      }
    });
  }

  Future<List<String>> getExportedHealthKeys({
    required String platform,
    required String domain,
    required List<String> idempotencyKeys,
  }) async {
    if (idempotencyKeys.isEmpty) return const <String>[];
    final dbInstance = await database;
    final placeholders = List.filled(idempotencyKeys.length, '?').join(',');
    final rows = await dbInstance.customSelect(
      '''
      SELECT idempotency_key
      FROM health_export_records
      WHERE platform = ?
        AND domain = ?
        AND idempotency_key IN ($placeholders)
      ''',
      variables: [
        drift.Variable.withString(platform),
        drift.Variable.withString(domain),
        for (final key in idempotencyKeys) drift.Variable.withString(key),
      ],
    ).get();
    return rows
        .map((row) => row.read<String>('idempotency_key'))
        .toList(growable: false);
  }

  Future<DateTime?> getEarliestHealthStepsDateLocal({
    String providerFilter = 'all',
  }) async {
    final stopwatch = Stopwatch()..start();
    final dbInstance = await database;
    var sql = '''
      SELECT MIN(start_at) AS min_start_at
      FROM health_step_segments
    ''';
    if (providerFilter == 'apple') {
      sql += " WHERE provider = 'apple_healthkit'";
    } else if (providerFilter == 'google') {
      sql += " WHERE provider = 'google_health_connect'";
    }
    final rows = await dbInstance.customSelect(sql).get();
    if (rows.isEmpty) {
      PerfDebugTimer.logDuration(
        area: 'db',
        label: 'getEarliestHealthStepsDateLocal',
        elapsed: stopwatch.elapsed,
        fields: {'rows': 0, 'provider': providerFilter},
      );
      return null;
    }
    final minEpoch = rows.first.read<int?>('min_start_at');
    if (minEpoch == null) {
      PerfDebugTimer.logDuration(
        area: 'db',
        label: 'getEarliestHealthStepsDateLocal',
        elapsed: stopwatch.elapsed,
        fields: {'rows': 1, 'provider': providerFilter},
      );
      return null;
    }
    final result = DateTime.fromMillisecondsSinceEpoch(
      minEpoch * _msPerSecond,
      isUtc: true,
    ).toLocal();
    PerfDebugTimer.logDuration(
      area: 'db',
      label: 'getEarliestHealthStepsDateLocal',
      elapsed: stopwatch.elapsed,
      fields: {'rows': 1, 'provider': providerFilter},
    );
    return result;
  }
}
