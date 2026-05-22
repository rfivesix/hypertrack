import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../statistics/domain/body_nutrition_analytics_models.dart';
import '../../../statistics/presentation/statistics_formatter.dart';
import '../../../statistics/presentation/widgets/body_nutrition_normalized_trend_chart.dart';
import '../statistics_hub_view_model.dart';
import 'analytics_card_base.dart';

class BodyMetricsSectionCard extends StatelessWidget {
  final SectionLoadState<BodyNutritionAnalyticsResult> state;
  final String rangeLabel;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  const BodyMetricsSectionCard({
    super.key,
    required this.state,
    required this.rangeLabel,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sectionId = StatisticsHubSectionId.bodyNutrition;
    final title = l10n.sectionBodyNutrition;

    if (state.isLoading && !state.hasData) {
      return AnalyticsCardBase.buildSectionLoadingCard(
        context,
        l10n,
        sectionId,
        title,
      );
    }
    if (state.hasError && !state.hasData) {
      return AnalyticsCardBase.buildSectionErrorCard(
        context,
        l10n,
        onRetry,
        sectionId,
        title,
      );
    }

    final body = state.data;
    final unitService = Provider.of<UnitService>(context);
    final weightValue = body?.currentWeightKg == null
        ? '-'
        : '${unitService.convertDisplayValue(body!.currentWeightKg!, UnitDimension.weight).toStringAsFixed(1)} ${unitService.suffixFor(UnitDimension.weight)}';
    final weightChangeValue = body?.weightChangeKg == null
        ? '-'
        : '${body!.weightChangeKg! >= 0 ? '+' : '-'}${unitService.convertDisplayValue(body.weightChangeKg!.abs(), UnitDimension.weight).toStringAsFixed(1)} ${unitService.suffixFor(UnitDimension.weight)}';
    final caloriesValue = body == null || body.loggedCalorieDays <= 0
        ? '-'
        : '${body.avgDailyCalories.round()} ${l10n.analyticsKcalPerDay}';
    final relationship = body == null
        ? l10n.analyticsInsightNotEnoughData
        : StatisticsPresentationFormatter.bodyNutritionRelationshipLabel(
            l10n,
            body.relationship,
          );
    final confidenceLabel = body == null
        ? l10n.analyticsInsufficientConfidenceLabel
        : StatisticsPresentationFormatter.bodyNutritionConfidenceLabel(
            l10n,
            body.confidence,
          );

    return AnalyticsCardBase.decorateSectionCard(
      context,
      state: state,
      child: SummaryCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnalyticsCardBase.buildHeaderWithChevron(
                context,
                label: title,
                chipText: rangeLabel,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBodyTrendPill(
                      context, l10n.metricsCurrentWeight, weightValue),
                  _buildBodyTrendPill(
                    context,
                    l10n.metricsWeightChange,
                    weightChangeValue,
                  ),
                  _buildBodyTrendPill(
                    context,
                    l10n.metricsAvgCalories,
                    caloriesValue,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBodyTrendPill(
                    context,
                    l10n.analyticsWeightTrendLabel,
                    body == null
                        ? l10n.analyticsTrendUnclear
                        : StatisticsPresentationFormatter
                            .bodyNutritionTrendDirectionLabel(
                            l10n,
                            body.weightTrend.direction,
                          ),
                  ),
                  _buildBodyTrendPill(
                    context,
                    l10n.analyticsCaloriesTrendLabel,
                    body == null
                        ? l10n.analyticsTrendUnclear
                        : StatisticsPresentationFormatter
                            .bodyNutritionTrendDirectionLabel(
                            l10n,
                            body.calorieTrend.direction,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                relationship,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _legendDot(
                    context,
                    color: Theme.of(context).colorScheme.primary,
                    label: l10n.analyticsBodyNutritionTotalWeightLabel,
                    shape: BoxShape.circle,
                  ),
                  const SizedBox(width: 12),
                  _legendDot(
                    context,
                    color: const Color(0xFFF97316),
                    label: l10n.analyticsBodyNutritionTotalCaloriesLabel,
                    shape: BoxShape.rectangle,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 84,
                child: BodyNutritionNormalizedTrendChart(
                  range: body?.range,
                  weightSeries: body?.weightDaily ?? const [],
                  calorieSeries: body?.caloriesDaily ?? const [],
                  compact: true,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body == null
                    ? confidenceLabel
                    : '$confidenceLabel • ${l10n.analyticsBasedOnDataCoverage(body.weightDays, body.loggedCalorieDays)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyTrendPill(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(
    BuildContext context, {
    required Color color,
    required String label,
    BoxShape shape = BoxShape.circle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: shape,
            borderRadius:
                shape == BoxShape.rectangle ? BorderRadius.circular(2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
