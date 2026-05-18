import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/workout_database_helper.dart';
import '../../generated/app_localizations.dart';
import '../../models/exercise.dart';
import '../../models/routine.dart';
import '../../models/workout_log.dart';
import '../app/presentation/widgets/glass_bottom_menu.dart';
import 'routine_share_formatter.dart';
import 'share_card_renderer.dart';
import 'share_labels.dart';
import 'workout_share_formatter.dart';

class ShareService {
  const ShareService({ShareCardRenderer renderer = const ShareCardRenderer()})
      : _renderer = renderer;

  final ShareCardRenderer _renderer;

  Future<void> showWorkoutShareSheet({
    required BuildContext context,
    required WorkoutLog workout,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showGlassBottomMenu<void>(
      context: context,
      title: l10n.shareWorkout,
      actions: [
        GlassMenuAction(
          icon: Icons.image_outlined,
          label: l10n.shareAsImage,
          onTap: () => _showWorkoutImageLayoutSheet(
            context: context,
            workout: workout,
          ),
        ),
        GlassMenuAction(
          icon: Icons.notes_outlined,
          label: l10n.shareAsText,
          onTap: () => shareWorkoutAsText(context: context, workout: workout),
        ),
      ],
    );
  }

  Future<void> showRoutineShareSheet({
    required BuildContext context,
    required Routine routine,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showGlassBottomMenu<void>(
      context: context,
      title: l10n.shareRoutine,
      actions: [
        GlassMenuAction(
          icon: Icons.image_outlined,
          label: l10n.shareAsImage,
          onTap: () => _showRoutineImageLayoutSheet(
            context: context,
            routine: routine,
          ),
        ),
        GlassMenuAction(
          icon: Icons.notes_outlined,
          label: l10n.shareAsText,
          onTap: () => shareRoutineAsText(context: context, routine: routine),
        ),
      ],
    );
  }

  Future<void> _showWorkoutImageLayoutSheet({
    required BuildContext context,
    required WorkoutLog workout,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showGlassBottomMenu<void>(
      context: context,
      title: l10n.shareAsImage,
      actions: [
        GlassMenuAction(
          icon: Icons.dashboard_outlined,
          label: l10n.shareImageSummary,
          onTap: () => shareWorkoutAsImage(
            context: context,
            workout: workout,
            layout: WorkoutShareCardLayout.summary,
          ),
        ),
        GlassMenuAction(
          icon: Icons.format_list_bulleted,
          label: l10n.shareImageExercises,
          onTap: () => shareWorkoutAsImage(
            context: context,
            workout: workout,
            layout: WorkoutShareCardLayout.exercises,
          ),
        ),
        GlassMenuAction(
          icon: Icons.pie_chart_outline,
          label: l10n.shareImageMuscleFocus,
          onTap: () => shareWorkoutAsImage(
            context: context,
            workout: workout,
            layout: WorkoutShareCardLayout.muscleFocus,
          ),
        ),
        GlassMenuAction(
          icon: Icons.crop_square,
          label: l10n.shareImageMinimal,
          onTap: () => shareWorkoutAsImage(
            context: context,
            workout: workout,
            layout: WorkoutShareCardLayout.minimal,
          ),
        ),
      ],
    );
  }

  Future<void> _showRoutineImageLayoutSheet({
    required BuildContext context,
    required Routine routine,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showGlassBottomMenu<void>(
      context: context,
      title: l10n.shareAsImage,
      actions: [
        GlassMenuAction(
          icon: Icons.dashboard_outlined,
          label: l10n.shareImageSummary,
          onTap: () => shareRoutineAsImage(
            context: context,
            routine: routine,
            layout: RoutineShareCardLayout.summary,
          ),
        ),
        GlassMenuAction(
          icon: Icons.format_list_bulleted,
          label: l10n.shareImageExercises,
          onTap: () => shareRoutineAsImage(
            context: context,
            routine: routine,
            layout: RoutineShareCardLayout.exercises,
          ),
        ),
      ],
    );
  }

  Future<void> shareWorkoutAsText({
    required BuildContext context,
    required WorkoutLog workout,
  }) async {
    final labels = ShareLabels.fromL10n(AppLocalizations.of(context)!);
    final locale = Localizations.localeOf(context).toString();
    final text = WorkoutShareFormatter(labels, locale: locale).format(workout);
    await _shareText(text, subject: workout.routineName ?? labels.appName);
  }

  Future<void> shareRoutineAsText({
    required BuildContext context,
    required Routine routine,
  }) async {
    final labels = ShareLabels.fromL10n(AppLocalizations.of(context)!);
    final locale = Localizations.localeOf(context).toString();
    final text = RoutineShareFormatter(labels, locale: locale).format(routine);
    await _shareText(text, subject: routine.name);
  }

  Future<void> shareWorkoutAsImage({
    required BuildContext context,
    required WorkoutLog workout,
    WorkoutShareCardLayout layout = WorkoutShareCardLayout.summary,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final labels = ShareLabels.fromL10n(l10n);
    final locale = Localizations.localeOf(context).toString();
    try {
      final muscleSummaries = layout == WorkoutShareCardLayout.muscleFocus
          ? await _loadMuscleSummaries(
              workout: workout,
              labels: labels,
              locale: locale,
            )
          : const <MuscleVolumeSummary>[];
      if (!context.mounted) return;
      final file = await _renderer.renderWorkoutCard(
        context: context,
        workout: workout,
        labels: labels,
        locale: locale,
        layout: layout,
        muscleSummaries: muscleSummaries,
      );
      await _shareImage(file, subject: workout.routineName ?? labels.appName);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
      }
      if (context.mounted) {
        await shareWorkoutAsText(context: context, workout: workout);
      }
    }
  }

  Future<void> shareRoutineAsImage({
    required BuildContext context,
    required Routine routine,
    RoutineShareCardLayout layout = RoutineShareCardLayout.summary,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final labels = ShareLabels.fromL10n(l10n);
    final locale = Localizations.localeOf(context).toString();
    try {
      final file = await _renderer.renderRoutineCard(
        context: context,
        routine: routine,
        labels: labels,
        locale: locale,
        layout: layout,
      );
      await _shareImage(file, subject: routine.name);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
      }
      if (context.mounted) {
        await shareRoutineAsText(context: context, routine: routine);
      }
    }
  }

  Future<void> _shareText(String text, {String? subject}) {
    return SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
  }

  Future<void> _shareImage(File file, {String? subject}) {
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        subject: subject,
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
  }

  Future<List<MuscleVolumeSummary>> _loadMuscleSummaries({
    required WorkoutLog workout,
    required ShareLabels labels,
    required String locale,
  }) async {
    final details = <String, Exercise>{};
    for (final set in workout.sets) {
      if (details.containsKey(set.exerciseName)) continue;
      final exercise =
          await WorkoutDatabaseHelper.instance.resolveExerciseForSetLog(set);
      if (exercise != null) {
        details[set.exerciseName] = exercise;
      }
    }
    return WorkoutShareFormatter(
      labels,
      locale: locale,
    ).muscleVolumeSummaries(workout, details);
  }

  ui.Rect _sharePositionOrigin() {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) return const ui.Rect.fromLTWH(0, 0, 1, 1);
    final view = views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    return ui.Rect.fromLTWH(
      0,
      0,
      math.max(1, logicalSize.width),
      math.max(1, logicalSize.height),
    );
  }
}
