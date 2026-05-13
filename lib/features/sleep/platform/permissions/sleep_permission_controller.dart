import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/glass_bottom_menu.dart';
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
      error: outcome.error,
      message: outcome.message,
    );
  }

  Future<void> requestAccess(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showGlassBottomMenu<bool>(
      context: context,
      title: l10n.sleepRequestAccessTitle,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                l10n.sleepRequestAccessSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(false);
                    },
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(true);
                    },
                    child: Text(l10n.onboardingNext),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final outcome = await _service.requestAccess();
    state.value = SleepPermissionStatus(
      state: outcome.state,
      error: outcome.error,
      message: outcome.message,
    );
  }
}
