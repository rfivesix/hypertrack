// lib/widgets/compact_nutrition_bar.dart

import 'package:flutter/material.dart';
import '../../../../models/daily_nutrition.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/glass_progress_bar.dart';

/// A compact visual overview of daily nutrition and hydration progress.
///
/// Displays progress bars for calories, protein, and water intake.
class CompactNutritionBar extends StatelessWidget {
  /// The [nutritionData] to visualize in this bar.
  final DailyNutrition nutritionData;
  const CompactNutritionBar({super.key, required this.nutritionData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassProgressBar(
          label: 'Kalorien',
          value: nutritionData.calories.toDouble(),
          target: nutritionData.targetCalories.toDouble(),
          unit: 'kcal',
          color: Colors.orange,
        ),
        const SizedBox(height: DesignConstants.spacingM),
        GlassProgressBar(
          label: 'Protein',
          value: nutritionData.protein.toDouble(),
          target: nutritionData.targetProtein.toDouble(),
          unit: 'g',
          color: Colors.red.shade400,
        ),
        const SizedBox(height: DesignConstants.spacingM),
        GlassProgressBar(
          label: 'Wasser',
          value: nutritionData.water / 1000,
          target: nutritionData.targetWater / 1000,
          unit: 'L',
          color: Colors.blue,
        ),
      ],
    );
  }
}
