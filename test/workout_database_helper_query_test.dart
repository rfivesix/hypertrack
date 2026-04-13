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
  });
}
