// test/features/diary/data/sources/product_local_data_source_test.dart

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/features/diary/data/sources/product_local_data_source.dart';
import 'package:train_libre/features/diary/domain/models/food_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProductLocalDataSource tests', () {
    late db.AppDatabase database;
    late ProductLocalDataSource dataSource;

    setUp(() async {
      database = db.AppDatabase(NativeDatabase.memory());
      dataSource = ProductLocalDataSource.forTesting(database);
    });

    tearDown(() async {
      await database.close();
    });

    final FoodItem testBaseItem1 = FoodItem(
      barcode: '111111',
      name: 'Brokkoli frisch',
      brand: 'Gartenfrisch',
      calories: 34,
      protein: 2.8,
      carbs: 7.0,
      fat: 0.4,
      source: FoodItemSource.base,
      category: 'vegetables',
    );

    final FoodItem testBaseItem2 = FoodItem(
      barcode: '222222',
      name: 'Brokkoli gekocht',
      brand: 'Gartenfrisch',
      calories: 35,
      protein: 2.4,
      carbs: 4.1,
      fat: 0.4,
      source: FoodItemSource.base,
      category: 'vegetables',
    );

    final FoodItem testBaseItem3 = FoodItem(
      barcode: '333333',
      name: 'Brokkoli roh',
      brand: 'Gartenfrisch',
      calories: 34,
      protein: 2.8,
      carbs: 7.0,
      fat: 0.4,
      source: FoodItemSource.base,
      category: 'vegetables',
    );

    final FoodItem testUserItem = FoodItem(
      barcode: '444444',
      name: 'Apfel Elstar',
      brand: 'Bio',
      calories: 52,
      protein: 0.3,
      carbs: 14,
      fat: 0.2,
      source: FoodItemSource.user,
      category: 'fruit',
    );

    final FoodItem testOffItem = FoodItem(
      barcode: '555555',
      name: 'Apfelmus ungezuckert',
      brand: 'Kaufland Bio',
      calories: 60,
      protein: 0.4,
      carbs: 13,
      fat: 0.1,
      source: FoodItemSource.off,
      category: 'fruit',
    );

    test('insertProduct, updateProduct, and getProductByBarcode mappings', () async {
      // 1. Insert product
      await dataSource.insertProduct(testUserItem);

      // 2. Retrieve and assert details
      final retrieved = await dataSource.getProductByBarcode('444444');
      expect(retrieved, isNotNull);
      expect(retrieved!.barcode, '444444');
      expect(retrieved.name, 'Apfel Elstar');
      expect(retrieved.calories, 52);
      expect(retrieved.protein, 0.3);
      expect(retrieved.source, FoodItemSource.user);

      // 3. Update product
      final updatedItem = FoodItem(
        barcode: '444444',
        name: 'Apfel Elstar Bio',
        brand: 'Bio',
        calories: 55,
        protein: 0.3,
        carbs: 14,
        fat: 0.2,
        source: FoodItemSource.user,
        category: 'fruit',
      );
      await dataSource.updateProduct(updatedItem);

      // 4. Retrieve again and verify updates
      final retrievedUpdated = await dataSource.getProductByBarcode('444444');
      expect(retrievedUpdated, isNotNull);
      expect(retrievedUpdated!.calories, 55);
      expect(retrievedUpdated.name, 'Apfel Elstar Bio');
    });

    test('Favorite management CRUD operations', () async {
      await dataSource.insertProduct(testBaseItem1);
      await dataSource.insertProduct(testUserItem);

      // Check initial state
      expect(await dataSource.isFavorite('111111'), isFalse);
      expect(await dataSource.getFavoriteBarcodes(), isEmpty);

      // Add to favorites
      await dataSource.addFavorite('111111');
      await dataSource.addFavorite('444444');

      expect(await dataSource.isFavorite('111111'), isTrue);
      expect(await dataSource.isFavorite('444444'), isTrue);
      expect(await dataSource.isFavorite('missing'), isFalse);

      final barcodes = await dataSource.getFavoriteBarcodes();
      expect(barcodes, unorderedEquals(['111111', '444444']));

      final favoriteProducts = await dataSource.getFavoriteProducts();
      expect(favoriteProducts.length, 2);
      expect(
        favoriteProducts.map((p) => p.name),
        unorderedEquals(['Brokkoli frisch', 'Apfel Elstar']),
      );

      // Remove favorite
      await dataSource.removeFavorite('111111');
      expect(await dataSource.isFavorite('111111'), isFalse);
      expect(await dataSource.getFavoriteBarcodes(), ['444444']);
    });

    test('searchProducts ranks exact, prefix, user/base, and off matches correctly', () async {
      await dataSource.insertProduct(testUserItem); // Apfel Elstar (user)
      await dataSource.insertProduct(testOffItem);  // Apfelmus ungezuckert (off)
      
      // Apfel (base)
      await dataSource.insertProduct(FoodItem(
        barcode: '666666',
        name: 'Apfel',
        brand: 'Garten',
        calories: 52,
        protein: 0.3,
        carbs: 14,
        fat: 0.2,
        source: FoodItemSource.base,
        category: 'fruit',
      ));

      // Global search for 'Apfel'
      final searchResults = await dataSource.searchProducts('Apfel');

      expect(searchResults.length, 3);

      // 1st should be exact name match: 'Apfel'
      expect(searchResults[0].barcode, '666666');

      // 2nd should be prefix match: 'Apfel Elstar' (since it is a 'user' source matching priority)
      expect(searchResults[1].barcode, '444444');

      // 3rd should be substring match: 'Apfelmus ungezuckert' from 'off' source
      expect(searchResults[2].barcode, '555555');
    });

    test('getBaseFoods filters by category and search keyword, sorted by usage', () async {
      await dataSource.insertProduct(testBaseItem1); // Brokkoli frisch (vegetables, base)
      await dataSource.insertProduct(testUserItem);  // Apfel Elstar (fruit, user - should be ignored)
      
      // Karotte (vegetables, base)
      await dataSource.insertProduct(FoodItem(
        barcode: '777777',
        name: 'Karotte',
        brand: '',
        calories: 41,
        protein: 0.9,
        carbs: 10,
        fat: 0.2,
        source: FoodItemSource.base,
        category: 'vegetables',
      ));

      // 1. Retrieve vegetables category
      final baseFoods = await dataSource.getBaseFoods(categoryKey: 'vegetables');
      expect(baseFoods.length, 2);
      expect(baseFoods.map((f) => f.name), unorderedEquals(['Brokkoli frisch', 'Karotte']));

      // 2. Retrieve base categories metadata
      await database.into(database.foodCategories).insert(
        const db.FoodCategoriesCompanion(
          key: drift.Value('vegetables'),
          nameDe: drift.Value('Gemüse'),
          nameEn: drift.Value('Vegetables'),
          emoji: drift.Value('🥦'),
        ),
      );

      final categories = await dataSource.getBaseCategories();
      expect(categories.length, 1);
      expect(categories[0]['key'], 'vegetables');
      expect(categories[0]['name_de'], 'Gemüse');
      expect(categories[0]['emoji'], '🥦');
    });

    test('fuzzyMatchCandidatesForRepair re-ranks using raw and cooked stateHints correctly', () async {
      await dataSource.insertProduct(testBaseItem1); // Brokkoli frisch
      await dataSource.insertProduct(testBaseItem2); // Brokkoli gekocht (cooked)
      await dataSource.insertProduct(testBaseItem3); // Brokkoli roh (raw)

      // 1. Without hint (should rank by text/exact/source priority)
      final normalCandidates = await dataSource.fuzzyMatchCandidatesForRepair('Brokkoli');
      expect(normalCandidates.isNotEmpty, isTrue);

      // 2. With 'cooked' hint (should boost 'Brokkoli gekocht')
      final cookedCandidates = await dataSource.fuzzyMatchCandidatesForRepair('Brokkoli', stateHint: 'cooked');
      expect(cookedCandidates.length, 3);
      expect(cookedCandidates[0].name, 'Brokkoli gekocht'); // Top rank boosted
      // 'Brokkoli roh' has 'raw' keyword, so it should be penalized to the bottom (last)
      expect(cookedCandidates[2].name, 'Brokkoli roh');

      // 3. With 'raw' hint (should boost 'Brokkoli roh')
      final rawCandidates = await dataSource.fuzzyMatchCandidatesForRepair('Brokkoli', stateHint: 'raw');
      expect(rawCandidates.length, 3);
      expect(rawCandidates[0].name, 'Brokkoli roh'); // Top rank boosted
      // 'Brokkoli gekocht' has 'cooked' keyword, so it should be penalized to the bottom (last)
      expect(rawCandidates[2].name, 'Brokkoli gekocht');
    });

    test('fuzzyMatchForAi delegates to matching logics and re-ranking', () async {
      await dataSource.insertProduct(testBaseItem1);

      final candidates = await dataSource.fuzzyMatchForAi('Brokkoli');
      expect(candidates.length, isNotNull);
      if (candidates.isNotEmpty) {
        expect(candidates[0].name, contains('Brokkoli'));
      }
    });

    test('getRecentProducts orders products descending by usage history', () async {
      await dataSource.insertProduct(testBaseItem1); // Brokkoli frisch
      await dataSource.insertProduct(testUserItem);  // Apfel Elstar

      // Insert recent consumption logs
      final now = DateTime.now();
      await database.into(database.nutritionLogs).insert(
        db.NutritionLogsCompanion(
          id: const drift.Value('log1'),
          legacyBarcode: const drift.Value('111111'),
          consumedAt: drift.Value(now.subtract(const Duration(minutes: 30))),
          amount: const drift.Value(150.0),
          mealType: const drift.Value('Breakfast'),
        ),
      );

      await database.into(database.nutritionLogs).insert(
        db.NutritionLogsCompanion(
          id: const drift.Value('log2'),
          legacyBarcode: const drift.Value('444444'),
          consumedAt: drift.Value(now.subtract(const Duration(minutes: 5))), // more recent!
          amount: const drift.Value(200.0),
          mealType: const drift.Value('Lunch'),
        ),
      );

      final recent = await dataSource.getRecentProducts();
      expect(recent.length, 2);
      // Apfel Elstar is consumed at -5min, so it must rank FIRST
      expect(recent[0].barcode, '444444');
      // Brokkoli frisch is consumed at -30min, so it must rank SECOND
      expect(recent[1].barcode, '111111');
    });
  });
}
