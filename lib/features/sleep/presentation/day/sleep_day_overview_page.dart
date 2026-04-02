import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/database_helper.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../screens/settings_screen.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/summary_card.dart';
import '../../data/repository/sleep_query_repository.dart';
import '../../data/sleep_day_repository.dart';
import '../../domain/aggregation/sleep_period_aggregations.dart';
import '../../domain/sleep_enums.dart';
import '../../domain/sleep_stage_segment.dart';
import '../../platform/sleep_sync_service.dart';
import '../details/sleep_data_unavailable_card.dart';
import '../month/sleep_month_overview_page.dart';
import '../sleep_navigation.dart';
import '../week/sleep_week_overview_page.dart';
import '../widgets/sleep_period_scope_layout.dart';
import 'sleep_day_view_model.dart' hide SleepPeriodScope;

class SleepDayOverviewPage extends StatefulWidget {
  const SleepDayOverviewPage({
    super.key,
    SleepDayDataRepository? repository,
    SleepDayViewModel? viewModel,
    SleepQueryRepository? queryRepository,
    SleepPeriodScope? initialScope,
    DateTime? selectedDay,
    SleepImportService? syncService,
  })  : _repository = repository,
        _viewModel = viewModel,
        _queryRepository = queryRepository,
        _initialScope = initialScope,
        _selectedDay = selectedDay,
        _syncService = syncService;

  final SleepDayDataRepository? _repository;
  final SleepDayViewModel? _viewModel;
  final SleepQueryRepository? _queryRepository;
  final SleepPeriodScope? _initialScope;
  final DateTime? _selectedDay;
  final SleepImportService? _syncService;

  @override
  State<SleepDayOverviewPage> createState() => _SleepDayOverviewPageState();
}

const _sleepOverviewSectionSpacing = DesignConstants.spacingM;

class _SleepDayOverviewPageState extends State<SleepDayOverviewPage> {
  late final SleepDayViewModel _dayViewModel;
  late final bool _ownsDayViewModel;
  late DateTime _anchorDay;
  SleepPeriodScope _scope = SleepPeriodScope.day;
  SleepQueryRepository? _queryRepository;
  bool _isLoadingWeek = false;
  bool _isLoadingMonth = false;
  WeekSleepAggregation? _weekAggregation;
  MonthSleepAggregation? _monthAggregation;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _anchorDay = _normalizeDate(
      widget._selectedDay ?? widget._viewModel?.selectedDay ?? DateTime.now(),
    );
    _scope = widget._initialScope ?? SleepPeriodScope.day;
    _ownsDayViewModel = widget._viewModel == null;
    _dayViewModel = widget._viewModel ??
        SleepDayViewModel(
          repository: widget._repository ?? SleepDayRepository(),
          syncService: widget._syncService,
          selectedDay: _anchorDay,
        );
    _dayViewModel.load();
    _queryRepository = widget._queryRepository;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _queryRepository ??= _readQueryRepositoryFromProvider();
      _loadScopeData();
      _hasInitialized = true;
    }
  }

  @override
  void dispose() {
    if (_ownsDayViewModel) {
      _dayViewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ChangeNotifierProvider.value(
      value: _dayViewModel,
      child: SleepPeriodScopeLayout(
        appBarTitle: l10n.sleepSectionTitle,
        selectedScope: _scope,
        anchorDate: _anchorDay,
        onScopeChanged: _onScopeChanged,
        onShiftPeriod: _shiftPeriod,
        child: _buildScopeContent(context),
      ),
    );
  }

  Widget _buildScopeContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_scope) {
      case SleepPeriodScope.day:
        return const _SleepDayOverviewContent();
      case SleepPeriodScope.week:
        if (_isLoadingWeek || _weekAggregation == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final aggregation = _weekAggregation!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WeekSummaryCard(aggregation: aggregation),
            const SizedBox(height: _sleepOverviewSectionSpacing),
            WeekWindowCard(aggregation: aggregation),
            const SizedBox(height: _sleepOverviewSectionSpacing),
            WeekScoreStrip(
              aggregation: aggregation,
              onTapDay: _selectDay,
            ),
            if (aggregation.days.every((day) => day.score == null)) ...[
              const SizedBox(height: _sleepOverviewSectionSpacing),
              SleepDataUnavailableCard(
                message: l10n.sleepWeekNoScoredNights,
                margin: EdgeInsets.zero,
              ),
            ],
          ],
        );
      case SleepPeriodScope.month:
        if (_isLoadingMonth || _monthAggregation == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final aggregation = _monthAggregation!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonthSummaryCard(aggregation: aggregation),
            const SizedBox(height: _sleepOverviewSectionSpacing),
            MonthCalendarGrid(
              aggregation: aggregation,
              onTapDay: _selectDay,
            ),
            if (aggregation.days.every((day) => day.score == null)) ...[
              const SizedBox(height: _sleepOverviewSectionSpacing),
              SleepDataUnavailableCard(
                message: l10n.sleepMonthNoScoredNights,
                margin: EdgeInsets.zero,
              ),
            ],
          ],
        );
    }
  }

  void _onScopeChanged(SleepPeriodScope scope) {
    if (_scope == scope) return;
    setState(() => _scope = scope);
    _loadScopeData();
  }

  void _shiftPeriod(int direction) {
    if (direction == 0) return;
    setState(() {
      switch (_scope) {
        case SleepPeriodScope.day:
          _anchorDay = _anchorDay.add(Duration(days: direction));
          break;
        case SleepPeriodScope.week:
          _anchorDay = _anchorDay.add(Duration(days: 7 * direction));
          break;
        case SleepPeriodScope.month:
          _anchorDay =
              DateTime(_anchorDay.year, _anchorDay.month + direction, 1);
          break;
      }
    });
    _loadScopeData();
  }

  void _selectDay(DateTime day) {
    setState(() {
      _anchorDay = _normalizeDate(day);
      _scope = SleepPeriodScope.day;
    });
    _loadScopeData();
  }

  Future<void> _loadScopeData() async {
    switch (_scope) {
      case SleepPeriodScope.day:
        await _dayViewModel.setSelectedDay(_anchorDay);
        break;
      case SleepPeriodScope.week:
        await _loadWeek();
        break;
      case SleepPeriodScope.month:
        await _loadMonth();
        break;
    }
  }

  Future<void> _loadWeek() async {
    final repo = await _ensureQueryRepository();
    if (repo == null) return;
    setState(() => _isLoadingWeek = true);
    final weekStart = _anchorDay.subtract(
      Duration(days: _anchorDay.weekday - DateTime.monday),
    );
    final analyses = await repo.getAnalysesInRange(
      fromInclusive: weekStart,
      toInclusive: weekStart.add(const Duration(days: 6)),
    );
    final aggregation = const SleepPeriodAggregationEngine().aggregateWeek(
      weekStart: weekStart,
      analyses: analyses,
    );
    if (!mounted) return;
    setState(() {
      _weekAggregation = aggregation;
      _isLoadingWeek = false;
    });
  }

  Future<void> _loadMonth() async {
    final repo = await _ensureQueryRepository();
    if (repo == null) return;
    setState(() => _isLoadingMonth = true);
    final monthStart = DateTime(_anchorDay.year, _anchorDay.month, 1);
    final monthEnd = DateTime(_anchorDay.year, _anchorDay.month + 1, 0);
    final analyses = await repo.getAnalysesInRange(
      fromInclusive: monthStart,
      toInclusive: monthEnd,
    );
    final aggregation = const SleepPeriodAggregationEngine().aggregateMonth(
      monthStart: monthStart,
      analyses: analyses,
    );
    if (!mounted) return;
    setState(() {
      _monthAggregation = aggregation;
      _isLoadingMonth = false;
    });
  }

  Future<SleepQueryRepository?> _ensureQueryRepository() async {
    if (_queryRepository != null) return _queryRepository;
    final database = await DatabaseHelper.instance.database;
    if (!mounted) return null;
    setState(
      () => _queryRepository = DriftSleepQueryRepository(database: database),
    );
    return _queryRepository;
  }

  SleepQueryRepository? _readQueryRepositoryFromProvider() {
    try {
      return Provider.of<SleepQueryRepository>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
  }

  DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class _SleepDayOverviewContent extends StatelessWidget {
  const _SleepDayOverviewContent();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SleepDayViewModel>();
    final overview = model.overview;
    if (model.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (overview == null) {
      return _SleepEmptyStateCard(
        onOpenSettings: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
          if (!context.mounted) return;
          await context.read<SleepDayViewModel>().load();
        },
        onImportNow: model.importNow,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SleepTimelineCard(overview: overview),
        const SizedBox(height: _sleepOverviewSectionSpacing),
        _SleepScoreCard(overview: overview),
        const SizedBox(height: _sleepOverviewSectionSpacing),
        _SleepMetricTileGrid(overview: overview),
      ],
    );
  }
}

class _SleepEmptyStateCard extends StatelessWidget {
  const _SleepEmptyStateCard({
    required this.onOpenSettings,
    required this.onImportNow,
  });

  final VoidCallback onOpenSettings;
  final Future<bool> Function() onImportNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SummaryCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.sleepEmptyDayNoData),
            const SizedBox(height: 8),
            Text(l10n.sleepEmptyDayConnectMessage),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(l10n.sleepOpenSettingsButton),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final ok = await onImportNow();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? l10n.sleepImportFinishedRefreshing
                              : l10n.sleepImportUnavailableSettingsHint,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sync),
                  label: Text(l10n.sleepImportNowButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepTimelineCard extends StatelessWidget {
  const _SleepTimelineCard({required this.overview});

  final SleepDayOverviewData overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final segments = overview.timelineSegments;
    if (segments.isEmpty) {
      return SummaryCard(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sleepTimelineTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(l10n.sleepTimelineUnavailable),
            ],
          ),
        ),
      );
    }

    final duration = overview.session.endAtUtc.difference(
      overview.session.startAtUtc,
    );
    final totalMinutes = duration.inMinutes <= 0 ? 1 : duration.inMinutes;
    final stageRows = <_StageRowData>[
      _StageRowData(
        label: l10n.sleepStageDeepLabel,
        stages: const {CanonicalSleepStage.deep},
        color: Colors.indigo,
      ),
      _StageRowData(
        label: l10n.sleepStageLightLabel,
        stages: const {
          CanonicalSleepStage.light,
          CanonicalSleepStage.asleepUnspecified,
        },
        color: Colors.blue,
      ),
      _StageRowData(
        label: l10n.sleepStageRemLabel,
        stages: const {CanonicalSleepStage.rem},
        color: Colors.purple,
      ),
      _StageRowData(
        label: l10n.sleepStageAwakeLabel,
        stages: const {
          CanonicalSleepStage.awake,
          CanonicalSleepStage.outOfBed,
        },
        color: Theme.of(context).colorScheme.outline,
      ),
    ];
    final visibleRows = stageRows
        .where(
          (row) =>
              segments.any((segment) => row.stages.contains(segment.stage)),
        )
        .toList(growable: false);
    if (visibleRows.isEmpty) {
      return SummaryCard(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sleepTimelineTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(l10n.sleepTimelineUnavailable),
            ],
          ),
        ),
      );
    }
    return SummaryCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sleepTimelineTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            for (final row in visibleRows) ...[
              _StageTimelineRow(
                label: row.label,
                segments: segments,
                totalMinutes: totalMinutes,
                stages: row.stages,
                color: row.color,
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _StageTimelineRow extends StatelessWidget {
  const _StageTimelineRow({
    required this.label,
    required this.segments,
    required this.totalMinutes,
    required this.stages,
    required this.color,
  });

  final String label;
  final List<SleepStageSegment> segments;
  final int totalMinutes;
  final Set<CanonicalSleepStage> stages;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  for (final segment in segments)
                    Expanded(
                      flex: (segment.endAtUtc
                              .difference(segment.startAtUtc)
                              .inMinutes
                              .clamp(1, totalMinutes))
                          .toInt(),
                      child: Container(
                        color:
                            stages.contains(segment.stage) ? color : background,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StageRowData {
  const _StageRowData({
    required this.label,
    required this.stages,
    required this.color,
  });

  final String label;
  final Set<CanonicalSleepStage> stages;
  final Color color;
}

class _SleepScoreCard extends StatelessWidget {
  const _SleepScoreCard({required this.overview});

  final SleepDayOverviewData overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final score = overview.analysis.score;
    final scoreText = score == null ? '--' : score.round().toString();
    final quality = overview.analysis.sleepQuality;
    final completeness = overview.analysis.scoreCompleteness;
    final regularityDays = overview.analysis.regularityValidDays ?? 0;
    final regularityUsed = overview.analysis.regularitySri != null;
    final regularityStable = overview.analysis.regularityStable == true;
    final subtitle = overview.analysis.score == null
        ? l10n.sleepScoreUnavailableForNight
        : _qualitySubtitle(
            l10n,
            quality,
            regularityUsed: regularityUsed,
            regularityStable: regularityStable,
            regularityDays: regularityDays,
          );
    final completenessText = completeness == null
        ? l10n.sleepScoreCompletenessLabel('--')
        : l10n.sleepScoreCompletenessLabel('${(completeness * 100).round()}%');
    return SummaryCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score == null
                        ? 0
                        : (score.clamp(0.0, 100.0) / 100.0).toDouble(),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    color: _qualityColor(quality),
                  ),
                  Text(scoreText),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.sleepScoreCardTitle),
                  Text(
                    _qualityLabel(l10n, quality),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(subtitle),
                  Text(completenessText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _qualityColor(SleepQualityBucket quality) {
    return switch (quality) {
      SleepQualityBucket.good => Colors.green,
      SleepQualityBucket.average => Colors.orange,
      SleepQualityBucket.poor => Colors.red,
      SleepQualityBucket.unavailable => Colors.grey,
    };
  }

  String _qualityLabel(AppLocalizations l10n, SleepQualityBucket quality) {
    return switch (quality) {
      SleepQualityBucket.good => l10n.sleepQualityGood,
      SleepQualityBucket.average => l10n.sleepQualityAverage,
      SleepQualityBucket.poor => l10n.sleepQualityPoor,
      SleepQualityBucket.unavailable => l10n.sleepQualityUnavailable,
    };
  }

  String _qualitySubtitle(
    AppLocalizations l10n,
    SleepQualityBucket quality, {
    required bool regularityUsed,
    required bool regularityStable,
    required int regularityDays,
  }) {
    final qualityText = switch (quality) {
      SleepQualityBucket.good => l10n.sleepQualitySubtitleGood,
      SleepQualityBucket.average => l10n.sleepQualitySubtitleAverage,
      SleepQualityBucket.poor => l10n.sleepQualitySubtitlePoor,
      SleepQualityBucket.unavailable => l10n.sleepQualitySubtitleUnavailable,
    };
    if (!regularityUsed) {
      return '$qualityText ${l10n.sleepQualityRegularityNotContributing}';
    }
    if (!regularityStable) {
      return '$qualityText ${l10n.sleepQualityRegularityPreliminary}';
    }
    return '$qualityText ${l10n.sleepQualityRegularityStable(regularityDays)}';
  }
}

class _SleepMetricTileGrid extends StatelessWidget {
  const _SleepMetricTileGrid({required this.overview});

  final SleepDayOverviewData overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final regularitySubtitle = overview.regularityNights.isEmpty
        ? l10n.sleepMetricUnavailable
        : l10n.sleepRegularityNightView(
            overview.regularityNights.length.clamp(0, 7),
          );
    return GridView.count(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      children: [
        _MetricTile(
          title: l10n.sleepMetricDurationTitle,
          subtitle:
              '${overview.totalSleepDuration.inHours}h ${overview.totalSleepDuration.inMinutes.remainder(60)}m',
          onTap: () =>
              SleepNavigation.openDurationDetail(context, overview: overview),
        ),
        _MetricTile(
          title: l10n.sleepMetricHeartRateTitle,
          subtitle: overview.sleepHrAvg == null
              ? l10n.sleepMetricUnavailable
              : '${overview.sleepHrAvg!.round()} ${l10n.sleepBpmUnit}',
          onTap: () =>
              SleepNavigation.openHeartRateDetail(context, overview: overview),
        ),
        _MetricTile(
          title: l10n.sleepMetricRegularityTitle,
          subtitle: regularitySubtitle,
          onTap: () =>
              SleepNavigation.openRegularityDetail(context, overview: overview),
        ),
        _MetricTile(
          title: l10n.sleepMetricDepthTitle,
          subtitle: overview.stageDataConfidence == SleepStageConfidence.low
              ? l10n.sleepMetricDepthLowConfidence
              : (overview.hasStageData
                  ? l10n.sleepMetricDepthStagesAvailable
                  : l10n.sleepMetricUnavailable),
          onTap: () =>
              SleepNavigation.openDepthDetail(context, overview: overview),
        ),
        _MetricTile(
          title: l10n.sleepMetricInterruptionsTitle,
          subtitle: overview.interruptionsCount == null
              ? l10n.sleepMetricUnavailable
              : '${overview.interruptionsCount}',
          onTap: () => SleepNavigation.openInterruptionsDetail(
            context,
            overview: overview,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
