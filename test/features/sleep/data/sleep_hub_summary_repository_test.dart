import 'dart:math' as math;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/sleep/data/processing/sleep_pipeline_service.dart';
import 'package:train_libre/features/sleep/data/sleep_hub_summary_repository.dart';
import 'package:train_libre/features/sleep/platform/ingestion/sleep_ingestion_models.dart';

SleepRawIngestionBatch _batchForNight({
  required int index,
  required int startHour, // hour in UTC, e.g. 22 or 23
  required int startMinute, // e.g. 0 or 30
  required int durationHours,
  required double bpm,
  required int awakeMinutes,
}) {
  final start = DateTime.utc(2026, 3, 1 + index, startHour, startMinute);
  final end = start.add(Duration(hours: durationHours));
  final awakeStart = start.add(const Duration(hours: 3));
  final awakeEnd = awakeStart.add(Duration(minutes: awakeMinutes));
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
  group('SleepHubSummaryRepository Unit Tests', () {
    late AppDatabase db;
    late SleepPipelineService pipeline;
    late SleepHubSummaryRepository repository;

    setUp(() {
      db = AppDatabase(
        NativeDatabase.memory(
          setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
        ),
      );
      pipeline = SleepPipelineService(database: db);
      repository = SleepHubSummaryRepository(database: db);
    });

    tearDown(() async {
      await repository.dispose();
      await db.close();
    });

    test('fetchSummary returns empty summary with hasData == false when database is empty', () async {
      final summary = await repository.fetchSummary(
        endDate: DateTime.utc(2026, 3, 10),
        daysBack: 7,
      );

      expect(summary.hasData, isFalse);
      expect(summary.averageScore, isNull);
      expect(summary.averageDuration, isNull);
      expect(summary.averageBedtimeMinutes, isNull);
      expect(summary.averageInterruptions, isNull);
      expect(summary.averageWakeDuration, isNull);
      expect(summary.nightsCount, 0);
    });

    test('fetchSummary returns empty summary when daysBack is 0 or negative', () async {
      // Seed some data first to ensure it's ignored when daysBack <= 0
      await pipeline.runImport(
        batch: _batchForNight(
          index: 0,
          startHour: 22,
          startMinute: 0,
          durationHours: 8,
          bpm: 50.0,
          awakeMinutes: 5,
        ),
      );

      final summaryZero = await repository.fetchSummary(
        endDate: DateTime.utc(2026, 3, 2),
        daysBack: 0,
      );
      expect(summaryZero.hasData, isFalse);

      final summaryNeg = await repository.fetchSummary(
        endDate: DateTime.utc(2026, 3, 2),
        daysBack: -5,
      );
      expect(summaryNeg.hasData, isFalse);
    });

    test('fetchSummary handles single night summary correctly', () async {
      await pipeline.runImport(
        batch: _batchForNight(
          index: 0,
          startHour: 22,
          startMinute: 30,
          durationHours: 8,
          bpm: 60.0,
          awakeMinutes: 10,
        ),
      );

      final summary = await repository.fetchSummary(
        endDate: DateTime.utc(2026, 3, 2),
        daysBack: 1,
      );

      expect(summary.hasData, isTrue);
      expect(summary.nightsCount, 1);
      expect(summary.averageScore, isNotNull);

      // Duration: 8 hours (480 mins) total session minus 10 mins awake = 470 mins (7 hours, 50 mins)
      expect(summary.averageDuration, const Duration(hours: 7, minutes: 50));

      // Circular bedtime checks
      final startUtc = DateTime.utc(2026, 3, 1, 22, 30);
      final localStart = startUtc.toLocal();
      final expectedBedtimeMinutes = localStart.hour * 60 + localStart.minute;
      expect(summary.averageBedtimeMinutes, expectedBedtimeMinutes);

      expect(summary.averageInterruptions, 1.0);
      expect(summary.averageWakeDuration, const Duration(minutes: 10));
    });

    test('fetchSummary handles multiple nights simple averages correctly', () async {
      // Import 3 nights on separate days
      await pipeline.runImport(
        batch: _batchForNight(
          index: 0,
          startHour: 22,
          startMinute: 0,
          durationHours: 8, // 480 mins total, 470 mins sleep
          bpm: 50.0,
          awakeMinutes: 10,
        ),
      );
      await pipeline.runImport(
        batch: _batchForNight(
          index: 1,
          startHour: 23,
          startMinute: 0,
          durationHours: 6, // 360 mins total, 340 mins sleep
          bpm: 60.0,
          awakeMinutes: 20,
        ),
      );
      await pipeline.runImport(
        batch: _batchForNight(
          index: 2,
          startHour: 21,
          startMinute: 0,
          durationHours: 7, // 420 mins total, 405 mins sleep
          bpm: 55.0,
          awakeMinutes: 15,
        ),
      );

      final summary = await repository.fetchSummary(
        endDate: DateTime.utc(2026, 3, 4),
        daysBack: 4,
      );

      expect(summary.hasData, isTrue);
      expect(summary.nightsCount, 3);
      expect(summary.averageScore, isNotNull);

      // Average duration: (470 + 340 + 405) / 3 = 405 minutes (6 hours, 45 minutes)
      expect(summary.averageDuration, const Duration(hours: 6, minutes: 45));

      // Interruptions average: (1 + 1 + 1) / 3 = 1.0
      expect(summary.averageInterruptions, 1.0);

      // Wake duration average: (10 + 20 + 15) / 3 = 15 minutes
      expect(summary.averageWakeDuration, const Duration(minutes: 15));
    });

    test('fetchSummary resolves bedtime circular mean around midnight crossings correctly', () async {
      // Let's seed two nights with bedtimes crossing midnight on separate days (e.g. index 0 and 2)
      final start1 = DateTime.utc(2026, 3, 1, 23, 30);
      final start2 = DateTime.utc(2026, 3, 3, 0, 30);

      final local1 = start1.toLocal();
      final local2 = start2.toLocal();

      final m1 = local1.hour * 60 + local1.minute;
      final m2 = local2.hour * 60 + local2.minute;

      // Seed these exact nights
      await pipeline.runImport(
        batch: _batchForNight(
          index: 0,
          startHour: 23,
          startMinute: 30,
          durationHours: 8,
          bpm: 55.0,
          awakeMinutes: 5,
        ),
      );
      await pipeline.runImport(
        batch: _batchForNight(
          index: 2,
          startHour: 0,
          startMinute: 30,
          durationHours: 8,
          bpm: 55.0,
          awakeMinutes: 5,
        ),
      );

      final summary = await repository.fetchSummary(
        endDate: DateTime.utc(2026, 3, 5),
        daysBack: 5,
      );

      expect(summary.hasData, isTrue);
      expect(summary.nightsCount, 2);

      // Average bedtime circular mean check:
      final angle1 = (m1 / 1440) * 2 * math.pi;
      final angle2 = (m2 / 1440) * 2 * math.pi;
      final avgSin = (math.sin(angle1) + math.sin(angle2)) / 2;
      final avgCos = (math.cos(angle1) + math.cos(angle2)) / 2;
      final avgAngle = math.atan2(avgSin, avgCos);
      final normalized = avgAngle < 0 ? avgAngle + 2 * math.pi : avgAngle;
      final expectedCircularMean = (normalized / (2 * math.pi) * 1440).round() % 1440;

      expect(summary.averageBedtimeMinutes, expectedCircularMean);
    });

    test('fetchSummary computes fallback for interruptions and wake when persisted fields are null', () async {
      await pipeline.runImport(
        batch: _batchForNight(
          index: 0,
          startHour: 22,
          startMinute: 0,
          durationHours: 8,
          bpm: 55.0,
          awakeMinutes: 12,
        ),
      );

      // Force raw DB updates to set analysis fields to null, forcing timeline repair fallbacks
      await db.customStatement('''
        UPDATE sleep_nightly_analyses
        SET interruptions_count = NULL,
            interruptions_wake_minutes = NULL
        WHERE session_id = 'session-0'
      ''');

      final summary = await repository.fetchSummary(
        endDate: DateTime.utc(2026, 3, 2),
        daysBack: 1,
      );

      expect(summary.hasData, isTrue);
      expect(summary.nightsCount, 1);
      // Timeline fallback for awakeMinutes should be const Duration(minutes: 12)
      expect(summary.averageInterruptions, 1.0);
      expect(summary.averageWakeDuration, const Duration(minutes: 12));
    });
  });
}
