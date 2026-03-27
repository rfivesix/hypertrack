// lib/screens/workout_log_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/exercise.dart';
import '../models/set_log.dart';
import '../models/workout_log.dart';
import 'general_exercise_selection_screen.dart';
import 'exercise_detail_screen.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import '../widgets/wger_attribution_widget.dart';
import '../widgets/workout_summary_bar.dart';
import '../widgets/workout_card.dart';

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
  Map<String, List<SetLog>> _groupedSets = {};
  Map<String, Exercise> _exerciseDetails = {};
  bool _isEditMode = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;

  // Wir nutzen weightController für KG oder DISTANCE
  final Map<int, TextEditingController> _weightControllers = {};
  // Wir nutzen repsController für REPS oder TIME(min)
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _rirControllers = {};

  DateTime? _editedStartTime;
  Map<String, double> _categoryVolume = {};

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadDetails();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _clearControllers();
    super.dispose();
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

  String _getSetDisplayText(String setType, int setIndex) {
    switch (setType) {
      case 'warmup':
        return 'W';
      case 'failure':
        return 'F';
      case 'dropset':
        return 'D';
      default:
        return '$setIndex';
    }
  }

  bool _isCardio(String exerciseName) {
    final ex = _exerciseDetails[exerciseName];
    return ex?.categoryName.toLowerCase() == 'cardio';
  }

  Future<void> _loadDetails({bool preserveEditState = false}) async {
    if (!preserveEditState) {
      setState(() => _isLoading = true);
    }

    final data = await WorkoutDatabaseHelper.instance.getWorkoutLogById(
      widget.logId,
    );
    if (data == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final groups = <String, List<SetLog>>{};
    for (var set in data.sets) {
      groups.putIfAbsent(set.exerciseName, () => []).add(set);
    }

    // Exercises laden um Cardio zu erkennen
    final Map<String, Exercise> details = {};
    for (var name in groups.keys) {
      final ex = await WorkoutDatabaseHelper.instance.getExerciseByName(name);
      if (ex != null) details[name] = ex;
    }

    // Volumen (nur Kraft) für den Header
    final catVol = <String, double>{};
    for (var set in data.sets) {
      // Nur wenn nicht Cardio zum Volumen zählen?
      // Vereinfacht: wir zählen alles was weight*reps hat.
      // Cardio hat weight=0/null im Log (da in distanceKm gespeichert), also automatisch 0.
      final v = (set.weightKg ?? 0) * (set.reps ?? 0);
      if (v > 0) {
        final cat = details[set.exerciseName]?.categoryName ?? 'Other';
        catVol.update(cat, (val) => val + v, ifAbsent: () => v);
      }
    }

    _notesController.text = data.notes ?? '';
    _editedStartTime = data.startTime;

    // Controller befüllen
    _clearControllers();
    for (final setLog in data.sets) {
      // Unterscheidung Cardio vs Kraft für Initial-Werte
      final isCardio =
          details[setLog.exerciseName]?.categoryName.toLowerCase() == 'cardio';

      String val1, val2;

      if (isCardio) {
        // Cardio: Val1 = Distance, Val2 = Duration(min)
        val1 = setLog.distanceKm?.toStringAsFixed(1).replaceAll('.0', '') ?? '';
        final sec = setLog.durationSeconds ?? 0;
        val2 = sec > 0 ? (sec / 60).toStringAsFixed(0) : '';
      } else {
        // Kraft: Val1 = Weight, Val2 = Reps
        val1 = setLog.weightKg?.toStringAsFixed(1).replaceAll('.0', '') ?? '';
        val2 = setLog.reps?.toString() ?? '';
      }

      _weightControllers[setLog.id!] = TextEditingController(text: val1);
      _repsControllers[setLog.id!] = TextEditingController(text: val2);
      _rirControllers[setLog.id!] = TextEditingController(
        text: setLog.rir?.toString() ?? '',
      );
    }

    if (!mounted) return;
    setState(() {
      _log = data;
      _groupedSets = groups;
      _exerciseDetails = details;
      _categoryVolume = catVol;
      if (!preserveEditState) {
        _isLoading = false;
      }
    });
  }

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
    final dbHelper = WorkoutDatabaseHelper.instance;

    final initialSetIds = _log!.sets.map((s) => s.id!).toSet();
    final currentSets = _groupedSets.values.expand((sets) => sets).toList();

    final idsToDelete = initialSetIds
        .difference(currentSets.map((s) => s.id!).toSet())
        .toList();

    final List<SetLog> setsToUpdate = [];
    final List<SetLog> setsToInsert = [];

    for (final setLog in currentSets) {
      // Hier wieder die Unterscheidung: Was bedeuten die Controller-Werte?
      final isCardio = _isCardio(setLog.exerciseName);

      final val1 = double.tryParse(
            _weightControllers[setLog.id!]?.text.replaceAll(',', '.') ?? '0',
          ) ??
          0.0;
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
          // Weight/Reps auf 0/null setzen bei Cardio, um Datenmüll zu vermeiden?
          weightKg: 0,
          reps: 0,
        );
      } else {
        // Val1 = Weight, Val2 = Reps (int)
        updatedSet = setLog.copyWith(
          weightKg: val1,
          reps: val2.toInt(),
          rir: rir,
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

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.snackbarRoutineSaved)));
    }

    setState(() => _isEditMode = false);
    _loadDetails();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                      color: colorScheme.onSurfaceVariant.withOpacity(0.1),
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

                          // Sets
                          ..._buildSetList(context, l10n),

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
                                          const GeneralExerciseSelectionScreen(),
                                    ),
                                  );
                                  if (selectedExercise != null) {
                                    setState(() {
                                      // Exercise Details lokal speichern, damit _isCardio und Name funktionieren
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
                                        // Default Werte setzen
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

  List<Widget> _buildSetList(BuildContext context, AppLocalizations l10n) {
    final entries = _groupedSets.entries.toList();

    if (!_isEditMode) {
      return entries
          .map((entry) => _buildExerciseCard(context, l10n, entry, -1))
          .toList();
    } else {
      return [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = entries.removeAt(oldIndex);
              entries.insert(newIndex, item);
              _groupedSets.clear();
              for (var entry in entries) {
                _groupedSets[entry.key] = entry.value;
              }
            });
          },
          itemCount: entries.length,
          itemBuilder: (context, index) {
            return _buildExerciseCard(context, l10n, entries[index], index);
          },
        ),
      ];
    }
  }

  Widget _buildExerciseCard(
    BuildContext context,
    AppLocalizations l10n,
    MapEntry<String, List<SetLog>> entry,
    int index,
  ) {
    final String exerciseName = entry.key;
    final Exercise? exercise = _exerciseDetails[exerciseName];
    final List<SetLog> sets = entry.value;
    final textTheme = Theme.of(context).textTheme;
    final isCardio = _isCardio(exerciseName);

    return WorkoutCard(
      key: _isEditMode ? ValueKey(exerciseName) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            leading: _isEditMode
                ? ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  )
                : null,
            title: InkWell(
              onTap: () {
                if (exercise != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ExerciseDetailScreen(exercise: exercise),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  exercise?.getLocalizedName(context) ?? exerciseName,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            trailing: _isEditMode
                ? IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    tooltip: l10n.removeExercise,
                    onPressed: () {
                      setState(() {
                        for (var set in sets) {
                          _weightControllers.remove(set.id!)?.dispose();
                          _repsControllers.remove(set.id!)?.dispose();
                          _rirControllers.remove(set.id!)?.dispose();
                        }
                        _groupedSets.remove(exerciseName);
                      });
                    },
                  )
                : const Icon(Icons.info_outline),
          ),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCardio)
                  Row(
                    children: [
                      _buildHeader(l10n.setLabel, flex: 2),
                      _buildHeader(l10n.cardioDistanceLabel, flex: 4),
                      const SizedBox(width: 8),
                      _buildHeader(l10n.cardioTimeLabel, flex: 4),
                      const SizedBox(width: 8),
                      _buildHeader(l10n.cardioIntensityShortLabel, flex: 2),
                      const SizedBox(width: 48), // Platz für Check/Del
                    ],
                  )
                else
                  Row(
                    children: [
                      _buildHeader(l10n.setLabel, flex: 2),
                      _buildHeader(
                        l10n.lastTimeLabel,
                        flex: 3,
                      ), // Nur in View sinnvoll, hier aber Platzhalter
                      _buildHeader(l10n.kgLabel, flex: 2),
                      _buildHeader(l10n.repsLabel, flex: 2),
                      _buildHeader("RIR", flex: 2),
                      const SizedBox(width: 48),
                    ],
                  ),

                // Set Rows
                ...sets.asMap().entries.map((setEntry) {
                  final setLog = setEntry.value;
                  final rowIndex = setEntry.key;
                  int workingSetIndex = 0;
                  for (int i = 0; i <= rowIndex; i++) {
                    if (sets[i].setType != 'warmup') workingSetIndex++;
                  }

                  return _buildSetRow(
                    setLog,
                    rowIndex,
                    workingSetIndex,
                    exerciseName,
                    l10n,
                    isCardio,
                  );
                }),

                if (_isEditMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextButton.icon(
                      onPressed: () {
                        final newSet = SetLog(
                          id: DateTime.now().millisecondsSinceEpoch,
                          workoutLogId: _log!.id!,
                          exerciseName: exerciseName,
                          setType: 'normal',
                          isCompleted: true,
                        );
                        setState(() {
                          sets.add(newSet);
                          _weightControllers[newSet.id!] =
                              TextEditingController();
                          _repsControllers[newSet.id!] =
                              TextEditingController();
                          _rirControllers[newSet.id!] = TextEditingController();
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addSetButton),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildSetRow(
    SetLog setLog,
    int rowIndex,
    int workingSetIndex,
    String exerciseName,
    AppLocalizations l10n,
    bool isCardio,
  ) {
    final setType = setLog.setType;
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final bool isColoredRow = rowIndex > 0 && rowIndex.isOdd;
    final Color rowColor = isColoredRow
        ? (isLightMode
            ? Colors.grey.withOpacity(0.1)
            : Colors.white.withOpacity(0.1))
        : Colors.transparent;

    // View Values
    String val1Display, val2Display;
    if (isCardio) {
      val1Display = setLog.distanceKm?.toString() ?? '-';
      final sec = setLog.durationSeconds ?? 0;
      val2Display = sec > 0 ? (sec / 60).round().toString() : '-';
    } else {
      val1Display =
          setLog.weightKg?.toStringAsFixed(1).replaceAll('.0', '') ?? '-';
      val2Display = setLog.reps?.toString() ?? '-';
    }

    return Container(
      color: rowColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              flex: isCardio ? 2 : 2,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_isEditMode) _showSetTypePicker(setLog.id!);
                  },
                  child: Text(
                    _getSetDisplayText(setType, workingSetIndex),
                    style: TextStyle(
                      color: _getSetTypeColor(setType),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            if (!isCardio)
              const Expanded(
                flex: 3,
                child: Center(child: Text("-")),
              ), // Last Time Placeholder

            Expanded(
              flex: isCardio ? 2 : 2,
              child: _isEditMode
                  ? TextFormField(
                      controller: _weightControllers[setLog.id!],
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        fillColor: Colors.transparent,
                        hintText: "-",
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  : Text(
                      val1Display,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: isCardio ? 2 : 2,
              child: _isEditMode
                  ? TextFormField(
                      controller: _repsControllers[setLog.id!],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        fillColor: Colors.transparent,
                        hintText: "-",
                      ),
                    )
                  : Text(
                      val2Display,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(width: 8),
            // RIR / Intens
            Expanded(
              flex: 2,
              child: _isEditMode
                  ? TextFormField(
                      controller: _rirControllers[setLog.id!],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        fillColor: Colors.transparent,
                        hintText: "-",
                      ),
                    )
                  : Text(
                      setLog.rir?.toString() ?? '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 48,
                child: _isEditMode
                    ? IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            _groupedSets[exerciseName]?.removeWhere(
                              (s) => s.id == setLog.id,
                            );
                            _weightControllers.remove(setLog.id!)?.dispose();
                            _repsControllers.remove(setLog.id!)?.dispose();
                            _rirControllers.remove(setLog.id!)?.dispose();
                          });
                        },
                      )
                    : const Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
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
    Navigator.pop(context);
  }

  void _showSetTypePicker(int setLogId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              title: const Text('Normal'),
              onTap: () => _changeSetType(setLogId, 'normal'),
            ),
            ListTile(
              title: const Text('Warmup'),
              onTap: () => _changeSetType(setLogId, 'warmup'),
            ),
            ListTile(
              title: const Text('Failure'),
              onTap: () => _changeSetType(setLogId, 'failure'),
            ),
            ListTile(
              title: const Text('Dropset'),
              onTap: () => _changeSetType(setLogId, 'dropset'),
            ),
          ],
        );
      },
    );
  }

  Color _getSetTypeColor(String setType) {
    switch (setType) {
      case 'warmup':
        return Colors.orange;
      case 'dropset':
        return Colors.blue;
      case 'failure':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
