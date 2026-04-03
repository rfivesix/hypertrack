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
import '../../domain/sleep_domain.dart';
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
    final chartSegments = _toChartSegments(overview.timelineSegments);
    if (chartSegments.isEmpty) {
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
    final chartStart = chartSegments.first.startAtUtc;
    final chartEnd = chartSegments.last.endAtUtc;
    final labels = _timelineLegend(chartSegments, l10n);
    final colors = _sleepStageColors();
    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
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
            const SizedBox(height: 12),
            _SleepTimelineLegend(labels: labels),
            const SizedBox(height: 14),
            SizedBox(
              height: 108,
              width: double.infinity,
              child: CustomPaint(
                painter: _SleepStagesPainter(
                  segments: chartSegments,
                  startAtUtc: chartStart,
                  endAtUtc: chartEnd,
                  colors: colors,
                  gridColor: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SleepTimelineAxis(
              start: chartStart.toLocal(),
              end: chartEnd.toLocal(),
              use24HourFormat: use24h,
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepTimelineAxis extends StatelessWidget {
  const _SleepTimelineAxis({
    required this.start,
    required this.end,
    required this.use24HourFormat,
  });

  final DateTime start;
  final DateTime end;
  final bool use24HourFormat;

  @override
  Widget build(BuildContext context) {
    final duration = end.difference(start);
    const tickCount = 6;
    final ticks = List<DateTime>.generate(tickCount, (index) {
      if (index == tickCount - 1) return end;
      final ratio = index / (tickCount - 1);
      final tickOffset = (duration.inMinutes * ratio).round();
      return start.add(Duration(minutes: tickOffset));
    });
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ticks
          .map((tick) => Text(_formatTick(tick, use24HourFormat)))
          .toList(growable: false),
    );
  }

  String _formatTick(DateTime value, bool use24h) {
    final hour = value.hour.toString().padLeft(2, '0');
    if (use24h) {
      return '$hour:00';
    }
    final suffix = value.hour >= 12 ? 'pm' : 'am';
    final twelveHour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    return '$twelveHour$suffix';
  }
}

class _SleepTimelineLegend extends StatelessWidget {
  const _SleepTimelineLegend({required this.labels});

  final List<(_SleepChartStage, String, Color)> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 6,
      children: labels
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.$3,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(item.$2),
              ],
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SleepStagesPainter extends CustomPainter {
  _SleepStagesPainter({
    required this.segments,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.colors,
    required this.gridColor,
  });

  final List<_ChartStageSegment> segments;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final Map<_SleepChartStage, Color> colors;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final totalMs =
        endAtUtc.millisecondsSinceEpoch - startAtUtc.millisecondsSinceEpoch;
    if (totalMs <= 0) return;

    const chartTop = 6.0;
    final chartBottom = size.height - 10.0;
    final chartHeight = chartBottom - chartTop;
    const stageCount = 4;
    final barThickness = chartHeight / stageCount;
    final segmentPaint = Paint()..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = chartTop + ((i + 1) * barThickness);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    double xFor(DateTime value) {
      final elapsed =
          value.millisecondsSinceEpoch - startAtUtc.millisecondsSinceEpoch;
      return (elapsed / totalMs) * size.width;
    }

    double yFor(_SleepChartStage stage) {
      final centerOffset = barThickness / 2;
      return switch (stage) {
        _SleepChartStage.awake => chartTop + centerOffset,
        _SleepChartStage.rem => chartTop + centerOffset + barThickness,
        _SleepChartStage.light => chartTop + centerOffset + (barThickness * 2),
        _SleepChartStage.deep => chartTop + centerOffset + (barThickness * 3),
      };
    }

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final x1 = xFor(segment.startAtUtc);
      final x2 = xFor(segment.endAtUtc);
      final yCenter = yFor(segment.stage);
      final yTop = yCenter - (barThickness / 2);
      segmentPaint.color = colors[segment.stage] ?? const Color(0xFF3F6FD8);
      canvas.drawRect(
        Rect.fromLTRB(x1, yTop, x2, yTop + barThickness),
        segmentPaint,
      );

      if (i + 1 < segments.length) {
        final next = segments[i + 1];
        final transitionX = xFor(segment.endAtUtc);
        final nextYCenter = yFor(next.stage);
        final minCenter = yCenter < nextYCenter ? yCenter : nextYCenter;
        final maxCenter = yCenter > nextYCenter ? yCenter : nextYCenter;
        final connectorWidth = (barThickness * 0.08).clamp(1.0, 2.0);
        final connectorLeft = transitionX - (connectorWidth / 2);
        final connectorRight = transitionX + (connectorWidth / 2);
        final connectorTop = minCenter - (barThickness / 2);
        final connectorBottom = maxCenter + (barThickness / 2);
        segmentPaint.color = colors[next.stage] ?? const Color(0xFF3F6FD8);
        canvas.drawRect(
          Rect.fromLTRB(
            connectorLeft,
            connectorTop,
            connectorRight,
            connectorBottom,
          ),
          segmentPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SleepStagesPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.startAtUtc != startAtUtc ||
        oldDelegate.endAtUtc != endAtUtc ||
        oldDelegate.colors != colors ||
        oldDelegate.gridColor != gridColor;
  }
}

enum _SleepChartStage { awake, rem, light, deep }

class _ChartStageSegment {
  const _ChartStageSegment({
    required this.startAtUtc,
    required this.endAtUtc,
    required this.stage,
  });

  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final _SleepChartStage stage;
}

List<_ChartStageSegment> _toChartSegments(List<SleepStageSegment> segments) {
  final sorted = [...segments]
    ..sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));
  final result = <_ChartStageSegment>[];
  for (final segment in sorted) {
    final chartStage = switch (segment.stage) {
      CanonicalSleepStage.awake ||
      CanonicalSleepStage.outOfBed =>
        _SleepChartStage.awake,
      CanonicalSleepStage.rem => _SleepChartStage.rem,
      CanonicalSleepStage.light ||
      CanonicalSleepStage.asleepUnspecified =>
        _SleepChartStage.light,
      CanonicalSleepStage.deep => _SleepChartStage.deep,
      _ => null,
    };
    if (chartStage == null) continue;
    if (segment.endAtUtc.isBefore(segment.startAtUtc) ||
        segment.endAtUtc.isAtSameMomentAs(segment.startAtUtc)) {
      continue;
    }
    result.add(
      _ChartStageSegment(
        startAtUtc: segment.startAtUtc,
        endAtUtc: segment.endAtUtc,
        stage: chartStage,
      ),
    );
  }
  return result;
}

List<(_SleepChartStage, String, Color)> _timelineLegend(
  List<_ChartStageSegment> chartSegments,
  AppLocalizations l10n,
) {
  final usedStages = chartSegments.map((segment) => segment.stage).toSet();
  final allLabels = [
    (
      _SleepChartStage.awake,
      l10n.sleepStageAwakeLabel,
      const Color(0xFFB8C7E0)
    ),
    (_SleepChartStage.rem, l10n.sleepStageRemLabel, const Color(0xFF85A8FF)),
    (
      _SleepChartStage.light,
      l10n.sleepStageLightLabel,
      const Color(0xFF3F6FD8)
    ),
    (_SleepChartStage.deep, l10n.sleepStageDeepLabel, const Color(0xFF2A5AF3)),
  ];
  return allLabels
      .where((entry) => usedStages.contains(entry.$1))
      .toList(growable: false);
}

Map<_SleepChartStage, Color> _sleepStageColors() {
  return {
    _SleepChartStage.awake: const Color(0xFFB8C7E0),
    _SleepChartStage.rem: const Color(0xFF85A8FF),
    _SleepChartStage.light: const Color(0xFF3F6FD8),
    _SleepChartStage.deep: const Color(0xFF2A5AF3),
  };
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
