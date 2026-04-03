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

    test('maps supported domains with normalized units and stable keys', () async {
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
      expect(nutrition.sodiumGrams, closeTo(1.2, 0.001));
      expect(nutrition.idempotencyKey, startsWith('nutrition_entry:'));

      expect(payload.hydration, isNotEmpty);
      final hydration = payload.hydration.first;
      expect(hydration.volumeLiters, closeTo(0.75, 0.001));
      expect(hydration.idempotencyKey, startsWith('hydration_entry:'));

      expect(payload.workouts, isNotEmpty);
      final workout = payload.workouts.first;
      expect(workout.workoutType.name, 'strength');
      expect(workout.idempotencyKey, startsWith('workout_session:'));
    });
  });
}

Future<void> _seed(AppDatabase db) async {
  final now = DateTime.now().toUtc();
  await db.into(db.products).insert(
        ProductsCompanion(
          barcode: const drift.Value('prod-1'),
          name: const drift.Value('Protein Bar'),
          calories: const drift.Value(250),
          protein: const drift.Value(20),
          carbs: const drift.Value(30),
          fat: const drift.Value(10),
          fiber: const drift.Value(5),
          sugar: const drift.Value(12),
          salt: const drift.Value(0.8),
          source: const drift.Value('user'),
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
          type: const drift.Value('body fat'),
          value: const drift.Value(15),
          unit: const drift.Value('%'),
          legacySessionId: const drift.Value(10),
        ),
      );

  await db.into(db.workoutLogs).insert(
        WorkoutLogsCompanion(
          startTime: drift.Value(now.subtract(const Duration(hours: 2))),
          endTime: drift.Value(now.subtract(const Duration(hours: 1))),
          status: const drift.Value('completed'),
          routineNameSnapshot: const drift.Value('Gym Strength'),
        ),
      );
}
