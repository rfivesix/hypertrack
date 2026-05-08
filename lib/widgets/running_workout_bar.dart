// lib/widgets/running_workout_bar.dart

import 'package:flutter/material.dart';
import 'package:train_libre/generated/app_localizations.dart';

/// A compact status bar displayed during an active workout session.
///
/// Shows the current [timeText] and provides actions to [onResume] or [onDiscard].
class RunningWorkoutBar extends StatelessWidget {
  /// The formatted duration of the current workout (e.g., "12:34").
  final String timeText; // z.B. "13:12"
  /// Callback to resume/open the full workout screen.
  final VoidCallback onResume;

  /// Callback to discard the active workout session.
  final VoidCallback onDiscard;

  const RunningWorkoutBar({
    super.key,
    required this.timeText,
    required this.onResume,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        // Time (left)
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20),
              const SizedBox(width: 6),
              Text(
                timeText,
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        // Resume (accent)
        FilledButton(
          onPressed: onResume,
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            minimumSize: const Size(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(l10n.continue_workout_button),
        ),
        const SizedBox(width: 8),
        // Discard (red)
        FilledButton(
          onPressed: onDiscard,
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
            minimumSize: const Size(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(l10n.discard_button),
        ),
      ],
    );
  }
}
