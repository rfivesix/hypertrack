import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/statistics/domain/statistics_range_policy.dart';
import '../../generated/app_localizations.dart';
import '../../screens/measurements_screen.dart';
import '../../util/body_nutrition_analytics_utils.dart';
import '../../util/design_constants.dart';
import '../../widgets/analytics_chart_defaults.dart';
import '../../widgets/analytics_section_header.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/summary_card.dart';

class BodyNutritionCorrelationScreen extends StatefulWidget {
  final int initialRangeIndex;

  const BodyNutritionCorrelationScreen({
    super.key,
    this.initialRangeIndex = 1,
  });

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

    return Scaffold(
      appBar: GlobalAppBar(title: l10n.bodyNutritionCorrelationTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  padding: DesignConstants.screenPadding.copyWith(
                    bottom: DesignConstants.bottomContentSpacer,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRangeChips(l10n),
                      const SizedBox(height: 6),
                      Text(
                        _effectiveRangeDisclosure(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: DesignConstants.spacingM),
                      _buildSummaryKpis(l10n, _analytics!),
                      const SizedBox(height: DesignConstants.spacingM),
                      AnalyticsSectionHeader(
                        title: l10n.analyticsBodyNutritionTrendContext,
                      ),
                      _buildStackedCharts(l10n, _analytics!),
                      const SizedBox(height: DesignConstants.spacingM),
                      AnalyticsSectionHeader(
                        title: l10n.analyticsInterpretationTitle,
                      ),
                      _buildInterpretationCard(l10n, _analytics!),
                      const SizedBox(height: 8),
                      SummaryCard(
                        child: ListTile(
                          leading: Icon(
                            Icons.straighten,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            l10n.body_measurements,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(l10n.measurements_description),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MeasurementsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
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

  Widget _buildSummaryKpis(
    AppLocalizations l10n,
    BodyNutritionAnalyticsResult data,
  ) {
    final currentWeight = data.currentWeightKg == null
        ? '-'
        : '${data.currentWeightKg!.toStringAsFixed(1)} ${l10n.analyticsUnitKg}';
    final weightChange = data.weightChangeKg == null
        ? '-'
        : '${data.weightChangeKg! >= 0 ? '+' : ''}${data.weightChangeKg!.toStringAsFixed(1)} ${l10n.analyticsUnitKg}';
    final avgCalories = '${data.avgDailyCalories.round()} kcal';

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Row(
              children: [
                _metricItem(l10n.metricsCurrentWeight, currentWeight,
                    '${data.weightDays} ${l10n.analyticsDaysWithWeightData}'),
                _metricItem(l10n.metricsWeightChange, weightChange,
                    _effectiveRangeDisclosure()),
                _metricItem(l10n.metricsAvgCalories, avgCalories,
                    l10n.analyticsPerDayLabel),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _insightText(l10n, data),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricItem(String label, String value, String subLabel) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            subLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedCharts(
    AppLocalizations l10n,
    BodyNutritionAnalyticsResult data,
  ) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartTitle(l10n.analyticsWeightTrendLabel),
            Text(
              'Y: ${l10n.analyticsUnitKg}   X: ${l10n.analyticsDayUnitLabel.toLowerCase()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            SizedBox(height: 170, child: _buildWeightChart(data)),
            const SizedBox(height: 10),
            _buildChartTitle(l10n.analyticsCaloriesTrendLabel),
            Text(
              'Y: kcal   X: ${l10n.analyticsDayUnitLabel.toLowerCase()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            SizedBox(height: 170, child: _buildCaloriesChart(data)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildWeightChart(BodyNutritionAnalyticsResult data) {
    if (data.weightDaily.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.chart_no_data_for_period),
      );
    }

    final firstDay = data.range.start;
    final points = (data.smoothedWeight.isNotEmpty
            ? data.smoothedWeight
            : data.weightDaily)
        .map((p) => FlSpot(_xOf(p.day, firstDay), p.value))
        .toList(growable: false);

    final labels = _xLabelPositions(data.range);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.totalDays - 1).toDouble().clamp(1, 100000),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final rounded = value.round();
                if (!labels.contains(rounded)) return const SizedBox.shrink();
                final day = firstDay.add(Duration(days: rounded));
                return Text(
                  DateFormat('MMMd').format(day),
                  style: Theme.of(context).textTheme.labelSmall,
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          AnalyticsChartDefaults.straightLine(
            spots: points,
            barWidth: 2.5,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesChart(BodyNutritionAnalyticsResult data) {
    if (data.caloriesDaily.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.chart_no_data_for_period),
      );
    }

    final firstDay = data.range.start;
    final series = data.smoothedCalories.isNotEmpty
        ? data.smoothedCalories
        : data.caloriesDaily;
    final points = series
        .map((p) => FlSpot(_xOf(p.day, firstDay), p.value))
        .toList(growable: false);

    final labels = _xLabelPositions(data.range);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.totalDays - 1).toDouble().clamp(1, 100000),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final rounded = value.round();
                if (!labels.contains(rounded)) return const SizedBox.shrink();
                final day = firstDay.add(Duration(days: rounded));
                return Text(
                  DateFormat('MMMd').format(day),
                  style: Theme.of(context).textTheme.labelSmall,
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          AnalyticsChartDefaults.straightLine(
            spots: points,
            barWidth: 2.5,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildInterpretationCard(
    AppLocalizations l10n,
    BodyNutritionAnalyticsResult data,
  ) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _insightText(l10n, data),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
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

  String _insightText(
      AppLocalizations l10n, BodyNutritionAnalyticsResult data) {
    switch (data.insightType) {
      case BodyNutritionInsightType.stableWeightCaloriesUp:
        return l10n.analyticsInsightStableWeightCaloriesUp;
      case BodyNutritionInsightType.weightUpCaloriesUp:
        return l10n.analyticsInsightWeightUpCaloriesUp;
      case BodyNutritionInsightType.caloriesDownWeightNotYetChanged:
        return l10n.analyticsInsightCaloriesDownWeightStable;
      case BodyNutritionInsightType.weightDownCaloriesDown:
        return l10n.analyticsInsightWeightDownCaloriesDown;
      case BodyNutritionInsightType.mixed:
        return l10n.analyticsInsightMixedPattern;
      case BodyNutritionInsightType.notEnoughData:
        return l10n.analyticsInsightNotEnoughData;
    }
  }

  double _xOf(DateTime day, DateTime firstDay) {
    final d0 = DateTime(firstDay.year, firstDay.month, firstDay.day);
    final d = DateTime(day.year, day.month, day.day);
    return d.difference(d0).inDays.toDouble();
  }

  Set<int> _xLabelPositions(DateTimeRange range) {
    final span = range.end.difference(range.start).inDays + 1;
    if (span <= 1) return {0};
    final interval = (span / 4).ceil().clamp(1, 10000);

    final positions = <int>{0, span - 1};
    for (var i = interval; i < span - 1; i += interval) {
      positions.add(i);
    }
    return positions;
  }

  String _effectiveRangeDisclosure() {
    final resolved = _rangePolicy.resolve(
      metricId: StatisticsMetricId.bodyNutritionInsightKpi,
      selectedRangeIndex: _rangeIndex,
      earliestAvailableDay: _analytics?.range.start,
    );
    final days = resolved.effectiveDays;
    final l10n = AppLocalizations.of(context)!;
    if (days == null || days <= 0) {
      return _ranges(l10n)[_rangeIndex];
    }
    if (_rangePolicy.isAllRangeIndex(_rangeIndex)) {
      return '${l10n.filterAll} (${days}d)';
    }
    return _ranges(l10n)[_rangeIndex];
  }
}
