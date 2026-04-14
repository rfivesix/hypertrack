// lib/screens/nutrition_screen.dart (Final & De-Materialisiert - Endgültige Korrektur)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dialogs/fluid_dialog_content.dart';
import '../models/fluid_entry.dart';
import '../models/supplement.dart';
import '../models/supplement_log.dart';
import '../util/design_constants.dart';
import '../widgets/glass_bottom_menu.dart';
import '../widgets/swipe_action_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../data/product_database_helper.dart';
import '../generated/app_localizations.dart';
import '../dialogs/quantity_dialog_content.dart';
import '../models/daily_nutrition.dart';
import '../models/food_entry.dart';
import '../models/tracked_food_item.dart';
import '../models/timeline_entry.dart';
import '../services/ui_state_service.dart';
import '../widgets/nutrition_summary_widget.dart';
import '../widgets/summary_card.dart';
import './food_detail_screen.dart';
import '../util/date_util.dart';

/// A screen for detailed nutrition logging and daily summaries.
///
/// Shows a breakdown of macronutrient and micronutrient intake,
/// water consumption, and caffeine logs over various time ranges.
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class FluidTimelineEntry extends TimelineEntry {
  final FluidEntry fluidEntry;

  FluidTimelineEntry(this.fluidEntry);

  @override
  DateTime get timestamp => fluidEntry.timestamp;
}

class _NutritionScreenState extends State<NutritionScreen> {
  DailyNutrition? _nutritionData;
  List<dynamic> _displayItems = [];
  bool _isLoading = true;
  DateTimeRange _selectedDateRange = DateTime.now().isSameDate(DateTime.now())
      ? DateTimeRange(
          start: DateTime.now(),
          end: DateTime.now(),
        ) // Einzeltag für heute
      : DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 6)),
          end: DateTime.now(),
        ); // Standard: Letzte 7 Tage
  bool _isSummaryExpanded = UiStateService.instance.isNutritionSummaryExpanded;
  String _selectedRangeKey = '1D';
  bool _isHeaderVisible = true;

  @override
  void initState() {
    super.initState();
    _loadEntriesForDateRange(_selectedDateRange);
  }

  Future<void> _loadEntriesForDateRange(DateTimeRange range) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final dbHelper = DatabaseHelper.instance;
    // Calculate exact sum of historical daily goals
    int targetCalories = 0;
    int targetProtein = 0;
    int targetCarbs = 0;
    int targetFat = 0;
    int targetWater = 0;

    for (int i = 0; i <= range.duration.inDays; i++) {
      final d = range.start.add(Duration(days: i));
      final goals = await dbHelper.getGoalsForDate(d);
      targetCalories += goals?.targetCalories ?? 2500;
      targetProtein += goals?.targetProtein ?? 180;
      targetCarbs += goals?.targetCarbs ?? 250;
      targetFat += goals?.targetFat ?? 80;
      targetWater += goals?.targetWater ?? 3000;
    }

    final prefs = await SharedPreferences.getInstance();
    final targetSugar = prefs.getInt('targetSugar') ?? 50;
    final targetFiber = prefs.getInt('targetFiber') ?? 30;
    final targetSalt = prefs.getInt('targetSalt') ?? 6;
    final foodEntries = await DatabaseHelper.instance.getEntriesForDateRange(
      range.start,
      range.end,
    );
    final fluidEntries = await DatabaseHelper.instance
        .getFluidEntriesForDateRange(range.start, range.end);
    final supplementLogs = await DatabaseHelper.instance
        .getAllSupplementLogs(); // Annahme: Methode existiert
    final supplements = await DatabaseHelper.instance.getAllSupplements();

    final caffeineSupplementId =
        supplements.firstWhere((s) => s.code == 'caffeine').id;

    final numberOfDays = range.duration.inDays + 1;
    final newNutritionSummary = DailyNutrition(
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetCarbs: targetCarbs,
      targetFat: targetFat,
      targetWater: targetWater,
      targetSugar: targetSugar * numberOfDays,
      targetFiber: targetFiber * numberOfDays,
      targetSalt: targetSalt * numberOfDays,
    );

    final List<FoodTimelineEntry> foodTimeline = [];
    for (final entry in foodEntries) {
      final foodItem = await ProductDatabaseHelper.instance.getProductByBarcode(
        entry.barcode,
      );
      if (foodItem != null) {
        final factor = entry.quantityInGrams / 100.0;
        newNutritionSummary.calories += (foodItem.calories * factor).round();
        newNutritionSummary.protein += (foodItem.protein * factor).round();
        newNutritionSummary.carbs += (foodItem.carbs * factor).round();
        newNutritionSummary.fat += (foodItem.fat * factor).round();
        newNutritionSummary.sugar += (foodItem.sugar ?? 0) * factor;
        newNutritionSummary.fiber += (foodItem.fiber ?? 0) * factor;
        newNutritionSummary.salt += (foodItem.salt ?? 0) * factor;
        foodTimeline.add(
          FoodTimelineEntry(TrackedFoodItem(entry: entry, item: foodItem)),
        );
      }
    }

    // *** KORREKTURBLOCK START ***
    // Nährwerte aus Flüssigkeiten zur Summe addieren
    newNutritionSummary.water = fluidEntries.fold(
      0,
      (sum, entry) => sum + entry.quantityInMl,
    );
    for (final entry in fluidEntries) {
      final factor = entry.quantityInMl / 100.0;
      newNutritionSummary.calories += entry.kcal ?? 0;
      newNutritionSummary.carbs +=
          ((entry.carbsPer100ml ?? 0) * factor).round();
      newNutritionSummary.sugar += (entry.sugarPer100ml ?? 0) * factor;
    }

    // Koffein aus Supplement-Logs berechnen
    if (caffeineSupplementId != null) {
      final relevantLogs = supplementLogs.where(
        (log) =>
            log.supplementId == caffeineSupplementId &&
            log.timestamp.isAfter(range.start) &&
            log.timestamp.isBefore(range.end),
      );
      newNutritionSummary.caffeine = relevantLogs.fold(
        0.0,
        (sum, log) => sum + log.dose,
      );
    }

    final fluidTimeline =
        fluidEntries.map((e) => FluidTimelineEntry(e)).toList();
    // *** KORREKTURBLOCK ENDE ***

    final List<dynamic> finalDisplayList = [];

    if (range.duration.inDays == 0) {
      // ... (Rest der Methode bleibt unverändert)
      final Map<String, List<FoodTimelineEntry>> groupedFood = {};
      for (final entry in foodTimeline) {
        final mealType = entry.trackedItem.entry.mealType;
        if (groupedFood.containsKey(mealType)) {
          groupedFood[mealType]!.add(entry);
        } else {
          groupedFood[mealType] = [entry];
        }
      }

      const mealOrder = [
        "mealtypeBreakfast",
        "mealtypeLunch",
        "mealtypeDinner",
        "mealtypeSnack",
      ];
      for (final mealKey in mealOrder) {
        if (groupedFood.containsKey(mealKey)) {
          finalDisplayList.add(mealKey);
          groupedFood[mealKey]!.sort(
            (a, b) => b.timestamp.compareTo(a.timestamp),
          );
          finalDisplayList.addAll(groupedFood[mealKey]!);
        }
      }

      if (fluidTimeline.isNotEmpty) {
        finalDisplayList.add("fluidsHeader");
        fluidTimeline.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        finalDisplayList.addAll(fluidTimeline);
      }
    } else {
      final List<TimelineEntry> combinedList = [
        ...foodTimeline,
        ...fluidTimeline,
      ];
      combinedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      DateTime? lastDate;
      for (final entry in combinedList) {
        final entryDate = entry.timestamp;
        if (lastDate == null || !entryDate.isSameDate(lastDate)) {
          finalDisplayList.add(entryDate);
          lastDate = entryDate;
        }
        finalDisplayList.add(entry);
      }
    }

    if (mounted) {
      setState(() {
        _nutritionData = newNutritionSummary;
        _displayItems = finalDisplayList;
        _isLoading = false;
      });
    }
  }

  void _navigateDay(bool forward) {
    final currentDay = _selectedDateRange.start;
    final newDay = currentDay.add(Duration(days: forward ? 1 : -1));
    // Navigation über den heutigen Tag hinaus verhindern
    if (forward && newDay.isAfter(DateTime.now())) return;

    setState(() {
      _selectedDateRange = DateTimeRange(start: newDay, end: newDay);
      _selectedRangeKey = 'custom'; // De-selektiert die Filter-Chips
    });
    _loadEntriesForDateRange(_selectedDateRange);
  }

  Future<void> _setTimeRange(String key) async {
    setState(() => _selectedRangeKey = key);
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (key) {
      case '1W':
        start = now.subtract(const Duration(days: 6));
        break;
      case '1M':
        start = now.subtract(const Duration(days: 29));
        break;
      case 'All':
        final earliest =
            await DatabaseHelper.instance.getEarliestFoodEntryDate();
        start = earliest ?? now;
        break;
      case '1D':
      default:
        start = now;
    }

    final normalizedStart = DateTime(start.year, start.month, start.day);
    setState(
      () =>
          _selectedDateRange = DateTimeRange(start: normalizedStart, end: end),
    );
    _loadEntriesForDateRange(_selectedDateRange);
  }

  Future<void> _deleteFoodEntry(int id) async {
    await DatabaseHelper.instance.deleteFoodEntry(id);
    _loadEntriesForDateRange(_selectedDateRange);
  }

  Future<void> _deleteFluidEntry(int id) async {
    await DatabaseHelper.instance.deleteFluidEntry(id);
    _loadEntriesForDateRange(_selectedDateRange);
  }

  Future<void> _editFoodEntry(TrackedFoodItem trackedItem) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();

    final result = await showGlassBottomMenu<(int, DateTime, String, double?)?>(
      context: context,
      title: trackedItem.item.name,
      contentBuilder: (ctx, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuantityDialogContent(
            key: dialogStateKey,
            item: trackedItem.item,
            initialQuantity: trackedItem.entry.quantityInGrams,
            initialTimestamp: trackedItem.entry.timestamp,
            initialMealType: trackedItem.entry.mealType,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
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
                      if (quantity != null && quantity > 0) {
                        Navigator.of(ctx).pop((
                          quantity,
                          state.selectedDateTime,
                          state.selectedMealType,
                          double.tryParse(
                            state.caffeineText.replaceAll(',', '.'),
                          ),
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
      ),
    );

    if (result != null) {
      final updatedEntry = FoodEntry(
        id: trackedItem.entry.id,
        barcode: trackedItem.item.barcode,
        quantityInGrams: result.$1,
        timestamp: result.$2,
        mealType: result.$3,
      );
      await DatabaseHelper.instance.updateFoodEntry(updatedEntry);
      _loadEntriesForDateRange(_selectedDateRange);
    }
  }

  Future<void> _editFluidEntry(FluidEntry fluidEntry) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<FluidDialogContentState> dialogStateKey = GlobalKey();

    final result = await showGlassBottomMenu<(String, int, double?, double?)?>(
      context: context,
      title: l10n.waterEntryTitle,
      contentBuilder: (ctx, close) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FluidDialogContent(
            key: dialogStateKey,
            initialName: fluidEntry.name,
            initialQuantity: fluidEntry.quantityInMl,
            initialTimestamp: fluidEntry.timestamp,
            initialSugar: fluidEntry.sugarPer100ml,
            initialCaffeine: fluidEntry.caffeinePer100ml,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
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
                      if (quantity != null && quantity > 0) {
                        Navigator.of(ctx).pop((
                          state.nameText,
                          quantity,
                          double.tryParse(state.sugarText.replaceAll(',', '.')),
                          double.tryParse(
                            state.caffeineText.replaceAll(',', '.'),
                          ),
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
      ),
    );

    if (result != null) {
      final sugarPer100ml = result.$3;
      final quantity = result.$2;
      final kcal = (sugarPer100ml != null)
          ? ((sugarPer100ml / 100) * quantity * 4).round()
          : null;

      final updatedEntry = FluidEntry(
        id: fluidEntry.id,
        name: result.$1,
        quantityInMl: quantity,
        kcal: kcal,
        sugarPer100ml: sugarPer100ml,
        carbsPer100ml: sugarPer100ml, // Spiegeln
        caffeinePer100ml: result.$4,
        timestamp: fluidEntry.timestamp,
        linked_food_entry_id:
            fluidEntry.linked_food_entry_id, // Wichtig: beibehalten
      );
      await DatabaseHelper.instance.updateFluidEntry(updatedEntry);

      // Koffein-Log aktualisieren/löschen
      await _logCaffeineDose(
        (result.$4 ?? 0) * (quantity / 100.0),
        fluidEntry.timestamp,
        fluidEntryId: fluidEntry.id,
      );

      _loadEntriesForDateRange(_selectedDateRange);
    }
  }

  // FÜGE DIE FEHLENDE LOGIK FÜR KOFFEIN HINZU (falls nicht vorhanden)
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();

    final rangeText = _selectedDateRange.duration.inDays == 0
        ? DateFormat.yMMMMd(locale).format(_selectedDateRange.start)
        : "${DateFormat.yMMMMd(locale).format(_selectedDateRange.start)} - ${DateFormat.yMMMMd(locale).format(_selectedDateRange.end)}";

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          l10n.nutritionScreenTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: true,
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 0.0,
                    ),
                    //padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //SizedBox(height: DesignConstants.spacingL), // <- DIESE ZEILE
                        //SizedBox(height: DesignConstants.spacingXL),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => _navigateDay(false),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    initialDateRange: _selectedDateRange,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedDateRange = picked;
                                      _selectedRangeKey = 'custom';
                                    });
                                    _loadEntriesForDateRange(picked);
                                  }
                                },
                                child: Text(
                                  rangeText,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _selectedDateRange.end.isSameDate(
                                DateTime.now(),
                              )
                                  ? null
                                  : () => _navigateDay(true),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignConstants.spacingL),
                        Row(
                          children: [
                            _buildFilterButton(l10n.filterToday, '1D'),
                            _buildFilterButton(l10n.filter7Days, '1W'),
                            _buildFilterButton(l10n.filter30Days, '1M'),
                            _buildFilterButton(l10n.filterAll, 'All'),
                          ],
                        ),
                        const SizedBox(
                          height: DesignConstants.spacingL,
                        ), // <- DIESE ZEILE
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.1),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isHeaderVisible
                      ? Column(
                          children: [
                            if (_nutritionData != null)
                              Column(
                                children: [
                                  // KORREKTUR: NutritionSummaryWidget in einem Padding, das dem horizontalen ListView-Padding entspricht.
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ), // <- Dieser Padding ist wichtig!
                                    child: NutritionSummaryWidget(
                                      nutritionData: _nutritionData!,
                                      isExpandedView: _isSummaryExpanded,
                                      l10n: l10n,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _isSummaryExpanded =
                                                !_isSummaryExpanded;
                                            UiStateService.instance
                                                    .isNutritionSummaryExpanded =
                                                _isSummaryExpanded;
                                          });
                                        },
                                        child: Text(
                                          _isSummaryExpanded
                                              ? l10n.showLess
                                              : l10n.showMoreDetails,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => setState(
                                          () => _isHeaderVisible = false,
                                        ),
                                        child: Text(l10n.hideSummary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _isHeaderVisible = true),
                              child: Text(l10n.showSummary),
                            ),
                          ),
                        ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.1),
                ),
                Expanded(
                  child: _displayItems.isEmpty
                      ? Center(child: Text(l10n.noEntriesForPeriod))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          itemCount: _displayItems.length,
                          separatorBuilder: (context, index) => const SizedBox(
                            height: DesignConstants.spacingM,
                          ), // KORREKTUR: Trenner
                          itemBuilder: (context, index) {
                            final item = _displayItems[index];

                            String getLocalizedMealName(String key) {
                              switch (key) {
                                case "mealtypeBreakfast":
                                  return l10n.mealtypeBreakfast;
                                case "mealtypeLunch":
                                  return l10n.mealtypeLunch;
                                case "mealtypeDinner":
                                  return l10n.mealtypeDinner;
                                case "mealtypeSnack":
                                  return l10n.mealtypeSnack;
                                case "fluidsHeader":
                                  return l10n.waterHeader;
                                default:
                                  return key;
                              }
                            }

                            if (item is DateTime) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 24.0,
                                  bottom: 8.0,
                                  left: 8.0,
                                ),
                                child: Text(
                                  DateFormat.yMMMMEEEEd(locale).format(item),
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              );
                            }

                            if (item is String) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 24.0,
                                  bottom: 8.0,
                                  left: 8.0,
                                ),
                                child: Text(
                                  getLocalizedMealName(item),
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }

                            // In lib/screens/nutrition_screen.dart (innerhalb von ListView.separated -> itemBuilder)

                            if (item is FoodTimelineEntry) {
                              final trackedItem = item.trackedItem;
                              return Dismissible(
                                key: Key('food_${trackedItem.entry.id}'),
                                direction: DismissDirection.horizontal,
                                background: const SwipeActionBackground(
                                  color: Colors.blueAccent,
                                  icon: Icons.edit,
                                  alignment: Alignment.centerLeft,
                                ),
                                secondaryBackground:
                                    const SwipeActionBackground(
                                  color: Colors.redAccent,
                                  icon: Icons.delete,
                                  alignment: Alignment.centerRight,
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.startToEnd) {
                                    _editFoodEntry(trackedItem);
                                    return false;
                                  } else {
                                    // NEU: Verwendung der Helper-Funktion
                                    return await showDeleteConfirmation(
                                      context,
                                    );
                                  }
                                },
                                onDismissed: (direction) {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    _deleteFoodEntry(trackedItem.entry.id!);
                                  }
                                },
                                child: SummaryCard(
                                  child: ListTile(
                                    leading: const Icon(Icons.restaurant),
                                    title: Text(trackedItem.item.name),
                                    subtitle: Text(
                                      l10n.foodListSubtitle(
                                        trackedItem.entry.quantityInGrams,
                                        DateFormat.Hm(
                                          locale,
                                        ).format(trackedItem.entry.timestamp),
                                      ),
                                    ),
                                    trailing: Text(
                                      l10n.foodListTrailingKcal(
                                        trackedItem.calculatedCalories,
                                      ),
                                    ),
                                    onTap: () => Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FoodDetailScreen(
                                              trackedItem: trackedItem,
                                            ),
                                          ),
                                        )
                                        .then(
                                          (_) => _loadEntriesForDateRange(
                                            _selectedDateRange,
                                          ),
                                        ),
                                  ),
                                ),
                              );
                            }

                            if (item is FluidTimelineEntry) {
                              final fluidEntry = item.fluidEntry;
                              return Dismissible(
                                key: Key('fluid_${fluidEntry.id}'),
                                direction: DismissDirection.horizontal,
                                background: const SwipeActionBackground(
                                  color: Colors.blueAccent,
                                  icon: Icons.edit,
                                  alignment: Alignment.centerLeft,
                                ),
                                secondaryBackground:
                                    const SwipeActionBackground(
                                  color: Colors.redAccent,
                                  icon: Icons.delete,
                                  alignment: Alignment.centerRight,
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.startToEnd) {
                                    _editFluidEntry(fluidEntry);
                                    return false;
                                  } else {
                                    // NEU: Verwendung der Helper-Funktion
                                    return await showDeleteConfirmation(
                                      context,
                                    );
                                  }
                                },
                                onDismissed: (direction) {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    _deleteFluidEntry(fluidEntry.id!);
                                  }
                                },
                                child: SummaryCard(
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.local_drink,
                                      color: colorScheme.primary,
                                    ),
                                    title: Text(fluidEntry.name),
                                    subtitle: Text(
                                      DateFormat.Hm(
                                        locale,
                                      ).format(fluidEntry.timestamp),
                                    ),
                                    trailing: Text(
                                      l10n.waterListTrailingMl(
                                        fluidEntry.quantityInMl,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (item is FluidTimelineEntry) {
                              final fluidEntry = item.fluidEntry;
                              return Dismissible(
                                key: Key('fluid_${fluidEntry.id}'),
                                direction: DismissDirection.horizontal,
                                background: const SwipeActionBackground(
                                  color: Colors.blueAccent,
                                  icon: Icons.edit,
                                  alignment: Alignment.centerLeft,
                                ),
                                secondaryBackground:
                                    const SwipeActionBackground(
                                  color: Colors.redAccent,
                                  icon: Icons.delete,
                                  alignment: Alignment.centerRight,
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.startToEnd) {
                                    _editFluidEntry(fluidEntry);
                                    return false;
                                  } else {
                                    return await showDeleteConfirmation(
                                      context,
                                    );
                                  }
                                },
                                onDismissed: (direction) {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    _deleteFluidEntry(fluidEntry.id!);
                                  }
                                },
                                child: SummaryCard(
                                  //externalMargin: EdgeInsets.zero,
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.local_drink,
                                      color: colorScheme.primary,
                                    ),
                                    title: Text(fluidEntry.name),
                                    subtitle: Text(
                                      DateFormat.Hm(
                                        locale,
                                      ).format(fluidEntry.timestamp),
                                    ),
                                    trailing: Text(
                                      l10n.waterListTrailingMl(
                                        fluidEntry.quantityInMl,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                ),
              ],
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String key) {
    final theme = Theme.of(context);
    final isSelected = _selectedRangeKey == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setTimeRange(key),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
