// lib/widgets/nutrition_summary_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../models/daily_nutrition.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/glass_progress_bar.dart';

/// A comprehensive summary widget for daily nutrition and macro tracking.
///
/// Displays multiple [GlassProgressBar]s in a grid-like layout for calories,
/// water, protein, carbs, and fats. Can be expanded to show sub-macros like sugar.
class NutritionSummaryWidget extends StatelessWidget {
  /// The daily nutrition data to display.
  final DailyNutrition nutritionData;

  /// Whether to show the expanded set of macros (e.g., sugar, fiber, salt, caffeine).
  final bool isExpandedView;
  final bool showSugarInOverview;

  /// Localization instance for labels.
  final AppLocalizations l10n;

  const NutritionSummaryWidget({
    super.key,
    required this.nutritionData,
    this.isExpandedView = false,
    this.showSugarInOverview = false,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final showSugarTile = !isExpandedView && showSugarInOverview;
    final unitService = context.watch<UnitService>();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: GlassProgressBar(
                    label: l10n.calories,
                    unit: 'kcal',
                    value: nutritionData.calories.toDouble(),
                    target: nutritionData.targetCalories.toDouble(),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingS),
                Expanded(
                  child: GlassProgressBar(
                    label: l10n.water,
                    unit: unitService.suffixFor(UnitDimension.liquid),
                    value: unitService.convertDisplayValue(
                      nutritionData.water.toDouble(),
                      UnitDimension.liquid,
                    ),
                    target: unitService.convertDisplayValue(
                      nutritionData.targetWater.toDouble(),
                      UnitDimension.liquid,
                    ),
                    color: Colors.blue,
                  ),
                ),
                if (showSugarTile) ...[
                  const SizedBox(height: DesignConstants.spacingS),
                  Expanded(
                    child: GlassProgressBar(
                      label: l10n.sugar,
                      unit: 'g',
                      value: nutritionData.sugar,
                      target: nutritionData.targetSugar.toDouble(),
                      color: Colors.pink.shade200,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: GlassProgressBar(
                    label: l10n.protein,
                    unit: 'g',
                    value: nutritionData.protein.toDouble(),
                    target: nutritionData.targetProtein.toDouble(),
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingS),
                Expanded(
                  child: GlassProgressBar(
                    label: l10n.carbs,
                    unit: 'g',
                    value: nutritionData.carbs.toDouble(),
                    target: nutritionData.targetCarbs.toDouble(),
                    color: Colors.green.shade400,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingS),
                Expanded(
                  child: GlassProgressBar(
                    label: l10n.fat,
                    unit: 'g',
                    value: nutritionData.fat.toDouble(),
                    target: nutritionData.targetFat.toDouble(),
                    color: Colors.purple.shade300,
                  ),
                ),
              ],
            ),
          ),
          if (isExpandedView) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Expanded(
                    child: GlassProgressBar(
                      label: l10n.sugar,
                      unit: 'g',
                      value: nutritionData.sugar,
                      target: nutritionData.targetSugar.toDouble(),
                      color: Colors.pink.shade200,
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  Expanded(
                    child: GlassProgressBar(
                      label: l10n.fiber,
                      unit: 'g',
                      value: nutritionData.fiber,
                      target: nutritionData.targetFiber.toDouble(),
                      color: Colors.brown.shade400,
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  Expanded(
                    child: GlassProgressBar(
                      label: l10n.salt,
                      unit: 'g',
                      value: nutritionData.salt,
                      target: nutritionData.targetSalt.toDouble(),
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  Expanded(
                    child: GlassProgressBar(
                      label: l10n.supplement_caffeine,
                      unit: 'mg',
                      value: nutritionData.caffeine,
                      target: nutritionData.targetCaffeine.toDouble(),
                      color: Colors.brown,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
