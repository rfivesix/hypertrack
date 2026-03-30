import 'sleep_permission_models.dart';
import 'sleep_permissions_service.dart';

abstract class HealthKitPermissionBridge {
  Future<bool> isAvailable();
  Future<HealthKitAuthorizationSnapshot> checkAuthorization();
  Future<HealthKitAuthorizationSnapshot> requestAuthorization();
}

class HealthKitAuthorizationSnapshot {
  const HealthKitAuthorizationSnapshot({
    required this.sleepGranted,
    required this.heartRateGranted,
  });

  final bool sleepGranted;
  final bool heartRateGranted;
}

class HealthKitSleepPermissionsService implements SleepPermissionsService {
  const HealthKitSleepPermissionsService(this._bridge);

  final HealthKitPermissionBridge _bridge;

  @override
  Future<SleepPermissionOutcome> checkStatus() async {
    try {
      final available = await _bridge.isAvailable();
      if (!available) {
        return const SleepPermissionOutcome.state(
          SleepPermissionState.unavailable,
        );
      }
      final snapshot = await _bridge.checkAuthorization();
      return _mapSnapshot(snapshot);
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
      final available = await _bridge.isAvailable();
      if (!available) {
        return const SleepPermissionOutcome.state(
          SleepPermissionState.unavailable,
        );
      }
      final snapshot = await _bridge.requestAuthorization();
      return _mapSnapshot(snapshot);
    } catch (error) {
      return SleepPermissionOutcome.error(
        SleepPlatformServiceError.unknown,
        message: error.toString(),
      );
    }
  }

  SleepPermissionOutcome _mapSnapshot(HealthKitAuthorizationSnapshot snapshot) {
    if (snapshot.sleepGranted && snapshot.heartRateGranted) {
      return const SleepPermissionOutcome.ready();
    }
    if (snapshot.sleepGranted || snapshot.heartRateGranted) {
      return const SleepPermissionOutcome.state(SleepPermissionState.partial);
    }
    return const SleepPermissionOutcome.state(SleepPermissionState.denied);
  }
}
