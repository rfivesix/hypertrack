import '../../models/routine.dart';
import '../../models/routine_exercise.dart';
import '../../models/set_template.dart';
import 'share_labels.dart';
import 'share_set_type.dart';

class RoutineShareFormatter {
  const RoutineShareFormatter(this.labels, {this.locale});

  final ShareLabels labels;
  final String? locale;

  String format(Routine routine) {
    final buffer = StringBuffer()
      ..writeln('${labels.appName} · ${routine.name}')
      ..writeln();

    if (routine.exercises.isEmpty) {
      buffer.writeln(labels.exercises);
      buffer.writeln();
    } else {
      for (final routineExercise in routine.exercises) {
        buffer.writeln(_exerciseName(routineExercise));
        for (final line
            in _formatTemplateGroups(routineExercise.setTemplates)) {
          buffer.writeln('- $line');
        }
        buffer.writeln();
      }
    }

    buffer
      ..writeln(labels.sharedWithTrainLibre)
      ..write(labels.githubUrl);
    return buffer.toString();
  }

  List<RoutineShareExerciseSummary> imageExerciseSummaries(
    Routine routine, {
    int visibleExerciseLimit = 6,
  }) {
    return routine.exercises.take(visibleExerciseLimit).map((routineExercise) {
      return RoutineShareExerciseSummary(
        name: _exerciseName(routineExercise),
        detail: imagePlanSummary(routineExercise.setTemplates),
      );
    }).toList(growable: false);
  }

  String _exerciseName(RoutineExercise routineExercise) {
    final exercise = routineExercise.exercise;
    final preferGerman = locale?.toLowerCase().startsWith('de') == true;
    final primary = preferGerman ? exercise.nameDe : exercise.nameEn;
    final fallback = preferGerman ? exercise.nameEn : exercise.nameDe;
    return primary.trim().isNotEmpty ? primary : fallback;
  }

  String imageSummaryLine(Routine routine) {
    final exerciseCount = routine.exercises.length;
    final setCount = routine.exercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.setTemplates.length,
    );
    final pieces = <String>[];
    if (exerciseCount > 0) {
      pieces.add('$exerciseCount ${labels.exercises}');
    }
    if (setCount > 0) {
      pieces.add('$setCount ${labels.sets}');
    }
    return pieces.join(' · ');
  }

  int remainingExerciseCount(Routine routine, int visibleExerciseLimit) {
    final remaining = routine.exercises.length - visibleExerciseLimit;
    return remaining > 0 ? remaining : 0;
  }

  Map<ShareSetType, int> setTypeCounts(Routine routine) {
    final counts = <ShareSetType, int>{};
    for (final exercise in routine.exercises) {
      for (final template in exercise.setTemplates) {
        final type = shareSetTypeFromRaw(template.setType);
        counts.update(type, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    return counts;
  }

  int plannedSetCount(Routine routine) {
    return routine.exercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.setTemplates.length,
    );
  }

  String imagePlanSummary(List<SetTemplate> templates) {
    final counts = <ShareSetType, int>{};
    for (final template in templates) {
      final type = shareSetTypeFromRaw(template.setType);
      counts.update(type, (value) => value + 1, ifAbsent: () => 1);
    }
    const orderedTypes = [
      ShareSetType.warmup,
      ShareSetType.work,
      ShareSetType.failure,
      ShareSetType.dropset,
      ShareSetType.superset,
      ShareSetType.other,
    ];
    return orderedTypes
        .where((type) => (counts[type] ?? 0) > 0)
        .map((type) => '${counts[type]}${_imageSetTypeCode(type)}')
        .join(' · ');
  }

  String _imageSetTypeCode(ShareSetType type) {
    return switch (type) {
      ShareSetType.warmup => 'W',
      ShareSetType.work => 'N',
      ShareSetType.failure => 'F',
      ShareSetType.dropset => 'D',
      ShareSetType.superset => 'S',
      ShareSetType.other => 'O',
    };
  }

  List<String> _formatTemplateGroups(List<SetTemplate> templates) {
    if (templates.isEmpty) return const <String>[];
    final groups = <_RoutineSetGroup>[];
    for (final template in templates) {
      final type = shareSetTypeFromRaw(template.setType);
      final targetReps = template.targetReps?.trim();
      final previous = groups.isNotEmpty ? groups.last : null;
      if (previous != null &&
          previous.type == type &&
          previous.targetReps == targetReps) {
        previous.count += 1;
      } else {
        groups.add(_RoutineSetGroup(type, targetReps));
      }
    }
    return groups.map(_formatGroup).toList(growable: false);
  }

  String _formatGroup(_RoutineSetGroup group) {
    final typeLabel = labels.setTypeCount(group.type, group.count);
    final reps = group.targetReps == null || group.targetReps!.isEmpty
        ? ''
        : ' x ${_formatRepRange(group.targetReps!)} ${labels.reps}';
    return '$typeLabel$reps';
  }

  String _formatRepRange(String value) => value.replaceAll('-', '–');
}

class _RoutineSetGroup {
  _RoutineSetGroup(this.type, this.targetReps);

  final ShareSetType type;
  final String? targetReps;
  int count = 1;
}

class RoutineShareExerciseSummary {
  const RoutineShareExerciseSummary({required this.name, required this.detail});

  final String name;
  final String detail;
}
