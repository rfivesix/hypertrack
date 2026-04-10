import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../data/database_helper.dart';
import '../../data/product_database_helper.dart';
import '../../data/workout_database_helper.dart';
import '../../features/sleep/data/sleep_day_repository.dart';
import '../../generated/app_localizations.dart';
import '../../models/daily_nutrition.dart';
import '../../models/supplement.dart';
import '../../models/tracked_supplement.dart';
import '../../services/health/steps_sync_service.dart';
import 'today_focus_widget_config.dart';
import 'today_focus_widget_models.dart';

class TodayFocusWidgetSyncService {
  TodayFocusWidgetSyncService._();

  static final TodayFocusWidgetSyncService instance =
      TodayFocusWidgetSyncService._();

  static const MethodChannel _channel =
      MethodChannel('hypertrack.widget/today_focus');

  Future<void> sync() async {
    if (kIsWeb) return;

    final l10n = _localizedStrings;
    final config = await TodayFocusWidgetConfig.load();
    if (!config.enabled) {
      await _pushPayload(
        payload: <String, Object>{
          'title': l10n.nutritionSectionTodayInFocus,
          'subtitle': '',
          'maxVisibleItems': config.maxVisibleItems,
          'items': <Map<String, Object>>[],
          'emptyText': l10n.widgetOpenAppToLoadData,
          'enabled': false,
        },
      );
      return;
    }

    final payload = await _buildPayload(config, l10n);
    await _pushPayload(payload: payload);
  }

  Future<void> _pushPayload({required Map<String, Object> payload}) async {
    final payloadJson = jsonEncode(payload);
    try {
      await _channel.invokeMethod<void>('setPayload', <String, Object>{
        'payloadJson': payloadJson,
      });
      await _channel.invokeMethod<void>('refresh');
    } on MissingPluginException {
      // Unsupported platform in MVP.
    } on PlatformException {
      // Ignore widget sync failures to keep app interactions fast.
    }
  }

  AppLocalizations get _localizedStrings {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final supportedLocale = AppLocalizations.supportedLocales.firstWhere(
      (supported) => supported.languageCode == locale.languageCode,
      orElse: () => const Locale('en'),
    );
    return lookupAppLocalizations(supportedLocale);
  }

  Future<Map<String, Object>> _buildPayload(
    TodayFocusWidgetConfig config,
    AppLocalizations l10n,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final db = DatabaseHelper.instance;
    final goals = await db.getGoalsForDate(today);

    final foodEntries = await db.getEntriesForDate(today);
    final fluidEntries = await db.getFluidEntriesForDate(today);

    final nutrition = DailyNutrition(
      targetCalories: goals?.targetCalories ?? 2500,
      targetProtein: goals?.targetProtein ?? 180,
      targetCarbs: goals?.targetCarbs ?? 250,
      targetFat: goals?.targetFat ?? 80,
      targetWater: goals?.targetWater ?? 3000,
      targetSugar: 50,
      targetCaffeine: 400,
    );

    for (final entry in fluidEntries) {
      nutrition.water += entry.quantityInMl;
      nutrition.calories += entry.kcal ?? 0;
      final factor = entry.quantityInMl / 100.0;
      nutrition.sugar += (entry.sugarPer100ml ?? 0) * factor;
      nutrition.carbs += ((entry.carbsPer100ml ?? 0) * factor).round();
    }

    final productDb = ProductDatabaseHelper.instance;
    for (final entry in foodEntries) {
      final food = await productDb.getProductByBarcode(entry.barcode);
      if (food == null) continue;
      final factor = entry.quantityInGrams / 100.0;
      nutrition.calories += (food.calories * factor).round();
      nutrition.protein += (food.protein * factor).round();
      nutrition.carbs += (food.carbs * factor).round();
      nutrition.fat += (food.fat * factor).round();
      nutrition.sugar += (food.sugar ?? 0) * factor;
    }

    final trackedSupplements = await _loadTrackedSupplements(today);
    final creatineSupplement = _findCreatineSupplement(trackedSupplements);

    final caffeineTracked = trackedSupplements.where(
      (tracked) => (tracked.supplement.code ?? '').toLowerCase() == 'caffeine',
    );
    if (caffeineTracked.isNotEmpty) {
      nutrition.caffeine = caffeineTracked.first.totalDosedToday;
    }

    final workouts = await WorkoutDatabaseHelper.instance
        .getWorkoutLogsForDateRange(today, today);
    final completedWorkoutCount =
        workouts.where((workout) => workout.endTime != null).length;

    final stepsSyncService = StepsSyncService();
    final stepsEnabled = await stepsSyncService.isTrackingEnabled();
    final stepsProviderFilter = StepsSyncService.providerFilterToRaw(
      await stepsSyncService.getProviderFilter(),
    );
    final stepsSourcePolicy = StepsSyncService.sourcePolicyToRaw(
      await stepsSyncService.getSourcePolicy(),
    );
    final currentSteps = stepsEnabled
        ? (await db.getDailyStepsTotal(
              dayLocal: today,
              providerFilter: stepsProviderFilter,
              sourcePolicy: stepsSourcePolicy,
            )) ??
            0
        : 0;

    final sleepRepository = SleepDayRepository();
    final sleepOverview = await sleepRepository.fetchOverview(today);
    await sleepRepository.dispose();

    final otherSupplements = trackedSupplements.where((tracked) {
      final code = (tracked.supplement.code ?? '').toLowerCase();
      final name = tracked.supplement.name.toLowerCase();
      if (code == 'caffeine' || code == 'creatine') return false;
      if (name.contains('caffeine') || name.contains('creatine')) return false;
      return true;
    }).toList();

    final otherSupplementsTaken =
        otherSupplements.where((tracked) => tracked.totalDosedToday > 0).length;

    final itemsByType = <TodayFocusMetricType, TodayFocusWidgetItem>{
      TodayFocusMetricType.calories: TodayFocusWidgetItem(
        type: TodayFocusMetricType.calories,
        label: TodayFocusMetricType.calories.localizedLabel(l10n),
        valueText: l10n.widgetValueProgress(
          nutrition.calories,
          nutrition.targetCalories,
          l10n.widgetUnitKcal,
        ),
        accentColorArgb: TodayFocusMetricType.calories.accentColorArgb,
      ),
      TodayFocusMetricType.protein: TodayFocusWidgetItem(
        type: TodayFocusMetricType.protein,
        label: TodayFocusMetricType.protein.localizedLabel(l10n),
        valueText: l10n.widgetValueProgress(
          nutrition.protein,
          nutrition.targetProtein,
          l10n.widgetUnitGramShort,
        ),
        accentColorArgb: TodayFocusMetricType.protein.accentColorArgb,
      ),
      TodayFocusMetricType.water: TodayFocusWidgetItem(
        type: TodayFocusMetricType.water,
        label: TodayFocusMetricType.water.localizedLabel(l10n),
        valueText: l10n.widgetValueProgress(
          nutrition.water,
          nutrition.targetWater,
          l10n.widgetUnitMl,
        ),
        accentColorArgb: TodayFocusMetricType.water.accentColorArgb,
      ),
      TodayFocusMetricType.carbohydrates: TodayFocusWidgetItem(
        type: TodayFocusMetricType.carbohydrates,
        label: TodayFocusMetricType.carbohydrates.localizedLabel(l10n),
        valueText: l10n.widgetValueProgress(
          nutrition.carbs,
          nutrition.targetCarbs,
          l10n.widgetUnitGramShort,
        ),
        accentColorArgb: TodayFocusMetricType.carbohydrates.accentColorArgb,
      ),
      TodayFocusMetricType.sugar: TodayFocusWidgetItem(
        type: TodayFocusMetricType.sugar,
        label: TodayFocusMetricType.sugar.localizedLabel(l10n),
        valueText: l10n.widgetValueProgress(
          nutrition.sugar.toStringAsFixed(1),
          nutrition.targetSugar,
          l10n.widgetUnitGramShort,
        ),
        accentColorArgb: TodayFocusMetricType.sugar.accentColorArgb,
      ),
      TodayFocusMetricType.fat: TodayFocusWidgetItem(
        type: TodayFocusMetricType.fat,
        label: TodayFocusMetricType.fat.localizedLabel(l10n),
        valueText: l10n.widgetValueProgress(
          nutrition.fat,
          nutrition.targetFat,
          l10n.widgetUnitGramShort,
        ),
        accentColorArgb: TodayFocusMetricType.fat.accentColorArgb,
      ),
      TodayFocusMetricType.caffeine: TodayFocusWidgetItem(
        type: TodayFocusMetricType.caffeine,
        label: TodayFocusMetricType.caffeine.localizedLabel(l10n),
        valueText: l10n.widgetValueProgress(
          nutrition.caffeine.toStringAsFixed(0),
          nutrition.targetCaffeine,
          l10n.widgetUnitMg,
        ),
        accentColorArgb: TodayFocusMetricType.caffeine.accentColorArgb,
      ),
      TodayFocusMetricType.steps: TodayFocusWidgetItem(
        type: TodayFocusMetricType.steps,
        label: TodayFocusMetricType.steps.localizedLabel(l10n),
        valueText: l10n.widgetValueProgress(
          currentSteps,
          goals?.targetSteps ?? StepsSyncService.defaultStepsGoal,
          l10n.steps,
        ),
        accentColorArgb: TodayFocusMetricType.steps.accentColorArgb,
      ),
      TodayFocusMetricType.workouts: TodayFocusWidgetItem(
        type: TodayFocusMetricType.workouts,
        label: TodayFocusMetricType.workouts.localizedLabel(l10n),
        valueText: l10n.widgetWorkoutCompletedCount(completedWorkoutCount),
        accentColorArgb: TodayFocusMetricType.workouts.accentColorArgb,
      ),
    };

    if (creatineSupplement != null) {
      final creatineTracked = trackedSupplements.firstWhere(
        (tracked) => tracked.supplement.id == creatineSupplement.id,
      );
      final target =
          creatineSupplement.dailyGoal ?? creatineSupplement.dailyLimit;
      final targetText = target == null
          ? '${creatineTracked.totalDosedToday.toStringAsFixed(1)} ${creatineSupplement.unit}'
          : l10n.widgetValueProgress(
              creatineTracked.totalDosedToday.toStringAsFixed(1),
              target.toStringAsFixed(1),
              creatineSupplement.unit,
            );
      itemsByType[TodayFocusMetricType.creatine] = TodayFocusWidgetItem(
        type: TodayFocusMetricType.creatine,
        label: TodayFocusMetricType.creatine.localizedLabel(l10n),
        valueText: targetText,
        accentColorArgb: TodayFocusMetricType.creatine.accentColorArgb,
      );
    }

    if (otherSupplements.isNotEmpty) {
      itemsByType[TodayFocusMetricType.otherSupplements] = TodayFocusWidgetItem(
        type: TodayFocusMetricType.otherSupplements,
        label: TodayFocusMetricType.otherSupplements.localizedLabel(l10n),
        valueText: l10n.widgetSupplementsProgress(
          otherSupplementsTaken,
          otherSupplements.length,
        ),
        accentColorArgb: TodayFocusMetricType.otherSupplements.accentColorArgb,
      );
    }

    if (sleepOverview != null) {
      final duration = sleepOverview.totalSleepDuration;
      final durationText = l10n.widgetSleepDuration(
        duration.inHours,
        duration.inMinutes.remainder(60),
      );
      itemsByType[TodayFocusMetricType.sleep] = TodayFocusWidgetItem(
        type: TodayFocusMetricType.sleep,
        label: TodayFocusMetricType.sleep.localizedLabel(l10n),
        valueText: sleepOverview.analysis.score == null
            ? durationText
            : l10n.widgetSleepWithScore(
                durationText,
                sleepOverview.analysis.score!.round(),
              ),
        accentColorArgb: TodayFocusMetricType.sleep.accentColorArgb,
      );
    }

    final orderedItems = <TodayFocusWidgetItem>[];
    for (final metric in TodayFocusMetricTypeX.stableOrder) {
      if (!config.selectedMetrics.contains(metric)) continue;
      final item = itemsByType[metric];
      if (item != null) {
        orderedItems.add(item);
      }
    }

    return <String, Object>{
      'title': l10n.nutritionSectionTodayInFocus,
      'subtitle': _formatDate(today),
      'maxVisibleItems': config.maxVisibleItems,
      'enabled': true,
      'items': orderedItems.map((item) => item.toJson()).toList(),
      'emptyText': l10n.widgetOpenAppToLoadData,
      'updatedAtEpochMs': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Supplement? _findCreatineSupplement(List<TrackedSupplement> tracked) {
    for (final item in tracked) {
      final code = (item.supplement.code ?? '').toLowerCase();
      final name = item.supplement.name.toLowerCase();
      if (code == 'creatine' || name.contains('creatine')) {
        return item.supplement;
      }
    }
    return null;
  }

  String _formatDate(DateTime day) {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final localeTag = locale.toLanguageTag();
    return DateFormat('EEE d.M', localeTag).format(day);
  }

  Future<List<TrackedSupplement>> _loadTrackedSupplements(DateTime day) async {
    final supplementsForDate =
        await DatabaseHelper.instance.getSupplementsForDate(day);
    final allSupplements = await DatabaseHelper.instance.getAllSupplements();
    final todaysSupplementLogs =
        await DatabaseHelper.instance.getSupplementLogsForDate(day);

    final dosesBySupplementId = <int, double>{};
    for (final log in todaysSupplementLogs) {
      dosesBySupplementId.update(
        log.supplementId,
        (value) => value + log.dose,
        ifAbsent: () => log.dose,
      );
    }

    final supplementsById = <int, Supplement>{
      for (final supplement in allSupplements)
        if (supplement.id != null) supplement.id!: supplement,
    };

    final tracked = <TrackedSupplement>[];
    for (final supplement in supplementsForDate) {
      final hasLog = dosesBySupplementId.containsKey(supplement.id);
      if (supplement.isTracked || hasLog) {
        tracked.add(
          TrackedSupplement(
            supplement: supplement,
            totalDosedToday: dosesBySupplementId[supplement.id] ?? 0.0,
          ),
        );
      }
    }

    for (final entry in dosesBySupplementId.entries) {
      final existing =
          tracked.any((tracked) => tracked.supplement.id == entry.key);
      if (existing) continue;
      final supplement = supplementsById[entry.key];
      if (supplement == null) continue;
      tracked.add(
        TrackedSupplement(
          supplement: supplement,
          totalDosedToday: entry.value,
        ),
      );
    }

    return tracked;
  }
}
