import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/base_food_language_service.dart';
import '../../../../services/theme_service.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../domain/models/food_item.dart';

class FoodItemSearchTile extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  const FoodItemSearchTile({
    super.key,
    required this.item,
    required this.onAdd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final themeService = Provider.of<ThemeService>(context);
    final baseFoodLang = BaseFoodLanguageService.resolveLanguageCode(
      choice: themeService.baseFoodLanguage,
      context: context,
    );

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
        title: Text(
          () {
            final name = item.source == FoodItemSource.base
                ? item.getLocalizedName(context, languageCode: baseFoodLang)
                : item.getLocalizedName(context);
            return name.isNotEmpty ? name : l10n.unknown;
          }(),
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
          onPressed: onAdd,
        ),
        onTap: onTap,
      ),
    );
  }
}
