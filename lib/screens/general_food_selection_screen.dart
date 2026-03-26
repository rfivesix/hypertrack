import 'package:flutter/material.dart';
import '../data/product_database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/food_item.dart';
import 'food_detail_screen.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';

/// A lightweight, general-purpose food picker that returns a [FoodItem].
///
/// This screen is intentionally minimal and should be used in non-diary
/// contexts that only need to select an item.
class GeneralFoodSelectionScreen extends StatefulWidget {
  const GeneralFoodSelectionScreen({super.key});

  @override
  State<GeneralFoodSelectionScreen> createState() =>
      _GeneralFoodSelectionScreenState();
}

class _GeneralFoodSelectionScreenState
    extends State<GeneralFoodSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodItem> _results = [];
  bool _isLoading = false;
  String _searchInitialText = '';
  List<Map<String, dynamic>> _baseCategories = [];
  final Map<String, List<FoodItem>> _catItems = {};
  final Set<String> _loadingCats = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadBaseCategories();
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
    super.dispose();
  }

  Future<void> _runFilter(String enteredKeyword) async {
    final l10n = AppLocalizations.of(context)!;
    if (enteredKeyword.isEmpty) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _searchInitialText = l10n.searchInitialHint;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final results = await ProductDatabaseHelper.instance.searchProducts(
      enteredKeyword,
    );
    if (!mounted) return;

    setState(() {
      _results = results;
      _isLoading = false;
      if (results.isEmpty) {
        _searchInitialText = l10n.searchNoResults;
      }
    });
  }

  Future<void> _loadBaseCategories() async {
    _baseCategories = await ProductDatabaseHelper.instance.getBaseCategories();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadCategoryItems(String key) async {
    if (_catItems.containsKey(key) || _loadingCats.contains(key)) return;
    _loadingCats.add(key);
    if (mounted) setState(() {});
    final items = await ProductDatabaseHelper.instance.getBaseFoods(
      categoryKey: key,
      limit: 500,
    );
    _catItems[key] = items;
    _loadingCats.remove(key);
    if (mounted) setState(() {});
  }

  Widget _buildFoodListItem(FoodItem item, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = l10n.foodItemSubtitle(
      item.brand.isNotEmpty ? item.brand : l10n.noBrand,
      item.calories,
    );

    return SummaryCard(
      child: ListTile(
        leading: Icon(
          item.source == FoodItemSource.base ? Icons.star : Icons.inventory_2,
          color: colorScheme.primary,
        ),
        title: Text(
          item.getLocalizedName(context).isNotEmpty
              ? item.getLocalizedName(context)
              : l10n.unknown,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(item),
        ),
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FoodDetailScreen(foodItem: item),
            ),
          );

          if (result is FoodItem && mounted) {
            Navigator.of(context).pop(result);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: GlobalAppBar(title: l10n.addFoodTitle),
      body: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _runFilter,
              decoration: InputDecoration(
                hintText: l10n.searchHintText,
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
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
            const SizedBox(height: DesignConstants.spacingM),
            Expanded(
              child: _searchController.text.trim().isEmpty
                  ? (_baseCategories.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: _baseCategories.length,
                            itemBuilder: (context, idx) {
                              final cat = _baseCategories[idx];
                              final key = cat['key'] as String;
                              final emoji = (cat['emoji'] as String?)?.trim();
                              final locale = Localizations.localeOf(
                                context,
                              ).languageCode;
                              final de = (cat['name_de'] as String?)?.trim();
                              final en = (cat['name_en'] as String?)?.trim();
                              final title = locale == 'de'
                                  ? (de?.isNotEmpty == true
                                        ? de!
                                        : (en?.isNotEmpty == true ? en! : key))
                                  : (en?.isNotEmpty == true
                                        ? en!
                                        : (de?.isNotEmpty == true ? de! : key));

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
                                  onExpansionChanged: (expanded) {
                                    if (expanded) _loadCategoryItems(key);
                                  },
                                  children: [
                                    if (loading)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    else if (items == null || items.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: Text(l10n.emptyCategory),
                                        ),
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        padding: DesignConstants.cardPadding
                                            .copyWith(top: 0),
                                        itemCount: items.length,
                                        itemBuilder: (_, i) =>
                                            _buildFoodListItem(items[i], l10n),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ))
                  : (_isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _results.isEmpty
                        ? Center(
                            child: Text(
                              _searchInitialText,
                              style: textTheme.titleMedium,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) =>
                                _buildFoodListItem(_results[index], l10n),
                          )),
            ),
          ],
        ),
      ),
    );
  }
}
