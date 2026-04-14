// lib/screens/add_food_screen.dart (Final & De-Materialisiert)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../data/product_database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/food_entry.dart';
import '../models/food_item.dart';
import '../models/supplement.dart';
import '../models/supplement_log.dart';
import 'create_food_screen.dart';
import 'food_detail_screen.dart';
import 'meal_screen.dart';
import 'scanner_screen.dart';
import 'ai_meal_capture_screen.dart';
import '../util/design_constants.dart';
import '../widgets/bottom_content_spacer.dart';
import '../widgets/glass_bottom_menu.dart';
import '../widgets/glass_fab.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/off_attribution_widget.dart';
import '../widgets/summary_card.dart';
import 'package:provider/provider.dart';
import '../services/haptic_feedback_service.dart';
import '../services/theme_service.dart';

// lib/screens/add_food_screen.dart

/// A comprehensive screen for searching and adding food items to the nutrition diary.
///
/// Features multiple tabs for catalog search, recently used items, favorites,
/// and pre-defined meals. Supports barcode scanning and creating custom food items.
class AddFoodScreen extends StatefulWidget {
  /// The index of the tab to display initially.
  final int initialTab;

  /// Optional initial date for the tracked entry.
  final DateTime? initialDate; // <--- NEU
  /// Optional category or meal type identifier for the entry.
  final String? initialMealType; // <--- NEU

  /// When true, the screen acts as a food picker — tapping an item pops it
  /// back to the caller instead of logging it. Used by AI meal review.
  final bool selectionMode;
  const AddFoodScreen({
    super.key,
    this.initialTab = 0,
    this.initialDate, // <--- NEU
    this.initialMealType, // <--- NEU
    this.selectionMode = false,
  });

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen>
    with SingleTickerProviderStateMixin {
  List<FoodItem> _foundFoodItems = [];
  bool _isLoadingSearch = false;
  String _searchInitialText = "";
  final _searchController = TextEditingController();

  List<FoodItem> _favoriteFoodItems = [];
  bool _isLoadingFavorites = true;

  List<FoodItem> _recentFoodItems = [];
  bool _isLoadingRecent = true;

  late TabController _tabController;
  final TextEditingController _baseSearchCtrl = TextEditingController();
  // String _baseSearch = '';
  Timer? _baseSearchDebounce;

  List<Map<String, dynamic>> _baseCategories = [];
  final Map<String, List<FoodItem>> _catItems = {}; // key -> Produkte
  final Set<String> _loadingCats = {}; // ladeanzeige je Kategorie
  // Meals
  List<Map<String, dynamic>> _meals = [];
  final Map<int, List<Map<String, dynamic>>> _mealItemsCache = {};
  bool _isLoadingMeals = true;
  int _currentTab = 0; // 0=Katalog, 1=Zuletzt, 2=Favoriten, 3=Mahlzeiten
  final bool _suspendFab = false;
  static const double _bottomPadding = 100.0;

  Future<void> _loadMeals() async {
    setState(() => _isLoadingMeals = true);
    final rows = await DatabaseHelper.instance.getMeals();
    setState(() {
      _meals = rows;
      _isLoadingMeals = false;
    });
  }

  Future<List<Map<String, dynamic>>> _getMealItems(int mealId) async {
    if (_mealItemsCache.containsKey(mealId)) return _mealItemsCache[mealId]!;
    final rows = await DatabaseHelper.instance.getMealItems(mealId);
    _mealItemsCache[mealId] = rows;
    return rows;
  }

  Future<void> _loadBaseCategories() async {
    _baseCategories = await ProductDatabaseHelper.instance.getBaseCategories();
    if (mounted) setState(() {});
  }

  Future<void> _loadCategoryItems(String key) async {
    if (_catItems.containsKey(key) || _loadingCats.contains(key)) return;
    _loadingCats.add(key);
    if (mounted) setState(() {});
    final items = await ProductDatabaseHelper.instance.getBaseFoods(
      categoryKey: key,
      limit: 500, // großzügig – DB ist lokal
    );
    _catItems[key] = items;
    _loadingCats.remove(key);
    if (mounted) setState(() {});
  }

  void _onBaseSearchChanged(String v) {
    _baseSearchDebounce?.cancel();
    /*
    _baseSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      setState(() => _baseSearch = v.trim());
    });
    */
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _currentTab = _tabController.index;
    _tabController.addListener(() {
      if (_currentTab != _tabController.index) {
        setState(() {
          _currentTab = _tabController.index;
        });
      }
    });

    _searchController.addListener(() => setState(() {}));
    _loadFavorites();
    _loadRecentItems();
    _baseSearchCtrl.addListener(
      () => _onBaseSearchChanged(_baseSearchCtrl.text),
    );
    _loadBaseCategories();
    _loadMeals();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_searchInitialText.isEmpty) {
      _searchInitialText = AppLocalizations.of(context)!.searchInitialHint;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _baseSearchDebounce?.cancel();
    _baseSearchCtrl.dispose();
    super.dispose();
  }

  void _runFilter(String enteredKeyword) async {
    final l10n = AppLocalizations.of(context)!;
    if (enteredKeyword.isEmpty) {
      setState(() {
        _foundFoodItems = [];
        _searchInitialText = l10n.searchInitialHint;
      });
      return;
    }
    setState(() {
      _isLoadingSearch = true;
    });

    final results = await ProductDatabaseHelper.instance.searchProducts(
      enteredKeyword,
    );

    if (mounted) {
      setState(() {
        _foundFoodItems = results;
        _isLoadingSearch = false;
        if (results.isEmpty) {
          _searchInitialText = l10n.searchNoResults;
        }
      });
    }
  }

  void _navigateAndCreateFood() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const CreateFoodScreen()))
        .then((_) {
      _searchController.clear();
      _runFilter('');
      _loadFavorites();
      _loadRecentItems();
    });
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoadingFavorites = true;
    });
    final results = await ProductDatabaseHelper.instance.getFavoriteProducts();
    if (mounted) {
      setState(() {
        _favoriteFoodItems = results;
        _isLoadingFavorites = false;
      });
    }
  }

  Future<void> _loadRecentItems() async {
    setState(() {
      _isLoadingRecent = true;
    });
    final results = await ProductDatabaseHelper.instance.getRecentProducts();
    if (mounted) {
      setState(() {
        _recentFoodItems = results;
        _isLoadingRecent = false;
      });
    }
  }

  Future<void> _createMealAndOpenEditor(AppLocalizations l10n) async {
    // Keep a non-empty default name to satisfy the NOT NULL DB constraint.
    final defaultName = l10n.mealTypeLabel; // e.g. "Meal"
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

    // Refresh list state after returning from the editor.
    await _loadMeals();

    // Optional cleanup:
    // If the user exits without changes, remove the placeholder meal.
    try {
      final items = await DatabaseHelper.instance.getMealItems(newMealId);
      // Delete if it still has the default name and no ingredients.
      final created = _meals.firstWhere((m) => m['id'] == newMealId);
      if ((created['name'] as String) == defaultName && items.isEmpty) {
        await DatabaseHelper.instance.deleteMeal(newMealId);
        await _loadMeals();
      }
    } catch (_) {
      /* ignore: cleanup is best-effort */
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    // Compute top padding because the body extends behind the app bar.
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    // Floating action button behavior by active tab.
    VoidCallback? fabOnPressed;
    String fabLabel;
    if (_suspendFab) {
      fabOnPressed = null;
      fabLabel = '';
    } else if (_currentTab == 3) {
      fabLabel = l10n.mealsCreate;
      fabOnPressed = () => _createMealAndOpenEditor(l10n);
    } else {
      fabLabel = l10n.fabCreateOwnFood;
      fabOnPressed = _navigateAndCreateFood;
    }

    return Scaffold(
      extendBodyBehindAppBar: true, // Required for the glass app bar effect.
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // Use GlobalAppBar for consistent top-level navigation styling.
      appBar: GlobalAppBar(title: l10n.nutritionExplorerTitle),

      body: Column(
        children: [
          // Spacer prevents content from rendering below the transparent app bar.
          SizedBox(height: topPadding),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicator: const BoxDecoration(),
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  labelPadding: EdgeInsets.zero,
                  labelColor: isLightMode ? Colors.black : Colors.white,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  tabs: [
                    Tab(text: l10n.tabCatalogSearch),
                    Tab(text: l10n.tabRecent),
                    Tab(text: l10n.tabFavorites),
                    Tab(text: l10n.tabMeals),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCatalogSearchTab(l10n),
                _buildRecentTab(l10n),
                _buildFavoritesTab(l10n),
                _buildMealsTab(l10n),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _suspendFab
          ? null
          : GlassFab(label: fabLabel, onPressed: fabOnPressed ?? () {}),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFavoritesTab(AppLocalizations l10n) {
    if (_isLoadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_favoriteFoodItems.isEmpty) {
      // NEUER, AUFGEWERTETER EMPTY STATE
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: DesignConstants.spacingL),
              Text(
                l10n.noFavorites,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignConstants.spacingS),
              Text(
                l10n.favoritesEmptyState,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: DesignConstants.cardPadding.copyWith(
              bottom: _bottomPadding,
            ),
            itemCount: _favoriteFoodItems.length,
            itemBuilder: (context, index) =>
                _buildFoodListItem(_favoriteFoodItems[index]),
          ),
        ),
        // const BottomContentSpacer(),
        if (_favoriteFoodItems.any((item) => item.source == FoodItemSource.off))
          const OffAttributionWidget(),
      ],
    );
  }

  Widget _buildRecentTab(AppLocalizations l10n) {
    if (_isLoadingRecent) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recentFoodItems.isEmpty) {
      // NEUER, AUFGEWERTETER EMPTY STATE
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: DesignConstants.spacingL),
              Text(
                l10n.nothingTrackedYet,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignConstants.spacingS),
              Text(
                l10n.recentEmptyState,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: DesignConstants.cardPadding.copyWith(
              bottom: _bottomPadding,
            ),
            itemCount: _recentFoodItems.length,
            itemBuilder: (context, index) =>
                _buildFoodListItem(_recentFoodItems[index]),
          ),
        ),
        if (_recentFoodItems.any((item) => item.source == FoodItemSource.off))
          const OffAttributionWidget(),
        //const BottomContentSpacer(),
      ],
    );
  }

  Widget _buildFoodListItem(FoodItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    IconData sourceIcon;
    switch (item.source) {
      case FoodItemSource.base:
        sourceIcon = Icons.star;
        break;
      case FoodItemSource.off:
      case FoodItemSource.user:
        sourceIcon = Icons.inventory_2;
        break;
    }

    return SummaryCard(
      child: ListTile(
        leading: Icon(sourceIcon, color: colorScheme.primary),
        // --- HIER IST DIE ÄNDERUNG ---
        title: Text(
          item.getLocalizedName(context).isNotEmpty
              ? item.getLocalizedName(context)
              : l10n.unknown,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // --- ENDE DER ÄNDERUNG ---
        subtitle: Text(
          l10n.foodItemSubtitle(
            item.brand.isNotEmpty ? item.brand : l10n.noBrand,
            item.calories,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.add_circle_outline,
            color: colorScheme.primary,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(item),
        ),
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FoodDetailScreen(foodItem: item),
            ),
          );
          if (!mounted) return;

          if (result is FoodItem) {
            Navigator.of(context).pop(result);
          } else {
            _loadFavorites();
            _loadRecentItems();
          }
        },
      ),
    );
  }

  // FÜGE DIESE NEUE METHODE HINZU
  void _scanBarcodeAndPop() async {
    final l10n = AppLocalizations.of(context)!;
    // Öffne den Scanner und warte auf einen Barcode (String) als Ergebnis
    final String? barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    // Wenn ein Barcode zurückgegeben wurde und der Screen noch existiert...
    if (barcode != null && mounted) {
      // ...suche das Produkt in der Datenbank.
      final foodItem = await ProductDatabaseHelper.instance.getProductByBarcode(
        barcode,
      );
      if (!mounted) return;

      // Wenn das Produkt gefunden wurde...
      if (foodItem != null) {
        // ...schließe den AddFoodScreen und gib das gefundene Item zurück.
        Navigator.of(context).pop(foodItem);
      } else {
        // Wenn nicht, zeige eine kurze Info-Nachricht.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.snackbarBarcodeNotFound(barcode))),
          );
        }
      }
    }
  }

  Widget _buildCatalogSearchTab(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // UI: Suchleiste + Scanner-Button (wie in _buildSearchTab)
    final searchRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _runFilter, // nutzt deine bestehende Suche
              decoration: InputDecoration(
                hintText: l10n.searchHintText,
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _runFilter('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // AI gradient entry point – only visible when AI is enabled
          if (Provider.of<ThemeService>(context).isAiEnabled) ...[
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFE88DCC),
                    Color(0xFFF4A77A),
                    Color(0xFFF7D06B),
                    Color(0xFF7DDEAE),
                    Color(0xFF6DC8D9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Icon(Icons.auto_awesome),
              ),
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AiMealCaptureScreen(
                      initialDate: widget.initialDate,
                      initialMealType: widget.initialMealType,
                    ),
                  ),
                );
                if (result == true && mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.qr_code_scanner, color: colorScheme.primary),
            onPressed: _scanBarcodeAndPop,
          ),
        ],
      ),
    );

    // FALL A: Kein Query → Kategorien/Accordion aus Base-DB (deine vorhandene Logik)

    final String q = _searchController.text.trim();
    if (q.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 12),
          searchRow,
          const SizedBox(height: 8),
          if (_baseCategories.isEmpty)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _catItems.clear();
                await _loadBaseCategories();
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: _bottomPadding),
                itemCount: _baseCategories.length + 1,
                itemBuilder: (context, idx) {
                  if (idx == _baseCategories.length) {
                    return const BottomContentSpacer();
                  }

                  final cat = _baseCategories[idx];
                  final key = cat['key'] as String;
                  final emoji = (cat['emoji'] as String?)?.trim();
                  final locale = Localizations.localeOf(context).languageCode;
                  final title = () {
                    final de = (cat['name_de'] as String?)?.trim();
                    final en = (cat['name_en'] as String?)?.trim();
                    if (locale == 'de') {
                      return (de?.isNotEmpty == true)
                          ? de!
                          : (en?.isNotEmpty == true ? en! : key);
                    } else {
                      return (en?.isNotEmpty == true)
                          ? en!
                          : (de?.isNotEmpty == true ? de! : key);
                    }
                  }();

                  final loading = _loadingCats.contains(key);
                  final items = _catItems[key];

                  return Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Text(
                        emoji?.isNotEmpty == true ? emoji! : '🗂️',
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(title),
                      initiallyExpanded: false,
                      onExpansionChanged: (expanded) {
                        if (expanded) _loadCategoryItems(key);
                      },
                      children: [
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (items == null || items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: Text(l10n.emptyCategory)),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: DesignConstants.cardPadding.copyWith(
                              top: 0,
                            ),
                            itemCount: items.length,
                            itemBuilder: (_, i) => _buildFoodListItem(items[i]),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    // FALL B: Mit Query → zuerst Base-Items, dann OFF/User-Items (Priorisierung)
    final baseHits = _foundFoodItems
        .where((it) => it.source == FoodItemSource.base)
        .toList();
    final otherHits = _foundFoodItems
        .where((it) => it.source != FoodItemSource.base)
        .toList();

    return Column(
      children: [
        const SizedBox(height: 12),
        searchRow,
        const SizedBox(height: 12),
        Expanded(
          child: _isLoadingSearch
              ? const Center(child: CircularProgressIndicator())
              : (baseHits.isEmpty && otherHits.isEmpty)
                  ? Center(
                      child: Text(
                        l10n.searchNoResults,
                        style: textTheme.titleMedium,
                      ),
                    )
                  : ListView(
                      padding: DesignConstants.cardPadding.copyWith(
                        bottom: _bottomPadding,
                      ),
                      children: [
                        if (baseHits.isNotEmpty) ...[
                          Text(
                            l10n.searchSectionBase,
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...baseHits.map(_buildFoodListItem),
                          const SizedBox(height: DesignConstants.spacingL),
                        ],
                        if (otherHits.isNotEmpty) ...[
                          Text(
                            l10n.searchSectionOther,
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...otherHits.map(_buildFoodListItem),
                        ],
                        if (otherHits
                            .any((i) => i.source == FoodItemSource.off))
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: OffAttributionWidget(),
                          ),
                        const BottomContentSpacer(),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildMealsTab(AppLocalizations l10n) {
    if (_isLoadingMeals) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_meals.isEmpty) {
      // Empty State: kein Top-Button mehr – Erstellen läuft über den FAB
      return Center(
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
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMeals,
      child: ListView.builder(
        padding: DesignConstants.cardPadding.copyWith(bottom: _bottomPadding),
        itemCount: _meals.length, // FIX: +1 entfernt, da Padding genutzt wird
        itemBuilder: (_, i) {
          final meal = _meals[i];
          return _buildMealCard(meal, l10n);
        },
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, AppLocalizations l10n) {
    final color = Theme.of(context).colorScheme;

    Future<Map<String, num>> computeMealTotals(int mealId) async {
      final items = await _getMealItems(mealId);
      int kcal = 0;
      double c = 0, f = 0, p = 0;

      for (final it in items) {
        final bc = it['barcode'] as String;
        final qty = (it['quantity_in_grams'] as num?)?.toDouble() ?? 0.0;
        final fi = await ProductDatabaseHelper.instance.getProductByBarcode(bc);
        if (fi == null) continue;

        final factor = qty / 100.0;
        kcal += ((fi.calories) * factor).round();
        c += (fi.carbs) * factor;
        f += (fi.fat) * factor;
        p += (fi.protein) * factor;
      }
      return {'kcal': kcal, 'c': c, 'f': f, 'p': p};
    }

    return SummaryCard(
      child: ListTile(
        leading: Icon(Icons.restaurant, color: color.primary),
        title: Text(meal['name'] as String),
        subtitle: FutureBuilder<Map<String, num>>(
          future: computeMealTotals(meal['id'] as int),
          builder: (_, snap) {
            // Fallback: nur Anzahl Zutaten, falls noch lädt
            if (!snap.hasData) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _getMealItems(meal['id'] as int),
                builder: (_, s2) {
                  final count = s2.data?.length ?? 0;
                  return Text('${l10n.mealIngredientsTitle}: $count');
                },
              );
            }
            final t = snap.data!;
            final c = (t['c'] ?? 0).toDouble();
            final f = (t['f'] ?? 0).toDouble();
            final p = (t['p'] ?? 0).toDouble();
            final kcal = (t['kcal'] ?? 0).toInt();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getMealItems(meal['id'] as int),
                  builder: (_, s2) {
                    final count = s2.data?.length ?? 0;
                    return Text('${l10n.mealIngredientsTitle}: $count');
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  '$kcal kcal   •   C ${c.toStringAsFixed(1)} g   •   F ${f.toStringAsFixed(1)} g   •   P ${p.toStringAsFixed(1)} g',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            );
          },
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: l10n.mealsAddToDiary,
              icon: Icon(Icons.add_circle_outline, color: color.primary),
              onPressed: () => _confirmAndLogMeal(meal, l10n),
            ),
            IconButton(
              tooltip: l10n.mealsEdit,
              icon: const Icon(Icons.edit),
              onPressed: () async {
                // Neuer Screen öffnen (View), direkt in Edit wechseln
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MealScreen(meal: meal, startInEdit: true),
                  ),
                );
                await _loadMeals();
              },
            ),
            IconButton(
              tooltip: l10n.mealsDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteMeal(meal, l10n),
            ),
          ],
        ),
        onTap: () async {
          // Neuer Detail-Screen (View)
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => MealScreen(meal: meal)));
          await _loadMeals();
        },
      ),
    );
  }

  Future<void> _deleteMeal(
    Map<String, dynamic> meal,
    AppLocalizations l10n,
  ) async {
    // NEU: Helper
    final ok = await showDeleteConfirmation(
      context,
      title: l10n.mealDeleteConfirmTitle,
      content: l10n.mealDeleteConfirmBody(meal['name'] as String),
    );

    if (!ok) return;
    await DatabaseHelper.instance.deleteMeal(meal['id'] as int);
    _mealItemsCache.remove(meal['id'] as int);
    await _loadMeals();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.mealDeleted)));
    }
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

    final Map<String, FoodItem?> products = {};
    for (final it in rawItems) {
      final bc = it['barcode'] as String;
      products[bc] = await ProductDatabaseHelper.instance.getProductByBarcode(
        bc,
      );
    }

    final Map<String, TextEditingController> qtyCtrls = {
      for (final it in rawItems)
        (it['barcode'] as String): TextEditingController(
          text: '${it['quantity_in_grams']}',
        ),
    };

    const internalTypes = [
      'mealtypeBreakfast',
      'mealtypeLunch',
      'mealtypeDinner',
      'mealtypeSnack',
    ];

    // Initialwerte aus Widget-Parametern oder Defaults
    String selectedMealType = widget.initialMealType ?? internalTypes.first;
    if (!internalTypes.contains(selectedMealType)) {
      selectedMealType = internalTypes.first;
    }

    DateTime selectedDate = widget.initialDate ?? DateTime.now();

    final Map<String, String> mealTypeLabel = {
      'mealtypeBreakfast': l10n.mealtypeBreakfast,
      'mealtypeLunch': l10n.mealtypeLunch,
      'mealtypeDinner': l10n.mealtypeDinner,
      'mealtypeSnack': l10n.mealtypeSnack,
    };
    if (!mounted) return;

    final ok = await showGlassBottomMenu<bool>(
          context: context,
          title: l10n.mealsAddToDiary,
          contentBuilder: (ctx, close) {
            return StatefulBuilder(
              builder: (ctx, modalSetState) {
                final locale = Localizations.localeOf(ctx).toString();
                final formattedDate = DateFormat.yMd(
                  locale,
                ).format(selectedDate);
                final formattedTime = DateFormat.Hm(
                  locale,
                ).format(selectedDate);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      meal['name'] as String,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),

                    // Datum & Zeit Auswahl
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(formattedDate),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              modalSetState(() {
                                selectedDate = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  selectedDate.hour,
                                  selectedDate.minute,
                                );
                              });
                            }
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(formattedTime),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.fromDateTime(selectedDate),
                            );
                            if (picked != null) {
                              modalSetState(() {
                                selectedDate = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  picked.hour,
                                  picked.minute,
                                );
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      initialValue: selectedMealType,
                      decoration: InputDecoration(
                        labelText: l10n.mealTypeLabel,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                      ),
                      items: internalTypes
                          .map(
                            (key) => DropdownMenuItem(
                              value: key,
                              child: Text(mealTypeLabel[key] ?? key),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          modalSetState(() => selectedMealType = v);
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: rawItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final it = rawItems[i];
                          final bc = it['barcode'] as String;
                          final fi = products[bc];
                          final displayName =
                              (fi?.name.isNotEmpty ?? false) ? fi!.name : bc;
                          final unit = (fi?.isLiquid == true) ? 'ml' : 'g';

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 18),
                                child: Icon(Icons.lunch_dining, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: qtyCtrls[bc],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: displayName,
                                    suffixText: unit,
                                    filled: true,
                                    fillColor: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              close();
                              Navigator.of(ctx).pop(false);
                            },
                            child: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              close();
                              Navigator.of(ctx).pop(true);
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
          },
        ) ??
        false;

    if (!ok) return;

    // Nutze das ausgewählte Datum (selectedDate) statt DateTime.now()
    for (final it in rawItems) {
      final bc = it['barcode'] as String;
      final ctrl = qtyCtrls[bc]!;
      final qty =
          int.tryParse(ctrl.text.trim()) ?? (it['quantity_in_grams'] as int);

      await DatabaseHelper.instance.insertFoodEntry(
        FoodEntry(
          barcode: bc,
          timestamp: selectedDate, // <--- VERWENDUNG
          quantityInGrams: qty,
          mealType: selectedMealType,
        ),
      );

      final fi = products[bc];
      if (fi != null) {
        final c100 = fi.caffeineMgPer100ml;
        if (fi.isLiquid == true && c100 != null && c100 > 0) {
          await _logCaffeineDose(
            c100 * (qty / 100.0),
            selectedDate,
          ); // <--- VERWENDUNG
        }
      }
    }

    if (mounted) {
      HapticFeedbackService.instance.confirmationFeedback();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.mealAddedToDiarySuccess)));
    }
  }

  Future<void> _logCaffeineDose(double doseMg, DateTime timestamp) async {
    if (doseMg <= 0) return;

    // Caffeine-Supplement suchen/anlegen
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
        (await DatabaseHelper.instance.insertSupplement(caffeine)).id!;

    await DatabaseHelper.instance.insertSupplementLog(
      SupplementLog(
        supplementId: caffeineId,
        dose: doseMg,
        unit: 'mg',
        timestamp: timestamp,
        // source_food_entry_id: hier könnten wir verlinken, wenn wir die neue FoodEntry-ID hätten –
        // in diesem Flow buchen wir mehrere; Verlinkung kannst du später erweitern.
      ),
    );
  }
}
