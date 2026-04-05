import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart' as db;
import 'package:hypertrack/data/drift_database.dart';
import 'package:hypertrack/data/workout_database_helper.dart';
import 'package:hypertrack/models/exercise.dart' as model;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkoutDatabaseHelper query semantics', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;
    late WorkoutDatabaseHelper helper;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
      helper = WorkoutDatabaseHelper.forTesting(databaseHelper: dbHelper);
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
  });
}
