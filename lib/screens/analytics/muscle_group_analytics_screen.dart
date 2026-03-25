import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/workout_database_helper.dart';
import '../../features/statistics/domain/analytics_state.dart';
import '../../features/statistics/domain/statistics_range_policy.dart';
import '../../features/statistics/presentation/statistics_formatter.dart';
import '../../generated/app_localizations.dart';
import '../../util/design_constants.dart';
import '../../widgets/analytics_chart_defaults.dart';
import '../../widgets/analytics_section_header.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/muscle_radar_chart.dart';
import '../../widgets/summary_card.dart';

class MuscleGroupAnalyticsScreen extends StatefulWidget {
  const MuscleGroupAnalyticsScreen({super.key});

  @override
  State<MuscleGroupAnalyticsScreen> createState() =>
      _MuscleGroupAnalyticsScreenState();
}

class _MuscleGroupAnalyticsScreenState
    extends State<MuscleGroupAnalyticsScreen> {
  static const _maxMuscleBars = 8;
  final _rangePolicy = StatisticsRangePolicyService.instance;
  bool _isLoading = true;
  int _periodIndex = 1; // 30 days
  int _selectedWeekIndex = -1;
  Map<String, dynamic> _analytics = const {};

  final List<int> _periodOptions = const [7, 30, 90, 180];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final daysBack = _periodOptions[_periodIndex];
    final weeksBack = _rangePolicy.resolveWeeksBack(
      metricId: StatisticsMetricId.muscleAnalytics,
      effectiveDays: daysBack,
    );

    final data = await WorkoutDatabaseHelper.instance.getMuscleGroupAnalytics(
      daysBack: daysBack,
      weeksBack: weeksBack,
    );

    if (!mounted) return;
    final weekly = (data['weekly'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    setState(() {
      _analytics = data;
      _selectedWeekIndex = weekly.isEmpty ? -1 : weekly.length - 1;
      _isLoading = false;
    });
  }

  String _formatCompact(num value) {
    return StatisticsPresentationFormatter.compactNumber(value);
  }

  List<MuscleRadarDatum> _buildRadarData(List<Map<String, dynamic>> muscles) {
    final sorted = muscles
        .where((m) => !StatisticsPresentationFormatter.isOtherCategoryLabel(
            m['muscleGroup'] as String?))
        .toList(growable: false)
      ..sort((a, b) => ((b['equivalentSets'] as num?)?.toDouble() ?? 0.0)
          .compareTo((a['equivalentSets'] as num?)?.toDouble() ?? 0.0));

    if (sorted.length <= _maxMuscleBars) {
      return sorted
          .map((m) => MuscleRadarDatum(
                label: m['muscleGroup'] as String,
                value: (m['equivalentSets'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList();
    }

    return sorted
        .take(_maxMuscleBars)
        .map((m) => MuscleRadarDatum(
              label: m['muscleGroup'] as String,
              value: (m['equivalentSets'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final muscles = (_analytics['muscles'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .where((m) => !StatisticsPresentationFormatter.isOtherCategoryLabel(
            m['muscleGroup'] as String?))
        .toList(growable: false);
    final weekly = (_analytics['weekly'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final undertrained =
        (_analytics['undertrained'] as List<dynamic>? ?? const [])
            .cast<String>();
    final dataQualityOk = (_analytics['dataQualityOk'] as bool?) ?? false;
    final radarData = _buildRadarData(muscles);
    final radarMax = radarData.isEmpty
        ? 0.0
        : radarData
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1.0, 1000000.0)
            .toDouble();

    final selectedWeek =
        (_selectedWeekIndex >= 0 && _selectedWeekIndex < weekly.length)
            ? weekly[_selectedWeekIndex]
            : null;

    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.muscleAnalyticsTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: DesignConstants.screenPadding.copyWith(
                top: DesignConstants.screenPadding.top + topPadding,
                bottom: DesignConstants.bottomContentSpacer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(l10n.analyticsPeriodLabel),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_periodOptions.length, (index) {
                      final days = _periodOptions[index];
                      final label = days == 7
                          ? l10n.filter7Days
                          : days == 30
                              ? l10n.filter30Days
                              : days == 90
                                  ? l10n.filter3Months
                                  : l10n.filter6Months;
                      return ChoiceChip(
                        label: Text(label),
                        selected: _periodIndex == index,
                        onSelected: (selected) {
                          if (!selected) return;
                          setState(() => _periodIndex = index);
                          _loadData();
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  _sectionLabel(l10n.analyticsRadarOverviewTitle),
                  SummaryCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (radarData.length < 3)
                            AnalyticsChartDefaults.stateView(
                              context: context,
                              l10n: l10n,
                              status: AnalyticsStatus.empty,
                              emptyLabel: l10n.noWorkoutDataLabel,
                            )
                          else
                            Center(
                              child: MuscleRadarChart(
                                data: radarData,
                                maxValue: radarMax,
                                centerLabel: l10n.metricsVolumeLifted,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.analyticsRadarVolumeCaption,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingM),
                  _sectionLabel(
                    l10n.analyticsWeeklySetsByMuscle,
                    isPrimary: true,
                  ),
                  if (weekly.isNotEmpty) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(weekly.length, (index) {
                          final row = weekly[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(row['weekLabel'] as String),
                              selected: _selectedWeekIndex == index,
                              onSelected: (selected) {
                                if (!selected) return;
                                setState(() => _selectedWeekIndex = index);
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingS),
                  ],
                  _buildWeeklySetsCard(selectedWeek),
                  const SizedBox(height: DesignConstants.spacingM),
                  _sectionLabel(l10n.analyticsFrequencyByMuscle),
                  _buildFrequencyCard(muscles),
                  const SizedBox(height: DesignConstants.spacingM),
                  _sectionLabel(l10n.analyticsGuidanceTitle),
                  SummaryCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dataQualityOk
                                ? l10n.analyticsGuidanceDirectionalDisclaimer
                                : l10n.analyticsGuidanceSoftenedDisclaimer,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _guidanceLabel(dataQualityOk, undertrained),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWeeklySetsCard(Map<String, dynamic>? selectedWeek) {
    final l10n = AppLocalizations.of(context)!;
    if (selectedWeek == null) {
      return SummaryCard(
        child: SizedBox(
          height: 180,
          child: AnalyticsChartDefaults.stateView(
            context: context,
            l10n: l10n,
            status: AnalyticsStatus.empty,
            emptyLabel: l10n.noWorkoutDataLabel,
            height: 180,
          ),
        ),
      );
    }

    final rawMuscles =
        (selectedWeek['muscles'] as Map<String, dynamic>?) ?? const {};
    final items = rawMuscles.entries
        .map((entry) => {
              'muscleGroup': entry.key,
              'value': (entry.value as num).toDouble(),
            })
        .where((m) => !StatisticsPresentationFormatter.isOtherCategoryLabel(
            m['muscleGroup'] as String?))
        .where((m) => (m['value'] as double) > 0)
        .toList()
      ..sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));

    return _buildMuscleBarChart(
      items: items.take(_maxMuscleBars).toList(),
      unit: l10n.analyticsUnitSets,
      emptyLabel: l10n.noWorkoutDataLabel,
      yAxisLabel:
          '${l10n.analyticsWeeklySetsByMuscle} (${l10n.analyticsUnitSets})',
      footer: l10n.analyticsWeekTotalEquivalentSets(
        (selectedWeek['totalEquivalentSets'] as num).toStringAsFixed(1),
      ),
      chartHeight: 260,
      emphasize: true,
    );
  }

  Widget _buildFrequencyCard(List<Map<String, dynamic>> muscles) {
    final l10n = AppLocalizations.of(context)!;
    final items = muscles
        .map((m) => {
              'muscleGroup': m['muscleGroup'] as String,
              'value': (m['frequencyPerWeek'] as num).toDouble(),
            })
        .where((m) => (m['value'] as double) > 0)
        .toList()
      ..sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));

    return _buildMuscleBarChart(
      items: items.take(_maxMuscleBars).toList(),
      unit: '/${l10n.analyticsPerWeekAbbrev}',
      emptyLabel: l10n.noWorkoutDataLabel,
      yAxisLabel:
          '${l10n.analyticsFrequencyByMuscle} (/${l10n.analyticsPerWeekAbbrev})',
      footer: l10n.analyticsFrequencyRuleFooter,
    );
  }

  Widget _buildMuscleBarChart({
    required List<Map<String, dynamic>> items,
    required String unit,
    required String emptyLabel,
    required String footer,
    required String yAxisLabel,
    double chartHeight = 220,
    bool emphasize = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return SummaryCard(
        child: SizedBox(
          height: chartHeight,
          child: AnalyticsChartDefaults.stateView(
            context: context,
            l10n: l10n,
            status: AnalyticsStatus.empty,
            emptyLabel: emptyLabel,
            height: chartHeight,
          ),
        ),
      );
    }

    final labels = items.map((e) => e['muscleGroup'] as String).toList();
    final values = items.map((e) => (e['value'] as num).toDouble()).toList();

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            if (emphasize)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.analyticsEquivalentSetsExplainer,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: AnalyticsChartDefaults.axisTitleLabel(
                context,
                'Y: $yAxisLabel',
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: chartHeight,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: AnalyticsChartDefaults.compactGrid,
                  borderData: AnalyticsChartDefaults.noBorder,
                  maxY: (values.reduce((a, b) => a > b ? a : b) * 1.2)
                      .clamp(1, 1e12),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          Theme.of(context).colorScheme.inverseSurface,
                      getTooltipItem: (group, _, rod, __) {
                        final index = group.x.toInt();
                        final label = labels[index];
                        final value = values[index];
                        return BarTooltipItem(
                          '$label\n${_formatCompact(value)} $unit',
                          TextStyle(
                            color:
                                Theme.of(context).colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: AnalyticsChartDefaults.standardTitles(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) =>
                            AnalyticsChartDefaults.tickLabel(
                          context,
                          _formatCompact(value),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          final label = labels[index];
                          final compact = label.length > 8
                              ? '${label.substring(0, 8)}...'
                              : label;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: AnalyticsChartDefaults.tickLabel(
                              context,
                              compact,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: values
                      .asMap()
                      .entries
                      .map((entry) => BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value,
                                width: emphasize ? 16 : 14,
                                borderRadius: BorderRadius.circular(4),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: AnalyticsChartDefaults.axisTitleLabel(
                context,
                'X: ${l10n.analyticsViewByMuscle}',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              footer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _guidanceLabel(bool dataQualityOk, List<String> undertrained) {
    final l10n = AppLocalizations.of(context)!;
    return StatisticsPresentationFormatter.muscleGuidanceLabel(
      l10n,
      dataQualityOk,
      undertrained,
    );
  }

  Widget _sectionLabel(String text, {bool isPrimary = false}) {
    if (!isPrimary) {
      return AnalyticsSectionHeader(title: text);
    }
    return AnalyticsSectionHeader(
      title: text,
      padding: const EdgeInsets.only(left: 4, bottom: 8),
    );
  }
}
