import 'package:flutter/material.dart';

import '../data/workout_database_helper.dart';
import '../features/statistics/data/statistics_hub_data_adapter.dart';
import '../features/statistics/domain/recovery_payload_models.dart';
import '../features/statistics/domain/statistics_range_policy.dart';
import '../features/statistics/presentation/statistics_formatter.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';
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
  static const _volumeKiloThreshold = 1000.0;

  late final l10n = AppLocalizations.of(context)!;
  final _hubDataAdapter = StatisticsHubDataAdapter(
    workoutDatabaseHelper: WorkoutDatabaseHelper.instance,
  );
  final _rangePolicy = StatisticsRangePolicyService.instance;

  int _selectedTimeRangeIndex = 1;

  bool _isLoadingStats = true;
  List<Map<String, dynamic>> _recentPRs = [];
  List<Map<String, dynamic>> _weeklyVolume = [];
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
                _buildSectionTitle(context, l10n.sectionRecovery),
                _buildRecoverySection(),
                const SizedBox(height: DesignConstants.spacingL),
                _buildSectionTitle(context, l10n.sectionConsistency),
                _buildConsistencySection(),
                const SizedBox(height: DesignConstants.spacingL),
                _buildSectionTitle(
                    context, l10n.analyticsSectionPerformanceRecords),
                _buildPerformanceSection(),
                const SizedBox(height: DesignConstants.spacingL),
                _buildSectionTitle(context, l10n.analyticsSectionVolumeMuscles),
                _buildMuscleVolumeSection(),
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

  Widget _buildConsistencySection() {
    final avgWorkouts = _trainingStats.avgPerWeek <= 0
        ? '-'
        : _trainingStats.avgPerWeek.toStringAsFixed(1);
    final streakText = _isLoadingStats
        ? l10n.load_dots
        : '${l10n.metricsCurrentStreak}: ${_trainingStats.streakWeeks} ${l10n.metricsActiveWeeks}';
    return SummaryCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConsistencyTrackerScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeading(
              icon: Icons.show_chart_rounded,
              label: l10n.workoutsPerWeekLabel,
              chipText: _timeRanges[_selectedTimeRangeIndex],
              chipColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              avgWorkouts == '-'
                  ? '-'
                  : _formatPerWeek(avgWorkouts),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              streakText,
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

  Widget _buildMuscleVolumeSection() {
    final muscles = (_muscleAnalytics['muscles'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final topMuscle = muscles.isNotEmpty ? muscles.first : null;
    final topMuscleShare =
        (topMuscle?['distributionShare'] as num?)?.toDouble() ?? 0.0;
    final topMuscleFrequency = topMuscle == null
        ? l10n.exerciseAnalyticsNoData
        : _formatPerWeek(
            (topMuscle['frequencyPerWeek'] as num).toDouble().toStringAsFixed(1),
          );

    return SummaryCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MuscleGroupAnalyticsScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeading(
              icon: Icons.tune_rounded,
              label: l10n.analyticsMuscleTopFrequency,
              chipText: '${(topMuscleShare * 100).toStringAsFixed(0)}%',
              chipColor: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(height: 4),
            Text(
              _formatMuscleLabel(topMuscle?['muscleGroup'] as String?),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              topMuscleFrequency,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            if (topMuscleShare > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: topMuscleShare.clamp(0.0, 1.0),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _buildDrillDownHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    final topImprovement =
        _notableImprovements.isNotEmpty ? _notableImprovements.first : null;
    final latestVolume =
        _weeklyVolume.isNotEmpty ? (_weeklyVolume.last['tonnage'] as num?) : null;
    final momentumValue = topImprovement == null
        ? '-'
        : '+${((topImprovement['improvementPct'] as num).toDouble()).toStringAsFixed(1)}%';
    final topExerciseName = topImprovement == null
        ? l10n.metricsMostImproved
        : (topImprovement['exerciseName'] as String? ?? l10n.metricsMostImproved);
    final recentRecordsText = _recentPRs.isEmpty
        ? l10n.exerciseAnalyticsNoData
        : '${l10n.analyticsRecentRecords}: ${_recentPRs.length}';
    final performanceSummaryText = _recentPRs.isEmpty
        ? recentRecordsText
        : '$recentRecordsText • ${l10n.metricsVolumeLifted}: ${_formatVolume(latestVolume)}';
    final momentumColor = topImprovement == null
        ? Theme.of(context).colorScheme.outline
        : Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        SummaryCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PRDashboardScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeading(
                  icon: Icons.bolt_rounded,
                  label: l10n.metricsMostImproved,
                  chipText: _timeRanges[_selectedTimeRangeIndex],
                  chipColor: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  topExerciseName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.trending_up_rounded, size: 18, color: momentumColor),
                    const SizedBox(width: 4),
                    Text(
                      momentumValue,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: momentumColor,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  performanceSummaryText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
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
    final recoveryHeadline =
        StatisticsPresentationFormatter.recoveryOverallLabel(l10n, overallState);

    final recoveryStatusSummary = hasData
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
                  _buildCardHeading(
                    icon: Icons.self_improvement_rounded,
                    label: l10n.metricsMuscleReadiness,
                    chipText: hasData ? l10n.sectionRecovery : l10n.load_dots,
                    chipColor: iconColor,
                  ),
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
                    Text(
                      recoveryHeadline,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recoveryStatusSummary,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeading(
                  icon: Icons.monitor_weight_outlined,
                  label: l10n.metricsCurrentWeight,
                  chipText: _effectiveBodyRangeLabel(),
                  chipColor: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 4),
                Text(
                  weightValue,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _buildBodyMetricsSupportingText(body, caloriesValue, weightChange),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
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

  String _buildBodyMetricsSupportingText(
    BodyNutritionAnalyticsResult? body,
    String caloriesValue,
    double? weightChange,
  ) {
    if (body == null) return l10n.analyticsInsightNotEnoughData;
    final changeText = weightChange == null
        ? null
        : '${l10n.metricsWeightChange}: ${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} ${l10n.analyticsUnitKg}';
    if (changeText == null) {
      return '${l10n.metricsAvgCalories}: $caloriesValue ${l10n.analyticsKcalPerDay}';
    }
    return '$changeText • ${l10n.metricsAvgCalories}: $caloriesValue ${l10n.analyticsKcalPerDay}';
  }

  String _formatVolume(num? volume) {
    if (volume == null) return l10n.exerciseAnalyticsNoData;
    if (volume >= _volumeKiloThreshold) {
      return '${(volume / _volumeKiloThreshold).toStringAsFixed(1)}k ${l10n.analyticsUnitKg}';
    }
    return '${volume.toStringAsFixed(0)} ${l10n.analyticsUnitKg}';
  }

  String _formatPerWeek(String valueText) {
    return '$valueText / ${l10n.analyticsPerWeekAbbrev}';
  }

  String _formatMuscleLabel(String? label) {
    if (label == null || label.trim().isEmpty) return '-';
    final normalized = label.trim();
    final normalizedLower = normalized.toLowerCase();
    if (normalizedLower == 'other' || normalizedLower == 'others') {
      return l10n.unknown;
    }
    return normalized;
  }

  Widget _buildCardHeading({
    required IconData icon,
    required String label,
    String? chipText,
    required Color chipColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: chipColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (chipText != null && chipText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: chipColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              chipText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
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

}
