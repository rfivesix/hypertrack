import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/drift_database.dart';
import 'package:hypertrack/features/sleep/data/persistence/dao/sleep_canonical_dao.dart';
import 'package:hypertrack/features/sleep/data/persistence/dao/sleep_nightly_analyses_dao.dart';
import 'package:hypertrack/features/sleep/data/persistence/dao/sleep_raw_imports_dao.dart';
import 'package:hypertrack/features/sleep/data/persistence/sleep_persistence_models.dart';
import 'package:hypertrack/features/sleep/data/repository/sleep_query_repository.dart';

void main() {
  late AppDatabase db;
  late SleepRawImportsDao rawDao;
  late SleepCanonicalSessionsDao sessionsDao;
  late SleepNightlyAnalysesDao analysesDao;

  setUp(() {
    db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
    rawDao = SleepRawImportsDao(db);
    sessionsDao = SleepCanonicalSessionsDao(db);
    analysesDao = SleepNightlyAnalysesDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed() async {
    final importedAt = DateTime.utc(2026, 3, 1, 8);
    await rawDao.upsert(
      SleepRawImportCompanion(
        id: 'raw-1',
        sourcePlatform: 'healthkit',
        sourceRecordHash: 'hash-1',
        importStatus: 'success',
        importedAt: importedAt,
        payloadJson: '{}',
      ),
    );
    await sessionsDao.upsert(
      SleepCanonicalSessionCompanion(
        id: 'session-1',
        rawImportId: 'raw-1',
        sourcePlatform: 'healthkit',
        sourceRecordHash: 'hash-session-1',
        normalizationVersion: 'n1',
        sessionType: 'mainSleep',
        startedAt: DateTime.utc(2026, 2, 28, 22),
        endedAt: DateTime.utc(2026, 3, 1, 6),
        importedAt: importedAt,
        normalizedAt: importedAt,
      ),
    );
    await analysesDao.upsert(
      SleepNightlyAnalysisCompanion(
        id: 'analysis-1',
        sessionId: 'session-1',
        sourcePlatform: 'healthkit',
        sourceRecordHash: 'hash-analysis-1',
        normalizationVersion: 'n1',
        analysisVersion: 'a1',
        nightDate: '2026-03-01',
        score: 80,
        totalSleepMinutes: 420,
        analyzedAt: DateTime.utc(2026, 3, 1, 7),
      ),
    );
  }

  test('reads nightly analysis by date', () async {
    await seed();
    final repo = DriftSleepQueryRepository(database: db);
    final analysis = await repo.getNightlyAnalysisByDate(DateTime(2026, 3, 1));
    expect(analysis, isNotNull);
    expect(analysis!.score, 80);
  });

  test('reads analyses in date range and returns empty for missing data',
      () async {
    await seed();
    final repo = DriftSleepQueryRepository(database: db);
    final rows = await repo.getAnalysesInRange(
      fromInclusive: DateTime(2026, 2, 28),
      toInclusive: DateTime(2026, 3, 2),
    );
    expect(rows.length, 1);

    final empty = await repo.getAnalysesInRange(
      fromInclusive: DateTime(2026, 4, 1),
      toInclusive: DateTime(2026, 4, 2),
    );
    expect(empty, isEmpty);
  });
}
