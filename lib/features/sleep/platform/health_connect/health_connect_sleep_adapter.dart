import '../healthkit/healthkit_sleep_adapter.dart';
import '../ingestion/sleep_ingestion_models.dart';
import '../permissions/sleep_permission_models.dart';
import '../permissions/sleep_permissions_service.dart';

abstract class HealthConnectDataSource {
  Future<SleepRawIngestionBatch> readSleepAndHeartRate({
    required DateTime fromUtc,
    required DateTime toUtc,
  });
}

class HealthConnectSleepAdapter {
  const HealthConnectSleepAdapter({
    required SleepPermissionsService permissionsService,
    required HealthConnectDataSource dataSource,
  })  : _permissionsService = permissionsService,
        _dataSource = dataSource;

  final SleepPermissionsService _permissionsService;
  final HealthConnectDataSource _dataSource;

  Future<SleepIngestionResult> importRange({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final permission = await _permissionsService.checkStatus();
    if (permission.state == SleepPermissionState.notInstalled) {
      return const SleepIngestionResult.failure(
        SleepIngestionFailure(SleepPlatformServiceError.notInstalled),
      );
    }
    if (permission.state == SleepPermissionState.unavailable) {
      return const SleepIngestionResult.failure(
        SleepIngestionFailure(SleepPlatformServiceError.unavailable),
      );
    }
    if (permission.state == SleepPermissionState.denied) {
      return const SleepIngestionResult.failure(
        SleepIngestionFailure(SleepPlatformServiceError.permissionDenied),
      );
    }
    if (permission.state == SleepPermissionState.partial) {
      return const SleepIngestionResult.failure(
        SleepIngestionFailure(SleepPlatformServiceError.permissionPartial),
      );
    }

    try {
      final batch = await _dataSource.readSleepAndHeartRate(
        fromUtc: fromUtc,
        toUtc: toUtc,
      );
      return SleepIngestionResult.success(batch);
    } catch (error) {
      return SleepIngestionResult.failure(
        SleepIngestionFailure(
          SleepPlatformServiceError.queryFailed,
          message: error.toString(),
        ),
      );
    }
  }
}
