// lib/util/permission_dialogs.dart

import 'package:flutter/material.dart';
import '../widgets/glass_bottom_menu.dart';

/// Shows a glass-styled explanation dialog before the system permission popup.
///
/// [title] and [body] provide context for why the permission is needed.
/// Returns true if the user clicks the continue button.
Future<bool> showPrePermissionDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String continueLabel,
  required String cancelLabel,
}) async {
  final result = await showGlassBottomMenu<bool>(
    context: context,
    title: title,
    contentBuilder: (ctx, close) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              body,
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
                  child: Text(cancelLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    close();
                    Navigator.of(ctx).pop(true);
                  },
                  child: Text(continueLabel),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  return result ?? false;
}
