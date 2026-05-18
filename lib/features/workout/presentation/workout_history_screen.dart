// lib/screens/workout_history_screen.dart (final, de-materialized with AppBar)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/unit_service.dart';
import '../../../data/workout_database_helper.dart';
import '../../../generated/app_localizations.dart';
import '../../../models/workout_log.dart';
import 'workout_log_detail_screen.dart';
import '../../../util/design_constants.dart';
import '../../../util/time_util.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/swipe_action_background.dart';

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
    // FIX: Use getFullWorkoutLogs() to load sets directly.
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
              // FIX: Improved empty state.
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
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
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

                    // New: calculate volume and sets for this log.
                    final totalSets = log.sets.length;
                    final totalVolume = log.sets.fold<double>(
                      0,
                      (sum, set) => sum + (set.weightKg ?? 0) * (set.reps ?? 0),
                    );

                    return Dismissible(
                      key: Key('log_${log.id}'),
                      direction: DismissDirection.endToStart,

                      // FIXED: Only `secondaryBackground` is needed here.
                      background: const SwipeActionBackground(
                        color: Colors.redAccent,
                        icon: Icons.delete,
                        alignment: Alignment.centerRight,
                      ),
                      confirmDismiss: (direction) async {
                        // New: helper (specific text needed here)
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // FIX: Subtitle is now a Column with more information.
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
                                  Flexible(
                                    child: Text(
                                      '${context.read<UnitService>().convertDisplayValue(totalVolume, UnitDimension.weight).toStringAsFixed(0)} ${context.read<UnitService>().suffixFor(UnitDimension.weight)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: DesignConstants.spacingM),
                                  Icon(
                                    Icons.replay_circle_filled_outlined,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      l10n.setCount(
                                        totalSets,
                                      ), // Uses the plural function
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
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
