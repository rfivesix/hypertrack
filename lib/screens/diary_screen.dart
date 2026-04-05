import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../data/product_database_helper.dart';
import '../dialogs/fluid_dialog_content.dart';
import '../dialogs/quantity_dialog_content.dart';
import '../generated/app_localizations.dart';
import '../models/daily_nutrition.dart';
import '../models/fluid_entry.dart';
import '../models/food_entry.dart';
import '../models/food_item.dart';
import '../models/supplement.dart';
import '../models/supplement_log.dart';
import '../models/tracked_food_item.dart';
import 'add_food_screen.dart';
import 'add_food_navigation_result.dart';
import 'food_detail_screen.dart';
import 'supplement_track_screen.dart';
import '../util/date_util.dart';
import '../util/design_constants.dart';
import '../widgets/bottom_content_spacer.dart';
import '../widgets/glass_bottom_menu.dart';
import '../widgets/measurement_chart_widget.dart';
import '../widgets/nutrition_summary_widget.dart';
import '../widgets/supplement_summary_widget.dart';
import '../widgets/swipe_action_background.dart';
import '../widgets/summary_card.dart';
import '../widgets/glass_progress_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracked_supplement.dart';
import '../data/workout_database_helper.dart';
import '../services/theme_service.dart';
import '../services/health/steps_sync_service.dart';
import '../features/steps/data/steps_aggregation_repository.dart';
import '../features/steps/domain/steps_models.dart';
import '../features/steps/presentation/steps_module_screen.dart';
import '../features/sleep/data/sleep_day_repository.dart';
import '../features/sleep/platform/sleep_sync_service.dart';
import '../features/sleep/presentation/sleep_navigation.dart';
import 'ai_recommendation_screen.dart';
import 'workout_history_screen.dart';
import '../widgets/todays_workout_summary_card.dart';

/// The central hub for tracking and viewing daily nutritional and activity data.
///
/// Displays a comprehensive overview of calories, macros, supplements, and workouts
/// for a selected date. Allows users to manage food entries, fluid intake, and
/// view historical measurements like weight.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => DiaryScreenState();
}

class DiaryScreenState extends State<DiaryScreen> {
  static const Duration _stepsSyncInterval = Duration(hours: 6);
  static const Duration _sleepSyncInterval = Duration(hours: 6);
  static const String _showSugarInDiaryOverviewPrefKey =
      'showSugarInDiaryOverview';
  bool _isLoading = true;
  final ValueNotifier<DateTime> selectedDateNotifier = ValueNotifier(
    DateTime.now(),
  );
  DateTime get _selectedDate => selectedDateNotifier.value;
  DailyNutrition? _dailyNutrition;
  Map<String, List<TrackedFoodItem>> _entriesByMeal = {};
  List<FluidEntry> _fluidEntries = [];
  List<TrackedSupplement> _trackedSupplements = [];
  final StepsSyncService _stepsSyncService = StepsSyncService();
  final StepsAggregationRepository _stepsRepository =
      HealthStepsAggregationRepository();
  int? _stepsForSelectedDay;
  bool _isStepsWidgetLoading = false;
  bool _stepsTrackingEnabled = true;
  int _targetSteps = StepsSyncService.defaultStepsGoal;
  final SleepSyncService _sleepSyncService = SleepSyncService();
  final SleepDayDataRepository _sleepRepository = SleepDayRepository();
  SleepDayOverviewData? _sleepOverview;
  bool _isSleepWidgetLoading = false;
  bool _sleepTrackingEnabled = false;
  bool _showSugarInOverview = false;

  // Workout summary state used by the daily overview card.
  Map<String, dynamic>? _workoutSummary;

  String _selectedChartRangeKey = '30D';
  final Map<String, bool> _mealExpanded = {
    "mealtypeBreakfast": false,
    "mealtypeLunch": false,
    "mealtypeDinner": false,
    "mealtypeSnack": false,
    "fluids": false,
  };

  @override
  void initState() {
    super.initState();
    loadDataForDate(_selectedDate);
  }

  @override
  void dispose() {
    selectedDateNotifier.dispose();
    super.dispose();
  }

  // Data-loading entry point for the currently selected date.
  Future<void> loadDataForDate(
    DateTime date, {
    bool forceStepsRefresh = false,
  }) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final dbHelper = DatabaseHelper.instance;

    // 1. Load goals from DB (historically accurate for the selected date)
    final goals = await dbHelper.getGoalsForDate(date);

    // 2. Prefs only for "Extra" values not in the DB schema
    final prefs = await SharedPreferences.getInstance();
    final stepsEnabled = await _stepsSyncService.isTrackingEnabled();
    final providerFilter = await _stepsSyncService.getProviderFilter();
    final providerFilterRaw = StepsSyncService.providerFilterToRaw(
      providerFilter,
    );

    // 3. Use values from DB or fallbacks
    final targetCalories = goals?.targetCalories ?? 2500;
    final targetProtein = goals?.targetProtein ?? 180;
    final targetCarbs = goals?.targetCarbs ?? 250;
    final targetFat = goals?.targetFat ?? 80;
    final targetWater = goals?.targetWater ?? 3000;
    final targetSugar = prefs.getInt('targetSugar') ?? 50;
    final showSugarInOverview =
        prefs.getBool(_showSugarInDiaryOverviewPrefKey) ?? false;

    // Caffeine and related targets still come from prefs (not in AppSettings yet).
    final targetCaffeine = prefs.getInt('targetCaffeine') ?? 400;
    final foodEntries = await DatabaseHelper.instance.getEntriesForDate(date);
    final fluidEntries = await DatabaseHelper.instance.getFluidEntriesForDate(
      date,
    );
    final waterIntake = fluidEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.quantityInMl,
    );

    final summary = DailyNutrition(
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetCarbs: targetCarbs,
      targetFat: targetFat,
      targetWater: targetWater,
      targetSugar: targetSugar,
      targetCaffeine: targetCaffeine,
    );
    summary.water = waterIntake;

    for (final entry in fluidEntries) {
      summary.calories += entry.kcal ?? 0;
      final factor = entry.quantityInMl / 100.0;
      summary.sugar += (entry.sugarPer100ml ?? 0) * factor;
      summary.carbs += ((entry.carbsPer100ml ?? 0) * factor).round();
    }

    final Map<String, List<TrackedFoodItem>> groupedEntries = {
      'mealtypeBreakfast': [],
      'mealtypeLunch': [],
      'mealtypeDinner': [],
      'mealtypeSnack': [],
    };

    for (final entry in foodEntries) {
      final foodItem = await ProductDatabaseHelper.instance.getProductByBarcode(
        entry.barcode,
      );
      if (foodItem != null) {
        summary.calories +=
            (foodItem.calories / 100 * entry.quantityInGrams).round();
        summary.protein +=
            (foodItem.protein / 100 * entry.quantityInGrams).round();
        summary.carbs += (foodItem.carbs / 100 * entry.quantityInGrams).round();
        summary.fat += (foodItem.fat / 100 * entry.quantityInGrams).round();
        summary.sugar +=
            (foodItem.sugar ?? 0) * (entry.quantityInGrams / 100.0);

        final trackedItem = TrackedFoodItem(entry: entry, item: foodItem);
        groupedEntries[entry.mealType]?.add(trackedItem);
      }
    }

    for (var meal in groupedEntries.values) {
      meal.sort((a, b) => b.entry.timestamp.compareTo(a.entry.timestamp));
    }

    final supplementsForDate =
        await DatabaseHelper.instance.getSupplementsForDate(date);
    final allSupplements = await DatabaseHelper.instance.getAllSupplements();
    final todaysSupplementLogs =
        await DatabaseHelper.instance.getSupplementLogsForDate(date);

    final Map<int, double> todaysDoses = {};
    for (final log in todaysSupplementLogs) {
      todaysDoses.update(
        log.supplementId,
        (value) => value + log.dose,
        ifAbsent: () => log.dose,
      );
    }

    Supplement? caffeineSupplement;
    try {
      caffeineSupplement = allSupplements.firstWhere(
        (s) => s.code == 'caffeine',
      );
    } catch (e) {
      caffeineSupplement = null;
    }

    if (caffeineSupplement != null && caffeineSupplement.id != null) {
      summary.caffeine = todaysDoses[caffeineSupplement.id] ?? 0.0;
    }

    final Map<int, Supplement> byId = {
      for (final s in allSupplements)
        if (s.id != null) s.id!: s,
    };

    final List<TrackedSupplement> trackedSupps = [];
    for (final s in supplementsForDate) {
      final hasLog = todaysDoses.containsKey(s.id);
      if (s.isTracked || hasLog) {
        trackedSupps.add(
          TrackedSupplement(
            supplement: s,
            totalDosedToday: todaysDoses[s.id] ?? 0.0,
          ),
        );
      }
    }
    for (final id in todaysDoses.keys) {
      if (!trackedSupps.any((ts) => ts.supplement.id == id)) {
        if (byId.containsKey(id)) {
          trackedSupps.add(
            TrackedSupplement(
              supplement: byId[id]!,
              totalDosedToday: todaysDoses[id]!,
            ),
          );
        }
      }
    }

    final workoutLogs = await WorkoutDatabaseHelper.instance
        .getWorkoutLogsForDateRange(date, date);
    final completedLogs =
        workoutLogs.where((log) => log.endTime != null).toList();
    Map<String, dynamic>? workoutSummary;

    if (completedLogs.isNotEmpty) {
      // --- KORREKTUR START ---
      Duration totalDuration = Duration.zero;
      double totalVolume = 0.0;
      int totalSets = 0;

      for (final log in completedLogs) {
        totalDuration += log.endTime!.difference(
          log.startTime,
        ); // Addiert die volle Dauer
        totalSets += log.sets.length;
        for (final set in log.sets) {
          totalVolume += (set.weightKg ?? 0) * (set.reps ?? 0);
        }
      }

      workoutSummary = {
        'duration': totalDuration, // Verwendet die korrekte Summe
        'volume': totalVolume,
        'sets': totalSets,
        'count': completedLogs.length,
      };
      // --- KORREKTUR ENDE ---
    }

    if (mounted) {
      setState(() {
        selectedDateNotifier.value = date;
        _dailyNutrition = summary;
        _entriesByMeal = groupedEntries;
        _fluidEntries = fluidEntries;
        _trackedSupplements = trackedSupps;
        _workoutSummary = workoutSummary;
        _stepsTrackingEnabled = stepsEnabled;
        _targetSteps = goals?.targetSteps ?? StepsSyncService.defaultStepsGoal;
        _showSugarInOverview = showSugarInOverview;
        _isLoading = false;
      });
    }
    await _loadStepsForDate(date, providerFilterRaw: providerFilterRaw);
    await _syncSleepIfDue(force: forceStepsRefresh);
    await _loadSleepForDate(date);
    await _syncStepsIfDue(date, force: forceStepsRefresh);
  }

  Future<void> _loadStepsForDate(
    DateTime date, {
    required String providerFilterRaw,
  }) async {
    final enabled = await _stepsSyncService.isTrackingEnabled();
    if (!enabled) {
      if (!mounted) return;
      setState(() {
        _stepsForSelectedDay = null;
        _stepsTrackingEnabled = false;
        _isStepsWidgetLoading = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _isStepsWidgetLoading = true);
    final sourcePolicy = await _stepsSyncService.getSourcePolicy();
    final sourcePolicyRaw = StepsSyncService.sourcePolicyToRaw(sourcePolicy);
    final total = await DatabaseHelper.instance.getDailyStepsTotal(
      dayLocal: date,
      providerFilter: providerFilterRaw,
      sourcePolicy: sourcePolicyRaw,
    );
    if (!mounted) return;
    setState(() {
      _stepsForSelectedDay = total;
      _stepsTrackingEnabled = true;
      _isStepsWidgetLoading = false;
    });
  }

  Future<void> _loadSleepForDate(DateTime date) async {
    final enabled = await _sleepSyncService.isTrackingEnabled();
    if (!enabled) {
      if (!mounted) return;
      setState(() {
        _sleepOverview = null;
        _sleepTrackingEnabled = false;
        _isSleepWidgetLoading = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _isSleepWidgetLoading = true);
    final overview = await _sleepRepository.fetchOverview(date);
    if (!mounted) return;
    setState(() {
      _sleepOverview = overview;
      _sleepTrackingEnabled = true;
      _isSleepWidgetLoading = false;
    });
  }

  Future<void> _syncStepsIfDue(DateTime date, {bool force = false}) async {
    final enabled = await _stepsSyncService.isTrackingEnabled();
    if (!enabled) return;
    final lastSync = await _stepsSyncService.getLastSyncAt();
    final shouldSync = force ||
        lastSync == null ||
        DateTime.now().toUtc().difference(lastSync) > _stepsSyncInterval;
    if (!shouldSync) return;
    if (!mounted) return;
    setState(() => _isStepsWidgetLoading = true);
    await _stepsRepository.refresh(force: force);
    final providerFilter = await _stepsSyncService.getProviderFilter();
    final providerFilterRaw = StepsSyncService.providerFilterToRaw(
      providerFilter,
    );
    await _loadStepsForDate(date, providerFilterRaw: providerFilterRaw);
  }

  Future<void> _syncSleepIfDue({bool force = false}) async {
    await _sleepSyncService.importRecentIfDue(
      minInterval: _sleepSyncInterval,
      force: force,
    );
  }

  Future<void> _deleteFoodEntry(int id) async {
    await DatabaseHelper.instance.deleteFoodEntry(id);
    loadDataForDate(_selectedDate);
  }

  Future<void> _deleteFluidEntry(int id) async {
    await DatabaseHelper.instance.deleteFluidEntry(id);
    loadDataForDate(_selectedDate);
  }

  // lib/screens/diary_screen.dart - ERSETZE DIE GESAMTE METHODE
  Future<void> _editFoodEntry(TrackedFoodItem trackedItem) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();

    final result = await showGlassBottomMenu<
        ({
          int quantity,
          DateTime timestamp,
          String mealType,
          bool isLiquid,
          double? sugarPer100ml,
          double? caffeinePer100ml,
        })?>(
      context: context,
      title: trackedItem.item.getLocalizedName(context),
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Der Inhalt des Dialogs (jetzt als Bottom-Sheet-Inhalt)
            QuantityDialogContent(
              key: dialogStateKey,
              item: trackedItem.item,
              initialQuantity: trackedItem.entry.quantityInGrams,
              initialTimestamp: trackedItem.entry.timestamp,
              initialMealType: trackedItem.entry.mealType,
              // Die aktuellen Nährwerte des Eintrags als Initial-Werte
              // Annahme: Wenn der Eintrag existiert, sind die Nährwerte fix.
              // Wir setzen nur die Liquid-Status, falls nötig.
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: close,
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final state = dialogStateKey.currentState;
                      if (state != null) {
                        final quantity = int.tryParse(state.quantityText);
                        final caffeine = double.tryParse(
                          state.caffeineText.replaceAll(',', '.'),
                        );
                        final sugar = double.tryParse(
                          state.sugarText.replaceAll(',', '.'),
                        );

                        if (quantity != null && quantity > 0) {
                          close();
                          // Hier geben wir das korrekte, anonyme Tupel zurück
                          Navigator.of(ctx).pop((
                            quantity: quantity,
                            timestamp: state.selectedDateTime,
                            mealType: state.selectedMealType,
                            isLiquid: state.isLiquid,
                            sugarPer100ml: sugar,
                            caffeinePer100ml: caffeine,
                          ));
                        }
                      }
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

    // Weiterhin die Daten aus dem Ergebnis verarbeiten
    if (result != null) {
      final updatedEntry = FoodEntry(
        id: trackedItem.entry.id,
        barcode: trackedItem.item.barcode,
        quantityInGrams: result.quantity,
        timestamp: result.timestamp,
        mealType: result.mealType,
      );
      await DatabaseHelper.instance.updateFoodEntry(updatedEntry);

      // 1. FluidEntry löschen (falls verknüpft)
      if (trackedItem.entry.id != null) {
        await DatabaseHelper.instance.deleteFluidEntryByLinkedFoodId(
          trackedItem.entry.id!,
        );
      }
      // 2. FluidEntry neu erstellen (falls jetzt flüssig)
      if (result.isLiquid) {
        final newFluidEntry = FluidEntry(
          timestamp: result.timestamp,
          quantityInMl: result.quantity,
          name: trackedItem.item.name,
          kcal: null,
          sugarPer100ml: result.sugarPer100ml,
          carbsPer100ml: result.sugarPer100ml, // Spiegeln
          caffeinePer100ml: result.caffeinePer100ml,
          linked_food_entry_id: trackedItem.entry.id, // Verknüpfung beibehalten
        );
        await DatabaseHelper.instance.insertFluidEntry(newFluidEntry);
      }

      // 3. Koffein-Log aktualisieren/löschen (in jedem Fall)
      await _logCaffeineDose(
        (result.caffeinePer100ml ?? 0) * (result.quantity / 100.0),
        result.timestamp,
        foodEntryId: trackedItem.entry.id,
      );

      loadDataForDate(_selectedDate);
    }
  }

  Future<void> _addFoodToMeal(String mealType) async {
    final routeResult = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) => AddFoodScreen(
          initialDate: _selectedDate, // <--- ÜBERGABE
          initialMealType: mealType, // <--- ÜBERGABE
        ),
      ),
    );

    if (!mounted) return;

    final addFoodResult = AddFoodNavigationResult.fromRouteResult(routeResult);
    if (addFoodResult.shouldRefresh) {
      loadDataForDate(_selectedDate);
      return;
    }

    final selectedFoodItem = addFoodResult.selectedFoodItem;
    if (selectedFoodItem == null) return;

    // FIX: Datum an das Hilfs-Menü übergeben
    final result = await _showQuantityMenu(
      selectedFoodItem,
      mealType,
      initialDate: _selectedDate, // <--- Parameter hinzufügen (siehe Punkt C)
    );

    if (result == null || !mounted) return;

    // ... (Rest der Logik bleibt gleich, nutzt result.timestamp) ...
    final int quantity = result.quantity;
    final DateTime timestamp = result.timestamp;
    final String resultMealType = result.mealType;
    final bool isLiquid = result.isLiquid;
    final double? caffeinePer100 = result.caffeinePer100ml;

    final newFoodEntry = FoodEntry(
      barcode: selectedFoodItem.barcode,
      timestamp: timestamp,
      quantityInGrams: quantity,
      mealType: resultMealType,
    );
    final newFoodEntryId = await DatabaseHelper.instance.insertFoodEntry(
      newFoodEntry,
    );

    if (isLiquid) {
      final newFluidEntry = FluidEntry(
        timestamp: timestamp,
        quantityInMl: quantity,
        name: selectedFoodItem.name,
        kcal: null,
        sugarPer100ml: null,
        carbsPer100ml: null,
        caffeinePer100ml: null,
        linked_food_entry_id: newFoodEntryId,
      );
      await DatabaseHelper.instance.insertFluidEntry(newFluidEntry);
    }

    if (isLiquid && caffeinePer100 != null && caffeinePer100 > 0) {
      final totalCaffeine = (caffeinePer100 / 100.0) * quantity;
      await _logCaffeineDose(
        totalCaffeine,
        timestamp,
        foodEntryId: newFoodEntryId,
      );
    }

    loadDataForDate(_selectedDate);
  }

  // FÜGEN SIE DIESE ZWEI NEUEN METHODEN ZUR KLASSE HINZU
  // In lib/screens/diary_screen.dart

  Future<
      ({
        int quantity,
        DateTime timestamp,
        String mealType,
        bool isLiquid,
        double? sugarPer100ml,
        double? caffeinePer100ml,
      })?> _showQuantityMenu(
    FoodItem item,
    String mealType, {
    DateTime? initialDate, // <--- NEUER PARAMETER
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();

    return showGlassBottomMenu(
      context: context,
      title: item.name,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuantityDialogContent(
              key: dialogStateKey,
              item: item,
              initialMealType: mealType,
              initialTimestamp: initialDate ??
                  _selectedDate, // <--- FIX: Nutze Parameter oder Fallback
            ),
            // ... (Rest der Methode: Buttons etc. bleibt gleich) ...
            const SizedBox(height: 12),
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
                      final state = dialogStateKey.currentState;
                      if (state != null) {
                        final quantity = int.tryParse(state.quantityText);
                        // ... parsing ...
                        final sugar = double.tryParse(
                          state.sugarText.replaceAll(',', '.'),
                        );
                        final caffeine = double.tryParse(
                          state.caffeineText.replaceAll(',', '.'),
                        );

                        if (quantity != null && quantity > 0) {
                          close();
                          Navigator.of(ctx).pop((
                            quantity: quantity,
                            timestamp: state.selectedDateTime,
                            mealType: state.selectedMealType,
                            isLiquid: state.isLiquid,
                            sugarPer100ml: sugar,
                            caffeinePer100ml: caffeine,
                          ));
                        }
                      }
                    },
                    child: Text(l10n.add_button),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _logCaffeineDose(
    double doseMg,
    DateTime timestamp, {
    int? foodEntryId,
    int? fluidEntryId,
  }) async {
    if (doseMg <= 0) return;

    final supplements = await DatabaseHelper.instance.getAllSupplements();
    Supplement? caffeineSupplement;
    try {
      caffeineSupplement = supplements.firstWhere((s) => s.code == 'caffeine');
    } catch (e) {
      return;
    }

    if (caffeineSupplement.id == null) return;

    await DatabaseHelper.instance.insertSupplementLog(
      SupplementLog(
        supplementId: caffeineSupplement.id!,
        dose: doseMg,
        unit: 'mg',
        timestamp: timestamp,
        source_food_entry_id: foodEntryId,
        source_fluid_entry_id: fluidEntryId,
      ),
    );
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      // Erlaube Auswahl in der Zukunft, z.B. für Vorausplanung
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      loadDataForDate(picked);
    }
  }

  void navigateDay(bool forward) {
    final newDay = _selectedDate.add(Duration(days: forward ? 1 : -1));
    // Im Gegensatz zum NutritionScreen erlauben wir hier die Navigation in die Zukunft
    // if (forward && newDay.isAfter(DateTime.now())) return;

    loadDataForDate(newDay);
  }

  Widget _buildWeightChartCard(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.weightHistoryTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8.0,
                      alignment: WrapAlignment.end,
                      children: [
                        '30D',
                        '90D',
                        'All',
                      ].map((key) => _buildFilterButton(key, key)).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingL),
            MeasurementChartWidget(
              chartType: 'weight',
              dateRange: _calculateDateRange(),
              unit: "kg",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String key) {
    final theme = Theme.of(context);
    final isSelected = _selectedChartRangeKey == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartRangeKey = key;
        });
        // Chart wird durch setState im MeasurementChartWidget neu geladen
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  DateTimeRange _calculateDateRange() {
    final now = DateTime.now();
    DateTime start;
    switch (_selectedChartRangeKey) {
      case '90D':
        start = now.subtract(const Duration(days: 89));
        break;
      case 'All':
        // Für "Alle" setzen wir ein sehr frühes Datum,
        // der Chart wird die Daten entsprechend laden
        start = DateTime(2020);
        break;
      case '30D':
      default:
        start = now.subtract(const Duration(days: 29));
    }
    return DateTimeRange(start: start, end: now);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double appBarHeight = MediaQuery.of(
      context,
    ).padding.top; // + kToolbarHeight;

    // 2. Get your base padding from your design constants
    const EdgeInsets basePadding =
        DesignConstants.cardPadding; // This is EdgeInsets.all(16.0)

    // 3. Create the final combined padding
    final EdgeInsets finalPadding = basePadding.copyWith(
      // Take the original top value (16.0) and add the app bar height
      top: basePadding.top + appBarHeight,
    );

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () =>
                loadDataForDate(_selectedDate, forceStepsRefresh: true),
            child: ListView(
              padding: finalPadding,
              children: [
                const SizedBox(height: DesignConstants.spacingL),
                _buildSectionTitle(context, l10n.today_overview_text),
                if (_dailyNutrition != null)
                  NutritionSummaryWidget(
                    nutritionData: _dailyNutrition!,
                    l10n: l10n,
                    isExpandedView: false,
                    showSugarInOverview: _showSugarInOverview,
                  ),

                const SizedBox(height: DesignConstants.spacingXS),
                SupplementSummaryWidget(
                  trackedSupplements: _trackedSupplements,
                  onTap: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          // FIX #65: Datum weiterreichen
                          builder: (context) =>
                              SupplementTrackScreen(initialDate: _selectedDate),
                        ),
                      )
                      .then((_) => loadDataForDate(_selectedDate)),
                ),
                if (_stepsTrackingEnabled) ...[_buildStepsSummaryCard()],
                if (_sleepTrackingEnabled) ...[_buildSleepSummaryCard()],
                // NEUER TEIL: Workout-Zusammenfassung hier einfügen
                if (_workoutSummary != null) ...[
                  //const SizedBox(height: DesignConstants.spacingXS),
                  TodaysWorkoutSummaryCard(
                    duration: _workoutSummary!['duration'] as Duration,
                    volume: _workoutSummary!['volume'] as double,
                    sets: _workoutSummary!['sets'] as int,
                    workoutCount: _workoutSummary!['count'] as int,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const WorkoutHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: DesignConstants.spacingXL),
                _buildSectionTitle(context, l10n.protocol_today_capslock),
                _buildTodaysLog(l10n),
                const SizedBox(height: DesignConstants.spacingXL),
                _buildSectionTitle(context, l10n.measurementWeightCapslock),
                _buildWeightChartCard(
                  context,
                  Theme.of(context).colorScheme,
                  l10n,
                ),
                const BottomContentSpacer(),
              ],
            ),
          );
  }

  Widget _buildStepsSummaryCard() {
    if (_isStepsWidgetLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: SummaryCard(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Syncing steps...'),
              ],
            ),
          ),
        ),
      );
    }
    if ((_stepsForSelectedDay ?? 0) <= 0) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StepsModuleScreen(
                initialScope: StepsScope.day,
                initialDate: _selectedDate,
              ),
            ),
          );
        },
        child: GlassProgressBar(
          label: 'Steps',
          unit: 'steps',
          value: (_stepsForSelectedDay ?? 0).toDouble(),
          target: (_targetSteps > 0
                  ? _targetSteps
                  : StepsSyncService.defaultStepsGoal)
              .toDouble(),
          color: theme.colorScheme.primary,
          height: 50,
          borderRadius: 16,
        ),
      ),
    );
  }

  Widget _buildSleepSummaryCard() {
    if (_isSleepWidgetLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: SummaryCard(
          margin: EdgeInsets.symmetric(vertical: 4.0),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading sleep...'),
              ],
            ),
          ),
        ),
      );
    }
    final overview = _sleepOverview;
    if (overview == null) {
      return const SizedBox.shrink();
    }
    final durationText = _formatSleepDuration(overview.totalSleepDuration);
    final score = overview.analysis.score;
    final scoreText = score == null ? '--' : score.round().toString();
    return SummaryCard(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      onTap: () => SleepNavigation.openDayForDate(context, _selectedDate),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.sleepSectionTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppLocalizations.of(context)!.durationLabel}: $durationText',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppLocalizations.of(context)!.sleepHubScoreLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  scoreText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatSleepDuration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildMealCard(
    String title,
    String mealKey,
    List<TrackedFoodItem> items,
    _MealMacros macros,
    AppLocalizations l10n,
  ) {
    final isOpen = _mealExpanded[mealKey] ?? false;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge; // Inter, fett wie im Rest

    return SummaryCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Tippen toggelt)
          InkWell(
            onTap: () => setState(() {
              _mealExpanded[mealKey] = !isOpen;
            }),
            child: Row(
              children: [
                Expanded(child: Text(title, style: titleStyle)),
                Icon(isOpen ? Icons.expand_less : Icons.expand_more),
                const SizedBox(width: 4),
                if (Provider.of<ThemeService>(context).isAiEnabled)
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_rounded),
                    color: theme.colorScheme.tertiary,
                    iconSize: 20,
                    onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => AiRecommendationScreen(
                            mealType: mealKey,
                            date: _selectedDate,
                          ),
                        ),
                      );
                      if (result == true) loadDataForDate(_selectedDate);
                    },
                    tooltip: 'AI Recommend',
                  ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: theme.colorScheme.primary,
                  onPressed: () => _addFoodToMeal(mealKey),
                  tooltip: l10n.addFoodOption,
                ),
              ],
            ),
          ),

          // <<< NEU: Makro-Zeile unter dem Titel (eigene Zeile, linksbündig)
          if (items.isNotEmpty) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${macros.calories} kcal · '
                '${macros.protein}g P · '
                '${macros.carbs}g C · '
                '${macros.fat}g F',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // Inhalt (animiert ein-/ausklappen)
          AnimatedCrossFade(
            crossFadeState:
                isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 180),
            firstChild: Column(
              children: [
                if (items.isNotEmpty) const Divider(height: 16),
                ...items.map((item) => _buildFoodEntryTile(l10n, item)),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
  // lib/screens/diary_screen.dart
  // In lib/screens/diary_screen.dart

  Future<void> _showAddFluidMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final key = GlobalKey<FluidDialogContentState>();

    await showGlassBottomMenu(
      context: context,
      title: l10n.add_liquid_title,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FluidDialogContent(
              key: key,
              initialTimestamp: _selectedDate, // <--- FIX: Datum übergeben
            ),
            const SizedBox(height: 12),
            // ... (Rest der Methode bleibt gleich: Buttons Row etc.)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: close,
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final state = key.currentState;
                      if (state == null) return;
                      final quantity = int.tryParse(state.quantityText);
                      if (quantity == null || quantity <= 0) return;

                      final name = state.nameText;
                      final sugarPer100ml = double.tryParse(
                        state.sugarText.replaceAll(',', '.'),
                      );
                      final caffeinePer100ml = double.tryParse(
                        state.caffeineText.replaceAll(',', '.'),
                      );
                      final kcal = (sugarPer100ml != null)
                          ? ((sugarPer100ml / 100) * quantity * 4).round()
                          : null;

                      final newEntry = FluidEntry(
                        timestamp: state
                            .selectedDateTime, // Das ist jetzt korrekt initialisiert
                        quantityInMl: quantity,
                        name: name,
                        kcal: kcal,
                        sugarPer100ml: sugarPer100ml,
                        carbsPer100ml: sugarPer100ml,
                        caffeinePer100ml: caffeinePer100ml,
                      );

                      final newId = await DatabaseHelper.instance
                          .insertFluidEntry(newEntry);

                      if (caffeinePer100ml != null && caffeinePer100ml > 0) {
                        final totalCaffeine =
                            (caffeinePer100ml / 100.0) * quantity;
                        await _logCaffeineDose(
                          totalCaffeine,
                          state.selectedDateTime,
                          fluidEntryId: newId,
                        );
                      }

                      close();
                      loadDataForDate(_selectedDate);
                    },
                    child: Text(l10n.add_button),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodaysLog(AppLocalizations l10n) {
    const mealOrder = [
      "fluids", // AN ERSTER STELLE
      "mealtypeBreakfast",
      "mealtypeLunch",
      "mealtypeDinner",
      "mealtypeSnack",
    ];

    return Column(
      children: [
        ...mealOrder.map((mealKey) {
          if (mealKey == "fluids") {
            return _buildFluidsCard(l10n);
          }

          final entries = _entriesByMeal[mealKey] ?? [];
          final mealMacros = _MealMacros();
          for (var item in entries) {
            final factor = item.entry.quantityInGrams / 100.0;
            mealMacros.calories += (item.item.calories * factor).round();
            mealMacros.protein += (item.item.protein * factor).round();
            mealMacros.carbs += (item.item.carbs * factor).round();
            mealMacros.fat += (item.item.fat * factor).round();
          }

          return _buildMealCard(
            _getLocalizedMealName(l10n, mealKey),
            mealKey,
            entries,
            mealMacros,
            l10n,
          );
        }),
      ],
    );
  }

  Widget _buildFluidsCard(AppLocalizations l10n) {
    final isOpen = _mealExpanded['fluids'] ?? false;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge;

    return SummaryCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() {
              _mealExpanded['fluids'] = !isOpen;
            }),
            child: Row(
              children: [
                Icon(
                  Icons.local_drink_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.waterHeader, style: titleStyle)),
                Icon(isOpen ? Icons.expand_less : Icons.expand_more),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: theme.colorScheme.primary,
                  onPressed: _showAddFluidMenu,
                  tooltip: l10n.addLiquidOption,
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            crossFadeState:
                isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 180),
            firstChild: Column(
              children: [
                if (_fluidEntries.isNotEmpty) const Divider(height: 16),
                ..._fluidEntries.map(
                  (entry) => _buildFluidEntryTile(l10n, entry),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFluidEntryTile(AppLocalizations l10n, FluidEntry entry) {
    final totalSugar = (entry.sugarPer100ml != null)
        ? (entry.sugarPer100ml! / 100 * entry.quantityInMl).toStringAsFixed(1)
        : '0';
    final totalCaffeine = (entry.caffeinePer100ml != null)
        ? (entry.caffeinePer100ml! / 100 * entry.quantityInMl).toStringAsFixed(
            1,
          )
        : '0';

    return Dismissible(
      key: Key('fluid_entry_${entry.id}'),
      background: const SwipeActionBackground(
        color: Colors.redAccent,
        icon: Icons.delete,
        alignment: Alignment.centerRight,
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // NEU: Helper
        return await showDeleteConfirmation(context);
      },
      onDismissed: (direction) {
        _deleteFluidEntry(entry.id!);
      },
      child: SummaryCard(
        child: ListTile(
          title: Text(entry.name),
          subtitle: Text(
            "${entry.quantityInMl}ml · Sugar: ${totalSugar}g · Caffeine: ${totalCaffeine}mg",
          ),
          trailing: Text("${entry.kcal ?? 0} kcal"),
        ),
      ),
    );
  }

  Widget _buildFoodEntryTile(
    AppLocalizations l10n,
    TrackedFoodItem trackedItem,
  ) {
    return Dismissible(
      key: Key('food_hub_entry_${trackedItem.entry.id}'),
      background: const SwipeActionBackground(
        color: Colors.blueAccent,
        icon: Icons.edit,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const SwipeActionBackground(
        color: Colors.redAccent,
        icon: Icons.delete,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _editFoodEntry(trackedItem);
          return false;
        } else {
          // NEU: Helper
          return await showDeleteConfirmation(context);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteFoodEntry(trackedItem.entry.id!);
        }
      },
      child: SummaryCard(
        child: ListTile(
          title: Text(trackedItem.item.name),
          subtitle: Text("${trackedItem.entry.quantityInGrams}g"),
          trailing: Text("${trackedItem.calculatedCalories} kcal"),
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) =>
                        FoodDetailScreen(trackedItem: trackedItem),
                  ),
                )
                .then((_) => loadDataForDate(_selectedDate));
          },
        ),
      ),
    );
  }

  String _getLocalizedMealName(AppLocalizations l10n, String key) {
    switch (key) {
      case "mealtypeBreakfast":
        return l10n.mealtypeBreakfast;
      case "mealtypeLunch":
        return l10n.mealtypeLunch;
      case "mealtypeDinner":
        return l10n.mealtypeDinner;
      case "mealtypeSnack":
        return l10n.mealtypeSnack;
      default:
        return key;
    }
  }
}

class _MealMacros {
  int calories = 0;
  int protein = 0;
  int carbs = 0;
  int fat = 0;
}

class DiaryAppBar extends StatelessWidget {
  final ValueNotifier<DateTime>? selectedDateNotifier;
  const DiaryAppBar({super.key, required this.selectedDateNotifier});

  String _getAppBarTitle(
    BuildContext context,
    AppLocalizations l10n,
    DateTime selectedDate,
  ) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBeforeYesterday = today.subtract(const Duration(days: 2));

    if (selectedDate.isSameDate(today)) {
      return l10n.today;
    } else if (selectedDate.isSameDate(yesterday)) {
      return l10n.yesterday; // ← NEW
    } else if (selectedDate.isSameDate(dayBeforeYesterday)) {
      return l10n.dayBeforeYesterday; // ← NEW
    } else {
      return DateFormat.yMMMMd(
        Localizations.localeOf(context).toString(),
      ).format(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Gracefully handle the case where the notifier might be null during the first frame
    if (selectedDateNotifier == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          l10n.today, // Default to 'Today'
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      );
    }

    return ValueListenableBuilder<DateTime>(
      valueListenable: selectedDateNotifier!,
      builder: (context, selectedDate, child) {
        final title = _getAppBarTitle(context, l10n, selectedDate);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        );
      },
    );
  }
}
