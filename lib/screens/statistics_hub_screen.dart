import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/workout_database_helper.dart';
import '../features/statistics/data/statistics_hub_data_adapter.dart';
import '../features/statistics/domain/body_nutrition_analytics_models.dart';
import '../features/statistics/domain/consistency_payload_models.dart';
import '../features/statistics/domain/recovery_payload_models.dart';
import '../features/statistics/domain/hub_payload_models.dart';
import '../features/statistics/domain/statistics_range_policy.dart';
import '../features/statistics/presentation/statistics_formatter.dart';
import '../features/sleep/data/sleep_hub_summary_repository.dart';
import '../features/sleep/presentation/sleep_navigation.dart';
import '../features/sleep/platform/sleep_sync_service.dart';
import '../features/steps/data/steps_aggregation_repository.dart';
import '../features/steps/domain/steps_models.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';
import '../widgets/analytics_section_header.dart';
import '../widgets/bottom_content_spacer.dart';
import '../widgets/summary_card.dart';
import '../features/steps/presentation/steps_module_screen.dart';
import 'analytics/body_nutrition_correlation_screen.dart';
import 'analytics/consistency_tracker_screen.dart';
import 'analytics/muscle_group_analytics_screen.dart';
import 'analytics/pr_dashboard_screen.dart';
import 'analytics/recovery_tracker_screen.dart';
import 'exercise_catalog_screen.dart';
import 'measurements_screen.dart';
import '../widgets/statistics_steps_card.dart';
import '../data/database_helper.dart';
import '../services/health/steps_sync_service.dart';

class StatisticsHubScreen extends StatefulWidget {
  const StatisticsHubScreen({
    super.key,
    StatisticsHubDataAdapter? hubDataAdapter,
    StepsAggregationRepository? stepsRepository,
    SleepHubSummaryRepository? sleepSummaryRepository,
    this.fetchHubAnalytics,
  })  : _hubDataAdapter = hubDataAdapter,
        _stepsRepository = stepsRepository,
        _sleepSummaryRepository = sleepSummaryRepository;

  final StatisticsHubDataAdapter? _hubDataAdapter;
  final StepsAggregationRepository? _stepsRepository;
  final SleepHubSummaryRepository? _sleepSummaryRepository;
  final Future<(StatisticsHubPayload, BodyNutritionAnalyticsResult)> Function(
    int selectedTimeRangeIndex,
  )? fetchHubAnalytics;

  @override
  State<StatisticsHubScreen> createState() => _StatisticsHubScreenState();
}

class _StatisticsHubScreenState extends State<StatisticsHubScreen> {
  static const int _days7 = 7;
  static const int _days30 = 30;
  static const int _days90 = 90;
  static const int _days180 = 180;
  static const _miniSignalPoints = 8;
  static const _fixedConsistencyWeeks = 6;
  static const _bodyTrendPoints = 10;
  static const _chipBackgroundOpacity = 0.14;
  static const _miniBarOpacity = 0.75;
  static const Duration _sleepSyncInterval = Duration(hours: 6);

  late final l10n = AppLocalizations.of(context)!;
  late final StatisticsHubDataAdapter _hubDataAdapter;
  final _rangePolicy = StatisticsRangePolicyService.instance;
  late final StepsAggregationRepository _stepsRepository;
  late final SleepHubSummaryRepository _sleepSummaryRepository;
  final StepsSyncService _stepsSyncService = StepsSyncService();
  final SleepSyncService _sleepSyncService = SleepSyncService();

  int _selectedTimeRangeIndex = 1;

  bool _isLoadingStats = true;
  List<Map<String, dynamic>> _workoutsPerWeek = [];
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
  RangeStepsAggregation? _stepsRange;
  SleepHubSummary? _sleepSummary;
  bool _stepsTrackingEnabled = false;
  bool _sleepTrackingEnabled = false;
  int _targetSteps = 8000;
  String _stepsProviderName = '';
  @override
  void initState() {
    super.initState();
    _hubDataAdapter = widget._hubDataAdapter ??
        StatisticsHubDataAdapter(
          workoutDatabaseHelper: WorkoutDatabaseHelper.instance,
        );
    _stepsRepository =
        widget._stepsRepository ?? HealthStepsAggregationRepository();
    _sleepSummaryRepository =
        widget._sleepSummaryRepository ?? SleepHubSummaryRepository();
    StepsSyncService.trackingEnabledListenable.addListener(
      _onTrackingEnabledChanged,
    );
    _syncTrackingEnabledFromSettings();
    _loadHubAnalytics();
  }

  @override
  void dispose() {
    StepsSyncService.trackingEnabledListenable.removeListener(
      _onTrackingEnabledChanged,
    );
    _sleepSummaryRepository.dispose();
    super.dispose();
  }

  void _onTrackingEnabledChanged() {
    final enabled = StepsSyncService.trackingEnabledListenable.value;
    if (enabled == null || !mounted) return;
    if (!enabled) {
      if (_stepsTrackingEnabled) {
        setState(() => _stepsTrackingEnabled = false);
      }
      return;
    }
    if (!_stepsTrackingEnabled && mounted) {
      setState(() => _stepsTrackingEnabled = true);
    }
    _loadHubAnalytics();
  }

  Future<void> _syncTrackingEnabledFromSettings() async {
    final enabled = await _stepsSyncService.isTrackingEnabled();
    if (!mounted || enabled == _stepsTrackingEnabled) return;
    setState(() => _stepsTrackingEnabled = enabled);
  }

  Future<void> _loadHubAnalytics() async {
    setState(() => _isLoadingStats = true);
    await _sleepSyncService.importRecentIfDue(
      minInterval: _sleepSyncInterval,
    );
    final selectedDays = _rangePolicy.selectedDaysFromIndex(
      _selectedTimeRangeIndex,
    );
    final earliest = await _stepsRepository.getEarliestAvailableDate();
    final resolvedRange = _rangePolicy.resolve(
      metricId: StatisticsMetricId.bodyNutritionTrend,
      selectedRangeIndex: _selectedTimeRangeIndex,
      selectedDays: selectedDays,
      earliestAvailableDay: earliest,
    );
    // Keep Steps and Sleep cards on the same effective hub window.
    final daysBack = resolvedRange.effectiveDays ?? selectedDays;
    final hubFuture = _fetchHubAnalytics(
      selectedTimeRangeIndex: _selectedTimeRangeIndex,
    );
    final stepsRangeFuture = _stepsRepository.getRangeAggregation(
      endDate: DateTime.now(),
      daysBack: daysBack,
    );
    final sleepSummaryFuture = _sleepSummaryRepository.fetchSummary(
      endDate: DateTime.now(),
      daysBack: daysBack,
    );
    final stepsTrackingFuture = _stepsRepository.isTrackingEnabled();
    final sleepTrackingFuture = _sleepSyncService.isTrackingEnabled();
    final targetStepsFuture =
        DatabaseHelper.instance.getCurrentTargetStepsOrDefault();
    final providerFuture = _stepsSyncService.getProviderFilter();

    final tuple = await hubFuture;
    final stepsRange = await stepsRangeFuture;
    final sleepSummary = await sleepSummaryFuture;
    final stepsTrackingEnabled = await stepsTrackingFuture;
    final sleepTrackingEnabled = await sleepTrackingFuture;
    final targetSteps = await targetStepsFuture;
    final providerFilter = await providerFuture;
    final providerRaw = StepsSyncService.providerFilterToRaw(providerFilter);
    String providerName = 'Local';
    if (providerRaw == 'appleHealth') {
      providerName = 'Apple Health';
    } else if (providerRaw == 'healthConnect') {
      providerName = 'Health Connect';
    } else if (providerRaw == 'withings') {
      providerName = 'Withings';
    } else if (providerRaw == 'garmin') {
      providerName = 'Garmin';
    } else if (providerRaw == 'fitbit') {
      providerName = 'Fitbit';
    }

    final hub = tuple.$1;
    final bodyNutrition = tuple.$2;
    final effectiveStepsTrackingEnabled =
        StepsSyncService.trackingEnabledListenable.value ??
            stepsTrackingEnabled;

    if (!mounted) return;
    setState(() {
      _workoutsPerWeek = hub.workoutsPerWeek;
      _muscleAnalytics = hub.muscleAnalytics;
      _trainingStats = hub.trainingStats;
      _recoveryAnalytics = hub.recoveryAnalytics;
      _notableImprovements = hub.notableImprovements;
      _bodyNutrition = bodyNutrition;
      _stepsRange = stepsRange;
      _sleepSummary = sleepSummary;
      _stepsTrackingEnabled = effectiveStepsTrackingEnabled;
      _sleepTrackingEnabled = sleepTrackingEnabled;
      _targetSteps = targetSteps;
      _stepsProviderName = providerName;
      _isLoadingStats = false;
    });
  }

  Future<(StatisticsHubPayload, BodyNutritionAnalyticsResult)>
      _fetchHubAnalytics({required int selectedTimeRangeIndex}) {
    final override = widget.fetchHubAnalytics;
    if (override != null) {
      return override(selectedTimeRangeIndex);
    }
    return _hubDataAdapter.fetch(
      selectedTimeRangeIndex: selectedTimeRangeIndex,
    );
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
                if (_stepsTrackingEnabled) ...[
                  _buildSectionTitle(context, "Steps"),
                  _buildStepsCard(),
                  const SizedBox(height: DesignConstants.spacingL),
                ],
                _buildSectionTitle(context, l10n.sectionRecovery),
                _buildRecoverySection(),
                const SizedBox(height: DesignConstants.spacingL),
                if (_sleepTrackingEnabled) ...[
                  _buildSectionTitle(context, l10n.sleepSectionTitle),
                  _buildSleepSection(),
                  const SizedBox(height: DesignConstants.spacingL),
                ],
                _buildSectionTitle(context, l10n.sectionConsistency),
                _buildConsistencySection(),
                const SizedBox(height: DesignConstants.spacingL),
                _buildSectionTitle(
                  context,
                  l10n.analyticsSectionPerformanceRecords,
                ),
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

  Widget _buildStepsCard() {
    final range = _stepsRange;
    final hasData =
        (range?.dailyTotals.any((bucket) => bucket.steps > 0) ?? false);
    final selectedDays = _rangePolicy.selectedDaysFromIndex(
      _selectedTimeRangeIndex,
    );
    final subtitleRange = _rangeSubtitle(selectedDays, range);
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    final stepsTitle = localeCode == 'de' ? 'Schritte' : 'Steps';
    final noDataText = !_stepsTrackingEnabled
        ? (localeCode == 'de'
            ? 'Schritt-Tracking in den Einstellungen aktivieren'
            : 'Enable step tracking in Settings')
        : (localeCode == 'de' ? 'Noch keine Schrittdaten' : 'No step data yet');

    // Fallback info if tracking disabled or no data
    if (!_stepsTrackingEnabled || !hasData) {
      return SummaryCard(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const StepsModuleScreen()));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderWithChevron(
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
      );
    }

    // In 7-day mode we show today's steps; in longer ranges we show total steps.
    final bool isSevenDays = _selectedTimeRangeIndex == 0;

    int currentSteps = 0;
    String stepsSubtitle = localeCode == 'de' ? 'Heute' : 'Today';

    if (isSevenDays) {
      final todayBucket = range!.dailyTotals.lastWhere(
        (bucket) =>
            bucket.start.isBefore(DateTime.now().add(const Duration(days: 1))),
        orElse: () => range.dailyTotals.last, // fallback
      );
      currentSteps = todayBucket.steps;
    } else {
      currentSteps = range!.totalSteps;
      stepsSubtitle = localeCode == 'de' ? 'Gesamtschrittzahl' : 'Total steps';
    }

    final subtitle = '$subtitleRange • $_stepsProviderName';

    return StatisticsStepsCard(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const StepsModuleScreen()));
      },
      title: stepsTitle,
      subtitle: subtitle,
      currentSteps: currentSteps,
      currentStepsSubtitle: stepsSubtitle,
      dailyTotals: range.dailyTotals,
      dailyGoal: _targetSteps,
    );
  }

  String _rangeSubtitle(int selectedDays, RangeStepsAggregation? range) {
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    if (range == null) {
      return localeCode == 'de' ? '$selectedDays Tage' : '$selectedDays days';
    }
    if (_rangePolicy.isAllTimeRangeIndex(_selectedTimeRangeIndex)) {
      return '${DateFormat.yMMMd().format(range.start)} – ${DateFormat.yMMMd().format(range.end)}';
    }
    if (selectedDays == _days7) {
      return localeCode == 'de' ? 'Letzte 7 Tage' : 'Last 7 days';
    }
    if (selectedDays == _days30) {
      return localeCode == 'de' ? 'Letzte 30 Tage' : 'Last 30 days';
    }
    if (selectedDays == _days90) {
      return localeCode == 'de' ? 'Letzte 3 Monate' : 'Last 3 months';
    }
    if (selectedDays == _days180) {
      return localeCode == 'de' ? 'Letzte 6 Monate' : 'Last 6 months';
    }
    return '${DateFormat.yMMMd().format(range.start)} – ${DateFormat.yMMMd().format(range.end)}';
  }

  Widget _buildConsistencySection() {
    final counts = _workoutsPerWeek
        .map((w) => ((w['count'] as num?) ?? 0).toDouble())
        .toList(growable: false);
    final avgWorkouts = counts.isEmpty
        ? '-'
        : (counts.reduce((a, b) => a + b) / counts.length).toStringAsFixed(1);
    final weeklyTrend = counts.toList(growable: false);
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
            _buildHeaderWithChevron(
              label: l10n.workoutsPerWeekLabel,
              chipText: _fixedWeeksChipLabel(_fixedConsistencyWeeks),
            ),
            const SizedBox(height: 4),
            Text(
              avgWorkouts == '-' ? '-' : _formatPerWeek(avgWorkouts),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
              '${l10n.analyticsRollingConsistency} • ${_fixedWeeksChipLabel(_fixedConsistencyWeeks)}',
            ),
            const SizedBox(height: 4),
            _buildMiniBars(
              values:
                  weeklyTrend.take(_miniSignalPoints).toList(growable: false),
              color: Theme.of(context).colorScheme.primary,
              semanticsLabel: l10n.sectionConsistency,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleVolumeSection() {
    final muscles = (_muscleAnalytics['muscles'] as List<dynamic>? ?? const [])
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
            (topMuscle['frequencyPerWeek'] as num).toDouble().toStringAsFixed(
                  1,
                ),
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
            _buildHeaderWithChevron(
              label: l10n.analyticsMuscleTopFrequency,
              trailingIcon: true,
              chipText: topMuscle == null
                  ? null
                  : '${(topMuscleShare * 100).toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 4),
            Text(
              _formatMuscleLabel(topMuscle?['muscleGroup'] as String?),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            _buildMicroCaption(_timeRanges[_selectedTimeRangeIndex]),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    final topImprovement =
        _notableImprovements.isNotEmpty ? _notableImprovements.first : null;
    final momentumValue = topImprovement == null
        ? '-'
        : '+${((topImprovement['improvementPct'] as num).toDouble()).toStringAsFixed(1)}%';
    final topExerciseName = topImprovement == null
        ? l10n.metricsMostImproved
        : (topImprovement['exerciseName'] as String? ??
            l10n.metricsMostImproved);
    final performanceSummaryText = _notableImprovements.isEmpty
        ? l10n.exerciseAnalyticsNoData
        : '${l10n.analyticsRecentRecords}: ${_notableImprovements.length}';
    final compactSignals = _notableImprovements
        .map((row) => ((row['improvementPct'] as num?) ?? 0).toDouble())
        .toList(growable: false);
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
                _buildHeaderWithChevron(
                  label: l10n.metricsMostImproved,
                  chipText: _effectivePerformanceRangeLabel(),
                ),
                const SizedBox(height: 4),
                Text(
                  topExerciseName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  momentumValue,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                _buildMicroCaption(l10n.analyticsRecentRecords),
                const SizedBox(height: 4),
                _buildMiniBars(
                  values: compactSignals,
                  color: Theme.of(context).colorScheme.primary,
                  semanticsLabel: l10n.analyticsSectionPerformanceRecords,
                ),
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
            leading: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              l10n.exerciseAnalyticsTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(l10n.exerciseAnalyticsSubtitle),
            trailing: Icon(
              Icons.chevron_right,
              size: DesignConstants.iconSizeM,
              color: Theme.of(context).colorScheme.outline,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                DesignConstants.borderRadiusM,
              ),
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

    return SummaryCard(
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
            Row(
              children: [
                Expanded(
                  child: _buildCardHeading(
                    label: l10n.metricsMuscleReadiness,
                    chipText: hasData ? l10n.currentlyTracking : null,
                  ),
                ),
                _buildDrillDownHint(),
              ],
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                  recovering: recovering,
                  ready: ready,
                  fresh: fresh,
                ),
                const SizedBox(height: 6),
                _buildMicroCaption(l10n.currentlyTracking),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSleepSection() {
    final l10n = AppLocalizations.of(context)!;
    final rangeLabel = _timeRanges[_selectedTimeRangeIndex];
    final summary = _sleepSummary;
    final score = summary?.averageScore;
    final scoreText = score == null ? '--' : score.round().toString();
    final scoreValue =
        score == null ? 0.0 : (score.clamp(0.0, 100.0) / 100.0).toDouble();
    final durationText = _formatSleepDuration(summary?.averageDuration);
    final bedtimeText = _formatBedtime(summary?.averageBedtimeMinutes);
    final interruptionsCount = summary?.averageInterruptions?.round();
    final interruptionsValue =
        interruptionsCount == null ? '--' : interruptionsCount.toString();
    final interruptionsSubtitle =
        (interruptionsCount == null || summary?.averageWakeDuration == null)
            ? l10n.sleepHubAverageLabel
            : l10n.sleepHubInterruptionsSummary(
                interruptionsCount,
                _formatSleepDuration(summary!.averageWakeDuration),
              );
    return SummaryCard(
      onTap: () => SleepNavigation.openDay(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                _buildRangeChip(rangeLabel),
                const SizedBox(width: 8),
                _buildDrillDownHint(),
                if (_isLoadingStats)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
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
                colorScheme.surfaceVariant,
              ),
            ),
          ),
          SizedBox(
            height: 72,
            width: 72,
            child: CircularProgressIndicator(
              value: scoreValue,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.primary,
              ),
              backgroundColor: Colors.transparent,
            ),
          ),
          Text(
            scoreText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildRangeChip(String label) {
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

  String _formatSleepDuration(Duration? value) {
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

  Widget _buildRecoveryDistributionBar({
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

  Widget _buildBodyMetricsSection() {
    final body = _bodyNutrition;
    final currentWeight = body?.currentWeightKg;
    final weightChange = body?.weightChangeKg;
    final avgCalories = body?.avgDailyCalories;
    final weightTrend =
        body?.smoothedWeight.map((p) => p.value).toList(growable: false) ??
            const <double>[];

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
                _buildHeaderWithChevron(
                  label: l10n.metricsCurrentWeight,
                  chipText: _effectiveBodyRangeLabel(),
                ),
                const SizedBox(height: 4),
                Text(
                  weightValue,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _buildBodyMetricsSupportingText(
                    body,
                    caloriesValue,
                    weightChange,
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 8),
                _buildMicroCaption(_effectiveBodyRangeLabel()),
                const SizedBox(height: 4),
                _buildMiniBars(
                  values: weightTrend
                      .take(_bodyTrendPoints)
                      .toList(growable: false),
                  color: Theme.of(context).colorScheme.secondary,
                  semanticsLabel: l10n.sectionBodyNutrition,
                ),
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
              size: DesignConstants.iconSizeM,
              color: Theme.of(context).colorScheme.outline,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                DesignConstants.borderRadiusM,
              ),
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
      return _dayCountLabel(days);
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

  String _formatPerWeek(String valueText) {
    return '$valueText / ${l10n.analyticsPerWeekAbbrev}';
  }

  String _formatMuscleLabel(String? label) {
    if (label == null || label.trim().isEmpty) {
      return _noClearFocusLabel();
    }
    final normalized = label.trim();
    if (StatisticsPresentationFormatter.isOtherCategoryLabel(normalized)) {
      return _noClearFocusLabel();
    }
    return normalized;
  }

  String _noClearFocusLabel() {
    final source = l10n.analyticsGuidanceNoClearWeakPoint;
    final stripped = source.replaceFirst(RegExp(r'^[^:]+:\s*'), '');
    return stripped.trim().isEmpty ? source : stripped.trim();
  }

  String _fixedWeeksChipLabel(int weeks) {
    return '$weeks ${l10n.weeksLabel}';
  }

  String _effectivePerformanceRangeLabel() {
    final resolved = _rangePolicy.resolve(
      metricId: StatisticsMetricId.hubNotablePrImprovements,
      selectedRangeIndex: _selectedTimeRangeIndex,
    );
    final days = resolved.effectiveDays;
    if (days == null) return _timeRanges[_selectedTimeRangeIndex];
    if (days == _rangePolicy.selectedDaysFromIndex(_selectedTimeRangeIndex)) {
      return _timeRanges[_selectedTimeRangeIndex];
    }
    return _dayCountLabel(days);
  }

  String _dayCountLabel(int days) {
    return '$days ${l10n.analyticsDayUnitLabel}';
  }

  Widget _buildCardHeading({required String label, String? chipText}) {
    final chipColor = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
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

  Widget _buildHeaderWithChevron({
    required String label,
    String? chipText,
    bool trailingIcon = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildCardHeading(label: label, chipText: chipText),
        ),
        if (trailingIcon) ...[const SizedBox(width: 8), _buildDrillDownHint()],
      ],
    );
  }

  Widget _buildDrillDownHint() {
    return Icon(
      Icons.chevron_right,
      size: 18,
      color: Theme.of(context).colorScheme.outline,
    );
  }

  Widget _buildMicroCaption(String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
    );
  }

  Widget _buildMiniBars({
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
