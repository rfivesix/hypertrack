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
      SELECT
        score,
        interruptions_count,
        interruptions_wake_minutes,
        score_completeness,
        regularity_sri,
        regularity_valid_days,
        regularity_is_stable
      FROM sleep_nightly_analyses
      LIMIT 1
      ''',
    ).getSingle();
    expect(analysis.readNullable<double>('score'), isNotNull);
    expect(analysis.readNullable<int>('interruptions_count'), 1);
    expect(analysis.readNullable<int>('interruptions_wake_minutes'), 5);
    expect(
      analysis.readNullable<double>('score_completeness'),
      closeTo(0.70, 0.0001),
    );
    expect(analysis.readNullable<double>('regularity_sri'), isNull);
    expect(analysis.readNullable<int>('regularity_valid_days'), lessThan(5));
    expect(analysis.readNullable<int>('regularity_is_stable'), 0);

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

  test('pipeline uses regularity in score when enough valid days exist',
      () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
    final service = SleepPipelineService(database: db);

    final sessions = <SleepIngestionSession>[];
    final segments = <SleepIngestionStageSegment>[];
    for (var i = 0; i < 7; i++) {
      final start = DateTime.utc(2026, 3, 1 + i, 22);
      final end = DateTime.utc(2026, 3, 2 + i, 6);
      final sessionId = 'session-$i';
      sessions.add(
        SleepIngestionSession(
          recordId: sessionId,
          startAtUtc: start,
          endAtUtc: end,
          platformSessionType: 'sleep',
          sourcePlatform: 'healthkit',
        ),
      );
      segments.addAll([
        SleepIngestionStageSegment(
          recordId: 'seg-$i-1',
          sessionRecordId: sessionId,
          startAtUtc: start,
          endAtUtc: start.add(const Duration(hours: 4)),
          platformStage: 'core',
          sourcePlatform: 'healthkit',
        ),
        SleepIngestionStageSegment(
          recordId: 'seg-$i-2',
          sessionRecordId: sessionId,
          startAtUtc: start.add(const Duration(hours: 4)),
          endAtUtc: start.add(const Duration(hours: 4, minutes: 10)),
          platformStage: 'awake',
          sourcePlatform: 'healthkit',
        ),
        SleepIngestionStageSegment(
          recordId: 'seg-$i-3',
          sessionRecordId: sessionId,
          startAtUtc: start.add(const Duration(hours: 4, minutes: 10)),
          endAtUtc: end,
          platformStage: 'core',
          sourcePlatform: 'healthkit',
        ),
      ]);
    }
    final batch = SleepRawIngestionBatch(
      sessions: sessions,
      stageSegments: segments,
      heartRateSamples: const [],
    );
    await service.runImport(batch: batch);

    final latest = await db.customSelect(
      '''
      SELECT
        score,
        score_completeness,
        regularity_sri,
        regularity_valid_days,
        regularity_is_stable
      FROM sleep_nightly_analyses
      WHERE night_date = '2026-03-08'
      LIMIT 1
      ''',
    ).getSingle();
    expect(latest.readNullable<double>('score'), isNotNull);
    expect(
      latest.readNullable<double>('score_completeness'),
      closeTo(1.0, 0.0001),
    );
    expect(latest.readNullable<double>('regularity_sri'), isNotNull);
    expect(latest.readNullable<int>('regularity_valid_days'),
        greaterThanOrEqualTo(7));
    expect(latest.readNullable<int>('regularity_is_stable'), 1);

    await db.close();
  });
}
