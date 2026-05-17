import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/nutrition_repository.dart';
import '../data/user_preferences_repository.dart';
import '../domain/use_cases/calculate_daily_nutrition_use_case.dart';
import '../models/daily_nutrition.dart';
import '../models/fluid_entry.dart';
import '../models/tracked_food_item.dart';
import '../models/tracked_supplement.dart';
import '../models/food_entry.dart';
import '../models/supplement.dart';
import '../models/supplement_log.dart';
import '../util/date_util.dart';

import '../services/health/steps_sync_service.dart';
import '../data/database_helper.dart'; // For getDailyStepsTotal
import '../features/sleep/data/sleep_day_repository.dart';
import '../features/sleep/platform/sleep_sync_service.dart';

import '../features/pulse/data/pulse_repository.dart';
import '../features/pulse/domain/pulse_models.dart';
import '../features/pulse/application/pulse_tracking_service.dart';

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
  final NutritionRepository _nutritionRepo = NutritionRepository.instance;
  final UserPreferencesRepository _prefsRepo = UserPreferencesRepository.instance;
  final CalculateDailyNutritionUseCase _calculateUseCase = CalculateDailyNutritionUseCase();

  static const Duration _stepsSyncInterval = Duration(hours: 6);
  static const Duration _sleepSyncInterval = Duration(hours: 6);

  final StepsSyncService _stepsSyncService = StepsSyncService();
  final SleepSyncService _sleepSyncService = SleepSyncService();
  final SleepDayDataRepository _sleepRepository = SleepDayRepository();
  final PulseTrackingSettingsService _pulseSyncService = PulseTrackingService();
  final PulseAnalysisRepository _pulseRepository = HealthPulseAnalysisRepository();

  final DiaryLoadCoordinator _loadCoordinator = DiaryLoadCoordinator();
  Future<void>? _activeDiaryLoadFuture;

  bool isLoading = true;
  DailyNutrition? dailyNutrition;
  Map<String, List<TrackedFoodItem>> entriesByMeal = {};
  List<FluidEntry> fluidEntries = [];
  List<TrackedSupplement> trackedSupplements = [];
  Map<String, dynamic>? workoutSummary;
  bool showSugarInOverview = false;

  int? stepsForSelectedDay;
  bool isStepsWidgetLoading = false;
  bool stepsTrackingEnabled = true;
  int targetSteps = StepsSyncService.defaultStepsGoal;

  SleepDayOverviewData? sleepOverview;
  bool isSleepWidgetLoading = false;
  bool sleepTrackingEnabled = false;

  PulseAnalysisSummary? pulseSummary;
  bool isPulseWidgetLoading = false;
  bool pulseTrackingEnabled = false;

  final ValueNotifier<DateTime> selectedDateNotifier;
  DateTime get selectedDate => selectedDateNotifier.value;

  DiaryViewModel({DateTime? initialDate})
      : selectedDateNotifier = ValueNotifier((initialDate ?? DateTime.now()).dateOnly) {
    loadDataForDate(selectedDate);
  }

  @override
  void dispose() {
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
    } while (_loadCoordinator.hasPendingReload && selectedDate.isSameDate(diaryDate));
  }

  Future<void> _loadDataForDateOnce(
    DateTime diaryDate, {
    required bool forceStepsRefresh,
  }) async {
    final loadGeneration = _loadCoordinator.begin(diaryDate);
    
    selectedDateNotifier.value = diaryDate;
    isLoading = true;
    isStepsWidgetLoading = false;
    isSleepWidgetLoading = false;
    isPulseWidgetLoading = false;
    notifyListeners();

    try {
      final goals = await _nutritionRepo.getGoalsForDate(diaryDate);
      final targetSugar = await _prefsRepo.getTargetSugar() ?? 50;
      final targetCaffeine = await _prefsRepo.getTargetCaffeine() ?? 400;
      showSugarInOverview = await _prefsRepo.getShowSugarInDiaryOverview();

      final entries = await _nutritionRepo.getEntriesForDate(diaryDate);
      final rawFluidEntries = await _nutritionRepo.getFluidEntriesForDate(diaryDate);
      final startOfDay = DateTime(diaryDate.year, diaryDate.month, diaryDate.day);
      final endOfDay = DateTime(diaryDate.year, diaryDate.month, diaryDate.day, 23, 59, 59, 999);
      final workoutLogs = await _nutritionRepo.getWorkoutLogsForDateRange(startOfDay, endOfDay);

      final barcodes = entries.map((e) => e.barcode).toSet().toList();
      final products = await _nutritionRepo.getProductsByBarcodes(barcodes);

      final supplementsForDate = await _nutritionRepo.getSupplementsForDate(diaryDate);
      final allSupplements = await _nutritionRepo.getAllSupplements();
      final todaysLogs = await _nutritionRepo.getSupplementLogsForDate(diaryDate);

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

      // Background Syncs
      final providerFilter = await _stepsSyncService.getProviderFilter();
      final providerFilterRaw = StepsSyncService.providerFilterToRaw(providerFilter);

      unawaited(_loadStepsForDate(
        diaryDate,
        providerFilterRaw: providerFilterRaw,
        loadGeneration: loadGeneration,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        if (_isCurrentLoad(loadGeneration, diaryDate)) {
          isStepsWidgetLoading = false;
          notifyListeners();
        }
      }));

      unawaited(_loadSleepAndSyncIfDue(
        diaryDate,
        force: forceStepsRefresh,
        loadGeneration: loadGeneration,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        if (_isCurrentLoad(loadGeneration, diaryDate)) {
          isSleepWidgetLoading = false;
          notifyListeners();
        }
      }));

      unawaited(_loadPulseForDate(
        diaryDate,
        loadGeneration: loadGeneration,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        if (_isCurrentLoad(loadGeneration, diaryDate)) {
          isPulseWidgetLoading = false;
          notifyListeners();
        }
      }));

      unawaited(_syncStepsIfDue(
        diaryDate,
        force: forceStepsRefresh,
        loadGeneration: loadGeneration,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        if (_isCurrentLoad(loadGeneration, diaryDate)) {
          isStepsWidgetLoading = false;
          notifyListeners();
        }
      }));

    } catch (e, st) {
      debugPrint('Error loading diary data: $e\n$st');
      if (_isCurrentLoad(loadGeneration, diaryDate)) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadSleepAndSyncIfDue(
    DateTime date, {
    required bool force,
    required int loadGeneration,
  }) async {
    await _loadSleepForDate(date, loadGeneration: loadGeneration);
    await _syncSleepIfDue(force: force);
    if (!_isCurrentLoad(loadGeneration, date)) return;
    await _loadSleepForDate(date, loadGeneration: loadGeneration);
  }

  Future<void> _loadStepsForDate(
    DateTime date, {
    required String providerFilterRaw,
    int? loadGeneration,
  }) async {
    try {
      final enabled = await _stepsSyncService.isTrackingEnabled();
      if (!_isCurrentLoad(loadGeneration ?? 0, date)) return;
      if (!enabled) {
        stepsForSelectedDay = null;
        stepsTrackingEnabled = false;
        isStepsWidgetLoading = false;
        notifyListeners();
        return;
      }
      isStepsWidgetLoading = true;
      notifyListeners();

      final sourcePolicy = await _stepsSyncService.getSourcePolicy();
      final sourcePolicyRaw = StepsSyncService.sourcePolicyToRaw(sourcePolicy);
      final total = await DatabaseHelper.instance.getDailyStepsTotal(
        dayLocal: date,
        providerFilter: providerFilterRaw,
        sourcePolicy: sourcePolicyRaw,
      );

      if (!_isCurrentLoad(loadGeneration ?? 0, date)) return;
      stepsForSelectedDay = total;
      stepsTrackingEnabled = true;
      isStepsWidgetLoading = false;
      notifyListeners();
    } catch (e) {
      if (!_isCurrentLoad(loadGeneration ?? 0, date)) return;
      isStepsWidgetLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSleepForDate(DateTime date, {int? loadGeneration}) async {
    try {
      final enabled = await _sleepSyncService.isTrackingEnabled();
      if (!_isCurrentLoad(loadGeneration ?? 0, date)) return;
      if (!enabled) {
        sleepOverview = null;
        sleepTrackingEnabled = false;
        isSleepWidgetLoading = false;
        notifyListeners();
        return;
      }
      isSleepWidgetLoading = true;
      notifyListeners();

      final overview = await _sleepRepository.fetchOverview(date);
      if (!_isCurrentLoad(loadGeneration ?? 0, date)) return;
      
      sleepOverview = overview;
      sleepTrackingEnabled = true;
      isSleepWidgetLoading = false;
      notifyListeners();
    } catch (e) {
      if (!_isCurrentLoad(loadGeneration ?? 0, date)) return;
      isSleepWidgetLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPulseForDate(DateTime date, {int? loadGeneration}) async {
    try {
      final enabled = await _pulseSyncService.isTrackingEnabled();
      if (!_isCurrentLoad(loadGeneration ?? 0, date)) return;
      if (!enabled) {
        pulseSummary = null;
        pulseTrackingEnabled = false;
        isPulseWidgetLoading = false;
        notifyListeners();
        return;
      }
      isPulseWidgetLoading = true;
      notifyListeners();

      final start = DateTime(date.year, date.month, date.day).toUtc();
      final end = start.add(const Duration(days: 1));
      final summary = await _pulseRepository.getAnalysis(
        window: PulseAnalysisWindow(startUtc: start, endUtc: end),
      );
      if (!_isCurrentLoad(loadGeneration ?? 0, date)) return;
      
      pulseSummary = summary;
      pulseTrackingEnabled = true;
      isPulseWidgetLoading = false;
      notifyListeners();
    } catch (e) {
      if (!_isCurrentLoad(loadGeneration ?? 0, date)) return;
      isPulseWidgetLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncStepsIfDue(
    DateTime diaryDate, {
    required bool force,
    required int loadGeneration,
  }) async {
    if (!stepsTrackingEnabled) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('last_steps_sync');
      final lastSync = lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;

      if (force || lastSync == null || DateTime.now().difference(lastSync) > _stepsSyncInterval) {
        isStepsWidgetLoading = true;
        notifyListeners();
        await _stepsSyncService.sync(forceRefresh: force);
        if (!_isCurrentLoad(loadGeneration, diaryDate)) return;

        final providerFilter = await _stepsSyncService.getProviderFilter();
        final providerFilterRaw = StepsSyncService.providerFilterToRaw(providerFilter);
        await _loadStepsForDate(
          diaryDate,
          providerFilterRaw: providerFilterRaw,
          loadGeneration: loadGeneration,
        );
      }
    } catch (e) {
      debugPrint('Background steps sync failed: $e');
    }
  }

  Future<void> _syncSleepIfDue({required bool force}) async {
    if (!sleepTrackingEnabled) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('last_sleep_sync');
      final lastSync = lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;

      if (force || lastSync == null || DateTime.now().difference(lastSync) > _sleepSyncInterval) {
        await _sleepSyncService.importRecentIfDue(force: force);
      }
    } catch (e) {
      debugPrint('Background sleep sync failed: $e');
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

    final supplements = await _nutritionRepo.getAllSupplements();
    Supplement? caffeineSupplement;
    try {
      caffeineSupplement = supplements.firstWhere((s) => s.code == 'caffeine');
    } catch (e) {
      return;
    }

    if (caffeineSupplement.id == null) return;

    await _nutritionRepo.insertSupplementLog(
      SupplementLog(
        supplementId: caffeineSupplement.id!,
        dose: doseMg,
        unit: 'mg',
        timestamp: timestamp,
        sourceFoodEntryId: foodEntryId,
        sourceFluidEntryId: fluidEntryId,
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
