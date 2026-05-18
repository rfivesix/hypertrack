import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/statistics/domain/recovery_domain_service.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart'
    as model;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkoutLocalDataSource query semantics', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;
    late WorkoutLocalDataSource helper;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
      helper = WorkoutLocalDataSource.forTesting(databaseHelper: dbHelper);
    });

    tearDown(() async {
      await database.close();
    });

    test('getAllCategories returns sorted unique non-empty categories',
        () async {
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              nameDe: const drift.Value('Bench Press'),
              nameEn: const drift.Value('Bench Press'),
              categoryName: const drift.Value('Strength'),
            ),
          );
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              nameDe: const drift.Value('Running'),
              nameEn: const drift.Value('Running'),
              categoryName: const drift.Value('Cardio'),
            ),
          );
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              nameDe: const drift.Value('Push-up'),
              nameEn: const drift.Value('Push-up'),
              categoryName: const drift.Value('Strength'),
            ),
          );
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              nameDe: const drift.Value('No Category'),
              nameEn: const drift.Value('No Category'),
              categoryName: const drift.Value(''),
            ),
          );

      final categories = await helper.getAllCategories();

      expect(categories, ['Cardio', 'Strength']);
    });

    test(
        'searchExercises applies query + category filters and keeps name order',
        () async {
      await helper.insertExercise(
        const model.Exercise(
          nameDe: 'Biceps Curl',
          nameEn: 'Biceps Curl',
          descriptionDe: '',
          descriptionEn: '',
          categoryName: 'Strength',
          primaryMuscles: ['biceps'],
          secondaryMuscles: [],
        ),
      );
      await helper.insertExercise(
        const model.Exercise(
          nameDe: 'Bench Press',
          nameEn: 'Bench Press',
          descriptionDe: '',
          descriptionEn: '',
          categoryName: 'Strength',
          primaryMuscles: ['chest'],
          secondaryMuscles: ['triceps'],
        ),
      );
      await helper.insertExercise(
        const model.Exercise(
          nameDe: 'Burpee',
          nameEn: 'Burpee',
          descriptionDe: '',
          descriptionEn: '',
          categoryName: 'Cardio',
          primaryMuscles: ['legs'],
          secondaryMuscles: [],
        ),
      );

      final strengthB = await helper.searchExercises(
        query: 'B',
        selectedCategories: const ['Strength'],
      );

      expect(strengthB.map((e) => e.nameDe).toList(), [
        'Bench Press',
        'Biceps Curl',
      ]);
    });

    test('getAllMuscleGroups parses json and csv-style lists and deduplicates',
        () async {
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              nameDe: const drift.Value('Barbell Row'),
              nameEn: const drift.Value('Barbell Row'),
              categoryName: const drift.Value('Strength'),
              musclesPrimary: const drift.Value('["lats","biceps"]'),
              musclesSecondary: const drift.Value('rear_delts, traps'),
            ),
          );
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              nameDe: const drift.Value('Incline Press'),
              nameEn: const drift.Value('Incline Press'),
              categoryName: const drift.Value('Strength'),
              musclesPrimary: const drift.Value('["chest","front_delts"]'),
              musclesSecondary: const drift.Value('["triceps"]'),
            ),
          );

      final groups = await helper.getAllMuscleGroups();

      expect(
        groups,
        [
          'biceps',
          'chest',
          'front_delts',
          'lats',
          'rear_delts',
          'traps',
          'triceps'
        ],
      );
    });

    test('catalog-style upsert updates metadata for existing exercise id',
        () async {
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              id: const drift.Value('catalog-1'),
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

      final refreshedCompanion = db.ExercisesCompanion(
        id: const drift.Value('catalog-1'),
        nameDe: const drift.Value('Bankdruecken Neu'),
        nameEn: const drift.Value('Bench Press New'),
        descriptionDe: const drift.Value('neu'),
        descriptionEn: const drift.Value('new'),
        categoryName: const drift.Value('Strength'),
        musclesPrimary: const drift.Value('["chest"]'),
        musclesSecondary: const drift.Value('["front_delts","triceps"]'),
        source: const drift.Value('base'),
        isCustom: const drift.Value(false),
      );

      await database.into(database.exercises).insert(
            refreshedCompanion,
            onConflict: drift.DoUpdate(
              (_) => refreshedCompanion,
              target: [database.exercises.id],
            ),
          );

      final refreshed = await helper.getExerciseByUuid('catalog-1');
      expect(refreshed, isNotNull);
      expect(refreshed!.nameEn, 'Bench Press New');
      expect(refreshed.secondaryMuscles, contains('front_delts'));
    });

    test(
        'catalog-style refresh remains non-destructive for exercises not present',
        () async {
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              id: const drift.Value('catalog-keep'),
              nameDe: const drift.Value('Historische Uebung'),
              nameEn: const drift.Value('Historical Exercise'),
              categoryName: const drift.Value('Strength'),
              source: const drift.Value('base'),
              isCustom: const drift.Value(false),
            ),
          );
      await database.into(database.exercises).insert(
            db.ExercisesCompanion(
              id: const drift.Value('catalog-update'),
              nameDe: const drift.Value('Rudern Alt'),
              nameEn: const drift.Value('Row Old'),
              categoryName: const drift.Value('Strength'),
              source: const drift.Value('base'),
              isCustom: const drift.Value(false),
            ),
          );

      final refreshedCompanion = db.ExercisesCompanion(
        id: const drift.Value('catalog-update'),
        nameDe: const drift.Value('Rudern Neu'),
        nameEn: const drift.Value('Row New'),
        categoryName: const drift.Value('Strength'),
        source: const drift.Value('base'),
        isCustom: const drift.Value(false),
      );
      await database.into(database.exercises).insert(
            refreshedCompanion,
            onConflict: drift.DoUpdate(
              (_) => refreshedCompanion,
              target: [database.exercises.id],
            ),
          );

      final names = (await helper
              .searchExercises(query: '', selectedCategories: const []))
          .map((e) => e.nameEn)
          .toList();
      expect(names, containsAll(['Historical Exercise', 'Row New']));
    });

    test('getRecoveryAnalytics counts bodyweight and weighted strength only',
        () async {
      final now = DateTime.now();
      final workoutId = await _insertWorkout(
        database,
        id: 'recovery-workout-main',
        startTime: now.subtract(const Duration(hours: 2)),
      );
      final ongoingWorkoutId = await _insertWorkout(
        database,
        id: 'recovery-workout-ongoing',
        startTime: now.subtract(const Duration(hours: 1)),
        status: 'ongoing',
      );

      final pushupId = await _insertExercise(
        database,
        id: 'recovery-pushup',
        name: 'Push-up',
        category: 'Strength',
        primaryMuscles: '["chest"]',
      );
      final pullupId = await _insertExercise(
        database,
        id: 'recovery-weighted-pullup',
        name: 'Weighted Pull-up',
        category: 'Strength',
        primaryMuscles: '["lats"]',
      );
      final warmupId = await _insertExercise(
        database,
        id: 'recovery-shoulder-raise',
        name: 'Shoulder Raise',
        category: 'Strength',
        primaryMuscles: '["front_delts"]',
      );
      final runId = await _insertExercise(
        database,
        id: 'recovery-running',
        name: 'Running',
        category: 'Cardio',
        primaryMuscles: '["quads","hamstrings"]',
      );
      final incompleteId = await _insertExercise(
        database,
        id: 'recovery-lunge',
        name: 'Lunge',
        category: 'Strength',
        primaryMuscles: '["glutes"]',
      );

      await _insertSet(
        database,
        workoutId: workoutId,
        exerciseId: pushupId,
        exerciseName: 'Push-up',
        weight: 0,
        reps: 12,
      );
      await _insertSet(
        database,
        workoutId: workoutId,
        exerciseId: pullupId,
        exerciseName: 'Weighted Pull-up',
        weight: 10,
        reps: 5,
      );
      await _insertSet(
        database,
        workoutId: workoutId,
        exerciseId: warmupId,
        exerciseName: 'Shoulder Raise',
        setType: 'warmup',
        weight: 5,
        reps: 15,
      );
      await _insertSet(
        database,
        workoutId: workoutId,
        exerciseId: runId,
        exerciseName: 'Running',
        reps: 1,
        distance: 5,
        durationSeconds: 1800,
      );
      await _insertSet(
        database,
        workoutId: workoutId,
        exerciseId: incompleteId,
        exerciseName: 'Lunge',
        reps: 10,
        isCompleted: false,
      );
      await _insertSet(
        database,
        workoutId: ongoingWorkoutId,
        exerciseId: incompleteId,
        exerciseName: 'Lunge',
        reps: 10,
      );

      final analytics = await helper.getRecoveryAnalytics(lookbackDays: 30);
      final muscles = _musclesByName(analytics);

      expect(analytics['hasData'], isTrue);
      expect(muscles.keys, containsAll(['chest', 'lats']));
      expect(muscles['chest']!['lastEquivalentSets'], 1.0);
      expect(muscles['lats']!['lastEquivalentSets'], 1.0);
      expect(muscles.keys, isNot(contains('front_delts')));
      expect(muscles.keys, isNot(contains('quads')));
      expect(muscles.keys, isNot(contains('hamstrings')));
      expect(muscles.keys, isNot(contains('glutes')));
    });

    test('getRecoveryAnalytics ignores sub-threshold muscle noise', () async {
      final now = DateTime.now();
      final workoutId = await _insertWorkout(
        database,
        id: 'recovery-threshold-workout',
        startTime: now.subtract(const Duration(hours: 2)),
      );
      final exerciseId = await _insertExercise(
        database,
        id: 'recovery-secondary-only',
        name: 'Secondary Only Row',
        category: 'Strength',
        primaryMuscles: '[]',
        secondaryMuscles: '["traps"]',
      );

      await _insertSet(
        database,
        workoutId: workoutId,
        exerciseId: exerciseId,
        exerciseName: 'Secondary Only Row',
        weight: 20,
        reps: 10,
      );

      final analytics = await helper.getRecoveryAnalytics(lookbackDays: 30);

      expect(
        RecoveryDomainService.minimumSignificantEquivalentSets,
        1.0,
      );
      expect(analytics['hasData'], isFalse);
      expect(analytics['muscles'], isEmpty);
    });

    test('getRecoveryAnalytics uses fixed lookback instead of stale history',
        () async {
      final now = DateTime.now();
      final oldWorkoutId = await _insertWorkout(
        database,
        id: 'recovery-old-workout',
        startTime: now.subtract(const Duration(days: 30)),
      );
      final recentWorkoutId = await _insertWorkout(
        database,
        id: 'recovery-recent-workout',
        startTime: now.subtract(const Duration(hours: 2)),
      );
      final chestId = await _insertExercise(
        database,
        id: 'recovery-old-bench',
        name: 'Bench Press',
        category: 'Strength',
        primaryMuscles: '["chest"]',
      );
      final bicepsId = await _insertExercise(
        database,
        id: 'recovery-recent-curl',
        name: 'Curl',
        category: 'Strength',
        primaryMuscles: '["biceps"]',
      );

      await _insertSet(
        database,
        workoutId: oldWorkoutId,
        exerciseId: chestId,
        exerciseName: 'Bench Press',
        weight: 80,
        reps: 8,
      );
      await _insertSet(
        database,
        workoutId: recentWorkoutId,
        exerciseId: bicepsId,
        exerciseName: 'Curl',
        weight: 20,
        reps: 8,
      );

      final analytics = await helper.getRecoveryAnalytics();
      final muscles = _musclesByName(analytics);

      expect(
        RecoveryDomainService.recoveryLookbackDays,
        14,
      );
      expect(muscles.keys, contains('biceps'));
      expect(muscles.keys, isNot(contains('chest')));
    });
  });
}

Future<String> _insertExercise(
  db.AppDatabase database, {
  required String id,
  required String name,
  required String category,
  required String primaryMuscles,
  String secondaryMuscles = '[]',
}) async {
  final row = await database.into(database.exercises).insertReturning(
        db.ExercisesCompanion(
          id: drift.Value(id),
          nameDe: drift.Value(name),
          nameEn: drift.Value(name),
          categoryName: drift.Value(category),
          musclesPrimary: drift.Value(primaryMuscles),
          musclesSecondary: drift.Value(secondaryMuscles),
        ),
      );
  return row.id;
}

Future<String> _insertWorkout(
  db.AppDatabase database, {
  required String id,
  required DateTime startTime,
  String status = 'completed',
}) async {
  final row = await database.into(database.workoutLogs).insertReturning(
        db.WorkoutLogsCompanion(
          id: drift.Value(id),
          startTime: drift.Value(startTime),
          endTime: drift.Value(startTime.add(const Duration(hours: 1))),
          status: drift.Value(status),
        ),
      );
  return row.id;
}

Future<void> _insertSet(
  db.AppDatabase database, {
  required String workoutId,
  required String exerciseId,
  required String exerciseName,
  String setType = 'normal',
  double? weight,
  int? reps,
  bool isCompleted = true,
  double? distance,
  int? durationSeconds,
}) async {
  await database.into(database.setLogs).insert(
        db.SetLogsCompanion(
          workoutLogId: drift.Value(workoutId),
          exerciseId: drift.Value(exerciseId),
          exerciseNameSnapshot: drift.Value(exerciseName),
          setType: drift.Value(setType),
          weight:
              weight == null ? const drift.Value.absent() : drift.Value(weight),
          reps: reps == null ? const drift.Value.absent() : drift.Value(reps),
          isCompleted: drift.Value(isCompleted),
          distance: distance == null
              ? const drift.Value.absent()
              : drift.Value(distance),
          durationSeconds: durationSeconds == null
              ? const drift.Value.absent()
              : drift.Value(durationSeconds),
        ),
      );
}

Map<String, Map<String, dynamic>> _musclesByName(
  Map<String, dynamic> analytics,
) {
  return {
    for (final muscle
        in (analytics['muscles'] as List<dynamic>).cast<Map<String, dynamic>>())
      muscle['muscleGroup'] as String: muscle,
  };
}
