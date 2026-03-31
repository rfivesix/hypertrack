import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/summary_card.dart';
import '../../domain/aggregation/sleep_period_aggregations.dart';
import '../../data/repository/sleep_query_repository.dart';
import '../../domain/sleep_enums.dart';
import '../sleep_navigation.dart';
import '../details/sleep_data_unavailable_card.dart';
import '../widgets/sleep_period_scope_layout.dart';

class SleepWeekOverviewPage extends StatefulWidget {
  const SleepWeekOverviewPage({
    super.key,
    required this.anchorDay,
    this.repository,
  });

  final DateTime anchorDay;
  final SleepQueryRepository? repository;

  @override
  State<SleepWeekOverviewPage> createState() => _SleepWeekOverviewPageState();
}

class _SleepWeekOverviewPageState extends State<SleepWeekOverviewPage> {
  late DateTime _anchorDay;
  late final SleepQueryRepository _repository;
  late final bool _ownsRepository;
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
    _ownsRepository = widget.repository == null;
    _repository = widget.repository ?? DriftSleepQueryRepository();
    _loadWeek();
  }

  @override
  void dispose() {
    if (_ownsRepository && _repository is DriftSleepQueryRepository) {
      unawaited((_repository as DriftSleepQueryRepository).dispose());
    }
    super.dispose();
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
                _WeekSummaryCard(aggregation: _aggregation!),
                const SizedBox(height: 12),
                _WeekWindowCard(aggregation: _aggregation!),
                const SizedBox(height: 12),
                _WeekScoreStrip(
                  aggregation: _aggregation!,
                  onTapDay: (day) => SleepNavigation.openDayForDate(context, day),
                ),
                if (_aggregation!.days.every((day) => day.score == null))
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: SleepDataUnavailableCard(
                      message: l10n.sleepWeekNoScoredNights,
                    ),
                  ),
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
      await SleepNavigation.openDayForDate(context, _anchorDay);
      return;
    }
    if (scope == SleepPeriodScope.month) {
      await SleepNavigation.openMonthForDate(context, _anchorDay);
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

class _WeekSummaryCard extends StatelessWidget {
  const _WeekSummaryCard({required this.aggregation});

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

class _WeekWindowCard extends StatelessWidget {
  const _WeekWindowCard({required this.aggregation});

  final WeekSleepAggregation aggregation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sleepSleepWindowTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: aggregation.sleepWindows.map((window) {
                  final top = window.normalizedTop();
                  final height = window.normalizedHeight();
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final maxHeight = constraints.maxHeight;
                                final barTop = top * maxHeight;
                                final barHeight = height * maxHeight;
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                    if (window.hasData)
                                      Positioned(
                                        top: barTop,
                                        left: 0,
                                        right: 0,
                                        height: barHeight.clamp(4, maxHeight),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _weekdayShort(window.date.weekday),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayShort(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'M',
      DateTime.tuesday => 'T',
      DateTime.wednesday => 'W',
      DateTime.thursday => 'T',
      DateTime.friday => 'F',
      DateTime.saturday => 'S',
      DateTime.sunday => 'S',
      _ => '-',
    };
  }
}

class _WeekScoreStrip extends StatelessWidget {
  const _WeekScoreStrip({required this.aggregation, required this.onTapDay});

  final WeekSleepAggregation aggregation;
  final ValueChanged<DateTime> onTapDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SummaryCard(
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
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
