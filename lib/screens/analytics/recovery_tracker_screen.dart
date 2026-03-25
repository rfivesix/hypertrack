import 'package:flutter/material.dart';

import '../../data/workout_database_helper.dart';
import '../../features/statistics/domain/analytics_state.dart';
import '../../features/statistics/domain/recovery_domain_service.dart';
import '../../features/statistics/domain/recovery_payload_models.dart';
import '../../features/statistics/presentation/statistics_formatter.dart';
import '../../generated/app_localizations.dart';
import '../../util/design_constants.dart';
import '../../widgets/analytics_section_header.dart';
import '../../widgets/analytics_chart_defaults.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/muscle_radar_chart.dart';
import '../../widgets/summary_card.dart';

class RecoveryTrackerScreen extends StatefulWidget {
  const RecoveryTrackerScreen({super.key});

  @override
  State<RecoveryTrackerScreen> createState() => _RecoveryTrackerScreenState();
}

class _RecoveryTrackerScreenState extends State<RecoveryTrackerScreen> {
  static const _maxRadarMuscles = 8;
  bool _isLoading = true;
  RecoveryAnalyticsPayload _recovery = const RecoveryAnalyticsPayload(
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

  @override
  void initState() {
    super.initState();
    _loadRecovery();
  }

  Future<void> _loadRecovery() async {
    setState(() => _isLoading = true);
    final data = await WorkoutDatabaseHelper.instance.getRecoveryAnalytics();
    if (!mounted) return;
    setState(() {
      _recovery = RecoveryAnalyticsPayload.fromMap(data);
      _isLoading = false;
    });
  }

  String _overallLabel(AppLocalizations l10n, String? state) {
    return StatisticsPresentationFormatter.recoveryOverallLabel(l10n, state);
  }

  String _stateLabel(AppLocalizations l10n, String state) {
    return StatisticsPresentationFormatter.recoveryStateLabel(l10n, state);
  }

  Color _stateColor(BuildContext context, String state) {
    return StatisticsPresentationFormatter.recoveryStateColor(context, state);
  }

  String _fatigueContextLabel(AppLocalizations l10n, bool highFatigue) {
    return highFatigue
        ? l10n.recoveryFatigueContextHigh
        : l10n.recoveryFatigueContextBaseline;
  }

  String _explanationForMuscle(
    AppLocalizations l10n,
    RecoveryMusclePayload muscle,
  ) {
    final muscleName = muscle.muscleGroup;
    final hours = muscle.hoursSinceLastSignificantLoad.round();
    final highFatigue = muscle.highSessionFatigue;

    if (highFatigue) {
      return l10n.recoveryExplanationWithHighFatigue(muscleName, hours);
    }
    return l10n.recoveryExplanationBasic(muscleName, hours);
  }

  bool _shouldHideMuscle(String name) {
    return RecoveryDomainService.shouldHideMuscle(name) ||
        StatisticsPresentationFormatter.isOtherCategoryLabel(name);
  }

  double _recoveryPressureScore(RecoveryMusclePayload muscle) {
    return RecoveryDomainService.recoveryPressureScore({
      'lastEquivalentSets': muscle.lastEquivalentSets,
      'hoursSinceLastSignificantLoad': muscle.hoursSinceLastSignificantLoad,
      'highSessionFatigue': muscle.highSessionFatigue,
    });
  }

  Color _overallStateColor(BuildContext context, String overallState) {
    switch (overallState) {
      case RecoveryDomainService.overallMostlyRecovered:
        return _stateColor(context, RecoveryDomainService.stateFresh);
      case RecoveryDomainService.overallMixedRecovery:
        return _stateColor(context, RecoveryDomainService.stateReady);
      case RecoveryDomainService.overallSeveralRecovering:
        return _stateColor(context, RecoveryDomainService.stateRecovering);
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  Color _pressureColor(BuildContext context, double score) {
    if (score < 34) {
      return _stateColor(context, RecoveryDomainService.stateFresh);
    }
    if (score < 67) {
      return _stateColor(context, RecoveryDomainService.stateReady);
    }
    return _stateColor(context, RecoveryDomainService.stateRecovering);
  }

  Widget _buildReadinessPill(
    BuildContext context,
    AppLocalizations l10n, {
    required String state,
    required int count,
    required int total,
  }) {
    final color = _stateColor(context, state);
    final percent = total > 0 ? (count / total * 100).round() : 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _stateLabel(l10n, state),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count · $percent%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextChip(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildScaleLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
    );
  }

  int _computeConsistentTrackedCount({
    required int tracked,
    required int recovering,
    required int ready,
    required int fresh,
  }) {
    // Keep distribution denominators consistent even if persisted tracked total
    // is missing or temporarily lower than visible state buckets.
    final trackedFromStates = recovering + ready + fresh;
    if (tracked <= 0) {
      return trackedFromStates;
    }
    return tracked < trackedFromStates ? trackedFromStates : tracked;
  }

  List<MuscleRadarDatum> _buildRadarData(List<RecoveryMusclePayload> muscles) {
    final sorted = [...muscles]
      ..sort((a, b) => _recoveryPressureScore(b).compareTo(
            _recoveryPressureScore(a),
          ));

    return sorted
        .take(_maxRadarMuscles)
        .map((m) => MuscleRadarDatum(
              label: m.muscleGroup,
              value: _recoveryPressureScore(m),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final recovering = _recovery.totals.recovering;
    final ready = _recovery.totals.ready;
    final fresh = _recovery.totals.fresh;
    final tracked = _computeConsistentTrackedCount(
      tracked: _recovery.totals.tracked,
      recovering: recovering,
      ready: ready,
      fresh: fresh,
    );
    final hasData = _recovery.hasData;

    final muscles = _recovery.muscles;
    final visibleMuscles = muscles
        .where((m) => !_shouldHideMuscle(m.muscleGroup))
        .toList(growable: false);
    final radarData = _buildRadarData(visibleMuscles);

    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.recoveryTrackerTitle),
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
                  AnalyticsSectionHeader(
                    title: l10n.metricsMuscleReadiness,
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                  ),
                  SummaryCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _overallLabel(l10n, _recovery.overallState),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _overallStateColor(
                                    context,
                                    _recovery.overallState,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasData
                                ? l10n.recoveryHubCountsSummary(
                                    recovering,
                                    ready,
                                    fresh,
                                  )
                                : l10n.recoveryHubNoDataSummary,
                          ),
                          if (hasData && tracked > 0) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: SizedBox(
                                height: 8,
                                child: Row(
                                  children: [
                                    if (recovering > 0)
                                      Expanded(
                                        flex: recovering,
                                        child: ColoredBox(
                                          color: _stateColor(
                                            context,
                                            RecoveryDomainService
                                                .stateRecovering,
                                          ),
                                        ),
                                      ),
                                    if (ready > 0)
                                      Expanded(
                                        flex: ready,
                                        child: ColoredBox(
                                          color: _stateColor(
                                            context,
                                            RecoveryDomainService.stateReady,
                                          ),
                                        ),
                                      ),
                                    if (fresh > 0)
                                      Expanded(
                                        flex: fresh,
                                        child: ColoredBox(
                                          color: _stateColor(
                                            context,
                                            RecoveryDomainService.stateFresh,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildReadinessPill(
                                  context,
                                  l10n,
                                  state: RecoveryDomainService.stateRecovering,
                                  count: recovering,
                                  total: tracked,
                                ),
                                const SizedBox(width: 8),
                                _buildReadinessPill(
                                  context,
                                  l10n,
                                  state: RecoveryDomainService.stateReady,
                                  count: ready,
                                  total: tracked,
                                ),
                                const SizedBox(width: 8),
                                _buildReadinessPill(
                                  context,
                                  l10n,
                                  state: RecoveryDomainService.stateFresh,
                                  count: fresh,
                                  total: tracked,
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            l10n.recoveryHeuristicDisclaimer,
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
                  AnalyticsSectionHeader(
                    title: l10n.analyticsRecentDistributionHeatmap,
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                  ),
                  SummaryCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (radarData.isEmpty)
                            AnalyticsChartDefaults.stateView(
                              context: context,
                              l10n: l10n,
                              status: AnalyticsStatus.empty,
                              emptyLabel: l10n.recoveryNoDataBody,
                            )
                          else
                            Center(
                              child: MuscleRadarChart(
                                data: radarData,
                                maxValue: 100,
                                centerLabel: l10n.metricsMuscleReadiness,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.recoveryRadarHeuristicCaption,
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
                  AnalyticsSectionHeader(
                    title: l10n.recoveryByMuscleTitle,
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  if (!hasData)
                    SummaryCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text(l10n.recoveryNoDataBody),
                      ),
                    )
                  else
                    ...visibleMuscles.map((muscle) {
                      final muscleName = muscle.muscleGroup;
                      final state = muscle.state;
                      final stateColor = _stateColor(context, state);
                      final hours =
                          muscle.hoursSinceLastSignificantLoad.round();
                      final highFatigue = muscle.highSessionFatigue;
                      final eqSets = muscle.lastEquivalentSets;
                      final recoveringUpper = muscle.recoveringUpperHours;
                      final readyUpper = muscle.readyUpperHours;
                      final pressureScore = _recoveryPressureScore(muscle);
                      final pressureColor =
                          _pressureColor(context, pressureScore);

                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: DesignConstants.spacingS),
                        child: SummaryCard(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        muscleName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            stateColor.withValues(alpha: 0.14),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        _stateLabel(l10n, state),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: stateColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildContextChip(
                                      context,
                                      l10n.recoveryRecentLoad(
                                        eqSets.toStringAsFixed(1),
                                      ),
                                    ),
                                    _buildContextChip(
                                      context,
                                      l10n.recoveryLastLoadedHours(hours),
                                    ),
                                    _buildContextChip(
                                      context,
                                      _fatigueContextLabel(l10n, highFatigue),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      pressureScore.toStringAsFixed(0),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: pressureColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                          value: pressureScore / 100,
                                          minHeight: 8,
                                          color: pressureColor,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      _buildScaleLabel(context, '0'),
                                      const Spacer(),
                                      _buildScaleLabel(context, '50'),
                                      const Spacer(),
                                      _buildScaleLabel(context, '100'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.recoveryWindowHeuristic(
                                    recoveringUpper,
                                    readyUpper,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _explanationForMuscle(l10n, muscle),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
