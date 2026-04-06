import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';
import '../../../widgets/summary_card.dart';
import '../domain/confidence_models.dart';
import '../domain/goal_models.dart';
import '../domain/recommendation_models.dart';
import 'recommendation_ui_copy.dart';

class NutritionRecommendationCard extends StatelessWidget {
  final BodyweightGoal goal;
  final double targetRateKgPerWeek;
  final NutritionRecommendation? recommendation;
  final DateTime? generatedAt;
  final DateTime nextAdaptiveRecommendationDueAt;
  final bool isAdaptiveRecommendationDueNow;
  final int activeTargetCalories;
  final bool isRecalculating;
  final bool isApplying;
  final VoidCallback? onRecalculate;
  final VoidCallback? onApply;

  const NutritionRecommendationCard({
    super.key,
    required this.goal,
    required this.targetRateKgPerWeek,
    required this.recommendation,
    required this.generatedAt,
    required this.nextAdaptiveRecommendationDueAt,
    required this.isAdaptiveRecommendationDueNow,
    required this.activeTargetCalories,
    required this.isRecalculating,
    required this.isApplying,
    required this.onRecalculate,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final recommendationWarning = recommendation == null
        ? null
        : RecommendationUiCopy.warningMessage(l10n, recommendation!);

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: recommendation == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adaptiveRecommendationCardTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.adaptiveRecommendationEmptyBody,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.adaptiveRecommendationGoalLine(
                      _goalLabel(l10n, goal),
                      _rateLabel(l10n, targetRateKgPerWeek),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.adaptiveRecommendationNextDueLine(
                      _formatDate(context, nextAdaptiveRecommendationDueAt),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (isAdaptiveRecommendationDueNow)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.adaptiveRecommendationDueNowLine,
                        key: const Key('adaptive_recommendation_due_now_line'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: isRecalculating ? null : onRecalculate,
                    child: Text(
                      isRecalculating
                          ? l10n.adaptiveRecommendationRecalculating
                          : l10n.adaptiveRecommendationRecalculateNowAction,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adaptiveRecommendationCardTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.adaptiveRecommendationGoalLine(
                      _goalLabel(l10n, recommendation!.goal),
                      _rateLabel(l10n, recommendation!.targetRateKgPerWeek),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.adaptiveRecommendationCalculatedAtLine(
                      _formatDateTime(
                        context,
                        generatedAt ?? recommendation!.generatedAt,
                      ),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.adaptiveRecommendationNextDueLine(
                      _formatDate(context, nextAdaptiveRecommendationDueAt),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (isAdaptiveRecommendationDueNow)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.adaptiveRecommendationDueNowLine,
                        key: const Key('adaptive_recommendation_due_now_line'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.adaptiveRecommendationMaintenanceLine(
                      recommendation!.estimatedMaintenanceCalories,
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  _MacroRow(
                    label: l10n.calories,
                    value: l10n.adaptiveRecommendationCaloriesValue(
                      recommendation!.recommendedCalories,
                    ),
                  ),
                  _MacroRow(
                    label: l10n.protein,
                    value: l10n.adaptiveRecommendationProteinValue(
                      recommendation!.recommendedProteinGrams,
                    ),
                  ),
                  _MacroRow(
                    label: l10n.carbs,
                    value: l10n.adaptiveRecommendationCarbsValue(
                      recommendation!.recommendedCarbsGrams,
                    ),
                  ),
                  _MacroRow(
                    label: l10n.fat,
                    value: l10n.adaptiveRecommendationFatValue(
                      recommendation!.recommendedFatGrams,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.adaptiveRecommendationConfidenceLine(
                      RecommendationUiCopy.confidenceLabel(
                        l10n,
                        recommendation!.confidence,
                      ),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.adaptiveRecommendationDataBasisLine(
                      recommendation!.inputSummary.windowDays,
                      recommendation!.inputSummary.weightLogCount,
                      recommendation!.inputSummary.intakeLoggedDays,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    RecommendationUiCopy.dataBasisMessage(
                      l10n,
                      recommendation!,
                    ),
                    key:
                        const Key('adaptive_recommendation_data_basis_message'),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.adaptiveRecommendationActiveCaloriesLine(
                      activeTargetCalories,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (recommendationWarning != null)
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
                        recommendationWarning,
                        key: const Key('adaptive_recommendation_warning_text'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    children: [
                      FilledButton.tonal(
                        onPressed: isRecalculating ? null : onRecalculate,
                        child: Text(
                          isRecalculating
                              ? l10n.adaptiveRecommendationRecalculating
                              : l10n.adaptiveRecommendationRecalculateNowAction,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isApplying ? null : onApply,
                        child: Text(
                          isApplying
                              ? l10n.adaptiveRecommendationApplying
                              : l10n.adaptiveRecommendationApplyAction,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  String _goalLabel(AppLocalizations l10n, BodyweightGoal goal) {
    switch (goal) {
      case BodyweightGoal.loseWeight:
        return l10n.adaptiveGoalLose;
      case BodyweightGoal.maintainWeight:
        return l10n.adaptiveGoalMaintain;
      case BodyweightGoal.gainWeight:
        return l10n.adaptiveGoalGain;
    }
  }

  String _rateLabel(AppLocalizations l10n, double kgPerWeek) {
    final sign = kgPerWeek > 0 ? '+' : '';
    return l10n.adaptiveRatePerWeek('$sign${kgPerWeek.toStringAsFixed(2)}');
  }

  String _formatDate(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
  }

  String _formatDateTime(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    final localValue = value.toLocal();
    final dateText = localizations.formatMediumDate(localValue);
    final timeText = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localValue),
      alwaysUse24HourFormat:
          MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
    );
    return '$dateText $timeText';
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
