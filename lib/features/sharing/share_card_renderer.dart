import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/routine.dart';
import '../../models/workout_log.dart';
import 'routine_share_formatter.dart';
import 'share_labels.dart';
import 'share_set_type.dart';
import 'workout_share_formatter.dart';

enum WorkoutShareCardLayout { summary, exercises, muscleFocus, minimal }

enum RoutineShareCardLayout { summary, exercises }

class ShareCardRenderer {
  const ShareCardRenderer();

  static const int visibleExerciseLimit = 6;
  static const int visibleRoutineExerciseLimit = 10;
  static const Size cardSize = Size(1080, 1350);

  Future<File> renderWorkoutCard({
    required BuildContext context,
    required WorkoutLog workout,
    required ShareLabels labels,
    required String locale,
    required WorkoutShareCardLayout layout,
    List<MuscleVolumeSummary> muscleSummaries = const <MuscleVolumeSummary>[],
  }) {
    final formatter = WorkoutShareFormatter(labels, locale: locale);
    final stats = formatter.stats(workout);
    final child = switch (layout) {
      WorkoutShareCardLayout.summary => _WorkoutSummaryCard(
          stats: stats,
          labels: labels,
        ),
      WorkoutShareCardLayout.exercises => _WorkoutExerciseListCard(
          stats: stats,
          rows: formatter.imageExerciseSummaries(
            workout,
            visibleExerciseLimit: visibleExerciseLimit,
          ),
          remainingCount:
              formatter.remainingExerciseCount(workout, visibleExerciseLimit),
          labels: labels,
        ),
      WorkoutShareCardLayout.muscleFocus => _WorkoutMuscleFocusCard(
          stats: stats,
          muscles: muscleSummaries,
          labels: labels,
        ),
      WorkoutShareCardLayout.minimal => _WorkoutMinimalCard(
          stats: stats,
          labels: labels,
        ),
    };
    return _renderToTemporaryFile(
      context: context,
      filePrefix: 'train-libre-workout-${layout.name}',
      child: child,
    );
  }

  Future<File> renderRoutineCard({
    required BuildContext context,
    required Routine routine,
    required ShareLabels labels,
    required String locale,
    required RoutineShareCardLayout layout,
  }) {
    final formatter = RoutineShareFormatter(labels, locale: locale);
    final child = switch (layout) {
      RoutineShareCardLayout.summary => _RoutineSummaryCard(
          routine: routine,
          formatter: formatter,
          labels: labels,
        ),
      RoutineShareCardLayout.exercises => _RoutineExerciseListCard(
          routine: routine,
          formatter: formatter,
          labels: labels,
        ),
    };
    return _renderToTemporaryFile(
      context: context,
      filePrefix: 'train-libre-routine-${layout.name}',
      child: child,
    );
  }

  Future<File> _renderToTemporaryFile({
    required BuildContext context,
    required String filePrefix,
    required Widget child,
  }) async {
    final boundaryKey = GlobalKey();
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -cardSize.width,
        top: 0,
        width: cardSize.width,
        height: cardSize.height,
        child: RepaintBoundary(
          key: boundaryKey,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: cardSize,
              textScaler: TextScaler.noScaling,
            ),
            child: Theme(
              data: Theme.of(context),
              child: Directionality(
                textDirection: Directionality.of(context),
                child: SizedBox.fromSize(size: cardSize, child: child),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('Share card render boundary was not available.');
      }
      final image = await boundary.toImage(pixelRatio: 1);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Could not encode share card image.');
      }
      final directory = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final file = File(p.join(directory.path, '$filePrefix-$stamp.png'));
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      return file;
    } finally {
      entry.remove();
    }
  }
}

class _ShareScaffold extends StatelessWidget {
  const _ShareScaffold({required this.children, required this.labels});

  final List<Widget> children;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF111315) : Colors.white;
    final foreground = isDark ? Colors.white : const Color(0xFF161A1D);

    return DefaultTextStyle(
      style: TextStyle(
        color: foreground,
        decoration: TextDecoration.none,
        fontFamily: theme.textTheme.bodyMedium?.fontFamily,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: background),
        child: Padding(
          padding: const EdgeInsets.all(72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
              _TrainLibreFooter(labels: labels),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutSummaryCard extends StatelessWidget {
  const _WorkoutSummaryCard({required this.stats, required this.labels});

  final WorkoutShareStats stats;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    return _ShareScaffold(
      labels: labels,
      children: [
        _Kicker(labels.shareImageSummary),
        const SizedBox(height: 30),
        _Title(stats.title),
        const SizedBox(height: 22),
        _Subtitle(stats.date),
        const SizedBox(height: 68),
        _MetricGrid(
          metrics: [
            _Metric(labels.duration, stats.duration ?? '-'),
            _Metric(labels.volume, stats.volume ?? '-'),
            _Metric(labels.exercises, '${stats.exerciseCount}'),
            _Metric(labels.sets, '${stats.setCount}'),
          ],
        ),
      ],
    );
  }
}

class _WorkoutExerciseListCard extends StatelessWidget {
  const _WorkoutExerciseListCard({
    required this.stats,
    required this.rows,
    required this.remainingCount,
    required this.labels,
  });

  final WorkoutShareStats stats;
  final List<WorkoutShareExerciseSummary> rows;
  final int remainingCount;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    return _ShareScaffold(
      labels: labels,
      children: [
        _Kicker(labels.shareImageExercises),
        const SizedBox(height: 26),
        _Title(stats.title, maxLines: 2),
        const SizedBox(height: 22),
        _Subtitle(
          [
            if (stats.duration != null) stats.duration,
            if (stats.volume != null) stats.volume,
            '${stats.setCount} ${labels.sets}',
          ].join(' · '),
        ),
        const SizedBox(height: 50),
        for (final row in rows)
          _ExercisePill(count: row.detail, name: row.name),
        if (remainingCount > 0) _MoreLine(labels.moreExercises(remainingCount)),
      ],
    );
  }
}

class _WorkoutMuscleFocusCard extends StatelessWidget {
  const _WorkoutMuscleFocusCard({
    required this.stats,
    required this.muscles,
    required this.labels,
  });

  final WorkoutShareStats stats;
  final List<MuscleVolumeSummary> muscles;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    final maxVolume =
        muscles.isEmpty ? 0.0 : muscles.map((m) => m.volume).reduce(math.max);
    final showRadar = muscles.length >= 3 && maxVolume > 0;
    final visibleMuscles = muscles.take(showRadar ? 3 : 4);
    return _ShareScaffold(
      labels: labels,
      children: [
        _Kicker(labels.shareImageMuscleFocus),
        const SizedBox(height: 26),
        _Title(stats.title, maxLines: 2),
        const SizedBox(height: 22),
        _Subtitle(
          [
            if (stats.duration != null) stats.duration,
            if (stats.volume != null) stats.volume,
            '${stats.setCount} ${labels.sets}',
          ].join(' · '),
        ),
        const SizedBox(height: 34),
        if (showRadar)
          Center(
            child: SizedBox(
              width: 430,
              height: 330,
              child: CustomPaint(
                painter: _ShareRadarPainter(
                  muscles: muscles.take(6).toList(growable: false),
                  maxValue: maxVolume,
                  lineColor: Theme.of(context).colorScheme.primary,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  gridColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.18),
                  textColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72),
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        for (final muscle in visibleMuscles)
          _MuscleVolumePill(muscle: muscle, maxVolume: maxVolume),
      ],
    );
  }
}

class _WorkoutMinimalCard extends StatelessWidget {
  const _WorkoutMinimalCard({required this.stats, required this.labels});

  final WorkoutShareStats stats;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    return _ShareScaffold(
      labels: labels,
      children: [
        _Kicker(labels.shareImageMinimal),
        const Spacer(),
        _Title(stats.title, maxLines: 3),
        const SizedBox(height: 46),
        _HugeMetric(stats.volume ?? stats.duration ?? '${stats.setCount}'),
        const SizedBox(height: 18),
        _Subtitle(
          [
            if (stats.duration != null) stats.duration,
            '${stats.setCount} ${labels.sets}',
          ].join(' · '),
        ),
        const Spacer(),
      ],
    );
  }
}

class _RoutineSummaryCard extends StatelessWidget {
  const _RoutineSummaryCard({
    required this.routine,
    required this.formatter,
    required this.labels,
  });

  final Routine routine;
  final RoutineShareFormatter formatter;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    final typeCounts = formatter.setTypeCounts(routine);
    return _ShareScaffold(
      labels: labels,
      children: [
        _Kicker(labels.shareImageSummary),
        const SizedBox(height: 30),
        _Title(routine.name),
        const SizedBox(height: 68),
        _MetricGrid(
          metrics: [
            _Metric(labels.exercises, '${routine.exercises.length}'),
            _Metric(labels.sets, '${formatter.plannedSetCount(routine)}'),
            _Metric(
              labels.warmupSuffix,
              '${typeCounts[ShareSetType.warmup] ?? 0}',
            ),
            _Metric(labels.failureSuffix,
                '${typeCounts[ShareSetType.failure] ?? 0}'),
          ],
        ),
      ],
    );
  }
}

class _RoutineExerciseListCard extends StatelessWidget {
  const _RoutineExerciseListCard({
    required this.routine,
    required this.formatter,
    required this.labels,
  });

  final Routine routine;
  final RoutineShareFormatter formatter;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    final rows = formatter.imageExerciseSummaries(
      routine,
      visibleExerciseLimit: ShareCardRenderer.visibleRoutineExerciseLimit,
    );
    final remaining = formatter.remainingExerciseCount(
      routine,
      ShareCardRenderer.visibleRoutineExerciseLimit,
    );
    return _ShareScaffold(
      labels: labels,
      children: [
        _Kicker(labels.shareImageExercises),
        const SizedBox(height: 26),
        _Title(routine.name, maxLines: 2),
        const SizedBox(height: 42),
        _RoutineExerciseGrid(
          rows: rows,
          remainingCount: remaining,
          labels: labels,
        ),
      ],
    );
  }
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 34,
        fontWeight: FontWeight.w900,
        decoration: TextDecoration.none,
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, {this.maxLines = 2});

  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 78,
        height: 1.02,
        fontWeight: FontWeight.w900,
        decoration: TextDecoration.none,
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.64),
        fontSize: 34,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.none,
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: metrics
          .map(
            (metric) => SizedBox(
              width: 444,
              height: 210,
              child: _MetricTile(metric: metric),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2124) : const Color(0xFFF0F3F0),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.58),
                fontSize: 28,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
            Text(
              metric.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisePill extends StatelessWidget {
  const _ExercisePill({required this.count, required this.name});

  final String count;
  final String name;

  @override
  Widget build(BuildContext context) {
    return _ListPill(
      child: Row(
        children: [
          Text(
            count,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineExerciseGrid extends StatelessWidget {
  const _RoutineExerciseGrid({
    required this.rows,
    required this.remainingCount,
    required this.labels,
  });

  final List<RoutineShareExerciseSummary> rows;
  final int remainingCount;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 18,
      children: [
        for (final row in rows)
          SizedBox(
            width: 454,
            height: 126,
            child: _RoutinePill(name: row.name, detail: row.detail),
          ),
        if (remainingCount > 0)
          SizedBox(
            width: 454,
            height: 126,
            child: _MoreRoutinePill(text: labels.moreExercises(remainingCount)),
          ),
      ],
    );
  }
}

class _RoutinePill extends StatelessWidget {
  const _RoutinePill({required this.name, required this.detail});

  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2124) : const Color(0xFFF0F3F0),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 31,
                height: 1.02,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.62),
                fontSize: 25,
                height: 1.05,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreRoutinePill extends StatelessWidget {
  const _MoreRoutinePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2124) : const Color(0xFFF0F3F0),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Center(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _MuscleVolumePill extends StatelessWidget {
  const _MuscleVolumePill({required this.muscle, required this.maxVolume});

  final MuscleVolumeSummary muscle;
  final double maxVolume;

  @override
  Widget build(BuildContext context) {
    final ratio = maxVolume <= 0 ? 0.0 : (muscle.volume / maxVolume);
    return _ListPill(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  muscle.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                muscle.formattedVolume,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListPill extends StatelessWidget {
  const _ListPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D2124) : const Color(0xFFF0F3F0),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
          child: child,
        ),
      ),
    );
  }
}

class _HugeMetric extends StatelessWidget {
  const _HugeMetric(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 96,
        fontWeight: FontWeight.w900,
        decoration: TextDecoration.none,
      ),
    );
  }
}

class _MoreLine extends StatelessWidget {
  const _MoreLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _ShareRadarPainter extends CustomPainter {
  const _ShareRadarPainter({
    required this.muscles,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.textColor,
  });

  final List<MuscleVolumeSummary> muscles;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (muscles.length < 3 || maxValue <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.34;
    final angleStep = (math.pi * 2) / muscles.length;
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var ring = 1; ring <= 4; ring += 1) {
      final path = Path();
      final ringRadius = radius * ring / 4;
      for (var i = 0; i < muscles.length; i += 1) {
        final point = _point(center, ringRadius, i, angleStep);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (var i = 0; i < muscles.length; i += 1) {
      canvas.drawLine(center, _point(center, radius, i, angleStep), gridPaint);
    }

    final valuePath = Path();
    for (var i = 0; i < muscles.length; i += 1) {
      final ratio = (muscles[i].volume / maxValue).clamp(0.0, 1.0);
      final point = _point(center, radius * ratio, i, angleStep);
      if (i == 0) {
        valuePath.moveTo(point.dx, point.dy);
      } else {
        valuePath.lineTo(point.dx, point.dy);
      }
    }
    valuePath.close();

    canvas.drawPath(
      valuePath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      valuePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < muscles.length; i += 1) {
      final labelPoint = _point(center, radius + 46, i, angleStep);
      final textPainter = TextPainter(
        text: TextSpan(
          text: muscles[i].name,
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.none,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: 125);
      textPainter.paint(
        canvas,
        Offset(
          labelPoint.dx - textPainter.width / 2,
          labelPoint.dy - textPainter.height / 2,
        ),
      );
    }
  }

  Offset _point(Offset center, double radius, int index, double angleStep) {
    final angle = -math.pi / 2 + index * angleStep;
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }

  @override
  bool shouldRepaint(covariant _ShareRadarPainter oldDelegate) {
    return oldDelegate.muscles != muscles ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}

class _TrainLibreFooter extends StatelessWidget {
  const _TrainLibreFooter({required this.labels});

  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Row(
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: SvgPicture.asset(
            'assets/icon/train-libre_icon_dark_green_no_bg.svg',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          labels.appName,
          style: TextStyle(
            color: muted,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            decoration: TextDecoration.none,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            labels.githubUrl.replaceFirst('https://', ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: muted,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value);

  final String label;
  final String value;
}
