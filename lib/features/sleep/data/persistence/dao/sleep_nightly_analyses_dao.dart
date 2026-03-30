import 'package:drift/drift.dart';

import '../../../../../data/drift_database.dart';
import '../sleep_persistence_models.dart';

class SleepNightlyAnalysesDao {
  const SleepNightlyAnalysesDao(this._db);

  final AppDatabase _db;

  Future<void> upsert(SleepNightlyAnalysisCompanion row) async {
    await _db.customStatement(
      '''
      INSERT OR REPLACE INTO sleep_nightly_analyses (
        id,
        session_id,
        source_platform,
        source_app_id,
        source_confidence,
        source_record_hash,
        normalization_version,
        analysis_version,
        night_date,
        score,
        total_sleep_minutes,
        sleep_efficiency_pct,
        resting_heart_rate_bpm,
        analyzed_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        row.id,
        row.sessionId,
        row.sourcePlatform,
        row.sourceAppId,
        row.sourceConfidence,
        row.sourceRecordHash,
        row.normalizationVersion,
        row.analysisVersion,
        row.nightDate,
        row.score,
        row.totalSleepMinutes,
        row.sleepEfficiencyPct,
        row.restingHeartRateBpm,
        row.analyzedAt,
        DateTime.now().toUtc(),
      ],
    );
  }

  Future<void> upsertBatch(List<SleepNightlyAnalysisCompanion> rows) async {
    await _db.transaction(() async {
      for (final row in rows) {
        await upsert(row);
      }
    });
  }

  Future<List<SleepNightlyAnalysisRecord>> findByNightRange({
    required String fromNightDateInclusive,
    required String toNightDateInclusive,
  }) async {
    final rows = await _db.customSelect(
      '''
      SELECT * FROM sleep_nightly_analyses
      WHERE night_date >= ? AND night_date <= ?
      ORDER BY night_date ASC
      ''',
      variables: [
        Variable<String>(fromNightDateInclusive),
        Variable<String>(toNightDateInclusive),
      ],
    ).get();
    return rows.map(_mapRow).toList(growable: false);
  }

  Future<List<SleepNightlyAnalysisRecord>> findBySessionId(String sessionId) async {
    final rows = await _db.customSelect(
      '''
      SELECT * FROM sleep_nightly_analyses
      WHERE session_id = ?
      ORDER BY analyzed_at DESC
      ''',
      variables: [Variable<String>(sessionId)],
    ).get();
    return rows.map(_mapRow).toList(growable: false);
  }

  /// Deletes analyses for [fromNightDateInclusive, toNightDateInclusive].
  ///
  /// This supports explicit analysis-version recompute windows without touching
  /// canonical rows.
  Future<void> deleteByNightRange({
    required String fromNightDateInclusive,
    required String toNightDateInclusive,
  }) async {
    await _db.customStatement(
      '''
      DELETE FROM sleep_nightly_analyses
      WHERE night_date >= ? AND night_date <= ?
      ''',
      <Object?>[fromNightDateInclusive, toNightDateInclusive],
    );
  }

  SleepNightlyAnalysisRecord _mapRow(QueryRow row) {
    return SleepNightlyAnalysisRecord(
      id: row.read<String>('id'),
      sessionId: row.read<String>('session_id'),
      sourcePlatform: row.read<String>('source_platform'),
      sourceAppId: row.readNullable<String>('source_app_id'),
      sourceConfidence: row.readNullable<String>('source_confidence'),
      sourceRecordHash: row.read<String>('source_record_hash'),
      normalizationVersion: row.read<String>('normalization_version'),
      analysisVersion: row.read<String>('analysis_version'),
      nightDate: row.read<String>('night_date'),
      score: row.readNullable<double>('score'),
      totalSleepMinutes: row.readNullable<int>('total_sleep_minutes'),
      sleepEfficiencyPct: row.readNullable<double>('sleep_efficiency_pct'),
      restingHeartRateBpm: row.readNullable<double>('resting_heart_rate_bpm'),
      analyzedAt: row.read<DateTime>('analyzed_at'),
      createdAt: row.read<DateTime>('created_at'),
      updatedAt: row.read<DateTime>('updated_at'),
    );
  }
}
