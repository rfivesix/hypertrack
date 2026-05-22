import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../domain/models/food_item.dart';

class CatalogCategoryTile extends StatelessWidget {
  final String categoryKey;
  final String title;
  final String? emoji;
  final bool isLoading;
  final List<FoodItem>? items;
  final ValueChanged<bool> onExpansionChanged;
  final Widget Function(FoodItem) itemTileBuilder;

  const CatalogCategoryTile({
    super.key,
    required this.categoryKey,
    required this.title,
    required this.emoji,
    required this.isLoading,
    required this.items,
    required this.onExpansionChanged,
    required this.itemTileBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoryItems = items;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Text(
          emoji?.isNotEmpty == true ? emoji! : '🗂️',
          style: const TextStyle(fontSize: 20),
        ),
        title: Text(title),
        initiallyExpanded: false,
        onExpansionChanged: onExpansionChanged,
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (categoryItems == null || categoryItems.isEmpty)
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
              itemCount: categoryItems.length,
              itemBuilder: (context, i) => itemTileBuilder(categoryItems[i]),
            ),
        ],
      ),
    );
  }
}
