import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/backup_manager.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart'
    show AppDatabase, ProductsCompanion, ExercisesCompanion;
import 'package:hypertrack/data/product_database_helper.dart';
import 'package:hypertrack/data/workout_database_helper.dart';
import 'package:hypertrack/models/food_entry.dart';
import 'package:hypertrack/models/measurement.dart';
import 'package:hypertrack/models/measurement_session.dart';
import 'package:hypertrack/models/set_log.dart';
import 'package:hypertrack/models/workout_log.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Backup/restore integrity', () {
    late AppDatabase db;
    late DatabaseHelper dbHelper;
    late WorkoutDatabaseHelper workoutDb;
    late ProductDatabaseHelper productDb;
    late BackupManager backupManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      db = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(db);
      workoutDb = WorkoutDatabaseHelper.forTesting(databaseHelper: dbHelper);
      productDb = ProductDatabaseHelper.forTesting(databaseHelper: dbHelper);
      backupManager = BackupManager(
        userDb: dbHelper,
        workoutDb: workoutDb,
        productDb: productDb,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('meal templates and nutrition entries survive backup restore',
        () async {
      await db.into(db.products).insert(
            const ProductsCompanion(
              barcode: drift.Value('base-apple'),
              name: drift.Value('Apple'),
              calories: drift.Value(52),
              protein: drift.Value(0.3),
              carbs: drift.Value(14),
              fat: drift.Value(0.2),
              source: drift.Value('base'),
            ),
          );
      await dbHelper.insertFoodEntry(
        FoodEntry(
          barcode: 'base-apple',
          timestamp: DateTime(2026, 4, 1, 12, 0),
          quantityInGrams: 180,
          mealType: 'mealtypeLunch',
        ),
      );
      final mealId = await dbHelper.insertMeal(
        name: 'Lunch Bowl',
        notes: 'High-carb pre-workout',
      );
      await dbHelper.addMealItem(
        mealId,
        barcode: 'base-apple',
        grams: 180,
      );

      final payload = await backupManager.generateBackupPayloadForTesting();

      final imported =
          await backupManager.importBackupPayloadForTesting(payload);
      expect(imported, isTrue);

      final restoredMeals = await dbHelper.getMeals();
      expect(restoredMeals.length, 1);
      expect(restoredMeals.first['name'], 'Lunch Bowl');
      expect(restoredMeals.first['notes'], 'High-carb pre-workout');

      final restoredItems =
          await dbHelper.getMealItems(restoredMeals.first['id'] as int);
      expect(restoredItems.length, 1);
      expect(restoredItems.first['barcode'], 'base-apple');
      expect(restoredItems.first['quantity_in_grams'], 180);

      final restoredEntries = await dbHelper.getEntriesForDate(
        DateTime(2026, 4, 1),
      );
      expect(restoredEntries.length, 1);
      expect(restoredEntries.first.barcode, 'base-apple');
      expect(restoredEntries.first.quantityInGrams, 180);
      expect(restoredEntries.first.mealType, 'mealtypeLunch');
    });

    test('changed goals/settings and target prefs survive backup restore',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('targetSugar', 37);
      await prefs.setInt('targetFiber', 31);
      await prefs.setInt('targetSalt', 5);

      await dbHelper.saveUserProfile(
        name: 'Alex',
        birthday: DateTime(1995, 3, 10),
        height: 182,
        gender: 'male',
      );
      await dbHelper.saveUserGoals(
        calories: 2500,
        protein: 180,
        carbs: 260,
        fat: 80,
        water: 3200,
        steps: 8500,
      );
      await dbHelper.saveUserGoals(
        calories: 2200,
        protein: 170,
        carbs: 210,
        fat: 70,
        water: 2800,
        steps: 9500,
      );

      final payload = await backupManager.generateBackupPayloadForTesting();

      await dbHelper.saveUserGoals(
        calories: 1800,
        protein: 120,
        carbs: 140,
        fat: 55,
        water: 2200,
        steps: 6000,
      );
      await prefs.setInt('targetSugar', 99);

      final imported =
          await backupManager.importBackupPayloadForTesting(payload);
      expect(imported, isTrue);

      final restoredSettings = await dbHelper.getAppSettings();
      expect(restoredSettings, isNotNull);
      expect(restoredSettings!.targetCalories, 2200);
      expect(restoredSettings.targetProtein, 170);
      expect(restoredSettings.targetCarbs, 210);
      expect(restoredSettings.targetFat, 70);
      expect(restoredSettings.targetWater, 2800);
      expect(restoredSettings.targetSteps, 9500);

      final historyRows = await db.select(db.dailyGoalsHistory).get();
      expect(
        historyRows.any(
          (row) => row.targetCalories == 2200 && row.targetSteps == 9500,
        ),
        isTrue,
      );

      final restoredPrefs = await SharedPreferences.getInstance();
      expect(restoredPrefs.getInt('targetSugar'), 37);
      expect(restoredPrefs.getInt('targetFiber'), 31);
      expect(restoredPrefs.getInt('targetSalt'), 5);
    });

    test('adaptive recommendation state in shared preferences survives restore',
        () async {
      final prefs = await SharedPreferences.getInstance();
      const goalKey = 'adaptive_nutrition_recommendation.goal_direction';
      const rateKey =
          'adaptive_nutrition_recommendation.target_rate_kg_per_week';
      const priorActivityLevelKey =
          'adaptive_nutrition_recommendation.prior_activity_level';
      const extraCardioHoursKey =
          'adaptive_nutrition_recommendation.extra_cardio_hours';
      const generatedKey = 'adaptive_nutrition_recommendation.latest_generated';
      const dueWeekKey =
          'adaptive_nutrition_recommendation.last_generated_due_week_key';

      await prefs.setString(goalKey, 'loseWeight');
      await prefs.setDouble(rateKey, -0.5);
      await prefs.setString(priorActivityLevelKey, 'veryHigh');
      await prefs.setString(extraCardioHoursKey, 'h5');
      await prefs.setString(
        generatedKey,
        jsonEncode(<String, dynamic>{
          'recommendedCalories': 2100,
          'goal': 'loseWeight',
          'targetRateKgPerWeek': -0.5,
        }),
      );
      await prefs.setString(dueWeekKey, '2026-03-30');

      final payload = await backupManager.generateBackupPayloadForTesting();
      final userPreferences =
          payload['userPreferences'] as Map<String, dynamic>;
      expect(userPreferences[priorActivityLevelKey], 'veryHigh');
      expect(userPreferences[extraCardioHoursKey], 'h5');

      await prefs.setString(goalKey, 'gainWeight');
      await prefs.setDouble(rateKey, 0.5);
      await prefs.setString(priorActivityLevelKey, 'low');
      await prefs.setString(extraCardioHoursKey, 'h0');
      await prefs.setString(generatedKey, '{}');
      await prefs.setString(dueWeekKey, '2026-04-06');

      final imported =
          await backupManager.importBackupPayloadForTesting(payload);
      expect(imported, isTrue);

      final restoredPrefs = await SharedPreferences.getInstance();
      expect(restoredPrefs.getString(goalKey), 'loseWeight');
      expect(restoredPrefs.getDouble(rateKey), -0.5);
      expect(restoredPrefs.getString(priorActivityLevelKey), 'veryHigh');
      expect(restoredPrefs.getString(extraCardioHoursKey), 'h5');
      expect(
        restoredPrefs.getString(generatedKey),
        jsonEncode(<String, dynamic>{
          'recommendedCalories': 2100,
          'goal': 'loseWeight',
          'targetRateKgPerWeek': -0.5,
        }),
      );
      expect(restoredPrefs.getString(dueWeekKey), '2026-03-30');
    });

    test('app settings restore even when profile payload is missing', () async {
      final payload = <String, dynamic>{
        'schemaVersion': BackupManager.currentSchemaVersion,
        'foodEntries': const <dynamic>[],
        'mealTemplates': const <dynamic>[],
        'fluidEntries': const <dynamic>[],
        'favoriteBarcodes': const <dynamic>[],
        'customFoodItems': const <dynamic>[],
        'measurementSessions': const <dynamic>[],
        'routines': const <dynamic>[],
        'workoutLogs': const <dynamic>[],
        'userPreferences': const <String, dynamic>{},
        'supplements': const <dynamic>[],
        'supplementLogs': const <dynamic>[],
        'customExercises': const <dynamic>[],
        'dailyGoalsHistory': const <dynamic>[],
        'supplementSettingsHistory': const <dynamic>[],
        'appSettings': <String, dynamic>{
          'userId': 'restored-user-1',
          'themeMode': 'system',
          'unitSystem': 'metric',
          'targetCalories': 2050,
          'targetProtein': 160,
          'targetCarbs': 200,
          'targetFat': 65,
          'targetWater': 2700,
          'targetSteps': 9000,
        },
        'profile': null,
        'healthStepSegments': const <dynamic>[],
      };

      final imported =
          await backupManager.importBackupPayloadForTesting(payload);
      expect(imported, isTrue);

      final restoredSettings = await dbHelper.getAppSettings();
      expect(restoredSettings, isNotNull);
      expect(restoredSettings!.userId, 'restored-user-1');
      expect(restoredSettings.targetCalories, 2050);
      expect(restoredSettings.targetSteps, 9000);

      final restoredProfile = await dbHelper.getUserProfile();
      expect(restoredProfile, isNotNull);
      expect(restoredProfile!.id, 'restored-user-1');
    });

    test('workout set metadata is preserved during restore import', () async {
      await db.into(db.exercises).insert(
            const ExercisesCompanion(
              nameDe: drift.Value('Kniebeuge'),
              nameEn: drift.Value('Squat'),
              source: drift.Value('base'),
              isCustom: drift.Value(false),
            ),
          );

      await workoutDb.importWorkoutData(
        routines: const [],
        workoutLogs: [
          WorkoutLog(
            routineName: 'Leg Day',
            startTime: DateTime(2026, 4, 2, 8, 0),
            endTime: DateTime(2026, 4, 2, 9, 0),
            notes: 'Felt strong',
            sets: [
              SetLog(
                workoutLogId: 1,
                exerciseName: 'Kniebeuge',
                setType: 'normal',
                weightKg: 120,
                reps: 5,
                restTimeSeconds: 180,
                isCompleted: false,
                log_order: 2,
                notes: 'paused reps',
                distanceKm: 0.1,
                durationSeconds: 75,
                rpe: 9,
                rir: 1,
              ),
            ],
          ),
        ],
      );

      final setRows = await db.select(db.setLogs).get();
      expect(setRows.length, 1);
      final set = setRows.first;
      expect(set.restTimeSeconds, 180);
      expect(set.isCompleted, isFalse);
      expect(set.logOrder, 2);
      expect(set.notes, 'paused reps');
      expect(set.distance, closeTo(0.1, 0.0001));
      expect(set.durationSeconds, 75);
      expect(set.rpe, 9);
      expect(set.rir, 1);
    });

    test(
        'backup payload contains critical persistence domains and changed values',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('targetSugar', 42);
      await prefs.setInt('targetFiber', 28);
      await prefs.setInt('targetSalt', 6);
      await prefs.setBool('ai_enabled', true);
      await prefs.setString('ai_selected_provider', 'openai');
      await prefs.setString('ai_selected_model_openai', 'gpt-5.4');

      await dbHelper.saveUserProfile(
        name: 'Taylor',
        birthday: DateTime(1994, 8, 12),
        height: 176,
        gender: 'female',
      );
      await dbHelper.saveUserGoals(
        calories: 2300,
        protein: 165,
        carbs: 240,
        fat: 72,
        water: 2900,
        steps: 9200,
      );
      await dbHelper.insertMeasurementSession(
        MeasurementSession(
          timestamp: DateTime(2026, 4, 3, 7, 45),
          measurements: [
            Measurement(
              sessionId: 0,
              type: 'weight',
              value: 78.4,
              unit: 'kg',
            ),
          ],
        ),
      );

      final payload = await backupManager.generateBackupPayloadForTesting();

      expect(payload['schemaVersion'], BackupManager.currentSchemaVersion);
      expect(payload['foodEntries'], isA<List<dynamic>>());
      expect(payload['mealTemplates'], isA<List<dynamic>>());
      expect(payload['fluidEntries'], isA<List<dynamic>>());
      expect(payload['favoriteBarcodes'], isA<List<dynamic>>());
      expect(payload['customFoodItems'], isA<List<dynamic>>());
      expect(payload['measurementSessions'], isA<List<dynamic>>());
      expect(payload['dailyGoalsHistory'], isA<List<dynamic>>());
      expect(payload['appSettings'], isA<Map<String, dynamic>>());
      expect(payload['profile'], isA<Map<String, dynamic>>());
      expect(payload['userPreferences'], isA<Map<String, dynamic>>());
      expect(payload['healthStepSegments'], isA<List<dynamic>>());

      final appSettings = payload['appSettings'] as Map<String, dynamic>;
      expect(appSettings['targetCalories'], 2300);
      expect(appSettings['targetProtein'], 165);
      expect(appSettings['targetCarbs'], 240);
      expect(appSettings['targetFat'], 72);
      expect(appSettings['targetWater'], 2900);
      expect(appSettings['targetSteps'], 9200);

      final userPreferences =
          payload['userPreferences'] as Map<String, dynamic>;
      expect(userPreferences['targetSugar'], 42);
      expect(userPreferences['targetFiber'], 28);
      expect(userPreferences['targetSalt'], 6);
      expect(userPreferences['ai_enabled'], isTrue);
      expect(userPreferences['ai_selected_provider'], 'openai');
      expect(userPreferences['ai_selected_model_openai'], 'gpt-5.4');
    });

    test('restore preserves daily goals history timestamps and target values',
        () async {
      final payload = <String, dynamic>{
        'schemaVersion': BackupManager.currentSchemaVersion,
        'foodEntries': const <dynamic>[],
        'mealTemplates': const <dynamic>[],
        'fluidEntries': const <dynamic>[],
        'favoriteBarcodes': const <dynamic>[],
        'customFoodItems': const <dynamic>[],
        'measurementSessions': const <dynamic>[],
        'routines': const <dynamic>[],
        'workoutLogs': const <dynamic>[],
        'userPreferences': const <String, dynamic>{},
        'supplements': const <dynamic>[],
        'supplementLogs': const <dynamic>[],
        'customExercises': const <dynamic>[],
        'supplementSettingsHistory': const <dynamic>[],
        'dailyGoalsHistory': <Map<String, dynamic>>[
          <String, dynamic>{
            'targetCalories': 2100,
            'targetProtein': 155,
            'targetCarbs': 210,
            'targetFat': 68,
            'targetWater': 2600,
            'targetSteps': 7000,
            'createdAt': '2026-01-10T08:30:00.000Z',
          },
          <String, dynamic>{
            'targetCalories': 2400,
            'targetProtein': 175,
            'targetCarbs': 250,
            'targetFat': 78,
            'targetWater': 3100,
            'targetSteps': 9500,
            'createdAt': '2026-03-05T18:15:00.000Z',
          },
        ],
        'appSettings': <String, dynamic>{
          'userId': 'hist-user-1',
          'themeMode': 'system',
          'unitSystem': 'metric',
          'targetCalories': 2400,
          'targetProtein': 175,
          'targetCarbs': 250,
          'targetFat': 78,
          'targetWater': 3100,
          'targetSteps': 9500,
        },
        'profile': null,
        'healthStepSegments': const <dynamic>[],
      };

      final imported =
          await backupManager.importBackupPayloadForTesting(payload);
      expect(imported, isTrue);

      final historyRows = await (db.select(db.dailyGoalsHistory)
            ..orderBy([(t) => drift.OrderingTerm.asc(t.createdAt)]))
          .get();

      expect(historyRows.length, 2);
      expect(historyRows[0].targetCalories, 2100);
      expect(historyRows[0].targetSteps, 7000);
      expect(
        historyRows[0].createdAt.toUtc(),
        DateTime.parse('2026-01-10T08:30:00.000Z').toUtc(),
      );

      expect(historyRows[1].targetCalories, 2400);
      expect(historyRows[1].targetSteps, 9500);
      expect(
        historyRows[1].createdAt.toUtc(),
        DateTime.parse('2026-03-05T18:15:00.000Z').toUtc(),
      );
    });
  });
}
