import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/ai_meal_validation.dart';
import '../../../../services/theme_service.dart';
import '../../../../widgets/common/macro_badge_row.dart';

/// Builds the compact per-portion macro badges row (kcal, P, C, F) for AI meal review items.
class MealReviewMacrosBar extends StatelessWidget {
  final AiNutritionTotals nutrition;

  const MealReviewMacrosBar({
    super.key,
    required this.nutrition,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isZero = nutrition.kcalRounded == 0 &&
        nutrition.proteinRounded == 0 &&
        nutrition.carbsRounded == 0 &&
        nutrition.fatRounded == 0;

    if (isZero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '---',
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
        ),
      );
    }

    return MacroBadgeRow(
      kcal: nutrition.kcalRounded,
      protein: nutrition.proteinRounded.toDouble(),
      carbs: nutrition.carbsRounded.toDouble(),
      fat: nutrition.fatRounded.toDouble(),
      useBadges: Provider.of<ThemeService>(context, listen: false).useColorfulMacroBadges,
    );
  }
}
