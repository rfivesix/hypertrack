import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../features/statistics/data/statistics_hub_data_adapter.dart';
import '../features/statistics/domain/body_nutrition_analytics_models.dart';
import '../features/statistics/domain/hub_payload_models.dart';
import '../features/statistics/domain/statistics_range_policy.dart';
import '../features/statistics/presentation/statistics_formatter.dart';
import '../features/statistics/presentation/widgets/body_nutrition_normalized_trend_chart.dart';
import '../features/pulse/data/pulse_repository.dart';
import '../features/pulse/domain/pulse_models.dart';
import '../features/pulse/presentation/pulse_analysis_screen.dart';
import '../features/sleep/data/sleep_hub_summary_repository.dart';
import '../features/sleep/presentation/sleep_navigation.dart';
import '../features/sleep/platform/sleep_sync_service.dart';
import '../features/steps/data/steps_aggregation_repository.dart';
import '../features/steps/domain/steps_models.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';
import '../widgets/common/common.dart';
import '../widgets/bottom_content_spacer.dart';
import '../widgets/summary_card.dart';
import '../features/steps/presentation/steps_module_screen.dart';
import 'analytics/body_nutrition_correlation_screen.dart';
import 'analytics/consistency_tracker_screen.dart';
import 'analytics/muscle_group_analytics_screen.dart';
import 'analytics/pr_dashboard_screen.dart';
import 'analytics/recovery_tracker_screen.dart';
import 'measurements_screen.dart';
import '../widgets/statistics_steps_card.dart';
import '../services/health/steps_sync_service.dart';
import '../services/unit_service.dart';
import 'statistics_hub_view_model.dart';

class StatisticsHubScreen extends StatelessWidget {
  const StatisticsHubScreen({
    super.key,
    StatisticsHubDataAdapter? hubDataAdapter,
    StepsAggregationRepository? stepsRepository,
    SleepHubSummaryRepository? sleepSummaryRepository,
    PulseAnalysisRepository? pulseRepository,
    this.fetchHubAnalytics,
    this.importSleepIfDue,
    this.isSleepTrackingEnabled,
    this.targetStepsLoader,
    this.stepsProviderNameLoader,
  })  : _hubDataAdapter = hubDataAdapter,
        _stepsRepository = stepsRepository,
        _sleepSummaryRepository = sleepSummaryRepository,
        _pulseRepository = pulseRepository;

  final StatisticsHubDataAdapter? _hubDataAdapter;
  final StepsAggregationRepository? _stepsRepository;
  final SleepHubSummaryRepository? _sleepSummaryRepository;
  final PulseAnalysisRepository? _pulseRepository;
  final Future<(StatisticsHubPayload, BodyNutritionAnalyticsResult)> Function(
    int selectedTimeRangeIndex,
  )? fetchHubAnalytics;
  final Future<SleepSyncResult?> Function({
    int lookbackDays,
    Duration minInterval,
    bool force,
  })? importSleepIfDue;
  final Future<bool> Function()? isSleepTrackingEnabled;
  final Future<int> Function()? targetStepsLoader;
  final Future<String> Function()? stepsProviderNameLoader;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StatisticsHubViewModel>(
      create: (context) => StatisticsHubViewModel(
        hubDataAdapter: _hubDataAdapter,
        stepsRepository: _stepsRepository,
        sleepSummaryRepository: _sleepSummaryRepository,
        pulseRepository: _pulseRepository,
        fetchHubAnalytics: fetchHubAnalytics,
        importSleepIfDue: importSleepIfDue,
        isSleepTrackingEnabled: isSleepTrackingEnabled,
        targetStepsLoader: targetStepsLoader,
        stepsProviderNameLoader: stepsProviderNameLoader ?? () async {
          final l10n = AppLocalizations.of(context)!;
          final stepsSyncService = StepsSyncService();
          final providerFilter = await stepsSyncService.getProviderFilter();
          final providerRaw = StepsSyncService.providerFilterToRaw(providerFilter);
          if (providerRaw == 'appleHealth') return l10n.statisticsProviderAppleHealth;
          if (providerRaw == 'healthConnect') return l10n.statisticsProviderHealthConnect;
          if (providerRaw == 'withings') return l10n.statisticsProviderWithings;
          if (providerRaw == 'garmin') return l10n.statisticsProviderGarmin;
          if (providerRaw == 'fitbit') return l10n.statisticsProviderFitbit;
          return l10n.statisticsProviderLocal;
        },
      ),
      child: const _StatisticsHubScreenView(),
    );
  }
}

class _StatisticsHubScreenView extends StatelessWidget {
  const _StatisticsHubScreenView();

  static const int _days7 = 7;
  static const int _days30 = 30;
  static const int _days90 = 90;
  static const int _days180 = 180;
  static const _miniSignalPoints = 8;
  static const _fixedConsistencyWeeks = 6;
  static const _chipBackgroundOpacity = 0.14;
  static const _miniBarOpacity = 0.75;

  List<String> _timeRanges(AppLocalizations l10n) => [
        l10n.filter7Days,
        l10n.filter30Days,
        l10n.filter3Months,
        l10n.filter6Months,
        l10n.filterAll,
      ];

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StatisticsHubViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final appBarHeight = MediaQuery.of(context).padding.top;
    final finalPadding = DesignConstants.cardPadding.copyWith(
      top: DesignConstants.cardPadding.top + appBarHeight + 16,
      left: 0,
      right: 0,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: finalPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTimeRangeFilter(context, viewModel, l10n),
                const SizedBox(height: DesignConstants.spacingL),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.cardPaddingInternal,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (viewModel.stepsTrackingEnabled) ...[
                        AppSectionHeader(title: l10n.steps),
                        _buildStepsCard(context, viewModel, l10n),
                        const SizedBox(height: DesignConstants.spacingL),
                      ],
                      AppSectionHeader(title: l10n.sectionRecovery),
                      _buildRecoverySection(context, viewModel, l10n),
                      if (viewModel.sleepTrackingEnabled) ...[
                        const SizedBox(height: 8),
                        _buildSleepSection(context, viewModel, l10n),
                      ],
                      if (viewModel.pulseTrackingEnabled) ...[
                        const SizedBox(height: 8),
                        _buildPulseSection(context, viewModel, l10n),
                      ],
                      const SizedBox(height: DesignConstants.spacingL),
                      AppSectionHeader(title: l10n.statisticsSectionTraining),
                      _buildConsistencySection(context, viewModel, l10n),
                      const SizedBox(height: 8),
                      _buildPerformanceSection(context, viewModel, l10n),
                      const SizedBox(height: 8),
                      _buildMuscleVolumeSection(context, viewModel, l10n),
                      const SizedBox(height: DesignConstants.spacingL),
                      AppSectionHeader(title: l10n.statisticsSectionBody),
                      _buildBodyMetricsSection(context, viewModel, l10n),
                      const SizedBox(height: 8),
                      _buildMeasurementsShortcutCard(context, l10n),
                      const BottomContentSpacer(),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeFilter(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final ranges = _timeRanges(l10n);
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignConstants.cardPaddingInternal,
        ),
        child: Row(
          children: List.generate(ranges.length, (index) {
            final range = ranges[index];
            final isSelected = viewModel.selectedTimeRangeIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(range),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    viewModel.selectedTimeRangeIndex = index;
                  }
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSectionLoadingCard(
    BuildContext context,
    AppLocalizations l10n,
    StatisticsHubSectionId sectionId,
    String title,
  ) {
    return SummaryCard(
      key: Key('statistics_section_loading_${sectionId.name}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              l10n.load_dots,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionErrorCard(
    BuildContext context,
    AppLocalizations l10n,
    StatisticsHubViewModel viewModel,
    StatisticsHubSectionId sectionId,
    String title,
  ) {
    return SummaryCard(
      key: Key('statistics_section_error_${sectionId.name}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeading(context, label: title),
            const SizedBox(height: 8),
            Text(
              l10n.error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.sleepStatusTechnicalError,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => viewModel.loadHubAnalytics(),
              child: Text(MaterialLocalizations.of(context)
                  .refreshIndicatorSemanticLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorateSectionCard<T>(
    BuildContext context, {
    required SectionLoadState<T> state,
    required Widget child,
  }) {
    if (!state.hasData || (!state.isLoading && !state.hasError)) {
      return child;
    }
    return Stack(
      children: [
        child,
        Positioned(
          top: 10,
          right: 10,
          child: state.isLoading
              ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
        ),
      ],
    );
  }

  Widget _buildStepsCard(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final section = viewModel.stepsState;
    if (section.isLoading && !section.hasData) {
      return _buildSectionLoadingCard(context, l10n, StatisticsHubSectionId.steps, l10n.steps);
    }
    if (section.hasError && !section.hasData) {
      return _buildSectionErrorCard(context, l10n, viewModel, StatisticsHubSectionId.steps, l10n.steps);
    }
    final range = viewModel.stepsRange;
    final hasData =
        (range?.dailyTotals.any((bucket) => bucket.steps > 0) ?? false);
    final selectedDays = viewModel.rangePolicy.selectedDaysFromIndex(
      viewModel.selectedTimeRangeIndex,
    );
    final subtitleRange = _rangeSubtitle(viewModel, l10n, selectedDays, range);
    final stepsTitle = l10n.steps;
    final noDataText = !viewModel.stepsTrackingEnabled
        ? l10n.statisticsEnableStepTrackingHint
        : l10n.statisticsNoStepDataYet;

    // Fallback info if tracking disabled or no data
    if (!viewModel.stepsTrackingEnabled || !hasData) {
      return _decorateSectionCard(
        context,
        state: section,
        child: SummaryCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StepsModuleScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderWithChevron(
                  context,
                  label: stepsTitle,
                  chipText: subtitleRange,
                ),
                const SizedBox(height: 8),
                Text(
                  noDataText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // In 7-day mode we show today's steps; in longer ranges we show total steps.
    final bool isSevenDays = viewModel.selectedTimeRangeIndex == 0;

    int currentSteps = 0;
    String stepsSubtitle = l10n.today;

    if (isSevenDays) {
      final todayBucket = range!.dailyTotals.lastWhere(
        (bucket) =>
            bucket.start.isBefore(DateTime.now().add(const Duration(days: 1))),
        orElse: () => range.dailyTotals.last, // fallback
      );
      currentSteps = todayBucket.steps;
    } else {
      currentSteps = range!.totalSteps;
      stepsSubtitle = l10n.statisticsTotalSteps;
    }

    return _decorateSectionCard(
      context,
      state: section,
      child: StatisticsStepsCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StepsModuleScreen()),
          );
        },
        title: stepsTitle,
        chipText: subtitleRange,
        currentSteps: currentSteps,
        currentStepsSubtitle: stepsSubtitle,
        dailyTotals: range.dailyTotals,
        dailyGoal: viewModel.targetSteps,
      ),
    );
  }

  String _rangeSubtitle(
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
    int selectedDays,
    RangeStepsAggregation? range,
  ) {
    if (range == null) {
      return '$selectedDays ${l10n.analyticsDayUnitLabel}';
    }
    if (viewModel.rangePolicy.isAllTimeRangeIndex(viewModel.selectedTimeRangeIndex)) {
      return '${DateFormat.yMMMd().format(range.start)} – ${DateFormat.yMMMd().format(range.end)}';
    }
    if (selectedDays == _days7) {
      return l10n.statisticsLast7Days;
    }
    if (selectedDays == _days30) {
      return l10n.statisticsLast30Days;
    }
    if (selectedDays == _days90) {
      return l10n.statisticsLast3Months;
    }
    if (selectedDays == _days180) {
      return l10n.statisticsLast6Months;
    }
    return '${DateFormat.yMMMd().format(range.start)} – ${DateFormat.yMMMd().format(range.end)}';
  }

  Widget _buildConsistencySection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final section = viewModel.consistencyState;
    if (section.isLoading && !section.hasData) {
      return _buildSectionLoadingCard(
        context,
        l10n,
        StatisticsHubSectionId.consistency,
        l10n.workoutsPerWeekLabel,
      );
    }
    if (section.hasError && !section.hasData) {
      return _buildSectionErrorCard(
        context,
        l10n,
        viewModel,
        StatisticsHubSectionId.consistency,
        l10n.workoutsPerWeekLabel,
      );
    }
    final counts = viewModel.workoutsPerWeek
        .map((w) => ((w['count'] as num?) ?? 0).toDouble())
        .toList(growable: false);
    final avgWorkouts = counts.isEmpty
        ? '-'
        : (counts.reduce((a, b) => a + b) / counts.length).toStringAsFixed(1);
    final weeklyTrend = counts.toList(growable: false);
    final streakText =
        '${l10n.metricsCurrentStreak}: ${viewModel.trainingStats.streakWeeks} ${l10n.metricsActiveWeeks}';
    return _decorateSectionCard(
      context,
      state: section,
      child: SummaryCard(
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
              _buildHeaderWithChevron(
                context,
                label: l10n.workoutsPerWeekLabel,
                chipText: _fixedWeeksChipLabel(l10n, _fixedConsistencyWeeks),
              ),
              const SizedBox(height: 4),
              Text(
                avgWorkouts == '-' ? '-' : _formatPerWeek(l10n, avgWorkouts),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
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
              _buildMicroCaption(
                context,
                '${l10n.analyticsRollingConsistency} • ${_fixedWeeksChipLabel(l10n, _fixedConsistencyWeeks)}',
              ),
              const SizedBox(height: 4),
              _buildMiniBars(
                context,
                values:
                    weeklyTrend.take(_miniSignalPoints).toList(growable: false),
                color: Theme.of(context).colorScheme.primary,
                semanticsLabel: l10n.sectionConsistency,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMuscleVolumeSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final section = viewModel.volumeMusclesState;
    if (section.isLoading && !section.hasData) {
      return _buildSectionLoadingCard(
        context,
        l10n,
        StatisticsHubSectionId.volumeMuscles,
        l10n.analyticsMuscleTopFrequency,
      );
    }
    if (section.hasError && !section.hasData) {
      return _buildSectionErrorCard(
        context,
        l10n,
        viewModel,
        StatisticsHubSectionId.volumeMuscles,
        l10n.analyticsMuscleTopFrequency,
      );
    }
    final muscles = (viewModel.muscleAnalytics['muscles'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .where(
          (m) => !StatisticsPresentationFormatter.isOtherCategoryLabel(
            m['muscleGroup'] as String?,
          ),
        )
        .toList(growable: false);
    final topMuscle = muscles.isNotEmpty ? muscles.first : null;
    final topMuscleShare =
        (topMuscle?['distributionShare'] as num?)?.toDouble() ?? 0.0;
    final topMuscleFrequency = topMuscle == null
        ? l10n.exerciseAnalyticsNoData
        : _formatPerWeek(
            l10n,
            (topMuscle['frequencyPerWeek'] as num).toDouble().toStringAsFixed(
                  1,
                ),
          );

    return _decorateSectionCard(
      context,
      state: section,
      child: SummaryCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const MuscleGroupAnalyticsScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderWithChevron(
                context,
                label: l10n.analyticsMuscleTopFrequency,
                trailingIcon: true,
                chipText: topMuscle == null
                    ? null
                    : '${(topMuscleShare * 100).toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 4),
              Text(
                _formatMuscleLabel(l10n, topMuscle?['muscleGroup'] as String?),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
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
              const SizedBox(height: 6),
              _buildMicroCaption(context, _timeRanges(l10n)[viewModel.selectedTimeRangeIndex]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final section = viewModel.performanceState;
    if (section.isLoading && !section.hasData) {
      return _buildSectionLoadingCard(
        context,
        l10n,
        StatisticsHubSectionId.performanceRecords,
        l10n.exerciseAnalyticsTitle,
      );
    }
    if (section.hasError && !section.hasData) {
      return _buildSectionErrorCard(
        context,
        l10n,
        viewModel,
        StatisticsHubSectionId.performanceRecords,
        l10n.exerciseAnalyticsTitle,
      );
    }
    final topImprovement =
        viewModel.notableImprovements.isNotEmpty ? viewModel.notableImprovements.first : null;
    final momentumValue = topImprovement == null
        ? '-'
        : '+${((topImprovement['improvementPct'] as num).toDouble()).toStringAsFixed(1)}%';
    final topExerciseName = topImprovement == null
        ? l10n.metricsMostImproved
        : (topImprovement['exerciseName'] as String? ??
            l10n.metricsMostImproved);
    final performanceSummaryText = viewModel.notableImprovements.isEmpty
        ? l10n.exerciseAnalyticsNoData
        : '${l10n.analyticsRecentRecords}: ${viewModel.notableImprovements.length}';
    final compactSignals = viewModel.notableImprovements
        .map((row) => ((row['improvementPct'] as num?) ?? 0).toDouble())
        .toList(growable: false);
    final momentumColor = topImprovement == null
        ? Theme.of(context).colorScheme.outline
        : Theme.of(context).colorScheme.primary;
    return _decorateSectionCard(
      context,
      state: section,
      child: SummaryCard(
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
              _buildHeaderWithChevron(
                context,
                label: l10n.exerciseAnalyticsTitle,
                chipText: _effectivePerformanceRangeLabel(viewModel, l10n),
              ),
              const SizedBox(height: 4),
              Text(
                topExerciseName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                momentumValue,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: momentumColor,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                performanceSummaryText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 8),
              _buildMicroCaption(context, l10n.analyticsRecentRecords),
              const SizedBox(height: 4),
              _buildMiniBars(
                context,
                values: compactSignals,
                color: Theme.of(context).colorScheme.primary,
                semanticsLabel: l10n.exerciseAnalyticsTitle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecoverySection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final section = viewModel.recoveryState;
    if (section.isLoading && !section.hasData) {
      return _buildSectionLoadingCard(
        context,
        l10n,
        StatisticsHubSectionId.recovery,
        l10n.metricsMuscleReadiness,
      );
    }
    if (section.hasError && !section.hasData) {
      return _buildSectionErrorCard(
        context,
        l10n,
        viewModel,
        StatisticsHubSectionId.recovery,
        l10n.metricsMuscleReadiness,
      );
    }
    final recovering = viewModel.recoveryAnalytics.totals.recovering;
    final ready = viewModel.recoveryAnalytics.totals.ready;
    final fresh = viewModel.recoveryAnalytics.totals.fresh;
    final hasData = viewModel.recoveryAnalytics.hasData;

    final overallState = viewModel.recoveryAnalytics.overallState;
    final recoveryHeadline =
        StatisticsPresentationFormatter.recoveryOverallLabel(
      l10n,
      overallState,
    );

    final recoveryStatusSummary = hasData
        ? l10n.recoveryHubCountsSummary(recovering, ready, fresh)
        : l10n.recoveryHubNoDataSummary;

    final iconColor = StatisticsPresentationFormatter.recoveryOverallColor(
      context,
      overallState,
    );

    return _decorateSectionCard(
      context,
      state: section,
      child: SummaryCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RecoveryTrackerScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderWithChevron(
                context,
                label: l10n.metricsMuscleReadiness,
                chipText: hasData ? l10n.currentlyTracking : null,
              ),
              Text(
                recoveryHeadline,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                recoveryStatusSummary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              if (hasData) ...[
                const SizedBox(height: 8),
                _buildRecoveryDistributionBar(
                  context,
                  recovering: recovering,
                  ready: ready,
                  fresh: fresh,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSleepSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final section = viewModel.sleepState;
    if (section.isLoading && !section.hasData) {
      return _buildSectionLoadingCard(
        context,
        l10n,
        StatisticsHubSectionId.sleep,
        l10n.sleepHubScoreLabel,
      );
    }
    if (section.hasError && !section.hasData) {
      return _buildSectionErrorCard(
        context,
        l10n,
        viewModel,
        StatisticsHubSectionId.sleep,
        l10n.sleepHubScoreLabel,
      );
    }
    final rangeLabel = _timeRanges(l10n)[viewModel.selectedTimeRangeIndex];
    final summary = viewModel.sleepSummary;
    final score = summary?.averageScore;
    final scoreText = score == null ? '--' : score.round().toString();
    final scoreValue =
        score == null ? 0.0 : (score.clamp(0.0, 100.0) / 100.0).toDouble();
    final durationText = _formatSleepDuration(l10n, summary?.averageDuration);
    final bedtimeText = _formatBedtime(summary?.averageBedtimeMinutes);
    final interruptionsCount = summary?.averageInterruptions?.round();
    final interruptionsValue =
        interruptionsCount == null ? '--' : interruptionsCount.toString();
    final interruptionsSubtitle =
        (interruptionsCount == null || summary?.averageWakeDuration == null)
            ? l10n.sleepHubAverageLabel
            : l10n.sleepHubInterruptionsSummary(
                interruptionsCount,
                _formatSleepDuration(l10n, summary!.averageWakeDuration),
              );
    return _decorateSectionCard(
      context,
      state: section,
      child: SummaryCard(
        onTap: () => SleepNavigation.openDay(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  _buildRangeChip(context, rangeLabel),
                  const SizedBox(width: 8),
                  _buildDrillDownHint(context),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildSleepScoreRing(
                    context,
                    scoreValue: scoreValue,
                    scoreText: scoreText,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sleepHubScoreLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.sleepMeanScoreLabel(scoreText),
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
                ],
              ),
              const SizedBox(height: 12),
              _buildSleepMetricRow(
                context,
                color: Theme.of(context).colorScheme.primary,
                label: l10n.durationLabel,
                value: durationText,
                subtitle: l10n.sleepHubAverageLabel,
              ),
              const Divider(height: 20),
              _buildSleepMetricRow(
                context,
                color: Theme.of(context).colorScheme.tertiary,
                label: l10n.sleepHubBedtimeLabel,
                value: bedtimeText,
                subtitle: l10n.sleepHubAverageLabel,
              ),
              const Divider(height: 20),
              _buildSleepMetricRow(
                context,
                color: Theme.of(context).colorScheme.error,
                label: l10n.sleepHubInterruptionsLabel,
                value: interruptionsValue,
                subtitle: interruptionsSubtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final section = viewModel.pulseState;
    if (section.isLoading && !section.hasData) {
      return _buildSectionLoadingCard(
        context,
        l10n,
        StatisticsHubSectionId.pulse,
        l10n.pulseTitle,
      );
    }
    if (section.hasError && !section.hasData) {
      return _buildSectionErrorCard(
        context,
        l10n,
        viewModel,
        StatisticsHubSectionId.pulse,
        l10n.pulseTitle,
      );
    }
    final selectedDays = viewModel.rangePolicy.selectedDaysFromIndex(
      viewModel.selectedTimeRangeIndex,
    );
    final rangeLabel = _rangeSubtitle(viewModel, l10n, selectedDays, viewModel.stepsRange);
    final summary = viewModel.pulseSummary;
    final chipLabel = summary == null ? rangeLabel : _pulseRangeLabel(context, summary);
    final hasMetrics = summary?.hasCoreMetrics ?? false;
    final rangeValue = !hasMetrics
        ? '--'
        : '${summary!.minBpm!.round()}-${summary.maxBpm!.round()} ${l10n.sleepBpmUnit}';
    final averageValue = summary?.averageBpm == null
        ? '--'
        : '${summary!.averageBpm!.round()} ${l10n.sleepBpmUnit}';
    final restingValue = summary?.restingBpm == null
        ? '--'
        : '${summary!.restingBpm!.round()} ${l10n.sleepBpmUnit}';
    final stateText = summary == null
        ? l10n.load_dots
        : summary.hasData
            ? '${l10n.pulseSampleCount(summary.sampleCount)} - ${_pulseQualityLabel(l10n, summary.quality)}'
            : _pulseNoDataMessage(l10n, summary.noDataReason);
    return _decorateSectionCard(
      context,
      state: section,
      child: SummaryCard(
        key: const Key('statistics_pulse_card'),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PulseAnalysisScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderWithChevron(
                context,
                label: l10n.pulseTitle,
                chipText: chipLabel,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPulseMetricTile(context, l10n.pulseRangeLabel, rangeValue),
                  _buildPulseMetricTile(context, l10n.pulseAverageLabel, averageValue),
                  _buildPulseMetricTile(context, l10n.pulseRestingLabel, restingValue),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                stateText,
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

  String _pulseRangeLabel(BuildContext context, PulseAnalysisSummary summary) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final start = summary.window.startUtc.toLocal();
    final endExclusive = summary.window.endUtc.toLocal();
    final end = DateTime(
      endExclusive.year,
      endExclusive.month,
      endExclusive.day,
    ).subtract(const Duration(days: 1));
    final startDay = DateTime(start.year, start.month, start.day);
    final spansYear = startDay.year != end.year;
    final formatter =
        spansYear ? DateFormat.yMMMd(localeCode) : DateFormat.MMMd(localeCode);
    return '${formatter.format(startDay)} - ${formatter.format(end)}';
  }

  Widget _buildPulseMetricTile(BuildContext context, String label, String value) {
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  String _pulseQualityLabel(AppLocalizations l10n, PulseDataQuality quality) {
    return switch (quality) {
      PulseDataQuality.ready => l10n.pulseQualityReady,
      PulseDataQuality.limited => l10n.pulseQualityLimited,
      PulseDataQuality.insufficient => l10n.pulseQualityInsufficient,
      PulseDataQuality.noData => l10n.pulseQualityNoData,
    };
  }

  String _pulseNoDataMessage(AppLocalizations l10n, PulseNoDataReason reason) {
    return switch (reason) {
      PulseNoDataReason.disabled => l10n.pulseNoDataDisabled,
      PulseNoDataReason.permissionDenied => l10n.pulseNoDataPermissionDenied,
      PulseNoDataReason.platformUnavailable => l10n.pulseNoDataUnavailable,
      PulseNoDataReason.queryFailed => l10n.pulseNoDataQueryFailed,
      _ => l10n.pulseNoDataDefault,
    };
  }

  Widget _buildSleepScoreRing(
    BuildContext context, {
    required double scoreValue,
    required String scoreText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 72,
      width: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 72,
            width: 72,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          SizedBox(
            height: 72,
            width: 72,
            child: CircularProgressIndicator(
              value: scoreValue,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              backgroundColor: Colors.transparent,
            ),
          ),
          Text(
            scoreText,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepMetricRow(
    BuildContext context, {
    required Color color,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          height: 10,
          width: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
            ],
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRangeChip(BuildContext context, String label) {
    final chipColor = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingS,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: _chipBackgroundOpacity),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _formatSleepDuration(AppLocalizations l10n, Duration? value) {
    if (value == null) return '--';
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _formatBedtime(int? minutes) {
    if (minutes == null) return '--';
    final normalized = minutes % 1440;
    final dateTime = DateTime(2020, 1, 1, normalized ~/ 60, normalized % 60);
    return DateFormat.Hm().format(dateTime);
  }

  Widget _buildRecoveryDistributionBar(
    BuildContext context, {
    required int recovering,
    required int ready,
    required int fresh,
  }) {
    final total = recovering + ready + fresh;
    if (total <= 0) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final segments = <MapEntry<int, Color>>[
      MapEntry(recovering, colorScheme.error),
      MapEntry(ready, colorScheme.primary),
      MapEntry(fresh, colorScheme.tertiary),
    ].where((segment) => segment.key > 0).toList(growable: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            for (final segment in segments)
              Expanded(
                flex: segment.key,
                child: ColoredBox(color: segment.value),
              ),
            if (segments.isEmpty)
              Expanded(child: ColoredBox(color: colorScheme.outline)),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyMetricsSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final section = viewModel.bodyNutritionState;
    if (section.isLoading && !section.hasData) {
      return _buildSectionLoadingCard(
        context,
        l10n,
        StatisticsHubSectionId.bodyNutrition,
        l10n.sectionBodyNutrition,
      );
    }
    if (section.hasError && !section.hasData) {
      return _buildSectionErrorCard(
        context,
        l10n,
        viewModel,
        StatisticsHubSectionId.bodyNutrition,
        l10n.sectionBodyNutrition,
      );
    }
    final body = viewModel.bodyNutrition;
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

    return _decorateSectionCard(
      context,
      state: section,
      child: SummaryCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BodyNutritionCorrelationScreen(
                initialRangeIndex: viewModel.selectedTimeRangeIndex,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderWithChevron(
                context,
                label: l10n.sectionBodyNutrition,
                chipText: _effectiveBodyRangeLabel(viewModel, l10n),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBodyTrendPill(context, l10n.metricsCurrentWeight, weightValue),
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
                  ),
                  const SizedBox(width: 12),
                  _legendDot(
                    context,
                    color: const Color(0xFFF97316),
                    label: l10n.analyticsBodyNutritionTotalCaloriesLabel,
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

  Widget _buildMeasurementsShortcutCard(BuildContext context, AppLocalizations l10n) {
    return SummaryCard(
      key: const Key('statistics_measurements_link_card'),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MeasurementsScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.straighten_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.body_measurements,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.all_measurements_no_cap,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  String _effectiveBodyRangeLabel(
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final resolved = viewModel.rangePolicy.resolve(
      metricId: StatisticsMetricId.bodyNutritionTrend,
      selectedRangeIndex: viewModel.selectedTimeRangeIndex,
      earliestAvailableDay: viewModel.bodyNutrition?.range.start,
    );
    final days = resolved.effectiveDays;
    if (days == null || days <= 0) return _timeRanges(l10n)[viewModel.selectedTimeRangeIndex];
    if (viewModel.rangePolicy.isAllTimeRangeIndex(viewModel.selectedTimeRangeIndex)) {
      return _dayCountLabel(l10n, days);
    }
    return _timeRanges(l10n)[viewModel.selectedTimeRangeIndex];
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

  Widget _legendDot(BuildContext context, {required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

  String _formatPerWeek(AppLocalizations l10n, String valueText) {
    return '$valueText / ${l10n.analyticsPerWeekAbbrev}';
  }

  String _formatMuscleLabel(AppLocalizations l10n, String? label) {
    if (label == null || label.trim().isEmpty) {
      return _noClearFocusLabel(l10n);
    }
    final normalized = label.trim();
    if (StatisticsPresentationFormatter.isOtherCategoryLabel(normalized)) {
      return _noClearFocusLabel(l10n);
    }
    return normalized;
  }

  String _noClearFocusLabel(AppLocalizations l10n) {
    final source = l10n.analyticsGuidanceNoClearWeakPoint;
    final stripped = source.replaceFirst(RegExp(r'^[^:]+:\s*'), '');
    return stripped.trim().isEmpty ? source : stripped.trim();
  }

  String _fixedWeeksChipLabel(AppLocalizations l10n, int weeks) {
    return '$weeks ${l10n.weeksLabel}';
  }

  String _effectivePerformanceRangeLabel(
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final resolved = viewModel.rangePolicy.resolve(
      metricId: StatisticsMetricId.hubNotablePrImprovements,
      selectedRangeIndex: viewModel.selectedTimeRangeIndex,
    );
    final days = resolved.effectiveDays;
    if (days == null) return _timeRanges(l10n)[viewModel.selectedTimeRangeIndex];
    if (days == viewModel.rangePolicy.selectedDaysFromIndex(viewModel.selectedTimeRangeIndex)) {
      return _timeRanges(l10n)[viewModel.selectedTimeRangeIndex];
    }
    return _dayCountLabel(l10n, days);
  }

  String _dayCountLabel(AppLocalizations l10n, int days) {
    return '$days ${l10n.analyticsDayUnitLabel}';
  }

  Widget _buildCardHeading(BuildContext context, {required String label, String? chipText}) {
    final chipColor = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (chipText != null && chipText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingS,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: _chipBackgroundOpacity),
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

  Widget _buildHeaderWithChevron(
    BuildContext context, {
    required String label,
    String? chipText,
    bool trailingIcon = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildCardHeading(context, label: label, chipText: chipText),
        ),
        if (trailingIcon) ...[const SizedBox(width: 8), _buildDrillDownHint(context)],
      ],
    );
  }

  Widget _buildDrillDownHint(BuildContext context) {
    return Icon(
      Icons.chevron_right,
      size: 18,
      color: Theme.of(context).colorScheme.outline,
    );
  }

  Widget _buildMicroCaption(BuildContext context, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
    );
  }

  Widget _buildMiniBars(
    BuildContext context, {
    required List<double> values,
    required Color color,
    required String semanticsLabel,
  }) {
    final clean = values.where((v) => v.isFinite).toList(growable: false);
    if (clean.isEmpty) return const SizedBox.shrink();
    final max = clean.fold<double>(0, (a, b) => a > b ? a : b);
    final normalized = max <= 0
        ? clean.map((_) => 0.2).toList(growable: false)
        : clean.map((v) => (v / max).clamp(0.08, 1.0)).toList(growable: false);

    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: 20,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final ratio in normalized)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FractionallySizedBox(
                    heightFactor: ratio,
                    alignment: Alignment.bottomCenter,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: _miniBarOpacity),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
