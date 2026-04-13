// lib/services/workout_session_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../models/exercise.dart';
import 'package:vibration/vibration.dart';
import '../models/routine_exercise.dart';
import '../models/set_log.dart';
import '../models/workout_log.dart';
import '../data/workout_database_helper.dart';
import '../models/set_template.dart';
import 'local_notification_service.dart';

/// Manager responsible for the lifecycle and state of an active workout session.
///
/// Handles session timing, set tracking, rest periods, and data persistence
/// between the UI and the database.
class WorkoutSessionManager extends ChangeNotifier with WidgetsBindingObserver {
  static final WorkoutSessionManager _instance =
      WorkoutSessionManager._internal();
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  final WorkoutDatabaseHelper _workoutDb;
  final bool _registerLifecycleObserver;

  /// Returns the singleton instance of [WorkoutSessionManager].
  factory WorkoutSessionManager() => _instance;
  WorkoutSessionManager._internal({
    WorkoutDatabaseHelper? workoutDb,
    bool registerLifecycleObserver = true,
  })  : _workoutDb = workoutDb ?? WorkoutDatabaseHelper.instance,
        _registerLifecycleObserver = registerLifecycleObserver {
    if (_registerLifecycleObserver) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @visibleForTesting
  factory WorkoutSessionManager.forTesting({
    required WorkoutDatabaseHelper workoutDb,
  }) {
    return WorkoutSessionManager._internal(
      workoutDb: workoutDb,
      registerLifecycleObserver: false,
    );
  }

  WorkoutLog? _workoutLog;
  List<RoutineExercise> _exercises = [];
  final Map<int, SetLog> _setLogs = {};

  // Speichert die Pausenzeit pro RoutineExercise-ID
  final Map<int, int?> pauseTimes = {};

  Timer? _restTimer;
  int _remainingRestSeconds = 0;
  Timer? _restDoneBannerTimer;
  bool _showRestDone = false;

  Timer? _workoutDurationTimer;
  Duration _elapsedDuration = Duration.zero;

  /// The total weight lifted across all completed sets in the current session.
  double _totalVolume = 0.0;

  /// The total number of sets recorded in the current session.
  int _totalSets = 0;

  /// Returns the total volume lifted.
  double get totalVolume => _totalVolume;

  /// Returns the total number of sets.
  int get totalSets => _totalSets;

  /// The active [WorkoutLog] being recorded.
  WorkoutLog? get workoutLog => _workoutLog;

  /// The list of [RoutineExercise]s included in the current workout.
  List<RoutineExercise> get exercises => _exercises;

  /// The number of seconds remaining in the current rest period.
  int get remainingRestSeconds => _remainingRestSeconds;

  /// Whether the "Rest Done" notification banner should be displayed.
  bool get showRestDone => _showRestDone;

  /// The duration since the start of the workout.
  Duration get elapsedDuration => _elapsedDuration;

  /// A map of [SetLog]s indexed by their corresponding [SetTemplate] ID.
  Map<int, SetLog> get setLogs => _setLogs;

  /// Whether a workout session is currently in progress.
  bool get isActive => _workoutLog != null && _workoutLog!.endTime == null;
  bool get _isAppInForeground =>
      _appLifecycleState == AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;

    if (_remainingRestSeconds <= 0) return;

    if (_isAppInForeground) {
      LocalNotificationService.instance.cancelRestTimerNotification();
    } else {
      LocalNotificationService.instance.scheduleRestTimerDoneNotification(
        secondsFromNow: _remainingRestSeconds,
      );
    }
  }

  // ===========================================================================
  // INIT & RESTORE
  // ===========================================================================

  /// Starts a new workout session with the given [log] and [routineExercises].
  ///
  /// Initializes the session state, creates initial [SetLog]s, and starts the timer.
  Future<void> startWorkout(
    WorkoutLog log,
    List<RoutineExercise> routineExercises,
  ) async {
    _workoutLog = log;
    _exercises = List.from(routineExercises);
    _setLogs.clear();
    pauseTimes.clear();

    // Pause-Zeiten initialisieren
    for (var re in _exercises) {
      if (re.id != null) {
        pauseTimes[re.id!] = re.pauseSeconds;
      }
    }

    _createInitialSetLogs();
    _startWorkoutTimer();
    notifyListeners();
  }

  /// Versucht, ein laufendes Workout aus der Datenbank wiederherzustellen.
  /// Wird in main.dart aufgerufen.
  /// Attempts to restore an ongoing workout session from the database.
  ///
  /// This should be called during application initialization to resume an interrupted workout.
  Future<void> tryRestoreSession() async {
    final ongoingWorkout = await _workoutDb.getOngoingWorkout();

    if (ongoingWorkout != null) {
      // ignore: avoid_print
      print(
        "Laufendes Workout gefunden (ID: ${ongoingWorkout.id}). Stelle Session wieder her...",
      );
      await restoreWorkoutSession(ongoingWorkout);
    }
  }

  void _createInitialSetLogs() async {
    _totalVolume = 0;
    _totalSets = 0;

    for (var re in _exercises) {
      for (var template in re.setTemplates) {
        if (template.id == null) continue;

        final newSetLog = SetLog(
          workoutLogId: _workoutLog!.id!,
          exerciseName: re.exercise.nameEn,
          setType: template.setType,
          weightKg: null,
          reps: null,
          restTimeSeconds: re.pauseSeconds,
          isCompleted: false,
          rir: null,
        );

        final id = await _workoutDb.insertSetLog(newSetLog);

        _setLogs[template.id!] = newSetLog.copyWith(id: id);
        _totalSets++;
      }
    }
    notifyListeners();
  }

  Future<void> restoreWorkoutSession(WorkoutLog log) async {
    _workoutLog = log;

    final savedSets = await _workoutDb.getSetLogsForWorkout(log.id!);

    _setLogs.clear();
    _exercises.clear();
    pauseTimes.clear();
    _totalVolume = 0;
    _totalSets = 0;

    if (savedSets.isEmpty) {
      if (log.routineName != null) {
        final routine = await _workoutDb.getRoutineByName(log.routineName!);
        if (routine != null) {
          _exercises = routine.exercises;
          for (var re in _exercises) {
            if (re.id != null) pauseTimes[re.id!] = re.pauseSeconds;
          }
        }
      }
      _startWorkoutTimer();
      notifyListeners();
      return;
    }

    // Ensure sets are sorted by log_order
    final sortedSets = List<SetLog>.from(savedSets)
      ..sort((a, b) => (a.log_order ?? 0).compareTo(b.log_order ?? 0));

    // Group SetLogs sequentially into blocks whenever the exercise name changes
    String? currentExerciseName;
    List<SetLog> currentBlock = [];
    final List<List<SetLog>> blocks = [];

    for (final s in sortedSets) {
      if (s.exerciseName != currentExerciseName) {
        if (currentBlock.isNotEmpty) {
          blocks.add(currentBlock);
        }
        currentBlock = [s];
        currentExerciseName = s.exerciseName;
      } else {
        currentBlock.add(s);
      }
    }
    if (currentBlock.isNotEmpty) {
      blocks.add(currentBlock);
    }

    // Reconstruct RoutineExercises from the blocks
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block.isEmpty) continue;

      final firstSet = block.first;
      final exName = firstSet.exerciseName;
      final exercise = await _workoutDb.resolveExerciseForSetLog(firstSet) ??
          Exercise(
            nameDe: exName,
            nameEn: exName,
            descriptionDe: '',
            descriptionEn: '',
            categoryName: 'Unknown',
            primaryMuscles: const [],
            secondaryMuscles: const [],
          );

      final syntheticReId = DateTime.now().millisecondsSinceEpoch + i;
      final pauseSec = block.first.restTimeSeconds ?? 90;

      final List<SetTemplate> templates = [];
      for (int j = 0; j < block.length; j++) {
        final s = block[j];
        // Ensure unique template IDs
        final templateId =
            DateTime.now().millisecondsSinceEpoch + j * 1000 + i * 10000;

        templates.add(
          SetTemplate(
            id: templateId,
            setType: s.setType,
            targetWeight: s.weightKg,
            targetReps: s.reps?.toString(),
            targetRir: s.rir,
          ),
        );

        _setLogs[templateId] = s;
        _totalVolume += (s.weightKg ?? 0) * (s.reps ?? 0);
        _totalSets++;
      }

      final re = RoutineExercise(
        id: syntheticReId,
        exercise: exercise,
        setTemplates: templates,
        pauseSeconds: pauseSec,
      );

      _exercises.add(re);
      pauseTimes[syntheticReId] = pauseSec;
    }

    _startWorkoutTimer();
    notifyListeners();
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  /// Updates a specific set identified by [templateId] with new data.
  ///
  /// Handles fallback logic for empty inputs when a set is completed and
  /// triggers the rest timer if a set is newly marked as finished.
  Future<void> updateSet(
    int templateId, {
    double? weight,
    bool clearWeight = false,
    int? reps,
    bool clearReps = false,
    bool? isCompleted,
    String? setType,
    int? rir,
    bool clearRir = false,
    // FIX: Cardio Parameter
    double? distance,
    bool clearDistance = false,
    int? duration,
    bool clearDuration = false,
  }) async {
    if (!_setLogs.containsKey(templateId)) return;

    final oldLog = _setLogs[templateId]!;

    // Fallback logic for when a set is completed but empty
    bool newlyCompleted = isCompleted == true && oldLog.isCompleted != true;
    double? finalWeight = weight;
    int? finalReps = reps;
    int? finalRir = rir;

    if (newlyCompleted) {
      SetTemplate? template;
      for (var re in _exercises) {
        for (var t in re.setTemplates) {
          if (t.id == templateId) {
            template = t;
            break;
          }
        }
        if (template != null) break;
      }

      final currentWeight = weight ?? oldLog.weightKg;
      final currentReps = reps ?? oldLog.reps;

      if (template != null) {
        if (currentWeight == null && !clearWeight) {
          finalWeight = template.targetWeight ?? 0.0;
        }
        if (currentReps == null && !clearReps) {
          if (template.targetReps != null && template.targetReps!.isNotEmpty) {
            if (template.targetReps!.contains('-')) {
              final parts = template.targetReps!.split('-');
              final min = int.tryParse(parts[0]) ?? 0;
              final max = int.tryParse(parts[1]) ?? 0;
              finalReps = ((min + max) / 2).round();
            } else {
              finalReps = int.tryParse(template.targetReps!) ?? 0;
            }
          } else {
            finalReps = 0;
          }
        }
      }
    }

    // Volumens-Berechnung update (Nur für Krafttraining relevant)
    if (finalWeight != null || finalReps != null || clearWeight || clearReps) {
      final oldVol = (oldLog.weightKg ?? 0) * (oldLog.reps ?? 0);
      final newWeight =
          clearWeight ? 0.0 : (finalWeight ?? oldLog.weightKg ?? 0.0);
      final newReps = clearReps ? 0 : (finalReps ?? oldLog.reps ?? 0);
      _totalVolume = _totalVolume - oldVol + (newWeight * newReps);
    }

    final newLog = oldLog.copyWith(
      weightKg: finalWeight,
      clearWeight: clearWeight,
      reps: finalReps,
      clearReps: clearReps,
      isCompleted: isCompleted,
      setType: setType,
      rir: finalRir,
      clearRir: clearRir,
      distanceKm: distance, // <--- NEU
      clearDistance: clearDistance,
      durationSeconds: duration, // <--- NEU
      clearDuration: clearDuration,
    );

    _setLogs[templateId] = newLog;
    await _workoutDb.insertSetLog(newLog); // Update in DB

    // Timer Logik (unverändert)
    if (isCompleted == true && oldLog.isCompleted != true) {
      int? pauseTime;
      for (var re in _exercises) {
        if (re.setTemplates.any((t) => t.id == templateId)) {
          pauseTime = pauseTimes[re.id!];
          break;
        }
      }
      if (pauseTime != null && pauseTime > 0) {
        _startRestTimer(pauseTime);
      }
    }

    notifyListeners();
  }

  /// Adds a new set to the exercise identified by [routineExerciseId].
  ///
  /// Creates a new [SetTemplate] and [SetLog], copying the weight/reps from the last set if available.
  Future<void> addSetToExercise(int routineExerciseId) async {
    final reIndex = _exercises.indexWhere((e) => e.id == routineExerciseId);
    if (reIndex == -1) return;
    final re = _exercises[reIndex];

    final tempTemplateId = DateTime.now().millisecondsSinceEpoch;

    final newTemplate = SetTemplate(
      id: tempTemplateId,
      setType: 'normal',
      targetReps: null,
      targetWeight: null,
      targetRir: null,
    );

    // KORREKTUR: Manuelle Erstellung statt copyWith
    final updatedRe = RoutineExercise(
      id: re.id,
      exercise: re.exercise,
      setTemplates: [...re.setTemplates, newTemplate],
      pauseSeconds: re.pauseSeconds,
    );

    _exercises[reIndex] = updatedRe;

    final prevSet = _setLogs.values
        .where((s) => s.exerciseName == re.exercise.nameEn)
        .lastOrNull;

    final newSetLog = SetLog(
      workoutLogId: _workoutLog!.id!,
      exerciseName: re.exercise.nameEn,
      setType: 'normal',
      weightKg: prevSet?.weightKg,
      reps: prevSet?.reps,
      restTimeSeconds: re.pauseSeconds,
      isCompleted: false,
      log_order: _setLogs.length,
      rir: null,
    );

    final dbId = await _workoutDb.insertSetLog(newSetLog);
    _setLogs[tempTemplateId] = newSetLog.copyWith(id: dbId);
    _totalSets++;

    notifyListeners();
  }

  /// Removes a specific set identified by [templateId] from the current workout.
  Future<void> removeSet(int templateId) async {
    if (!_setLogs.containsKey(templateId)) return;

    final log = _setLogs[templateId]!;

    if (log.id != null) {
      await _workoutDb.deleteSetLogs([log.id!]);
    }

    _setLogs.remove(templateId);

    for (var i = 0; i < _exercises.length; i++) {
      final re = _exercises[i];
      final tIndex = re.setTemplates.indexWhere((t) => t.id == templateId);
      if (tIndex != -1) {
        final newTemplates = List<SetTemplate>.from(re.setTemplates)
          ..removeAt(tIndex);

        // KORREKTUR: Manuelle Erstellung statt copyWith
        _exercises[i] = RoutineExercise(
          id: re.id,
          exercise: re.exercise,
          setTemplates: newTemplates,
          pauseSeconds: re.pauseSeconds,
        );
        break;
      }
    }

    _totalVolume -= (log.weightKg ?? 0) * (log.reps ?? 0);
    _totalSets--;

    notifyListeners();
  }

  /// Adds a new [exercise] to the current workout session.
  ///
  /// Automatically generates initial set templates and logs based on the exercise category.
  Future<void> addExercise(Exercise exercise) async {
    final tempReId = DateTime.now().millisecondsSinceEpoch;

    // FIX: Cardio Check für Anzahl der Sets
    final isCardio = exercise.categoryName.toLowerCase() == 'cardio';
    final initialSetCount = isCardio ? 1 : 3;
    final initialReps =
        isCardio ? '' : '10'; // Auch hier: Cardio leer, Kraft 10

    final templates = List.generate(
      initialSetCount,
      (index) => SetTemplate(
        id: tempReId + index + 1,
        setType: 'normal',
        targetReps: initialReps,
        targetWeight: null,
      ),
    );

    final re = RoutineExercise(
      id: tempReId,
      exercise: exercise,
      setTemplates: templates,
      pauseSeconds: 90,
    );

    _exercises.add(re);
    pauseTimes[tempReId] = 90;

    for (var t in templates) {
      final newSetLog = SetLog(
        workoutLogId: _workoutLog!.id!,
        exerciseName: exercise.nameEn,
        setType: 'normal',
        weightKg: null,
        reps: null,
        restTimeSeconds: 90,
        isCompleted: false,
        // Optional: logOrder hier schon setzen, aber Manager macht das nicht explizit bisher
        log_order: _setLogs.length,
      );
      final dbId = await _workoutDb.insertSetLog(newSetLog);
      _setLogs[t.id!] = newSetLog.copyWith(id: dbId);
      _totalSets++;
    }

    notifyListeners();
  }

  /// Removes an exercise and all its associated sets from the session.
  Future<void> removeExercise(int routineExerciseId) async {
    final reIndex = _exercises.indexWhere((e) => e.id == routineExerciseId);
    if (reIndex == -1) return;

    final re = _exercises[reIndex];

    final idsToDelete = <int>[];
    for (var t in re.setTemplates) {
      if (_setLogs.containsKey(t.id)) {
        final log = _setLogs[t.id]!;
        if (log.id != null) idsToDelete.add(log.id!);
        _totalVolume -= (log.weightKg ?? 0) * (log.reps ?? 0);
        _totalSets--;
        _setLogs.remove(t.id);
      }
    }
    await _workoutDb.deleteSetLogs(idsToDelete);

    _exercises.removeAt(reIndex);
    pauseTimes.remove(routineExerciseId);

    notifyListeners();
  }

  /// Changes the order of an exercise in the session.
  void reorderExercise(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _exercises.removeAt(oldIndex);
    _exercises.insert(newIndex, item);

    _updateLogOrdersInDatabase();

    notifyListeners();
  }

  /// Recalculates and persists the log_order for all current sets.
  /// Called after reordering exercises to ensure the new order survives app restarts.
  void _updateLogOrdersInDatabase() async {
    int globalOrderCounter = 0;
    final List<SetLog> setsToUpdate = [];

    for (final routineExercise in _exercises) {
      for (final template in routineExercise.setTemplates) {
        final setLog = _setLogs[template.id];
        if (setLog != null) {
          final updatedLog = setLog.copyWith(log_order: globalOrderCounter);
          _setLogs[template.id!] = updatedLog;
          setsToUpdate.add(updatedLog);
          globalOrderCounter++;
        }
      }
    }

    if (setsToUpdate.isNotEmpty) {
      _workoutDb.updateSetLogs(setsToUpdate);
    }
  }

  // ===========================================================================
  // TIMER LOGIC
  // ===========================================================================

  /// Updates the rest duration for a specific exercise and its pending sets.
  void updatePauseTime(int routineExerciseId, int seconds) {
    pauseTimes[routineExerciseId] = seconds;
    _workoutDb.updatePauseTime(routineExerciseId, seconds);

    // Lokale SetLogs updaten
    final exercise = _exercises.firstWhere((e) => e.id == routineExerciseId);

    for (var t in exercise.setTemplates) {
      if (_setLogs.containsKey(t.id)) {
        final log = _setLogs[t.id]!;
        if (log.isCompleted != true) {
          final updatedLog = log.copyWith(restTimeSeconds: seconds);
          _setLogs[t.id!] = updatedLog;
          _workoutDb.insertSetLog(updatedLog);
        }
      }
    }

    notifyListeners();
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    _restDoneBannerTimer?.cancel();
    LocalNotificationService.instance.cancelRestTimerNotification();
    _showRestDone = false;
    _remainingRestSeconds = seconds;

    if (!_isAppInForeground) {
      LocalNotificationService.instance.scheduleRestTimerDoneNotification(
        secondsFromNow: seconds,
      );
    }

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingRestSeconds > 0) {
        _remainingRestSeconds--;
        if (_remainingRestSeconds == 0) {
          if (_isAppInForeground) {
            LocalNotificationService.instance.cancelRestTimerNotification();
            FlutterRingtonePlayer().playNotification();
            Vibration.vibrate(duration: 500);
          } else {
            LocalNotificationService.instance.showRestTimerDoneNotification();
          }
        }
        notifyListeners();
      } else {
        timer.cancel();
        _showRestDone = true;
        notifyListeners();
        _restDoneBannerTimer = Timer(const Duration(seconds: 10), () {
          _showRestDone = false;
          notifyListeners();
        });
      }
    });
    notifyListeners();
  }

  /// Cancels any active rest timer and hides the notification banner.
  void cancelRest() {
    _restTimer?.cancel();
    LocalNotificationService.instance.cancelRestTimerNotification();
    _remainingRestSeconds = 0;
    _showRestDone = false;
    notifyListeners();
  }

  void _startWorkoutTimer() {
    _workoutDurationTimer?.cancel();
    _elapsedDuration = Duration.zero;
    if (_workoutLog != null) {
      _elapsedDuration = DateTime.now().difference(_workoutLog!.startTime);
    }
    _workoutDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_workoutLog != null) {
        _elapsedDuration = DateTime.now().difference(_workoutLog!.startTime);
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  /// Finalizes the current workout session.
  ///
  /// Deletes incomplete sets, reorders completed sets for chronological consistency,
  /// marks the workout as finished in the database, and clears the manager's state.
  /// Optionally updates the workout [title] and [notes] before completing.
  Future<void> finishWorkout({String? title, String? notes}) async {
    _workoutDurationTimer?.cancel();
    _restTimer?.cancel();
    await LocalNotificationService.instance.cancelRestTimerNotification();

    if (_workoutLog != null) {
      final logId = _workoutLog!.id!;

      // 1. Unvollständige Sets identifizieren und löschen
      // Wir filtern lokal, welche IDs gelöscht werden müssen
      final incompleteSetIds = _setLogs.values
          .where((s) => s.isCompleted == false && s.id != null)
          .map((s) => s.id!)
          .toList();

      if (incompleteSetIds.isNotEmpty) {
        await _workoutDb.deleteSetLogs(incompleteSetIds);
      }

      // 2. Reihenfolge aktualisieren (Reordering Fix)
      // Wir iterieren durch die aktuelle Übungsliste (die vom User ggf. umsortiert wurde)
      // und vergeben neue logOrder-Indizes für die verbleibenden (completed) Sets.
      int globalOrderCounter = 0;
      final List<SetLog> setsToUpdate = [];

      for (final routineExercise in _exercises) {
        for (final template in routineExercise.setTemplates) {
          final setLog = _setLogs[template.id];
          // Nur completed Sets werden behalten und neu sortiert
          if (setLog != null && setLog.isCompleted == true) {
            setsToUpdate.add(setLog.copyWith(log_order: globalOrderCounter));
            globalOrderCounter++;
          }
        }
      }

      // Batch-Update der Reihenfolge in der DB
      if (setsToUpdate.isNotEmpty) {
        await _workoutDb.updateSetLogs(setsToUpdate);
      }

      // 3. Workout abschließen
      await _workoutDb.finishWorkout(logId, title: title, notes: notes);

      // Cleanup
      _workoutLog = null;
      _setLogs.clear();
      pauseTimes.clear();
      _exercises.clear();

      notifyListeners();
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _restDoneBannerTimer?.cancel();
    _workoutDurationTimer?.cancel();
    if (_registerLifecycleObserver) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }
}
