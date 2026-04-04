import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/drift_database.dart';
import 'package:hypertrack/features/sleep/platform/health_connect/health_connect_sleep_adapter.dart';
import 'package:hypertrack/features/sleep/platform/healthkit/healthkit_sleep_adapter.dart';
import 'package:hypertrack/features/sleep/platform/ingestion/sleep_ingestion_models.dart';
import 'package:hypertrack/features/sleep/platform/permissions/sleep_permission_models.dart';
import 'package:hypertrack/features/sleep/platform/permissions/sleep_permissions_service.dart';
import 'package:hypertrack/features/sleep/platform/sleep_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PermissionService implements SleepPermissionsService {
  const _PermissionService(this.outcome);
  final SleepPermissionOutcome outcome;

  @override
  Future<SleepPermissionOutcome> checkStatus() async => outcome;

  @override
  Future<SleepPermissionOutcome> requestAccess() async => outcome;
}

class _HealthKitSource implements HealthKitDataSource {
  const _HealthKitSource(this.batch);
  final SleepRawIngestionBatch batch;

  @override
  Future<SleepRawIngestionBatch> readSleepAndHeartRate({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async =>
      batch;
}

class _HealthConnectSource implements HealthConnectDataSource {
  const _HealthConnectSource(this.batch);
  final SleepRawIngestionBatch batch;

  @override
  Future<SleepRawIngestionBatch> readSleepAndHeartRate({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async =>
      batch;
}

SleepRawIngestionBatch _batch() {
  final sessionStart = DateTime.utc(2026, 3, 29, 22);
  final sessionEnd = DateTime.utc(2026, 3, 30, 6);
  return SleepRawIngestionBatch(
    sessions: [
      SleepIngestionSession(
        recordId: 's1',
        startAtUtc: sessionStart,
        endAtUtc: sessionEnd,
        platformSessionType: 'sleep',
        sourcePlatform: 'apple_healthkit',
      ),
    ],
    stageSegments: [
      SleepIngestionStageSegment(
        recordId: 'seg1',
        sessionRecordId: 's1',
        startAtUtc: sessionStart,
        endAtUtc: sessionStart.add(const Duration(hours: 2)),
        platformStage: 'core',
        sourcePlatform: 'apple_healthkit',
      ),
    ],
    heartRateSamples: [
      SleepIngestionHeartRateSample(
        recordId: 'hr1',
        sessionRecordId: 's1',
        sampledAtUtc: sessionStart.add(const Duration(hours: 1)),
        bpm: 54,
        sourcePlatform: 'apple_healthkit',
      ),
    ],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('importRecent persists mapped data when permission ready', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
    final service = SleepSyncService.withOverrides(
      iosPermissionsService: const _PermissionService(
        SleepPermissionOutcome.ready(),
      ),
      androidPermissionsService: const _PermissionService(
        SleepPermissionOutcome.ready(),
      ),
      iosDataSource: _HealthKitSource(_batch()),
      androidDataSource: _HealthConnectSource(_batch()),
      database: db,
    );
    await service.setTrackingEnabled(true);

    final result = await service.importRecent();
    expect(result.success, isTrue);

    final sessions = await db
        .customSelect('SELECT COUNT(*) c FROM sleep_canonical_sessions')
        .getSingle();
    final segments = await db
        .customSelect('SELECT COUNT(*) c FROM sleep_canonical_stage_segments')
        .getSingle();
    final hrs = await db
        .customSelect(
          'SELECT COUNT(*) c FROM sleep_canonical_heart_rate_samples',
        )
        .getSingle();
    final analyses = await db.customSelect('''
      SELECT score, interruptions_count
      FROM sleep_nightly_analyses
      LIMIT 1
      ''').getSingle();

    expect(sessions.read<int>('c'), greaterThan(0));
    expect(segments.read<int>('c'), greaterThan(0));
    expect(hrs.read<int>('c'), greaterThan(0));
    expect(analyses.readNullable<double>('score'), isNotNull);
    expect(analyses.readNullable<int>('interruptions_count'), isNotNull);
    await db.close();
  });

  test('importRecent returns denied when tracking disabled', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
    final service = SleepSyncService.withOverrides(
      iosPermissionsService: const _PermissionService(
        SleepPermissionOutcome.ready(),
      ),
      androidPermissionsService: const _PermissionService(
        SleepPermissionOutcome.ready(),
      ),
      iosDataSource: _HealthKitSource(_batch()),
      androidDataSource: _HealthConnectSource(_batch()),
      database: db,
    );

    final result = await service.importRecent();
    expect(result.success, isFalse);
    expect(result.permissionState, SleepPermissionState.denied);
    await db.close();
  });

  test('importRecentIfDue throttles repeated automatic imports', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
    final service = SleepSyncService.withOverrides(
      iosPermissionsService: const _PermissionService(
        SleepPermissionOutcome.ready(),
      ),
      androidPermissionsService: const _PermissionService(
        SleepPermissionOutcome.ready(),
      ),
      iosDataSource: _HealthKitSource(_batch()),
      androidDataSource: _HealthConnectSource(_batch()),
      database: db,
    );
    await service.setTrackingEnabled(true);

    final first = await service.importRecentIfDue(
      minInterval: const Duration(hours: 6),
    );
    expect(first, isNotNull);
    expect(first!.success, isTrue);

    final second = await service.importRecentIfDue(
      minInterval: const Duration(hours: 6),
    );
    expect(second, isNull);

    final analysesCount = await db
        .customSelect('SELECT COUNT(*) c FROM sleep_nightly_analyses')
        .getSingle();
    expect(analysesCount.read<int>('c'), 1);
    await db.close();
  });
}
