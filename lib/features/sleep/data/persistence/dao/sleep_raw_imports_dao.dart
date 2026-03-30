import '../../../../../data/drift_database.dart';
import '../sleep_persistence_models.dart';

class SleepRawImportsDao {
  const SleepRawImportsDao(this._db);

  final AppDatabase _db;

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
        row.importedAt,
        row.payloadJson,
        DateTime.now().toUtc(),
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
        Variable<DateTime>(fromInclusive),
        Variable<DateTime>(toExclusive),
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
      <Object?>[fromInclusive, toExclusive],
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
      importedAt: row.read<DateTime>('imported_at'),
      payloadJson: row.read<String>('payload_json'),
      createdAt: row.read<DateTime>('created_at'),
      updatedAt: row.read<DateTime>('updated_at'),
    );
  }
}
