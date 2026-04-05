import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart';
import 'package:hypertrack/data/product_database_helper.dart';
import 'package:hypertrack/features/statistics/data/body_nutrition_analytics_data_adapter.dart';
import 'package:hypertrack/models/fluid_entry.dart';
import 'package:hypertrack/models/food_entry.dart';
import 'package:hypertrack/models/food_item.dart';
import 'package:hypertrack/models/measurement.dart' as model;
import 'package:hypertrack/models/measurement_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BodyNutritionAnalyticsDataAdapter.fetch', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;
    late ProductDatabaseHelper productHelper;
    late BodyNutritionAnalyticsDataAdapter adapter;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
      productHelper =
          ProductDatabaseHelper.forTesting(databaseHelper: dbHelper);
      adapter = BodyNutritionAnalyticsDataAdapter(
        databaseHelper: dbHelper,
        productDatabaseHelper: productHelper,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('all-time range uses earliest relevant date and aggregates calories',
        () async {
      final measurementDate = DateTime(2026, 4, 1, 7, 15);
      final foodDate = DateTime(2026, 4, 2, 12, 00);
      final fluidDate = DateTime(2026, 4, 3, 18, 00);

      await dbHelper.insertMeasurementSession(
        MeasurementSession(
          timestamp: measurementDate,
          measurements: [
            model.Measurement(
              sessionId: 0,
              type: 'weight',
              value: 80.0,
              unit: 'kg',
            ),
          ],
        ),
      );

      await productHelper.insertProduct(
        FoodItem(
          barcode: 'known',
          name: 'Known Product',
          calories: 200,
          protein: 0,
          carbs: 0,
          fat: 0,
          source: FoodItemSource.user,
        ),
      );

      await dbHelper.insertFoodEntry(
        FoodEntry(
          barcode: 'known',
          timestamp: foodDate,
          quantityInGrams: 150,
          mealType: 'Lunch',
        ),
      );
      await dbHelper.insertFoodEntry(
        FoodEntry(
          barcode: 'unknown',
          timestamp: foodDate,
          quantityInGrams: 100,
          mealType: 'Lunch',
        ),
      );
      await dbHelper.insertFluidEntry(
        FluidEntry(
          timestamp: foodDate,
          quantityInMl: 500,
          name: 'Juice',
          kcal: 120,
        ),
      );
      await dbHelper.insertFluidEntry(
        FluidEntry(
          timestamp: fluidDate,
          quantityInMl: 400,
          name: 'Soda',
          kcal: 80,
        ),
      );

      final result = await adapter.fetch(
        rangeIndex: 4, // all-time
        now: DateTime(2026, 4, 5, 9, 30),
      );

      expect(result.range.start, DateTime(2026, 4, 1));
      expect(result.range.end, DateTime(2026, 4, 5, 23, 59, 59));
      expect(result.weightPoints.length, 1);
      expect(result.weightPoints.first.date, measurementDate);
      expect(result.weightPoints.first.value, 80.0);
      expect(result.caloriesByDay[DateTime(2026, 4, 2)], closeTo(420.0, 0.001));
      expect(result.caloriesByDay[DateTime(2026, 4, 3)], closeTo(80.0, 0.001));
    });

    test('all-time range without data falls back to current day only',
        () async {
      final now = DateTime(2026, 4, 10, 14, 00);

      final result = await adapter.fetch(rangeIndex: 4, now: now);

      expect(result.range.start, DateTime(2026, 4, 10));
      expect(result.range.end, DateTime(2026, 4, 10, 23, 59, 59));
      expect(result.weightPoints, isEmpty);
      expect(result.caloriesByDay, isEmpty);
    });

    test('non-all-time range honors selected window semantics', () async {
      await dbHelper.insertMeasurementSession(
        MeasurementSession(
          timestamp: DateTime(2026, 3, 1, 8, 00),
          measurements: [
            model.Measurement(
              sessionId: 0,
              type: 'weight',
              value: 82.0,
              unit: 'kg',
            ),
          ],
        ),
      );

      final result = await adapter.fetch(
        rangeIndex: 0, // 7 days
        now: DateTime(2026, 4, 10, 9, 00),
      );

      expect(result.range.start, DateTime(2026, 4, 4));
      expect(result.range.end, DateTime(2026, 4, 10, 23, 59, 59));
      expect(result.weightPoints, isEmpty);
    });
  });
}
