import 'package:flutter/material.dart';

import '../../features/statistics/presentation/widgets/body_nutrition_normalized_trend_chart.dart';
import '../../features/statistics/domain/statistics_range_policy.dart';
import '../../features/statistics/presentation/statistics_formatter.dart';
import '../../generated/app_localizations.dart';
import '../../util/body_nutrition_analytics_utils.dart';
import '../../util/design_constants.dart';
import '../../widgets/analytics_section_header.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/summary_card.dart';

class BodyNutritionCorrelationScreen extends StatefulWidget {
  final int initialRangeIndex;

  const BodyNutritionCorrelationScreen({super.key, this.initialRangeIndex = 1});

  @override
  State<BodyNutritionCorrelationScreen> createState() =>
      _BodyNutritionCorrelationScreenState();
}

class _BodyNutritionCorrelationScreenState
    extends State<BodyNutritionCorrelationScreen> {
  final _rangePolicy = StatisticsRangePolicyService.instance;
  bool _isLoading = true;
  late int _rangeIndex;
  BodyNutritionAnalyticsResult? _analytics;

  @override
  void initState() {
    super.initState();
    _rangeIndex = widget.initialRangeIndex.clamp(0, 4);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final analytics = await BodyNutritionAnalyticsUtils.build(
      rangeIndex: _rangeIndex,
    );
    if (!mounted) return;
    setState(() {
      _analytics = analytics;
      _isLoading = false;
    });
  }

  List<String> _ranges(AppLocalizations l10n) => [
        l10n.filter7Days,
        l10n.filter30Days,
        l10n.filter3Months,
        l10n.filter6Months,
        l10n.filterAll,
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.bodyNutritionCorrelationTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  padding: DesignConstants.screenPadding.copyWith(
                    top: DesignConstants.screenPadding.top + topPadding,
                    bottom: DesignConstants.bottomContentSpacer,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRangeChips(l10n),
                      const SizedBox(height: DesignConstants.spacingM),
                      _buildSummaryCard(l10n, _analytics!),
                      const SizedBox(height: DesignConstants.spacingM),
                      AnalyticsSectionHeader(
                        title: l10n.analyticsBodyNutritionTrendContext,
                      ),
                      _buildTrendComparisonCard(l10n, _analytics!),
                      const SizedBox(height: DesignConstants.spacingM),
                      AnalyticsSectionHeader(
                        title: l10n.analyticsInterpretationTitle,
                      ),
                      _buildInterpretationCard(l10n, _analytics!),
                    ],
                  ),
                ),
    );
  }

  Widget _buildRangeChips(AppLocalizations l10n) {
    final labels = _ranges(l10n);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(labels[index]),
              selected: _rangeIndex == index,
              onSelected: (selected) {
                if (!selected) return;
                setState(() => _rangeIndex = index);
                _load();
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCard(
    AppLocalizations l10n,
    BodyNutritionAnalyticsResult data,
  ) {
    final currentWeight = data.currentWeightKg == null
        ? '-'
        : '${data.currentWeightKg!.toStringAsFixed(1)} ${l10n.analyticsUnitKg}';
    final weightChange = data.weightChangeKg == null
        ? '-'
        : '${data.weightChangeKg! >= 0 ? '+' : ''}${data.weightChangeKg!.toStringAsFixed(1)} ${l10n.analyticsUnitKg}';
    final avgCalories = data.loggedCalorieDays <= 0
        ? '-'
        : '${data.avgDailyCalories.round()} ${l10n.analyticsKcalPerDay}';

    final confidenceLabel =
        StatisticsPresentationFormatter.bodyNutritionConfidenceLabel(
            l10n, data.confidence);

    final relationship =
        StatisticsPresentationFormatter.bodyNutritionRelationshipLabel(
      l10n,
      data.relationship,
    );

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sectionBodyNutrition,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _kpiPill(l10n.metricsCurrentWeight, currentWeight),
                _kpiPill(l10n.metricsWeightChange, weightChange),
                _kpiPill(l10n.metricsAvgCalories, avgCalories),
              ],
            ),
            const SizedBox(height: 10),
            _trendChipRow(l10n, data),
            const SizedBox(height: 10),
            Text(
              relationship,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.analyticsEffectiveRangeLabel}: ${_effectiveRangeDisclosure()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            Text(
              '$confidenceLabel • ${l10n.analyticsBasedOnDataCoverage(data.weightDays, data.loggedCalorieDays)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendChipRow(
      AppLocalizations l10n, BodyNutritionAnalyticsResult data) {
    final weightLabel =
        StatisticsPresentationFormatter.bodyNutritionTrendDirectionLabel(
            l10n, data.weightTrend.direction);
    final calorieLabel =
        StatisticsPresentationFormatter.bodyNutritionTrendDirectionLabel(
            l10n, data.calorieTrend.direction);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _trendChip(l10n.analyticsWeightTrendLabel, weightLabel),
        _trendChip(l10n.analyticsCaloriesTrendLabel, calorieLabel),
      ],
    );
  }

  Widget _trendChip(String title, String value) {
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
          Text(title, style: Theme.of(context).textTheme.labelSmall),
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

  Widget _kpiPill(String label, String value) {
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

  Widget _buildTrendComparisonCard(
    AppLocalizations l10n,
    BodyNutritionAnalyticsResult data,
  ) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.analyticsBodyNutritionNormalizedHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _legendDot(
                  color: Theme.of(context).colorScheme.primary,
                  label: l10n.analyticsWeightTrendLabel,
                ),
                const SizedBox(width: 12),
                _legendDot(
                  color: Theme.of(context).colorScheme.secondary,
                  label: l10n.analyticsCaloriesTrendLabel,
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: BodyNutritionNormalizedTrendChart(
                range: data.normalizedTrendRange,
                weightSeries: data.normalizedWeightTrend,
                calorieSeries: data.normalizedCaloriesTrend,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildInterpretationCard(
    AppLocalizations l10n,
    BodyNutritionAnalyticsResult data,
  ) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.analyticsObservedPatternLabel,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              StatisticsPresentationFormatter.bodyNutritionRelationshipLabel(
                l10n,
                data.relationship,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Text(
              StatisticsPresentationFormatter.bodyNutritionConfidenceLabel(
                l10n,
                data.confidence,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              _confidenceHint(l10n, data.confidence),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.analyticsCorrelationDisclaimer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _confidenceHint(
    AppLocalizations l10n,
    BodyNutritionConfidence confidence,
  ) {
    return switch (confidence) {
      BodyNutritionConfidence.high =>
        l10n.analyticsBodyNutritionConfidenceHighHint,
      BodyNutritionConfidence.moderate =>
        l10n.analyticsBodyNutritionConfidenceModerateHint,
      BodyNutritionConfidence.low =>
        l10n.analyticsBodyNutritionConfidenceLowHint,
      BodyNutritionConfidence.insufficient =>
        l10n.analyticsInsightNotEnoughData,
    };
  }

  String _effectiveRangeDisclosure() {
    final resolved = _rangePolicy.resolve(
      metricId: StatisticsMetricId.bodyNutritionTrend,
      selectedRangeIndex: _rangeIndex,
      earliestAvailableDay: _analytics?.range.start,
    );
    final days = resolved.effectiveDays;
    final l10n = AppLocalizations.of(context)!;
    if (days == null || days <= 0) {
      return _ranges(l10n)[_rangeIndex];
    }
    if (_rangePolicy.isAllTimeRangeIndex(_rangeIndex)) {
      return '$days ${l10n.analyticsDayUnitLabel}';
    }
    return _ranges(l10n)[_rangeIndex];
  }
}
