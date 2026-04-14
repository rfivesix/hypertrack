// lib/widgets/workout_summary_bar.dart

import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import '../util/time_util.dart'; // Wir erstellen diese Hilfsdatei gleich

/// A horizontal bar displaying key workout metrics.
///
/// Shows [duration], total [volume], and total [sets]. Can optionally
/// display a [progress] bar.
class WorkoutSummaryBar extends StatelessWidget {
  const WorkoutSummaryBar({
    super.key,
    this.duration,
    required this.volume,
    required this.sets,
    this.progress, // NULL => Spacer-Modus
  });

  /// The elapsed or total time.
  final Duration? duration;

  /// Total weight lifted.
  final double volume;

  /// Total number of sets.
  final int sets;

  /// Optional progress value (0..1) for the progress bar.
  final double? progress; // 0..1 oder null

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header ohne grauen Kasten
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                context: context,
                label: l10n.durationLabel,
                value: formatDuration(duration ?? Duration.zero),
                highlight: true,
              ),
              _buildStatColumn(
                context: context,
                label: l10n.volumeLabel,
                value: "${volume.toStringAsFixed(0)} kg",
              ),
              _buildStatColumn(
                context: context,
                label: l10n.setsLabel,
                value: sets.toString(),
              ),
            ],
          ),
        ),

        // Progress / Spacer: volle Breite, kein Padding
        SizedBox(
          width: double.infinity,
          child: _WorkoutProgressBar(value: progress),
        ),
      ],
    );
  }

  /// Ein kleines Helfer-Widget für eine einzelne Statistik-Spalte.
  Widget _buildStatColumn({
    required BuildContext context,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
      color: highlight
          ? theme.colorScheme.primary
          : theme.textTheme.titleMedium?.color,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.grey[600],
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _WorkoutProgressBar extends StatelessWidget {
  const _WorkoutProgressBar({required this.value});
  final double? value; // null => Spacer

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Colors.white.withValues(alpha: 0.10); // dezentes Grau
    final fg = cs.primary;

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LayoutBuilder(
        builder: (context, c) {
          final v = (value ?? 0).clamp(0.0, 1.0);
          final w = c.maxWidth * v;
          return Stack(
            children: [
              Container(height: 6, color: bg),
              if (value != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: w,
                  height: 6,
                  color: fg,
                ),
            ],
          );
        },
      ),
    );

    // kein Außenabstand → wirklich von ganz links bis ganz rechts
    return bar;
  }
}
