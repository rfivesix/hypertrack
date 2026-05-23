// lib/screens/workout_log_detail_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../domain/repositories/workout_repository.dart';
import '../data/sources/workout_local_data_source.dart';
import '../../sharing/share_service.dart';
import '../../../generated/app_localizations.dart';
import '../../exercise_catalog/domain/models/exercise.dart';
import '../domain/models/set_log.dart';
import '../domain/models/workout_log.dart';
import '../../../services/health/workout_heart_rate_models.dart';
import '../../../services/health/workout_heart_rate_service.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../pulse/application/pulse_tracking_service.dart';
import '../../../services/unit_service.dart';
import '../../exercise_catalog/presentation/exercise_catalog_screen.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/summary_card.dart';
import '../../exercise_catalog/presentation/widgets/wger_attribution_widget.dart';
import 'widgets/workout_summary_bar.dart';
import 'widgets/workout_heart_rate_section.dart';
import 'widgets/workout_exercise_log_card.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';

/// A detailed view for a single completed [WorkoutLog].
///
/// Displays the full set log for each exercise performed during the session.
/// Supports an edit mode to adjust notes, start times, and set-level data.
class WorkoutLogDetailScreen extends StatefulWidget {
  /// The unique identifier of the workout log to display.
  final int logId;
  const WorkoutLogDetailScreen({super.key, required this.logId});

  @override
  State<WorkoutLogDetailScreen> createState() => _WorkoutLogDetailScreenState();
}

class _WorkoutLogDetailScreenState extends State<WorkoutLogDetailScreen> {
  bool _isLoading = true;
  WorkoutLog? _log;
  final WorkoutHeartRateService _heartRateService =
      const WorkoutHeartRateService();
  WorkoutHeartRateSummary? _heartRateSummary;
  Map<String, List<SetLog>> _groupedSets = {};
  Map<String, Exercise> _exerciseDetails = {};
  Map<String, String> _exerciseNotes = {};
  bool _isEditMode = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;

  // Use weightController for KG or DISTANCE
  final Map<int, TextEditingController> _weightControllers = {};
  // Use repsController for REPS or TIME (min)
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _rirControllers = {};

  bool _pulseTrackingEnabled = false;
  DateTime? _editedStartTime;
  Map<String, double> _categoryVolume = {};
  static const ShareService _shareService = ShareService();

  StreamSubscription<List<SetLog>>? _setLogsSubscription;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadDetails();
    _setLogsSubscription = context
        .read<IWorkoutRepository>()
        .watchSetLogsForWorkout(widget.logId)
        .listen(_onSetLogsUpdated);
  }

  @override
  void dispose() {
    _setLogsSubscription?.cancel();
    _notesController.dispose();
    _clearControllers();
    super.dispose();
  }

  void _onSetLogsUpdated(List<SetLog> updatedSets) async {
    if (!mounted || _isEditMode || _log == null) return;

    final repo = context.read<IWorkoutRepository>();
    final mutableSets = List<SetLog>.from(updatedSets);
    await _calculateHistoricalPRs(mutableSets, beforeTimestamp: _log!.startTime);

    final updatedGroups = <String, List<SetLog>>{};
    for (var set in mutableSets) {
      updatedGroups.putIfAbsent(set.exerciseName, () => []).add(set);
    }

    // Resolve any newly added exercises not in _exerciseDetails
    for (final set in mutableSets) {
      if (!_exerciseDetails.containsKey(set.exerciseName)) {
        final ex = await repo.resolveExerciseForSetLog(set);
        if (ex != null) {
          _exerciseDetails[set.exerciseName] = ex;
        }
      }
    }

    // Recalculate volume based on the resolved map
    final catVol = <String, double>{};
    for (var set in mutableSets) {
      final v = (set.weightKg ?? 0) * (set.reps ?? 0);
      if (v > 0) {
        final cat = _exerciseDetails[set.exerciseName]?.categoryName ?? 'Other';
        catVol.update(cat, (val) => val + v, ifAbsent: () => v);
      }
    }

    if (!mounted || _isEditMode) return;

    setState(() {
      _log = WorkoutLog(
        id: _log!.id,
        routineName: _log!.routineName,
        startTime: _log!.startTime,
        endTime: _log!.endTime,
        notes: _log!.notes,
        startZoneOffsetMinutes: _log!.startZoneOffsetMinutes,
        endZoneOffsetMinutes: _log!.endZoneOffsetMinutes,
        sets: mutableSets,
      );
      _groupedSets = updatedGroups;
      _categoryVolume = catVol;
    });
  }

  void _clearControllers() {
    for (var c in _weightControllers.values) {
      c.dispose();
    }
    for (var c in _repsControllers.values) {
      c.dispose();
    }
    for (var c in _rirControllers.values) {
      c.dispose();
    }
    _weightControllers.clear();
    _repsControllers.clear();
    _rirControllers.clear();
  }

  bool _isCardio(String exerciseName) {
    final ex = _exerciseDetails[exerciseName];
    return ex?.categoryName.toLowerCase() == 'cardio';
  }

  Future<void> _loadDetails({bool preserveEditState = false}) async {
    if (!preserveEditState) {
      setState(() => _isLoading = true);
    }

    final data = await WorkoutLocalDataSource.instance.getWorkoutLogById(
      widget.logId,
    );
    if (data == null) {
      if (mounted) {
        setState(() {
          _heartRateSummary = null;
          _isLoading = false;
        });
      }
      return;
    }

    final savedExerciseNotes = await WorkoutLocalDataSource.instance
        .getWorkoutExerciseNotes(widget.logId);

    final heartRateFuture = _heartRateService.loadForWorkoutWindow(
      startTime: data.startTime,
      endTime: data.endTime,
    );

    final pulseTrackingFuture = PulseTrackingService().isTrackingEnabled();
    // ignore: use_build_context_synchronously
    final unitService = context.read<UnitService>();

    final groups = <String, List<SetLog>>{};
    for (var set in data.sets) {
      groups.putIfAbsent(set.exerciseName, () => []).add(set);
    }

    // Resolve exercise metadata via stored exercise_id when available.
    final Map<String, Exercise> details = {};
    for (final set in data.sets) {
      if (details.containsKey(set.exerciseName)) continue;
      final ex = await WorkoutLocalDataSource.instance.resolveExerciseForSetLog(
        set,
      );
      if (ex != null) {
        details[set.exerciseName] = ex;
      }
    }

    // Volume for the header (strength only)
    final catVol = <String, double>{};
    for (var set in data.sets) {
      // Count toward volume only when not cardio?
      // Simplified: count anything that has weight * reps.
      // Cardio has weight=0/null in the log because it is stored in distanceKm, so it is automatically 0.
      final v = (set.weightKg ?? 0) * (set.reps ?? 0);
      if (v > 0) {
        final cat = details[set.exerciseName]?.categoryName ?? 'Other';
        catVol.update(cat, (val) => val + v, ifAbsent: () => v);
      }
    }

    _notesController.text = data.notes ?? '';
    _editedStartTime = data.startTime;

    // Populate controllers
    _clearControllers();
    for (final setLog in data.sets) {
      // Distinguish cardio vs strength for initial values
      final isCardio =
          details[setLog.exerciseName]?.categoryName.toLowerCase() == 'cardio';

      String val1, val2;

      if (isCardio) {
        // Cardio: Val1 = Distance, Val2 = Duration(min)
        val1 = setLog.distanceKm?.toStringAsFixed(1).replaceAll('.0', '') ?? '';
        final sec = setLog.durationSeconds ?? 0;
        val2 = sec > 0 ? (sec / 60).toStringAsFixed(0) : '';
      } else {
        // Strength: Val1 = weight, Val2 = reps
        val1 = setLog.weightKg == null
            ? ''
            : unitService
                .convertDisplayValue(setLog.weightKg!, UnitDimension.weight)
                .toStringAsFixed(1)
                .replaceAll('.0', '');
        val2 = setLog.reps?.toString() ?? '';
      }

      _weightControllers[setLog.id!] = TextEditingController(text: val1);
      _repsControllers[setLog.id!] = TextEditingController(text: val2);
      _rirControllers[setLog.id!] = TextEditingController(
        text: setLog.rir?.toString() ?? '',
      );
    }

    if (!mounted) return;
    final heartRateSummary = await heartRateFuture;
    final pulseTrackingEnabled = await pulseTrackingFuture;
    if (!mounted) return;

    // Recalculate PRs for historical view
    await _calculateHistoricalPRs(data.sets, beforeTimestamp: data.startTime);

    // Re-group because copies were made
    final updatedGroups = <String, List<SetLog>>{};
    for (var set in data.sets) {
      updatedGroups.putIfAbsent(set.exerciseName, () => []).add(set);
    }

    setState(() {
      _log = data;
      _groupedSets = updatedGroups;
      _exerciseDetails = details;
      _exerciseNotes = savedExerciseNotes;
      _categoryVolume = catVol;
      _heartRateSummary = heartRateSummary;
      _pulseTrackingEnabled = pulseTrackingEnabled;
      if (!preserveEditState) {
        _isLoading = false;
      }
    });
  }

  Future<void> _calculateHistoricalPRs(
    List<SetLog> sets, {
    DateTime? beforeTimestamp,
  }) async {
    final db = WorkoutLocalDataSource.instance;
    final Map<String, Map<String, double>> historicalBests = {};

    for (var i = 0; i < sets.length; i++) {
      final setLog = sets[i];
      final exName = setLog.exerciseName;

      if (!historicalBests.containsKey(exName)) {
        historicalBests[exName] = await db.getExerciseBests(
          exName,
          excludeWorkoutLogId: widget.logId,
          beforeTimestamp: beforeTimestamp,
        );
      }

      final bests = historicalBests[exName]!;
      final currentWeight = setLog.weightKg ?? 0.0;
      final currentReps = setLog.reps ?? 0;
      final currentVolume = currentWeight * currentReps;
      double currentEst1rm = 0.0;
      if (currentReps > 0 && currentReps <= 10) {
        currentEst1rm = currentWeight * (36 / (37 - currentReps));
      }

      bool isMaxWeightPR = false;
      bool isMaxVolumePR = false;
      bool isMaxEst1RMPR = false;
      double? weightDiff;
      double? volumeDiff;
      double? est1rmDiff;

      if (currentWeight > 0 &&
          setLog.isCompleted == true &&
          setLog.setType != 'warmup') {
        final oldMaxWeight = bests['maxWeight'] ?? 0.0;
        if (currentWeight > oldMaxWeight) {
          isMaxWeightPR = true;
          weightDiff = oldMaxWeight > 0 ? currentWeight - oldMaxWeight : null;
          bests['maxWeight'] = currentWeight;
        }

        final oldMaxVolume = bests['maxVolume'] ?? 0.0;
        if (currentVolume > oldMaxVolume) {
          isMaxVolumePR = true;
          volumeDiff = oldMaxVolume > 0 ? currentVolume - oldMaxVolume : null;
          bests['maxVolume'] = currentVolume;
        }

        final oldMaxEst1rm = bests['maxEst1rm'] ?? 0.0;
        if (currentEst1rm > oldMaxEst1rm) {
          isMaxEst1RMPR = true;
          est1rmDiff = oldMaxEst1rm > 0 ? currentEst1rm - oldMaxEst1rm : null;
          bests['maxEst1rm'] = currentEst1rm;
        }
      }

      sets[i] = setLog.copyWith(
        isMaxWeightPR: isMaxWeightPR,
        isMaxVolumePR: isMaxVolumePR,
        isMaxEst1RMPR: isMaxEst1RMPR,
        weightPRDiff: weightDiff,
        volumePRDiff: volumeDiff,
        est1rmPRDiff: est1rmDiff,
      );
    }
  }

  // Formatting now uses UnitService so this helper is no longer needed.

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (_isEditMode) {
        _loadDetails(preserveEditState: true);
      } else {
        _loadDetails();
      }
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _editedStartTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_editedStartTime ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _editedStartTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context)!;
    final dbHelper = WorkoutLocalDataSource.instance;
    final unitService = context.read<UnitService>();

    final initialSetIds = _log!.sets.map((s) => s.id!).toSet();
    final currentSets = _groupedSets.values.expand((sets) => sets).toList();

    final idsToDelete = initialSetIds
        .difference(currentSets.map((s) => s.id!).toSet())
        .toList();

    final List<SetLog> setsToUpdate = [];
    final List<SetLog> setsToInsert = [];

    for (final setLog in currentSets) {
      // Distinguish again what the controller values mean.
      final isCardio = _isCardio(setLog.exerciseName);

      final val1Input = double.tryParse(
            _weightControllers[setLog.id!]?.text.replaceAll(',', '.') ?? '0',
          ) ??
          0.0;
      final val1 = isCardio
          ? val1Input
          : unitService.convertToMetric(val1Input, UnitDimension.weight);
      final val2 = double.tryParse(
            _repsControllers[setLog.id!]?.text.replaceAll(',', '.') ?? '0',
          ) ??
          0.0;
      final rir = int.tryParse(_rirControllers[setLog.id!]?.text ?? '');

      SetLog updatedSet;

      if (isCardio) {
        // Val1 = Distance, Val2 = Minutes (-> Seconds)
        updatedSet = setLog.copyWith(
          distanceKm: val1,
          durationSeconds: (val2 * 60).round(),
          rir: rir,
          clearRir: rir == null,
          // Set weight/reps to 0/null for cardio to avoid bad data?
          weightKg: 0,
          reps: 0,
        );
      } else {
        // Val1 = Weight, Val2 = Reps (int)
        updatedSet = setLog.copyWith(
          weightKg: val1,
          reps: val2.toInt(),
          rir: rir,
          clearRir: rir == null,
          // Cardio Felder nullen
          distanceKm: null,
          durationSeconds: null,
        );
      }

      if (initialSetIds.contains(setLog.id)) {
        setsToUpdate.add(updatedSet);
      } else {
        setsToInsert.add(updatedSet);
      }
    }

    await dbHelper.updateWorkoutLogDetails(
      widget.logId,
      _editedStartTime!,
      _notesController.text,
    );
    if (idsToDelete.isNotEmpty) await dbHelper.deleteSetLogs(idsToDelete);
    if (setsToUpdate.isNotEmpty) await dbHelper.updateSetLogs(setsToUpdate);
    for (final set in setsToInsert) {
      await dbHelper.insertSetLog(
        set.copyWith(id: null, workoutLogId: widget.logId),
      );
    }
    for (final exerciseName in _exerciseNotes.keys) {
      final note = _exerciseNotes[exerciseName];
      await dbHelper.saveWorkoutExerciseNote(
        workoutLogId: widget.logId,
        exerciseName: exerciseName,
        notes: note != null && note.isNotEmpty ? note : null,
      );
    }

    if (mounted) {
      HapticFeedbackService.instance.confirmationFeedback();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.snackbarRoutineSaved)));
    }

    setState(() => _isEditMode = false);
    _loadDetails();
  }

  void _editExerciseNotes(BuildContext context, String exerciseName) async {
    final l10n = AppLocalizations.of(context)!;
    final controller =
        TextEditingController(text: _exerciseNotes[exerciseName] ?? '');

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
                if (_exerciseNotes[exerciseName] != null &&
                    _exerciseNotes[exerciseName]!.isNotEmpty) ...[
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
      setState(() {
        _exerciseNotes[exerciseName] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.watch<UnitService>();
    final locale = Localizations.localeOf(context).toString();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    double totalVolume = 0.0;
    if (_log != null) {
      for (final set in _log!.sets) {
        totalVolume += (set.weightKg ?? 0) * (set.reps ?? 0);
      }
    }
    final Duration duration =
        _log?.endTime?.difference(_log!.startTime) ?? Duration.zero;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBar(
        title: l10n.workoutDetailsTitle,
        actions: [
          if (!_isLoading && _log != null)
            _isEditMode
                ? TextButton(
                    onPressed: _saveChanges,
                    child: Text(
                      l10n.save,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _toggleEditMode,
                  ),
          if (!_isLoading && _log != null && !_isEditMode)
            IconButton(
              tooltip: l10n.share,
              icon: const Icon(Icons.ios_share),
              onPressed: () => _shareService.showWorkoutShareSheet(
                context: context,
                workout: _log!,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _log == null
              ? Center(child: Text(l10n.workoutNotFound))
              : Column(
                  children: [
                    WorkoutSummaryBar(
                      duration: duration,
                      volume: totalVolume,
                      sets: _log!.sets.length,
                      progress: null,
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          // Header Info
                          Padding(
                            padding: DesignConstants.cardPadding,
                            child: SummaryCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _log!.routineName ??
                                            l10n.freeWorkoutTitle,
                                        style: textTheme.headlineMedium,
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            DateFormat.yMMMMd(
                                              locale,
                                            ).add_Hm().format(
                                                  _editedStartTime ??
                                                      _log!.startTime,
                                                ),
                                          ),
                                          if (_isEditMode)
                                            IconButton(
                                              icon: Icon(
                                                Icons.calendar_today,
                                                size: 18,
                                                color: colorScheme.primary,
                                              ),
                                              onPressed: _pickDateTime,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: DesignConstants.spacingM,
                                      ),
                                      _isEditMode
                                          ? TextFormField(
                                              controller: _notesController,
                                              decoration: InputDecoration(
                                                labelText: l10n.notesLabel,
                                              ),
                                              maxLines: 3,
                                            )
                                          : (_log!.notes != null &&
                                                  _log!.notes!.isNotEmpty
                                              ? Text(
                                                  '${l10n.notesLabel}: ${_log!.notes!}',
                                                  style: const TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                )
                                              : const SizedBox.shrink()),
                                      if (_categoryVolume.isNotEmpty) ...[
                                        const Divider(height: 24),
                                        Text(
                                          l10n.muscleSplitLabel,
                                          style: textTheme.titleMedium,
                                        ),
                                        const SizedBox(
                                          height: DesignConstants.spacingS,
                                        ),
                                        ..._buildCategoryBars(context),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_heartRateSummary != null &&
                              (_pulseTrackingEnabled ||
                                  _heartRateSummary!.hasData))
                            Padding(
                              padding: DesignConstants.cardPadding.copyWith(
                                top: 0,
                              ),
                              child: WorkoutHeartRateSection(
                                summary: _heartRateSummary!,
                                pulseTrackingEnabled: _pulseTrackingEnabled,
                              ),
                            ),

                          // Sets
                          if (!_isEditMode)
                            ..._groupedSets.entries.map((entry) {
                              final String exerciseName = entry.key;
                              final Exercise? exercise = _exerciseDetails[exerciseName];
                              final List<SetLog> sets = entry.value;
                              final isCardio = _isCardio(exerciseName);

                              return WorkoutExerciseLogCard(
                                exerciseName: exerciseName,
                                exercise: exercise,
                                sets: sets,
                                isEditMode: false,
                                isCardio: isCardio,
                                weightControllers: _weightControllers,
                                repsControllers: _repsControllers,
                                rirControllers: _rirControllers,
                                exerciseNote: _exerciseNotes[exerciseName],
                                onEditNotes: (exName) => _editExerciseNotes(context, exName),
                                onDeleteExercise: (exName) {
                                  setState(() {
                                    for (var set in sets) {
                                      _weightControllers.remove(set.id!)?.dispose();
                                      _repsControllers.remove(set.id!)?.dispose();
                                      _rirControllers.remove(set.id!)?.dispose();
                                    }
                                    _groupedSets.remove(exName);
                                    _exerciseNotes.remove(exName);
                                  });
                                },
                                onAddSet: () {},
                                onDeleteSet: (setId) {},
                                onSetTypeTap: (setId) {},
                                index: -1,
                              );
                            })
                          else ...[
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              onReorder: (int oldIndex, int newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) {
                                    newIndex -= 1;
                                  }
                                  final entries = _groupedSets.entries.toList();
                                  final item = entries.removeAt(oldIndex);
                                  entries.insert(newIndex, item);
                                  _groupedSets.clear();
                                  for (var entry in entries) {
                                    _groupedSets[entry.key] = entry.value;
                                  }
                                });
                              },
                              itemCount: _groupedSets.length,
                              itemBuilder: (context, index) {
                                final entry = _groupedSets.entries.elementAt(index);
                                final String exerciseName = entry.key;
                                final Exercise? exercise = _exerciseDetails[exerciseName];
                                final List<SetLog> sets = entry.value;
                                final isCardio = _isCardio(exerciseName);

                                return WorkoutExerciseLogCard(
                                  key: ValueKey(exerciseName),
                                  exerciseName: exerciseName,
                                  exercise: exercise,
                                  sets: sets,
                                  isEditMode: true,
                                  isCardio: isCardio,
                                  weightControllers: _weightControllers,
                                  repsControllers: _repsControllers,
                                  rirControllers: _rirControllers,
                                  exerciseNote: _exerciseNotes[exerciseName],
                                  onEditNotes: (exName) => _editExerciseNotes(context, exName),
                                  onDeleteExercise: (exName) {
                                    setState(() {
                                      for (var set in sets) {
                                        _weightControllers.remove(set.id!)?.dispose();
                                        _repsControllers.remove(set.id!)?.dispose();
                                        _rirControllers.remove(set.id!)?.dispose();
                                      }
                                      _groupedSets.remove(exName);
                                      _exerciseNotes.remove(exName);
                                    });
                                  },
                                  onAddSet: () {
                                    final newSet = SetLog(
                                      id: DateTime.now().millisecondsSinceEpoch,
                                      workoutLogId: _log!.id!,
                                      exerciseName: exerciseName,
                                      setType: 'normal',
                                      isCompleted: true,
                                    );
                                    setState(() {
                                      sets.add(newSet);
                                      _weightControllers[newSet.id!] = TextEditingController();
                                      _repsControllers[newSet.id!] = TextEditingController();
                                      _rirControllers[newSet.id!] = TextEditingController();
                                    });
                                  },
                                  onDeleteSet: (setId) {
                                    setState(() {
                                      sets.removeWhere((s) => s.id == setId);
                                      _weightControllers.remove(setId)?.dispose();
                                      _repsControllers.remove(setId)?.dispose();
                                      _rirControllers.remove(setId)?.dispose();
                                    });
                                  },
                                  onSetTypeTap: (setId) => _showSetTypePicker(setId),
                                  index: index,
                                );
                              },
                            ),
                          ],

                          // Add Exercise (Edit Mode)
                          if (_isEditMode)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TextButton.icon(
                                onPressed: () async {
                                  final selectedExercise =
                                      await Navigator.of(context)
                                          .push<Exercise>(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ExerciseCatalogScreen(
                                              isSelectionMode: true),
                                    ),
                                  );
                                  if (selectedExercise != null) {
                                    setState(() {
                                      // Store exercise details locally so _isCardio and name work.
                                      _exerciseDetails[selectedExercise
                                              .getLocalizedName(context)] =
                                          selectedExercise;

                                      final newSet = SetLog(
                                        id: DateTime.now()
                                            .millisecondsSinceEpoch,
                                        workoutLogId: _log!.id!,
                                        exerciseName: selectedExercise
                                            .getLocalizedName(context),
                                        setType: 'normal',
                                        isCompleted: true,
                                        // Set default values
                                        weightKg: 0,
                                        reps: 0,
                                        distanceKm: 0,
                                        durationSeconds: 0,
                                      );
                                      _groupedSets[selectedExercise
                                          .getLocalizedName(context)] = [
                                        newSet,
                                      ];

                                      _weightControllers[newSet.id!] =
                                          TextEditingController();
                                      _repsControllers[newSet.id!] =
                                          TextEditingController();
                                      _rirControllers[newSet.id!] =
                                          TextEditingController();
                                    });
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: Text(l10n.addExerciseToWorkoutButton),
                              ),
                            ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                            child: WgerAttributionWidget(
                              textStyle: textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  List<Widget> _buildCategoryBars(BuildContext context) {
    final total = _categoryVolume.values.fold<double>(0, (a, b) => a + b);
    return _categoryVolume.entries.map((entry) {
      final fraction = total > 0 ? entry.value / total : 0.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(entry.key, style: const TextStyle(fontSize: 12)),
            ),
            Expanded(
              flex: 5,
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.grey.shade300,
                color: Theme.of(context).colorScheme.primary,
                minHeight: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text("${(fraction * 100).toStringAsFixed(0)}%"),
          ],
        ),
      );
    }).toList();
  }


  void _changeSetType(int setLogId, String newType) {
    setState(() {
      for (var entry in _groupedSets.entries) {
        for (var setLog in entry.value) {
          if (setLog.id == setLogId) {
            final index = entry.value.indexOf(setLog);
            entry.value[index] = setLog.copyWith(setType: newType);
            break;
          }
        }
      }
    });
  }

  void _showSetTypePicker(int setLogId) {
    final l10n = AppLocalizations.of(context)!;

    Widget buildSymbol(String char, Color color) {
      return Text(
        char,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final options = [
      {
        'type': 'normal',
        'label': l10n.set_type_normal,
        'symbol': buildSymbol('N', Colors.grey),
      },
      {
        'type': 'warmup',
        'label': l10n.set_type_warmup,
        'symbol': buildSymbol('W', Colors.orange),
      },
      {
        'type': 'failure',
        'label': l10n.set_type_failure,
        'symbol': buildSymbol('F', Colors.red),
      },
      {
        'type': 'dropset',
        'label': l10n.set_type_dropset,
        'symbol': buildSymbol('D', Colors.blue),
      },
    ];

    showGlassBottomMenu(
      context: context,
      title: l10n.changeSetTypTitle,
      actions: options.map((opt) {
        return GlassMenuAction(
          customIcon: opt['symbol'] as Widget,
          label: opt['label'] as String,
          onTap: () => _changeSetType(setLogId, opt['type'] as String),
        );
      }).toList(),
    );
  }
}
