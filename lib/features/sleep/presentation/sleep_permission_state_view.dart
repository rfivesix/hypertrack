import 'package:flutter/material.dart';

import '../platform/permissions/sleep_permission_models.dart';

class SleepPermissionStateView extends StatelessWidget {
  const SleepPermissionStateView({
    super.key,
    required this.status,
    this.onConnect,
  });

  final SleepPermissionStatus status;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) {
    final title = _title(status.state);
    final body = _body(status.state);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            if (onConnect != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onConnect,
                child: const Text('Connect health data'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _title(SleepPermissionState state) {
    switch (state) {
      case SleepPermissionState.loading:
        return 'Checking health connection';
      case SleepPermissionState.ready:
        return 'Health data connected';
      case SleepPermissionState.denied:
        return 'Permission denied';
      case SleepPermissionState.partial:
        return 'Partial permissions';
      case SleepPermissionState.unavailable:
        return 'Health source unavailable';
      case SleepPermissionState.notInstalled:
        return 'Health Connect not installed';
    }
  }

  String _body(SleepPermissionState state) {
    switch (state) {
      case SleepPermissionState.loading:
        return 'Please wait while availability and permissions are checked.';
      case SleepPermissionState.ready:
        return 'Sleep and heart-rate access is available.';
      case SleepPermissionState.denied:
        return 'Enable permissions to import sleep data.';
      case SleepPermissionState.partial:
        return 'Some sleep permissions are missing. Grant all for best results.';
      case SleepPermissionState.unavailable:
        return 'This device cannot provide the required health source.';
      case SleepPermissionState.notInstalled:
        return 'Install Health Connect to continue on Android.';
    }
  }
}
