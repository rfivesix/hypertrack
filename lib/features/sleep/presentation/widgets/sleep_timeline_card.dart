import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../domain/sleep_domain.dart';
import '../../data/sleep_day_repository.dart';

class SleepTimelineCard extends StatelessWidget {
  const SleepTimelineCard({super.key, required this.overview});

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
            _SleepTimelinePlot(
              segments: chartSegments,
              startAtUtc: chartStart,
              endAtUtc: chartEnd,
              colors: colors,
              gridColor: Theme.of(context).colorScheme.outlineVariant,
              use24HourFormat: use24h,
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepTimelinePlot extends StatelessWidget {
  const _SleepTimelinePlot({
    required this.segments,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.colors,
    required this.gridColor,
    required this.use24HourFormat,
  });

  final List<_ChartStageSegment> segments;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final Map<_SleepChartStage, Color> colors;
  final Color gridColor;
  final bool use24HourFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final axisTextStyle =
        (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final ticks = _buildTimelineTicks(
          startAtUtc: startAtUtc,
          endAtUtc: endAtUtc,
          use24HourFormat: use24HourFormat,
          availableWidth: constraints.maxWidth,
          textStyle: axisTextStyle,
        );
        return Column(
          children: [
            SizedBox(
              height: 108,
              width: double.infinity,
              child: CustomPaint(
                painter: _SleepStagesPainter(
                  segments: segments,
                  startAtUtc: startAtUtc,
                  endAtUtc: endAtUtc,
                  colors: colors,
                  gridColor: gridColor,
                  timestampTicksUtc: ticks
                      .map((tick) => tick.timestampUtc)
                      .toList(growable: false),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              key: const Key('sleep-timeline-axis'),
              height: 20,
              width: double.infinity,
              child: Stack(
                children: [
                  for (var i = 0; i < ticks.length; i++)
                    Positioned(
                      left: ticks[i].left,
                      child: Text(
                        ticks[i].label,
                        key: Key('sleep-timeline-tick-$i'),
                        style: axisTextStyle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

List<_TimelineAxisTick> _buildTimelineTicks({
  required DateTime startAtUtc,
  required DateTime endAtUtc,
  required bool use24HourFormat,
  required double availableWidth,
  required TextStyle textStyle,
}) {
  final totalMinutes = endAtUtc.difference(startAtUtc).inMinutes;
  if (totalMinutes <= 0 || availableWidth <= 0) {
    return [];
  }
  final intervalMinutes = _selectTickIntervalMinutes(
    totalMinutes: totalMinutes,
    availableWidth: availableWidth,
  );
  final formatter = use24HourFormat ? DateFormat.Hm() : DateFormat.jm();

  final startLocal = startAtUtc.toLocal();
  final endLocal = endAtUtc.toLocal();
  final rawTicksLocal = <DateTime>{startLocal, endLocal};
  final startMinutes = startLocal.hour * 60 + startLocal.minute;
  final firstBoundaryMinute =
      ((startMinutes + intervalMinutes - 1) ~/ intervalMinutes) *
          intervalMinutes;
  var current = DateTime(
    startLocal.year,
    startLocal.month,
    startLocal.day,
    0,
    firstBoundaryMinute,
  );
  if (current.isBefore(startLocal)) {
    current = current.add(Duration(minutes: intervalMinutes));
  }
  while (current.isBefore(endLocal)) {
    rawTicksLocal.add(current);
    current = current.add(Duration(minutes: intervalMinutes));
  }

  final sortedTicksUtc = rawTicksLocal
      .map((tick) => tick.toUtc())
      .toList(growable: false)
    ..sort((a, b) => a.compareTo(b));

  if (sortedTicksUtc.isEmpty) return [];

  final effectiveWidth = availableWidth - 4;
  final candidates = <_TimelineAxisTick>[];
  for (final tickUtc in sortedTicksUtc) {
    final ratio = tickUtc.difference(startAtUtc).inMinutes / totalMinutes;
    final anchorX = ratio * effectiveWidth + 2;
    final label = formatter.format(tickUtc.toLocal());
    final painter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelWidth = painter.width;
    final left = (anchorX - (labelWidth / 2)).clamp(
      0.0,
      availableWidth - labelWidth,
    );
    candidates.add(
      _TimelineAxisTick(
        timestampUtc: tickUtc,
        label: label,
        left: left,
      ),
    );
  }

  if (candidates.length <= 2) return candidates;

  const minimumDistance = 56.0;
  final selected = <_TimelineAxisTick>[candidates.first];
  for (var i = 1; i < candidates.length - 1; i++) {
    final tick = candidates[i];
    final spacingFromPrevious = tick.left - selected.last.left;
    if (spacingFromPrevious >= minimumDistance) {
      selected.add(tick);
    }
  }
  final endTick = candidates.last;
  while (selected.length > 1 &&
      (endTick.left - selected.last.left) < minimumDistance) {
    selected.removeLast();
  }
  if ((endTick.left - selected.last.left) >= minimumDistance) {
    selected.add(endTick);
  }
  return selected;
}

int _selectTickIntervalMinutes({
  required int totalMinutes,
  required double availableWidth,
}) {
  final maxLabels = (availableWidth / 82).floor().clamp(4, 10);
  const candidates = [30, 45, 60, 90, 120, 180, 240, 360];
  for (final interval in candidates) {
    final interior = (totalMinutes / interval).floor();
    final estimatedLabels = interior + 2;
    if (estimatedLabels <= maxLabels) return interval;
  }
  return candidates.last;
}

class _TimelineAxisTick {
  const _TimelineAxisTick({
    required this.timestampUtc,
    required this.label,
    required this.left,
  });

  final DateTime timestampUtc;
  final String label;
  final double left;
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
    required this.timestampTicksUtc,
  });

  final List<_ChartStageSegment> segments;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final Map<_SleepChartStage, Color> colors;
  final Color gridColor;
  final List<DateTime> timestampTicksUtc;

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

    final timestampGridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.42)
      ..strokeWidth = 1;
    for (final tick in timestampTicksUtc) {
      final x = xFor(tick);
      _drawDottedVerticalLine(
        canvas,
        x: x,
        top: chartTop,
        bottom: chartBottom,
        paint: timestampGridPaint,
      );
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
        oldDelegate.gridColor != gridColor ||
        oldDelegate.timestampTicksUtc != timestampTicksUtc;
  }

  void _drawDottedVerticalLine(
    Canvas canvas, {
    required double x,
    required double top,
    required double bottom,
    required Paint paint,
  }) {
    const dashLength = 3.0;
    const gapLength = 4.0;
    var y = top;
    while (y < bottom) {
      final y2 = (y + dashLength).clamp(top, bottom);
      canvas.drawLine(Offset(x, y), Offset(x, y2), paint);
      y += dashLength + gapLength;
    }
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
      const Color(0xFFB8C7E0),
    ),
    (_SleepChartStage.rem, l10n.sleepStageRemLabel, const Color(0xFF85A8FF)),
    (
      _SleepChartStage.light,
      l10n.sleepStageLightLabel,
      const Color(0xFF3F6FD8),
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
