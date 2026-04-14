/*// lib/widgets/nutrition_summary_widget.dart

import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import '../models/daily_nutrition.dart';
import '../util/design_constants.dart';
import 'summary_card.dart';
import 'dart:ui'; // Für den ImageFilter.blur

class _NutrientSpec {
  final String label;
  final String unit;
  final double value;
  final double target;
  final Color color;

  _NutrientSpec({
    required this.label,
    required this.unit,
    required this.value,
    required this.target,
    required this.color,
  });
}

class NutritionSummaryWidget extends StatelessWidget {
  final DailyNutrition nutritionData;
  final bool isExpandedView;
  final AppLocalizations l10n;

  const NutritionSummaryWidget({
    super.key,
    required this.nutritionData,
    this.isExpandedView = false,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final specs = <String, _NutrientSpec>{
      'calories': _NutrientSpec(
          label: l10n.calories,
          unit: 'kcal',
          value: nutritionData.calories.toDouble(),
          target: nutritionData.targetCalories.toDouble(),
          color: Colors.orange),
      'water': _NutrientSpec(
          label: l10n.water,
          unit: 'ml',
          value: nutritionData.water.toDouble(),
          target: nutritionData.targetWater.toDouble(),
          color: Colors.blue),
      'protein': _NutrientSpec(
          label: l10n.protein,
          unit: 'g',
          value: nutritionData.protein.toDouble(),
          target: nutritionData.targetProtein.toDouble(),
          color: Colors.red.shade400),
      'carbs': _NutrientSpec(
          label: l10n.carbs,
          unit: 'g',
          value: nutritionData.carbs.toDouble(),
          target: nutritionData.targetCarbs.toDouble(),
          color: Colors.green.shade400),
      'fat': _NutrientSpec(
          label: l10n.fat,
          unit: 'g',
          value: nutritionData.fat.toDouble(),
          target: nutritionData.targetFat.toDouble(),
          color: Colors.purple.shade300),
      'sugar': _NutrientSpec(
          label: l10n.sugar,
          unit: 'g',
          value: nutritionData.sugar,
          target: nutritionData.targetSugar.toDouble(),
          color: Colors.pink.shade200),
      'fiber': _NutrientSpec(
          label: l10n.fiber,
          unit: 'g',
          value: nutritionData.fiber,
          target: nutritionData.targetFiber.toDouble(),
          color: Colors.brown.shade400),
      'salt': _NutrientSpec(
          label: l10n.salt,
          unit: 'g',
          value: nutritionData.salt,
          target: nutritionData.targetSalt.toDouble(),
          color: Colors.grey.shade500),
    };

    return SummaryCard(
      // KORREKTUR: internalPadding für diese spezifische Karte ist 12.0
      //internalPadding: const EdgeInsets.all(12.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3, // KORREKTUR 2: Flex-Wert erhöht, um mehr Platz zu geben
              child: Column(
                children: [
                  Expanded(child: _InfoBox(spec: specs['calories']!)),
                  const SizedBox(height: DesignConstants.spacingS),
                  Expanded(child: _InfoBox(spec: specs['water']!)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4, // KORREKTUR 2: Flex-Wert erhöht
              child: Column(
                children: [
                  Expanded(child: _InfoBox(spec: specs['protein']!)),
                  const SizedBox(height: DesignConstants.spacingS),
                  Expanded(child: _InfoBox(spec: specs['carbs']!)),
                  const SizedBox(height: DesignConstants.spacingS),
                  Expanded(child: _InfoBox(spec: specs['fat']!)),
                ],
              ),
            ),
            if (isExpandedView) ...[
              const SizedBox(width: 8),
              Expanded(
                flex: 4, // KORREKTUR 2: Flex-Wert erhöht
                child: Column(
                  children: [
                    Expanded(child: _InfoBox(spec: specs['sugar']!)),
                    const SizedBox(height: DesignConstants.spacingS),
                    Expanded(child: _InfoBox(spec: specs['fiber']!)),
                    const SizedBox(height: DesignConstants.spacingS),
                    Expanded(child: _InfoBox(spec: specs['salt']!)),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
// Ersetze die komplette _InfoBox Klasse in lib/widgets/nutrition_summary_widget.dart

class _InfoBox extends StatelessWidget {
  final _NutrientSpec spec;
  const _InfoBox({required this.spec});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final colorScheme = theme.colorScheme;

    final hasTarget = spec.target > 0;
    final rawProgress = hasTarget ? (spec.value / spec.target) : 0.0;
    final progress = rawProgress.clamp(0.0, 1.0);

    // Farben für den Glas-Effekt, identisch zur SummaryCard
    final backgroundColor = brightness == Brightness.dark
        ? Colors.white.withValues(alpha:0.10)
        : Colors.white.withValues(alpha:0.65);

    final borderColor = brightness == Brightness.dark
        ? Colors.white.withValues(alpha:0.20)
        : Colors.black.withValues(alpha:0.12);

    return Container(
      // Die Dekoration ist jetzt die Glas-Dekoration
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
            9), // Etwas weniger Rundung für die kleinen Boxen
        border: Border.all(
          color: borderColor,
          width: 1.0, // Etwas dünnerer Rand
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: BackdropFilter(
          filter:
              ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0), // Etwas weniger Blur
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Der animierte Füllbalken bleibt erhalten
              Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  builder: (context, p, child) =>
                      FractionallySizedBox(widthFactor: p, child: child),
                  child: Container(color: spec.color),
                ),
              ),
              // Der Text-Inhalt liegt über dem Füllbalken
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        spec.label,
                        maxLines: 1,
                        style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasTarget
                          ? '${spec.value.toStringAsFixed(1)} / ${spec.target.toStringAsFixed(0)} ${spec.unit}'
                          : '${spec.value.toStringAsFixed(1)} ${spec.unit}',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha:0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
// lib/widgets/nutrition_summary_widget.dart

import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import '../models/daily_nutrition.dart';
import '../util/design_constants.dart';

import 'glass_progress_bar.dart'; // Für den ImageFilter.blur

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
                    unit: 'ml',
                    value: nutritionData.water.toDouble(),
                    target: nutritionData.targetWater.toDouble(),
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
