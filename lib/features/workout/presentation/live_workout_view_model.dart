import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../../exercise_catalog/domain/models/exercise.dart';
import '../domain/models/routine_exercise.dart';
import '../domain/models/set_log.dart';
import '../domain/models/set_template.dart';
import '../domain/models/workout_log.dart';
import '../data/workout_repository.dart';
import '../domain/detect_personal_record_use_case.dart';
import '../domain/log_workout_set_use_case.dart';
import '../../../services/local_notification_service.dart';

class LiveWorkoutViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final WorkoutRepository _repository;
  final DetectPersonalRecordUseCase _detectPRUseCase;
  final LogWorkoutSetUseCase _logSetUseCase;
  final bool _registerLifecycleObserver;

  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  LiveWorkoutViewModel({
    WorkoutRepository? repository,
    DetectPersonalRecordUseCase? detectPRUseCase,
    LogWorkoutSetUseCase? logSetUseCase,
    bool registerLifecycleObserver = true,
  })  : _repository = repository ?? WorkoutRepository(),
        _detectPRUseCase = detectPRUseCase ?? DetectPersonalRecordUseCase(),
        _logSetUseCase = logSetUseCase ?? LogWorkoutSetUseCase(),
        _registerLifecycleObserver = registerLifecycleObserver {
    if (_registerLifecycleObserver) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @visibleForTesting
  factory LiveWorkoutViewModel.forTesting({
    required WorkoutRepository workoutDb,
  }) {
    return LiveWorkoutViewModel(
      repository: workoutDb,
      registerLifecycleObserver: false,
    );
  }

  WorkoutLog? _workoutLog;
  List<RoutineExercise> _exercises = [];
  final Map<int, SetLog> _setLogs = {};
  final Map<int, int?> pauseTimes = {};

  Timer? _restTimer;
  int _remainingRestSeconds = 0;
  Timer? _restDoneBannerTimer;
  bool _showRestDone = false;

  Timer? _workoutDurationTimer;
  Duration _elapsedDuration = Duration.zero;

  double _totalVolume = 0.0;
  int _totalSets = 0;

  final Map<String, Map<String, double>> _exerciseBests = {};
  
  // UI State moved from view
  final Map<int, TextEditingController> weightControllers = {};
  final Map<int, TextEditingController> repsControllers = {};
  final Map<int, TextEditingController> rirControllers = {};
  final Map<String, List<SetLog>> lastPerformances = {};
  
  bool isLoading = true;

  final StreamController<PRAlert> _prEventsController = StreamController<PRAlert>.broadcast();
  Stream<PRAlert> get prEvents => _prEventsController.stream;

  double get totalVolume => _totalVolume;
  int get totalSets => _totalSets;
  WorkoutLog? get workoutLog => _workoutLog;
  List<RoutineExercise> get exercises => _exercises;
  int get remainingRestSeconds => _remainingRestSeconds;
  bool get showRestDone => _showRestDone;
  Duration get elapsedDuration => _elapsedDuration;
  Map<int, SetLog> get setLogs => _setLogs;
  bool get isActive => _workoutLog != null && _workoutLog!.endTime == null;

  bool get _isAppInForeground => _appLifecycleState == AppLifecycleState.resumed;

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

  Future<void> tryRestoreSession() async {
    final ongoingWorkout = await _repository.getOngoingWorkout();
    if (ongoingWorkout != null) {
      await restoreWorkoutSession(ongoingWorkout);
    }
  }

  Future<void> startWorkout(WorkoutLog log, List<RoutineExercise> routineExercises) async {
    _workoutLog = log;
    _exercises = List.from(routineExercises);
    _setLogs.clear();
    pauseTimes.clear();

    for (var re in _exercises) {
      if (re.id != null) {
        pauseTimes[re.id!] = re.pauseSeconds;
      }
    }

    _createInitialSetLogs();
    _startWorkoutTimer();
    notifyListeners();
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

        final id = await _repository.insertSetLog(newSetLog);
        _setLogs[template.id!] = newSetLog.copyWith(id: id);
        _totalSets++;
      }
    }
    notifyListeners();
  }

  Future<void> restoreWorkoutSession(WorkoutLog log) async {
    _workoutLog = log;
    final savedSets = await _repository.getSetLogsForWorkout(log.id!);

    _setLogs.clear();
    _exercises.clear();
    pauseTimes.clear();
    _totalVolume = 0;
    _totalSets = 0;

    if (savedSets.isEmpty) {
      if (log.routineName != null) {
        final routine = await _repository.getRoutineByName(log.routineName!);
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

    final sortedSets = List<SetLog>.from(savedSets)
      ..sort((a, b) => (a.logOrder ?? 0).compareTo(b.logOrder ?? 0));

    String? currentExerciseName;
    List<SetLog> currentBlock = [];
    final List<List<SetLog>> blocks = [];

    for (final s in sortedSets) {
      if (s.exerciseName != currentExerciseName) {
        if (currentBlock.isNotEmpty) blocks.add(currentBlock);
        currentBlock = [s];
        currentExerciseName = s.exerciseName;
      } else {
        currentBlock.add(s);
      }
    }
    if (currentBlock.isNotEmpty) blocks.add(currentBlock);

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block.isEmpty) continue;

      final firstSet = block.first;
      final exName = firstSet.exerciseName;
      final exercise = await _repository.resolveExerciseForSetLog(firstSet) ??
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
        final templateId = DateTime.now().millisecondsSinceEpoch + j * 1000 + i * 10000;

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

  Future<void> loadInitialData(WorkoutLog initialLog, List<RoutineExercise>? initialExercises) async {
    isLoading = true;
    notifyListeners();
    
    List<RoutineExercise> exercisesToInit = [];
    if (!isActive) {
      exercisesToInit = initialExercises ?? [];
      await startWorkout(initialLog, exercisesToInit);
    } else {
      exercisesToInit = _exercises;
    }

    for (var re in exercisesToInit) {
      final lastSets = await _repository.getLastSetsForExercise(re.exercise.nameEn);
      lastPerformances[re.exercise.nameEn] = lastSets;
    }

    syncControllers();
    isLoading = false;
    notifyListeners();
  }

  void syncControllers() {
    _setLogs.forEach((templateId, setLog) {
      final exercise = _exercises.firstWhere(
        (re) => re.setTemplates.any((t) => t.id == templateId),
        orElse: () => _exercises.first,
      );
      final isCardio = exercise.exercise.categoryName.toLowerCase() == 'cardio';

      if (!weightControllers.containsKey(templateId)) {
        String initText;
        if (isCardio) {
          initText = setLog.distanceKm?.toStringAsFixed(1).replaceAll('.0', '') ?? '';
        } else {
          initText = setLog.weightKg == null
              ? ''
              : setLog.weightKg!.toStringAsFixed(2).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
        }
        weightControllers[templateId] = TextEditingController(text: initText);
      }

      if (!repsControllers.containsKey(templateId)) {
        String initText;
        if (isCardio) {
          initText = setLog.durationSeconds != null ? (setLog.durationSeconds! ~/ 60).toString() : '';
        } else {
          initText = setLog.reps?.toString() ?? '';
        }
        repsControllers[templateId] = TextEditingController(text: initText);
      }

      if (!rirControllers.containsKey(templateId)) {
        rirControllers[templateId] = TextEditingController(text: setLog.rir?.toString() ?? '');
      }
    });
  }

  void disposeControllers() {
    for (var c in weightControllers.values) { c.dispose(); }
    for (var c in repsControllers.values) { c.dispose(); }
    for (var c in rirControllers.values) { c.dispose(); }
    weightControllers.clear();
    repsControllers.clear();
    rirControllers.clear();
  }

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
    double? distance,
    bool clearDistance = false,
    int? duration,
    bool clearDuration = false,
  }) async {
    if (!_setLogs.containsKey(templateId)) return;

    final oldLog = _setLogs[templateId]!;
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

    final result = _logSetUseCase.execute(
      oldLog: oldLog,
      template: template,
      weight: weight,
      clearWeight: clearWeight,
      reps: reps,
      clearReps: clearReps,
      isCompleted: isCompleted,
      setType: setType,
      rir: rir,
      clearRir: clearRir,
      distance: distance,
      clearDistance: clearDistance,
      duration: duration,
      clearDuration: clearDuration,
    );

    _setLogs[templateId] = result.updatedSet;
    _totalVolume += result.volumeDelta;

    if (isCompleted == true && oldLog.isCompleted != true && result.updatedSet.setType != 'warmup') {
      await _checkAndApplyPRs(result.updatedSet, templateId);
    }

    await _repository.updateSetLogs([_setLogs[templateId]!]);

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

  Future<void> _checkAndApplyPRs(SetLog setLog, int templateId) async {
    final exName = setLog.exerciseName;

    if (!_exerciseBests.containsKey(exName)) {
      final exercise = await _repository.getExerciseByName(exName);
      final altName = exercise?.nameEn != exName ? exercise?.nameEn : null;
      final exerciseUuid = exercise?.id != null
          ? await _repository.getExerciseUuidByLocalId(exercise!.id!)
          : null;

      final bests = await _repository.getExerciseBests(
        exName,
        altName: altName,
        exerciseUuid: exerciseUuid,
      );
      _exerciseBests[exName] = bests;
    }

    final prResult = _detectPRUseCase.execute(
      currentSet: setLog,
      historicalBests: _exerciseBests[exName]!,
    );

    _setLogs[templateId] = prResult.updatedSetLog;

    if (prResult.alerts.isNotEmpty) {
      HapticFeedback.heavyImpact();
      for (final alert in prResult.alerts) {
        _prEventsController.add(alert);
      }
    }
  }

  Future<void> addSetToExercise(int routineExerciseId) async {
    final reIndex = _exercises.indexWhere((e) => e.id == routineExerciseId);
    if (reIndex == -1) return;
    final re = _exercises[reIndex];

    final existingTemplateIds = _allTemplateIds()..addAll(_setLogs.keys);
    final tempTemplateId = _nextSyntheticId(existingTemplateIds);

    final newTemplate = SetTemplate(
      id: tempTemplateId,
      setType: 'normal',
      targetReps: null,
      targetWeight: null,
      targetRir: null,
    );

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
      logOrder: _setLogs.length,
      rir: null,
    );

    final dbId = await _repository.insertSetLog(newSetLog);
    _setLogs[tempTemplateId] = newSetLog.copyWith(id: dbId);
    _totalSets++;

    syncControllers();
    notifyListeners();
  }

  Future<void> removeSet(int templateId) async {
    if (!_setLogs.containsKey(templateId)) return;
    final log = _setLogs[templateId]!;
    if (log.id != null) {
      await _repository.deleteSetLogs([log.id!]);
    }
    _setLogs.remove(templateId);

    for (var i = 0; i < _exercises.length; i++) {
      final re = _exercises[i];
      final tIndex = re.setTemplates.indexWhere((t) => t.id == templateId);
      if (tIndex != -1) {
        final newTemplates = List<SetTemplate>.from(re.setTemplates)..removeAt(tIndex);
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
    
    weightControllers[templateId]?.dispose();
    repsControllers[templateId]?.dispose();
    rirControllers[templateId]?.dispose();
    weightControllers.remove(templateId);
    repsControllers.remove(templateId);
    rirControllers.remove(templateId);

    notifyListeners();
  }

  Future<void> addExercise(Exercise exercise) async {
    final tempReId = _nextSyntheticId(_allRoutineExerciseIds());
    final isCardio = exercise.categoryName.toLowerCase() == 'cardio';
    final initialSetCount = isCardio ? 1 : 3;
    final initialReps = isCardio ? '' : '10';

    final existingTemplateIds = _allTemplateIds()..addAll(_setLogs.keys);
    final templates = <SetTemplate>[];
    for (var index = 0; index < initialSetCount; index++) {
      final templateId = _nextSyntheticId(existingTemplateIds, seed: tempReId + index + 1);
      existingTemplateIds.add(templateId);
      templates.add(SetTemplate(id: templateId, setType: 'normal', targetReps: initialReps, targetWeight: null));
    }

    final re = RoutineExercise(id: tempReId, exercise: exercise, setTemplates: templates, pauseSeconds: 90);
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
        logOrder: _setLogs.length,
      );
      final dbId = await _repository.insertSetLog(newSetLog);
      _setLogs[t.id!] = newSetLog.copyWith(id: dbId);
      _totalSets++;
    }

    syncControllers();
    notifyListeners();
  }

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
        
        weightControllers[t.id]?.dispose();
        repsControllers[t.id]?.dispose();
        rirControllers[t.id]?.dispose();
        weightControllers.remove(t.id);
        repsControllers.remove(t.id);
        rirControllers.remove(t.id);
      }
    }
    await _repository.deleteSetLogs(idsToDelete);
    _exercises.removeAt(reIndex);
    pauseTimes.remove(routineExerciseId);

    notifyListeners();
  }

  void reorderExercise(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _exercises.removeAt(oldIndex);
    _exercises.insert(newIndex, item);
    _updateLogOrdersInDatabase();
    notifyListeners();
  }

  void _updateLogOrdersInDatabase() async {
    int globalOrderCounter = 0;
    final List<SetLog> setsToUpdate = [];
    for (final routineExercise in _exercises) {
      for (final template in routineExercise.setTemplates) {
        final setLog = _setLogs[template.id];
        if (setLog != null) {
          final updatedLog = setLog.copyWith(logOrder: globalOrderCounter);
          _setLogs[template.id!] = updatedLog;
          setsToUpdate.add(updatedLog);
          globalOrderCounter++;
        }
      }
    }
    if (setsToUpdate.isNotEmpty) _repository.updateSetLogs(setsToUpdate);
  }

  void updatePauseTime(int routineExerciseId, int seconds) {
    pauseTimes[routineExerciseId] = seconds;
    _repository.updatePauseTime(routineExerciseId, seconds);

    final exercise = _exercises.firstWhere((e) => e.id == routineExerciseId);
    for (var t in exercise.setTemplates) {
      if (_setLogs.containsKey(t.id)) {
        final log = _setLogs[t.id]!;
        if (log.isCompleted != true) {
          final updatedLog = log.copyWith(restTimeSeconds: seconds);
          _setLogs[t.id!] = updatedLog;
          _repository.updateSetLogs([updatedLog]);
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
      LocalNotificationService.instance.scheduleRestTimerDoneNotification(secondsFromNow: seconds);
    }

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingRestSeconds > 0) {
        _remainingRestSeconds--;
        if (_remainingRestSeconds == 0) {
          if (_isAppInForeground) {
            LocalNotificationService.instance.cancelRestTimerNotification();
            unawaited(SystemSound.play(SystemSoundType.alert));
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
    if (_workoutLog != null) _elapsedDuration = DateTime.now().difference(_workoutLog!.startTime);
    _workoutDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_workoutLog != null) {
        _elapsedDuration = DateTime.now().difference(_workoutLog!.startTime);
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> finishWorkout({String? title, String? notes}) async {
    _workoutDurationTimer?.cancel();
    _restTimer?.cancel();
    await LocalNotificationService.instance.cancelRestTimerNotification();

    if (_workoutLog != null) {
      final logId = _workoutLog!.id!;
      final incompleteSetIds = _setLogs.values
          .where((s) => s.isCompleted == false && s.id != null)
          .map((s) => s.id!)
          .toList();

      if (incompleteSetIds.isNotEmpty) await _repository.deleteSetLogs(incompleteSetIds);

      int globalOrderCounter = 0;
      final List<SetLog> setsToUpdate = [];
      for (final routineExercise in _exercises) {
        for (final template in routineExercise.setTemplates) {
          final setLog = _setLogs[template.id];
          if (setLog != null && setLog.isCompleted == true) {
            setsToUpdate.add(setLog.copyWith(logOrder: globalOrderCounter));
            globalOrderCounter++;
          }
        }
      }
      if (setsToUpdate.isNotEmpty) await _repository.updateSetLogs(setsToUpdate);

      await _repository.finishWorkout(logId, title: title, notes: notes);

      _workoutLog = null;
      _setLogs.clear();
      pauseTimes.clear();
      _exercises.clear();
      disposeControllers();

      notifyListeners();
    }
  }

  Future<void> clearLocalSessionState() async {
    _workoutDurationTimer?.cancel();
    _restTimer?.cancel();
    _restDoneBannerTimer?.cancel();
    await LocalNotificationService.instance.cancelRestTimerNotification();

    _workoutLog = null;
    _exercises.clear();
    _setLogs.clear();
    _exerciseBests.clear();
    pauseTimes.clear();
    _remainingRestSeconds = 0;
    _showRestDone = false;
    _elapsedDuration = Duration.zero;
    _totalVolume = 0.0;
    _totalSets = 0;
    disposeControllers();
    notifyListeners();
  }

  Set<int> _allTemplateIds() {
    final ids = <int>{};
    for (final exercise in _exercises) {
      for (final template in exercise.setTemplates) {
        if (template.id != null) ids.add(template.id!);
      }
    }
    return ids;
  }

  Set<int> _allRoutineExerciseIds() {
    final ids = <int>{...pauseTimes.keys};
    for (final exercise in _exercises) {
      if (exercise.id != null) ids.add(exercise.id!);
    }
    return ids;
  }

  int _nextSyntheticId(Set<int> existingIds, {int? seed}) {
    var candidate = seed ?? DateTime.now().microsecondsSinceEpoch;
    while (existingIds.contains(candidate)) {
      candidate += 1;
    }
    return candidate;
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _restDoneBannerTimer?.cancel();
    _workoutDurationTimer?.cancel();
    _prEventsController.close();
    disposeControllers();
    if (_registerLifecycleObserver) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
