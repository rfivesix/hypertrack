import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';

import '../../../services/profile_service.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import '../../statistics/domain/analytics_state.dart';
import '../../statistics/domain/recovery_domain_service.dart';
import '../../statistics/domain/recovery_payload_models.dart';
import '../../statistics/presentation/statistics_formatter.dart';
import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/app_section_header.dart';
import 'widgets/analytics_chart_defaults.dart';
import '../../../widgets/common/global_app_bar.dart';
import '../../workout/presentation/widgets/muscle_radar_chart.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../widgets/common/algorithm_info_sheet.dart';
import '../../exercise_catalog/domain/body_slug_mapper.dart';

class RecoveryTrackerScreen extends StatefulWidget {
  const RecoveryTrackerScreen({super.key});

  @override
  State<RecoveryTrackerScreen> createState() => _RecoveryTrackerScreenState();
}

class _RecoveryTrackerScreenState extends State<RecoveryTrackerScreen> {
  /// Canonical major muscle groups shown on the radar, in fixed clockwise
  /// display order (starting from top). The order is stable so the polygon
  /// shape stays recognisable across sessions regardless of training history.
  static const List<String> _canonicalRadarOrder = [
    'chest',
    'shoulders',
    'abs',
    'triceps',
    'back',
    'biceps',
    'lower back',
    'glutes',
    'hamstrings',
    'quads',
    'calves',
  ];

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _muscleKeys = {};

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRecovery() async {
    setState(() => _isLoading = true);
    final data = await WorkoutLocalDataSource.instance.getRecoveryAnalytics();
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
    final rawName = muscle.muscleGroup;
    final muscleName =
        StatisticsPresentationFormatter.muscleGroupLabel(l10n, rawName);
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

  double _readinessScore(RecoveryMusclePayload muscle) {
    return RecoveryDomainService.readinessScore(
      hoursSinceLastSignificantLoad: muscle.hoursSinceLastSignificantLoad,
      recoveringUpperHours: muscle.recoveringUpperHours.toDouble(),
      readyUpperHours: muscle.readyUpperHours.toDouble(),
    );
  }

  double _lastLoadPressureScore(RecoveryMusclePayload muscle) {
    return RecoveryDomainService.lastLoadPressureScore(
      lastEquivalentSets: muscle.lastEquivalentSets,
      highSessionFatigue: muscle.highSessionFatigue,
    );
  }

  String _lastLoadPressureLabel(
    AppLocalizations l10n,
    RecoveryMusclePayload muscle,
  ) {
    final pressureScore = _lastLoadPressureScore(muscle);
    final level = RecoveryDomainService.pressureLevelForScore(pressureScore);
    final levelLabel =
        StatisticsPresentationFormatter.recoveryPressureLevelLabel(l10n, level);
    return l10n.recoveryLastLoadPressure(levelLabel);
  }

  String _formatEquivalentSets(BuildContext context, double value) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final format = NumberFormat.decimalPattern(localeName)
      ..minimumFractionDigits = 1
      ..maximumFractionDigits = 1;
    return format.format(value);
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
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

  List<MuscleRadarDatum> _buildRadarData(
    List<RecoveryMusclePayload> muscles,
    AppLocalizations l10n,
  ) {
    // Build a lookup of major group → readiness score from real recovery data.
    final Map<String, double> scoreByGroup = {};
    for (final m in muscles) {
      final key = RecoveryDomainService.majorMuscleGroupFor(m.muscleGroup);
      if (key == null) continue;
      final score = _readinessScore(m);
      // If multiple minor muscles map to the same major group, keep the lowest
      // readiness score (most fatigued wins — conservative display).
      if (!scoreByGroup.containsKey(key) || score < scoreByGroup[key]!) {
        scoreByGroup[key] = score;
      }
    }

    // Return all canonical groups in fixed display order, injecting 100.0
    // (fully rested / fresh) for any group not found in training data.
    return _canonicalRadarOrder.map((group) {
      final score = scoreByGroup[group] ?? 100.0;
      return MuscleRadarDatum(
        label: StatisticsPresentationFormatter.muscleGroupLabel(l10n, group),
        value: score,
      );
    }).toList();
  }

  void _scrollToMuscle(String muscleGroup) {
    final key = _muscleKeys[muscleGroup];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  Widget _buildBodyView(
    BuildContext context,
    List<RecoveryMusclePayload> muscles,
    BodySide side,
  ) {
    final List<BodyPartHighlightData> highlights = [];

    for (final muscle in muscles) {
      final slugs = BodySlugMapper.fromRawName(muscle.muscleGroup);
      final color = _stateColor(context, muscle.state);

      for (final slug in slugs) {
        highlights.add(
          BodyPartHighlightData(
            slug: slug,
            color: color,
            payload: muscle.muscleGroup,
          ),
        );
      }
    }

    final filteredHighlights = BodySlugMapper.forSide(highlights, side);

    return BodyHighlighter(
      gender: context.watch<ProfileService>().gender.toBodyGender(),
      side: side,
      highlightedParts: filteredHighlights,
      onBodyPartTap: (slug, data) {
        if (data.payload is String) {
          _scrollToMuscle(data.payload as String);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

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
    final radarData = _buildRadarData(visibleMuscles, l10n);

    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlobalAppBar(
          title: l10n.recoveryTrackerTitle,
          actions: [
            AlgorithmInfoButton(
              title: l10n.infoRecoveryTitle,
              explanation: l10n.infoRecoveryExplanation,
              keyPoints: l10n.infoRecoveryKeyPoints.split('\n'),
              technicalTitle: l10n.infoRecoveryTechnicalTitle,
              technicalExplanation: l10n.infoRecoveryTechnicalExplanation,
              markdownAssetPath:
                  'documentation/features/muscle_recovery_model.md',
              iconColor: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                controller: _scrollController,
                padding: DesignConstants.screenPadding.copyWith(
                  top: DesignConstants.screenPadding.top + topPadding,
                  bottom: DesignConstants.bottomContentSpacer,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  AppSectionHeader(
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
                  AppSectionHeader(
                    title: l10n.analyticsRecentDistributionHeatmap,
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                  ),
                  SummaryCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!hasData)
                            AnalyticsChartDefaults.stateView(
                              context: context,
                              l10n: l10n,
                              status: AnalyticsStatus.empty,
                              emptyLabel: l10n.recoveryNoDataBody,
                            )
                          else ...[
                            TabBar(
                              tabs: [
                                Tab(
                                  icon: const Icon(Icons.accessibility_new),
                                  text: l10n.involvedMuscles,
                                ),
                                Tab(
                                  icon: const Icon(Icons.radar),
                                  text: l10n.analysis,
                                ),
                              ],
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              labelColor: colorScheme.primary,
                              unselectedLabelColor: colorScheme.onSurfaceVariant,
                              indicatorColor: colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 320,
                              child: TabBarView(
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildBodyView(
                                          context,
                                          visibleMuscles,
                                          BodySide.front,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildBodyView(
                                          context,
                                          visibleMuscles,
                                          BodySide.back,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Center(
                                    child: MuscleRadarChart(
                                      data: radarData,
                                      maxValue: 100,
                                      centerLabel: l10n.metricsMuscleReadiness,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                  AppSectionHeader(
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
                      final rawName = muscle.muscleGroup;
                      final muscleName =
                          StatisticsPresentationFormatter.muscleGroupLabel(
                        l10n,
                        rawName,
                      );
                      final state = muscle.state;
                      final stateColor = _stateColor(context, state);
                      final hours =
                          muscle.hoursSinceLastSignificantLoad.round();
                      final highFatigue = muscle.highSessionFatigue;
                      final eqSets = muscle.lastEquivalentSets;
                      final recoveringUpper = muscle.recoveringUpperHours;
                      final readyUpper = muscle.readyUpperHours;
                      final readinessScore = _readinessScore(muscle);
                      final readinessColor = stateColor;

                      final key = _muscleKeys.putIfAbsent(
                        rawName,
                        () => GlobalKey(),
                      );

                      return Padding(
                        key: key,
                        padding: const EdgeInsets.only(
                          bottom: DesignConstants.spacingS,
                        ),
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
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: stateColor.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
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
                                        _formatEquivalentSets(context, eqSets),
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
                                    _buildContextChip(
                                      context,
                                      _lastLoadPressureLabel(l10n, muscle),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      l10n.recoveryReadinessLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      readinessScore.toStringAsFixed(0),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: readinessColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    999,
                                  ),
                                  child: LinearProgressIndicator(
                                    value: readinessScore / 100,
                                    minHeight: 8,
                                    color: readinessColor,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                  ),
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
                                  l10n.recoveryCurrentWindow(
                                    recoveringUpper,
                                    readyUpper,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _explanationForMuscle(l10n, muscle),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
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
      ),
    );
  }
}
