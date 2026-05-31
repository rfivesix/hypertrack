import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/features/diary/data/sources/product_local_data_source.dart';
import 'package:train_libre/features/diary/domain/models/food_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue #421: Beverage/Fluid Ingestion Mapping', () {
    late db.AppDatabase database;

    setUp(() {
      database = db.AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    // Helper to invoke private _mapProductRow via the visibleForTesting helper
    dynamic mapProductRowHelper(Map<String, dynamic> row, String sourceLabel) {
      return BasisDataManager.instance.mapProductRowForTesting(row, sourceLabel: sourceLabel);
    }

    test('default fallback isFluid is false', () {
      final row = {
        'barcode': '123',
        'name': 'Solid Apple',
        'calories': 52,
        'protein': 0.3,
        'carbs': 14.0,
        'fat': 0.2,
      };
      final db.ProductsCompanion companion = mapProductRowHelper(row, 'off');
      expect(companion.isFluid.value, isFalse);
    });

    test('isFluid is false when nutrition baseline token contains 100g', () {
      final row = {
        'barcode': '123',
        'name': 'Apple Puree',
        'calories': 52,
        'protein': 0.3,
        'carbs': 14.0,
        'fat': 0.2,
        'nutrition_data_per': '100g',
        'is_fluid': 1, // Stale column value that should be overridden
      };
      final db.ProductsCompanion companion = mapProductRowHelper(row, 'off');
      expect(companion.isFluid.value, isFalse);
    });

    test('isFluid is true when nutrition baseline token contains 100ml', () {
      final row = {
        'barcode': '456',
        'name': 'Orange Juice',
        'calories': 45,
        'protein': 0.7,
        'carbs': 10.4,
        'fat': 0.2,
        'nutrition_data_prepared_per': '100ml',
      };
      final db.ProductsCompanion companion = mapProductRowHelper(row, 'off');
      expect(companion.isFluid.value, isTrue);
    });

    test('isFluid is true when category contains beverages, drinks, or waters tags', () {
      final row1 = {
        'barcode': '789',
        'name': 'Cola',
        'calories': 40,
        'protein': 0.0,
        'carbs': 10.0,
        'fat': 0.0,
        'category': 'en:beverages',
      };
      final db.ProductsCompanion companion1 = mapProductRowHelper(row1, 'off');
      expect(companion1.isFluid.value, isTrue);

      final row2 = {
        'barcode': '7892',
        'name': 'Energy Drink',
        'calories': 45,
        'protein': 0.0,
        'carbs': 11.0,
        'fat': 0.0,
        'categories_tags': 'en:drinks',
      };
      final db.ProductsCompanion companion2 = mapProductRowHelper(row2, 'off');
      expect(companion2.isFluid.value, isTrue);

      final row3 = {
        'barcode': '7893',
        'name': 'Mineral Water',
        'calories': 0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'categories': 'en:waters',
      };
      final db.ProductsCompanion companion3 = mapProductRowHelper(row3, 'off');
      expect(companion3.isFluid.value, isTrue);
    });
  });

  group('Issue #423: EAN Master Record Overrides', () {
    late db.AppDatabase database;
    late ProductLocalDataSource productDb;

    setUp(() {
      database = db.AppDatabase(NativeDatabase.memory());
      productDb = ProductLocalDataSource.forTesting(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('prioritizes user overrides over static OFF catalog records', () async {
      // 1. Insert static uncorrected OFF item
      final barcode = '4012345678901';
      await database.into(database.products).insert(
            db.ProductsCompanion.insert(
              barcode: barcode,
              name: 'Monster Ultra (Uncorrected)',
              calories: 2,
              protein: 0.0,
              carbs: 0.9,
              fat: 0.0,
              source: const drift.Value('off'),
              isFluid: const drift.Value(false),
            ),
          );

      // Verify base fetch retrieves uncorrected values
      final initialItem = await productDb.getProductByBarcode(barcode);
      expect(initialItem, isNotNull);
      expect(initialItem!.name, 'Monster Ultra (Uncorrected)');
      expect(initialItem.isFluid, isFalse);

      // 2. Perform custom user modifications (updates caffeine, fluid status, Net Qty)
      final modifiedItem = FoodItem(
        barcode: barcode,
        name: 'Monster Ultra',
        brand: 'Monster Energy',
        calories: 3,
        protein: 0.1,
        carbs: 1.1,
        fat: 0.0,
        source: FoodItemSource.off,
        isFluid: true,
        caffeineMgPer100ml: 32.0,
        productQuantity: 500.0,
        productQuantityUnit: 'ml',
      );

      // Save using updateProduct (which executes an automatic upsert into user_food_overrides)
      await productDb.updateProduct(modifiedItem);

      // Verify that user_food_overrides table has the record saved
      final overrideRow = await (database.select(database.userFoodOverrides)
            ..where((tbl) => tbl.barcode.equals(barcode)))
          .getSingle();
      expect(overrideRow.name, 'Monster Ultra');
      expect(overrideRow.caffeine, 32.0);
      expect(overrideRow.isFluid, isTrue);

      // 3. Verify repository lookups prioritize the overrides!
      final fetchedItem = await productDb.getProductByBarcode(barcode);
      expect(fetchedItem, isNotNull);
      expect(fetchedItem!.name, 'Monster Ultra');
      expect(fetchedItem.brand, 'Monster Energy');
      expect(fetchedItem.calories, 3);
      expect(fetchedItem.protein, 0.1);
      expect(fetchedItem.carbs, 1.1);
      expect(fetchedItem.isFluid, isTrue);
      expect(fetchedItem.caffeineMgPer100ml, 32.0);
      expect(fetchedItem.productQuantity, 500.0);
      expect(fetchedItem.productQuantityUnit, 'ml');

      // Verify batch lookup also prioritizes the override
      final batchFetched = await productDb.getProductsByBarcodes([barcode]);
      expect(batchFetched.first.name, 'Monster Ultra');
      expect(batchFetched.first.caffeineMgPer100ml, 32.0);

      // Verify global search prioritized overrides
      final searchResult = await productDb.searchProducts('Monster');
      expect(searchResult.first.name, 'Monster Ultra');
      expect(searchResult.first.caffeineMgPer100ml, 32.0);
    });
  });
}
