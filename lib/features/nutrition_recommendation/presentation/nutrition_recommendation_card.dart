import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';
import '../../../widgets/summary_card.dart';
import '../domain/confidence_models.dart';
import '../domain/goal_models.dart';
import '../domain/recommendation_models.dart';

class NutritionRecommendationCard extends StatelessWidget {
  final BodyweightGoal goal;
  final double targetRateKgPerWeek;
  final NutritionRecommendation? recommendation;
  final int activeTargetCalories;
  final bool isApplying;
  final VoidCallback? onApply;

  const NutritionRecommendationCard({
    super.key,
    required this.goal,
    required this.targetRateKgPerWeek,
    required this.recommendation,
    required this.activeTargetCalories,
    required this.isApplying,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: recommendation == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adaptive recommendation',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track weight and nutrition for about a week to unlock the first weekly recommendation.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Goal: ${WeeklyTargetRateCatalog.goalLabel(goal)} (${WeeklyTargetRateCatalog.rateLabel(targetRateKgPerWeek)})',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adaptive recommendation',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Goal: ${WeeklyTargetRateCatalog.goalLabel(recommendation!.goal)} (${WeeklyTargetRateCatalog.rateLabel(recommendation!.targetRateKgPerWeek)})',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Maintenance estimate: ${recommendation!.estimatedMaintenanceCalories} kcal',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  _MacroRow(
                    label: l10n.calories,
                    value: '${recommendation!.recommendedCalories} kcal',
                  ),
                  _MacroRow(
                    label: l10n.protein,
                    value: '${recommendation!.recommendedProteinGrams} g',
                  ),
                  _MacroRow(
                    label: l10n.carbs,
                    value: '${recommendation!.recommendedCarbsGrams} g',
                  ),
                  _MacroRow(
                    label: l10n.fat,
                    value: '${recommendation!.recommendedFatGrams} g',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Confidence: ${_confidenceLabel(recommendation!.confidence)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Data basis: ${recommendation!.inputSummary.windowDays} days, ${recommendation!.inputSummary.weightLogCount} weight logs, ${recommendation!.inputSummary.intakeLoggedDays} intake days',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current active calories: $activeTargetCalories kcal',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (recommendation!.warningState.warningLevel !=
                      RecommendationWarningLevel.none)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: recommendation!.warningState.warningLevel ==
                                RecommendationWarningLevel.high
                            ? theme.colorScheme.errorContainer
                            : theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        recommendation!.warningState.warningLevel ==
                                RecommendationWarningLevel.high
                            ? 'Large adjustment detected. Please review your recent logging completeness before applying.'
                            : 'Review suggested: recommendation was adjusted conservatively due to data variability.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: isApplying ? null : onApply,
                      child: Text(
                        isApplying
                            ? 'Applying...'
                            : 'Apply recommendation to active goals',
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  static String _confidenceLabel(RecommendationConfidence confidence) {
    switch (confidence) {
      case RecommendationConfidence.notEnoughData:
        return 'Not enough data';
      case RecommendationConfidence.low:
        return 'Low';
      case RecommendationConfidence.medium:
        return 'Medium';
      case RecommendationConfidence.high:
        return 'High';
    }
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final String value;

  const _MacroRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
