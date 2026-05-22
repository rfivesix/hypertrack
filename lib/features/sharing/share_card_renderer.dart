import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../workout/domain/models/routine.dart';
import '../workout/domain/models/workout_log.dart';
import 'routine_share_formatter.dart';
import 'share_labels.dart';
import 'share_set_type.dart';
import 'workout_share_formatter.dart';

part 'painters/share_radar_painter.dart';
part 'widgets/routine_share_cards.dart';
part 'widgets/share_card_elements.dart';
part 'widgets/workout_share_cards.dart';

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
