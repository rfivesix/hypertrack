// lib/widgets/todays_workout_summary_card.dart

import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import '../util/time_util.dart';
import 'summary_card.dart';

/// A summary card specifically for displaying today's workout activity.
///
/// Shows total [duration], [volume], [sets], and the number of performed workouts.
class TodaysWorkoutSummaryCard extends StatelessWidget {
  /// Combined duration of all workouts today.
  final Duration duration;

  /// Total weight lifted across all workouts today.
  final double volume;

  /// Total number of sets completed.
  final int sets;

  /// Total number of workout sessions logged today.
  final int workoutCount;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  const TodaysWorkoutSummaryCard({
    super.key,
    required this.duration,
    required this.volume,
    required this.sets,
    required this.workoutCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Erstellt den Subtitle-Text mit allen Statistiken
    final subtitleText =
        '${formatDuration(duration)}  •  ${volume.toStringAsFixed(0)} kg  •  ${l10n.setCount(sets)}';

    return SummaryCard(
      // Padding wird von der ListTile übernommen
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 16.0,
        ),
        leading: Icon(
          Icons.fitness_center,
          color: theme.colorScheme.primary,
          size: 32,
        ),
        title: Text(
          workoutCount > 1
              ? l10n.workoutsLabel // "Workouts"
              : l10n.workout, // "Workout"
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitleText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
