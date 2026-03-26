// lib/screens/food_explorer_screen.dart (Final & De-Materialisiert)

import 'package:flutter/material.dart';
import '../data/product_database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/food_item.dart';
import 'create_food_screen.dart';
import 'food_detail_screen.dart';
import '../util/design_constants.dart';
import '../widgets/glass_fab.dart';
import '../widgets/off_attribution_widget.dart';
import '../widgets/summary_card.dart'; // HINZUGEFÜGT

/// A screen for exploring and managing the food database independently of tracking.
///
/// Allows searching for products and managing favorites without requiring
/// a target date or meal context.
class FoodExplorerScreen extends StatefulWidget {
  const FoodExplorerScreen({super.key});

  @override
  State<FoodExplorerScreen> createState() => _FoodExplorerScreenState();
}

class _FoodExplorerScreenState extends State<FoodExplorerScreen>
    with SingleTickerProviderStateMixin {
  List<FoodItem> _foundFoodItems = [];
  bool _isLoadingSearch = false;
  String _searchInitialText = "";
  final _searchController = TextEditingController();

  List<FoodItem> _favoriteFoodItems = [];
  bool _isLoadingFavorites = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() => setState(() {}));
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
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

  // lib/screens/food_explorer_screen.dart

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // KORREKTUR: Direkte Abfrage des Theme-Modus
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.addFoodTitle,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingL),
                TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicator: const BoxDecoration(),
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  dividerColor: Colors.transparent,
                  // KORREKTUR: Dynamische Farbe basierend auf dem Theme-Modus
                  labelColor: isLightMode ? Colors.black : Colors.white,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.0,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.0,
                  ),
                  tabs: [
                    Tab(text: l10n.tabSearch),
                    Tab(text: l10n.tabFavorites),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.onSurfaceVariant.withOpacity(0.1),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildSearchTab(l10n), _buildFavoritesTab(l10n)],
            ),
          ),
        ],
      ),
      floatingActionButton: GlassFab(
        onPressed: _navigateAndCreateFood,
        label: l10n.createFoodScreenTitle,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSearchTab(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: DesignConstants.cardPadding,
      child: Column(
        children: [
          // KORREKTUR 4: TextField nutzt globale InputDecorationTheme
          TextField(
            controller: _searchController,
            onChanged: (value) => _runFilter(value),
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
          const SizedBox(height: 20),
          Expanded(
            child: _isLoadingSearch
                ? const Center(child: CircularProgressIndicator())
                : _foundFoodItems.isNotEmpty
                ? ListView.builder(
                    itemCount: _foundFoodItems.length,
                    itemBuilder: (context, index) =>
                        _buildFoodListItem(_foundFoodItems[index]),
                  )
                : Center(
                    child: Text(
                      _searchInitialText,
                      style: textTheme.titleMedium,
                    ),
                  ),
          ),
          if (_foundFoodItems.any((item) => item.source == FoodItemSource.off))
            const OffAttributionWidget(),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(AppLocalizations l10n) {
    if (_isLoadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_favoriteFoodItems.isEmpty) {
      return Center(
        child: Text(
          l10n.favoritesEmptyState,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: DesignConstants.cardPadding,
            itemCount: _favoriteFoodItems.length,
            itemBuilder: (context, index) =>
                _buildFoodListItem(_favoriteFoodItems[index]),
          ),
        ),
        if (_favoriteFoodItems.any((item) => item.source == FoodItemSource.off))
          const OffAttributionWidget(),
      ],
    );
  }

  // KORREKTUR 5: _buildFoodListItem verwendet jetzt SummaryCard
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
      // KORREKTUR: Jetzt mit SummaryCard
      child: ListTile(
        leading: Icon(sourceIcon, color: colorScheme.primary),
        title: Text(
          item.name.isNotEmpty ? item.name : l10n.unknown,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
        onTap: () => Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => FoodDetailScreen(foodItem: item),
              ),
            )
            .then((_) {
              _loadFavorites();
            }),
      ),
    );
  }
}
