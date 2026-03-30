enum SleepPermissionState {
  loading,
  ready,
  denied,
  partial,
  unavailable,
  notInstalled,
  technicalError,
}

class SleepPermissionStatus {
  const SleepPermissionStatus({
    required this.state,
    this.error,
    this.message,
  });

  final SleepPermissionState state;
  final SleepPlatformServiceError? error;
  final String? message;
}

enum SleepPlatformServiceError {
  unavailable,
  notInstalled,
  permissionDenied,
  permissionPartial,
  queryFailed,
  unknown,
}

class SleepPermissionOutcome {
  const SleepPermissionOutcome.ready()
      : state = SleepPermissionState.ready,
        error = null,
        message = null;

  const SleepPermissionOutcome.state(this.state, {this.message}) : error = null;

  const SleepPermissionOutcome.error(this.error, {this.message})
      : state = SleepPermissionState.technicalError;

  final SleepPermissionState state;
  final SleepPlatformServiceError? error;
  final String? message;
}
