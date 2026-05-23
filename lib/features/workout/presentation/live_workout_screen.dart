// lib/screens/live_workout_screen.dart
// FINAL: Cardio fix + null safety + header logic

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../util/design_constants.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/glass_fab.dart';
import '../data/sources/workout_local_data_source.dart';
import '../../../generated/app_localizations.dart';
import '../../exercise_catalog/domain/models/exercise.dart';
import '../domain/models/routine.dart';
import '../domain/models/routine_exercise.dart';
import '../domain/models/workout_log.dart';
import '../../../services/haptic_feedback_service.dart';
import 'live_workout_view_model.dart';
import '../domain/detect_personal_record_use_case.dart';
import '../../../services/unit_service.dart';
import '../../exercise_catalog/presentation/widgets/wger_attribution_widget.dart';
import 'widgets/workout_summary_bar.dart';
import '../../exercise_catalog/presentation/exercise_catalog_screen.dart';
import '../../exercise_catalog/presentation/exercise_detail_screen.dart';
import 'package:provider/provider.dart';
import 'workout_summary_screen.dart';
import 'widgets/workout_card.dart';
import 'widgets/pr_celebration_banner.dart';
import 'widgets/exercise_e1rm_summary.dart';
import 'widgets/live_workout_set_row.dart';
// Used when vibration is enabled.

/// The active workout tracking screen, managing the real-time session state.
///
/// Handles input for sets, reps, weight, RPE/RIR, and cardio metrics. Coordinates
/// with [LiveWorkoutViewModel] to persist progress and provide rest timers.
class LiveWorkoutScreen extends StatefulWidget {
  /// Optional [Routine] used to initialize the workout exercises.
  final Routine? routine;

  /// The [WorkoutLog] representing the current active session.
  final WorkoutLog workoutLog;

  const LiveWorkoutScreen({super.key, this.routine, required this.workoutLog});

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen>
    with TickerProviderStateMixin {
  late final VoidCallback _onManagerUpdateCallback;
  LiveWorkoutViewModel? _manager;
  bool _canPop = false;

  void _handleBack() {
    setState(() {
      _canPop = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  // PR Celebration State
  StreamSubscription<PRAlert>? _prEventsSubscription;
  final List<PRAlert> _prQueue = [];
  bool _isShowingPR = false;
  PRAlert? _currentPR;
  late final AnimationController _prAnimationController;
  late final Animation<Offset> _prSlideAnimation;

  @override
  void initState() {
    super.initState();

    _prAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _prSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _prAnimationController,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    ));

    _onManagerUpdateCallback = () {
      if (mounted) {
        setState(() {});
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final manager = Provider.of<LiveWorkoutViewModel>(
        context,
        listen: false,
      );
      _manager = manager;
      manager.addListener(_onManagerUpdateCallback);
      manager.loadInitialData(widget.workoutLog, widget.routine?.exercises);

      _prEventsSubscription = manager.prEvents.listen((event) {
        _prQueue.add(event);
        _processPRQueue();
      });
    });
  }

  void _processPRQueue() async {
    if (_isShowingPR || _prQueue.isEmpty) return;

    _isShowingPR = true;
    _currentPR = _prQueue.removeAt(0);
    if (mounted) setState(() {});

    await _prAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) {
      await _prAnimationController.reverse();
      _isShowingPR = false;
      _currentPR = null;
      setState(() {});
      _processPRQueue();
    }
  }

  @override
  void dispose() {
    _manager?.removeListener(_onManagerUpdateCallback);
    _prEventsSubscription?.cancel();
    _prAnimationController.dispose();
    super.dispose();
  }

  // --- Cardio check helper ---
  bool _isCardio(RoutineExercise re) {
    return re.exercise.categoryName.toLowerCase() == 'cardio';
  }

  Future<void> _finishWorkout() async {
    final l10n = AppLocalizations.of(context)!;
    final manager = Provider.of<LiveWorkoutViewModel>(context, listen: false);

    // Pre-fill the title with the routine name or "Free Workout"
    final defaultTitle =
        manager.workoutLog?.routineName ?? l10n.freeWorkoutTitle;
    final titleController = TextEditingController(text: defaultTitle);
    final notesController = TextEditingController();

    final result = await showGlassBottomMenu<({String title, String notes})>(
      context: context,
      title: l10n.finishWorkoutButton,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                l10n.dialogFinishWorkoutBody,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: l10n.finishWorkoutTitleLabel,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: l10n.finishWorkoutNotesLabel,
                hintText: l10n.finishWorkoutNotesHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(null);
                    },
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop((
                        title: titleController.text.trim(),
                        notes: notesController.text.trim(),
                      ));
                    },
                    child: Text(l10n.finishWorkoutButton),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    titleController.dispose();
    notesController.dispose();

    if (result != null && mounted) {
      final logId = manager.workoutLog?.id;
      await manager.finishWorkout(
        title: result.title.isNotEmpty ? result.title : null,
        notes: result.notes.isNotEmpty ? result.notes : null,
      );
      if (mounted && logId != null) {
        HapticFeedbackService.instance.confirmationFeedback();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => WorkoutSummaryScreen(logId: logId),
          ),
        );
      }
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    Provider.of<LiveWorkoutViewModel>(
      context,
      listen: false,
    ).reorderExercise(oldIndex, newIndex);
  }

  void _removeExercise(RoutineExercise exerciseToRemove) {
    Provider.of<LiveWorkoutViewModel>(
      context,
      listen: false,
    ).removeExercise(exerciseToRemove.id!);
  }

  void _editExerciseNotes(BuildContext context, RoutineExercise re) async {
    final l10n = AppLocalizations.of(context)!;
    final manager = Provider.of<LiveWorkoutViewModel>(context, listen: false);
    final controller = TextEditingController(text: re.notes ?? '');

    final result = await showGlassBottomMenu<String?>(
      context: context,
      title: "Übungsnotiz",
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: "Notizen oder Hinweise eingeben...",
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (re.notes != null && re.notes!.isNotEmpty) ...[
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    tooltip: "Notiz löschen",
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop('');
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(null);
                    },
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(controller.text.trim());
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (result != null) {
      await manager.updateExerciseNotes(re.exercise.nameEn, result);
    }
  }

  void _addExercise() async {
    final manager = Provider.of<LiveWorkoutViewModel>(context, listen: false);
    final selectedExercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (context) =>
            const ExerciseCatalogScreen(isSelectionMode: true),
      ),
    );

    if (selectedExercise != null) {
      final lastSets = await WorkoutLocalDataSource.instance
          .getLastSetsForExercise(selectedExercise.nameEn);
      if (mounted) {
        setState(() {
          manager.lastPerformances[selectedExercise.nameEn] = lastSets;
        });
      }
      await manager.addExercise(selectedExercise);
    }
  }

  void _addSet(RoutineExercise re) {
    Provider.of<LiveWorkoutViewModel>(
      context,
      listen: false,
    ).addSetToExercise(re.id!);
  }

  // --- HEADER HELPER ---
  Widget _buildHeaderRow(RoutineExercise re, AppLocalizations l10n) {
    // Important: cardio check here.
    final bool isCardio = _isCardio(re);
    final unitService = context.read<UnitService>();

    if (isCardio) {
      return Row(
        children: [
          _buildHeader(l10n.setLabel, flex: 2), // Set Nr.
          _buildHeader(l10n.lastTimeLabel, flex: 3), // History/Last
          _buildHeader(l10n.cardioDistanceLabel, flex: 4), // More space
          const SizedBox(width: 8),
          _buildHeader(l10n.cardioTimeLabel, flex: 4), // More space
          const SizedBox(width: 8),
          _buildHeader(l10n.cardioIntensityLabel, flex: 2),
          const SizedBox(width: 48), // Space for checkbox
        ],
      );
    }
    // Standard Strength Header
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeader(l10n.setLabel, flex: 1),
        _buildHeader(l10n.lastTimeLabel, flex: 2),
        _buildHeader(unitService.suffixFor(UnitDimension.weight), flex: 2),
        _buildHeader(l10n.repsLabel, flex: 2),
        _buildHeader("RIR", flex: 1),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildHeader(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getLocalizedRecordType(String recordType) {
    final l10n = AppLocalizations.of(context)!;
    switch (recordType) {
      case "Best Max Weight":
        return l10n.prBannerBestMaxWeight;
      case "Best Volume Set":
        return l10n.prBannerBestVolumeSet;
      case "Best 1-Rep Max":
        return l10n.prBannerBest1RM;
      default:
        return recordType;
    }
  }

  Widget _buildPRCelebrationBanner() {
    final pr = _currentPR;
    if (pr == null) return const SizedBox.shrink();

    final localizedRecordType = _getLocalizedRecordType(pr.recordType);
    final unitService = context.read<UnitService>();
    final String achievementText = _formatDisplayWeightText(
      pr.achievementValue,
      unitService,
    );
    final String diffText = pr.diff != null
        ? " (+${_formatDisplayWeightValue(pr.diff!, unitService)} ${unitService.suffixFor(UnitDimension.weight)})"
        : "";

    return PrCelebrationBanner(
      slideAnimation: _prSlideAnimation,
      exerciseName: pr.exerciseName,
      localizedRecordType: localizedRecordType,
      achievementText: achievementText,
      diffText: diffText,
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Text(
              l10n.emptyStateAddFirstExercise,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              "Füge eine Übung hinzu, um mit dem Protokollieren zu beginnen.",
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            ElevatedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: Text(l10n.fabAddExercise),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.watch<UnitService>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final manager = Provider.of<LiveWorkoutViewModel>(context);

    // If the workout was just finished, the manager state is cleared.
    // We return a blank scaffold to avoid any errors during the Navigator transition.
    if (!manager.isActive && !manager.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    }

    // Edit rest helper
    void editPauseTime(RoutineExercise routineExercise) async {
      final currentPause = manager.pauseTimes[routineExercise.id!];
      final controller = TextEditingController(
        text: currentPause?.toString() ?? '',
      );

      final result = await showGlassBottomMenu<int?>(
        context: context,
        title: l10n.editPauseTimeTitle,
        contentBuilder: (ctx, close) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.pauseInSeconds,
                  hintText: "z.B. 90",
                  suffixText: "s",
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        close();
                        Navigator.of(ctx).pop(null);
                      },
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final val = int.tryParse(controller.text);
                        close();
                        Navigator.of(ctx).pop(val);
                      },
                      child: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );

      if (result != null) {
        manager.updatePauseTime(routineExercise.id!, result);
      }
    }

    final mgr = manager;
    final int planned = mgr.setLogs.length;
    final int completed =
        mgr.setLogs.values.where((s) => s.isCompleted == true).length;
    final double progress = planned == 0 ? 0.0 : completed / planned;

    if (!manager.isLoading) {
      manager.syncControllers();
    }

    return PopScope(
        canPop: _canPop,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          // The system back swipe won't pop the route automatically because canPop is false.
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading:
                false, // We will provide our own back button
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleBack,
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: colorScheme.onSurface,
            scrolledUnderElevation: 0,
            centerTitle: false,
            title: Text(
              manager.workoutLog?.routineName ?? l10n.freeWorkoutTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            actions: [
              TextButton(
                onPressed: _finishWorkout,
                child: Text(
                  l10n.finishWorkoutButton,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: manager.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    Column(
                      children: [
                        WorkoutSummaryBar(
                          duration: mgr.elapsedDuration,
                          volume: mgr.totalVolume,
                          sets: planned,
                          progress: progress,
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                        ),
                        Expanded(
                          child: manager.exercises.isEmpty
                              ? _buildEmptyState(l10n)
                              : ReorderableListView.builder(
                                  padding: const EdgeInsets.only(
                                    bottom: DesignConstants.bottomContentSpacer,
                                  ),
                                  onReorder: _onReorder,
                                  itemCount: manager.exercises.length,
                                  itemBuilder: (context, index) {
                                    final routineExercise =
                                        manager.exercises[index];
                                    final showE1rmSummary =
                                        !_isCardio(routineExercise);
                                    return WorkoutCard(
                                      key: ValueKey(routineExercise.id),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                              vertical: 8.0,
                                            ),
                                            leading:
                                                ReorderableDragStartListener(
                                              index: index,
                                              child:
                                                  const Icon(Icons.drag_handle),
                                            ),
                                            title: InkWell(
                                              onTap: () =>
                                                  Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ExerciseDetailScreen(
                                                    exercise: routineExercise
                                                        .exercise,
                                                  ),
                                                ),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 4.0,
                                                ),
                                                child: Text(
                                                  routineExercise.exercise
                                                      .getLocalizedName(
                                                          context),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: textTheme.titleLarge
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (manager.pauseTimes[
                                                            routineExercise
                                                                .id!] !=
                                                        null &&
                                                    manager.pauseTimes[
                                                            routineExercise
                                                                .id!]! >
                                                        0)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      right: 4.0,
                                                    ),
                                                    child: Text(
                                                      "${manager.pauseTimes[routineExercise.id!]}s",
                                                      style: textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                        color:
                                                            colorScheme.primary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                  ),
                                                  tooltip: "Notizen bearbeiten",
                                                  onPressed: () =>
                                                      _editExerciseNotes(
                                                          context,
                                                          routineExercise),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.timer_outlined,
                                                  ),
                                                  tooltip: l10n.editPauseTime,
                                                  onPressed: () =>
                                                      editPauseTime(
                                                    routineExercise,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.redAccent,
                                                  ),
                                                  tooltip: l10n.removeExercise,
                                                  onPressed: () =>
                                                      _removeExercise(
                                                    routineExercise,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (routineExercise.notes != null &&
                                              routineExercise.notes!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 16.0,
                                                right: 16.0,
                                                bottom: 12.0,
                                              ),
                                              child: InkWell(
                                                onTap: () => _editExerciseNotes(
                                                    context, routineExercise),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme
                                                        .surfaceContainerHighest
                                                        .withValues(alpha: 0.5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                      color: colorScheme
                                                          .onSurfaceVariant
                                                          .withValues(
                                                              alpha: 0.1),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .description_outlined,
                                                        size: 16,
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          routineExercise
                                                              .notes!,
                                                          style: textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (showE1rmSummary)
                                            ExerciseE1rmSummary(
                                              routineExercise: routineExercise,
                                              manager: manager,
                                            ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 0.0,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // FIX: Insert header row dynamically.
                                                _buildHeaderRow(
                                                  routineExercise,
                                                  l10n,
                                                ),

                                                // Set Rows
                                                ...routineExercise.setTemplates
                                                    .asMap()
                                                    .entries
                                                    .map((setEntry) {
                                                  final templateId =
                                                      setEntry.value.id!;
                                                  final template = setEntry
                                                      .value; // <--- Template
                                                  final setLog = manager
                                                      .setLogs[templateId];

                                                  if (setLog == null) {
                                                    return const SizedBox
                                                        .shrink();
                                                  }
                                                  int workingSetIndex = 0;
                                                  for (int i = 0;
                                                      i <= setEntry.key;
                                                      i++) {
                                                    final currentTemplateId =
                                                        routineExercise
                                                            .setTemplates[i]
                                                            .id!;
                                                    if (manager
                                                            .setLogs[
                                                                currentTemplateId]
                                                            ?.setType !=
                                                        'warmup') {
                                                      workingSetIndex++;
                                                    }
                                                  }

                                                  return LiveWorkoutSetRow(
                                                    setIndex: workingSetIndex,
                                                    rowIndex: setEntry.key,
                                                    templateId: templateId,
                                                    setLog: setLog,
                                                    lastPerfSets: manager.lastPerformances[
                                                            routineExercise
                                                                .exercise
                                                                .nameEn] ??
                                                        [],
                                                    template: template,
                                                    manager: manager,
                                                    isCardio: _isCardio(routineExercise),
                                                  );
                                                }),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 16.0,
                                                  ),
                                                  child: TextButton.icon(
                                                    onPressed: () => _addSet(
                                                        routineExercise),
                                                    icon: const Icon(Icons.add),
                                                    label:
                                                        Text(l10n.addSetButton),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),

                    // --- Top Celebration Banner ---
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildPRCelebrationBanner(),
                    ),
                  ],
                ),
          floatingActionButton: GlassFab(
            label: l10n.fabAddExercise,
            onPressed: _addExercise,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedBuilder(
                animation: manager,
                builder: (context, _) {
                  final bar = _buildRestBottomBar(l10n, colorScheme, manager);
                  return bar ?? const SizedBox.shrink();
                },
              ),
              if (manager.remainingRestSeconds <= 0 && !manager.showRestDone)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: WgerAttributionWidget(
                    textStyle: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ));
  }

  Widget? _buildRestBottomBar(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    LiveWorkoutViewModel manager,
  ) {
    final isRunning = manager.remainingRestSeconds > 0;
    final isDoneBanner = !isRunning && manager.showRestDone;
    if (!isRunning && !isDoneBanner) return null;
    final theme = Theme.of(context);
    if (isRunning) {
      return BottomAppBar(
        color: colorScheme.surface,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${l10n.restTimerLabel}: ${manager.remainingRestSeconds}s",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  manager.cancelRest();
                },
                child: Text(l10n.skipButton),
              ),
            ],
          ),
        ),
      );
    }
    return BottomAppBar(
      color: Colors.green.shade600,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Pause vorbei!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                manager.cancelRest();
              },
              child: Text(
                l10n.snackbar_button_ok,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDisplayWeightText(
    String metricText,
    UnitService unitService, {
    int fractionDigits = 1,
  }) {
    final value = _extractNumericValue(metricText);
    if (value == null) return metricText;
    return '${_formatDisplayWeightValue(value, unitService, fractionDigits: fractionDigits)} ${unitService.suffixFor(UnitDimension.weight)}';
  }

  String _formatDisplayWeightValue(
    double metricValue,
    UnitService unitService, {
    int fractionDigits = 1,
  }) {
    return unitService
        .convertDisplayValue(metricValue, UnitDimension.weight)
        .toStringAsFixed(fractionDigits)
        .replaceAll('.0', '');
  }

  double? _extractNumericValue(String text) {
    final match = RegExp(r'[-+]?\d+(?:[.,]\d+)?').firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(0)!.replaceAll(',', '.'));
  }
}
