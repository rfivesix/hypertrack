// lib/screens/live_workout_screen.dart
// FINAL: Cardio fix + null safety + header logic

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../util/design_constants.dart';
import '../widgets/glass_bottom_menu.dart';
import '../widgets/glass_fab.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../models/routine_exercise.dart';
import '../models/set_log.dart';
import '../models/workout_log.dart';
import '../models/set_template.dart';
import '../services/haptic_feedback_service.dart';
import '../services/workout_session_manager.dart';
import '../services/unit_service.dart';
import '../widgets/wger_attribution_widget.dart';
import '../widgets/workout_summary_bar.dart';
import 'general_exercise_selection_screen.dart';
import 'exercise_detail_screen.dart';
import 'package:provider/provider.dart';
import 'workout_summary_screen.dart';
import '../widgets/workout_card.dart';
// Used when vibration is enabled.

/// The active workout tracking screen, managing the real-time session state.
///
/// Handles input for sets, reps, weight, RPE/RIR, and cardio metrics. Coordinates
/// with [WorkoutSessionManager] to persist progress and provide rest timers.
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
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _rirControllers = {};

  final Map<String, List<SetLog>> _lastPerformances = {};
  bool _isLoading = true;

  late final VoidCallback _onManagerUpdateCallback;
  WorkoutSessionManager? _manager;

  // PR Celebration State
  StreamSubscription<PREvent>? _prEventsSubscription;
  final List<PREvent> _prQueue = [];
  bool _isShowingPR = false;
  PREvent? _currentPR;
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
        final manager = Provider.of<WorkoutSessionManager>(
          context,
          listen: false,
        );
        _syncControllersWithManager(manager);
        setState(() {});
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeScreen();
      final manager = Provider.of<WorkoutSessionManager>(
        context,
        listen: false,
      );
      _manager = manager;
      manager.addListener(_onManagerUpdateCallback);

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
    _clearControllers();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    final manager = Provider.of<WorkoutSessionManager>(context, listen: false);
    List<RoutineExercise> exercisesToInit = [];

    if (!manager.isActive) {
      exercisesToInit = widget.routine?.exercises ?? [];
      await manager.startWorkout(widget.workoutLog, exercisesToInit);
    } else {
      exercisesToInit = manager.exercises;
    }

    for (var re in exercisesToInit) {
      final lastSets = await WorkoutDatabaseHelper.instance
          .getLastSetsForExercise(re.exercise.nameEn);
      if (mounted) {
        _lastPerformances[re.exercise.nameEn] = lastSets;
      }
    }

    _syncControllersWithManager(manager);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // --- Cardio check helper ---
  bool _isCardio(RoutineExercise re) {
    return re.exercise.categoryName.toLowerCase() == 'cardio';
  }

  void _syncControllersWithManager(WorkoutSessionManager manager) {
    final unitService = context.read<UnitService>();
    manager.setLogs.forEach((templateId, setLog) {
      // Find the associated exercise
      final exercise = manager.exercises.firstWhere(
        (re) => re.setTemplates.any((t) => t.id == templateId),
        // Fallback if template is not found (should not happen)
        orElse: () => manager.exercises.first,
      );
      final isCardio = _isCardio(exercise);

      // --- WEIGHT / DISTANCE CONTROLLER ---
      if (!_weightControllers.containsKey(templateId)) {
        String initText;
        if (isCardio) {
          // Cardio: Distance
          initText =
              setLog.distanceKm?.toStringAsFixed(1).replaceAll('.0', '') ?? '';
        } else {
          // Strength: weight
          initText = setLog.weightKg == null
              ? ''
              : unitService
                  .convertDisplayValue(setLog.weightKg!, UnitDimension.weight)
                  .toStringAsFixed(1)
                  .replaceAll('.0', '');
        }

        _weightControllers[templateId] = TextEditingController(text: initText);

        _weightControllers[templateId]!.addListener(() {
          final text = _weightControllers[templateId]!.text;
          final val = double.tryParse(text.replaceAll(',', '.'));
          final clearValue = val == null && text.isEmpty;

          if (isCardio) {
            // Update Distance
            if (val != manager.setLogs[templateId]?.distanceKm || clearValue) {
              manager.updateSet(
                templateId,
                distance: val,
                clearDistance: clearValue,
              );
            }
          } else {
            // Update Weight
            final metricValue = val == null
                ? null
                : unitService.convertToMetric(val, UnitDimension.weight);
            if (metricValue != manager.setLogs[templateId]?.weightKg ||
                clearValue) {
              manager.updateSet(
                templateId,
                weight: metricValue,
                clearWeight: clearValue,
              );
            }
          }
        });
      }

      // --- REPS / DURATION CONTROLLER ---
      if (!_repsControllers.containsKey(templateId)) {
        String initText;
        if (isCardio) {
          // Cardio: duration in minutes from seconds
          final seconds = setLog.durationSeconds ?? 0;
          initText = seconds > 0 ? (seconds / 60).toStringAsFixed(0) : '';
        } else {
          // Strength: reps
          initText = setLog.reps?.toString() ?? '';
        }

        _repsControllers[templateId] = TextEditingController(text: initText);

        _repsControllers[templateId]!.addListener(() {
          final text = _repsControllers[templateId]!.text;
          if (isCardio) {
            // Input minutes -> save seconds
            final minutes = double.tryParse(text.replaceAll(',', '.'));
            final seconds = (minutes != null) ? (minutes * 60).round() : null;
            final clearDuration = seconds == null && text.isEmpty;
            if (seconds != manager.setLogs[templateId]?.durationSeconds ||
                clearDuration) {
              manager.updateSet(
                templateId,
                duration: seconds,
                clearDuration: clearDuration,
              );
            }
          } else {
            final val = int.tryParse(text);
            final clearReps = val == null && text.isEmpty;
            if (val != manager.setLogs[templateId]?.reps || clearReps) {
              manager.updateSet(templateId, reps: val, clearReps: clearReps);
            }
          }
        });
      }

      // --- RIR CONTROLLER ---
      if (!_rirControllers.containsKey(templateId)) {
        _rirControllers[templateId] = TextEditingController(
          text: setLog.rir?.toString() ?? '',
        );

        _rirControllers[templateId]!.addListener(() {
          final text = _rirControllers[templateId]!.text;
          final val = int.tryParse(text);
          final clearRir = val == null && text.isEmpty;
          if (val != manager.setLogs[templateId]?.rir || clearRir) {
            manager.updateSet(templateId, rir: val, clearRir: clearRir);
          }
        });
      }

      // --- SYNC FALLBACK VALUES TO UI ---
      // If a set was completed and the manager filled in a fallback value,
      // update the UI text fields to show the accepted fallback number.
      if (setLog.weightKg != null &&
          _weightControllers[templateId]?.text.isEmpty == true) {
        _weightControllers[templateId]!.text = unitService
            .convertDisplayValue(setLog.weightKg!, UnitDimension.weight)
            .toStringAsFixed(1)
            .replaceAll('.0', '');
      }
      if (setLog.distanceKm != null &&
          _weightControllers[templateId]?.text.isEmpty == true &&
          isCardio) {
        _weightControllers[templateId]!.text =
            setLog.distanceKm!.toStringAsFixed(1).replaceAll('.0', '');
      }
      if (setLog.reps != null &&
          _repsControllers[templateId]?.text.isEmpty == true &&
          !isCardio) {
        _repsControllers[templateId]!.text = setLog.reps!.toString();
      }
      if (setLog.durationSeconds != null &&
          _repsControllers[templateId]?.text.isEmpty == true &&
          isCardio) {
        _repsControllers[templateId]!.text =
            (setLog.durationSeconds! / 60).toStringAsFixed(0);
      }
      if (setLog.rir != null &&
          _rirControllers[templateId]?.text.isEmpty == true) {
        _rirControllers[templateId]!.text = setLog.rir!.toString();
      }
    });

    // Cleanup
    final toRemove = _weightControllers.keys
        .where((id) => !manager.setLogs.containsKey(id))
        .toList();
    for (final id in toRemove) {
      _weightControllers.remove(id)?.dispose();
      _repsControllers.remove(id)?.dispose();
      _rirControllers.remove(id)?.dispose();
    }
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

  Future<void> _finishWorkout() async {
    final l10n = AppLocalizations.of(context)!;
    final manager = Provider.of<WorkoutSessionManager>(context, listen: false);

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
    Provider.of<WorkoutSessionManager>(
      context,
      listen: false,
    ).reorderExercise(oldIndex, newIndex);
  }

  void _removeExercise(RoutineExercise exerciseToRemove) {
    Provider.of<WorkoutSessionManager>(
      context,
      listen: false,
    ).removeExercise(exerciseToRemove.id!);
  }

  void _addExercise() async {
    final manager = Provider.of<WorkoutSessionManager>(context, listen: false);
    final selectedExercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (context) => const GeneralExerciseSelectionScreen(),
      ),
    );

    if (selectedExercise != null) {
      final lastSets = await WorkoutDatabaseHelper.instance
          .getLastSetsForExercise(selectedExercise.nameEn);
      if (mounted) {
        setState(() {
          _lastPerformances[selectedExercise.nameEn] = lastSets;
        });
      }
      await manager.addExercise(selectedExercise);
    }
  }

  void _addSet(RoutineExercise re) {
    Provider.of<WorkoutSessionManager>(
      context,
      listen: false,
    ).addSetToExercise(re.id!);
  }

  void _removeSet(int templateId) {
    Provider.of<WorkoutSessionManager>(
      context,
      listen: false,
    ).removeSet(templateId);
  }

  void _changeSetType(int templateId, String newType) {
    Provider.of<WorkoutSessionManager>(
      context,
      listen: false,
    ).updateSet(templateId, setType: newType);
  }

  void _showSetTypePicker(int templateId) {
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
          onTap: () => _changeSetType(templateId, opt['type'] as String),
        );
      }).toList(),
    );
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
        _buildHeader(l10n.setLabel, flex: 2),
        _buildHeader(l10n.lastTimeLabel, flex: 3),
        _buildHeader(unitService.suffixFor(UnitDimension.weight), flex: 2),
        const SizedBox(width: 8),
        _buildHeader(l10n.repsLabel, flex: 2),
        const SizedBox(width: 8),
        _buildHeader("RIR", flex: 2),
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
    if (_currentPR == null) return const SizedBox.shrink();

    final localizedRecordType = _getLocalizedRecordType(_currentPR!.recordType);
    final unitService = context.read<UnitService>();
    final String achievementText = _formatDisplayWeightText(
      _currentPR!.achievementValue,
      unitService,
    );
    final String diffText = _currentPR!.diff != null
        ? " (+${_formatDisplayWeightValue(_currentPR!.diff!, unitService)} ${unitService.suffixFor(UnitDimension.weight)})"
        : "";

    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = isLightMode
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.8);
    final borderColor = isLightMode
        ? Colors.grey.withValues(alpha: 0.3)
        : Colors.amber.withValues(alpha: 0.4);
    final primaryTextColor = isLightMode ? Colors.black : Colors.white;
    final secondaryTextColor = isLightMode ? Colors.black87 : Colors.white70;

    return SlideTransition(
      position: _prSlideAnimation,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentPR!.exerciseName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                              children: [
                                TextSpan(text: "$localizedRecordType - "),
                                TextSpan(
                                  text: achievementText,
                                  style: const TextStyle(color: Colors.amber),
                                ),
                                if (diffText.isNotEmpty)
                                  TextSpan(
                                    text: diffText,
                                    style: TextStyle(
                                      color:
                                          Colors.amber.withValues(alpha: 0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPRBadge(SetLog setLog) {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.read<UnitService>();
    String label = l10n.newPersonalRecordLabel;

    if (setLog.isMaxWeightPR && setLog.weightPRDiff != null) {
      label =
          "+${_formatDisplayWeightValue(setLog.weightPRDiff!, unitService)} ${unitService.suffixFor(UnitDimension.weight)}";
    } else if (setLog.isMaxEst1RMPR && setLog.est1rmPRDiff != null) {
      label =
          "+${_formatDisplayWeightValue(setLog.est1rmPRDiff!, unitService)} ${unitService.suffixFor(UnitDimension.weight)} (1RM)";
    } else if (setLog.isMaxVolumePR && setLog.volumePRDiff != null) {
      label =
          "+${_formatDisplayWeightValue(setLog.volumePRDiff!, unitService, fractionDigits: 0)} ${unitService.suffixFor(UnitDimension.weight)} (Vol)";
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Tooltip(
        message: l10n.prBadgeTooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetRow(
    int setIndex,
    int rowIndex,
    int templateId,
    SetLog setLog,
    List<SetLog> lastPerfSets,
    SetTemplate template,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final manager = Provider.of<WorkoutSessionManager>(context, listen: false);
    final bool isCompleted = setLog.isCompleted ?? false;
    final unitService = context.read<UnitService>();

    // Cardio Check
    final exercise = manager.exercises.firstWhere(
      (re) => re.setTemplates.any((t) => t.id == templateId),
    );
    final bool isCardio = _isCardio(exercise);

    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final bool isColoredRow = rowIndex > 0 && rowIndex.isOdd;
    final Color rowColor = isColoredRow
        ? (isLightMode
            ? Colors.grey.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.1))
        : Colors.transparent;

    // Hint Logic
    String weightHint = '0';
    String repHint = '0';
    String rirHint =
        template.targetRir != null ? template.targetRir.toString() : '-';

    if (isCardio) {
      weightHint = "-"; // Distance Hint
      repHint = "-"; // Time Hint
    } else {
      final double tWeight = template.targetWeight ?? 0.0;
      weightHint = tWeight > 0
          ? unitService
              .convertDisplayValue(tWeight, UnitDimension.weight)
              .toStringAsFixed(1)
              .replaceAll('.0', '')
          : '0';
      repHint = (template.targetReps?.isNotEmpty == true)
          ? template.targetReps!
          : '0';
    }

    final rowContent = Row(
      children: [
        // 1. SET NUMBER
        Expanded(
          flex: 2,
          child: Center(
            child: GestureDetector(
              onTap: () => isCompleted ? null : _showSetTypePicker(templateId),
              child: Text(
                _getSetDisplayText(setLog.setType, setIndex),
                style: TextStyle(
                  color: _getSetTypeColor(setLog.setType),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // 2. LAST PERFORMANCE
        Expanded(
          flex: 3,
          child: isCardio
              ? const SizedBox.shrink() // For cardio, do not show history yet.
              : Text(
                  (rowIndex < lastPerfSets.length)
                      ? "${unitService.convertDisplayValue(lastPerfSets[rowIndex].weightKg ?? 0, UnitDimension.weight).toStringAsFixed(1).replaceAll('.0', '')}${unitService.suffixFor(UnitDimension.weight)} × ${lastPerfSets[rowIndex].reps}"
                      : "-",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),

        // 3. INPUT 1: WEIGHT / DISTANCE
        Expanded(
          flex: isCardio ? 2 : 2, // More space for cardio distance
          child: TextFormField(
            controller: _weightControllers[templateId],
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              fillColor: Colors.transparent,
              hintText: weightHint,
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.5),
                fontSize: 18,
              ),
            ),
            enabled: !isCompleted,
          ),
        ),
        const SizedBox(width: 8),

        // 4. INPUT 2: REPS / TIME
        Expanded(
          flex: isCardio ? 2 : 2, // More space for cardio time
          child: TextFormField(
            controller: _repsControllers[templateId],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              fillColor: Colors.transparent,
              hintText: repHint,
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.5),
                fontSize: 18,
              ),
            ),
            enabled: !isCompleted,
          ),
        ),
        const SizedBox(width: 8),

        // 5. INPUT 3: RIR / INTENSITY
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _rirControllers[templateId],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              fillColor: Colors.transparent,
              hintText: rirHint,
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.5),
                fontSize: 18,
              ),
            ),
            enabled: !isCompleted,
          ),
        ),

        // 6. CHECKBOX
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                child: IconButton(
                  icon: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                  onPressed: () {
                    manager.updateSet(templateId, isCompleted: !isCompleted);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final currentSetE1rm = _calculateBrzyckiE1rm(
      setLog,
      requireCompleted: false,
    );
    final showCurrentSetE1rm = !isCardio && currentSetE1rm != null;

    final bool hasPR = isCompleted &&
        (setLog.isMaxWeightPR || setLog.isMaxVolumePR || setLog.isMaxEst1RMPR);

    final rowWithSubInfo = Column(
      children: [
        rowContent,
        if (showCurrentSetE1rm || hasPR)
          Padding(
            padding: const EdgeInsets.only(right: 12.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasPR) ...[
                  _buildPRBadge(setLog),
                  if (showCurrentSetE1rm) const SizedBox(width: 8),
                ],
                if (showCurrentSetE1rm)
                  Text(
                    l10n.liveWorkoutE1rmCurrentSet(
                      _formatDisplayWeightValue(currentSetE1rm, unitService),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );

    return Dismissible(
      key: ValueKey('set_$templateId'),
      direction:
          isCompleted ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (_) => _removeSet(templateId),
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color:
                  isCompleted ? Colors.green.withValues(alpha: 0.2) : rowColor,
            ),
          ),
          rowWithSubInfo,
        ],
      ),
    );
  }

  Widget _buildExerciseE1rmSummary(
    AppLocalizations l10n,
    RoutineExercise routineExercise,
    WorkoutSessionManager manager,
  ) {
    final unitService = context.read<UnitService>();
    final sessionBest = _getSessionBestE1rm(routineExercise, manager);
    if (sessionBest == null) return const SizedBox.shrink();

    final lastSessionBest = _getLastSessionBestE1rm(
      routineExercise.exercise.nameEn,
    );
    final hasDelta = lastSessionBest != null;
    final delta = hasDelta ? sessionBest - lastSessionBest : null;

    final theme = Theme.of(context);
    final isPositive = (delta ?? 0) >= 0;
    final deltaPrefix = isPositive ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.liveWorkoutE1rmBestSession(
                _formatDisplayWeightValue(sessionBest, unitService),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (hasDelta)
            Text(
              l10n.liveWorkoutE1rmVsLastSession(
                '$deltaPrefix${_formatDisplayWeightValue(delta!.abs(), unitService)}',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isPositive
                    ? Colors.green.shade700
                    : theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
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
    final manager = Provider.of<WorkoutSessionManager>(context);

    // If the workout was just finished, the manager state is cleared.
    // We return a blank scaffold to avoid any errors during the Navigator transition.
    if (!manager.isActive && !_isLoading) {
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

    if (!_isLoading) {
      _syncControllersWithManager(manager);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: true,
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
      body: _isLoading
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
                                        leading: ReorderableDragStartListener(
                                          index: index,
                                          child: const Icon(Icons.drag_handle),
                                        ),
                                        title: InkWell(
                                          onTap: () =>
                                              Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ExerciseDetailScreen(
                                                exercise:
                                                    routineExercise.exercise,
                                              ),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4.0,
                                            ),
                                            child: Text(
                                              routineExercise.exercise
                                                  .getLocalizedName(context),
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
                                                        routineExercise.id!] !=
                                                    null &&
                                                manager.pauseTimes[
                                                        routineExercise.id!]! >
                                                    0)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 4.0,
                                                ),
                                                child: Text(
                                                  "${manager.pauseTimes[routineExercise.id!]}s",
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                    color: colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.timer_outlined,
                                              ),
                                              tooltip: l10n.editPauseTime,
                                              onPressed: () => editPauseTime(
                                                routineExercise,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                              ),
                                              tooltip: l10n.removeExercise,
                                              onPressed: () => _removeExercise(
                                                routineExercise,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (showE1rmSummary)
                                        _buildExerciseE1rmSummary(
                                          l10n,
                                          routineExercise,
                                          manager,
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
                                              final setLog =
                                                  manager.setLogs[templateId];

                                              if (setLog == null) {
                                                return const SizedBox.shrink();
                                              }
                                              int workingSetIndex = 0;
                                              for (int i = 0;
                                                  i <= setEntry.key;
                                                  i++) {
                                                final currentTemplateId =
                                                    routineExercise
                                                        .setTemplates[i].id!;
                                                if (manager
                                                        .setLogs[
                                                            currentTemplateId]
                                                        ?.setType !=
                                                    'warmup') {
                                                  workingSetIndex++;
                                                }
                                              }

                                              return _buildSetRow(
                                                workingSetIndex,
                                                setEntry.key,
                                                templateId,
                                                setLog,
                                                _lastPerformances[
                                                        routineExercise
                                                            .exercise.nameEn] ??
                                                    [],
                                                template, // <--- Pass template
                                              );
                                            }),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
    );
  }

  Widget? _buildRestBottomBar(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    WorkoutSessionManager manager,
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

  bool _isQualifyingSetForE1rm(
    SetLog setLog, {
    required bool requireCompleted,
  }) {
    final reps = setLog.reps;
    final weight = setLog.weightKg;
    final isWarmup = setLog.setType == 'warmup';
    final isCompleted = setLog.isCompleted == true;

    if (isWarmup) return false;
    if (requireCompleted && !isCompleted) return false;
    if (weight == null || weight <= 0) return false;
    if (reps == null || reps <= 0 || reps > 10) return false;

    return true;
  }

  double? _calculateBrzyckiE1rm(
    SetLog setLog, {
    required bool requireCompleted,
  }) {
    if (!_isQualifyingSetForE1rm(setLog, requireCompleted: requireCompleted)) {
      return null;
    }

    final reps = setLog.reps!;
    final weight = setLog.weightKg!;
    return weight * (36 / (37 - reps));
  }

  double? _getSessionBestE1rm(
    RoutineExercise routineExercise,
    WorkoutSessionManager manager,
  ) {
    double? best;

    for (final template in routineExercise.setTemplates) {
      final setLog = manager.setLogs[template.id];
      if (setLog == null) continue;

      final value = _calculateBrzyckiE1rm(setLog, requireCompleted: true);
      if (value == null) continue;

      if (best == null || value > best) {
        best = value;
      }
    }

    return best;
  }

  double? _getLastSessionBestE1rm(String exerciseName) {
    final lastSets = _lastPerformances[exerciseName] ?? const <SetLog>[];
    double? best;

    for (final setLog in lastSets) {
      final value = _calculateBrzyckiE1rm(setLog, requireCompleted: true);
      if (value == null) continue;

      if (best == null || value > best) {
        best = value;
      }
    }

    return best;
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
