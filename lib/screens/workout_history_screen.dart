// lib/screens/workout_history_screen.dart (Final & De-Materialisiert mit AppBar)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/workout_log.dart';
import 'workout_log_detail_screen.dart';
import '../util/design_constants.dart';
import '../util/time_util.dart';
import '../widgets/glass_bottom_menu.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import '../widgets/swipe_action_background.dart';

/// A screen displaying a list of all previously completed workout sessions.
///
/// Allows users to view high-level summaries of past workouts, delete entries,
/// and navigate to detailed logs via [WorkoutLogDetailScreen].
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});
  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  bool _isLoading = true;
  List<WorkoutLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    // KORREKTUR: Wir verwenden getFullWorkoutLogs(), um die Sätze direkt mitzuladen.
    final data = await WorkoutDatabaseHelper.instance.getFullWorkoutLogs();
    if (mounted) {
      setState(() {
        _logs = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLog(int logId) async {
    await WorkoutDatabaseHelper.instance.deleteWorkoutLog(logId);
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final colorScheme = Theme.of(context).colorScheme;

    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.workoutHistoryTitle),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          // KORREKTUR: Aufgewerteter "Empty State"
          ? Center(
              child: Padding(
                padding: DesignConstants.cardPadding.copyWith(
                  top: DesignConstants.cardPadding.top + topPadding,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_toggle_off_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: DesignConstants.spacingL),
                    Text(
                      l10n.workoutHistoryEmptyTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                    Text(
                      l10n.emptyHistory,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: DesignConstants.cardPadding.copyWith(
                top: DesignConstants.cardPadding.top + topPadding,
              ),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final duration = log.endTime?.difference(log.startTime);

                // NEU: Berechne Volumen und Sätze für diesen Log
                final totalSets = log.sets.length;
                final totalVolume = log.sets.fold<double>(
                  0,
                  (sum, set) => sum + (set.weightKg ?? 0) * (set.reps ?? 0),
                );

                return Dismissible(
                  key: Key('log_${log.id}'),
                  direction: DismissDirection.endToStart,

                  // KORRIGIERT: Nur `secondaryBackground` wird hier benötigt
                  background: const SwipeActionBackground(
                    color: Colors.redAccent,
                    icon: Icons.delete,
                    alignment: Alignment.centerRight,
                  ),
                  confirmDismiss: (direction) async {
                    // NEU: Helper (Textspezifizierung hier nötig)
                    return await showDeleteConfirmation(
                      context,
                      content: l10n.deleteWorkoutConfirmContent,
                    );
                  },
                  onDismissed: (direction) {
                    _deleteLog(log.id!);
                  },
                  child: SummaryCard(
                    child: ListTile(
                      leading: const Icon(Icons.event_note, size: 40),
                      title: Text(
                        log.routineName ?? l10n.freeWorkoutTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // KORREKTUR: Das Subtitle wird jetzt ein Column mit mehr Infos
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.yMMMMd(
                              locale,
                            ).add_Hm().format(log.startTime),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.monitor_weight_outlined,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${totalVolume.toStringAsFixed(0)} kg',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.replay_circle_filled_outlined,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.setCount(
                                  totalSets,
                                ), // Nutzt die Plural-Funktion
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: duration != null
                          ? Text(
                              formatDuration(duration),
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : null,
                      onTap: () => Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  WorkoutLogDetailScreen(logId: log.id!),
                            ),
                          )
                          .then((_) => _loadHistory()),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
