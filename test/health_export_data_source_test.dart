import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart';
import 'package:hypertrack/health_export/data/health_export_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthExportDataSource', () {
    late AppDatabase db;
    late DatabaseHelper dbHelper;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(db);
      await _seed(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('maps supported domains with normalized units and stable keys',
        () async {
      final source = HealthExportDataSource(
        databaseHelper: dbHelper,
      );
      final payload = await source.loadPayload(lookbackDays: 10);

      expect(payload.measurements, isNotEmpty);
      final weight = payload.measurements.firstWhere(
        (record) => record.type.name == 'weight',
      );
      expect(weight.value, closeTo(80, 0.001));
      expect(weight.idempotencyKey, startsWith('measurement:'));

      final bodyFat = payload.measurements.firstWhere(
        (record) => record.type.name == 'bodyFatPercentage',
      );
      expect(bodyFat.value, 15);

      expect(payload.nutrition, isNotEmpty);
      final nutrition = payload.nutrition.first;
      expect(nutrition.caloriesKcal, closeTo(300, 0.001));
      expect(nutrition.sodiumGrams, closeTo(0.384, 0.001));
      expect(nutrition.idempotencyKey, startsWith('nutrition_entry:'));

      expect(payload.hydration, isNotEmpty);
      final hydration = payload.hydration.first;
      expect(hydration.volumeLiters, closeTo(0.75, 0.001));
      expect(hydration.idempotencyKey, startsWith('hydration_entry:'));

      expect(payload.workouts, isNotEmpty);
      final workout = payload.workouts.first;
      expect(workout.workoutType.name, 'strength');
      expect(workout.idempotencyKey, startsWith('workout_session:'));
      expect(workout.startZoneOffsetMinutes, isNotNull);
      expect(workout.endZoneOffsetMinutes, isNotNull);
      expect(
        workout.notes,
        'Session note\n\n'
        'Kurzhantelbankdrücken — W 20kg x 20, W 30kg x 8, W 40kg x 3, S 45kg x 8, F 45kg x 8\n'
        'Brustpresse — S 80kg x 12, S 90kg x 10, D 70kg x 8\n'
        'Seitheben — S 12kg x 15, S 12kg x 14, F 10kg x 16',
      );
    });
  });
}

Future<void> _seed(AppDatabase db) async {
  final now = DateTime.now().toUtc();
  await db.into(db.products).insert(
        const ProductsCompanion(
          barcode: drift.Value('prod-1'),
          name: drift.Value('Protein Bar'),
          calories: drift.Value(250),
          protein: drift.Value(20),
          carbs: drift.Value(30),
          fat: drift.Value(10),
          fiber: drift.Value(5),
          sugar: drift.Value(12),
          salt: drift.Value(0.8),
          source: drift.Value('user'),
        ),
      );

  await db.into(db.nutritionLogs).insert(
        NutritionLogsCompanion(
          consumedAt: drift.Value(now.subtract(const Duration(days: 1))),
          amount: const drift.Value(120),
          mealType: const drift.Value('Snack'),
          legacyBarcode: const drift.Value('prod-1'),
        ),
      );

  await db.into(db.fluidLogs).insert(
        FluidLogsCompanion(
          consumedAt: drift.Value(now.subtract(const Duration(days: 1))),
          amountMl: const drift.Value(750),
          name: const drift.Value('Water'),
        ),
      );

  await db.into(db.measurements).insert(
        MeasurementsCompanion(
          date: drift.Value(now.subtract(const Duration(days: 1))),
          type: const drift.Value('weight'),
          value: const drift.Value(80),
          unit: const drift.Value('kg'),
          legacySessionId: const drift.Value(10),
        ),
      );
  await db.into(db.measurements).insert(
        MeasurementsCompanion(
          date: drift.Value(now.subtract(const Duration(days: 1))),
          type: const drift.Value('fat_percent'),
          value: const drift.Value(15),
          unit: const drift.Value('%'),
          legacySessionId: const drift.Value(10),
        ),
      );

  final workout = await db.into(db.workoutLogs).insertReturning(
        WorkoutLogsCompanion(
          startTime: drift.Value(now.subtract(const Duration(hours: 2))),
          endTime: drift.Value(now.subtract(const Duration(hours: 1))),
          status: const drift.Value('completed'),
          routineNameSnapshot: const drift.Value('Gym Strength'),
          notes: const drift.Value('Session note'),
        ),
      );
  await db.batch((batch) {
    batch.insertAll(
      db.setLogs,
      [
        SetLogsCompanion(
          workoutLogId: drift.Value(workout.id),
          exerciseNameSnapshot: const drift.Value('Kurzhantelbankdrücken'),
          setType: const drift.Value('warmup'),
          weight: const drift.Value(20),
          reps: const drift.Value(20),
          isCompleted: const drift.Value(true),
          logOrder: const drift.Value(0),
        ),
        SetLogsCompanion(
          workoutLogId: drift.Value(workout.id),
          exerciseNameSnapshot: const drift.Value('Kurzhantelbankdrücken'),
          setType: const drift.Value('warmup'),
          weight: const drift.Value(30),
          reps: const drift.Value(8),
          isCompleted: const drift.Value(true),
          logOrder: const drift.Value(1),
        ),
        SetLogsCompanion(
          workoutLogId: drift.Value(workout.id),
          exerciseNameSnapshot: const drift.Value('Kurzhantelbankdrücken'),
          setType: const drift.Value('warmup'),
          weight: const drift.Value(40),
          reps: const drift.Value(3),
          isCompleted: const drift.Value(true),
          logOrder: const drift.Value(2),
        ),
        SetLogsCompanion(
          workoutLogId: drift.Value(workout.id),
          exerciseNameSnapshot: const drift.Value('Kurzhantelbankdrücken'),
          setType: const drift.Value('normal'),
          weight: const drift.Value(45),
          reps: const drift.Value(8),
          isCompleted: const drift.Value(true),
          logOrder: const drift.Value(3),
        ),
        SetLogsCompanion(
          workoutLogId: drift.Value(workout.id),
          exerciseNameSnapshot: const drift.Value('Kurzhantelbankdrücken'),
          setType: const drift.Value('failure'),
          weight: const drift.Value(45),
          reps: const drift.Value(8),
          isCompleted: const drift.Value(true),
          logOrder: const drift.Value(4),
        ),
        SetLogsCompanion(
          workoutLogId: drift.Value(workout.id),
          exerciseNameSnapshot: const drift.Value('Brustpresse'),
          setType: const drift.Value('normal'),
          weight: const drift.Value(80),
          reps: const drift.Value(12),
          isCompleted: const drift.Value(true),
          logOrder: const drift.Value(5),
        ),
        SetLogsCompanion(
          workoutLogId: drift.Value(workout.id),
          exerciseNameSnapshot: const drift.Value('Brustpresse'),
          setType: const drift.Value('normal'),
          weight: const drift.Value(90),
          reps: const drift.Value(10),
          isCompleted: const drift.Value(true),
          logOrder: const drift.Value(6),
        ),
        SetLogsCompanion(
          workoutLogId: drift.Value(workout.id),
          exerciseNameSnapshot: const drift.Value('Brustpresse'),
          setType: const drift.Value('dropset'),
          weight: const drift.Value(70),
          reps: const drift.Value(8),
          isCompleted: const drift.Value(true),
          logOrder: const drift.Value(7),
        ),
        SetLogsCompanion(
          workoutLogId: drift.Value(workout.id),
          exerciseNameSnapshot: const drift.Value('Seitheben'),
          setType: const drift.Value('normal'),
          weight: const drift.Value(12),
          reps: const drift.Value(15),
          isCompleted: const drift.Value(true),
          logOrder: const drift.Value(8),
        ),
        SetLogsCompanion(
          workoutLogId: drift.Value(workout.id),
          exerciseNameSnapshot: const drift.Value('Seitheben'),
          setType: const drift.Value('normal'),
          weight: const drift.Value(12),
          reps: const drift.Value(14),
          isCompleted: const drift.Value(true),
          logOrder: const drift.Value(9),
        ),
        SetLogsCompanion(
          workoutLogId: drift.Value(workout.id),
          exerciseNameSnapshot: const drift.Value('Seitheben'),
          setType: const drift.Value('failure'),
          weight: const drift.Value(10),
          reps: const drift.Value(16),
          isCompleted: const drift.Value(true),
          logOrder: const drift.Value(10),
        ),
      ],
    );
  });
}
