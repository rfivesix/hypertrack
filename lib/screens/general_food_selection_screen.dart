import 'package:flutter/material.dart';
import '../data/product_database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/food_item.dart';
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

class _GeneralFoodSelectionScreenState extends State<GeneralFoodSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodItem> _results = [];
  bool _isLoading = false;
  String _searchInitialText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
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
              child: _isLoading
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
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            return SummaryCard(
                              child: ListTile(
                                leading: const Icon(Icons.restaurant),
                                title: Text(
                                  item.getLocalizedName(context),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  item.brand.isNotEmpty
                                      ? '${item.brand} • ${item.calories} kcal/100g'
                                      : '${item.calories} kcal/100g',
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    color: colorScheme.primary,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(item),
                                ),
                                onTap: () => Navigator.of(context).pop(item),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
