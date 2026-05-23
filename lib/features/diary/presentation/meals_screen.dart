import 'dart:async';
import 'package:flutter/material.dart';
import '../../../generated/app_localizations.dart';
import '../../../data/database_helper.dart';
import '../data/sources/product_local_data_source.dart';
import '../domain/models/food_entry.dart';
import '../domain/models/food_item.dart';
import '../../supplements/domain/models/supplement.dart';
import '../../supplements/domain/models/supplement_log.dart';
import '../../../services/haptic_feedback_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import 'widgets/meal_item_card.dart';
import 'widgets/confirm_log_meal_bottom_sheet.dart';
import 'add_food_screen.dart';
import 'meal_screen.dart';

/// A screen that displays a list of the user's saved meals.
///
/// Provides access to create new meals or edit existing ones with a clean design.
class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  List<Map<String, dynamic>> _meals = [];
  bool _loading = true;

  final Map<int, List<Map<String, dynamic>>> _mealItemsCache = {};
  final Map<int, Future<MealCardNutritionTotals>> _mealTotalsFutureCache = {};

  @override
  void initState() {
    super.initState();
    _reloadMeals();
  }

  Future<void> _reloadMeals() async {
    setState(() {
      _loading = true;
      _mealItemsCache.clear();
      _mealTotalsFutureCache.clear();
    });
    final meals = await DatabaseHelper.instance.getMeals();
    if (!mounted) return;
    setState(() {
      _meals = meals;
      _loading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _getMealItems(int mealId) async {
    if (_mealItemsCache.containsKey(mealId)) return _mealItemsCache[mealId]!;
    final rows = await DatabaseHelper.instance.getMealItems(mealId);
    _mealItemsCache[mealId] = rows;
    return rows;
  }

  Future<Map<String, FoodItem>> _getProductsForMealItems(
    List<Map<String, dynamic>> items,
  ) async {
    final barcodes = items
        .map((item) => item['barcode'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final products =
        await ProductLocalDataSource.instance.getProductsByBarcodes(barcodes);
    return {for (final product in products) product.barcode: product};
  }

  Future<MealCardNutritionTotals> _getMealTotals(int mealId) {
    return _mealTotalsFutureCache.putIfAbsent(mealId, () async {
      final items = await _getMealItems(mealId);
      final productsByBarcode = await _getProductsForMealItems(items);
      return calculateMealCardNutritionTotals(
        items: items,
        productsByBarcode: productsByBarcode,
      );
    });
  }

  Future<void> _confirmAndLogMeal(
    Map<String, dynamic> meal,
    AppLocalizations l10n,
  ) async {
    final mealId = meal['id'] as int;
    final rawItems = List<Map<String, dynamic>>.from(
      await _getMealItems(mealId),
    );
    if (rawItems.isEmpty) return;

    final products = await _getProductsForMealItems(rawItems);

    if (!mounted) return;

    await showGlassBottomMenu<bool>(
      context: context,
      title: l10n.mealsAddToDiary,
      contentBuilder: (ctx, close) {
        return ConfirmLogMealBottomSheet(
          mealName: meal['name'] as String,
          rawItems: rawItems,
          products: products,
          initialDate: DateTime.now(),
          initialMealType: 'mealtypeBreakfast',
          onClose: close,
          onSave: (date, mealType, quantities) async {
            for (final it in rawItems) {
              final bc = it['barcode'] as String;
              final qty = quantities[bc] ?? (it['quantity_in_grams'] as int);

              final newFoodEntryId = await DatabaseHelper.instance.insertFoodEntry(
                FoodEntry(
                  barcode: bc,
                  timestamp: date,
                  quantityInGrams: qty,
                  mealType: mealType,
                ),
              );

              final fi = products[bc];
              final c100 = fi?.caffeineMgPer100ml;
              if (fi?.isLiquid == true && c100 != null && c100 > 0) {
                await _logCaffeineDose(
                  c100 * (qty / 100.0),
                  date,
                  foodEntryId: newFoodEntryId,
                );
              }
            }

            if (mounted) {
              HapticFeedbackService.instance.confirmationFeedback();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                SnackBar(content: Text(l10n.mealAddedToDiarySuccess)),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _logCaffeineDose(
    double doseMg,
    DateTime timestamp, {
    int? foodEntryId,
  }) async {
    if (doseMg <= 0) return;

    final supplements = await DatabaseHelper.instance.getAllSupplements();
    final caffeine = supplements.firstWhere(
      (s) => (s.code == 'caffeine') || s.name.toLowerCase() == 'caffeine',
      orElse: () => Supplement(
        name: 'Caffeine',
        defaultDose: 100,
        unit: 'mg',
        dailyLimit: 400,
        code: 'caffeine',
        isBuiltin: true,
      ),
    );

    final caffeineId = caffeine.id ??
        (await DatabaseHelper.instance.insertSupplement(caffeine));

    await DatabaseHelper.instance.insertSupplementLog(
      SupplementLog(
        supplementId: caffeineId,
        dose: doseMg,
        unit: 'mg',
        timestamp: timestamp,
        sourceFoodEntryId: foodEntryId,
      ),
    );
  }

  Future<void> _deleteMeal(
    Map<String, dynamic> meal,
    AppLocalizations l10n,
  ) async {
    final ok = await showDeleteConfirmation(
      context,
      title: l10n.mealDeleteConfirmTitle,
      content: l10n.mealDeleteConfirmBody(meal['name'] as String),
    );

    if (!ok) return;
    final mealId = meal['id'] as int;
    await DatabaseHelper.instance.deleteMeal(mealId);
    _mealItemsCache.remove(mealId);
    _mealTotalsFutureCache.remove(mealId);
    await _reloadMeals();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mealDeleted)),
      );
    }
  }

  Future<void> _createMealAndOpenEditor(AppLocalizations l10n) async {
    final defaultName = l10n.mealTypeLabel;
    final newMealId = await DatabaseHelper.instance.insertMeal(
      name: defaultName,
      notes: '',
    );
    if (!mounted) return;

    final meal = {'id': newMealId, 'name': defaultName, 'notes': ''};

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MealScreen(meal: meal, startInEdit: true),
      ),
    );

    await _reloadMeals();

    try {
      final items = await DatabaseHelper.instance.getMealItems(newMealId);
      final created = _meals.firstWhere((m) => m['id'] == newMealId);
      if ((created['name'] as String) == defaultName && items.isEmpty) {
        await DatabaseHelper.instance.deleteMeal(newMealId);
        await _reloadMeals();
      }
    } catch (_) {
      // ignore: cleanup is best effort
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBar(title: l10n.tabMeals),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _meals.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: DesignConstants.spacingL),
                        Text(
                          l10n.mealsEmptyTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignConstants.spacingS),
                        Text(
                          l10n.mealsEmptyBody,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _reloadMeals,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      DesignConstants.screenPaddingHorizontal,
                      12.0 + topPadding,
                      DesignConstants.screenPaddingHorizontal,
                      96.0,
                    ),
                    itemCount: _meals.length,
                    itemBuilder: (context, i) {
                      final meal = _meals[i];
                      final mealId = meal['id'] as int;

                      return MealItemCard(
                        meal: meal,
                        mealTotalsFuture: _getMealTotals(mealId),
                        ingredientCount: _mealItemsCache[mealId]?.length ?? 0,
                        onAdd: () => _confirmAndLogMeal(meal, l10n),
                        onEdit: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MealScreen(meal: meal, startInEdit: true),
                            ),
                          );
                          await _reloadMeals();
                        },
                        onDelete: () => _deleteMeal(meal, l10n),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MealScreen(meal: meal),
                            ),
                          );
                          await _reloadMeals();
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: GlassFab(
        label: l10n.mealsCreate,
        onPressed: () => _createMealAndOpenEditor(l10n),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
