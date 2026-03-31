// lib/widgets/compact_nutrition_bar.dart

import 'package:flutter/material.dart';
import '../models/daily_nutrition.dart';
import '../util/design_constants.dart';

/// A compact visual overview of daily nutrition and hydration progress.
///
/// Displays progress bars for calories, protein, and water intake.
class CompactNutritionBar extends StatelessWidget {
  /// The [nutritionData] to visualize in this bar.
  final DailyNutrition nutritionData;
  const CompactNutritionBar({super.key, required this.nutritionData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: DesignConstants.cardMargin,
      child: Column(
        children: [
          _buildProgressBar(
            context: context,
            label: 'Kalorien',
            value: nutritionData.calories.toDouble(),
            target: nutritionData.targetCalories.toDouble(),
            unit: 'kcal',
            color: Colors.orange,
          ),
          const SizedBox(height: DesignConstants.spacingM),
          _buildProgressBar(
            context: context,
            label: 'Protein',
            value: nutritionData.protein.toDouble(),
            target: nutritionData.targetProtein.toDouble(),
            unit: 'g',
            color: Colors.red.shade400,
          ),
          const SizedBox(height: DesignConstants.spacingM),
          _buildProgressBar(
            context: context,
            label: 'Wasser',
            value: nutritionData.water.toDouble(),
            target: nutritionData.targetWater.toDouble(),
            unit: 'L',
            isWater: true,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required BuildContext context,
    required String label,
    required double value,
    required double target,
    required String unit,
    required Color color,
    bool isWater = false,
  }) {
    final progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    final displayValue =
        isWater ? (value / 1000).toStringAsFixed(1) : value.toStringAsFixed(0);
    final displayTarget = isWater
        ? (target / 1000).toStringAsFixed(0)
        : target.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '$displayValue / $displayTarget $unit',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
