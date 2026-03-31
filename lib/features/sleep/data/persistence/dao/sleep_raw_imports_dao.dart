import 'package:drift/drift.dart';

import '../../../../../data/drift_database.dart';
import '../sleep_persistence_models.dart';

class SleepRawImportsDao {
  const SleepRawImportsDao(this._db);

  final AppDatabase _db;

  int _toEpochMillis(DateTime value) => value.toUtc().millisecondsSinceEpoch;

  DateTime _fromEpochMillis(int value) =>
      DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);

  Future<void> upsert(SleepRawImportCompanion row) async {
    await _db.customStatement(
      '''
      INSERT OR REPLACE INTO sleep_raw_imports (
        id,
        source_platform,
        source_app_id,
        source_confidence,
        source_record_hash,
        import_status,
        error_code,
        error_message,
        imported_at,
        payload_json,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      <Object?>[
        row.id,
        row.sourcePlatform,
        row.sourceAppId,
        row.sourceConfidence,
        row.sourceRecordHash,
        row.importStatus,
        row.errorCode,
        row.errorMessage,
        _toEpochMillis(row.importedAt),
        row.payloadJson,
        _toEpochMillis(DateTime.now()),
      ],
    );
  }

  Future<void> upsertBatch(List<SleepRawImportCompanion> rows) async {
    await _db.transaction(() async {
      for (final row in rows) {
        await upsert(row);
      }
    });
  }

  Future<List<SleepRawImportRecord>> findByDateRange({
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) async {
    final result = await _db.customSelect(
      '''
      SELECT * FROM sleep_raw_imports
      WHERE imported_at >= ? AND imported_at < ?
      ORDER BY imported_at ASC
      ''',
      variables: [
        Variable<int>(_toEpochMillis(fromInclusive)),
        Variable<int>(_toEpochMillis(toExclusive)),
      ],
    ).get();
    return result.map(_mapRaw).toList(growable: false);
  }

  Future<List<SleepRawImportRecord>> findBySourceHash(String sourceRecordHash) async {
    final result = await _db.customSelect(
      '''
      SELECT * FROM sleep_raw_imports
      WHERE source_record_hash = ?
      ORDER BY imported_at DESC
      ''',
      variables: [Variable<String>(sourceRecordHash)],
    ).get();
    return result.map(_mapRaw).toList(growable: false);
  }

  Future<List<SleepRawImportRecord>> findByStatus(String status) async {
    final result = await _db.customSelect(
      '''
      SELECT * FROM sleep_raw_imports
      WHERE import_status = ?
      ORDER BY imported_at DESC
      ''',
      variables: [Variable<String>(status)],
    ).get();
    return result.map(_mapRaw).toList(growable: false);
  }

  /// Deletes raw imports in [fromInclusive, toExclusive).
  ///
  /// This is intended for targeted recompute windows when raw archival needs to
  /// be replaced by a deterministic re-import.
  Future<void> deleteByImportedAtRange({
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) async {
    await _db.customStatement(
      'DELETE FROM sleep_raw_imports WHERE imported_at >= ? AND imported_at < ?',
      <Object?>[_toEpochMillis(fromInclusive), _toEpochMillis(toExclusive)],
    );
  }

  SleepRawImportRecord _mapRaw(QueryRow row) {
    return SleepRawImportRecord(
      id: row.read<String>('id'),
      sourcePlatform: row.read<String>('source_platform'),
      sourceAppId: row.readNullable<String>('source_app_id'),
      sourceConfidence: row.readNullable<String>('source_confidence'),
      sourceRecordHash: row.read<String>('source_record_hash'),
      importStatus: row.read<String>('import_status'),
      errorCode: row.readNullable<String>('error_code'),
      errorMessage: row.readNullable<String>('error_message'),
      importedAt: _fromEpochMillis(row.read<int>('imported_at')),
      payloadJson: row.read<String>('payload_json'),
      createdAt: _fromEpochMillis(row.read<int>('created_at')),
      updatedAt: _fromEpochMillis(row.read<int>('updated_at')),
    );
  }
}
