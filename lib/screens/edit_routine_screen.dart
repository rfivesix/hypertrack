// lib/screens/edit_routine_screen.dart
// FINAL: Cardio Clean-Up (1 Set, Cleaner Layout, Empty Defaults)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../models/routine_exercise.dart';
import '../models/set_template.dart';
import 'general_exercise_selection_screen.dart';
import 'exercise_detail_screen.dart';
import '../util/design_constants.dart';
import '../widgets/glass_bottom_menu.dart';
import '../widgets/glass_fab.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/set_type_chip.dart';
import '../widgets/wger_attribution_widget.dart';
import '../widgets/workout_card.dart';

/// A screen for creating or modifying a [Routine].
///
/// Allows users to name their routine and manage a list of [RoutineExercise] items.
/// Each exercise can have multiple sets with target reps, weight, and RIR.
class EditRoutineScreen extends StatefulWidget {
  /// The [Routine] to be edited. If null, a new routine is created.
  final Routine? routine;
  const EditRoutineScreen({super.key, this.routine});

  @override
  State<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> {
  final _nameController = TextEditingController();
  List<RoutineExercise> _routineExercises = [];
  bool _isNewRoutine = true;
  int? _routineId;
  String _originalName = '';
  bool _isLoading = false;

  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _rirControllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.routine != null) {
      _isNewRoutine = false;
      _routineId = widget.routine!.id;
      _nameController.text = widget.routine!.name;
      _originalName = widget.routine!.name;
      _loadExercisesForRoutine();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var c in _repsControllers.values) {
      c.dispose();
    }
    for (var c in _weightControllers.values) {
      c.dispose();
    }
    for (var c in _rirControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isCardio(RoutineExercise re) {
    return re.exercise.categoryName.toLowerCase() == 'cardio';
  }

  Future<void> _loadExercisesForRoutine() async {
    if (_routineId == null) return;
    setState(() => _isLoading = true);
    final routineWithExercises =
        await WorkoutDatabaseHelper.instance.getRoutineById(_routineId!);
    if (mounted && routineWithExercises != null) {
      for (var c in _repsControllers.values) {
        c.dispose();
      }
      for (var c in _weightControllers.values) {
        c.dispose();
      }
      for (var c in _rirControllers.values) {
        c.dispose();
      }

      _repsControllers.clear();
      _weightControllers.clear();
      _rirControllers.clear();

      for (var re in routineWithExercises.exercises) {
        final isCardio = _isCardio(re);
        for (var st in re.setTemplates) {
          // FIX: Wenn es Cardio ist und der Wert "8-12" (Default DB) ist, leer anzeigen
          String repsText = st.targetReps ?? '';
          if (isCardio && repsText == '8-12') repsText = '';

          _repsControllers[st.id!] = TextEditingController(text: repsText);
          _weightControllers[st.id!] = TextEditingController(
            text: st.targetWeight?.toString() ?? '',
          );
          _rirControllers[st.id!] = TextEditingController(
            text: st.targetRir?.toString() ?? '',
          );
        }
      }

      setState(() {
        _routineExercises = routineWithExercises.exercises;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addExercises() async {
    if (_isNewRoutine) {
      final success = await _saveRoutine(isAddingExercise: true);
      if (!success) return;
    }
    if (!mounted) return;
    final selectedExercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (context) => const GeneralExerciseSelectionScreen(),
      ),
    );

    if (selectedExercise != null && _routineId != null) {
      // FIX: Cardio Check vor dem Hinzufügen
      final isCardio = selectedExercise.categoryName.toLowerCase() == 'cardio';
      final initialSetCount = isCardio ? 1 : 3;

      final newRoutineExercise =
          await WorkoutDatabaseHelper.instance.addExerciseToRoutine(
        _routineId!,
        selectedExercise.id!,
        initialSetCount: initialSetCount,
      ); // Parameter

      if (newRoutineExercise != null) {
        for (var st in newRoutineExercise.setTemplates) {
          // FIX: Leere Reps für Cardio
          final defaultReps = isCardio ? '' : st.targetReps;

          _repsControllers[st.id!] = TextEditingController(text: defaultReps);
          _weightControllers[st.id!] = TextEditingController(
            text: st.targetWeight?.toString() ?? '',
          );
          _rirControllers[st.id!] = TextEditingController(
            text: st.targetRir?.toString() ?? '',
          );
        }
        setState(() {
          _routineExercises = [..._routineExercises, newRoutineExercise];
        });
      }
    }
  }

  Future<bool> _saveRoutine({bool isAddingExercise = false}) async {
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.validatorPleaseEnterRoutineName)),
        );
      }
      return false;
    }

    int? currentRoutineId = _routineId;

    if (_isNewRoutine) {
      final newRoutine = await WorkoutDatabaseHelper.instance.createRoutine(
        _nameController.text.trim(),
      );
      currentRoutineId = newRoutine.id;
      if (mounted) {
        setState(() {
          _routineId = newRoutine.id;
          _isNewRoutine = false;
          _originalName = newRoutine.name;
        });
      }
      if (mounted && !isAddingExercise) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.snackbarRoutineCreated)));
      }
    } else {
      if (_nameController.text.trim() != _originalName) {
        await WorkoutDatabaseHelper.instance.updateRoutineName(
          currentRoutineId!,
          _nameController.text.trim(),
        );
      }
    }

    final db = WorkoutDatabaseHelper.instance;
    for (var re in _routineExercises) {
      final List<SetTemplate> currentTemplates = [];
      for (var set in re.setTemplates) {
        final rirText = _rirControllers[set.id!]?.text ?? '';
        currentTemplates.add(
          set.copyWith(
            targetReps: _repsControllers[set.id!]?.text,
            targetWeight: double.tryParse(
              _weightControllers[set.id!]!.text.replaceAll(',', '.'),
            ),
            targetRir: int.tryParse(rirText),
            clearTargetRir: rirText.isEmpty,
          ),
        );
      }
      await db.replaceSetTemplatesForExercise(re.id!, currentTemplates);
    }

    if (mounted && !isAddingExercise) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.snackbarRoutineSaved)));
      Navigator.of(context).pop(true);
    }
    return true;
  }

  void _addSet(RoutineExercise routineExercise) {
    setState(() {
      final isCardio = _isCardio(routineExercise);
      final newSet = SetTemplate(
        id: DateTime.now().millisecondsSinceEpoch,
        setType: 'normal',
        targetReps: isCardio ? '' : '8-12', // FIX
      );

      final exerciseIndex = _routineExercises.indexOf(routineExercise);
      if (exerciseIndex == -1) return;

      final updatedTemplates = [...routineExercise.setTemplates, newSet];
      final updatedExercise = RoutineExercise(
        id: routineExercise.id,
        exercise: routineExercise.exercise,
        setTemplates: updatedTemplates,
        pauseSeconds: routineExercise.pauseSeconds,
      );
      _routineExercises[exerciseIndex] = updatedExercise;

      _repsControllers[newSet.id!] = TextEditingController(
        text: newSet.targetReps,
      );
      _weightControllers[newSet.id!] = TextEditingController();
      _rirControllers[newSet.id!] = TextEditingController();
    });
  }

  void _removeSet(RoutineExercise re, int setTemplateId, int index) {
    setState(() {
      final exerciseIndex = _routineExercises.indexOf(re);
      if (exerciseIndex == -1) return;

      final updatedTemplates = [...re.setTemplates];
      updatedTemplates.removeAt(index);

      final updatedExercise = RoutineExercise(
        id: re.id,
        exercise: re.exercise,
        setTemplates: updatedTemplates,
        pauseSeconds: re.pauseSeconds,
      );
      _routineExercises[exerciseIndex] = updatedExercise;

      _repsControllers.remove(setTemplateId)?.dispose();
      _weightControllers.remove(setTemplateId)?.dispose();
      _rirControllers.remove(setTemplateId)?.dispose();
    });
  }

  void _changeSetType(SetTemplate setTemplate, String newType) {
    setState(() {
      final reIndex = _routineExercises.indexWhere(
        (re) => re.setTemplates.contains(setTemplate),
      );
      if (reIndex == -1) return;

      final routineExercise = _routineExercises[reIndex];
      final setIndex = routineExercise.setTemplates.indexOf(setTemplate);
      if (setIndex == -1) return;

      final updatedTemplates = [...routineExercise.setTemplates];
      updatedTemplates[setIndex] = setTemplate.copyWith(setType: newType);

      _routineExercises[reIndex] = RoutineExercise(
        id: routineExercise.id,
        exercise: routineExercise.exercise,
        setTemplates: updatedTemplates,
        pauseSeconds: routineExercise.pauseSeconds,
      );
    });
  }

  void _showSetTypePicker(SetTemplate setTemplate) {
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
          onTap: () => _changeSetType(setTemplate, opt['type'] as String),
        );
      }).toList(),
    );
  }

  void _editPauseTime(RoutineExercise re) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: re.pauseSeconds?.toString() ?? '',
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
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
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
                      final seconds = int.tryParse(controller.text);
                      close();
                      Navigator.of(ctx).pop(seconds);
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
      await WorkoutDatabaseHelper.instance.updatePauseTime(re.id!, result);
      _loadExercisesForRoutine();
    }
  }

  void _deleteSingleExercise(RoutineExercise ex) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDeleteConfirmation(
      context,
      title: l10n.deleteExerciseConfirmTitle,
      content: l10n.deleteExerciseConfirmContent(
        ex.exercise.getLocalizedName(context),
      ),
    );

    if (confirmed && _routineId != null) {
      await WorkoutDatabaseHelper.instance.removeExerciseFromRoutine(ex.id!);
      _loadExercisesForRoutine();
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final RoutineExercise item = _routineExercises.removeAt(oldIndex);
      _routineExercises.insert(newIndex, item);
    });
    if (_routineId != null) {
      WorkoutDatabaseHelper.instance.updateExerciseOrder(
        _routineId!,
        _routineExercises,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBar(
        title: _isNewRoutine ? l10n.titleNewRoutine : l10n.titleEditRoutine,
        actions: [
          TextButton(
            onPressed: () => _saveRoutine(),
            child: Text(
              l10n.save,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: DesignConstants.cardPadding.copyWith(
              top: DesignConstants.cardPadding.top + topPadding,
            ),
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.formFieldRoutineName),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.validatorPleaseEnterRoutineName;
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.onSurfaceVariant.withOpacity(0.1),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _routineExercises.isEmpty
                    ? Center(
                        child: Text(
                          l10n.emptyStateAddFirstExercise,
                          style: textTheme.titleMedium,
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _routineExercises.length,
                        proxyDecorator:
                            (Widget child, int index, Animation<double> anim) {
                          return Material(
                            elevation: 4.0,
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: child,
                          );
                        },
                        onReorder: _onReorder,
                        itemBuilder: (context, index) {
                          final routineExercise = _routineExercises[index];
                          final bool isCardio = _isCardio(routineExercise);

                          return WorkoutCard(
                            key: ValueKey(routineExercise.id),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  title: InkWell(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ExerciseDetailScreen(
                                          exercise: routineExercise.exercise,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: Text(
                                        routineExercise.exercise
                                            .getLocalizedName(
                                          context,
                                        ),
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  leading: ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.drag_handle),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (routineExercise.pauseSeconds !=
                                              null &&
                                          routineExercise.pauseSeconds! > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 4.0,
                                          ),
                                          child: Text(
                                            "${routineExercise.pauseSeconds}s",
                                            style:
                                                textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.timer_outlined),
                                        tooltip: l10n.editPauseTime,
                                        onPressed: () =>
                                            _editPauseTime(routineExercise),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: l10n.removeExercise,
                                        onPressed: () => _deleteSingleExercise(
                                            routineExercise),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 0.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildHeaderRow(routineExercise, l10n),
                                      ...routineExercise.setTemplates
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final setIndex = entry.key;
                                        final setTemplate = entry.value;

                                        int workingSetIndex = 0;
                                        for (int i = 0; i <= setIndex; i++) {
                                          if (routineExercise
                                                  .setTemplates[i].setType !=
                                              'warmup') {
                                            workingSetIndex++;
                                          }
                                        }

                                        return _buildSetTemplateRow(
                                          workingSetIndex,
                                          setIndex,
                                          routineExercise,
                                          setTemplate,
                                          setIndex,
                                          isCardio, // <--- CARDIO FLAG
                                          l10n,
                                        );
                                      }),
                                      const SizedBox(
                                        height: DesignConstants.spacingS,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                        ),
                                        child: TextButton.icon(
                                          onPressed: () =>
                                              _addSet(routineExercise),
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
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
            child: WgerAttributionWidget(
              textStyle: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      floatingActionButton: GlassFab(
        label: l10n.fabAddExercise,
        onPressed: _addExercises,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // --- HEADER ROW (Dynamic) ---
  Widget _buildHeaderRow(RoutineExercise re, AppLocalizations l10n) {
    final bool isCardio = _isCardio(re);
    if (isCardio) {
      return Row(
        children: [
          _buildHeader(l10n.setLabel, flex: 2), // FIX: Kleiner
          _buildHeader(l10n.cardioDistanceLabel,
              flex: 4), // FIX: Sehr viel Platz
          const SizedBox(width: 8),
          _buildHeader(l10n.cardioTimeLabel, flex: 4), // FIX: Sehr viel Platz
          const SizedBox(width: 8),
          _buildHeader(l10n.cardioIntensityLabel, flex: 2),
          const SizedBox(width: 48),
        ],
      );
    }
    // Standard Strength Header
    return Row(
      children: [
        _buildHeader(l10n.setLabel, flex: 2),
        _buildHeader(l10n.kgLabel, flex: 2),
        const SizedBox(width: 8),
        _buildHeader(l10n.repsLabel, flex: 2),
        const SizedBox(width: 8),
        _buildHeader("RIR", flex: 2),
        const SizedBox(width: 48),
      ],
    );
  }

  // --- TEMPLATE ROW (Dynamic) ---
  Widget _buildSetTemplateRow(
    int setIndex,
    int rowIndex,
    RoutineExercise re,
    SetTemplate template,
    int listIndex,
    bool isCardio,
    AppLocalizations l10n,
  ) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final bool isColoredRow = rowIndex > 0 && rowIndex.isOdd;

    final Color rowColor;
    if (isColoredRow) {
      rowColor = isLightMode
          ? Colors.grey.withOpacity(0.08)
          : Colors.white.withOpacity(0.05);
    } else {
      rowColor = Colors.transparent;
    }

    return Container(
      color: rowColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              flex: isCardio ? 2 : 2, // FIX: Kleiner für Cardio
              child: Center(
                child: SetTypeChip(
                  setType: template.setType,
                  setIndex: (template.setType == 'warmup') ? null : setIndex,
                  onTap: () => _showSetTypePicker(template),
                ),
              ),
            ),
            if (isCardio) ...[
              // CARDIO FIELDS
              Expanded(
                flex: 4, // FIX: Mehr Platz
                child: TextFormField(
                  controller: _weightControllers[template.id!],
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: "-",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2, // FIX: Mehr Platz
                child: TextFormField(
                  controller: _repsControllers[template.id!],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: "-",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _rirControllers[template.id!],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: "-",
                  ),
                ),
              ),
            ] else ...[
              // STRENGTH FIELDS
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _weightControllers[template.id!],
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: l10n.kgLabelShort,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _repsControllers[template.id!],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: l10n.set_reps_hint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _rirControllers[template.id!],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    hintText: "-",
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 48,
                child: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _removeSet(re, template.id!, listIndex),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String text, {required int flex}) => Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
