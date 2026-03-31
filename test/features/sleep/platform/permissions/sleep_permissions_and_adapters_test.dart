import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/platform/health_connect/health_connect_sleep_adapter.dart';
import 'package:hypertrack/features/sleep/platform/healthkit/healthkit_sleep_adapter.dart';
import 'package:hypertrack/features/sleep/platform/ingestion/sleep_ingestion_models.dart';
import 'package:hypertrack/features/sleep/platform/permissions/health_connect_sleep_permissions_service.dart';
import 'package:hypertrack/features/sleep/platform/permissions/healthkit_sleep_permissions_service.dart';
import 'package:hypertrack/features/sleep/platform/permissions/sleep_permission_controller.dart';
import 'package:hypertrack/features/sleep/platform/permissions/sleep_permission_models.dart';
import 'package:hypertrack/features/sleep/platform/permissions/sleep_permissions_service.dart';

class _FakeHealthKitPermissionBridge implements HealthKitPermissionBridge {
  _FakeHealthKitPermissionBridge({
    required this.available,
    required this.check,
    required this.request,
  });

  final bool available;
  final HealthKitAuthorizationSnapshot check;
  final HealthKitAuthorizationSnapshot request;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<HealthKitAuthorizationSnapshot> checkAuthorization() async => check;

  @override
  Future<HealthKitAuthorizationSnapshot> requestAuthorization() async =>
      request;
}

class _FakeHealthConnectPermissionBridge
    implements HealthConnectPermissionBridge {
  _FakeHealthConnectPermissionBridge({
    required this.availability,
    required this.check,
    required this.request,
  });

  final HealthConnectAvailability availability;
  final HealthConnectPermissionSnapshot check;
  final HealthConnectPermissionSnapshot request;

  @override
  Future<HealthConnectAvailability> getAvailability() async => availability;

  @override
  Future<HealthConnectPermissionSnapshot> checkPermissions() async => check;

  @override
  Future<HealthConnectPermissionSnapshot> requestPermissions() async => request;
}

class _FakeHealthKitDataSource implements HealthKitDataSource {
  _FakeHealthKitDataSource(this.batch);
  final SleepRawIngestionBatch batch;

  @override
  Future<SleepRawIngestionBatch> readSleepAndHeartRate({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async =>
      batch;
}

class _ThrowingHealthKitDataSource implements HealthKitDataSource {
  @override
  Future<SleepRawIngestionBatch> readSleepAndHeartRate({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    throw StateError('query failed');
  }
}

class _FakeHealthConnectDataSource implements HealthConnectDataSource {
  _FakeHealthConnectDataSource(this.batch);
  final SleepRawIngestionBatch batch;

  @override
  Future<SleepRawIngestionBatch> readSleepAndHeartRate({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async =>
      batch;
}

class _StaticPermissionService implements SleepPermissionsService {
  const _StaticPermissionService(this.outcome);

  final SleepPermissionOutcome outcome;

  @override
  Future<SleepPermissionOutcome> checkStatus() async => outcome;

  @override
  Future<SleepPermissionOutcome> requestAccess() async => outcome;
}

SleepRawIngestionBatch _sampleBatch() => SleepRawIngestionBatch(
      sessions: [
        SleepIngestionSession(
          recordId: 's',
          startAtUtc: DateTime.utc(2026, 1, 1, 22),
          endAtUtc: DateTime.utc(2026, 1, 2, 6),
          platformSessionType: 'sleep',
          sourcePlatform: 'test',
        ),
      ],
      stageSegments: const [],
      heartRateSamples: const [],
    );

void main() {
  group('HealthKitSleepPermissionsService', () {
    test('maps full grant to ready', () async {
      final service = HealthKitSleepPermissionsService(
        _FakeHealthKitPermissionBridge(
          available: true,
          check: const HealthKitAuthorizationSnapshot(
            sleepGranted: true,
            heartRateGranted: true,
          ),
          request: const HealthKitAuthorizationSnapshot(
            sleepGranted: true,
            heartRateGranted: true,
          ),
        ),
      );

      final result = await service.checkStatus();
      expect(result.state, SleepPermissionState.ready);
    });

    test('maps partial grant to partial', () async {
      final service = HealthKitSleepPermissionsService(
        _FakeHealthKitPermissionBridge(
          available: true,
          check: const HealthKitAuthorizationSnapshot(
            sleepGranted: true,
            heartRateGranted: false,
          ),
          request: const HealthKitAuthorizationSnapshot(
            sleepGranted: true,
            heartRateGranted: false,
          ),
        ),
      );

      final result = await service.checkStatus();
      expect(result.state, SleepPermissionState.partial);
    });

    test('maps unavailable to unavailable', () async {
      final service = HealthKitSleepPermissionsService(
        _FakeHealthKitPermissionBridge(
          available: false,
          check: const HealthKitAuthorizationSnapshot(
            sleepGranted: false,
            heartRateGranted: false,
          ),
          request: const HealthKitAuthorizationSnapshot(
            sleepGranted: false,
            heartRateGranted: false,
          ),
        ),
      );

      final result = await service.checkStatus();
      expect(result.state, SleepPermissionState.unavailable);
    });
  });

  group('HealthConnectSleepPermissionsService', () {
    test('maps not installed and unavailable states distinctly', () async {
      final notInstalled = HealthConnectSleepPermissionsService(
        _FakeHealthConnectPermissionBridge(
          availability: HealthConnectAvailability.notInstalled,
          check: const HealthConnectPermissionSnapshot(
            sleepGranted: false,
            heartRateGranted: false,
          ),
          request: const HealthConnectPermissionSnapshot(
            sleepGranted: false,
            heartRateGranted: false,
          ),
        ),
      );
      final unavailable = HealthConnectSleepPermissionsService(
        _FakeHealthConnectPermissionBridge(
          availability: HealthConnectAvailability.unavailable,
          check: const HealthConnectPermissionSnapshot(
            sleepGranted: false,
            heartRateGranted: false,
          ),
          request: const HealthConnectPermissionSnapshot(
            sleepGranted: false,
            heartRateGranted: false,
          ),
        ),
      );

      expect(
        (await notInstalled.checkStatus()).state,
        SleepPermissionState.notInstalled,
      );
      expect(
        (await unavailable.checkStatus()).state,
        SleepPermissionState.unavailable,
      );
    });
  });

  group('Sleep adapters', () {
    test('HealthKit adapter returns denied/partial/query failure', () async {
      final deniedAdapter = HealthKitSleepAdapter(
        permissionsService: const _StaticPermissionService(
          SleepPermissionOutcome.state(SleepPermissionState.denied),
        ),
        dataSource: _FakeHealthKitDataSource(_sampleBatch()),
      );

      final denied = await deniedAdapter.importRange(
        fromUtc: DateTime.utc(2026, 1, 1),
        toUtc: DateTime.utc(2026, 1, 2),
      );
      expect(denied.failure?.error, SleepPlatformServiceError.permissionDenied);

      final partialAdapter = HealthKitSleepAdapter(
        permissionsService: const _StaticPermissionService(
          SleepPermissionOutcome.state(SleepPermissionState.partial),
        ),
        dataSource: _FakeHealthKitDataSource(_sampleBatch()),
      );
      final partial = await partialAdapter.importRange(
        fromUtc: DateTime.utc(2026, 1, 1),
        toUtc: DateTime.utc(2026, 1, 2),
      );
      expect(
        partial.failure?.error,
        SleepPlatformServiceError.permissionPartial,
      );

      final failingAdapter = HealthKitSleepAdapter(
        permissionsService: const _StaticPermissionService(
          SleepPermissionOutcome.ready(),
        ),
        dataSource: _ThrowingHealthKitDataSource(),
      );
      final failed = await failingAdapter.importRange(
        fromUtc: DateTime.utc(2026, 1, 1),
        toUtc: DateTime.utc(2026, 1, 2),
      );
      expect(failed.failure?.error, SleepPlatformServiceError.queryFailed);
    });

    test('Health Connect adapter maps not-installed and success', () async {
      final notInstalledAdapter = HealthConnectSleepAdapter(
        permissionsService: const _StaticPermissionService(
          SleepPermissionOutcome.state(SleepPermissionState.notInstalled),
        ),
        dataSource: _FakeHealthConnectDataSource(_sampleBatch()),
      );
      final unavailable = await notInstalledAdapter.importRange(
        fromUtc: DateTime.utc(2026, 1, 1),
        toUtc: DateTime.utc(2026, 1, 2),
      );
      expect(
        unavailable.failure?.error,
        SleepPlatformServiceError.notInstalled,
      );

      final successAdapter = HealthConnectSleepAdapter(
        permissionsService: const _StaticPermissionService(
          SleepPermissionOutcome.ready(),
        ),
        dataSource: _FakeHealthConnectDataSource(_sampleBatch()),
      );
      final success = await successAdapter.importRange(
        fromUtc: DateTime.utc(2026, 1, 1),
        toUtc: DateTime.utc(2026, 1, 2),
      );
      expect(success.isSuccess, isTrue);
      expect(success.batch?.sessions.length, 1);
    });

    test('HealthKit adapter keeps not-installed distinct', () async {
      final adapter = HealthKitSleepAdapter(
        permissionsService: const _StaticPermissionService(
          SleepPermissionOutcome.state(SleepPermissionState.notInstalled),
        ),
        dataSource: _FakeHealthKitDataSource(_sampleBatch()),
      );
      final result = await adapter.importRange(
        fromUtc: DateTime.utc(2026, 1, 1),
        toUtc: DateTime.utc(2026, 1, 2),
      );
      expect(result.failure?.error, SleepPlatformServiceError.notInstalled);
    });
  });

  group('SleepPermissionController', () {
    test('preserves technical error details in status', () async {
      final controller = SleepPermissionController(
        const _StaticPermissionService(
          SleepPermissionOutcome.error(
            SleepPlatformServiceError.queryFailed,
            message: 'bridge timeout',
          ),
        ),
      );

      await controller.refresh();

      expect(controller.state.value.state, SleepPermissionState.technicalError);
      expect(
        controller.state.value.error,
        SleepPlatformServiceError.queryFailed,
      );
      expect(controller.state.value.message, 'bridge timeout');
    });
  });
}
