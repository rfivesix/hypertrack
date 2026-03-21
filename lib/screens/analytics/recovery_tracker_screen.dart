import 'package:flutter/material.dart';

import '../../data/workout_database_helper.dart';
import '../../features/statistics/domain/recovery_domain_service.dart';
import '../../features/statistics/domain/recovery_payload_models.dart';
import '../../generated/app_localizations.dart';
import '../../util/design_constants.dart';
import '../../widgets/analytics_section_header.dart';
import '../../widgets/global_app_bar.dart';
import '../../widgets/muscle_radar_chart.dart';
import '../../widgets/summary_card.dart';

class RecoveryTrackerScreen extends StatefulWidget {
  const RecoveryTrackerScreen({super.key});

  @override
  State<RecoveryTrackerScreen> createState() => _RecoveryTrackerScreenState();
}

class _RecoveryTrackerScreenState extends State<RecoveryTrackerScreen> {
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
    return switch (state) {
      RecoveryDomainService.overallMostlyRecovered =>
        l10n.recoveryOverallMostlyRecovered,
      RecoveryDomainService.overallMixedRecovery => l10n.recoveryOverallMixed,
      RecoveryDomainService.overallSeveralRecovering =>
        l10n.recoveryOverallSeveralRecovering,
      _ => l10n.recoveryOverallInsufficientData,
    };
  }

  String _stateLabel(AppLocalizations l10n, String state) {
    return switch (state) {
      RecoveryDomainService.stateRecovering => l10n.recoveryStateRecovering,
      RecoveryDomainService.stateReady => l10n.recoveryStateReady,
      RecoveryDomainService.stateFresh => l10n.recoveryStateFresh,
      _ => l10n.recoveryStateUnknown,
    };
  }

  Color _stateColor(BuildContext context, String state) {
    return switch (state) {
      RecoveryDomainService.stateRecovering => Colors.orange,
      RecoveryDomainService.stateReady => Colors.blue,
      RecoveryDomainService.stateFresh => Colors.green,
      _ => Theme.of(context).colorScheme.outline,
    };
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
    return RecoveryDomainService.shouldHideMuscle(name);
  }

  double _recoveryPressureScore(RecoveryMusclePayload muscle) {
    return RecoveryDomainService.recoveryPressureScore({
      'lastEquivalentSets': muscle.lastEquivalentSets,
      'hoursSinceLastSignificantLoad': muscle.hoursSinceLastSignificantLoad,
      'highSessionFatigue': muscle.highSessionFatigue,
    });
  }

  List<MuscleRadarDatum> _buildRadarData(List<RecoveryMusclePayload> muscles) {
    final sorted = [...muscles]
      ..sort((a, b) => _recoveryPressureScore(b).compareTo(
            _recoveryPressureScore(a),
          ));

    final top = sorted.take(8).toList();
    final rest = sorted.skip(8).toList();
    final data = top
        .map((m) => MuscleRadarDatum(
              label: m.muscleGroup,
              value: _recoveryPressureScore(m),
            ))
        .toList();

    if (rest.isNotEmpty) {
      final avg = rest.map(_recoveryPressureScore).reduce((a, b) => a + b) /
          rest.length;
      data.add(MuscleRadarDatum(label: 'Other', value: avg));
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final recovering = _recovery.totals.recovering;
    final ready = _recovery.totals.ready;
    final fresh = _recovery.totals.fresh;
    final hasData = _recovery.hasData;

    final muscles = _recovery.muscles;
    final visibleMuscles = muscles
        .where((m) => !_shouldHideMuscle(m.muscleGroup))
        .toList(growable: false);
    final radarData = _buildRadarData(visibleMuscles);

    return Scaffold(
      appBar: GlobalAppBar(title: l10n.recoveryTrackerTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: DesignConstants.screenPadding.copyWith(
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
                            _overallLabel(
                                l10n, _recovery.overallState),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
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
                            Text(l10n.recoveryNoDataBody)
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
                      final hours = muscle.hoursSinceLastSignificantLoad.round();
                      final highFatigue = muscle.highSessionFatigue;
                      final eqSets = muscle.lastEquivalentSets;
                      final recoveringUpper = muscle.recoveringUpperHours;
                      final readyUpper = muscle.readyUpperHours;

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
                                Text(
                                  l10n.recoveryRecentLoad(
                                      eqSets.toStringAsFixed(1)),
                                ),
                                const SizedBox(height: 2),
                                Text(l10n.recoveryLastLoadedHours(hours)),
                                const SizedBox(height: 2),
                                Text(_fatigueContextLabel(l10n, highFatigue)),
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
