import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart' as db;
import 'package:hypertrack/data/drift_database.dart' show AppDatabase;
import 'package:hypertrack/data/workout_database_helper.dart';
import 'package:hypertrack/models/routine_exercise.dart';
import 'package:hypertrack/models/set_log.dart';
import 'package:hypertrack/models/set_template.dart';
import 'package:hypertrack/models/exercise.dart' as model;
import 'package:hypertrack/services/workout_session_manager.dart';

Future<void> _waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final start = DateTime.now();
  while (!condition()) {
    if (DateTime.now().difference(start) > timeout) {
      fail('Condition not met within timeout.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkoutSessionManager high-value behavior', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;
    late WorkoutDatabaseHelper workoutDb;
    late WorkoutSessionManager manager;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
      workoutDb = WorkoutDatabaseHelper.forTesting(databaseHelper: dbHelper);
      manager = WorkoutSessionManager.forTesting(workoutDb: workoutDb);
    });

    tearDown(() async {
      manager.dispose();
      await database.close();
    });

    test('tryRestoreSession keeps empty state when no ongoing workout exists',
        () async {
      expect(manager.workoutLog, isNull);
      expect(manager.exercises, isEmpty);
      expect(manager.setLogs, isEmpty);
      expect(manager.isActive, isFalse);

      await manager.tryRestoreSession();

      expect(manager.workoutLog, isNull);
      expect(manager.exercises, isEmpty);
      expect(manager.setLogs, isEmpty);
      expect(manager.isActive, isFalse);
    });

    test(
      'restoreWorkoutSession loads routine exercises when persisted sets are missing',
      () async {
        final exercise = await workoutDb.insertExercise(
          const model.Exercise(
            nameDe: 'Bankdruecken',
            nameEn: 'Bench Press',
            descriptionDe: '',
            descriptionEn: '',
            categoryName: 'Strength',
            primaryMuscles: ['chest'],
            secondaryMuscles: ['triceps'],
          ),
        );
        final routine = await workoutDb.createRoutine('Push A');
        final re =
            await workoutDb.addExerciseToRoutine(routine.id!, exercise.id!);
        await workoutDb.updatePauseTime(re!.id!, 120);
        final log = await workoutDb.startWorkout(routineName: 'Push A');

        await manager.restoreWorkoutSession(log);

        expect(manager.workoutLog?.id, log.id);
        expect(manager.exercises.length, 1);
        expect(manager.exercises.first.exercise.nameEn, 'Bench Press');
        expect(manager.exercises.first.setTemplates.length, 3);
        expect(manager.pauseTimes[manager.exercises.first.id!], 120);
        expect(manager.setLogs, isEmpty);
      },
    );

    test('startWorkout creates null-initialized set logs from templates',
        () async {
      final log = await workoutDb.startWorkout(routineName: 'Session');
      final exercise = const model.Exercise(
        id: 1,
        nameDe: 'Kniebeuge',
        nameEn: 'Squat',
        descriptionDe: '',
        descriptionEn: '',
        categoryName: 'Strength',
        primaryMuscles: ['quads'],
        secondaryMuscles: [],
      );
      final routineExercise = RoutineExercise(
        id: 100,
        exercise: exercise,
        pauseSeconds: 90,
        setTemplates: [
          SetTemplate(id: 1001, setType: 'normal', targetReps: '6-8'),
          SetTemplate(id: 1002, setType: 'normal', targetReps: '6-8'),
        ],
      );

      await manager.startWorkout(log, [routineExercise]);
      await _waitFor(() => manager.setLogs.length == 2);

      expect(manager.totalSets, 2);
      expect(manager.totalVolume, 0);
      expect(manager.setLogs[1001]!.weightKg, isNull);
      expect(manager.setLogs[1001]!.reps, isNull);
      expect(manager.setLogs[1002]!.weightKg, isNull);
      expect(manager.setLogs[1002]!.reps, isNull);
    });

    test('addSetToExercise keeps previous-set defaults and ordering', () async {
      final log = await workoutDb.startWorkout(routineName: 'Session');
      final exercise = const model.Exercise(
        id: 1,
        nameDe: 'Bankdruecken',
        nameEn: 'Bench Press',
        descriptionDe: '',
        descriptionEn: '',
        categoryName: 'Strength',
        primaryMuscles: ['chest'],
        secondaryMuscles: [],
      );
      final routineExercise = RoutineExercise(
        id: 200,
        exercise: exercise,
        pauseSeconds: 75,
        setTemplates: [
          SetTemplate(id: 2001, setType: 'normal', targetReps: '8-12'),
        ],
      );

      await manager.startWorkout(log, [routineExercise]);
      await _waitFor(() => manager.setLogs.length == 1);

      await manager.updateSet(2001, weight: 100, reps: 8, isCompleted: false);
      await manager.addSetToExercise(200);
      await _waitFor(() => manager.setLogs.length == 2);

      final newSet = manager.setLogs.entries
          .firstWhere((entry) => entry.key != 2001)
          .value;

      expect(newSet.weightKg, 100);
      expect(newSet.reps, 8);
      expect(newSet.isCompleted, isFalse);
      expect(newSet.log_order, 1);
      expect(manager.totalSets, 2);
    });

    test(
        'updateSet completion fallback uses template targets and updates volume',
        () async {
      final log = await workoutDb.startWorkout(routineName: 'Session');
      final exercise = const model.Exercise(
        id: 1,
        nameDe: 'Bankdruecken',
        nameEn: 'Bench Press',
        descriptionDe: '',
        descriptionEn: '',
        categoryName: 'Strength',
        primaryMuscles: ['chest'],
        secondaryMuscles: [],
      );
      final routineExercise = RoutineExercise(
        id: 300,
        exercise: exercise,
        pauseSeconds: null,
        setTemplates: [
          SetTemplate(
            id: 3001,
            setType: 'normal',
            targetReps: '8-12',
            targetWeight: 80,
          ),
        ],
      );

      await manager.startWorkout(log, [routineExercise]);
      await _waitFor(() => manager.setLogs.length == 1);
      await manager.updateSet(3001, isCompleted: true);

      final set = manager.setLogs[3001]!;
      expect(set.weightKg, 80);
      expect(set.reps, 10);
      expect(set.isCompleted, isTrue);
      expect(manager.totalVolume, 800);
    });

    test('restoreWorkoutSession rebuilds exercise blocks and preserves order',
        () async {
      await workoutDb.insertExercise(
        const model.Exercise(
          nameDe: 'Bankdruecken',
          nameEn: 'Bench Press',
          descriptionDe: '',
          descriptionEn: '',
          categoryName: 'Strength',
          primaryMuscles: ['chest'],
          secondaryMuscles: [],
        ),
      );
      await workoutDb.insertExercise(
        const model.Exercise(
          nameDe: 'Kniebeuge',
          nameEn: 'Squat',
          descriptionDe: '',
          descriptionEn: '',
          categoryName: 'Strength',
          primaryMuscles: ['quads'],
          secondaryMuscles: [],
        ),
      );
      final log = await workoutDb.startWorkout(routineName: 'Mixed');

      await workoutDb.insertSetLog(
        SetLog(
          workoutLogId: log.id!,
          exerciseName: 'Bench Press',
          setType: 'normal',
          weightKg: 100,
          reps: 5,
          restTimeSeconds: 90,
          isCompleted: true,
          log_order: 0,
        ),
      );
      await workoutDb.insertSetLog(
        SetLog(
          workoutLogId: log.id!,
          exerciseName: 'Bench Press',
          setType: 'normal',
          weightKg: 105,
          reps: 4,
          restTimeSeconds: 90,
          isCompleted: true,
          log_order: 1,
        ),
      );
      await workoutDb.insertSetLog(
        SetLog(
          workoutLogId: log.id!,
          exerciseName: 'Squat',
          setType: 'normal',
          weightKg: 140,
          reps: 3,
          restTimeSeconds: 120,
          isCompleted: true,
          log_order: 2,
        ),
      );

      await manager.restoreWorkoutSession(log);

      expect(manager.exercises.length, 2);
      expect(manager.exercises[0].exercise.nameEn, 'Bench Press');
      expect(manager.exercises[1].exercise.nameEn, 'Squat');
      expect(manager.exercises[0].setTemplates.length, 2);
      expect(manager.exercises[1].setTemplates.length, 1);
      expect(
        manager.exercises[0].setTemplates.map((t) => t.targetWeight).toList(),
        [100, 105],
      );
      expect(
        manager.exercises[0].setTemplates.map((t) => t.targetReps).toList(),
        ['5', '4'],
      );
      expect(manager.totalSets, 3);
      expect(manager.totalVolume, 1340);
      expect(manager.pauseTimes.values.toSet(), {90, 120});
    });

    test('restoreWorkoutSession resolves exercise by stored exercise_id',
        () async {
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              id: const drift.Value('catalog-bench-1'),
              nameDe: const drift.Value('Bankdruecken Alt'),
              nameEn: const drift.Value('Bench Press Old'),
              descriptionDe: const drift.Value('alt'),
              descriptionEn: const drift.Value('old'),
              categoryName: const drift.Value('Strength'),
              musclesPrimary: const drift.Value('["chest"]'),
              musclesSecondary: const drift.Value('["triceps"]'),
              source: const drift.Value('base'),
              isCustom: const drift.Value(false),
            ),
          );

      final log = await workoutDb.startWorkout(routineName: 'Rename Case');
      await workoutDb.insertSetLog(
        SetLog(
          workoutLogId: log.id!,
          exerciseName: 'Bench Press Old',
          setType: 'normal',
          weightKg: 100,
          reps: 5,
          restTimeSeconds: 90,
          isCompleted: true,
          log_order: 0,
        ),
      );

      await (database.update(database.exercises)
            ..where((tbl) => tbl.id.equals('catalog-bench-1')))
          .write(
        const db.ExercisesCompanion(
          nameDe: drift.Value('Bankdruecken Neu'),
          nameEn: drift.Value('Bench Press New'),
          descriptionDe: drift.Value('neu'),
          descriptionEn: drift.Value('new'),
        ),
      );

      await manager.restoreWorkoutSession(log);

      expect(manager.exercises.length, 1);
      expect(manager.exercises.first.exercise.nameEn, 'Bench Press New');
      expect(manager.setLogs.length, 1);
      expect(manager.totalVolume, 500);
    });

    test(
      'restoreWorkoutSession keeps historical sets even when exercise row is missing',
      () async {
        await database.into(database.exercises).insert(
              db.ExercisesCompanion(
                id: const drift.Value('catalog-missing-1'),
                nameDe: const drift.Value('Historische Uebung'),
                nameEn: const drift.Value('Historical Exercise'),
                categoryName: const drift.Value('Strength'),
                musclesPrimary: const drift.Value('["back"]'),
                musclesSecondary: const drift.Value('[]'),
                source: const drift.Value('base'),
                isCustom: const drift.Value(false),
              ),
            );

        final log = await workoutDb.startWorkout(routineName: 'Missing Case');
        await workoutDb.insertSetLog(
          SetLog(
            workoutLogId: log.id!,
            exerciseName: 'Historical Exercise',
            setType: 'normal',
            weightKg: 80,
            reps: 8,
            restTimeSeconds: 75,
            isCompleted: true,
            log_order: 0,
          ),
        );

        await database.customStatement(
          "UPDATE set_logs SET exercise_id = NULL WHERE exercise_name_snapshot = 'Historical Exercise'",
        );
        await (database.delete(
          database.exercises,
        )..where((tbl) => tbl.id.equals('catalog-missing-1')))
            .go();

        await manager.restoreWorkoutSession(log);

        expect(manager.exercises.length, 1);
        expect(manager.exercises.first.exercise.nameEn, 'Historical Exercise');
        expect(manager.exercises.first.exercise.categoryName, 'Unknown');
        expect(manager.setLogs.length, 1);
      },
    );

    test('finishWorkout deletes incomplete sets and clears manager session',
        () async {
      final log = await workoutDb.startWorkout(routineName: 'Session');
      final exerciseA = const model.Exercise(
        id: 1,
        nameDe: 'A',
        nameEn: 'Exercise A',
        descriptionDe: '',
        descriptionEn: '',
        categoryName: 'Strength',
        primaryMuscles: ['x'],
        secondaryMuscles: [],
      );
      final exerciseB = const model.Exercise(
        id: 2,
        nameDe: 'B',
        nameEn: 'Exercise B',
        descriptionDe: '',
        descriptionEn: '',
        categoryName: 'Strength',
        primaryMuscles: ['y'],
        secondaryMuscles: [],
      );

      await manager.startWorkout(log, [
        RoutineExercise(
          id: 400,
          exercise: exerciseA,
          pauseSeconds: null,
          setTemplates: [SetTemplate(id: 4001, setType: 'normal')],
        ),
        RoutineExercise(
          id: 500,
          exercise: exerciseB,
          pauseSeconds: null,
          setTemplates: [SetTemplate(id: 5001, setType: 'normal')],
        ),
      ]);
      await _waitFor(() => manager.setLogs.length == 2);

      await manager.updateSet(4001, weight: 50, reps: 10, isCompleted: true);
      await manager.updateSet(5001, weight: 60, reps: 8, isCompleted: false);

      await manager.finishWorkout(title: 'Done', notes: 'Great session');

      expect(manager.workoutLog, isNull);
      expect(manager.exercises, isEmpty);
      expect(manager.setLogs, isEmpty);
      expect(manager.isActive, isFalse);

      final storedLog = await workoutDb.getWorkoutLogById(log.id!);
      final storedSets = await workoutDb.getSetLogsForWorkout(log.id!);

      expect(storedLog, isNotNull);
      expect(storedLog!.endTime, isNotNull);
      expect(storedLog.routineName, 'Done');
      expect(storedLog.notes, 'Great session');
      expect(storedSets.length, 1);
      expect(storedSets.first.exerciseName, 'Exercise A');
      expect(storedSets.first.log_order, 0);
      expect(storedSets.first.isCompleted, isTrue);
    });
  });
}
