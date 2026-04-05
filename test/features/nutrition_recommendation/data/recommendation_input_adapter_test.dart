import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart'
    show AppDatabase, NutritionLogsCompanion, ProductsCompanion;
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_input_adapter.dart';
import 'package:hypertrack/models/fluid_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecommendationInputAdapter', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;
    late RecommendationInputAdapter adapter;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
      adapter = RecommendationInputAdapter(databaseHelper: dbHelper);
    });

    tearDown(() async {
      await database.close();
    });

    test(
        'buildInput uses productId first, falls back to barcode, merges fluid kcal, and flags unresolved rows',
        () async {
      final byIdProduct =
          await database.into(database.products).insertReturning(
                const ProductsCompanion(
                  barcode: drift.Value('id-product'),
                  name: drift.Value('ID Product'),
                  calories: drift.Value(220),
                  protein: drift.Value(10),
                  carbs: drift.Value(20),
                  fat: drift.Value(5),
                  source: drift.Value('base'),
                ),
              );
      await database.into(database.products).insertReturning(
            const ProductsCompanion(
              barcode: drift.Value('barcode-product'),
              name: drift.Value('Barcode Product'),
              calories: drift.Value(300),
              protein: drift.Value(10),
              carbs: drift.Value(20),
              fat: drift.Value(5),
              source: drift.Value('base'),
            ),
          );

      final day = DateTime(2026, 4, 5);

      await database.into(database.nutritionLogs).insert(
            NutritionLogsCompanion(
              productId: drift.Value(byIdProduct.id),
              consumedAt: drift.Value(DateTime(2026, 4, 5, 8, 0)),
              amount: const drift.Value(100.0),
              mealType: const drift.Value('mealtypeBreakfast'),
            ),
          );
      await database.into(database.nutritionLogs).insert(
            NutritionLogsCompanion(
              legacyBarcode: const drift.Value('barcode-product'),
              consumedAt: drift.Value(DateTime(2026, 4, 5, 13, 0)),
              amount: const drift.Value(50.0),
              mealType: const drift.Value('mealtypeLunch'),
            ),
          );
      await database.into(database.nutritionLogs).insert(
            NutritionLogsCompanion(
              productId: drift.Value(byIdProduct.id),
              legacyBarcode: const drift.Value('barcode-product'),
              consumedAt: drift.Value(DateTime(2026, 4, 5, 18, 0)),
              amount: const drift.Value(100.0),
              mealType: const drift.Value('mealtypeDinner'),
            ),
          );
      await database.into(database.nutritionLogs).insert(
            NutritionLogsCompanion(
              legacyBarcode: const drift.Value('missing-product'),
              consumedAt: drift.Value(DateTime(2026, 4, 5, 19, 0)),
              amount: const drift.Value(100.0),
              mealType: const drift.Value('mealtypeDinner'),
            ),
          );
      await dbHelper.insertFluidEntry(
        FluidEntry(
          timestamp: DateTime(2026, 4, 5, 20, 0),
          quantityInMl: 330,
          name: 'Soda',
          kcal: 80,
        ),
      );

      final input = await adapter.buildInput(now: day);

      expect(input.intakeLoggedDays, 1);
      expect(input.avgLoggedCalories, closeTo(670.0, 0.001));
      expect(input.qualityFlags, contains('unresolved_food_calories'));
    });
  });
}
