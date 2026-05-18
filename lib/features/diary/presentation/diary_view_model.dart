import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/repositories/diary_repository.dart';
import '../../supplements/domain/repositories/supplement_repository.dart';
import '../../workout/domain/repositories/workout_repository.dart';
import '../../../data/user_preferences_repository.dart';
import '../domain/calculate_daily_nutrition_use_case.dart';
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
  final UserPreferencesRepository _prefsRepo =
      UserPreferencesRepository.instance;
  final CalculateDailyNutritionUseCase _calculateUseCase =
      CalculateDailyNutritionUseCase();

  final DiaryHealthSyncCoordinator healthSyncCoordinator =
      DiaryHealthSyncCoordinator();
  final DiaryLoadCoordinator _loadCoordinator = DiaryLoadCoordinator();
  Future<void>? _activeDiaryLoadFuture;

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
    loadDataForDate(selectedDate);
  }

  @override
  void dispose() {
    healthSyncCoordinator.removeListener(notifyListeners);
    healthSyncCoordinator.dispose();
    selectedDateNotifier.dispose();
    super.dispose();
  }

  bool _isCurrentLoad(int generation, DateTime date) {
    return _loadCoordinator.isCurrent(generation, date);
  }

  Future<void> loadDataForDate(
    DateTime date, {
    bool forceStepsRefresh = false,
    bool queueIfInFlight = false,
  }) async {
    final diaryDate = normalizeDiaryDate(date);
    final activeFuture = _activeDiaryLoadFuture;
    if (activeFuture != null &&
        _loadCoordinator.coalesceIfInFlight(
          diaryDate,
          forceStepsRefresh: forceStepsRefresh,
          queueIfInFlight: queueIfInFlight,
        )) {
      return activeFuture;
    }

    _loadCoordinator.markInFlight(diaryDate);
    late final Future<void> loadFuture;
    loadFuture = _runDiaryLoadQueue(
      diaryDate,
      forceStepsRefresh: forceStepsRefresh,
    ).whenComplete(() {
      if (identical(_activeDiaryLoadFuture, loadFuture)) {
        _activeDiaryLoadFuture = null;
        _loadCoordinator.clearInFlight(diaryDate);
      }
    });
    _activeDiaryLoadFuture = loadFuture;
    return loadFuture;
  }

  Future<void> _runDiaryLoadQueue(
    DateTime diaryDate, {
    required bool forceStepsRefresh,
  }) async {
    var shouldForceStepsRefresh = forceStepsRefresh;
    do {
      _loadCoordinator.clearPendingReload();
      await _loadDataForDateOnce(
        diaryDate,
        forceStepsRefresh: shouldForceStepsRefresh,
      );
      shouldForceStepsRefresh = _loadCoordinator.pendingForceStepsRefresh;
    } while (_loadCoordinator.hasPendingReload &&
        selectedDate.isSameDate(diaryDate));
  }

  Future<void> _loadDataForDateOnce(
    DateTime diaryDate, {
    required bool forceStepsRefresh,
  }) async {
    final loadGeneration = _loadCoordinator.begin(diaryDate);

    selectedDateNotifier.value = diaryDate;
    isLoading = true;
    notifyListeners();

    try {
      final goals = await _nutritionRepo.getGoalsForDate(diaryDate);
      final targetSugar = await _prefsRepo.getTargetSugar() ?? 50;
      final targetCaffeine = await _prefsRepo.getTargetCaffeine() ?? 400;
      showSugarInOverview = await _prefsRepo.getShowSugarInDiaryOverview();

      final entries = await _nutritionRepo.getEntriesForDate(diaryDate);
      final rawFluidEntries =
          await _nutritionRepo.getFluidEntriesForDate(diaryDate);
      final startOfDay =
          DateTime(diaryDate.year, diaryDate.month, diaryDate.day);
      final endOfDay = DateTime(
          diaryDate.year, diaryDate.month, diaryDate.day, 23, 59, 59, 999);
      final workoutLogs =
          await _workoutRepo.getWorkoutLogsForDateRange(startOfDay, endOfDay);

      final barcodes = entries.map((e) => e.barcode).toSet().toList();
      final products = await _nutritionRepo.getProductsByBarcodes(barcodes);

      final supplementsForDate =
          await _supplementRepo.getSupplementsForDate(diaryDate);
      final allSupplements = await _supplementRepo.getAllSupplements();
      final todaysLogs =
          await _supplementRepo.getSupplementLogsForDate(diaryDate);

      if (!_isCurrentLoad(loadGeneration, diaryDate)) return;

      final state = _calculateUseCase.execute(
        goals: goals,
        targetSugar: targetSugar,
        targetCaffeine: targetCaffeine,
        foodEntries: entries,
        fluidEntries: rawFluidEntries,
        foodProducts: products,
        workoutLogs: workoutLogs,
        supplementsForDate: supplementsForDate,
        allSupplements: allSupplements,
        todaysSupplementLogs: todaysLogs,
      );

      dailyNutrition = state.summary;
      entriesByMeal = state.entriesByMeal;
      fluidEntries = rawFluidEntries;
      trackedSupplements = state.trackedSupplements;
      workoutSummary = state.workoutSummary;
      targetSteps = goals?.targetSteps ?? StepsSyncService.defaultStepsGoal;

      isLoading = false;
      notifyListeners();

      // Delegate all health data loading and background sync
      unawaited(healthSyncCoordinator.loadAndSyncHealthData(
        date: diaryDate,
        forceStepsRefresh: forceStepsRefresh,
        isCurrentLoad: (date) => _isCurrentLoad(loadGeneration, date),
      ));
    } catch (e, st) {
      debugPrint('Error loading diary data: $e\n$st');
      if (_isCurrentLoad(loadGeneration, diaryDate)) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> deleteFoodEntry(int id) async {
    await _nutritionRepo.deleteFoodEntry(id);
    loadDataForDate(selectedDate);
  }

  Future<void> deleteFluidEntry(int id) async {
    await _nutritionRepo.deleteFluidEntry(id);
    loadDataForDate(selectedDate);
  }

  Future<void> deleteFluidEntryByLinkedFoodId(int linkedFoodId) async {
    await _nutritionRepo.deleteFluidEntryByLinkedFoodId(linkedFoodId);
  }

  Future<void> updateFluidEntry(FluidEntry entry) async {
    await _nutritionRepo.updateFluidEntry(entry);
    loadDataForDate(selectedDate);
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
      loadDataForDate(newDate);
    }
  }

  void navigateDay(bool forward) {
    final newDay = selectedDate.dateOnly.add(Duration(days: forward ? 1 : -1));
    loadDataForDate(newDay);
  }
}
