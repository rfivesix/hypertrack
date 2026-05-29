import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/sleep/platform/health_connect/health_connect_sleep_adapter.dart';
import 'package:train_libre/features/sleep/platform/healthkit/healthkit_sleep_adapter.dart';
import 'package:train_libre/features/sleep/platform/ingestion/sleep_ingestion_models.dart';
import 'package:train_libre/features/sleep/platform/permissions/sleep_permission_models.dart';
import 'package:train_libre/features/sleep/platform/permissions/sleep_permissions_service.dart';
import 'package:train_libre/features/sleep/platform/sleep_sync_service.dart';
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
  _HealthKitSource(this.batch);
  SleepRawIngestionBatch batch;

  @override
  Future<SleepRawIngestionBatch> readSleepAndHeartRate({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async =>
      batch;
}

class _HealthConnectSource implements HealthConnectDataSource {
  _HealthConnectSource(this.batch);
  SleepRawIngestionBatch batch;

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

  test('importRecent correctly updates sleep session duration and avoids duplicates/ghosts on corrected sync', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
    final initialBatch = _batch();
    final kitSource = _HealthKitSource(initialBatch);
    final connectSource = _HealthConnectSource(initialBatch);

    final service = SleepSyncService.withOverrides(
      iosPermissionsService: const _PermissionService(
        SleepPermissionOutcome.ready(),
      ),
      androidPermissionsService: const _PermissionService(
        SleepPermissionOutcome.ready(),
      ),
      iosDataSource: kitSource,
      androidDataSource: connectSource,
      database: db,
    );
    await service.setTrackingEnabled(true);

    // First import: initial state
    final firstResult = await service.importRecent();
    expect(firstResult.success, isTrue);

    // Verify initial values
    var sessions = await db
        .customSelect('SELECT * FROM sleep_canonical_sessions')
        .get();
    expect(sessions.length, 1);
    expect(sessions.first.read<String>('id'), 's1');
    expect(
      DateTime.fromMillisecondsSinceEpoch(sessions.first.read<int>('ended_at'), isUtc: true),
      DateTime.utc(2026, 3, 30, 6),
    );

    // Update batch to simulate wearable correcting the duration
    final updatedBatch = _updatedBatch();
    kitSource.batch = updatedBatch;
    connectSource.batch = updatedBatch;

    // Second import: corrected sync
    final secondResult = await service.importRecent();
    expect(secondResult.success, isTrue);

    // Verify that session s1 has been updated with the corrected end time,
    // and there is still exactly one session record (no duplicate row)
    var updatedSessions = await db
        .customSelect('SELECT * FROM sleep_canonical_sessions')
        .get();
    expect(updatedSessions.length, 1);
    expect(updatedSessions.first.read<String>('id'), 's1');
    expect(
      DateTime.fromMillisecondsSinceEpoch(updatedSessions.first.read<int>('ended_at'), isUtc: true),
      DateTime.utc(2026, 3, 30, 7), // 1 hour later
    );

    // Verify there are no duplicate/ghost segments remaining
    var segments = await db
        .customSelect('SELECT * FROM sleep_canonical_stage_segments')
        .get();
    expect(segments.length, 1);
    expect(segments.first.read<String>('id'), 'seg1_new');

    // Verify heart rates are also updated
    var hrs = await db
        .customSelect('SELECT * FROM sleep_canonical_heart_rate_samples')
        .get();
    expect(hrs.length, 1);
    expect(hrs.first.read<String>('id'), 'hr1_new');

    await db.close();
  });

  test('importRecent clears out overlapping ghost-sessions inside the time window', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (rawDb) => rawDb.execute('PRAGMA foreign_keys = ON;'),
      ),
    );

    // Create a database state with a ghost session
    final kitSource = _HealthKitSource(_batch());
    final connectSource = _HealthConnectSource(_batch());

    final service = SleepSyncService.withOverrides(
      iosPermissionsService: const _PermissionService(
        SleepPermissionOutcome.ready(),
      ),
      androidPermissionsService: const _PermissionService(
        SleepPermissionOutcome.ready(),
      ),
      iosDataSource: kitSource,
      androidDataSource: connectSource,
      database: db,
    );
    await service.setTrackingEnabled(true);

    // Import the first session 's1' (22:00 to 06:00)
    await service.importRecent();

    // Now simulate an overlapping but distinct consolidated session 's2' (from 23:00 to 05:00)
    // which should replace the old one due to temporal overlap
    final overlappingBatch = SleepRawIngestionBatch(
      sessions: [
        SleepIngestionSession(
          recordId: 's2',
          startAtUtc: DateTime.utc(2026, 3, 29, 23),
          endAtUtc: DateTime.utc(2026, 3, 30, 5),
          platformSessionType: 'sleep',
          sourcePlatform: 'apple_healthkit',
        ),
      ],
      stageSegments: [
        SleepIngestionStageSegment(
          recordId: 'seg2',
          sessionRecordId: 's2',
          startAtUtc: DateTime.utc(2026, 3, 29, 23),
          endAtUtc: DateTime.utc(2026, 3, 30, 1),
          platformStage: 'core',
          sourcePlatform: 'apple_healthkit',
        ),
      ],
      heartRateSamples: [
        SleepIngestionHeartRateSample(
          recordId: 'hr2',
          sessionRecordId: 's2',
          sampledAtUtc: DateTime.utc(2026, 3, 30, 0),
          bpm: 60,
          sourcePlatform: 'apple_healthkit',
        ),
      ],
    );

    kitSource.batch = overlappingBatch;
    connectSource.batch = overlappingBatch;

    // Run sync again
    final result = await service.importRecent();
    expect(result.success, isTrue);

    // Verify s1 is completely deleted due to temporal overlap and replaced by s2
    final sessions = await db
        .customSelect('SELECT * FROM sleep_canonical_sessions')
        .get();
    expect(sessions.length, 1);
    expect(sessions.first.read<String>('id'), 's2');

    // Segments and HR should also be replaced
    final segments = await db
        .customSelect('SELECT * FROM sleep_canonical_stage_segments')
        .get();
    expect(segments.length, 1);
    expect(segments.first.read<String>('id'), 'seg2');

    await db.close();
  });
}

SleepRawIngestionBatch _updatedBatch() {
  final sessionStart = DateTime.utc(2026, 3, 29, 22);
  final sessionEnd = DateTime.utc(2026, 3, 30, 7); // Extended by 1 hour
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
        recordId: 'seg1_new',
        sessionRecordId: 's1',
        startAtUtc: sessionStart,
        endAtUtc: sessionStart.add(const Duration(hours: 3)),
        platformStage: 'core',
        sourcePlatform: 'apple_healthkit',
      ),
    ],
    heartRateSamples: [
      SleepIngestionHeartRateSample(
        recordId: 'hr1_new',
        sessionRecordId: 's1',
        sampledAtUtc: sessionStart.add(const Duration(hours: 2)),
        bpm: 58,
        sourcePlatform: 'apple_healthkit',
      ),
    ],
  );
}
