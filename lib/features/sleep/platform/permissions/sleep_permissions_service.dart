import 'sleep_permission_models.dart';

abstract class SleepPermissionsService {
  Future<SleepPermissionOutcome> checkStatus();
  Future<SleepPermissionOutcome> requestAccess();
}
