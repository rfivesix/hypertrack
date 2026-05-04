import 'package:intl/intl.dart';

import '../../models/exercise.dart';
import '../../models/set_log.dart';
import '../../models/workout_log.dart';
import 'share_labels.dart';
import 'share_set_type.dart';

class WorkoutShareFormatter {
  const WorkoutShareFormatter(this.labels, {this.locale});

  final ShareLabels labels;
  final String? locale;

  String format(WorkoutLog workout) {
    final completedSets = _completedSets(workout);
    final exerciseGroups = _groupByExercise(completedSets);
    final buffer = StringBuffer()
      ..writeln(_workoutName(workout))
      ..writeln(_dateDurationLine(workout));

    final volume = totalVolume(workout);
    if (volume > 0) {
      buffer.writeln('${labels.volume}: ${_formatWeight(volume)}');
    }

    final stats = <String>[];
    if (exerciseGroups.isNotEmpty) {
      stats.add('${exerciseGroups.length} ${labels.exercises}');
    }
    if (completedSets.isNotEmpty) {
      stats.add('${completedSets.length} ${labels.sets}');
    }
    if (stats.isNotEmpty) {
      buffer.writeln(stats.join(' · '));
    }
    buffer.writeln();

    for (final entry in exerciseGroups.entries) {
      buffer.writeln(entry.key);
      for (var index = 0; index < entry.value.length; index += 1) {
        buffer.writeln(
          '${labels.setNumber(index + 1)}: ${_formatSetLine(entry.value[index])}',
        );
      }
      buffer.writeln();
    }

    buffer
      ..writeln(labels.sharedWithTrainLibre)
      ..write(labels.githubUrl);
    return buffer.toString();
  }

  WorkoutShareStats stats(WorkoutLog workout) {
    final completedSets = _completedSets(workout);
    return WorkoutShareStats(
      title: _workoutName(workout),
      date: workoutDate(workout),
      duration: _formatWorkoutDuration(workout),
      volume:
          totalVolume(workout) > 0 ? _formatWeight(totalVolume(workout)) : null,
      exerciseCount: _groupByExercise(completedSets).length,
      setCount: completedSets.length,
    );
  }

  List<WorkoutShareExerciseSummary> imageExerciseSummaries(
    WorkoutLog workout, {
    int visibleExerciseLimit = 6,
  }) {
    final groups = _groupByExercise(_completedSets(workout));
    return groups.entries.take(visibleExerciseLimit).map((entry) {
      return WorkoutShareExerciseSummary(
        name: entry.key,
        detail: '${entry.value.length}x',
      );
    }).toList(growable: false);
  }

  List<WorkoutShareExerciseSummary> topVolumeSummaries(
    WorkoutLog workout, {
    int visibleExerciseLimit = 4,
  }) {
    final groups = _groupByExercise(_completedSets(workout));
    final summaries = groups.entries.map((entry) {
      final volume = entry.value.fold<double>(
        0,
        (sum, set) => sum + ((set.weightKg ?? 0) * (set.reps ?? 0)),
      );
      return WorkoutShareExerciseSummary(
        name: entry.key,
        detail: volume > 0 ? _formatWeight(volume) : '${entry.value.length}x',
      );
    }).toList()
      ..sort((a, b) {
        final av = _parseFormattedWeight(a.detail);
        final bv = _parseFormattedWeight(b.detail);
        return bv.compareTo(av);
      });
    return summaries.take(visibleExerciseLimit).toList(growable: false);
  }

  List<MuscleVolumeSummary> muscleVolumeSummaries(
    WorkoutLog workout,
    Map<String, Exercise> exerciseDetails, {
    int visibleMuscleLimit = 6,
  }) {
    final volumeByMuscle = <String, double>{};
    for (final set in _completedSets(workout)) {
      final volume = (set.weightKg ?? 0) * (set.reps ?? 0);
      if (volume <= 0) continue;

      final exercise = exerciseDetails[set.exerciseName];
      final muscles = exercise?.primaryMuscles
              .map((muscle) => muscle.trim())
              .where((muscle) => muscle.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];

      if (muscles.isEmpty) {
        volumeByMuscle.update('Other', (value) => value + volume,
            ifAbsent: () => volume);
      } else {
        for (final muscle in muscles) {
          volumeByMuscle.update(muscle, (value) => value + volume,
              ifAbsent: () => volume);
        }
      }
    }

    final summaries = volumeByMuscle.entries
        .map(
          (entry) => MuscleVolumeSummary(
            name: entry.key,
            volume: entry.value,
            formattedVolume: _formatWeight(entry.value),
          ),
        )
        .toList()
      ..sort((a, b) => b.volume.compareTo(a.volume));

    return summaries.take(visibleMuscleLimit).toList(growable: false);
  }

  String imageSummaryLine(WorkoutLog workout) {
    final workoutStats = stats(workout);
    return [
      if (workoutStats.duration != null) workoutStats.duration,
      if (workoutStats.volume != null) workoutStats.volume,
      if (workoutStats.setCount > 0) '${workoutStats.setCount} ${labels.sets}',
    ].join(' · ');
  }

  String workoutTitle(WorkoutLog workout) => _workoutName(workout);

  String workoutDate(WorkoutLog workout) {
    return DateFormat.yMMMd(locale).format(workout.startTime);
  }

  int remainingExerciseCount(WorkoutLog workout, int visibleExerciseLimit) {
    final count = _groupByExercise(_completedSets(workout)).length;
    final remaining = count - visibleExerciseLimit;
    return remaining > 0 ? remaining : 0;
  }

  double totalVolume(WorkoutLog workout) {
    return _completedSets(workout).fold<double>(
      0,
      (sum, set) => sum + ((set.weightKg ?? 0) * (set.reps ?? 0)),
    );
  }

  List<SetLog> _completedSets(WorkoutLog workout) {
    return workout.sets
        .where((set) => set.isCompleted != false)
        .toList(growable: false);
  }

  String _workoutName(WorkoutLog workout) {
    final name = workout.routineName?.trim();
    return name == null || name.isEmpty ? labels.freeWorkoutTitle : name;
  }

  String _dateDurationLine(WorkoutLog workout) {
    final date = DateFormat.yMMMEd(locale).add_Hm().format(workout.startTime);
    final duration = _formatWorkoutDuration(workout);
    return duration == null ? date : '$date · $duration';
  }

  String? _formatWorkoutDuration(WorkoutLog workout) {
    final duration = workout.endTime?.difference(workout.startTime);
    if (duration == null || duration.inSeconds <= 0) return null;
    return _formatMinutes(duration);
  }

  Map<String, List<SetLog>> _groupByExercise(List<SetLog> sets) {
    final groups = <String, List<SetLog>>{};
    final sorted = [...sets]..sort((a, b) {
        final order = (a.logOrder ?? 0).compareTo(b.logOrder ?? 0);
        return order != 0 ? order : a.exerciseName.compareTo(b.exerciseName);
      });
    for (final set in sorted) {
      final exerciseName = set.exerciseName.trim();
      if (exerciseName.isEmpty) continue;
      groups.putIfAbsent(exerciseName, () => <SetLog>[]).add(set);
    }
    return groups;
  }

  String _formatSetLine(SetLog set) {
    final parts = <String>[];
    final hasWeight = set.weightKg != null && set.weightKg! > 0;
    final hasReps = set.reps != null && set.reps! > 0;
    final hasDistance = set.distanceKm != null && set.distanceKm! > 0;
    final hasDuration = set.durationSeconds != null && set.durationSeconds! > 0;

    if (hasWeight && hasReps) {
      parts.add('${_formatNumber(set.weightKg!)} ${labels.kg} x ${set.reps}');
    } else if (hasReps) {
      parts.add('${set.reps} ${labels.reps}');
    } else if (hasWeight) {
      parts.add('${_formatNumber(set.weightKg!)} ${labels.kg}');
    }

    if (hasDistance) {
      parts.add('${_formatNumber(set.distanceKm!)} ${labels.km}');
    }
    if (hasDuration) {
      parts.add(_formatMinutes(Duration(seconds: set.durationSeconds!)));
    }

    final line = parts.isEmpty ? labels.set : parts.join(' · ');
    final suffix = _specialSetTypeSuffix(set);
    return suffix == null ? line : '$line [$suffix]';
  }

  String? _specialSetTypeSuffix(SetLog set) {
    final type = set.supersetId != null
        ? ShareSetType.superset
        : shareSetTypeFromRaw(set.setType);
    return switch (type) {
      ShareSetType.work => null,
      ShareSetType.warmup => labels.warmupSuffix,
      ShareSetType.failure => labels.failureSuffix,
      ShareSetType.dropset => labels.dropsetSuffix,
      ShareSetType.superset => labels.supersetSuffix,
      ShareSetType.other => labels.otherSuffix,
    };
  }

  String _formatMinutes(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes <= 0) return '<1 ${labels.min}';
    return '$minutes ${labels.min}';
  }

  String _formatWeight(double value) => '${_formatNumber(value)} ${labels.kg}';

  String _formatNumber(double value) {
    return NumberFormat.decimalPattern(locale)
        .format(value == value.roundToDouble() ? value.round() : value);
  }

  double _parseFormattedWeight(String value) {
    final normalized = value
        .replaceAll(labels.kg, '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(normalized) ?? 0;
  }
}

class WorkoutShareStats {
  const WorkoutShareStats({
    required this.title,
    required this.date,
    required this.duration,
    required this.volume,
    required this.exerciseCount,
    required this.setCount,
  });

  final String title;
  final String date;
  final String? duration;
  final String? volume;
  final int exerciseCount;
  final int setCount;
}

class WorkoutShareExerciseSummary {
  const WorkoutShareExerciseSummary({required this.name, required this.detail});

  final String name;
  final String detail;
}

class MuscleVolumeSummary {
  const MuscleVolumeSummary({
    required this.name,
    required this.volume,
    required this.formattedVolume,
  });

  final String name;
  final double volume;
  final String formattedVolume;
}
