import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/database_helper.dart';
import '../../../services/health/steps_sync_service.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/bottom_content_spacer.dart';
import '../../../widgets/global_app_bar.dart';
import '../../../widgets/statistics_steps_card.dart';
import '../../../widgets/summary_card.dart';
import '../data/steps_aggregation_repository.dart';
import '../domain/steps_models.dart';

const double _chartTopInset = 8;
const double _chartBottomInset = 28;
const double _chartLeftInset = 30;
const double _weekChartTopInset = 36;

String _compactAxisLabel(int value) {
  if (value >= 10000) {
    return '${(value / 1000).round()}k';
  }
  if (value >= 1000) {
    final short = (value / 1000).toStringAsFixed(1);
    return short.endsWith('.0')
        ? '${short.substring(0, short.length - 2)}k'
        : '${short}k';
  }
  return value.toString();
}

class StepsModuleScreen extends StatefulWidget {
  const StepsModuleScreen({
    super.key,
    this.repository,
    this.initialScope = StepsScope.day,
    this.initialDate,
    this.targetStepsLoader,
    this.stepsProviderNameLoader,
  });

  final StepsAggregationRepository? repository;
  final StepsScope initialScope;
  final DateTime? initialDate;
  final Future<int> Function()? targetStepsLoader;
  final Future<String> Function()? stepsProviderNameLoader;

  @override
  State<StepsModuleScreen> createState() => _StepsModuleScreenState();
}

class _StepsModuleScreenState extends State<StepsModuleScreen> {
  late final StepsAggregationRepository _repository;
  StepsScope _scope = StepsScope.day;
  DateTime _anchorDate = DateTime.now();
  bool _isLoading = true;
  DayStepsAggregation? _dayData;
  WeekStepsAggregation? _weekData;
  MonthStepsAggregation? _monthData;
  DateTime? _lastUpdatedAtUtc;
  int _targetSteps = StepsSyncService.defaultStepsGoal;
  String _stepsProviderName = 'Local';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? HealthStepsAggregationRepository();
    _scope = widget.initialScope;
    final seed = widget.initialDate ?? DateTime.now();
    _anchorDate = DateTime(seed.year, seed.month, seed.day);
    _loadScopeData();
  }

  Future<void> _loadScopeData() async {
    setState(() => _isLoading = true);
    final anchor = _anchorDate;
    final targetStepsFuture =
        widget.targetStepsLoader?.call() ??
            DatabaseHelper.instance.getCurrentTargetStepsOrDefault();
    final providerNameFuture =
        widget.stepsProviderNameLoader?.call() ?? _loadProviderName();
    switch (_scope) {
      case StepsScope.day:
        _dayData = await _repository.getDayAggregation(anchor);
        break;
      case StepsScope.week:
        _weekData = await _repository.getWeekAggregation(anchor);
        break;
      case StepsScope.month:
        _monthData = await _repository.getMonthAggregation(anchor);
        break;
    }
    _lastUpdatedAtUtc = await _repository.getLastUpdatedAt();
    _targetSteps = await targetStepsFuture;
    _stepsProviderName = await providerNameFuture;
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<String> _loadProviderName() async {
    final providerFilter = await StepsSyncService().getProviderFilter();
    return _providerDisplayName(
      StepsSyncService.providerFilterToRaw(providerFilter),
    );
  }

  void _onScopeChanged(StepsScope nextScope) {
    if (_scope == nextScope) return;
    setState(() => _scope = nextScope);
    _loadScopeData();
  }

  void _shiftPeriod(int direction) {
    setState(() {
      switch (_scope) {
        case StepsScope.day:
          _anchorDate = DateTime(
            _anchorDate.year,
            _anchorDate.month,
            _anchorDate.day + direction,
          );
          break;
        case StepsScope.week:
          _anchorDate = _anchorDate.add(Duration(days: 7 * direction));
          break;
        case StepsScope.month:
          _anchorDate = DateTime(
            _anchorDate.year,
            _anchorDate.month + direction,
            1,
          );
          break;
      }
    });
    _loadScopeData();
  }

  bool _canShiftForward() {
    final now = DateTime.now();
    switch (_scope) {
      case StepsScope.day:
        final selected = DateTime(
          _anchorDate.year,
          _anchorDate.month,
          _anchorDate.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        return selected.isBefore(today);
      case StepsScope.week:
        final selectedStart = _startOfWeek(_anchorDate);
        final currentStart = _startOfWeek(now);
        return selectedStart.isBefore(currentStart);
      case StepsScope.month:
        final selected = DateTime(_anchorDate.year, _anchorDate.month, 1);
        final current = DateTime(now.year, now.month, 1);
        return selected.isBefore(current);
    }
  }

  DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  String _periodLabel(BuildContext context) {
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    switch (_scope) {
      case StepsScope.day:
        return DateFormat.yMMMd(localeCode).format(_anchorDate);
      case StepsScope.week:
        final start = _startOfWeek(_anchorDate);
        final end = start.add(const Duration(days: 6));
        return '${DateFormat.MMMd(localeCode).format(start)} – ${DateFormat.MMMd(localeCode).format(end)}';
      case StepsScope.month:
        return DateFormat.yMMMM(
          localeCode,
        ).format(DateTime(_anchorDate.year, _anchorDate.month, 1));
    }
  }

  Widget _buildPeriodNavigator(BuildContext context) {
    final canForward = _canShiftForward();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _shiftPeriod(-1),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous',
          ),
          Expanded(
            child: Text(
              _periodLabel(context),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: canForward ? () => _shiftPeriod(1) : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    final showSummaryCard = _scope == StepsScope.month;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlobalAppBar(title: 'Steps'),
      body: Padding(
        padding: DesignConstants.screenPadding.copyWith(
          top: DesignConstants.screenPadding.top + topPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ScopeSwitcher(scope: _scope, onChanged: _onScopeChanged),
            _buildPeriodNavigator(context),
            const SizedBox(height: DesignConstants.spacingS),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TrendCanvas(
                            key: ValueKey(_scope),
                            scope: _scope,
                            dayData: _dayData,
                            weekData: _weekData,
                            monthData: _monthData,
                            dailyGoal: _targetSteps,
                          ),
                          if (showSummaryCard) ...[
                            const SizedBox(height: DesignConstants.spacingS),
                            _buildScopeSummaryCard(context),
                          ],
                          if (!showSummaryCard)
                            const SizedBox(height: DesignConstants.spacingS),
                          if (_lastUpdatedAtUtc != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                _lastUpdatedLabel(context, _lastUpdatedAtUtc!),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                              ),
                            ),
                          const BottomContentSpacer(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeSummaryCard(BuildContext context) {
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    final isDe = localeCode == 'de';
    final title = isDe ? 'Schritte' : 'Steps';
    final todayLabel = isDe ? 'Heute' : 'Today';
    final totalLabel = isDe ? 'Gesamtschrittzahl' : 'Total steps';
    final safeGoal =
        _targetSteps > 0 ? _targetSteps : StepsSyncService.defaultStepsGoal;

    switch (_scope) {
      case StepsScope.day:
        final data = _dayData;
        final subtitle = data == null
            ? '${isDe ? 'Heute' : 'Today'} • $_stepsProviderName'
            : '${DateFormat.MMMd(localeCode).format(data.date)} • $_stepsProviderName';
        final dayBucket = StepsBucket(
          start: data?.date ?? _anchorDate,
          steps: data?.totalSteps ?? 0,
        );
        return StatisticsStepsCard(
          title: title,
          subtitle: subtitle,
          currentSteps: data?.totalSteps ?? 0,
          currentStepsSubtitle: todayLabel,
          dailyTotals: [dayBucket],
          dailyGoal: safeGoal,
          showChevron: false,
        );
      case StepsScope.week:
        final data = _weekData;
        final subtitle =
            '${isDe ? 'Diese Woche' : 'This week'} • $_stepsProviderName';
        return StatisticsStepsCard(
          title: title,
          subtitle: subtitle,
          currentSteps: data?.totalSteps ?? 0,
          currentStepsSubtitle: totalLabel,
          dailyTotals: data?.dailyTotals ?? const [],
          dailyGoal: safeGoal,
          showChevron: false,
        );
      case StepsScope.month:
        final data = _monthData;
        final subtitle =
            '${isDe ? 'Diesen Monat' : 'This month'} • $_stepsProviderName';
        return StatisticsStepsCard(
          title: title,
          subtitle: subtitle,
          currentSteps: data?.totalSteps ?? 0,
          currentStepsSubtitle: totalLabel,
          dailyTotals: data?.dailyTotals ?? const [],
          dailyGoal: safeGoal,
          showChevron: false,
        );
    }
  }

  String _lastUpdatedLabel(BuildContext context, DateTime timestampUtc) {
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    final timeText = DateFormat.Hm().format(timestampUtc.toLocal());
    if (localeCode == 'de') {
      return 'Aktualisiert $timeText';
    }
    return 'Updated $timeText';
  }

  String _providerDisplayName(String providerRaw) {
    switch (providerRaw) {
      case 'appleHealth':
        return 'Apple Health';
      case 'healthConnect':
        return 'Health Connect';
      case 'withings':
        return 'Withings';
      case 'garmin':
        return 'Garmin';
      case 'fitbit':
        return 'Fitbit';
      default:
        return 'Local';
    }
  }
}

class _ScopeSwitcher extends StatelessWidget {
  const _ScopeSwitcher({required this.scope, required this.onChanged});

  final StepsScope scope;
  final ValueChanged<StepsScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDe =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'de';
    return Semantics(
      label: 'Steps scope switcher',
      child: SegmentedButton<StepsScope>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: StepsScope.day,
            label: Text(isDe ? 'Tag' : 'Day'),
          ),
          ButtonSegment(
            value: StepsScope.week,
            label: Text(isDe ? 'Woche' : 'Week'),
          ),
          ButtonSegment(
            value: StepsScope.month,
            label: Text(isDe ? 'Monat' : 'Month'),
          ),
        ],
        selected: {scope},
        onSelectionChanged: (selected) => onChanged(selected.first),
      ),
    );
  }
}

class _TrendCanvas extends StatelessWidget {
  const _TrendCanvas({
    super.key,
    required this.scope,
    required this.dayData,
    required this.weekData,
    required this.monthData,
    required this.dailyGoal,
  });

  final StepsScope scope;
  final DayStepsAggregation? dayData;
  final WeekStepsAggregation? weekData;
  final MonthStepsAggregation? monthData;
  final int dailyGoal;

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (scope) {
            StepsScope.day => _DayHistogram(
                key: const ValueKey('day-canvas'),
                date: dayData?.date,
                buckets: dayData?.hourlyBuckets ?? const [],
                dailyGoal: dailyGoal,
              ),
            StepsScope.week => _WeekBars(
                key: const ValueKey('week-canvas'),
                weekStart: weekData?.weekStart,
                buckets: weekData?.dailyTotals ?? const [],
                dailyGoal: dailyGoal,
              ),
            StepsScope.month => _MonthGrid(
                key: const ValueKey('month-canvas'),
                monthStart: monthData?.monthStart,
                buckets: monthData?.dailyTotals ?? const [],
                dailyGoal: dailyGoal,
              ),
          },
        ),
      ),
    );
  }
}

class _DayHistogram extends StatelessWidget {
  const _DayHistogram({
    super.key,
    required this.buckets,
    required this.dailyGoal,
    this.date,
  });

  final List<StepsBucket> buckets;
  final int dailyGoal;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    final isDe = localeCode == 'de';
    final numberFormat = NumberFormat.decimalPattern(localeCode);
    final total = buckets.fold<int>(0, (sum, b) => sum + b.steps);
    final activeHours = buckets.where((b) => b.steps > 0).length;
    final safeGoal =
        dailyGoal > 0 ? dailyGoal : StepsSyncService.defaultStepsGoal;

    StepsBucket? peakBucket;
    for (final bucket in buckets) {
      if (peakBucket == null || bucket.steps > peakBucket.steps) {
        peakBucket = bucket;
      }
    }

    int maxValue = 0;
    for (final bucket in buckets) {
      if (bucket.steps > maxValue) {
        maxValue = bucket.steps;
      }
    }
    if (maxValue <= 0) {
      maxValue = 2000;
    } else {
      // Round up to the nearest 2,000 steps for the Y axis max.
      maxValue = ((maxValue + 1999) ~/ 2000) * 2000;
    }
    const dayChartHeight = 160.0;
    const dayChartBottom = dayChartHeight - _chartBottomInset;
    const dayDrawableHeight = dayChartBottom - _chartTopInset;
    final dayGoalRatio = (safeGoal / maxValue).clamp(0.0, 1.0);
    final dayGoalLineY = dayChartBottom - (dayDrawableHeight * dayGoalRatio);
    final dayGoalLabelTop =
        (dayGoalLineY - 10).clamp(0.0, dayChartHeight - 16).toDouble();

    final peakText = peakBucket == null || peakBucket.steps <= 0
        ? '-'
        : '${DateFormat.Hm(localeCode).format(peakBucket.start)} • ${numberFormat.format(peakBucket.steps)}';

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDe ? 'Stundenverlauf' : 'Hourly timeline',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (date != null)
          Text(
            DateFormat.MMMd(localeCode).format(date!),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InsightPill(
              label: isDe ? 'Gesamt' : 'Total',
              value: numberFormat.format(total),
            ),
            _InsightPill(
              label: isDe ? 'Aktive Stunden' : 'Active hours',
              value: activeHours.toString(),
            ),
            _InsightPill(
              label: isDe ? 'Höchste Stunde' : 'Peak hour',
              value: peakText,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: dayChartHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HorizontalGuidePainter(
                    lineColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    goalColor: Theme.of(context).colorScheme.primary,
                    goalRatio: (safeGoal / maxValue).clamp(0.0, 1.0),
                    leftInset: _chartLeftInset,
                    topInset: _chartTopInset,
                    bottomInset: _chartBottomInset,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: dayGoalLabelTop,
                child: Text(
                  _compactAxisLabel(maxValue),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Positioned(
                left: 0,
                top: ((160 - _chartBottomInset - _chartTopInset) / 2) +
                    _chartTopInset -
                    8,
                child: Text(
                  _compactAxisLabel((maxValue / 2).round()),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: _chartLeftInset,
                    top: _chartTopInset,
                    right: 4,
                    bottom: _chartBottomInset,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: buckets.map((bucket) {
                      final ratio = (bucket.steps / maxValue).clamp(
                        0.0,
                        1.0,
                      );
                      return Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final barHeight = constraints.maxHeight * ratio;
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: bucket.steps <= 0
                                  ? Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : Container(
                                      width: 6,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(
                                          4,
                                        ),
                                      ),
                                    ),
                            );
                          },
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ),
              ),
              Positioned(
                left: _chartLeftInset,
                right: 4,
                bottom: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '00',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      '06',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      '12',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      '18',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      '24',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({
    super.key,
    required this.buckets,
    required this.dailyGoal,
    this.weekStart,
  });

  final List<StepsBucket> buckets;
  final int dailyGoal;
  final DateTime? weekStart;

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    final isDe = localeCode == 'de';
    final numberFormat = NumberFormat.decimalPattern(localeCode);
    final safeGoal =
        dailyGoal > 0 ? dailyGoal : StepsSyncService.defaultStepsGoal;
    final total = buckets.fold<int>(0, (sum, b) => sum + b.steps);
    final avg = buckets.isEmpty ? 0 : (total / buckets.length).round();
    final goalDays = buckets.where((b) => b.steps >= safeGoal).length;

    int maxValue = safeGoal;
    for (final bucket in buckets) {
      if (bucket.steps > maxValue) {
        maxValue = bucket.steps;
      }
    }
    if (maxValue <= 0) {
      maxValue = 1;
    }
    const weekChartHeight = 172.0;
    const weekChartBottom = weekChartHeight - _chartBottomInset;
    const weekDrawableHeight = weekChartBottom - _weekChartTopInset;
    final weekGoalRatio = (safeGoal / maxValue).clamp(0.0, 1.0);
    final weekGoalLineY =
        weekChartBottom - (weekDrawableHeight * weekGoalRatio);
    final weekGoalLabelTop =
        (weekGoalLineY - 10).clamp(0.0, weekChartHeight - 16).toDouble();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          weekStart == null
              ? (isDe ? 'Diese Woche' : 'This week')
              : '${DateFormat.MMMd(localeCode).format(weekStart!)} – ${DateFormat.MMMd(localeCode).format(weekStart!.add(const Duration(days: 6)))}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InsightPill(
              label: isDe ? 'Gesamt' : 'Total',
              value: numberFormat.format(total),
            ),
            _InsightPill(
              label: isDe ? 'Ø / Tag' : 'Avg / day',
              value: numberFormat.format(avg),
            ),
            _InsightPill(
              label: isDe ? 'Ziel erreicht' : 'Goal hit',
              value: '$goalDays/${buckets.length}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: weekChartHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HorizontalGuidePainter(
                    lineColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    goalColor: Theme.of(context).colorScheme.primary,
                    goalRatio: (safeGoal / maxValue).clamp(0.0, 1.0),
                    leftInset: _chartLeftInset,
                    topInset: _weekChartTopInset,
                    bottomInset: _chartBottomInset,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: weekGoalLabelTop,
                child: Text(
                  _compactAxisLabel(maxValue),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Positioned(
                left: 0,
                top: ((172 - _chartBottomInset - _weekChartTopInset) / 2) +
                    _weekChartTopInset -
                    8,
                child: Text(
                  _compactAxisLabel((maxValue / 2).round()),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: _chartLeftInset,
                    top: _weekChartTopInset,
                    right: 4,
                    bottom: _chartBottomInset,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(buckets.length, (index) {
                      final bucket = buckets[index];
                      final ratio = (bucket.steps / maxValue).clamp(0.0, 1.0);
                      final isGoalHit = bucket.steps >= safeGoal;

                      return Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final barHeight = constraints.maxHeight * ratio;
                            return Stack(
                              alignment: Alignment.bottomCenter,
                              clipBehavior: Clip.none,
                              children: [
                                if (bucket.steps <= 0)
                                  Container(
                                    width: 14,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 34,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                if (isGoalHit && bucket.steps > 0)
                                  Positioned(
                                    bottom: barHeight + 2,
                                    child: Container(
                                      width: 13,
                                      height: 13,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Positioned(
                left: _chartLeftInset,
                right: 4,
                bottom: 0,
                child: Row(
                  children: List.generate(buckets.length, (index) {
                    final bucket = buckets[index];
                    final day = DateTime(
                      bucket.start.year,
                      bucket.start.month,
                      bucket.start.day,
                    );
                    final isToday = day == today;
                    final label = DateFormat.E(
                      localeCode,
                    ).format(bucket.start).substring(0, 1).toUpperCase();
                    return Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight:
                                    isToday ? FontWeight.w700 : FontWeight.w500,
                                color: isToday
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    super.key,
    required this.buckets,
    required this.dailyGoal,
    this.monthStart,
  });

  final List<StepsBucket> buckets;
  final int dailyGoal;
  final DateTime? monthStart;

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    final isDe = localeCode == 'de';
    final numberFormat = NumberFormat.decimalPattern(localeCode);
    final safeGoal =
        dailyGoal > 0 ? dailyGoal : StepsSyncService.defaultStepsGoal;

    final resolvedMonthStart = monthStart ??
        (buckets.isNotEmpty
            ? DateTime(buckets.first.start.year, buckets.first.start.month, 1)
            : DateTime(DateTime.now().year, DateTime.now().month, 1));
    final nextMonth = DateTime(
      resolvedMonthStart.year,
      resolvedMonthStart.month + 1,
      1,
    );
    final daysInMonth = nextMonth.difference(resolvedMonthStart).inDays;
    final leadingEmpty = resolvedMonthStart.weekday - DateTime.monday;

    final byDay = <int, int>{
      for (final bucket in buckets) bucket.start.day: bucket.steps,
    };
    final total = buckets.fold<int>(0, (sum, b) => sum + b.steps);
    final avg = daysInMonth == 0 ? 0 : (total / daysInMonth).round();
    final goalDays = buckets.where((b) => b.steps >= safeGoal).length;

    int maxValue = safeGoal;
    for (final bucket in buckets) {
      if (bucket.steps > maxValue) {
        maxValue = bucket.steps;
      }
    }
    if (maxValue <= 0) {
      maxValue = 1;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mondayReference = DateTime(2024, 1, 1);

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat.yMMMM(localeCode).format(resolvedMonthStart),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InsightPill(
              label: isDe ? 'Ø / Tag' : 'Avg / day',
              value: numberFormat.format(avg),
            ),
            _InsightPill(
              label: isDe ? 'Zieltage' : 'Goal days',
              value: '$goalDays/${buckets.length}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(7, (index) {
            final dayLabel = DateFormat.E(localeCode)
                .format(mondayReference.add(Duration(days: index)))
                .substring(0, 1)
                .toUpperCase();
            return Expanded(
              child: Center(
                child: Text(
                  dayLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          itemCount: leadingEmpty + daysInMonth,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            if (index < leadingEmpty) {
              return const SizedBox.shrink();
            }
            final day = index - leadingEmpty + 1;
            final steps = byDay[day] ?? 0;
            final ratio = (steps / maxValue).clamp(0.0, 1.0);
            final isToday = today.year == resolvedMonthStart.year &&
                today.month == resolvedMonthStart.month &&
                today.day == day;
            final background = Color.lerp(
              Theme.of(context).colorScheme.surfaceContainerHighest,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
              ratio,
            )!;

            return Container(
              decoration: BoxDecoration(
                color: steps == 0
                    ? Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.6)
                    : background,
                borderRadius: BorderRadius.circular(6),
                border: isToday
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: steps == 0
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _InsightPill extends StatelessWidget {
  const _InsightPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalGuidePainter extends CustomPainter {
  _HorizontalGuidePainter({
    required this.lineColor,
    required this.goalColor,
    required this.goalRatio,
    required this.leftInset,
    required this.topInset,
    required this.bottomInset,
  });

  final Color lineColor;
  final Color goalColor;
  final double goalRatio;
  final double leftInset;
  final double topInset;
  final double bottomInset;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final goalPaint = Paint()
      ..color = goalColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;

    final chartTop = topInset;
    final chartBottom = size.height - bottomInset;
    final chartHeight = chartBottom - chartTop;
    final chartStart = leftInset;
    final chartEnd = size.width;

    for (final ratio in const [0.0, 0.5, 1.0]) {
      final y = chartBottom - chartHeight * ratio;
      canvas.drawLine(Offset(chartStart, y), Offset(chartEnd, y), guidePaint);
    }

    final yGoal = chartBottom - chartHeight * goalRatio.clamp(0.0, 1.0);
    var startX = chartStart;
    while (startX < chartEnd) {
      canvas.drawLine(
        Offset(startX, yGoal),
        Offset(startX + 6, yGoal),
        goalPaint,
      );
      startX += 10;
    }
  }

  @override
  bool shouldRepaint(covariant _HorizontalGuidePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.goalColor != goalColor ||
        oldDelegate.goalRatio != goalRatio ||
        oldDelegate.leftInset != leftInset ||
        oldDelegate.topInset != topInset ||
        oldDelegate.bottomInset != bottomInset;
  }
}
