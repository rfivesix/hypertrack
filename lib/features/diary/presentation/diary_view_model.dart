import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/repositories/diary_repository.dart';
import '../../supplements/domain/repositories/supplement_repository.dart';
import '../../workout/domain/repositories/workout_repository.dart';
import '../../../core/infrastructure/user_preferences_repository.dart';
import '../domain/calculate_daily_nutrition_use_case.dart';
import '../domain/models/daily_goal.dart';
import '../domain/models/daily_nutrition.dart';
import '../domain/models/fluid_entry.dart';
import '../domain/models/tracked_food_item.dart';
import '../../supplements/domain/models/tracked_supplement.dart';
import '../domain/models/food_entry.dart';
import '../../supplements/domain/models/supplement.dart';
import '../../supplements/domain/models/supplement_log.dart';
import '../../../util/date_util.dart';
import '../../../services/health/steps_sync_service.dart';
import '../../sleep/data/sleep_day_repository.dart';
import '../../pulse/domain/pulse_models.dart';
import 'diary_health_sync_coordinator.dart';
import '../../workout/domain/models/workout_log.dart';

DateTime normalizeDiaryDate(DateTime date) => date.dateOnly;
DateTime resolveDiaryInitialDate({DateTime? initialDate, DateTime? now}) {
  return (initialDate ?? now ?? DateTime.now()).dateOnly;
}

class DiaryLoadCoordinator {
  int _generation = 0;
  DateTime? _activeDate;
  DateTime? _inFlightDate;
  bool _hasPendingReload = false;
  bool _pendingForceStepsRefresh = false;

  int begin(DateTime date) {
    _activeDate = normalizeDiaryDate(date);
    return ++_generation;
  }

  bool isCurrent(int generation, DateTime date) {
    return generation == _generation &&
        (_activeDate?.isSameDate(normalizeDiaryDate(date)) ?? false);
  }

  bool coalesceIfInFlight(
    DateTime date, {
    required bool forceStepsRefresh,
    required bool queueIfInFlight,
  }) {
    final diaryDate = normalizeDiaryDate(date);
    if (!(_inFlightDate?.isSameDate(diaryDate) ?? false)) {
      return false;
    }
    if (forceStepsRefresh || queueIfInFlight) {
      _hasPendingReload = true;
      _pendingForceStepsRefresh |= forceStepsRefresh;
    }
    return true;
  }

  void markInFlight(DateTime date) {
    _inFlightDate = normalizeDiaryDate(date);
  }

  void clearInFlight(DateTime date) {
    if (_inFlightDate?.isSameDate(normalizeDiaryDate(date)) ?? false) {
      _inFlightDate = null;
    }
  }

  void clearPendingReload() {
    _hasPendingReload = false;
    _pendingForceStepsRefresh = false;
  }

  bool get hasPendingReload => _hasPendingReload;
  bool get pendingForceStepsRefresh => _pendingForceStepsRefresh;
}

class DiaryViewModel extends ChangeNotifier {
  final IDiaryRepository _nutritionRepo;
  final SupplementRepository _supplementRepo;
  final IWorkoutRepository _workoutRepo;

  @visibleForTesting
  SupplementRepository get supplementRepo => _supplementRepo;
  final UserPreferencesRepository _prefsRepo =
      UserPreferencesRepository.instance;
  final CalculateDailyNutritionUseCase _calculateUseCase =
      CalculateDailyNutritionUseCase();

  final DiaryHealthSyncCoordinator healthSyncCoordinator =
      DiaryHealthSyncCoordinator();

  StreamSubscription<DailyGoal?>? _goalsSubscription;
  StreamSubscription<List<FoodEntry>>? _entriesSubscription;
  StreamSubscription<List<FluidEntry>>? _fluidsSubscription;
  StreamSubscription<List<Supplement>>? _supplementsSubscription;
  StreamSubscription<List<SupplementLog>>? _supplementLogsSubscription;
  StreamSubscription<List<WorkoutLog>>? _workoutsSubscription;

  DailyGoal? _activeGoals;
  List<FoodEntry> _activeEntries = [];
  List<FluidEntry> _activeFluids = [];
  List<Supplement> _activeSupplements = [];
  List<SupplementLog> _activeSupplementLogs = [];
  List<WorkoutLog> _activeWorkouts = [];

  bool isLoading = true;
  DailyNutrition? dailyNutrition;
  Map<String, List<TrackedFoodItem>> entriesByMeal = {};
  List<FluidEntry> fluidEntries = [];
  List<TrackedSupplement> trackedSupplements = [];
  Map<String, dynamic>? workoutSummary;
  bool showSugarInOverview = false;

  int targetSteps = StepsSyncService.defaultStepsGoal;

  // Delegated Health Sync Properties
  int? get stepsForSelectedDay => healthSyncCoordinator.stepsForSelectedDay;
  bool get isStepsWidgetLoading => healthSyncCoordinator.isStepsWidgetLoading;
  bool get stepsTrackingEnabled => healthSyncCoordinator.stepsTrackingEnabled;

  SleepDayOverviewData? get sleepOverview =>
      healthSyncCoordinator.sleepOverview;
  bool get isSleepWidgetLoading => healthSyncCoordinator.isSleepWidgetLoading;
  bool get sleepTrackingEnabled => healthSyncCoordinator.sleepTrackingEnabled;

  PulseAnalysisSummary? get pulseSummary => healthSyncCoordinator.pulseSummary;
  bool get isPulseWidgetLoading => healthSyncCoordinator.isPulseWidgetLoading;
  bool get pulseTrackingEnabled => healthSyncCoordinator.pulseTrackingEnabled;

  final ValueNotifier<DateTime> selectedDateNotifier;
  DateTime get selectedDate => selectedDateNotifier.value;

  DiaryViewModel({
    required IDiaryRepository nutritionRepo,
    required SupplementRepository supplementRepo,
    required IWorkoutRepository workoutRepo,
    DateTime? initialDate,
  })  : _nutritionRepo = nutritionRepo,
        _supplementRepo = supplementRepo,
        _workoutRepo = workoutRepo,
        selectedDateNotifier =
            ValueNotifier((initialDate ?? DateTime.now()).dateOnly) {
    healthSyncCoordinator.addListener(notifyListeners);
    setSelectedDate(selectedDate);
  }

  @override
  void dispose() {
    _goalsSubscription?.cancel();
    _entriesSubscription?.cancel();
    _fluidsSubscription?.cancel();
    _supplementsSubscription?.cancel();
    _supplementLogsSubscription?.cancel();
    _workoutsSubscription?.cancel();
    healthSyncCoordinator.removeListener(notifyListeners);
    healthSyncCoordinator.dispose();
    selectedDateNotifier.dispose();
    super.dispose();
  }



  void setSelectedDate(DateTime date) {
    final diaryDate = normalizeDiaryDate(date);
    selectedDateNotifier.value = diaryDate;

    // Cancel existing subscriptions
    _goalsSubscription?.cancel();
    _entriesSubscription?.cancel();
    _fluidsSubscription?.cancel();
    _supplementsSubscription?.cancel();
    _supplementLogsSubscription?.cancel();
    _workoutsSubscription?.cancel();

    isLoading = true;
    notifyListeners();

    // Re-establish reactive stream listeners for the new selected date
    _goalsSubscription = _nutritionRepo.watchGoalsForDate(diaryDate).listen((goals) {
      _activeGoals = goals;
      _updateCalculatedState();
    });

    _entriesSubscription = _nutritionRepo.watchEntriesForDate(diaryDate).listen((entries) {
      _activeEntries = entries;
      _updateCalculatedState();
    });

    _fluidsSubscription = _nutritionRepo.watchFluidEntriesForDate(diaryDate).listen((fluids) {
      _activeFluids = fluids;
      _updateCalculatedState();
    });

    _supplementsSubscription = _supplementRepo.watchSupplementsForDate(diaryDate).listen((supps) {
      _activeSupplements = supps;
      _updateCalculatedState();
    });

    _supplementLogsSubscription = _supplementRepo.watchSupplementLogsForDate(diaryDate).listen((logs) {
      _activeSupplementLogs = logs;
      _updateCalculatedState();
    });

    _workoutsSubscription = _workoutRepo
        .watchWorkoutLogsForDateRange(diaryDate, diaryDate)
        .listen((workouts) {
      _activeWorkouts = workouts;
      _updateCalculatedState();
    });

    // Delegate all health data loading and background sync
    unawaited(healthSyncCoordinator.loadAndSyncHealthData(
      date: diaryDate,
      forceStepsRefresh: false,
      isCurrentLoad: (d) => d.isSameDate(diaryDate),
    ));
  }

  Future<void> syncHealthData({bool forceStepsRefresh = false}) async {
    await healthSyncCoordinator.loadAndSyncHealthData(
      date: selectedDate,
      forceStepsRefresh: forceStepsRefresh,
      isCurrentLoad: (d) => d.isSameDate(selectedDate),
    );
  }

  @Deprecated('Use setSelectedDate or syncHealthData instead')
  Future<void> loadDataForDate(
    DateTime date, {
    bool forceStepsRefresh = false,
    bool queueIfInFlight = false,
  }) async {
    setSelectedDate(date);
    if (forceStepsRefresh) {
      await syncHealthData(forceStepsRefresh: true);
    }
  }

  void _updateCalculatedState() async {
    try {
      final targetSugar = await _prefsRepo.getTargetSugar() ?? 50;
      final targetCaffeine = await _prefsRepo.getTargetCaffeine() ?? 400;
      showSugarInOverview = await _prefsRepo.getShowSugarInDiaryOverview();

      final barcodes = _activeEntries.map((e) => e.barcode).toSet().toList();
      final products = await _nutritionRepo.getProductsByBarcodes(barcodes);

      final allSupplements = await _supplementRepo.getAllSupplements();

      final state = _calculateUseCase.execute(
        goals: _activeGoals,
        targetSugar: targetSugar,
        targetCaffeine: targetCaffeine,
        foodEntries: _activeEntries,
        fluidEntries: _activeFluids,
        foodProducts: products,
        workoutLogs: _activeWorkouts,
        supplementsForDate: _activeSupplements,
        allSupplements: allSupplements,
        todaysSupplementLogs: _activeSupplementLogs,
      );

      dailyNutrition = state.summary;
      entriesByMeal = state.entriesByMeal;
      fluidEntries = _activeFluids;
      trackedSupplements = state.trackedSupplements;
      workoutSummary = state.workoutSummary;
      targetSteps = _activeGoals?.targetSteps ?? StepsSyncService.defaultStepsGoal;

      isLoading = false;
      notifyListeners();
    } catch (e, st) {
      debugPrint('Error calculating reactive diary state: $e\n$st');
    }
  }

  Future<void> deleteFoodEntry(int id) async {
    await _nutritionRepo.deleteFoodEntry(id);
  }

  Future<void> deleteFluidEntry(int id) async {
    await _nutritionRepo.deleteFluidEntry(id);
  }

  Future<void> deleteFluidEntryByLinkedFoodId(int linkedFoodId) async {
    await _nutritionRepo.deleteFluidEntryByLinkedFoodId(linkedFoodId);
  }

  Future<void> updateFluidEntry(FluidEntry entry) async {
    await _nutritionRepo.updateFluidEntry(entry);
  }

  Future<void> updateFoodEntry(FoodEntry entry) async {
    await _nutritionRepo.updateFoodEntry(entry);
  }

  Future<int> insertFluidEntry(FluidEntry entry) async {
    return await _nutritionRepo.insertFluidEntry(entry);
  }

  Future<int> insertFoodEntry(FoodEntry entry) async {
    return await _nutritionRepo.insertFoodEntry(entry);
  }

  Future<void> logCaffeineDose(
    double doseMg,
    DateTime timestamp, {
    int? foodEntryId,
    int? fluidEntryId,
  }) async {
    if (doseMg <= 0) return;

    final supplements = await _supplementRepo.getAllSupplements();
    Supplement? caffeineSupplement;
    try {
      caffeineSupplement = supplements.firstWhere((s) => s.code == 'caffeine');
    } catch (e) {
      return;
    }

    if (caffeineSupplement.id == null) return;

    await _supplementRepo.insertSupplementLog(
      SupplementLog(
        supplementId: caffeineSupplement.id!,
        dose: doseMg,
        unit: 'mg',
        timestamp: timestamp,
      ),
    );
  }

  void pickDate(DateTime newDate) {
    if (!newDate.isSameDate(selectedDate)) {
      setSelectedDate(newDate);
    }
  }

  void navigateDay(bool forward) {
    final newDay = selectedDate.dateOnly.add(Duration(days: forward ? 1 : -1));
    setSelectedDate(newDay);
  }
}
