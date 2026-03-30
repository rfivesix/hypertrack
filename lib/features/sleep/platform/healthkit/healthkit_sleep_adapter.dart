import '../ingestion/sleep_ingestion_models.dart';
import '../permissions/sleep_permission_models.dart';
import '../permissions/sleep_permissions_service.dart';

class SleepIngestionFailure {
  const SleepIngestionFailure(this.error, {this.message});

  final SleepPlatformServiceError error;
  final String? message;
}

class SleepIngestionResult {
  const SleepIngestionResult.success(this.batch) : failure = null;

  const SleepIngestionResult.failure(this.failure) : batch = null;

  final SleepRawIngestionBatch? batch;
  final SleepIngestionFailure? failure;

  bool get isSuccess => batch != null;
}

abstract class HealthKitDataSource {
  Future<SleepRawIngestionBatch> readSleepAndHeartRate({
    required DateTime fromUtc,
    required DateTime toUtc,
  });
}

class HealthKitSleepAdapter {
  const HealthKitSleepAdapter({
    required SleepPermissionsService permissionsService,
    required HealthKitDataSource dataSource,
  })  : _permissionsService = permissionsService,
        _dataSource = dataSource;

  final SleepPermissionsService _permissionsService;
  final HealthKitDataSource _dataSource;

  Future<SleepIngestionResult> importRange({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final permission = await _permissionsService.checkStatus();
    if (permission.state == SleepPermissionState.denied) {
      return const SleepIngestionResult.failure(
        SleepIngestionFailure(SleepPlatformServiceError.permissionDenied),
      );
    }
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
    if (permission.state == SleepPermissionState.partial) {
      return const SleepIngestionResult.failure(
        SleepIngestionFailure(SleepPlatformServiceError.permissionPartial),
      );
    }
    if (permission.state == SleepPermissionState.technicalError) {
      return SleepIngestionResult.failure(
        SleepIngestionFailure(
          permission.error ?? SleepPlatformServiceError.unknown,
          message: permission.message,
        ),
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
