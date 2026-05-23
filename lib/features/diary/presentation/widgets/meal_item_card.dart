import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/theme_service.dart';
import '../../../../widgets/common/macro_badge_row.dart';
import '../../../../widgets/common/summary_card.dart';
import '../add_food_screen.dart';

class MealItemCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  final Future<MealCardNutritionTotals> mealTotalsFuture;
  final int ingredientCount;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const MealItemCard({
    super.key,
    required this.meal,
    required this.mealTotalsFuture,
    required this.ingredientCount,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final themeService = Provider.of<ThemeService>(context);

    return SummaryCard(
      child: ListTile(
        leading: Icon(Icons.restaurant, color: color.primary),
        title: Text(meal['name'] as String),
        subtitle: FutureBuilder<MealCardNutritionTotals>(
          future: mealTotalsFuture,
          builder: (_, snap) {
            final totals = snap.data;
            final count = totals?.ingredientCount ?? ingredientCount;

            if (totals == null) {
              return Text('${AppLocalizations.of(context)!.mealIngredientsTitle}: $count');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${AppLocalizations.of(context)!.mealIngredientsTitle}: $count'),
                const SizedBox(height: 2),
                MacroBadgeRow(
                  kcal: totals.kcal,
                  protein: totals.protein,
                  carbs: totals.carbs,
                  fat: totals.fat,
                  useBadges: themeService.useColorfulMacroBadges,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            );
          },
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: AppLocalizations.of(context)!.mealsAddToDiary,
              icon: Icon(Icons.add_circle_outline, color: color.primary),
              onPressed: onAdd,
            ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.mealsEdit,
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.mealsDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
