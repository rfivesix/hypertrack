import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../statistics/data/statistics_hub_data_adapter.dart';
import '../../statistics/domain/body_nutrition_analytics_models.dart';
import '../../statistics/domain/hub_payload_models.dart';
import '../../statistics/domain/statistics_range_policy.dart';
import '../../pulse/data/pulse_repository.dart';
import '../../sleep/data/sleep_hub_summary_repository.dart';
import '../../sleep/presentation/sleep_navigation.dart';
import '../../sleep/platform/sleep_sync_service.dart';
import '../../steps/data/steps_aggregation_repository.dart';
import '../../steps/domain/steps_models.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/common.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/summary_card.dart';
import '../../steps/presentation/steps_module_screen.dart';
import 'body_nutrition_correlation_screen.dart';
import 'consistency_tracker_screen.dart';
import 'muscle_group_analytics_screen.dart';
import 'pr_dashboard_screen.dart';
import 'recovery_tracker_screen.dart';
import '../../profile/presentation/measurements_screen.dart';
import '../../steps/presentation/statistics_steps_card.dart';
import '../../pulse/presentation/pulse_analysis_screen.dart';
import '../../../services/health/steps_sync_service.dart';
import 'statistics_hub_view_model.dart';

// Standalone widget imports
import 'widgets/analytics_card_base.dart';
import 'widgets/body_metrics_section_card.dart';
import 'widgets/consistency_section_card.dart';
import 'widgets/muscle_volume_section_card.dart';
import 'widgets/performance_section_card.dart';
import 'widgets/pulse_section_card.dart';
import 'widgets/recovery_section_card.dart';
import 'widgets/sleep_section_card.dart';

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
        stepsProviderNameLoader: stepsProviderNameLoader ??
            () async {
              final l10n = AppLocalizations.of(context)!;
              final stepsSyncService = StepsSyncService();
              final providerFilter = await stepsSyncService.getProviderFilter();
              final providerRaw =
                  StepsSyncService.providerFilterToRaw(providerFilter);
              if (providerRaw == 'appleHealth') {
                return l10n.statisticsProviderAppleHealth;
              }
              if (providerRaw == 'healthConnect') {
                return l10n.statisticsProviderHealthConnect;
              }
              if (providerRaw == 'withings') {
                return l10n.statisticsProviderWithings;
              }
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
                TimeRangeFilter(
                  ranges: _timeRanges(l10n),
                  selectedIndex: viewModel.selectedTimeRangeIndex,
                  onSelected: (index) {
                    viewModel.selectedTimeRangeIndex = index;
                  },
                ),
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

  Widget _buildStepsCard(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final section = viewModel.stepsState;
    if (section.isLoading && !section.hasData) {
      return AnalyticsCardBase.buildSectionLoadingCard(
          context, l10n, StatisticsHubSectionId.steps, l10n.steps);
    }
    if (section.hasError && !section.hasData) {
      return AnalyticsCardBase.buildSectionErrorCard(
          context, l10n, () => viewModel.loadHubAnalytics(), StatisticsHubSectionId.steps, l10n.steps);
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
      return AnalyticsCardBase.decorateSectionCard(
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
                AnalyticsCardBase.buildHeaderWithChevron(
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

    return AnalyticsCardBase.decorateSectionCard(
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
    if (viewModel.rangePolicy
        .isAllTimeRangeIndex(viewModel.selectedTimeRangeIndex)) {
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

  Widget _buildRecoverySection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    return RecoverySectionCard(
      state: viewModel.recoveryState,
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecoveryTrackerScreen()),
        );
      },
    );
  }

  Widget _buildSleepSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    return SleepSectionCard(
      state: viewModel.sleepState,
      rangeLabel: _timeRanges(l10n)[viewModel.selectedTimeRangeIndex],
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () => SleepNavigation.openDay(context),
    );
  }

  Widget _buildPulseSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    final selectedDays = viewModel.rangePolicy.selectedDaysFromIndex(
      viewModel.selectedTimeRangeIndex,
    );
    final rangeLabel =
        _rangeSubtitle(viewModel, l10n, selectedDays, viewModel.stepsRange);
    return PulseSectionCard(
      state: viewModel.pulseState,
      fallbackRangeLabel: rangeLabel,
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PulseAnalysisScreen()),
        );
      },
    );
  }

  Widget _buildConsistencySection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    return ConsistencySectionCard(
      state: viewModel.consistencyState,
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConsistencyTrackerScreen()),
        );
      },
    );
  }

  Widget _buildPerformanceSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    return PerformanceSectionCard(
      state: viewModel.performanceState,
      chipText: _effectivePerformanceRangeLabel(viewModel, l10n),
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PRDashboardScreen()),
        );
      },
    );
  }

  Widget _buildMuscleVolumeSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    return MuscleVolumeSectionCard(
      state: viewModel.volumeMusclesState,
      rangeLabel: _timeRanges(l10n)[viewModel.selectedTimeRangeIndex],
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const MuscleGroupAnalyticsScreen()),
        );
      },
    );
  }

  Widget _buildBodyMetricsSection(
    BuildContext context,
    StatisticsHubViewModel viewModel,
    AppLocalizations l10n,
  ) {
    return BodyMetricsSectionCard(
      state: viewModel.bodyNutritionState,
      rangeLabel: _effectiveBodyRangeLabel(viewModel, l10n),
      onRetry: () => viewModel.loadHubAnalytics(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BodyNutritionCorrelationScreen(
              initialRangeIndex: viewModel.selectedTimeRangeIndex,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeasurementsShortcutCard(
      BuildContext context, AppLocalizations l10n) {
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
    if (days == null || days <= 0) {
      return _timeRanges(l10n)[viewModel.selectedTimeRangeIndex];
    }
    if (viewModel.rangePolicy
        .isAllTimeRangeIndex(viewModel.selectedTimeRangeIndex)) {
      return _dayCountLabel(l10n, days);
    }
    return _timeRanges(l10n)[viewModel.selectedTimeRangeIndex];
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
    if (days == null) {
      return _timeRanges(l10n)[viewModel.selectedTimeRangeIndex];
    }
    if (days ==
        viewModel.rangePolicy
            .selectedDaysFromIndex(viewModel.selectedTimeRangeIndex)) {
      return _timeRanges(l10n)[viewModel.selectedTimeRangeIndex];
    }
    return _dayCountLabel(l10n, days);
  }

  String _dayCountLabel(AppLocalizations l10n, int days) {
    return '$days ${l10n.analyticsDayUnitLabel}';
  }
}
