import 'package:drift/drift.dart';

import '../../../../../data/drift_database.dart';
import '../sleep_persistence_models.dart';

class SleepCanonicalSessionsDao {
  const SleepCanonicalSessionsDao(this._db);

  final AppDatabase _db;

  int _toEpochMillis(DateTime value) => value.toUtc().millisecondsSinceEpoch;

  DateTime _fromEpochMillis(int value) =>
      DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);

  Future<void> upsert(SleepCanonicalSessionCompanion row) async {
    await _db.customStatement(
      '''
      INSERT OR REPLACE INTO sleep_canonical_sessions (
        id,
        raw_import_id,
        source_platform,
        source_app_id,
        source_confidence,
        source_record_hash,
        normalization_version,
        session_type,
        started_at,
        ended_at,
        timezone,
        imported_at,
        normalized_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        row.id,
        row.rawImportId,
        row.sourcePlatform,
        row.sourceAppId,
        row.sourceConfidence,
        row.sourceRecordHash,
        row.normalizationVersion,
        row.sessionType,
        _toEpochMillis(row.startedAt),
        _toEpochMillis(row.endedAt),
        row.timezone,
        _toEpochMillis(row.importedAt),
        _toEpochMillis(row.normalizedAt),
        _toEpochMillis(DateTime.now()),
      ],
    );
  }

  Future<void> upsertBatch(List<SleepCanonicalSessionCompanion> rows) async {
    await _db.transaction(() async {
      for (final row in rows) {
        await upsert(row);
      }
    });
  }

  Future<List<SleepCanonicalSessionRecord>> findByDateRange({
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) async {
    final result = await _db
        .customSelect(
          '''
      SELECT * FROM sleep_canonical_sessions
      WHERE started_at < ? AND ended_at > ?
      ORDER BY started_at ASC
      ''',
          variables: [
            Variable<int>(_toEpochMillis(toExclusive)),
            Variable<int>(_toEpochMillis(fromInclusive)),
          ],
        )
        .get();
    return result.map(_mapSession).toList(growable: false);
  }

  Future<SleepCanonicalSessionRecord?> findById(String sessionId) async {
    final row = await _db
        .customSelect(
          'SELECT * FROM sleep_canonical_sessions WHERE id = ? LIMIT 1',
          variables: [Variable<String>(sessionId)],
        )
        .getSingleOrNull();
    if (row == null) return null;
    return _mapSession(row);
  }

  Future<List<SleepCanonicalSessionRecord>> findBySourceHash(
    String sourceRecordHash,
  ) async {
    final result = await _db
        .customSelect(
          '''
      SELECT * FROM sleep_canonical_sessions
      WHERE source_record_hash = ?
      ORDER BY normalized_at DESC
      ''',
          variables: [Variable<String>(sourceRecordHash)],
        )
        .get();
    return result.map(_mapSession).toList(growable: false);
  }

  /// Deletes canonical sessions where the session overlaps [fromInclusive, toExclusive).
  ///
  /// Because stage segments and HR samples are ON DELETE CASCADE, this is the
  /// canonical recompute boundary delete for a time window.
  Future<void> deleteByDateRange({
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) async {
    await _db.customStatement(
      '''
      DELETE FROM sleep_canonical_sessions
      WHERE started_at < ? AND ended_at > ?
      ''',
      <Object?>[_toEpochMillis(toExclusive), _toEpochMillis(fromInclusive)],
    );
  }

  SleepCanonicalSessionRecord _mapSession(QueryRow row) {
    return SleepCanonicalSessionRecord(
      id: row.read<String>('id'),
      rawImportId: row.readNullable<String>('raw_import_id'),
      sourcePlatform: row.read<String>('source_platform'),
      sourceAppId: row.readNullable<String>('source_app_id'),
      sourceConfidence: row.readNullable<String>('source_confidence'),
      sourceRecordHash: row.read<String>('source_record_hash'),
      normalizationVersion: row.read<String>('normalization_version'),
      sessionType: row.read<String>('session_type'),
      startedAt: _fromEpochMillis(row.read<int>('started_at')),
      endedAt: _fromEpochMillis(row.read<int>('ended_at')),
      timezone: row.readNullable<String>('timezone'),
      importedAt: _fromEpochMillis(row.read<int>('imported_at')),
      normalizedAt: _fromEpochMillis(row.read<int>('normalized_at')),
      createdAt: _fromEpochMillis(row.read<int>('created_at')),
      updatedAt: _fromEpochMillis(row.read<int>('updated_at')),
    );
  }
}

class SleepCanonicalStageSegmentsDao {
  const SleepCanonicalStageSegmentsDao(this._db);

  final AppDatabase _db;

  int _toEpochMillis(DateTime value) => value.toUtc().millisecondsSinceEpoch;

  DateTime _fromEpochMillis(int value) =>
      DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);

  Future<void> upsertBatch(
    List<SleepCanonicalStageSegmentCompanion> rows,
  ) async {
    await _db.transaction(() async {
      for (final row in rows) {
        await _db.customStatement(
          '''
          INSERT OR REPLACE INTO sleep_canonical_stage_segments (
            id,
            session_id,
            source_platform,
            source_app_id,
            source_confidence,
            source_record_hash,
            normalization_version,
            stage,
            started_at,
            ended_at,
            imported_at,
            normalized_at,
            updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            row.id,
            row.sessionId,
            row.sourcePlatform,
            row.sourceAppId,
            row.sourceConfidence,
            row.sourceRecordHash,
            row.normalizationVersion,
            row.stage,
            _toEpochMillis(row.startedAt),
            _toEpochMillis(row.endedAt),
            _toEpochMillis(row.importedAt),
            _toEpochMillis(row.normalizedAt),
            _toEpochMillis(DateTime.now()),
          ],
        );
      }
    });
  }

  Future<List<SleepCanonicalStageSegmentRecord>> findBySessionId(
    String sessionId,
  ) async {
    final result = await _db
        .customSelect(
          '''
      SELECT * FROM sleep_canonical_stage_segments
      WHERE session_id = ?
      ORDER BY started_at ASC
      ''',
          variables: [Variable<String>(sessionId)],
        )
        .get();
    return result.map(_mapRow).toList(growable: false);
  }

  Future<void> deleteBySessionIds(List<String> sessionIds) async {
    if (sessionIds.isEmpty) return;
    final placeholders = List.filled(sessionIds.length, '?').join(', ');
    await _db.customStatement(
      'DELETE FROM sleep_canonical_stage_segments WHERE session_id IN ($placeholders)',
      sessionIds.cast<Object?>(),
    );
  }

  SleepCanonicalStageSegmentRecord _mapRow(QueryRow row) {
    return SleepCanonicalStageSegmentRecord(
      id: row.read<String>('id'),
      sessionId: row.read<String>('session_id'),
      sourcePlatform: row.read<String>('source_platform'),
      sourceAppId: row.readNullable<String>('source_app_id'),
      sourceConfidence: row.readNullable<String>('source_confidence'),
      sourceRecordHash: row.read<String>('source_record_hash'),
      normalizationVersion: row.read<String>('normalization_version'),
      stage: row.read<String>('stage'),
      startedAt: _fromEpochMillis(row.read<int>('started_at')),
      endedAt: _fromEpochMillis(row.read<int>('ended_at')),
      importedAt: _fromEpochMillis(row.read<int>('imported_at')),
      normalizedAt: _fromEpochMillis(row.read<int>('normalized_at')),
      createdAt: _fromEpochMillis(row.read<int>('created_at')),
      updatedAt: _fromEpochMillis(row.read<int>('updated_at')),
    );
  }
}

class SleepCanonicalHeartRateSamplesDao {
  const SleepCanonicalHeartRateSamplesDao(this._db);

  final AppDatabase _db;

  int _toEpochMillis(DateTime value) => value.toUtc().millisecondsSinceEpoch;

  DateTime _fromEpochMillis(int value) =>
      DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);

  Future<void> upsertBatch(
    List<SleepCanonicalHeartRateSampleCompanion> rows,
  ) async {
    await _db.transaction(() async {
      for (final row in rows) {
        await _db.customStatement(
          '''
          INSERT OR REPLACE INTO sleep_canonical_heart_rate_samples (
            id,
            session_id,
            source_platform,
            source_app_id,
            source_confidence,
            source_record_hash,
            normalization_version,
            sampled_at,
            bpm,
            imported_at,
            normalized_at,
            updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            row.id,
            row.sessionId,
            row.sourcePlatform,
            row.sourceAppId,
            row.sourceConfidence,
            row.sourceRecordHash,
            row.normalizationVersion,
            _toEpochMillis(row.sampledAt),
            row.bpm,
            _toEpochMillis(row.importedAt),
            _toEpochMillis(row.normalizedAt),
            _toEpochMillis(DateTime.now()),
          ],
        );
      }
    });
  }

  Future<List<SleepCanonicalHeartRateSampleRecord>> findBySessionId(
    String sessionId,
  ) async {
    final result = await _db
        .customSelect(
          '''
      SELECT * FROM sleep_canonical_heart_rate_samples
      WHERE session_id = ?
      ORDER BY sampled_at ASC
      ''',
          variables: [Variable<String>(sessionId)],
        )
        .get();
    return result.map(_mapRow).toList(growable: false);
  }

  Future<void> deleteBySessionIds(List<String> sessionIds) async {
    if (sessionIds.isEmpty) return;
    final placeholders = List.filled(sessionIds.length, '?').join(', ');
    await _db.customStatement(
      'DELETE FROM sleep_canonical_heart_rate_samples WHERE session_id IN ($placeholders)',
      sessionIds.cast<Object?>(),
    );
  }

  SleepCanonicalHeartRateSampleRecord _mapRow(QueryRow row) {
    return SleepCanonicalHeartRateSampleRecord(
      id: row.read<String>('id'),
      sessionId: row.read<String>('session_id'),
      sourcePlatform: row.read<String>('source_platform'),
      sourceAppId: row.readNullable<String>('source_app_id'),
      sourceConfidence: row.readNullable<String>('source_confidence'),
      sourceRecordHash: row.read<String>('source_record_hash'),
      normalizationVersion: row.read<String>('normalization_version'),
      sampledAt: _fromEpochMillis(row.read<int>('sampled_at')),
      bpm: row.read<double>('bpm'),
      importedAt: _fromEpochMillis(row.read<int>('imported_at')),
      normalizedAt: _fromEpochMillis(row.read<int>('normalized_at')),
      createdAt: _fromEpochMillis(row.read<int>('created_at')),
      updatedAt: _fromEpochMillis(row.read<int>('updated_at')),
    );
  }
}
