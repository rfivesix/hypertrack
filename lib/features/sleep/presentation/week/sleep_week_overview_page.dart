import 'dart:math' as math;

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
                const SizedBox(height: 12),
                WeekWindowCard(aggregation: _aggregation!),
                const SizedBox(height: 12),
                WeekScoreStrip(
                  aggregation: _aggregation!,
                  onTapDay: (day) =>
                      SleepNavigation.openDayForDate(context, day),
                ),
                if (_aggregation!.days.every((day) => day.score == null))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
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
      await SleepNavigation.openDayForDate(
        context,
        _anchorDay,
        replace: true,
      );
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
  const WeekSummaryCard({required this.aggregation});

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

class WeekWindowCard extends StatelessWidget {
  const WeekWindowCard({required this.aggregation});

  final WeekSleepAggregation aggregation;
  static const int _minMinutes = 20 * 60;
  static const int _maxMinutes = 36 * 60;
  static const List<int> _tickMinutes = <int>[
    21 * 60,
    24 * 60,
    27 * 60,
    30 * 60,
    33 * 60,
    36 * 60,
  ];
  static const double _labelSpacing = 4;
  static const double _labelRowHeight = 16;

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
                children: [
                  SizedBox(
                    width: 44,
                    child: Column(
                      children: [
                        Expanded(
                          child: _TimeAxisLabels(
                            tickMinutes: _tickMinutes,
                            minMinutes: _minMinutes,
                            maxMinutes: _maxMinutes,
                          ),
                        ),
                        const SizedBox(height: _labelSpacing),
                        const SizedBox(height: _labelRowHeight),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _WeekWindowChart(
                      windows: aggregation.sleepWindows,
                      minMinutes: _minMinutes,
                      maxMinutes: _maxMinutes,
                      tickMinutes: _tickMinutes,
                      labelRowHeight: _labelRowHeight,
                      labelSpacing: _labelSpacing,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekWindowChart extends StatelessWidget {
  const _WeekWindowChart({
    required this.windows,
    required this.minMinutes,
    required this.maxMinutes,
    required this.tickMinutes,
    required this.labelRowHeight,
    required this.labelSpacing,
  });

  final List<SleepWindowSegment> windows;
  final int minMinutes;
  final int maxMinutes;
  final List<int> tickMinutes;
  final double labelRowHeight;
  final double labelSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: windows.map((window) {
                        final top = window.normalizedTop(
                          minMinutes: minMinutes,
                          maxMinutes: maxMinutes,
                        );
                        final height = window.normalizedHeight(
                          minMinutes: minMinutes,
                          maxMinutes: maxMinutes,
                        );
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
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
                                          borderRadius:
                                              BorderRadius.circular(6),
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
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
                        );
                      }).toList(growable: false),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _TimeGridPainter(
                          tickMinutes: tickMinutes,
                          minMinutes: minMinutes,
                          maxMinutes: maxMinutes,
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: labelSpacing),
        SizedBox(
          height: labelRowHeight,
          child: Row(
            children: windows
                .map(
                  (window) => Expanded(
                    child: Text(
                      _weekdayShort(window.date.weekday),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
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

class _TimeAxisLabels extends StatelessWidget {
  const _TimeAxisLabels({
    required this.tickMinutes,
    required this.minMinutes,
    required this.maxMinutes,
  });

  final List<int> tickMinutes;
  final int minMinutes;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final range = (maxMinutes - minMinutes).clamp(1, maxMinutes).toDouble();
        return Stack(
          children: [
            for (final minute in tickMinutes)
              Positioned(
                top: _positionForMinute(minute.toDouble(), height, range),
                right: 6,
                child: Text(
                  _formatTickLabel(minute),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _positionForMinute(double minute, double height, double range) {
    final normalized = ((minute - minMinutes) / range).clamp(0.0, 1.0);
    return (normalized * height) - 6;
  }

  String _formatTickLabel(int minute) {
    var hours = (minute ~/ 60) % 24;
    if (hours < 0) hours += 24;
    return '${hours}:00';
  }
}

class _TimeGridPainter extends CustomPainter {
  _TimeGridPainter({
    required this.tickMinutes,
    required this.minMinutes,
    required this.maxMinutes,
    required this.color,
  });

  final List<int> tickMinutes;
  final int minMinutes;
  final int maxMinutes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final range = math.max(1, maxMinutes - minMinutes).toDouble();
    for (final minute in tickMinutes) {
      final normalized = ((minute - minMinutes) / range).clamp(0.0, 1.0);
      final y = normalized * size.height;
      _drawDashedLine(canvas, paint, Offset(0, y), Offset(size.width, y));
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Paint paint,
    Offset start,
    Offset end,
  ) {
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    var progress = 0.0;
    while (progress < distance) {
      final current = progress / distance;
      final next = (progress + dashWidth) / distance;
      final from = Offset(
        start.dx + dx * current,
        start.dy + dy * current,
      );
      final to = Offset(
        start.dx + dx * next.clamp(0.0, 1.0),
        start.dy + dy * next.clamp(0.0, 1.0),
      );
      canvas.drawLine(from, to, paint);
      progress += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TimeGridPainter oldDelegate) {
    return oldDelegate.tickMinutes != tickMinutes ||
        oldDelegate.minMinutes != minMinutes ||
        oldDelegate.maxMinutes != maxMinutes ||
        oldDelegate.color != color;
  }
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

class WeekScoreStrip extends StatelessWidget {
  const WeekScoreStrip({required this.aggregation, required this.onTapDay});

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
