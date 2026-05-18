import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/sharing/routine_share_formatter.dart';
import 'package:train_libre/features/sharing/share_labels.dart';
import 'package:train_libre/features/sharing/share_set_type.dart';
import 'package:train_libre/features/sharing/workout_share_formatter.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/domain/models/routine.dart';
import 'package:train_libre/features/workout/domain/models/routine_exercise.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/set_template.dart';
import 'package:train_libre/features/workout/domain/models/workout_log.dart';

void main() {
  final english = _labels();
  final german = _labels(
    sharedWithTrainLibre: 'Geteilt mit Train Libre',
    volume: 'Volumen',
    reps: 'Wdh',
    warmupSuffix: 'Aufwärmen',
    failureSuffix: 'Muskelversagen',
    dropsetSuffix: 'Dropsatz',
    setTypeCount: _germanSetTypeCount,
    setTypeCompact: _germanSetTypeCompact,
  );

  group('WorkoutShareFormatter', () {
    test('formats weighted workout with normal per-set lines and volume', () {
      final formatter = WorkoutShareFormatter(english);
      final text = formatter.format(
        _workout([
          _set('Bench Press', weightKg: 80, reps: 8),
          _set('Bench Press', weightKg: 80, reps: 7, order: 2),
        ]),
      );

      expect(text, contains('Push Day'));
      expect(text, contains('Volume: 1,200 kg'));
      expect(text, contains('1 exercises · 2 sets'));
      expect(text, contains('Set 1: 80 kg x 8'));
      expect(text, contains('Set 2: 80 kg x 7'));
      expect(text, isNot(contains('[Work')));
      expect(text, contains('Shared with Train Libre'));
      expect(text, contains('https://github.com/rfivesix/train-libre'));
      expect(text, isNot(contains('workoutLogId')));
    });

    test('formats warm-up and failure sets as suffixes', () {
      final formatter = WorkoutShareFormatter(german);
      final text = formatter.format(
        _workout([
          _set('Leg Curl', setType: 'warmup', weightKg: 45, reps: 13),
          _set('Leg Curl', weightKg: 70, reps: 5, order: 2),
          _set('Leg Curl', setType: 'failure', weightKg: 55, reps: 8, order: 3),
        ]),
      );

      expect(text, contains('Set 1: 45 kg x 13 [Aufwärmen]'));
      expect(text, contains('Set 2: 70 kg x 5'));
      expect(text, contains('Set 3: 55 kg x 8 [Muskelversagen]'));
    });

    test('formats dropsets as suffixes', () {
      final formatter = WorkoutShareFormatter(english);
      final text = formatter.format(
        _workout([_set('Curl', setType: 'dropset', weightKg: 20, reps: 12)]),
      );

      expect(text, contains('Set 1: 20 kg x 12 [Dropset]'));
    });

    test('handles bodyweight/no-weight sets as reps only', () {
      final formatter = WorkoutShareFormatter(german);
      final text = formatter.format(_workout([_set('Push-up', reps: 20)]));

      expect(text, contains('Set 1: 20 Wdh'));
      expect(text, isNot(contains('0 kg')));
    });

    test('handles cardio distance and duration cleanly', () {
      final formatter = WorkoutShareFormatter(german);
      final text = formatter.format(
        _workout([
          _set(
            'Rowing Machine',
            weightKg: 1,
            distanceKm: 0.6,
            durationSeconds: 120,
          ),
        ]),
      );

      expect(text, contains('Set 1: 1 kg · 0.6 km · 2 min'));
    });

    test('truncates long image exercise list outside UI', () {
      final formatter = WorkoutShareFormatter(english);
      final workout = _workout(
        List.generate(
          8,
          (index) => _set('Exercise $index', reps: 10, order: index),
        ),
      );

      expect(formatter.imageExerciseSummaries(workout).length, 6);
      expect(formatter.remainingExerciseCount(workout, 6), 2);
    });

    test('builds muscle volume summaries from exercise muscles', () {
      final formatter = WorkoutShareFormatter(english);
      final workout = _workout([
        _set('Row', weightKg: 80, reps: 10),
        _set('Curl', weightKg: 20, reps: 10, order: 2),
      ]);
      final muscles = formatter.muscleVolumeSummaries(
        workout,
        {
          'Row': _exercise(
            'Row',
            primaryMuscles: const ['Lats', 'Upper Back'],
          ),
          'Curl': _exercise('Curl', primaryMuscles: const ['Biceps']),
        },
      );

      expect(muscles.map((m) => m.name), containsAll(['Lats', 'Upper Back']));
      expect(muscles.first.formattedVolume, '800 kg');
      expect(muscles.any((m) => m.name == 'Row'), isFalse);
    });
  });

  group('RoutineShareFormatter', () {
    test('formats English singular/plural labels and rep ranges', () {
      final formatter = RoutineShareFormatter(english);
      final text = formatter.format(
        Routine(
          name: 'Upper',
          exercises: [
            _routineExercise('Bench Press', [
              SetTemplate(setType: 'warmup', targetReps: '15-20'),
              SetTemplate(setType: 'normal', targetReps: '8-12'),
              SetTemplate(setType: 'normal', targetReps: '8-12'),
              SetTemplate(setType: 'normal', targetReps: '8-12'),
              SetTemplate(setType: 'failure', targetReps: '10-15'),
            ]),
          ],
        ),
      );

      expect(text, contains('- 1 warm-up set x 15–20 reps'));
      expect(text, contains('- 3 work sets x 8–12 reps'));
      expect(text, contains('- 1 failure set x 10–15 reps'));
      expect(text, contains('Shared with Train Libre'));
      expect(text, contains('https://github.com/rfivesix/train-libre'));
    });

    test('formats German singular/plural labels and rep ranges', () {
      final formatter = RoutineShareFormatter(german, locale: 'de');
      final text = formatter.format(
        Routine(
          name: 'Unterkörper',
          exercises: [
            _routineExercise('Leg Curl', [
              SetTemplate(setType: 'warmup', targetReps: '15-20'),
              SetTemplate(setType: 'warmup', targetReps: '15-20'),
              SetTemplate(setType: 'normal', targetReps: '8-12'),
              SetTemplate(setType: 'failure', targetReps: '10-15'),
              SetTemplate(setType: 'failure', targetReps: '10-15'),
              SetTemplate(setType: 'failure', targetReps: '10-15'),
            ]),
          ],
        ),
      );

      expect(text, contains('- 2 Aufwärmsätze x 15–20 Wdh'));
      expect(text, contains('- 1 Arbeitssatz x 8–12 Wdh'));
      expect(
        text,
        contains('- 3 Sätze bis zum Muskelversagen x 10–15 Wdh'),
      );
      expect(text, contains('Geteilt mit Train Libre'));
      expect(text, contains('https://github.com/rfivesix/train-libre'));
    });

    test('routine image summary stays compact', () {
      final formatter = RoutineShareFormatter(german, locale: 'de');
      final summary = formatter.imagePlanSummary([
        SetTemplate(setType: 'warmup', targetReps: '15-20'),
        SetTemplate(setType: 'normal', targetReps: '8-12'),
        SetTemplate(setType: 'failure', targetReps: '10-15'),
        SetTemplate(setType: 'failure', targetReps: '10-15'),
      ]);

      expect(summary, '1W · 1N · 2F');
      expect(summary, isNot(contains('15')));
      expect(summary, isNot(contains('Wdh')));
    });
  });
}

ShareLabels _labels({
  String sharedWithTrainLibre = 'Shared with Train Libre',
  String volume = 'Volume',
  String reps = 'reps',
  String warmupSuffix = 'Warm-up',
  String failureSuffix = 'Failure',
  String dropsetSuffix = 'Dropset',
  String Function(ShareSetType, int) setTypeCount = _englishSetTypeCount,
  String Function(ShareSetType, int) setTypeCompact = _englishSetTypeCompact,
}) {
  return ShareLabels(
    appName: 'Train Libre',
    sharedWithTrainLibre: sharedWithTrainLibre,
    freeWorkoutTitle: 'Free Workout',
    duration: 'Duration',
    volume: volume,
    exercises: 'exercises',
    sets: 'sets',
    set: 'set',
    setNumber: (number) => 'Set $number',
    reps: reps,
    kg: 'kg',
    km: 'km',
    min: 'min',
    warmup: 'Warm-up',
    work: 'Work sets',
    failure: 'Failure',
    dropset: 'Dropset',
    superset: 'Superset',
    other: 'Other',
    warmupSuffix: warmupSuffix,
    failureSuffix: failureSuffix,
    dropsetSuffix: dropsetSuffix,
    supersetSuffix: 'Superset',
    otherSuffix: 'Other',
    setTypeCount: setTypeCount,
    setTypeCompact: setTypeCompact,
    moreExercises: (count) => '+ $count more exercises',
    githubUrl: 'https://github.com/rfivesix/train-libre',
    shareImageSummary: 'Summary',
    shareImageExercises: 'Exercises',
    shareImageMuscleFocus: 'Muscle focus',
    shareImageMinimal: 'Minimal',
  );
}

String _englishSetTypeCount(ShareSetType type, int count) {
  final singular = switch (type) {
    ShareSetType.warmup => 'warm-up set',
    ShareSetType.work => 'work set',
    ShareSetType.failure => 'failure set',
    ShareSetType.dropset => 'dropset',
    ShareSetType.superset => 'superset',
    ShareSetType.other => 'other set',
  };
  final plural = switch (type) {
    ShareSetType.dropset => 'dropsets',
    ShareSetType.superset => 'supersets',
    _ => '${singular}s',
  };
  return '$count ${count == 1 ? singular : plural}';
}

String _englishSetTypeCompact(ShareSetType type, int count) {
  final label = switch (type) {
    ShareSetType.warmup => 'warm-up',
    ShareSetType.work => 'work',
    ShareSetType.failure => 'failure',
    ShareSetType.dropset => 'dropset',
    ShareSetType.superset => 'superset',
    ShareSetType.other => 'other',
  };
  return '$count $label';
}

String _germanSetTypeCount(ShareSetType type, int count) {
  return switch (type) {
    ShareSetType.warmup =>
      '$count ${count == 1 ? 'Aufwärmsatz' : 'Aufwärmsätze'}',
    ShareSetType.work =>
      '$count ${count == 1 ? 'Arbeitssatz' : 'Arbeitssätze'}',
    ShareSetType.failure =>
      '$count ${count == 1 ? 'Satz' : 'Sätze'} bis zum Muskelversagen',
    ShareSetType.dropset => '$count ${count == 1 ? 'Dropsatz' : 'Dropsätze'}',
    ShareSetType.superset =>
      '$count ${count == 1 ? 'Supersatz' : 'Supersätze'}',
    ShareSetType.other => '$count Spezial-Sätze',
  };
}

String _germanSetTypeCompact(ShareSetType type, int count) {
  final label = switch (type) {
    ShareSetType.warmup => 'Aufwärmen',
    ShareSetType.work => 'Arbeit',
    ShareSetType.failure => 'Muskelversagen',
    ShareSetType.dropset => count == 1 ? 'Dropsatz' : 'Dropsätze',
    ShareSetType.superset => count == 1 ? 'Supersatz' : 'Supersätze',
    ShareSetType.other => 'Spezial',
  };
  return '$count $label';
}

WorkoutLog _workout(List<SetLog> sets) {
  return WorkoutLog(
    id: 42,
    routineName: 'Push Day',
    startTime: DateTime(2026, 5, 2, 10),
    endTime: DateTime(2026, 5, 2, 10, 58),
    sets: sets,
  );
}

SetLog _set(
  String exerciseName, {
  String setType = 'normal',
  double? weightKg,
  int? reps,
  double? distanceKm,
  int? durationSeconds,
  int order = 1,
}) {
  return SetLog(
    id: order,
    workoutLogId: 42,
    exerciseName: exerciseName,
    setType: setType,
    weightKg: weightKg,
    reps: reps,
    distanceKm: distanceKm,
    durationSeconds: durationSeconds,
    isCompleted: true,
    logOrder: order,
  );
}

RoutineExercise _routineExercise(String name, List<SetTemplate> templates) {
  return RoutineExercise(
    exercise: _exercise(name),
    setTemplates: templates,
  );
}

Exercise _exercise(
  String name, {
  List<String> primaryMuscles = const [],
}) {
  return Exercise(
    nameDe: name,
    nameEn: name,
    descriptionDe: '',
    descriptionEn: '',
    categoryName: 'Strength',
    primaryMuscles: primaryMuscles,
    secondaryMuscles: const [],
  );
}
