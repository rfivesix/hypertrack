import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/drift_database.dart';
import 'package:hypertrack/features/sleep/data/processing/sleep_pipeline_service.dart';
import 'package:hypertrack/features/sleep/platform/ingestion/sleep_ingestion_models.dart';

void main() {
  test('pipeline imports, persists analyses and supports forced recompute',
      () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
    final service = SleepPipelineService(database: db);

    final batch = SleepRawIngestionBatch(
      sessions: [
        SleepIngestionSession(
          recordId: 'session-1',
          startAtUtc: DateTime.utc(2026, 3, 1, 22),
          endAtUtc: DateTime.utc(2026, 3, 2, 6),
          platformSessionType: 'sleep',
          sourcePlatform: 'healthkit',
        ),
      ],
      stageSegments: [
        SleepIngestionStageSegment(
          recordId: 'seg-1',
          sessionRecordId: 'session-1',
          startAtUtc: DateTime.utc(2026, 3, 1, 22),
          endAtUtc: DateTime.utc(2026, 3, 2, 2),
          platformStage: 'core',
          sourcePlatform: 'healthkit',
        ),
        SleepIngestionStageSegment(
          recordId: 'seg-2',
          sessionRecordId: 'session-1',
          startAtUtc: DateTime.utc(2026, 3, 2, 2),
          endAtUtc: DateTime.utc(2026, 3, 2, 2, 5),
          platformStage: 'awake',
          sourcePlatform: 'healthkit',
        ),
        SleepIngestionStageSegment(
          recordId: 'seg-3',
          sessionRecordId: 'session-1',
          startAtUtc: DateTime.utc(2026, 3, 2, 2, 5),
          endAtUtc: DateTime.utc(2026, 3, 2, 6),
          platformStage: 'core',
          sourcePlatform: 'healthkit',
        ),
      ],
      heartRateSamples: [
        SleepIngestionHeartRateSample(
          recordId: 'hr-1',
          sessionRecordId: 'session-1',
          sampledAtUtc: DateTime.utc(2026, 3, 2, 1),
          bpm: 52,
          sourcePlatform: 'healthkit',
        ),
      ],
    );

    final first = await service.runImport(batch: batch);
    expect(first.importedSessions, 1);
    expect(first.analyzedNights, 1);

    final second = await service.runImport(batch: batch, forceRecompute: true);
    expect(second.importedSessions, 1);
    expect(second.analyzedNights, 1);

    final analysesCount = await db
        .customSelect('SELECT COUNT(*) c FROM sleep_nightly_analyses')
        .getSingle();
    expect(analysesCount.read<int>('c'), 1);

    final analysis = await db.customSelect(
      '''
      SELECT score, interruptions_count, interruptions_wake_minutes
      FROM sleep_nightly_analyses
      LIMIT 1
      ''',
    ).getSingle();
    expect(analysis.readNullable<double>('score'), isNotNull);
    expect(analysis.readNullable<int>('interruptions_count'), 1);
    expect(analysis.readNullable<int>('interruptions_wake_minutes'), 5);

    await db.close();
  });

  test('forced recompute deletes raw imports for sessions in target window',
      () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
    final service = SleepPipelineService(database: db);

    final batchOne = SleepRawIngestionBatch(
      sessions: [
        SleepIngestionSession(
          recordId: 'session-1',
          startAtUtc: DateTime.utc(2026, 3, 1, 22),
          endAtUtc: DateTime.utc(2026, 3, 2, 6),
          platformSessionType: 'sleep',
          sourcePlatform: 'healthkit',
        ),
      ],
      stageSegments: const [],
      heartRateSamples: const [],
    );

    final batchTwo = SleepRawIngestionBatch(
      sessions: [
        SleepIngestionSession(
          recordId: 'session-2',
          startAtUtc: DateTime.utc(2026, 3, 10, 22),
          endAtUtc: DateTime.utc(2026, 3, 11, 6),
          platformSessionType: 'sleep',
          sourcePlatform: 'healthkit',
        ),
      ],
      stageSegments: const [],
      heartRateSamples: const [],
    );

    await service.runImport(batch: batchOne);

    await service.runImport(
      batch: batchTwo,
      forceRecompute: true,
      recomputeFromInclusive: DateTime.utc(2026, 3, 1),
      recomputeToExclusive: DateTime.utc(2026, 3, 3),
    );

    final rows = await db
        .customSelect('SELECT id FROM sleep_raw_imports ORDER BY id')
        .get();
    final ids = rows.map((row) => row.read<String>('id')).toList();
    expect(ids, ['raw:session-2']);

    await db.close();
  });
}
