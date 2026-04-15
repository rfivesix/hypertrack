import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../widgets/summary_card.dart';
import '../../domain/aggregation/sleep_period_aggregations.dart';

typedef SleepWindowDayLabelBuilder = String Function(
    BuildContext context, DateTime date);

class SleepWindowChartCard extends StatelessWidget {
  const SleepWindowChartCard({
    super.key,
    required this.title,
    required this.windows,
    this.chartHeight = 140,
    this.dayLabelBuilder = _weekdayShortLabel,
  });

  final String title;
  final List<SleepWindowSegment> windows;
  final double chartHeight;
  final SleepWindowDayLabelBuilder dayLabelBuilder;

  static const int _fallbackMinMinutes = 20 * 60;
  static const int _fallbackMaxMinutes = 36 * 60;
  static const double _labelSpacing = 4;
  static const double _labelRowHeight = 16;

  @override
  Widget build(BuildContext context) {
    final bounds = _resolveBounds(windows);
    return SummaryCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: chartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 44,
                    child: Column(
                      children: [
                        Expanded(
                          child: _TimeAxisLabels(
                            tickMinutes: bounds.tickMinutes,
                            minMinutes: bounds.minMinutes,
                            maxMinutes: bounds.maxMinutes,
                          ),
                        ),
                        const SizedBox(height: _labelSpacing),
                        const SizedBox(height: _labelRowHeight),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _SleepWindowChart(
                      windows: windows,
                      minMinutes: bounds.minMinutes,
                      maxMinutes: bounds.maxMinutes,
                      tickMinutes: bounds.tickMinutes,
                      labelRowHeight: _labelRowHeight,
                      labelSpacing: _labelSpacing,
                      dayLabelBuilder: dayLabelBuilder,
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

  _SleepWindowBounds _resolveBounds(List<SleepWindowSegment> windows) {
    final dataWindows = windows.where((window) => window.hasData).toList();
    if (dataWindows.isEmpty) {
      return _SleepWindowBounds(
        minMinutes: _fallbackMinMinutes,
        maxMinutes: _fallbackMaxMinutes,
        tickMinutes: _buildTickMinutes(
          minMinutes: _fallbackMinMinutes,
          maxMinutes: _fallbackMaxMinutes,
        ),
      );
    }

    final earliestStart = dataWindows
        .map((window) => window.displayStartMinutes)
        .reduce(math.min);
    final latestEnd =
        dataWindows.map((window) => window.displayEndMinutes).reduce(math.max);

    final flooredHour = (earliestStart ~/ 60) * 60;
    final minMinutes = earliestStart % 60 == 0 ? flooredHour - 60 : flooredHour;

    final ceilBase = ((latestEnd + 59) ~/ 60) * 60;
    final maxMinutes = latestEnd % 60 == 0 ? ceilBase + 60 : ceilBase;

    return _SleepWindowBounds(
      minMinutes: minMinutes,
      maxMinutes: maxMinutes,
      tickMinutes: _buildTickMinutes(
        minMinutes: minMinutes,
        maxMinutes: maxMinutes,
      ),
    );
  }

  List<int> _buildTickMinutes(
      {required int minMinutes, required int maxMinutes}) {
    final spanMinutes = math.max(60, maxMinutes - minMinutes);
    final spanHours = (spanMinutes / 60).ceil();
    final stepHours = switch (spanHours) {
      <= 8 => 1,
      <= 12 => 2,
      <= 18 => 3,
      <= 24 => 4,
      _ => 6,
    };
    final step = stepHours * 60;
    final ticks = <int>[];
    for (var minute = minMinutes; minute <= maxMinutes; minute += step) {
      ticks.add(minute);
    }
    if (ticks.isEmpty || ticks.last != maxMinutes) {
      ticks.add(maxMinutes);
    }
    return ticks;
  }
}

class _SleepWindowBounds {
  const _SleepWindowBounds({
    required this.minMinutes,
    required this.maxMinutes,
    required this.tickMinutes,
  });

  final int minMinutes;
  final int maxMinutes;
  final List<int> tickMinutes;
}

class _SleepWindowChart extends StatelessWidget {
  const _SleepWindowChart({
    required this.windows,
    required this.minMinutes,
    required this.maxMinutes,
    required this.tickMinutes,
    required this.labelRowHeight,
    required this.labelSpacing,
    required this.dayLabelBuilder,
  });

  final List<SleepWindowSegment> windows;
  final int minMinutes;
  final int maxMinutes;
  final List<int> tickMinutes;
  final double labelRowHeight;
  final double labelSpacing;
  final SleepWindowDayLabelBuilder dayLabelBuilder;

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
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.6),
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
                      dayLabelBuilder(context, window.date),
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
    const labelHeight = 14.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final range = math.max(1, maxMinutes - minMinutes).toDouble();
        return Stack(
          children: [
            for (final minute in tickMinutes)
              Positioned(
                top: _positionForMinute(
                  minute.toDouble(),
                  height,
                  range,
                  labelHeight,
                ),
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

  double _positionForMinute(
    double minute,
    double height,
    double range,
    double labelHeight,
  ) {
    final normalized = ((minute - minMinutes) / range).clamp(0.0, 1.0);
    final centered = (normalized * height) - (labelHeight / 2);
    return centered.clamp(0.0, math.max(0.0, height - labelHeight));
  }

  String _formatTickLabel(int minute) {
    var hours = (minute ~/ 60) % 24;
    if (hours < 0) hours += 24;
    return '$hours:00';
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

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    var progress = 0.0;
    while (progress < distance) {
      final current = progress / distance;
      final next = (progress + dashWidth) / distance;
      final from = Offset(start.dx + dx * current, start.dy + dy * current);
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

String _weekdayShortLabel(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  final symbol = DateFormat.E(locale).format(date);
  return symbol.isEmpty ? '-' : symbol.substring(0, 1).toUpperCase();
}
