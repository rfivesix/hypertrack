import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/database_helper.dart';
import 'dialogs/fluid_dialog_content.dart';
import 'dialogs/quantity_dialog_content.dart';
import '../../../generated/app_localizations.dart';
import '../domain/repositories/diary_repository.dart';
import '../../supplements/domain/repositories/supplement_repository.dart';
import '../../workout/domain/repositories/workout_repository.dart';
import '../domain/models/fluid_entry.dart';
import '../domain/models/food_entry.dart';
import '../domain/models/food_item.dart';
import '../domain/models/tracked_food_item.dart';
import 'add_food_screen.dart';
import 'add_food_navigation_result.dart';
import '../../supplements/presentation/supplement_track_screen.dart';
import '../../../util/date_util.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'widgets/nutrition_summary_widget.dart';
import '../../supplements/presentation/widgets/supplement_summary_widget.dart';
import '../../../widgets/common/macro_badge_row.dart';
import 'diary_view_model.dart';
import '../../../services/theme_service.dart';
import '../../workout/presentation/workout_history_screen.dart';
import '../../workout/presentation/widgets/todays_workout_summary_card.dart';
import 'widgets/weight_chart_card.dart';
import 'widgets/steps_summary_card.dart';
import 'widgets/sleep_summary_card.dart';
import 'widgets/pulse_summary_card.dart';
import 'widgets/food_entry_tile.dart';
import 'widgets/fluid_entry_tile.dart';

/// The central hub for tracking and viewing daily nutritional and activity data.
///
/// Displays a comprehensive overview of calories, macros, supplements, and workouts
/// for a selected date. Allows users to manage food entries, fluid intake, and
/// view historical measurements like weight.
class DiaryScreen extends StatelessWidget {
  final DateTime? initialDate;
  final GlobalKey<DiaryScreenState>? contentKey;

  const DiaryScreen({super.key, this.initialDate, this.contentKey});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DiaryViewModel(
        nutritionRepo: context.read<IDiaryRepository>(),
        supplementRepo: context.read<SupplementRepository>(),
        workoutRepo: context.read<IWorkoutRepository>(),
        initialDate: initialDate,
      ),
      child: _DiaryScreenContent(key: contentKey ?? key),
    );
  }
}

class _DiaryScreenContent extends StatefulWidget {
  const _DiaryScreenContent({super.key});

  @override
  State<_DiaryScreenContent> createState() => DiaryScreenState();
}

class DiaryScreenState extends State<_DiaryScreenContent> {
  DiaryViewModel get viewModel => context.read<DiaryViewModel>();
  ValueNotifier<DateTime> get selectedDateNotifier =>
      viewModel.selectedDateNotifier;

  void setSelectedDate(DateTime date) {
    context.read<DiaryViewModel>().setSelectedDate(date);
  }

  Future<void> syncHealthData({bool forceStepsRefresh = false}) async {
    await context
        .read<DiaryViewModel>()
        .syncHealthData(forceStepsRefresh: forceStepsRefresh);
  }

  @Deprecated('Use setSelectedDate or syncHealthData instead')
  Future<void> loadDataForDate(DateTime date,
      {bool queueIfInFlight = false, bool forceStepsRefresh = false}) async {
    setSelectedDate(date);
    if (forceStepsRefresh) {
      await syncHealthData(forceStepsRefresh: true);
    }
  }

  final Map<String, bool> _mealExpanded = {
    "mealtypeBreakfast": false,
    "mealtypeLunch": false,
    "mealtypeDinner": false,
    "mealtypeSnack": false,
    "fluids": false,
  };

  Future<void> _deleteFoodEntry(int id) async {
    final viewModel = context.read<DiaryViewModel>();
    await viewModel.deleteFoodEntry(id);
  }

  Future<void> _deleteFluidEntry(int id) async {
    final viewModel = context.read<DiaryViewModel>();
    await viewModel.deleteFluidEntry(id);
  }

  Future<void> _editFluidEntry(FluidEntry entry) async {
    if (entry.linkedFoodEntryId != null) {
      TrackedFoodItem? trackedItem;
      // Search in all meals for the linked food entry
      for (var mealList in viewModel.entriesByMeal.values) {
        for (var item in mealList) {
          if (item.entry.id == entry.linkedFoodEntryId) {
            trackedItem = item;
            break;
          }
        }
        if (trackedItem != null) break;
      }

      if (trackedItem != null) {
        // Reuse the existing food edit logic
        await _editFoodEntry(trackedItem);
        return;
      }
    }

    // Standalone fluid entry edit (e.g. water added via FAB)
    final l10n = AppLocalizations.of(context)!;
    final key = GlobalKey<FluidDialogContentState>();

    await showGlassBottomMenu(
      context: context,
      title: l10n.add_liquid_title, // Reuse the same title or similar
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FluidDialogContent(
              key: key,
              initialQuantity: entry.quantityInMl,
              initialTimestamp: entry.timestamp,
              initialName: entry.name,
              initialSugar: entry.sugarPer100ml,
              initialCaffeine: entry.caffeinePer100ml,
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
                    onPressed: () async {
                      final vm = viewModel;
                      final state = key.currentState;
                      if (state == null) return;
                      final quantity = int.tryParse(state.quantityText);
                      if (quantity == null || quantity <= 0) return;

                      final name = state.nameText;
                      final sugar = double.tryParse(
                        state.sugarText.replaceAll(',', '.'),
                      );
                      final caffeine = double.tryParse(
                        state.caffeineText.replaceAll(',', '.'),
                      );
                      final kcal = (sugar != null)
                          ? ((sugar / 100) * quantity * 4).round()
                          : null;

                      final updated = FluidEntry(
                        id: entry.id,
                        timestamp: state.selectedDateTime,
                        quantityInMl: quantity,
                        name: name,
                        kcal: kcal,
                        sugarPer100ml: sugar,
                        carbsPer100ml: sugar,
                        caffeinePer100ml: caffeine,
                        linkedFoodEntryId: entry.linkedFoodEntryId,
                      );

                      try {
                        await vm.updateFluidEntry(updated);

                        // Update caffeine dose
                        await vm.logCaffeineDose(
                          (caffeine ?? 0) * (quantity / 100.0),
                          state.selectedDateTime,
                          fluidEntryId: entry.id,
                        );

                        close();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.error)),
                        );
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
  }

  Future<void> _editFoodEntry(TrackedFoodItem trackedItem) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();
    final vm = viewModel;

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
        final linkedFluid = vm.fluidEntries
            .where((f) => f.linkedFoodEntryId == trackedItem.entry.id)
            .firstOrNull;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog content, now used as bottom-sheet content
            QuantityDialogContent(
              key: dialogStateKey,
              item: trackedItem.item,
              initialQuantity: trackedItem.entry.quantityInGrams,
              initialTimestamp: trackedItem.entry.timestamp,
              initialMealType: trackedItem.entry.mealType,
              initialIsLiquid: linkedFluid != null ? true : null,
              initialSugar: linkedFluid?.sugarPer100ml,
              initialCaffeine: linkedFluid?.caffeinePer100ml,
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
                          // Return the correct anonymous tuple here.
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

    // Continue processing the result data.
    if (result != null) {
      if (!mounted) return;
      final updatedEntry = FoodEntry(
        id: trackedItem.entry.id,
        barcode: trackedItem.item.barcode,
        quantityInGrams: result.quantity,
        timestamp: result.timestamp,
        mealType: result.mealType,
      );
      await vm.updateFoodEntry(updatedEntry);

      // 1. Delete FluidEntry if linked.
      if (trackedItem.entry.id != null) {
        await vm.deleteFluidEntryByLinkedFoodId(
          trackedItem.entry.id!,
        );
      }
      // 2. Recreate FluidEntry if it is now liquid.
      if (result.isLiquid) {
        final newFluidEntry = FluidEntry(
          timestamp: result.timestamp,
          quantityInMl: result.quantity,
          name: trackedItem.item.name,
          kcal: (trackedItem.item.calories / 100 * result.quantity).round(),
          sugarPer100ml: result.sugarPer100ml,
          carbsPer100ml: result.sugarPer100ml, // Spiegeln
          caffeinePer100ml: result.caffeinePer100ml,
          linkedFoodEntryId: trackedItem.entry.id, // Preserve the link
        );
        await vm.insertFluidEntry(newFluidEntry);
      }

      // 3. Update/delete caffeine log in every case.
      await vm.logCaffeineDose(
        (result.caffeinePer100ml ?? 0) * (result.quantity / 100.0),
        result.timestamp,
        foodEntryId: trackedItem.entry.id,
      );
      // No manual reload needed, state is reactive
    }
  }

  Future<void> _addFoodToMeal(String mealType) async {
    final vm = viewModel;
    final routeResult = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) => AddFoodScreen(
          initialDate: vm.selectedDate, // <--- Pass-through
          initialMealType: mealType, // <--- Pass-through
        ),
      ),
    );

    if (!mounted) return;

    final addFoodResult = AddFoodNavigationResult.fromRouteResult(routeResult);
    if (addFoodResult.shouldRefresh) {
      return;
    }

    final selectedFoodItem = addFoodResult.selectedFoodItem;
    if (selectedFoodItem == null) return;

    // FIX: Pass the date to the helper menu.
    final result = await _showQuantityMenu(
      selectedFoodItem,
      mealType,
      initialDate: vm.selectedDate, // <--- Add parameter (see point C)
    );

    if (result == null || !mounted) return;

    // ... (rest of the logic stays the same, uses result.timestamp) ...
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
    final newFoodEntryId = await vm.insertFoodEntry(
      newFoodEntry,
    );

    if (!mounted) return;

    if (isLiquid) {
      final newFluidEntry = FluidEntry(
        timestamp: timestamp,
        quantityInMl: quantity,
        name: selectedFoodItem.name,
        kcal: (selectedFoodItem.calories / 100 * quantity).round(),
        sugarPer100ml: result.sugarPer100ml,
        carbsPer100ml: result.sugarPer100ml,
        caffeinePer100ml: result.caffeinePer100ml,
        linkedFoodEntryId: newFoodEntryId,
      );
      await vm.insertFluidEntry(newFluidEntry);
    }

    if (isLiquid && caffeinePer100 != null && caffeinePer100 > 0) {
      final totalCaffeine = (caffeinePer100 / 100.0) * quantity;
      await vm.logCaffeineDose(
        totalCaffeine,
        timestamp,
        foodEntryId: newFoodEntryId,
      );
    }
  }

  // Add these two new methods to the class.
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
    DateTime? initialDate, // <--- New parameter
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
              initialTimestamp:
                  (initialDate ?? viewModel.selectedDate).withCurrentTime,
            ),
            // ... (rest of the method: buttons, etc. stays the same) ...
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

  Future<void> pickDate() async {
    final viewModel = context.read<DiaryViewModel>();
    final picked = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      viewModel.pickDate(picked);
    }
  }

  void navigateDay(bool forward) {
    context.read<DiaryViewModel>().navigateDay(forward);
  }


  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DiaryViewModel>();
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

    return viewModel.isLoading
        ? const Center(child: CircularProgressIndicator())
         : RefreshIndicator(
            onRefresh: () => syncHealthData(forceStepsRefresh: true),
            child: ListView(
              padding: finalPadding,
              children: [
                AppSectionHeader(title: l10n.today_overview_text),
                if (viewModel.dailyNutrition != null)
                  NutritionSummaryWidget(
                    nutritionData: viewModel.dailyNutrition!,
                    l10n: l10n,
                    isExpandedView: false,
                    showSugarInOverview: viewModel.showSugarInOverview,
                  ),

                const SizedBox(height: DesignConstants.spacingXS),
                SupplementSummaryWidget(
                  trackedSupplements: viewModel.trackedSupplements,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      // FIX #65: Pass date along
                      builder: (context) => SupplementTrackScreen(
                          initialDate: viewModel.selectedDate),
                    ),
                  ),
                ),
                if (viewModel.stepsTrackingEnabled) ...[
                  const StepsSummaryCard()
                ],
                if (viewModel.sleepTrackingEnabled) ...[
                  const SleepSummaryCard()
                ],
                if (viewModel.pulseTrackingEnabled) ...[
                  const PulseSummaryCard()
                ],
                // New section: insert workout summary here.
                if (viewModel.workoutSummary != null) ...[
                  TodaysWorkoutSummaryCard(
                    duration: viewModel.workoutSummary!['duration'] as Duration,
                    volume: viewModel.workoutSummary!['volume'] as double,
                    sets: viewModel.workoutSummary!['sets'] as int,
                    workoutCount: viewModel.workoutSummary!['count'] as int,
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
                AppSectionHeader(title: l10n.protocol_today_capslock),
                _buildTodaysLog(l10n),
                const SizedBox(height: DesignConstants.spacingXL),
                AppSectionHeader(title: l10n.measurementWeightCapslock),
                const WeightChartCard(),
                const BottomContentSpacer(),
              ],
            ),
          );
  }


  // Section headers now use the centralized AppSectionHeader widget.

  Widget _buildMealCard(
    String title,
    String mealKey,
    List<TrackedFoodItem> items,
    _MealMacros macros,
    AppLocalizations l10n,
  ) {
    final isOpen = _mealExpanded[mealKey] ?? false;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium;

    return AppCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (tap toggles)
          InkWell(
            onTap: () => setState(() {
              _mealExpanded[mealKey] = !isOpen;
            }),
            child: Row(
              children: [
                Expanded(child: Text(title, style: titleStyle)),
                Icon(isOpen ? Icons.expand_less : Icons.expand_more),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: theme.colorScheme.primary,
                  onPressed: () => _addFoodToMeal(mealKey),
                  tooltip: l10n.addFoodOption,
                ),
              ],
            ),
          ),

          // <<< New: macro row below the title (own line, left aligned)
          if (items.isNotEmpty) ...[
            const SizedBox(height: 4),
            MacroBadgeRow(
              kcal: macros.calories.round(),
              protein: macros.protein,
              carbs: macros.carbs,
              fat: macros.fat,
              useBadges: context.read<ThemeService>().useColorfulMacroBadges,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // Content (animated expand/collapse)
          AnimatedCrossFade(
            crossFadeState:
                isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: DesignConstants.expandCollapseDuration,
            firstChild: Column(
              children: [
                if (items.isNotEmpty) const Divider(height: 16),
                ...items.map(
                  (item) => FoodEntryTile(
                    trackedItem: item,
                    onEdit: _editFoodEntry,
                    onDelete: _deleteFoodEntry,
                  ),
                ),
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
              initialTimestamp: viewModel.selectedDate.withCurrentTime,
            ),
            const SizedBox(height: 12),
            // ... (rest of the method stays the same: buttons row, etc.)
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
                      final vm = viewModel;
                      final state = key.currentState;
                      if (state == null) return;
                      final diaryDate = vm.selectedDate;
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
                            .selectedDateTime, // This is now initialized correctly.
                        quantityInMl: quantity,
                        name: name,
                        kcal: kcal,
                        sugarPer100ml: sugarPer100ml,
                        carbsPer100ml: sugarPer100ml,
                        caffeinePer100ml: caffeinePer100ml,
                      );

                      try {
                        final newId = await DatabaseHelper.instance
                            .insertFluidEntry(newEntry);

                        if (!mounted) return;

                        if (caffeinePer100ml != null && caffeinePer100ml > 0) {
                          final totalCaffeine =
                              (caffeinePer100ml / 100.0) * quantity;
                          await vm.logCaffeineDose(
                            totalCaffeine,
                            state.selectedDateTime,
                            fluidEntryId: newId,
                          );
                        }
                      } catch (_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.error)),
                        );
                        return;
                      }

                      close();
                      if (!mounted) return;
                      vm.loadDataForDate(diaryDate, queueIfInFlight: true);
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
      "fluids", // In first position
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

          final entries = viewModel.entriesByMeal[mealKey] ?? [];
          final mealMacros = _MealMacros();
          for (var item in entries) {
            final factor = item.entry.quantityInGrams / 100.0;
            mealMacros.calories += (item.item.calories * factor).toDouble();
            mealMacros.protein += (item.item.protein * factor).toDouble();
            mealMacros.carbs += (item.item.carbs * factor).toDouble();
            mealMacros.fat += (item.item.fat * factor).toDouble();
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
    final titleStyle = theme.textTheme.titleMedium;

    return AppCardContainer(
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
          // Summary row — always visible, above the expand/collapse section
          if (viewModel.fluidEntries.isNotEmpty) ...[
            const SizedBox(height: 4),
            Builder(
              builder: (ctx) {
                int totalMl = 0;
                int totalKcal = 0;
                double totalSugar = 0;
                double totalCaffeine = 0;
                for (var entry in viewModel.fluidEntries) {
                  totalMl += entry.quantityInMl;
                  if (entry.kcal != null) totalKcal += entry.kcal!;
                  if (entry.sugarPer100ml != null) {
                    totalSugar +=
                        (entry.sugarPer100ml! / 100) * entry.quantityInMl;
                  }
                  if (entry.caffeinePer100ml != null) {
                    totalCaffeine +=
                        (entry.caffeinePer100ml! / 100) * entry.quantityInMl;
                  }
                }
                return MacroBadgeRow(
                  kcal: totalKcal.round(),
                  sugar: totalSugar,
                  caffeine: totalCaffeine,
                  waterMl: totalMl,
                  useBadges: ctx.read<ThemeService>().useColorfulMacroBadges,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                );
                },

            ),
          ],
          AnimatedCrossFade(
            crossFadeState:
                isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: DesignConstants.expandCollapseDuration,
            firstChild: Column(
              children: [
                if (viewModel.fluidEntries.isNotEmpty)
                  const Divider(height: 16),
                ...viewModel.fluidEntries.map(
                  (entry) => FluidEntryTile(
                    entry: entry,
                    onEdit: _editFluidEntry,
                    onDelete: _deleteFluidEntry,
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
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
  double calories = 0;
  double protein = 0;
  double carbs = 0;
  double fat = 0;
}

class DiaryAppBar extends StatefulWidget {
  final GlobalKey<DiaryScreenState> diaryKey;
  const DiaryAppBar({super.key, required this.diaryKey});

  @override
  State<DiaryAppBar> createState() => _DiaryAppBarState();
}

class _DiaryAppBarState extends State<DiaryAppBar> {
  ValueNotifier<DateTime>? _notifier;

  @override
  void initState() {
    super.initState();
    _checkNotifier();
  }

  void _checkNotifier() {
    final notifier = widget.diaryKey.currentState?.selectedDateNotifier;
    if (notifier != null) {
      setState(() => _notifier = notifier);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkNotifier();
      });
    }
  }

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
      return l10n.yesterday;
    } else if (selectedDate.isSameDate(dayBeforeYesterday)) {
      return l10n.dayBeforeYesterday;
    } else {
      return DateFormat.yMMMMd(
        Localizations.localeOf(context).toString(),
      ).format(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_notifier == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          l10n.today,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      );
    }

    return ValueListenableBuilder<DateTime>(
      valueListenable: _notifier!,
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
