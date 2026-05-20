import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/sources/workout_local_data_source.dart';
import '../../sharing/share_service.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/routine.dart';
import '../domain/repositories/workout_repository.dart';
import '../../../services/haptic_feedback_service.dart';
import 'edit_routine_screen.dart';
import 'live_workout_screen.dart';
import '../../../util/design_constants.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/swipe_action_background.dart';

/// A screen that displays a list of all saved [Routine] templates.
///
/// Users can start a workout from a routine, duplicate existing ones,
/// or navigate to [EditRoutineScreen] to create or edit routines.
class RoutinesScreen extends StatefulWidget {
  /// Optional ID to automatically open the editor for a specific routine.
  final int? initialRoutineId;
  const RoutinesScreen({super.key, this.initialRoutineId});
  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  static const ShareService _shareService = ShareService();
  late final Stream<List<Routine>> _routinesStream;
  bool _initialRoutineOpened = false;

  @override
  void initState() {
    super.initState();
    _routinesStream = Provider.of<IWorkoutRepository>(context, listen: false)
        .watchAllRoutines();
  }

  void _startWorkout(Routine routine) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    final fullRoutine = await WorkoutLocalDataSource.instance.getRoutineById(
      routine.id!,
    );
    final newWorkoutLog = await WorkoutLocalDataSource.instance.startWorkout(
      routineName: routine.name,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    if (fullRoutine != null) {
      HapticFeedbackService.instance.confirmationFeedback();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LiveWorkoutScreen(
            routine: fullRoutine,
            workoutLog: newWorkoutLog,
          ),
        ),
      );
    }
  }

  void _startEmptyWorkout() async {
    final l10n = AppLocalizations.of(context)!;
    final newWorkoutLog = await WorkoutLocalDataSource.instance.startWorkout(
      routineName: l10n.freeWorkoutTitle,
    );
    if (!mounted) return;
    HapticFeedbackService.instance.confirmationFeedback();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LiveWorkoutScreen(workoutLog: newWorkoutLog),
      ),
    );
  }

  void _createNewRoutine() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const EditRoutineScreen()),
    );
  }

  // New methods for the menu
  void _duplicateRoutine(int routineId) async {
    await WorkoutLocalDataSource.instance.duplicateRoutine(routineId);
    HapticFeedbackService.instance.confirmationFeedback();
  }

  Future<void> _shareRoutine(Routine routine) async {
    final fullRoutine =
        await WorkoutLocalDataSource.instance.getRoutineById(routine.id!);
    if (!mounted || fullRoutine == null) return;
    await _shareService.showRoutineShareSheet(
      context: context,
      routine: fullRoutine,
    );
  }

  // 1. The menu method
  void _deleteRoutine(BuildContext context, Routine routine) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDeleteConfirmation(
      context,
      content: l10n.deleteRoutineConfirmContent(routine.name),
    );

    if (confirmed) {
      await WorkoutLocalDataSource.instance.deleteRoutine(routine.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme; // Defined here

    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBar(title: l10n.workoutRoutinesTitle),
      body: StreamBuilder<List<Routine>>(
        stream: _routinesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final routines = snapshot.data ?? [];

          // If an initialRoutineId was passed, navigate there directly on first load.
          if (widget.initialRoutineId != null &&
              !_initialRoutineOpened &&
              routines.isNotEmpty) {
            _initialRoutineOpened = true;
            try {
              final routineToEdit = routines.firstWhere(
                (r) => r.id == widget.initialRoutineId,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        EditRoutineScreen(routine: routineToEdit),
                  ),
                );
              });
            } catch (_) {}
          }

          if (routines.isEmpty) {
            return _buildEmptyState(context, l10n, textTheme);
          }

          return ListView.builder(
            padding: DesignConstants.cardPadding.copyWith(
              top: DesignConstants.cardPadding.top + topPadding,
            ),
            itemCount: routines.length + 1, // instead of +2
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildStartEmptyWorkoutCard(context, l10n);
              }
              final routine = routines[index - 1];
              return Dismissible(
                key: Key('routine_${routine.id}'),
                direction: DismissDirection.endToStart,

                // Same backgrounds as in Nutrition Screen
                background: const SwipeActionBackground(
                  color: Colors.redAccent,
                  icon: Icons.delete,
                  alignment: Alignment.centerRight,
                ),

                confirmDismiss: (direction) async {
                  return await showDeleteConfirmation(context);
                },

                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    _deleteRoutine(context, routine); // actually delete
                  }
                },

                child: SummaryCard(
                  child: ListTile(
                    leading: ElevatedButton(
                      onPressed: () => _startWorkout(routine),
                      child: Text(l10n.startButton),
                    ),
                    title: Text(
                      routine.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(l10n.editRoutineSubtitle),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: textTheme.bodyMedium?.color,
                      ),
                      onSelected: (value) {
                        if (value == 'duplicate') {
                          _duplicateRoutine(routine.id!);
                        } else if (value == 'share') {
                          _shareRoutine(routine);
                        } else if (value == 'delete') {
                          _deleteRoutine(context, routine);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'duplicate',
                          child: Text(l10n.duplicate),
                        ),
                        PopupMenuItem<String>(
                          value: 'share',
                          child: Text(l10n.share),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              EditRoutineScreen(routine: routine),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: GlassFab(
        label: l10n.addRoutineButton,
        onPressed: _createNewRoutine,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // FIX 5: _buildStartEmptyWorkoutCard as SummaryCard button
  Widget _buildStartEmptyWorkoutCard(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return SummaryCard(
      child: ListTile(
        leading: const Icon(Icons.play_circle_fill),
        title: Text(
          l10n.startEmptyWorkoutButton,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: _startEmptyWorkout,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        ),
      ),
    );
  }

  // In RoutinesScreen: _buildEmptyState ersetzen/erweitern

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    TextTheme textTheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Text(
              l10n.emptyRoutinesTitle,
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.emptyRoutinesSubtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: DesignConstants.spacingXL),

            // Existing button: create routine
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: _createNewRoutine,
              icon: const Icon(Icons.add),
              label: Text(
                l10n.createFirstRoutineButton,
                style: textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),

            const SizedBox(height: DesignConstants.spacingM),

            // New: start free workout (visible in empty state too)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: _startEmptyWorkout,
              icon: const Icon(Icons.play_circle_fill),
              label: Text(l10n.startEmptyWorkoutButton),
            ),
          ],
        ),
      ),
    );
  }
}
