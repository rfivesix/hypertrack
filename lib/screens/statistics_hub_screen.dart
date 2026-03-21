import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/workout_database_helper.dart';
import '../features/statistics/data/statistics_hub_data_adapter.dart';
import '../features/statistics/domain/consistency_payload_models.dart';
import '../features/statistics/domain/recovery_payload_models.dart';
import '../features/statistics/domain/statistics_range_policy.dart';
import '../features/statistics/domain/analytics_state.dart';
import '../features/statistics/presentation/statistics_formatter.dart';
import '../generated/app_localizations.dart';
import '../util/body_nutrition_analytics_utils.dart';
import '../util/design_constants.dart';
import '../widgets/analytics_chart_defaults.dart';
import '../widgets/analytics_section_header.dart';
import '../widgets/bottom_content_spacer.dart';
import '../widgets/summary_card.dart';
import 'analytics/body_nutrition_correlation_screen.dart';
import 'analytics/consistency_tracker_screen.dart';
import 'analytics/muscle_group_analytics_screen.dart';
import 'analytics/pr_dashboard_screen.dart';
import 'analytics/recovery_tracker_screen.dart';
import 'exercise_catalog_screen.dart';
import 'measurements_screen.dart';

class StatisticsHubScreen extends StatefulWidget {
  const StatisticsHubScreen({super.key});

  @override
  State<StatisticsHubScreen> createState() => _StatisticsHubScreenState();
}

class _StatisticsHubScreenState extends State<StatisticsHubScreen> {
  late final l10n = AppLocalizations.of(context)!;
  final _hubDataAdapter = StatisticsHubDataAdapter(
    workoutDatabaseHelper: WorkoutDatabaseHelper.instance,
  );
  final _rangePolicy = StatisticsRangePolicyService.instance;

  int _selectedTimeRangeIndex = 1;

  bool _isLoadingStats = true;
  List<Map<String, dynamic>> _recentPRs = [];
  List<Map<String, dynamic>> _weeklyVolume = [];
  List<Map<String, dynamic>> _workoutsPerWeek = [];
  List<WeeklyConsistencyMetricPayload> _weeklyConsistencyMetrics = [];
  Map<String, dynamic> _muscleAnalytics = const {};
  List<Map<String, dynamic>> _notableImprovements = [];
  TrainingStatsPayload _trainingStats = const TrainingStatsPayload(
    totalWorkouts: 0,
    thisWeekCount: 0,
    avgPerWeek: 0.0,
    streakWeeks: 0,
  );
  RecoveryAnalyticsPayload _recoveryAnalytics = const RecoveryAnalyticsPayload(
    hasData: false,
    overallState: '',
    totals: RecoveryTotalsPayload(
      recovering: 0,
      ready: 0,
      fresh: 0,
      tracked: 0,
    ),
    muscles: [],
  );
  BodyNutritionAnalyticsResult? _bodyNutrition;
  _HubConsistencyMetric _hubConsistencyMetric = _HubConsistencyMetric.volume;

  @override
  void initState() {
    super.initState();
    _loadHubAnalytics();
  }

  Future<void> _loadHubAnalytics() async {
    setState(() => _isLoadingStats = true);
    final (hub, bodyNutrition) = await _hubDataAdapter.fetch(
      selectedTimeRangeIndex: _selectedTimeRangeIndex,
    );

    if (!mounted) return;
    setState(() {
      _recentPRs = hub.recentPrs;
      _weeklyVolume = hub.weeklyVolume;
      _workoutsPerWeek = hub.workoutsPerWeek;
      _weeklyConsistencyMetrics = hub.weeklyConsistencyMetrics;
      _muscleAnalytics = hub.muscleAnalytics;
      _trainingStats = hub.trainingStats;
      _recoveryAnalytics = hub.recoveryAnalytics;
      _notableImprovements = hub.notableImprovements;
      _bodyNutrition = bodyNutrition;
      _isLoadingStats = false;
    });
  }

  List<String> get _timeRanges => [
        l10n.filter7Days,
        l10n.filter30Days,
        l10n.filter3Months,
        l10n.filter6Months,
        l10n.filterAll,
      ];

  @override
  Widget build(BuildContext context) {
    final appBarHeight = MediaQuery.of(context).padding.top;
    final finalPadding = DesignConstants.cardPadding.copyWith(
      top: DesignConstants.cardPadding.top + appBarHeight + 16,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: finalPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTimeRangeFilter(),
                const SizedBox(height: DesignConstants.spacingL),
                _buildSectionTitle(context, l10n.sectionConsistency),
                _buildConsistencySection(),
                const SizedBox(height: DesignConstants.spacingL),
                _buildSectionTitle(context, l10n.analyticsSectionVolumeMuscles),
                _buildMuscleVolumeSection(),
                const SizedBox(height: DesignConstants.spacingL),
                _buildSectionTitle(
                    context, l10n.analyticsSectionPerformanceRecords),
                _buildPerformanceSection(),
                const SizedBox(height: DesignConstants.spacingL),
                _buildSectionTitle(context, l10n.sectionRecovery),
                _buildRecoverySection(),
                const SizedBox(height: DesignConstants.spacingL),
                _buildSectionTitle(context, l10n.sectionBodyNutrition),
                _buildBodyMetricsSection(),
                const BottomContentSpacer(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_timeRanges.length, (index) {
          final range = _timeRanges[index];
          final isSelected = _selectedTimeRangeIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(range),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTimeRangeIndex = index);
                  _loadHubAnalytics();
                }
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return AnalyticsSectionHeader(title: title);
  }

  String _hubMetricName() {
    return switch (_hubConsistencyMetric) {
      _HubConsistencyMetric.volume => l10n.metricsVolumeLifted,
      _HubConsistencyMetric.duration => l10n.durationLabel,
      _HubConsistencyMetric.frequency => l10n.workoutsPerWeekLabel,
    };
  }

  String _hubMetricUnit() {
    return switch (_hubConsistencyMetric) {
      _HubConsistencyMetric.volume => l10n.analyticsUnitKg,
      _HubConsistencyMetric.duration => 'min',
      _HubConsistencyMetric.frequency => l10n.analyticsPerWeekAbbrev,
    };
  }

  List<double> _hubMetricValues() {
    if (_weeklyConsistencyMetrics.isEmpty) {
      return _workoutsPerWeek
          .map((e) => (e['count'] as num?)?.toDouble() ?? 0.0)
          .toList();
    }
    return _weeklyConsistencyMetrics.map((row) {
      return switch (_hubConsistencyMetric) {
        _HubConsistencyMetric.volume =>
          row.tonnage,
        _HubConsistencyMetric.duration =>
          row.durationMinutes,
        _HubConsistencyMetric.frequency =>
          row.count.toDouble(),
      };
    }).toList();
  }

  Widget _buildConsistencySection() {
    return Column(
      children: [
        SummaryCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ConsistencyTrackerScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isLoadingStats
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMiniBars(_hubMetricValues()),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.metricsVolumeLifted),
                      selected:
                          _hubConsistencyMetric == _HubConsistencyMetric.volume,
                      onSelected: (_) {
                        setState(() => _hubConsistencyMetric =
                            _HubConsistencyMetric.volume);
                      },
                    ),
                    ChoiceChip(
                      label: Text(l10n.durationLabel),
                      selected: _hubConsistencyMetric ==
                          _HubConsistencyMetric.duration,
                      onSelected: (_) {
                        setState(() => _hubConsistencyMetric =
                            _HubConsistencyMetric.duration);
                      },
                    ),
                    ChoiceChip(
                      label: Text(l10n.workoutsPerWeekLabel),
                      selected: _hubConsistencyMetric ==
                          _HubConsistencyMetric.frequency,
                      onSelected: (_) {
                        setState(() => _hubConsistencyMetric =
                            _HubConsistencyMetric.frequency);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_hubMetricName()} (${_hubMetricUnit()}) / ${l10n.analyticsViewWeek}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol(
                      l10n.metricsWorkoutsWeek,
                      '${_trainingStats.thisWeekCount}',
                      l10n.thisWeekLabel,
                    ),
                    _buildMetricCol(
                      l10n.metricsCurrentStreak,
                      '${_trainingStats.streakWeeks}',
                      l10n.metricsActiveWeeks,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDrillDownHint(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleVolumeSection() {
    final muscles = (_muscleAnalytics['muscles'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final topMuscles = muscles.take(5).toList();
    final weekly = (_muscleAnalytics['weekly'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final latestWeek = weekly.isNotEmpty ? weekly.last : null;
    final latestWeekSets =
        (latestWeek?['totalEquivalentSets'] as num?)?.toDouble() ?? 0.0;
    final topMuscle = topMuscles.isNotEmpty ? topMuscles.first : null;
    final undertrained =
        (_muscleAnalytics['undertrained'] as List<dynamic>? ?? const [])
            .cast<String>();
    final dataQualityOk = (_muscleAnalytics['dataQualityOk'] as bool?) ?? false;

    return SummaryCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MuscleGroupAnalyticsScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLoadingStats
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMuscleDistributionHeatmap(topMuscles),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCol(
                  l10n.analyticsMuscleWeeklySets,
                  latestWeekSets.toStringAsFixed(1),
                  latestWeek?['weekLabel'] as String? ?? l10n.thisWeekLabel,
                ),
                _buildMetricCol(
                  l10n.analyticsMuscleTopFrequency,
                  topMuscle?['muscleGroup'] as String? ?? '-',
                  topMuscle != null
                      ? '${(topMuscle['frequencyPerWeek'] as num).toDouble().toStringAsFixed(1)}/${l10n.analyticsPerWeekAbbrev}'
                      : l10n.exerciseAnalyticsNoData,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _muscleGuidanceLabel(dataQualityOk, undertrained),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            _buildDrillDownHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Column(
      children: [
        SummaryCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PRDashboardScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.analyticsRecentRecords,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (_recentPRs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      l10n.exerciseAnalyticsNoData,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  )
                else
                  ...List.generate(_recentPRs.length * 2 - 1, (i) {
                    if (i.isOdd) return const Divider(height: 12);
                    final pr = _recentPRs[i ~/ 2];
                    final name = pr['exerciseName'] as String;
                    final weight = pr['weight'] as double;
                    final reps = pr['reps'] as int;
                    final weightStr = weight == weight.truncateToDouble()
                        ? weight.toInt().toString()
                        : weight.toStringAsFixed(1);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          l10n.analyticsPerfWithReps(weightStr, reps),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol(
                      l10n.metricsVolumeLifted,
                      _weeklyVolume.isNotEmpty
                          ? (_weeklyVolume.last['tonnage'] as num) >= 1000
                              ? '${((_weeklyVolume.last['tonnage'] as num) / 1000).toStringAsFixed(1)}k'
                              : (_weeklyVolume.last['tonnage'] as num)
                                  .toStringAsFixed(0)
                          : '0',
                      l10n.analyticsKgThisWeek,
                    ),
                    _buildMetricCol(
                      l10n.metricsMostImproved,
                      _notableImprovements.isNotEmpty
                          ? _notableImprovements.first['exerciseName'] as String
                          : '-',
                      _notableImprovements.isNotEmpty
                          ? '+${((_notableImprovements.first['improvementPct'] as num).toDouble()).toStringAsFixed(1)}%'
                          : l10n.exerciseAnalyticsNoData,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDrillDownHint(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SummaryCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseCatalogScreen()),
            );
          },
          child: ListTile(
            leading: Icon(Icons.search,
                color: Theme.of(context).colorScheme.primary),
            title: Text(l10n.exerciseAnalyticsTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(l10n.exerciseAnalyticsSubtitle),
            trailing: Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecoverySection() {
    final recovering = _recoveryAnalytics.totals.recovering;
    final ready = _recoveryAnalytics.totals.ready;
    final fresh = _recoveryAnalytics.totals.fresh;
    final hasData = _recoveryAnalytics.hasData;

    final overallState = _recoveryAnalytics.overallState;
    final overallLabel =
        StatisticsPresentationFormatter.recoveryOverallLabel(l10n, overallState);

    final subtitle = hasData
        ? l10n.recoveryHubCountsSummary(recovering, ready, fresh)
        : l10n.recoveryHubNoDataSummary;

    final iconColor = StatisticsPresentationFormatter.recoveryOverallColor(
      context,
      overallState,
    );

    return SummaryCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecoveryTrackerScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.self_improvement, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.metricsMuscleReadiness,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (_isLoadingStats)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else ...[
                    Text(subtitle),
                    const SizedBox(height: 2),
                    Text(
                      overallLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyMetricsSection() {
    final body = _bodyNutrition;
    final currentWeight = body?.currentWeightKg;
    final weightChange = body?.weightChangeKg;
    final avgCalories = body?.avgDailyCalories;

    final weightValue = currentWeight == null
        ? '-'
        : '${currentWeight.toStringAsFixed(1)} ${l10n.analyticsUnitKg}';
    final weightChangeValue = weightChange == null
        ? '-'
        : '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} ${l10n.analyticsUnitKg}';
    final caloriesValue =
        avgCalories == null ? '-' : avgCalories.round().toString();

    return Column(
      children: [
        SummaryCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BodyNutritionCorrelationScreen(
                  initialRangeIndex: _selectedTimeRangeIndex,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isLoadingStats || body == null
                      ? const Center(child: CircularProgressIndicator())
                      : _buildBodyNutritionMiniChart(body),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMetricCol(
                      l10n.metricsCurrentWeight,
                      weightValue,
                      body == null
                          ? l10n.exerciseAnalyticsNoData
                          : '${body.weightDays} ${l10n.analyticsDaysWithWeightData}',
                      width: 104,
                    ),
                    _buildMetricCol(
                      l10n.metricsWeightChange,
                      weightChangeValue,
                      _effectiveBodyRangeLabel(),
                      width: 104,
                    ),
                    _buildMetricCol(
                      l10n.metricsAvgCalories,
                      caloriesValue,
                      l10n.analyticsKcalPerDay,
                      width: 104,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    body == null
                        ? l10n.analyticsInsightNotEnoughData
                        : _bodyNutritionInsightLabel(body),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildDrillDownHint(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SummaryCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MeasurementsScreen()),
            );
          },
          child: ListTile(
            leading: Icon(Icons.straighten,
                color: Theme.of(context).colorScheme.primary),
            title: Text(l10n.body_measurements,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(l10n.measurements_description),
            trailing: Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyNutritionMiniChart(BodyNutritionAnalyticsResult data) {
    final normalizedWeight =
        BodyNutritionAnalyticsUtils.normalizedSeries(data.smoothedWeight);
    final normalizedCalories =
        BodyNutritionAnalyticsUtils.normalizedSeries(data.smoothedCalories);

    if (normalizedWeight.isEmpty && normalizedCalories.isEmpty) {
      return AnalyticsChartDefaults.stateView(
        context: context,
        l10n: l10n,
        status: AnalyticsStatus.empty,
      );
    }

    final start = data.range.start;
    final maxX =
        (data.totalDays - 1).toDouble().clamp(1.0, 100000.0).toDouble();

    List<FlSpot> toSpots(List<DailyValuePoint> points) {
      return points.map((p) {
        final x = DateTime(p.day.year, p.day.month, p.day.day)
            .difference(DateTime(start.year, start.month, start.day))
            .inDays
            .toDouble();
        return FlSpot(x, p.value);
      }).toList(growable: false);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: 0,
          maxY: 1,
          gridData: AnalyticsChartDefaults.noGrid,
          borderData: AnalyticsChartDefaults.noBorder,
          lineTouchData: const LineTouchData(enabled: false),
          titlesData: AnalyticsChartDefaults.hiddenTitles,
          lineBarsData: [
            if (normalizedCalories.isNotEmpty)
              AnalyticsChartDefaults.straightLine(
                spots: toSpots(normalizedCalories),
                barWidth: 2,
                color: Theme.of(context).colorScheme.secondary,
              ),
            if (normalizedWeight.isNotEmpty)
              AnalyticsChartDefaults.straightLine(
                spots: toSpots(normalizedWeight),
                barWidth: 2.5,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  String _bodyNutritionInsightLabel(BodyNutritionAnalyticsResult data) {
    return StatisticsPresentationFormatter.bodyNutritionInsightLabel(
      l10n,
      data.insightType,
    );
  }

  String _effectiveBodyRangeLabel() {
    final resolved = _rangePolicy.resolve(
      metricId: StatisticsMetricId.bodyNutritionTrend,
      selectedRangeIndex: _selectedTimeRangeIndex,
      earliestAvailableDay: _bodyNutrition?.range.start,
    );
    final days = resolved.effectiveDays;
    if (days == null || days <= 0) return _timeRanges[_selectedTimeRangeIndex];
    if (_rangePolicy.isAllTimeRangeIndex(_selectedTimeRangeIndex)) {
      return '${l10n.filterAll} (${days}d)';
    }
    return _timeRanges[_selectedTimeRangeIndex];
  }

  Widget _buildMetricCol(String label, String value, String subLabel,
      {double width = 132}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: width,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: width,
          child: Text(value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          width: width,
          child: Text(subLabel,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildDrillDownHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          l10n.analyticsViewDetails,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
        const SizedBox(width: 2),
        Icon(
          Icons.chevron_right,
          size: 18,
          color: Theme.of(context).colorScheme.outline,
        ),
      ],
    );
  }

  Widget _buildMiniBars(List<double> values) {
    if (values.isEmpty || values.every((v) => v <= 0)) {
      return Center(
        child: Text(
          l10n.exerciseAnalyticsNoData,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      );
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((value) {
          final ratio = maxValue <= 0 ? 0.0 : value / maxValue;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Container(
                height: (ratio * 72).clamp(6, 72),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMuscleDistributionHeatmap(List<Map<String, dynamic>> muscles) {
    if (muscles.isEmpty) {
      return Center(
        child: Text(
          l10n.noWorkoutDataLabel,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
          textAlign: TextAlign.center,
        ),
      );
    }

    final maxShare = muscles
        .map((m) => (m['distributionShare'] as num).toDouble())
        .fold<double>(0.0, (a, b) => a > b ? a : b)
        .clamp(0.0001, 1.0);

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: muscles.map((m) {
          final share = (m['distributionShare'] as num).toDouble();
          final ratio = (share / maxShare).clamp(0.08, 1.0);
          final label = m['muscleGroup'] as String;
          final pct = (share * 100).toStringAsFixed(0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              children: [
                SizedBox(
                  width: 78,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 12,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerLow,
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.45 + (ratio * 0.45)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 34,
                  child: Text(
                    '$pct%',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _muscleGuidanceLabel(bool dataQualityOk, List<String> undertrained) {
    return StatisticsPresentationFormatter.muscleGuidanceLabel(
      l10n,
      dataQualityOk,
      undertrained.take(2),
    );
  }
}

enum _HubConsistencyMetric { volume, duration, frequency }
