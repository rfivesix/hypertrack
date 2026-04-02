import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/drift_database.dart';
import 'package:hypertrack/features/sleep/data/processing/sleep_pipeline_service.dart';
import 'package:hypertrack/features/sleep/data/sleep_day_repository.dart';
import 'package:hypertrack/features/sleep/platform/ingestion/sleep_ingestion_models.dart';

SleepRawIngestionBatch _batchForNight({
  required int index,
  required double bpm,
}) {
  final start = DateTime.utc(2026, 3, 1 + index, 22);
  final end = start.add(const Duration(hours: 8));
  final awakeStart = start.add(const Duration(hours: 3));
  final awakeEnd = awakeStart.add(const Duration(minutes: 5));
  return SleepRawIngestionBatch(
    sessions: [
      SleepIngestionSession(
        recordId: 'session-$index',
        startAtUtc: start,
        endAtUtc: end,
        platformSessionType: 'sleep',
        sourcePlatform: 'health_connect',
      ),
    ],
    stageSegments: [
      SleepIngestionStageSegment(
        recordId: 'seg-$index-1',
        sessionRecordId: 'session-$index',
        startAtUtc: start,
        endAtUtc: awakeStart,
        platformStage: 'light',
        sourcePlatform: 'health_connect',
      ),
      SleepIngestionStageSegment(
        recordId: 'seg-$index-2',
        sessionRecordId: 'session-$index',
        startAtUtc: awakeStart,
        endAtUtc: awakeEnd,
        platformStage: 'awake',
        sourcePlatform: 'health_connect',
      ),
      SleepIngestionStageSegment(
        recordId: 'seg-$index-3',
        sessionRecordId: 'session-$index',
        startAtUtc: awakeEnd,
        endAtUtc: end,
        platformStage: 'light',
        sourcePlatform: 'health_connect',
      ),
    ],
    heartRateSamples: List.generate(6, (sampleIndex) {
      return SleepIngestionHeartRateSample(
        recordId: 'hr-$index-$sampleIndex',
        sessionRecordId: 'session-$index',
        sampledAtUtc: start.add(Duration(minutes: 30 * (sampleIndex + 1))),
        bpm: bpm + sampleIndex,
        sourcePlatform: 'health_connect',
      );
    }),
  );
}

void main() {
  test('fetchOverview surfaces score, interruptions, and HR baseline/delta',
      () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
    final pipeline = SleepPipelineService(database: db);

    for (var i = 0; i < 11; i += 1) {
      await pipeline.runImport(
        batch: _batchForNight(index: i, bpm: 50 + (i % 3)),
      );
    }

    final repository = SleepDayRepository(database: db);
    final overview = await repository.fetchOverview(DateTime.utc(2026, 3, 12));

    expect(overview, isNotNull);
    expect(overview!.analysis.score, isNotNull);
    expect(overview.interruptionsCount, 1);
    expect(overview.interruptionsWakeDuration, const Duration(minutes: 5));
    expect(overview.sleepHrAvg, isNotNull);
    expect(overview.baselineSleepHr, isNotNull);
    expect(overview.deltaSleepHr, isNotNull);
    expect(overview.heartRateSamples, isNotEmpty);
    expect(overview.heartRateSamples.length, 6);
    expect(overview.heartRateSamples.first.bpm, closeTo(51, 0.001));
    expect(
      overview.heartRateSamples.first.sampledAtUtc.isBefore(
        overview.heartRateSamples.last.sampledAtUtc,
      ),
      isTrue,
    );

    await db.close();
  });

  test(
      'fetchOverview computes interruption fallback when persisted fields null',
      () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
    final pipeline = SleepPipelineService(database: db);
    await pipeline.runImport(batch: _batchForNight(index: 0, bpm: 52));

    await db.customStatement(
      '''
      UPDATE sleep_nightly_analyses
      SET interruptions_count = NULL,
          interruptions_wake_minutes = NULL
      WHERE session_id = 'session-0'
      ''',
    );

    final repository = SleepDayRepository(database: db);
    final overview = await repository.fetchOverview(DateTime.utc(2026, 3, 2));

    expect(overview, isNotNull);
    expect(overview!.interruptionsCount, 1);
    expect(overview.interruptionsWakeDuration, const Duration(minutes: 5));

    await db.close();
  });
}
