import 'package:flutter/foundation.dart';

import 'sleep_permission_models.dart';
import 'sleep_permissions_service.dart';

class SleepPermissionController {
  SleepPermissionController(this._service)
      : state = ValueNotifier<SleepPermissionStatus>(
          const SleepPermissionStatus(state: SleepPermissionState.loading),
        );

  final SleepPermissionsService _service;
  final ValueNotifier<SleepPermissionStatus> state;

  Future<void> refresh() async {
    final outcome = await _service.checkStatus();
    state.value = SleepPermissionStatus(
      state: outcome.state,
      message: outcome.message,
    );
  }

  Future<void> requestAccess() async {
    final outcome = await _service.requestAccess();
    state.value = SleepPermissionStatus(
      state: outcome.state,
      message: outcome.message,
    );
  }
}
