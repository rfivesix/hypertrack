import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/database_helper.dart';
import '../../../services/health/steps_sync_service.dart';
import '../../sleep/data/sleep_day_repository.dart';
import '../../sleep/platform/sleep_sync_service.dart';
import '../../pulse/data/pulse_repository.dart';
import '../../pulse/domain/pulse_models.dart';
import '../../pulse/application/pulse_tracking_service.dart';

/// Coordinator that handles health tracking (Steps, Sleep, Pulse)
/// background synchronization and reactive state.
class DiaryHealthSyncCoordinator extends ChangeNotifier {
  static const Duration _stepsSyncInterval = Duration(hours: 6);
  static const Duration _sleepSyncInterval = Duration(hours: 6);

  final StepsSyncService _stepsSyncService = StepsSyncService();
  final SleepSyncService _sleepSyncService = SleepSyncService();
  final SleepDayDataRepository _sleepRepository = SleepDayRepository();
  final PulseTrackingSettingsService _pulseSyncService = PulseTrackingService();
  final PulseAnalysisRepository _pulseRepository =
      HealthPulseAnalysisRepository();

  int? stepsForSelectedDay;
  bool isStepsWidgetLoading = false;
  bool stepsTrackingEnabled = true;

  SleepDayOverviewData? sleepOverview;
  bool isSleepWidgetLoading = false;
  bool sleepTrackingEnabled = false;

  PulseAnalysisSummary? pulseSummary;
  bool isPulseWidgetLoading = false;
  bool pulseTrackingEnabled = false;

  Future<void> loadAndSyncHealthData({
    required DateTime date,
    required bool forceStepsRefresh,
    required bool Function(DateTime date) isCurrentLoad,
  }) async {
    final providerFilter = await _stepsSyncService.getProviderFilter();
    final providerFilterRaw =
        StepsSyncService.providerFilterToRaw(providerFilter);

    unawaited(_loadStepsForDate(
      date,
      providerFilterRaw: providerFilterRaw,
      isCurrentLoad: isCurrentLoad,
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      if (isCurrentLoad(date)) {
        isStepsWidgetLoading = false;
        notifyListeners();
      }
    }));

    unawaited(_loadSleepAndSyncIfDue(
      date,
      force: forceStepsRefresh,
      isCurrentLoad: isCurrentLoad,
    ).timeout(const Duration(seconds: 15), onTimeout: () {
      if (isCurrentLoad(date)) {
        isSleepWidgetLoading = false;
        notifyListeners();
      }
    }));

    unawaited(_loadPulseForDate(
      date,
      isCurrentLoad: isCurrentLoad,
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      if (isCurrentLoad(date)) {
        isPulseWidgetLoading = false;
        notifyListeners();
      }
    }));

    unawaited(_syncStepsIfDue(
      date,
      force: forceStepsRefresh,
      isCurrentLoad: isCurrentLoad,
    ).timeout(const Duration(seconds: 15), onTimeout: () {
      if (isCurrentLoad(date)) {
        isStepsWidgetLoading = false;
        notifyListeners();
      }
    }));
  }

  Future<void> _loadSleepAndSyncIfDue(
    DateTime date, {
    required bool force,
    required bool Function(DateTime date) isCurrentLoad,
  }) async {
    await _loadSleepForDate(date, isCurrentLoad: isCurrentLoad);
    await _syncSleepIfDue(force: force);
    if (!isCurrentLoad(date)) return;
    await _loadSleepForDate(date, isCurrentLoad: isCurrentLoad);
  }

  Future<void> _loadStepsForDate(
    DateTime date, {
    required String providerFilterRaw,
    required bool Function(DateTime date) isCurrentLoad,
  }) async {
    try {
      final enabled = await _stepsSyncService.isTrackingEnabled();
      if (!isCurrentLoad(date)) return;
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

      if (!isCurrentLoad(date)) return;
      stepsForSelectedDay = total;
      stepsTrackingEnabled = true;
      isStepsWidgetLoading = false;
      notifyListeners();
    } catch (e) {
      if (!isCurrentLoad(date)) return;
      isStepsWidgetLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSleepForDate(
    DateTime date, {
    required bool Function(DateTime date) isCurrentLoad,
  }) async {
    try {
      final enabled = await _sleepSyncService.isTrackingEnabled();
      if (!isCurrentLoad(date)) return;
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
      if (!isCurrentLoad(date)) return;

      sleepOverview = overview;
      sleepTrackingEnabled = true;
      isSleepWidgetLoading = false;
      notifyListeners();
    } catch (e) {
      if (!isCurrentLoad(date)) return;
      isSleepWidgetLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPulseForDate(
    DateTime date, {
    required bool Function(DateTime date) isCurrentLoad,
  }) async {
    try {
      final enabled = await _pulseSyncService.isTrackingEnabled();
      if (!isCurrentLoad(date)) return;
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
      if (!isCurrentLoad(date)) return;

      pulseSummary = summary;
      pulseTrackingEnabled = true;
      isPulseWidgetLoading = false;
      notifyListeners();
    } catch (e) {
      if (!isCurrentLoad(date)) return;
      isPulseWidgetLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncStepsIfDue(
    DateTime diaryDate, {
    required bool force,
    required bool Function(DateTime date) isCurrentLoad,
  }) async {
    if (!stepsTrackingEnabled) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('last_steps_sync');
      final lastSync =
          lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;

      if (force ||
          lastSync == null ||
          DateTime.now().difference(lastSync) > _stepsSyncInterval) {
        isStepsWidgetLoading = true;
        notifyListeners();
        await _stepsSyncService.sync(forceRefresh: force);
        if (!isCurrentLoad(diaryDate)) return;

        final providerFilter = await _stepsSyncService.getProviderFilter();
        final providerFilterRaw =
            StepsSyncService.providerFilterToRaw(providerFilter);
        await _loadStepsForDate(
          diaryDate,
          providerFilterRaw: providerFilterRaw,
          isCurrentLoad: isCurrentLoad,
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
      final lastSync =
          lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;

      if (force ||
          lastSync == null ||
          DateTime.now().difference(lastSync) > _sleepSyncInterval) {
        await _sleepSyncService.importRecentIfDue(force: force);
      }
    } catch (e) {
      debugPrint('Background sleep sync failed: $e');
    }
  }
}
