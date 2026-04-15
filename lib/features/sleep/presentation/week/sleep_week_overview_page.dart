import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/summary_card.dart';
import '../../domain/aggregation/sleep_period_aggregations.dart';
import '../../data/repository/sleep_query_repository.dart';
import '../../domain/sleep_enums.dart';
import '../sleep_navigation.dart';
import '../details/sleep_data_unavailable_card.dart';
import '../widgets/sleep_window_chart_card.dart';
import '../widgets/sleep_period_scope_layout.dart';

const _sleepOverviewSectionSpacing = DesignConstants.spacingM;

class SleepWeekOverviewPage extends StatefulWidget {
  const SleepWeekOverviewPage({
    super.key,
    required this.anchorDay,
    required this.repository,
  });

  final DateTime anchorDay;
  final SleepQueryRepository repository;

  @override
  State<SleepWeekOverviewPage> createState() => _SleepWeekOverviewPageState();
}

class _SleepWeekOverviewPageState extends State<SleepWeekOverviewPage> {
  late DateTime _anchorDay;
  late final SleepQueryRepository _repository;
  WeekSleepAggregation? _aggregation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _anchorDay = DateTime(
      widget.anchorDay.year,
      widget.anchorDay.month,
      widget.anchorDay.day,
    );
    _repository = widget.repository;
    _loadWeek();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SleepPeriodScopeLayout(
      appBarTitle: l10n.sleepSectionTitle,
      selectedScope: SleepPeriodScope.week,
      anchorDate: _anchorDay,
      onScopeChanged: _onScopeChanged,
      onShiftPeriod: _shiftPeriod,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WeekSummaryCard(aggregation: _aggregation!),
                const SizedBox(height: _sleepOverviewSectionSpacing),
                WeekWindowCard(aggregation: _aggregation!),
                const SizedBox(height: _sleepOverviewSectionSpacing),
                WeekScoreStrip(
                  aggregation: _aggregation!,
                  onTapDay: (day) =>
                      SleepNavigation.openDayForDate(context, day),
                ),
                if (_aggregation!.days.every((day) => day.score == null)) ...[
                  const SizedBox(height: _sleepOverviewSectionSpacing),
                  SleepDataUnavailableCard(
                    message: l10n.sleepWeekNoScoredNights,
                    margin: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _loadWeek() async {
    setState(() => _isLoading = true);
    final weekStart = _anchorDay.subtract(
      Duration(days: _anchorDay.weekday - DateTime.monday),
    );
    final analyses = await _repository.getAnalysesInRange(
      fromInclusive: weekStart,
      toInclusive: weekStart.add(const Duration(days: 6)),
    );
    final aggregation = const SleepPeriodAggregationEngine().aggregateWeek(
      weekStart: weekStart,
      analyses: analyses,
    );
    if (!mounted) return;
    setState(() {
      _aggregation = aggregation;
      _isLoading = false;
    });
  }

  Future<void> _onScopeChanged(SleepPeriodScope scope) async {
    if (scope == SleepPeriodScope.day) {
      await SleepNavigation.openDayForDate(context, _anchorDay, replace: true);
      return;
    }
    if (scope == SleepPeriodScope.month) {
      await SleepNavigation.openMonthForDate(
        context,
        _anchorDay,
        replace: true,
      );
      return;
    }
  }

  void _shiftPeriod(int direction) {
    setState(() {
      _anchorDay = _anchorDay.add(Duration(days: 7 * direction));
    });
    _loadWeek();
  }
}

class WeekSummaryCard extends StatelessWidget {
  const WeekSummaryCard({super.key, required this.aggregation});

  final WeekSleepAggregation aggregation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String formatDuration(Duration? value) {
      if (value == null) return '--';
      final h = value.inHours;
      final m = value.inMinutes.remainder(60);
      return '${h}h ${m}m';
    }

    final mean = aggregation.meanScore == null
        ? '--'
        : aggregation.meanScore!.toStringAsFixed(0);
    return SummaryCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sleepWeekSummaryTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.sleepMeanScoreLabel(mean)),
            Text(
              l10n.sleepWeekdayAvgDurationLabel(
                formatDuration(aggregation.weekdayAverageDuration),
              ),
            ),
            Text(
              l10n.sleepWeekendAvgDurationLabel(
                formatDuration(aggregation.weekendAverageDuration),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeekWindowCard extends StatelessWidget {
  const WeekWindowCard({super.key, required this.aggregation});

  final WeekSleepAggregation aggregation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SleepWindowChartCard(
      title: l10n.sleepSleepWindowTitle,
      windows: aggregation.sleepWindows,
    );
  }
}

class WeekScoreStrip extends StatelessWidget {
  const WeekScoreStrip({
    super.key,
    required this.aggregation,
    required this.onTapDay,
  });

  final WeekSleepAggregation aggregation;
  final ValueChanged<DateTime> onTapDay;

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
            Text(
              l10n.sleepDailyScoreTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: aggregation.days.map((day) {
                final score = day.score;
                return Expanded(
                  child: InkWell(
                    onTap: () => onTapDay(day.date),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        children: [
                          Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: _chipColor(context, day.sleepQuality),
                              borderRadius: BorderRadius.circular(
                                DesignConstants.borderRadiusS,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              score == null ? '--' : score.round().toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${day.date.day}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Color _chipColor(BuildContext context, SleepQualityBucket quality) {
    final scheme = Theme.of(context).colorScheme;
    return switch (quality) {
      SleepQualityBucket.good => Colors.green.shade300,
      SleepQualityBucket.average => Colors.amber.shade300,
      SleepQualityBucket.poor => Colors.red.shade300,
      SleepQualityBucket.unavailable => scheme.surfaceContainerHighest,
    };
  }
}
