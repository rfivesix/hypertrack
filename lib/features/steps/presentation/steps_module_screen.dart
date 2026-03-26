import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../util/design_constants.dart';
import '../../../widgets/bottom_content_spacer.dart';
import '../../../widgets/global_app_bar.dart';
import '../../../widgets/summary_card.dart';
import '../data/steps_aggregation_repository.dart';
import '../domain/steps_models.dart';

class StepsModuleScreen extends StatefulWidget {
  const StepsModuleScreen({super.key, this.repository});

  final StepsAggregationRepository? repository;

  @override
  State<StepsModuleScreen> createState() => _StepsModuleScreenState();
}

class _StepsModuleScreenState extends State<StepsModuleScreen> {
  late final StepsAggregationRepository _repository;
  StepsScope _scope = StepsScope.day;
  bool _isLoading = true;
  DayStepsAggregation? _dayData;
  WeekStepsAggregation? _weekData;
  MonthStepsAggregation? _monthData;
  DateTime? _lastUpdatedAtUtc;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? HealthStepsAggregationRepository();
    _loadScopeData();
  }

  Future<void> _loadScopeData() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    switch (_scope) {
      case StepsScope.day:
        _dayData = await _repository.getDayAggregation(now);
        break;
      case StepsScope.week:
        _weekData = await _repository.getWeekAggregation(now);
        break;
      case StepsScope.month:
        _monthData = await _repository.getMonthAggregation(now);
        break;
    }
    _lastUpdatedAtUtc = await _repository.getLastUpdatedAt();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _onScopeChanged(StepsScope nextScope) {
    if (_scope == nextScope) return;
    setState(() => _scope = nextScope);
    _loadScopeData();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
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
                          ),
                          const SizedBox(height: DesignConstants.spacingS),
                          _StepsSummaryCard(
                            scope: _scope,
                            dayData: _dayData,
                            weekData: _weekData,
                            monthData: _monthData,
                            lastUpdatedAtUtc: _lastUpdatedAtUtc,
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
}

class _ScopeSwitcher extends StatelessWidget {
  const _ScopeSwitcher({
    required this.scope,
    required this.onChanged,
  });

  final StepsScope scope;
  final ValueChanged<StepsScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Steps scope switcher',
      child: SegmentedButton<StepsScope>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: StepsScope.day, label: Text('Day')),
          ButtonSegment(value: StepsScope.week, label: Text('Week')),
          ButtonSegment(value: StepsScope.month, label: Text('Month')),
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
  });

  final StepsScope scope;
  final DayStepsAggregation? dayData;
  final WeekStepsAggregation? weekData;
  final MonthStepsAggregation? monthData;

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
              ),
            StepsScope.week => _WeekBars(
                key: const ValueKey('week-canvas'),
                weekStart: weekData?.weekStart,
                buckets: weekData?.dailyTotals ?? const [],
              ),
            StepsScope.month => _MonthGrid(
                key: const ValueKey('month-canvas'),
                monthStart: monthData?.monthStart,
                buckets: monthData?.dailyTotals ?? const [],
              ),
          },
        ),
      ),
    );
  }
}

class _DayHistogram extends StatelessWidget {
  const _DayHistogram({super.key, required this.buckets, this.date});
  final List<StepsBucket> buckets;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final maxValue = buckets.isEmpty
        ? 1
        : buckets.fold<int>(0, (max, b) => b.steps > max ? b.steps : max);
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today by hour', style: Theme.of(context).textTheme.titleMedium),
        if (date != null)
          Text(
            DateFormat.MMMd().format(date!),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: buckets
                .map(
                  (bucket) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        height: 100 * (bucket.steps / maxValue),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({super.key, required this.buckets, this.weekStart});
  final List<StepsBucket> buckets;
  final DateTime? weekStart;

  @override
  Widget build(BuildContext context) {
    final maxValue = buckets.isEmpty
        ? 1
        : buckets.fold<int>(0, (max, b) => b.steps > max ? b.steps : max);
    final labels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          weekStart == null
              ? 'Last 7 days'
              : '${DateFormat.MMMd().format(weekStart!)} – ${DateFormat.MMMd().format(weekStart!.add(const Duration(days: 6)))}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(buckets.length, (index) {
            final bucket = buckets[index];
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 90 * (bucket.steps / maxValue),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(labels[index], style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({super.key, required this.buckets, this.monthStart});
  final List<StepsBucket> buckets;
  final DateTime? monthStart;

  @override
  Widget build(BuildContext context) {
    final maxValue = buckets.isEmpty
        ? 1
        : buckets.fold<int>(0, (max, b) => b.steps > max ? b.steps : max);
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          monthStart == null
              ? 'This month'
              : DateFormat.yMMMM().format(monthStart!),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: buckets
              .map(
                (bucket) => Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withOpacity(
                      0.15 + 0.85 * (bucket.steps / maxValue),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _StepsSummaryCard extends StatelessWidget {
  const _StepsSummaryCard({
    required this.scope,
    required this.dayData,
    required this.weekData,
    required this.monthData,
    required this.lastUpdatedAtUtc,
  });

  final StepsScope scope;
  final DayStepsAggregation? dayData;
  final WeekStepsAggregation? weekData;
  final MonthStepsAggregation? monthData;
  final DateTime? lastUpdatedAtUtc;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern();
    final (scopeLabel, value, miniTrend) = switch (scope) {
      StepsScope.day => (
          dayData == null
              ? 'Today'
              : 'Today (${DateFormat.MMMd().format(dayData!.date)})',
          dayData?.totalSteps ?? 0,
          dayData?.hourlyBuckets.map((b) => b.steps.toDouble()).toList(growable: false) ??
              const <double>[]
        ),
      StepsScope.week => (
          weekData == null
              ? 'This week'
              : '${DateFormat.MMMd().format(weekData!.weekStart)} – ${DateFormat.MMMd().format(weekData!.weekStart.add(const Duration(days: 6)))}',
          weekData?.totalSteps ?? 0,
          weekData?.dailyTotals.map((b) => b.steps.toDouble()).toList(growable: false) ??
              const <double>[]
        ),
      StepsScope.month => (
          monthData == null
              ? 'This month'
              : DateFormat.yMMMM().format(monthData!.monthStart),
          monthData?.totalSteps ?? 0,
          monthData?.dailyTotals.map((b) => b.steps.toDouble()).toList(growable: false) ??
              const <double>[]
        ),
    };
    final max = miniTrend.isEmpty ? 1.0 : miniTrend.reduce((a, b) => a > b ? a : b);

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Steps • $scopeLabel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              formatter.format(value),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (lastUpdatedAtUtc != null) ...[
              const SizedBox(height: 4),
              Text(
                'Updated ${DateFormat.Hm().format(lastUpdatedAtUtc!.toLocal())}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: miniTrend
                    .map(
                      (point) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Container(
                            height: 24 * (point / max),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
