import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../data/database_helper.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import '../../diary/presentation/dialogs/fluid_dialog_content.dart';
import '../../supplements/presentation/dialogs/log_supplement_menu.dart';
import '../../diary/presentation/dialogs/quantity_dialog_content.dart';
import '../../../generated/app_localizations.dart';
import '../../diary/domain/models/food_entry.dart';
import '../../diary/domain/models/fluid_entry.dart';
import '../../diary/domain/models/food_item.dart';
import '../../workout/domain/models/routine.dart';
import '../../supplements/domain/models/supplement.dart';
import '../../supplements/domain/models/supplement_log.dart';
import '../../workout/domain/models/workout_log.dart';
import '../../diary/presentation/add_food_navigation_result.dart';
import '../../diary/presentation/add_food_screen.dart';
import '../../diary/presentation/ai_meal_capture_screen.dart';
import '../../profile/presentation/add_measurement_screen.dart';
import '../../diary/presentation/diary_screen.dart';
import '../../workout/presentation/edit_routine_screen.dart';
import '../../workout/presentation/live_workout_screen.dart';
import '../../diary/presentation/nutrition_hub_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../analytics/presentation/statistics_hub_screen.dart';
import '../../workout/presentation/workout_hub_screen.dart';
import '../../../services/profile_service.dart';
import '../../steps/data/steps_aggregation_repository.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../services/theme_service.dart';
import '../../workout/presentation/live_workout_view_model.dart';
import '../../../theme/color_constants.dart';
import '../../../util/date_util.dart';
import '../../../util/design_constants.dart';
import 'widgets/glass_bottom_menu.dart';
import 'widgets/glass_bottom_nav_bar.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/keep_alive_page.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';
import '../../../navigation/app_route_observer.dart';
import '../../../services/app_tour_service.dart';
import '../../onboarding/presentation/widgets/app_tour_overlay.dart';

/// The root scaffold containing the main navigation structure.
///
/// Hosts the bottom navigation bar and manages switching between primary tabs:
/// Diary, Workout, Statistics, and Nutrition Hub. Also provides the global Speed Dial.
class MainScreen extends StatefulWidget {
  /// The optional index of the tab to be displayed initially.
  final int? initialTabIndex;
  const MainScreen({super.key, this.initialTabIndex});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin, RouteAware {
  late PageController _pageController;
  int _currentIndex = 0;
  final GlobalKey<DiaryScreenState> _tagebuchKey =
      GlobalKey<DiaryScreenState>();
  final GlobalKey _tourNavigationBarKey = GlobalKey();
  final GlobalKey _tourFabKey = GlobalKey();
  final GlobalKey _tourDiaryTabKey = GlobalKey();
  final GlobalKey _tourWorkoutTabKey = GlobalKey();
  final GlobalKey _tourStatisticsTabKey = GlobalKey();
  final GlobalKey _tourNutritionTabKey = GlobalKey();
  bool _isAddMenuOpen = false;
  bool _isTourActive = false;
  bool _isTourOfferVisible = false;
  bool _isRouteObserverAttached = false;
  int _tourStepIndex = 0;
  Rect? _tourTargetRect;
  late final AnimationController _menuController;
  final StepsAggregationRepository _stepsRepository =
      HealthStepsAggregationRepository();

  ThemeService get themeService =>
      Provider.of<ThemeService>(context, listen: false);
  bool get isLiquid => themeService.visualStyle == 1;

  double get kNavBarHeight => isLiquid ? 65 : 72;
  double kBarFabGap = 12.0;

  double _safe01(double v) => v.isNaN ? 0.0 : v.clamp(0.0, 1.0).toDouble();
  DateTime get _currentActiveDate {
    if (_currentIndex == 0 && _tagebuchKey.currentState != null) {
      return _tagebuchKey.currentState!.selectedDateNotifier.value.dateOnly;
    }
    return DateTime.now().dateOnly;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePendingAppTourEntry();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_isRouteObserverAttached && route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
      _isRouteObserverAttached = true;
    }
  }

  @override
  void didPush() {
    _handlePendingAppTourEntry();
  }

  @override
  void didPopNext() {
    _handlePendingAppTourEntry();
  }

  @override
  void dispose() {
    if (_isRouteObserverAttached) {
      appRouteObserver.unsubscribe(this);
    }
    _pageController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_isWarping) {
      return;
    }
    setState(() => _currentIndex = index);
  }

  final bool _isWarping = false;

  void _onNavigationTapped(int index) {
    if (!_pageController.hasClients) return;
    _pageController.jumpToPage(index);
  }

  void _toggleAddMenu() {
    setState(() {
      _isAddMenuOpen = !_isAddMenuOpen;
      if (_isAddMenuOpen) {
        _menuController.forward();
      } else {
        _menuController.reverse();
      }
    });
  }

  void _executeAddMenuAction(String action) async {
    switch (action) {
      case 'start_workout':
        _showStartWorkoutMenu();
        break;
      case 'add_measurement':
        // New: get date
        final targetDate = _currentActiveDate;

        final success = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => AddMeasurementScreen(
              initialDate: targetDate, // <--- Pass-through
            ),
          ),
        );
        if (success == true) _refreshHomeScreen();
        break;
      case 'add_food':
        _handleAddFood();
        break;
      case 'add_liquid':
        await _showAddFluidMenu();
        break;
      case 'log_supplement':
        _showLogSupplementMenu();
        break;
      case 'ai_meal_capture':
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                AiMealCaptureScreen(initialDate: _currentActiveDate),
          ),
        );
        if (result == true) _refreshHomeScreen();
        break;
    }
  }

  Future<void> _refreshHomeScreen() async {
    if (_currentIndex == 0) {
      await _tagebuchKey.currentState?.syncHealthData(
        forceStepsRefresh: false, // Don't force 30-day refresh on every log
      );
    } else {
      // If we're not on the diary tab, we still want to trigger a background sync if due
      await _stepsRepository.refresh(force: false);
    }
  }

  Future<void> _refreshDiaryForActiveDate({
    bool queueIfInFlight = false,
  }) async {
    if (_currentIndex != 0) return;
    await _tagebuchKey.currentState?.syncHealthData();
  }

  Future<void> _showLogSupplementMenu() async {
    // ... (supplement selection stays the same) ...
    final l10n = AppLocalizations.of(context)!;
    final Supplement? selectedSupplement =
        await showGlassBottomMenu<Supplement>(
      context: context,
      title: l10n.logIntakeTitle,
      contentBuilder: (ctx, close) => LogSupplementMenu(close: close),
    );

    if (selectedSupplement == null || !mounted) return;

    // FIX: Get date
    final targetDate = _currentActiveDate;
    final initialTimestamp = targetDate.withCurrentTime;

    final result = await showGlassBottomMenu<(double, DateTime)?>(
      context: context,
      title: localizeSupplementName(selectedSupplement, l10n),
      contentBuilder: (ctx, close) {
        return LogSupplementDoseBody(
          supplement: selectedSupplement,
          initialTimestamp: initialTimestamp, // <--- FIX: Pass date with time
          primaryLabel: l10n.add_button,
          onCancel: close,
          onSubmit: (dose, ts) {
            close();
            Navigator.of(ctx).pop((dose, ts));
          },
        );
      },
    );

    if (result != null) {
      final newLog = SupplementLog(
        supplementId: selectedSupplement.id!,
        dose: result.$1,
        unit: selectedSupplement.unit,
        timestamp: result.$2,
      );
      try {
        await DatabaseHelper.instance.insertSupplementLog(newLog);
        HapticFeedbackService.instance.confirmationFeedback();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.error)),
          );
        }
      } finally {
        _refreshHomeScreen();
      }
    }
  }

  Future<void> _showStartWorkoutMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final routines = await WorkoutLocalDataSource.instance.getAllRoutines();
    if (!mounted) return;

    // Wait for the menu result.
    // The menu closes itself and returns the data.
    final result =
        await showGlassBottomMenu<({WorkoutLog log, Routine? routine})>(
      context: context,
      title: l10n.startWorkout,
      contentBuilder: (ctx, close) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        Widget glassCard({required Widget child, EdgeInsets? padding}) {
          return Material(
            color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.08),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: child,
            ),
          );
        }

        final freeWorkoutTile = glassCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              // 1. Create workout
              final newWorkoutLog = await WorkoutLocalDataSource.instance
                  .startWorkout(routineName: l10n.freeWorkoutTitle);

              if (!ctx.mounted) return;

              // 2. Close menu and return data
              // Use Navigator.of(ctx).pop(...), not 'close()', to send data.
              Navigator.of(ctx).pop((log: newWorkoutLog, routine: null));
            },
            child: Row(
              children: [
                const Icon(Icons.play_arrow_rounded),
                const SizedBox(width: 12),
                Text(
                  l10n.startEmptyWorkoutButton,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        );

        final routinesList = ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            shrinkWrap: true,
            itemCount: routines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final r = routines[i];
              return glassCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () async {
                        // Show loading indicator on top of the menu.
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        final fullRoutine = await WorkoutLocalDataSource
                            .instance
                            .getRoutineById(r.id!);
                        final newWorkoutLog = await WorkoutLocalDataSource
                            .instance
                            .startWorkout(routineName: r.name);

                        if (!mounted) return;
                        Navigator.of(context).pop(); // Close loading indicator

                        if (fullRoutine != null && ctx.mounted) {
                          // Close menu and return data
                          Navigator.of(
                            ctx,
                          ).pop((log: newWorkoutLog, routine: fullRoutine));
                        }
                      },
                      child: Text(l10n.startButton),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Editing navigates directly (that is ok because it is a new screen).
                          // pop+push would also be better here, but keep this for edit,
                          // because the user wants to return to the menu while editing.
                          // Close only the menu here without a result.
                          close();
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => EditRoutineScreen(routine: r),
                                ),
                              )
                              .then((_) => _refreshHomeScreen());
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(ctx)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.editRoutineSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(ctx).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.more_vert_rounded,
                      color: Theme.of(ctx).textTheme.bodyMedium?.color,
                    ),
                  ],
                ),
              );
            },
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            freeWorkoutTile,
            if (routines.isNotEmpty) ...[
              const SizedBox(height: 12),
              routinesList,
            ],
          ],
        );
      },
    );

    // The actual navigation to the workout happens here,
    // after the menu is closed.
    if (result != null && mounted) {
      HapticFeedbackService.instance.confirmationFeedback();
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => LiveWorkoutScreen(
                routine: result.routine,
                workoutLog: result.log,
              ),
            ),
          )
          .then((_) => _refreshHomeScreen());
    }
  }

  Future<void> _handleAddFood() async {
    final l10n = AppLocalizations.of(context)!;
    // FIX: Get date
    final targetDate = _currentActiveDate;

    final routeResult = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) => AddFoodScreen(
          initialDate: targetDate, // <--- Pass-through
          // initialMealType: null, // Default is ok
        ),
      ),
    );

    if (!mounted) return;

    final addFoodResult = AddFoodNavigationResult.fromRouteResult(routeResult);
    if (addFoodResult.shouldRefresh) {
      _refreshHomeScreen();
      return;
    }

    final selectedFoodItem = addFoodResult.selectedFoodItem;
    if (selectedFoodItem == null) return;

    // FIX: Pass date (adjust signature below).
    final result = await _showQuantityMenu(
      selectedFoodItem,
      initialDate: targetDate,
    );

    if (result == null || !mounted) return;

    final int quantity = result.quantity;
    final DateTime timestamp =
        result.timestamp; // This now comes correctly from the dialog.
    final String mealType = result.mealType;
    final bool isLiquid = result.isLiquid;
    final double? caffeinePer100 = result.caffeinePer100ml;

    // ... (remaining logic: insertFoodEntry, insertFluidEntry, etc. stays the same) ...
    // The timestamp here is already correct because it comes from the dialog,
    // initialized with targetDate.

    final newFoodEntry = FoodEntry(
      barcode: selectedFoodItem.barcode,
      timestamp: timestamp,
      quantityInGrams: quantity,
      mealType: mealType,
    );

    try {
      final newFoodEntryId = await DatabaseHelper.instance.insertFoodEntry(
        newFoodEntry,
      );
      HapticFeedbackService.instance.confirmationFeedback();

      if (isLiquid) {
        // ... insertFluidEntry with timestamp ...
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
        await DatabaseHelper.instance.insertFluidEntry(newFluidEntry);
      }

      if (isLiquid && caffeinePer100 != null && caffeinePer100 > 0) {
        // ... logCaffeineDose ...
        final totalCaffeine = (caffeinePer100 / 100.0) * quantity;
        await _logCaffeineDose(
          totalCaffeine,
          timestamp,
          foodEntryId: newFoodEntryId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error)),
        );
      }
    } finally {
      _refreshHomeScreen();
    }
  }

  Future<void> _showAddFluidMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final key = GlobalKey<FluidDialogContentState>();
    final targetDate = _currentActiveDate; // <--- FIX

    await showGlassBottomMenu(
      context: context,
      title: l10n.add_liquid_title,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FluidDialogContent(
              key: key,
              initialTimestamp: targetDate.withCurrentTime,
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
                        timestamp: state.selectedDateTime,
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
                        HapticFeedbackService.instance.confirmationFeedback();

                        if (caffeinePer100ml != null && caffeinePer100ml > 0) {
                          final totalCaffeine =
                              (caffeinePer100ml / 100.0) * quantity;
                          await _logCaffeineDose(
                            totalCaffeine,
                            state.selectedDateTime,
                            fluidEntryId: newId,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.error)),
                          );
                        }
                      } finally {
                        close();
                        await _refreshDiaryForActiveDate(queueIfInFlight: true);
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
      caffeineSupplement = supplements.firstWhere(
        (s) => (s.code == 'caffeine') || s.name.toLowerCase() == 'caffeine',
      );
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
        sourceFoodEntryId: foodEntryId,
        sourceFluidEntryId: fluidEntryId,
      ),
    );
  }

  Future<
      ({
        int quantity,
        DateTime timestamp,
        String mealType,
        bool isLiquid,
        double? sugarPer100ml,
        double? caffeinePer100ml,
      })?> _showQuantityMenu(
    FoodItem item, {
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
              initialTimestamp: (initialDate ?? DateTime.now()).withCurrentTime,
            ),
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
                        final sugar = double.tryParse(
                          state.sugarText.replaceAll(',', '.'),
                        );
                        final caffeine = double.tryParse(
                          state.caffeineText.replaceAll(',', '.'),
                        );
                        if (quantity != null && quantity > 0) {
                          HapticFeedbackService.instance.confirmationFeedback();
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

  String localizeSupplementName(Supplement s, AppLocalizations l10n) {
    switch (s.code) {
      case 'caffeine':
        return l10n.supplement_caffeine;
      case 'creatine_monohydrate':
        return l10n.supplement_creatine_monohydrate;
      default:
        return s.name;
    }
  }

  // Replace this method
  GlobalAppBar _buildAppBar(
    BuildContext context,
    int index,
    AppLocalizations l10n,
  ) {
    switch (index) {
      case 1: // Workout
        return GlobalAppBar(
          title: l10n.workout,
          actions: [_profileAppBarButton(context)],
        );
      case 2: // Stats
        return GlobalAppBar(
          title: l10n.statistics,
          actions: [_profileAppBarButton(context)],
        );
      case 3: // Nutrition Hub
        return GlobalAppBar(
          title: l10n.nutritionHubTitle,
          actions: [_profileAppBarButton(context)],
        );
      case 0: // Diary
      default:
        return GlobalAppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          titleWidget: DiaryAppBar(
            diaryKey: _tagebuchKey,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                _tagebuchKey.currentState?.navigateDay(false);
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () {
                _tagebuchKey.currentState?.pickDate();
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                _tagebuchKey.currentState?.navigateDay(true);
              },
            ),
            _profileAppBarButton(context),
          ],
        );
    }
  }

  List<Map<String, dynamic>> _getSpeedDialActions(AppLocalizations l10n) {
    return [
      {
        'icon': Icons.local_drink,
        'label': l10n.addLiquidOption,
        'action': 'add_liquid',
      },
      {
        'icon': Icons.restaurant_menu,
        'label': l10n.addFoodOption,
        'action': 'add_food',
      },
      {
        'icon': Icons.straighten_outlined,
        'label': l10n.addMeasurement,
        'action': 'add_measurement',
      },
      {
        'icon': Icons.fitness_center,
        'label': l10n.startWorkout,
        'action': 'start_workout',
      },
      {
        'icon': Icons.medication_outlined,
        'label': l10n.logIntakeTitle,
        'action': 'log_supplement',
      },
      if (themeService.isAiEnabled)
        {
          'icon': Icons.auto_awesome,
          'label': l10n.aiMealCapture,
          'action': 'ai_meal_capture',
          'gradient': true,
        },
    ];
  }

  List<_AppTourStep> _buildAppTourSteps(AppLocalizations l10n) {
    return [
      _AppTourStep(
        anchorKey: _tourNavigationBarKey,
        tabIndex: 0,
        title: l10n.appTourStepNavigationTitle,
        description: l10n.appTourStepNavigationBody,
      ),
      _AppTourStep(
        anchorKey: _tourFabKey,
        tabIndex: 0,
        title: l10n.appTourStepQuickActionsTitle,
        description: l10n.appTourStepQuickActionsBody,
      ),
      _AppTourStep(
        anchorKey: _tourDiaryTabKey,
        tabIndex: 0,
        title: l10n.appTourStepDiaryTitle,
        description: l10n.appTourStepDiaryBody,
      ),
      _AppTourStep(
        anchorKey: _tourWorkoutTabKey,
        tabIndex: 1,
        title: l10n.appTourStepWorkoutTitle,
        description: l10n.appTourStepWorkoutBody,
      ),
      _AppTourStep(
        anchorKey: _tourNutritionTabKey,
        tabIndex: 3,
        title: l10n.appTourStepNutritionTitle,
        description: l10n.appTourStepNutritionBody,
      ),
      _AppTourStep(
        anchorKey: _tourStatisticsTabKey,
        tabIndex: 2,
        title: l10n.appTourStepStatisticsTitle,
        description: l10n.appTourStepStatisticsBody,
      ),
    ];
  }

  Rect? _rectForKey(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return null;
    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  Future<void> _handlePendingAppTourEntry() async {
    if (!mounted || _isTourActive || _isTourOfferVisible) return;
    final entry = await AppTourService.instance.consumePendingEntryPoint();
    if (!mounted || entry == null) return;

    switch (entry) {
      case AppTourEntryPoint.postOnboardingOffer:
        await _showPostOnboardingTourOffer();
        break;
      case AppTourEntryPoint.settingsRestart:
        await _startAppTour();
        break;
    }
  }

  Future<void> _showPostOnboardingTourOffer() async {
    if (!mounted || _isTourOfferVisible) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isTourOfferVisible = true);
    final shouldStartTour = await showGlassBottomMenu<bool>(
      context: context,
      title: l10n.appTourOfferTitle,
      contentBuilder: (ctx, close) => Column(
        key: const Key('app_tour_offer_dialog'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.appTourOfferBody,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('app_tour_offer_skip_button'),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.appTourOfferSkip),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('app_tour_offer_start_button'),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l10n.appTourOfferStart),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _isTourOfferVisible = false);
    await AppTourService.instance.markOfferShown();

    if (shouldStartTour == true) {
      await _startAppTour();
      return;
    }
    await AppTourService.instance.markSkipped();
  }

  Future<void> _startAppTour() async {
    if (!mounted) return;
    await AppTourService.instance.markOfferShown();
    setState(() {
      _isTourActive = true;
      _tourStepIndex = 0;
      _tourTargetRect = null;
      _isAddMenuOpen = false;
    });
    _menuController.reverse();
    await _showAppTourStep(0);
  }

  Future<void> _showAppTourStep(int index) async {
    if (!mounted || !_isTourActive) return;
    final l10n = AppLocalizations.of(context)!;
    final steps = _buildAppTourSteps(l10n);
    if (index < 0 || index >= steps.length) return;
    final step = steps[index];

    if (_currentIndex != step.tabIndex) {
      _onNavigationTapped(step.tabIndex);
    }

    setState(() {
      _tourStepIndex = index;
      _tourTargetRect = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isTourActive) return;
      final targetRect =
          _rectForKey(step.anchorKey) ?? _rectForKey(_tourNavigationBarKey);
      setState(() => _tourTargetRect = targetRect);
    });
  }

  Future<void> _nextTourStep() async {
    if (!mounted || !_isTourActive) return;
    final l10n = AppLocalizations.of(context)!;
    final steps = _buildAppTourSteps(l10n);
    final nextIndex = _tourStepIndex + 1;
    if (nextIndex >= steps.length) {
      await _completeAppTour();
      return;
    }
    await _showAppTourStep(nextIndex);
  }

  Future<void> _skipAppTour() async {
    if (!mounted || !_isTourActive) return;
    setState(() {
      _isTourActive = false;
      _tourTargetRect = null;
      _tourStepIndex = 0;
    });
    await AppTourService.instance.markSkipped();
  }

  Future<void> _completeAppTour() async {
    if (!mounted || !_isTourActive) return;
    setState(() {
      _isTourActive = false;
      _tourTargetRect = null;
      _tourStepIndex = 0;
    });
    await AppTourService.instance.markCompleted();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appTourSteps = _buildAppTourSteps(l10n);
    final activeTourStep = (_isTourActive &&
            _tourStepIndex >= 0 &&
            _tourStepIndex < appTourSteps.length)
        ? appTourSteps[_tourStepIndex]
        : null;

    final manager = context.watch<LiveWorkoutViewModel>();
    final bool isWorkoutRunning = manager.isActive;
    final String elapsed = _formatDuration(manager.elapsedDuration);

    // Animation parameters
    // const basePad = 120.0; // Unused locally
    // final runningPad = manager.isActive ? 68.0 : 0.0; // Unused locally
    // final bg = isDark ? summaryCardDarkMode : summaryCardWhiteMode; // Unused locally in build, used in GlassNavBar logic internal

    // Because we use a completely custom floating Bottom Navigation Bar and Workout Bar,
    // the system Scaffold does not automatically inset floating Snackbars.
    // By providing a transparent dummy bottomNavigationBar, ScaffoldMessenger
    // will natively push up all Snackbars (including those from settings).
    final double dynamicBottomPadding = isWorkoutRunning ? 120 + 68 : 120;

    return Stack(
      children: [
        Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          appBar: _buildAppBar(context, _currentIndex, l10n),
          bottomNavigationBar: SizedBox(height: dynamicBottomPadding),
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: <Widget>[
              KeepAlivePage(
                storageKey: const PageStorageKey('tab_tagebuch'),
                child: DiaryScreen(contentKey: _tagebuchKey),
              ),
              const KeepAlivePage(
                storageKey: PageStorageKey('tab_workout'),
                child: WorkoutHubScreen(),
              ),
              const KeepAlivePage(
                storageKey: PageStorageKey('tab_stats'),
                child: StatisticsHubScreen(),
              ),
              const KeepAlivePage(
                storageKey: PageStorageKey('tab_nutrition'),
                child: NutritionHubScreen(),
              ),
            ],
          ),
        ),
        // Laufendes Workout Overlay
        if (isWorkoutRunning)
          Positioned(
            bottom: 36 + kNavBarHeight,
            left: 16,
            right: 16,
            child: _FrostedBar(
              child: _RunningWorkoutRow(
                timeText: elapsed,
                onContinue: () {
                  final log = context.read<LiveWorkoutViewModel>().workoutLog;
                  if (log != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            LiveWorkoutScreen(workoutLog: log, routine: null),
                      ),
                    );
                  }
                },
                onDiscard: () async {
                  final l10n = AppLocalizations.of(context)!;
                  final wsm = context.read<LiveWorkoutViewModel>();
                  final logId = wsm.workoutLog?.id;

                  // FIX: showDeleteConfirmation instead of showDialog.
                  final confirmed = await showDeleteConfirmation(
                    context,
                    title: l10n.discard_button, // "Discard"
                    content:
                        l10n.deleteWorkoutConfirmContent, // "Really delete?"
                    confirmLabel: l10n.discard_button, // Red button: "Discard"
                  );

                  if (confirmed) {
                    if (logId != null) {
                      await WorkoutLocalDataSource.instance.deleteWorkoutLog(
                        logId,
                      );
                    }
                    await wsm.finishWorkout();
                  }
                },
                l10n: l10n,
              ),
            ),
          ),
        // Bottom Nav Bar & FAB
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: KeyedSubtree(
                  key: _tourNavigationBarKey,
                  child: GlassBottomNavBar(
                    currentIndex: _currentIndex,
                    onTap: _onNavigationTapped,
                    onFabTap: _toggleAddMenu,
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(
                          Icons.book_outlined,
                          key: _tourDiaryTabKey,
                        ),
                        label: l10n.diary,
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(
                          Icons.fitness_center_outlined,
                          key: _tourWorkoutTabKey,
                        ),
                        label: l10n.workout,
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(
                          Icons.bar_chart_outlined,
                          key: _tourStatisticsTabKey,
                        ),
                        label: l10n.statistics,
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(
                          Icons.restaurant_menu_rounded,
                          key: _tourNutritionTabKey,
                        ),
                        label: l10n.nutrition,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: kBarFabGap),
              GlassFab(
                key: _tourFabKey,
                onPressed: _toggleAddMenu,
                icon: Icons.add,
              ),
            ],
          ),
        ),
        // Speed Dial Menu Animation
        AnimatedBuilder(
          animation: _menuController,
          builder: (context, _) {
            final v = _safe01(_menuController.value);
            final themeService = context.watch<ThemeService>();
            final bool isDarkLocal =
                Theme.of(context).brightness == Brightness.dark;
            final Color bgLocal =
                isDarkLocal ? summaryCardDarkMode : summaryCardWhiteMode;
            final Color neutralTintLocal =
                (isDarkLocal ? Colors.white : Colors.black).withValues(
              alpha: isDarkLocal ? 0.10 : 0.10,
            );
            final Color effectiveGlassLocal = Color.alphaBlend(
              neutralTintLocal,
              bgLocal.withValues(alpha: isDarkLocal ? 0.22 : 0.16),
            );

            // Define liquid animation radius locally here or from a constant.
            const double rLiquid = 99;

            return Offstage(
              offstage: v == 0.0,
              child: IgnorePointer(
                ignoring: v == 0.0,
                child: Stack(
                  children: [
                    Opacity(
                      opacity: v,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isAddMenuOpen = false;
                            _menuController.reverse();
                          });
                        },
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 6.0 * v,
                            sigmaY: 6.0 * v,
                          ),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.4 * v),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 100.0,
                      right: 20.0,
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children:
                              _getSpeedDialActions(l10n).asMap().entries.map((
                            entry,
                          ) {
                            final index = entry.key;
                            final action = entry.value;
                            final curved = CurvedAnimation(
                              parent: _menuController,
                              curve: Interval(
                                (index * 0.12).clamp(0.0, 0.95),
                                1.0,
                                curve: Curves.easeOutBack,
                              ),
                            );
                            final tv = _safe01(curved.value);
                            final offsetY = 90.0 * (index + 1);
                            return Transform.translate(
                              offset: Offset(0, (1 - tv) * offsetY),
                              child: Opacity(
                                opacity: tv,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10.0,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        action['label'],
                                        style: TextStyle(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? Colors.black87
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          setState(() {
                                            _isAddMenuOpen = false;
                                            _menuController.reverse();
                                          });
                                          _executeAddMenuAction(
                                            action['action'],
                                          );
                                        },
                                        child: themeService.visualStyle == 1
                                            ? LiquidGlass.withOwnLayer(
                                                settings: LiquidGlassSettings(
                                                  thickness: 25,
                                                  blur: 5,
                                                  glassColor:
                                                      effectiveGlassLocal,
                                                  lightIntensity: 0.35,
                                                  saturation: 1.10,
                                                ),
                                                shape:
                                                    const LiquidRoundedSuperellipse(
                                                  borderRadius: rLiquid,
                                                ),
                                                child: Container(
                                                  width: 65.0,
                                                  height: 65.0,
                                                  decoration: BoxDecoration(
                                                    color: neutralTintLocal,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      rLiquid,
                                                    ),
                                                  ),
                                                  foregroundDecoration:
                                                      BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      rLiquid,
                                                    ),
                                                    border: Border.all(
                                                      color: isDarkLocal
                                                          ? Colors.white
                                                              .withValues(
                                                              alpha: 0.20,
                                                            )
                                                          : Colors.black
                                                              .withValues(
                                                              alpha: 0.08,
                                                            ),
                                                      width: 1.2,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: action['gradient'] ==
                                                          true
                                                      ? ShaderMask(
                                                          blendMode:
                                                              BlendMode.srcIn,
                                                          shaderCallback:
                                                              (bounds) =>
                                                                  createAiGradientShader(
                                                            bounds,
                                                          ),
                                                          child: Icon(
                                                            action['icon'],
                                                            size: 28,
                                                          ),
                                                        )
                                                      : Icon(
                                                          action['icon'],
                                                          size: 28,
                                                          color: isDarkLocal
                                                              ? Colors.white
                                                              : Colors.black,
                                                        ),
                                                ),
                                              )
                                            : ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                    sigmaX: 12,
                                                    sigmaY: 12,
                                                  ),
                                                  child: Container(
                                                    width: 76,
                                                    height: 76,
                                                    decoration: BoxDecoration(
                                                      color: bgLocal.withValues(
                                                          alpha: 0.80),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        18,
                                                      ),
                                                      border: Border.all(
                                                        color: isDarkLocal
                                                            ? Colors.white
                                                                .withValues(
                                                                alpha: 0.30,
                                                              )
                                                            : Colors.black
                                                                .withValues(
                                                                alpha: 0.10,
                                                              ),
                                                        width: 1.5,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(
                                                            alpha: 0.25,
                                                          ),
                                                          blurRadius: 10,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: action['gradient'] ==
                                                            true
                                                        ? ShaderMask(
                                                            blendMode:
                                                                BlendMode.srcIn,
                                                            shaderCallback:
                                                                (bounds) =>
                                                                    const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                  0xFFE88DCC,
                                                                ),
                                                                Color(
                                                                  0xFFF4A77A,
                                                                ),
                                                                Color(
                                                                  0xFFF7D06B,
                                                                ),
                                                                Color(
                                                                  0xFF7DDEAE,
                                                                ),
                                                                Color(
                                                                  0xFF6DC8D9,
                                                                ),
                                                              ],
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            ).createShader(
                                                              bounds,
                                                            ),
                                                            child: Icon(
                                                              action['icon'],
                                                              size: 28,
                                                            ),
                                                          )
                                                        : Icon(
                                                            action['icon'],
                                                            size: 28,
                                                            color: isDarkLocal
                                                                ? Colors.white
                                                                : Colors.black,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_isTourActive && activeTourStep != null)
          AppTourOverlay(
            targetRect: _tourTargetRect,
            title: activeTourStep.title,
            description: activeTourStep.description,
            progressLabel: '${_tourStepIndex + 1}/${appTourSteps.length}',
            nextLabel: _tourStepIndex == appTourSteps.length - 1
                ? l10n.appTourDone
                : l10n.appTourNext,
            skipLabel: l10n.appTourSkip,
            onNext: _nextTourStep,
            onSkip: _skipAppTour,
          ),
      ],
    );
  }

  Widget _profileAppBarButton(BuildContext context) {
    final profileService = Provider.of<ProfileService>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.only(
        right: DesignConstants.screenPaddingHorizontal,
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          // Refresh diary data when returning from profile/settings
          _refreshHomeScreen();
        },
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: (profileService.profileImagePath != null)
              ? FileImage(File(profileService.profileImagePath!))
              : null,
          child: (profileService.profileImagePath == null)
              ? const Icon(Icons.person, size: 20, color: Colors.black54)
              : null,
        ),
      ),
    );
  }
}

class _AppTourStep {
  final GlobalKey anchorKey;
  final int tabIndex;
  final String title;
  final String description;

  const _AppTourStep({
    required this.anchorKey,
    required this.tabIndex,
    required this.title,
    required this.description,
  });
}

class _FrostedBar extends StatelessWidget {
  final Widget child;
  const _FrostedBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? summaryCardDarkMode : summaryCardWhiteMode;
    final themeService = context.watch<ThemeService>();

    final Color neutralTint = (isDark ? Colors.white : Colors.black)
        .withValues(alpha: isDark ? 0.1 : 0.1);
    final Color effectiveGlass = Color.alphaBlend(
      neutralTint,
      bg.withValues(alpha: isDark ? 0.8 : 0.5),
    );

    if (themeService.visualStyle == 1) {
      double radius = 99;
      return SizedBox(
        height: 65.0,
        child: LiquidStretch(
          stretch: 0.2,
          interactionScale: 1.04,
          child: LiquidGlass.withOwnLayer(
            settings: LiquidGlassSettings(
              thickness: 30,
              blur: 0.75,
              glassColor: effectiveGlass,
              lightIntensity: 0.35,
              saturation: 1.10,
            ),
            shape: LiquidRoundedSuperellipse(borderRadius: radius),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: neutralTint),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius.toDouble()),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.20)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 1.2,
                    ),
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      );
    }
    double radius = 20;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius.toDouble()),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(radius.toDouble()),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.30)
                  : Colors.black.withValues(alpha: 0.10),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                offset: const Offset(0, 6),
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RunningWorkoutRow extends StatelessWidget {
  final String timeText;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;
  final AppLocalizations l10n;

  const _RunningWorkoutRow({
    required this.timeText,
    required this.onContinue,
    required this.onDiscard,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20),
              const SizedBox(width: 6),
              Text(
                timeText,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.9),
                  decoration: TextDecoration.none,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            minimumSize: const Size(0, 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(l10n.continue_workout_button),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onDiscard,
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
            minimumSize: const Size(0, 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(l10n.discard_button),
        ),
      ],
    );
  }
}
