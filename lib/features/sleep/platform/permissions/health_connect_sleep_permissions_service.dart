import 'sleep_permission_models.dart';
import 'sleep_permissions_service.dart';

abstract class HealthConnectPermissionBridge {
  Future<HealthConnectAvailability> getAvailability();
  Future<HealthConnectPermissionSnapshot> checkPermissions();
  Future<HealthConnectPermissionSnapshot> requestPermissions();
}

enum HealthConnectAvailability { available, unavailable, notInstalled }

class HealthConnectPermissionSnapshot {
  const HealthConnectPermissionSnapshot({
    required this.sleepGranted,
    required this.heartRateGranted,
  });

  final bool sleepGranted;
  final bool heartRateGranted;
}

class HealthConnectSleepPermissionsService implements SleepPermissionsService {
  const HealthConnectSleepPermissionsService(this._bridge);

  final HealthConnectPermissionBridge _bridge;

  @override
  Future<SleepPermissionOutcome> checkStatus() async {
    try {
      final availability = await _bridge.getAvailability();
      final mappedAvailability = _mapAvailability(availability);
      if (mappedAvailability != null) return mappedAvailability;
      final permissions = await _bridge.checkPermissions();
      return _mapPermissions(permissions);
    } catch (error) {
      return SleepPermissionOutcome.error(
        SleepPlatformServiceError.unknown,
        message: error.toString(),
      );
    }
  }

  @override
  Future<SleepPermissionOutcome> requestAccess() async {
    try {
      final availability = await _bridge.getAvailability();
      final mappedAvailability = _mapAvailability(availability);
      if (mappedAvailability != null) return mappedAvailability;
      final permissions = await _bridge.requestPermissions();
      return _mapPermissions(permissions);
    } catch (error) {
      return SleepPermissionOutcome.error(
        SleepPlatformServiceError.unknown,
        message: error.toString(),
      );
    }
  }

  SleepPermissionOutcome? _mapAvailability(HealthConnectAvailability state) {
    switch (state) {
      case HealthConnectAvailability.available:
        return null;
      case HealthConnectAvailability.unavailable:
        return const SleepPermissionOutcome.state(
          SleepPermissionState.unavailable,
        );
      case HealthConnectAvailability.notInstalled:
        return const SleepPermissionOutcome.state(
          SleepPermissionState.notInstalled,
        );
    }
  }

  SleepPermissionOutcome _mapPermissions(
    HealthConnectPermissionSnapshot snapshot,
  ) {
    if (snapshot.sleepGranted && snapshot.heartRateGranted) {
      return const SleepPermissionOutcome.ready();
    }
    if (snapshot.sleepGranted || snapshot.heartRateGranted) {
      return const SleepPermissionOutcome.state(SleepPermissionState.partial);
    }
    return const SleepPermissionOutcome.state(SleepPermissionState.denied);
  }
}
