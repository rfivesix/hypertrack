import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/drift_database.dart';
import 'package:hypertrack/features/sleep/data/persistence/dao/sleep_canonical_dao.dart';
import 'package:hypertrack/features/sleep/data/persistence/dao/sleep_nightly_analyses_dao.dart';
import 'package:hypertrack/features/sleep/data/persistence/dao/sleep_raw_imports_dao.dart';
import 'package:hypertrack/features/sleep/data/persistence/sleep_persistence_models.dart';

void main() {
  late AppDatabase database;
  late SleepRawImportsDao rawDao;
  late SleepCanonicalSessionsDao sessionsDao;
  late SleepCanonicalStageSegmentsDao stagesDao;
  late SleepCanonicalHeartRateSamplesDao hrDao;
  late SleepNightlyAnalysesDao analysesDao;

  setUp(() {
    database = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );
    rawDao = SleepRawImportsDao(database);
    sessionsDao = SleepCanonicalSessionsDao(database);
    stagesDao = SleepCanonicalStageSegmentsDao(database);
    hrDao = SleepCanonicalHeartRateSamplesDao(database);
    analysesDao = SleepNightlyAnalysesDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('sleep migration creates expected tables', () async {
    final rows = await database.customSelect(
      '''
      SELECT name FROM sqlite_master
      WHERE type = 'table'
      AND name IN (
        'sleep_raw_imports',
        'sleep_canonical_sessions',
        'sleep_canonical_stage_segments',
        'sleep_canonical_heart_rate_samples',
        'sleep_nightly_analyses'
      )
      ORDER BY name
      ''',
    ).get();

    expect(
      rows.map((r) => r.read<String>('name')).toList(growable: false),
      [
        'sleep_canonical_heart_rate_samples',
        'sleep_canonical_sessions',
        'sleep_canonical_stage_segments',
        'sleep_nightly_analyses',
        'sleep_raw_imports',
      ],
    );
  });

  test('raw dao insert and query by status/hash works', () async {
    final importedAt = DateTime.utc(2026, 2, 1, 1);
    await rawDao.upsert(
      SleepRawImportCompanion(
        id: 'raw-1',
        sourcePlatform: 'healthkit',
        sourceAppId: 'com.test.health',
        sourceConfidence: 'high',
        sourceRecordHash: 'hash-raw-1',
        importStatus: 'success',
        importedAt: importedAt,
        payloadJson: '{"sample":true}',
      ),
    );

    final byStatus = await rawDao.findByStatus('success');
    final byHash = await rawDao.findBySourceHash('hash-raw-1');
    final byRange = await rawDao.findByDateRange(
      fromInclusive: importedAt.subtract(const Duration(hours: 1)),
      toExclusive: importedAt.add(const Duration(hours: 1)),
    );

    expect(byStatus.length, 1);
    expect(byHash.length, 1);
    expect(byRange.length, 1);
    expect(byRange.single.payloadJson, '{"sample":true}');
  });

  test('canonical daos insert/query and delete-by-range semantics work', () async {
    final importedAt = DateTime.utc(2026, 2, 2, 7);
    final normalizedAt = DateTime.utc(2026, 2, 2, 7, 5);

    await rawDao.upsert(
      SleepRawImportCompanion(
        id: 'raw-1',
        sourcePlatform: 'health_connect',
        sourceAppId: 'com.android.healthconnect',
        sourceConfidence: 'medium',
        sourceRecordHash: 'hash-raw-for-session-1',
        importStatus: 'success',
        importedAt: importedAt,
        payloadJson: '{"seed":"canonical-test"}',
      ),
    );

    await sessionsDao.upsert(
      SleepCanonicalSessionCompanion(
        id: 'session-1',
        rawImportId: 'raw-1',
        sourcePlatform: 'health_connect',
        sourceAppId: 'com.android.healthconnect',
        sourceConfidence: 'medium',
        sourceRecordHash: 'hash-session-1',
        normalizationVersion: 'n1',
        sessionType: 'mainSleep',
        startedAt: DateTime.utc(2026, 2, 1, 22),
        endedAt: DateTime.utc(2026, 2, 2, 6),
        timezone: 'UTC',
        importedAt: importedAt,
        normalizedAt: normalizedAt,
      ),
    );

    await stagesDao.upsertBatch([
      SleepCanonicalStageSegmentCompanion(
        id: 'seg-1',
        sessionId: 'session-1',
        sourcePlatform: 'health_connect',
        sourceAppId: 'com.android.healthconnect',
        sourceConfidence: 'medium',
        sourceRecordHash: 'hash-seg-1',
        normalizationVersion: 'n1',
        stage: 'light',
        startedAt: DateTime.utc(2026, 2, 1, 22),
        endedAt: DateTime.utc(2026, 2, 1, 23),
        importedAt: importedAt,
        normalizedAt: normalizedAt,
      ),
    ]);

    await hrDao.upsertBatch([
      SleepCanonicalHeartRateSampleCompanion(
        id: 'hr-1',
        sessionId: 'session-1',
        sourcePlatform: 'health_connect',
        sourceAppId: 'com.android.healthconnect',
        sourceConfidence: 'medium',
        sourceRecordHash: 'hash-hr-1',
        normalizationVersion: 'n1',
        sampledAt: DateTime.utc(2026, 2, 2, 1),
        bpm: 52,
        importedAt: importedAt,
        normalizedAt: normalizedAt,
      ),
    ]);

    final sessions = await sessionsDao.findByDateRange(
      fromInclusive: DateTime.utc(2026, 2, 1, 20),
      toExclusive: DateTime.utc(2026, 2, 2, 8),
    );
    final segments = await stagesDao.findBySessionId('session-1');
    final samples = await hrDao.findBySessionId('session-1');

    expect(sessions.length, 1);
    expect(segments.length, 1);
    expect(samples.length, 1);

    await sessionsDao.deleteByDateRange(
      fromInclusive: DateTime.utc(2026, 2, 1, 20),
      toExclusive: DateTime.utc(2026, 2, 2, 8),
    );

    final sessionsAfterDelete = await sessionsDao.findByDateRange(
      fromInclusive: DateTime.utc(2026, 2, 1, 20),
      toExclusive: DateTime.utc(2026, 2, 2, 8),
    );
    final rawAfterDelete = await rawDao.findBySourceHash('hash-raw-for-session-1');
    final segmentsAfterDelete = await stagesDao.findBySessionId('session-1');
    final samplesAfterDelete = await hrDao.findBySessionId('session-1');

    expect(sessionsAfterDelete, isEmpty);
    expect(rawAfterDelete.length, 1);
    expect(segmentsAfterDelete, isEmpty);
    expect(samplesAfterDelete, isEmpty);
  });

  test('derived analyses dao insert/query/delete by night range works', () async {
    final importedAt = DateTime.utc(2026, 2, 2, 6, 30);
    final normalizedAt = DateTime.utc(2026, 2, 2, 6, 35);
    await rawDao.upsert(
      SleepRawImportCompanion(
        id: 'raw-for-analysis-session',
        sourcePlatform: 'healthkit',
        sourceAppId: 'com.apple.health',
        sourceConfidence: 'high',
        sourceRecordHash: 'hash-raw-for-analysis-session',
        importStatus: 'success',
        importedAt: importedAt,
        payloadJson: '{"seed":"analysis-test"}',
      ),
    );
    await sessionsDao.upsert(
      SleepCanonicalSessionCompanion(
        id: 'session-1',
        rawImportId: 'raw-for-analysis-session',
        sourcePlatform: 'healthkit',
        sourceAppId: 'com.apple.health',
        sourceConfidence: 'high',
        sourceRecordHash: 'hash-session-for-analysis',
        normalizationVersion: 'n1',
        sessionType: 'mainSleep',
        startedAt: DateTime.utc(2026, 2, 1, 22),
        endedAt: DateTime.utc(2026, 2, 2, 6),
        timezone: 'UTC',
        importedAt: importedAt,
        normalizedAt: normalizedAt,
      ),
    );

    await analysesDao.upsert(
      SleepNightlyAnalysisCompanion(
        id: 'analysis-1',
        sessionId: 'session-1',
        sourcePlatform: 'healthkit',
        sourceAppId: 'com.apple.health',
        sourceConfidence: 'high',
        sourceRecordHash: 'hash-analysis-1',
        normalizationVersion: 'n1',
        analysisVersion: 'a1',
        nightDate: '2026-02-02',
        score: 81,
        totalSleepMinutes: 432,
        sleepEfficiencyPct: 91.2,
        restingHeartRateBpm: 50,
        analyzedAt: DateTime.utc(2026, 2, 2, 7),
      ),
    );

    final bySession = await analysesDao.findBySessionId('session-1');
    final byRange = await analysesDao.findByNightRange(
      fromNightDateInclusive: '2026-02-01',
      toNightDateInclusive: '2026-02-03',
    );

    expect(bySession.length, 1);
    expect(byRange.single.totalSleepMinutes, 432);

    await analysesDao.deleteByNightRange(
      fromNightDateInclusive: '2026-02-01',
      toNightDateInclusive: '2026-02-03',
    );

    final afterDelete = await analysesDao.findBySessionId('session-1');
    expect(afterDelete, isEmpty);
  });
}
