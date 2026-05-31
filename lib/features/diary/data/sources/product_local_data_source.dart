// lib/data/product_database_helper.dart

import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import '../../../../data/database_helper.dart';
import '../../../../data/drift_database.dart' as db;
import '../../../../config/app_data_sources.dart';
import '../../domain/models/food_item.dart';
import '../../../../services/catalog_file_migration.dart';
import '../../../../util/perf_debug_timer.dart';
import '../../domain/use_cases/evaluate_food_source_use_case.dart';

/// Helper class for managing food product data in the Drift database.
///
/// Provides methods for searching products, managing favorites, and retrieving
/// base foods from the katalog.
class ProductLocalDataSource {
  final db.AppDatabase _dbInstance;

  ProductLocalDataSource(this._dbInstance);

  static ProductLocalDataSource get instance =>
      DatabaseHelper.instance.productLocalDataSource;

  db.AppDatabase get dbInstance => _dbInstance;

  ProductLocalDataSource.forTesting(this._dbInstance);

  // Access to the central Drift instance
  Future<db.AppDatabase> get database async {
    return _dbInstance;
  }

  // --- MAPPING HELPERS ---

  List<String>? _parseJsonList(String? json) {
    if (json == null || json.isEmpty) return null;
    if (json.startsWith('[') && json.endsWith(']')) {
      return json
          .substring(1, json.length - 1)
          .split(',')
          .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ""))
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [json];
  }

  db.ProductsCompanion _mapModelToCompanion(FoodItem item) {
    return db.ProductsCompanion(
      barcode: Value(item.barcode),
      name: Value(item.name),
      nameDe: Value(item.nameDe),
      nameEn: Value(item.nameEn),
      brand: Value(item.brand),
      calories: Value(item.calories),
      protein: Value(item.protein),
      carbs: Value(item.carbs),
      fat: Value(item.fat),
      sugar: Value(item.sugar),
      fiber: Value(item.fiber),
      salt: Value(item.salt),
      caffeine: Value(item.caffeineMgPer100ml),
      caffeineMgPer100g: Value(item.caffeineMgPer100g),
      ingredientsText: Value(item.ingredientsText),
      ingredientsAnalysisTags: Value(_listToJson(item.ingredientsAnalysisTags)),
      additivesTags: Value(_listToJson(item.additivesTags)),
      productQuantity: Value(item.productQuantity),
      productQuantityUnit: Value(item.productQuantityUnit),
      isFluid: Value(item.isFluid),
      isLiquid: Value(item.isLiquid ?? false),
      source: Value(_sourceToString(item.source)),
      category: Value(item.category),
    );
  }

  String? _listToJson(List<String>? list) {
    if (list == null) return null;
    return '[${list.map((e) => '"$e"').join(',')}]';
  }

  String _sourceToString(FoodItemSource source) {
    switch (source) {
      case FoodItemSource.base:
        return 'base';
      case FoodItemSource.off:
        return 'off';
      case FoodItemSource.user:
        return 'user';
    }
  }



  FoodItem _mapRowAndOverrideToFoodItem(db.Product row, db.UserFoodOverride? overrideRow) {
    FoodItemSource source;
    switch (row.source) {
      case 'base':
        source = FoodItemSource.base;
        break;
      case 'off':
      case 'off_retained':
        source = FoodItemSource.off;
        break;
      default:
        source = FoodItemSource.user;
    }

    return FoodItem(
      barcode: row.barcode,
      name: overrideRow?.name ?? row.name,
      nameDe: overrideRow?.nameDe ?? row.nameDe ?? row.name,
      nameEn: overrideRow?.nameEn ?? row.nameEn ?? row.name,
      brand: overrideRow?.brand ?? row.brand ?? '',
      calories: overrideRow?.calories ?? row.calories,
      protein: overrideRow?.protein ?? row.protein,
      carbs: overrideRow?.carbs ?? row.carbs,
      fat: overrideRow?.fat ?? row.fat,
      source: source,
      category: overrideRow?.category ?? row.category,
      sugar: overrideRow?.sugar ?? row.sugar,
      fiber: overrideRow?.fiber ?? row.fiber,
      salt: overrideRow?.salt ?? row.salt,
      sodium: (overrideRow?.salt ?? row.salt) != null ? (overrideRow?.salt ?? row.salt)! / 2.5 : null,
      kj: ((overrideRow?.calories ?? row.calories) * 4.184),
      calcium: null,
      isLiquid: overrideRow?.isLiquid ?? row.isLiquid,
      isFluid: overrideRow?.isFluid ?? row.isFluid,
      caffeineMgPer100ml: overrideRow?.caffeine ?? row.caffeine,
      caffeineMgPer100g: overrideRow?.caffeineMgPer100g ?? row.caffeineMgPer100g,
      ingredientsText: overrideRow?.ingredientsText ?? row.ingredientsText,
      ingredientsAnalysisTags: _parseJsonList(overrideRow?.ingredientsAnalysisTags ?? row.ingredientsAnalysisTags),
      additivesTags: _parseJsonList(overrideRow?.additivesTags ?? row.additivesTags),
      productQuantity: overrideRow?.productQuantity ?? row.productQuantity,
      productQuantityUnit: overrideRow?.productQuantityUnit ?? row.productQuantityUnit,
    );
  }

  Future<List<FoodItem>> _enrichProductsWithOverrides(List<db.Product> rows) async {
    if (rows.isEmpty) return [];
    final dbInstance = await database;
    final barcodes = rows.map((r) => r.barcode).toList();

    final overrides = await (dbInstance.select(dbInstance.userFoodOverrides)
          ..where((tbl) => tbl.barcode.isIn(barcodes)))
        .get();

    final overrideMap = {for (final o in overrides) o.barcode: o};

    return rows.map((row) {
      final o = overrideMap[row.barcode];
      return _mapRowAndOverrideToFoodItem(row, o);
    }).toList();
  }

  // --- PUBLIC API ---

  /// Inserts a new product into the database or replaces an existing one with the same barcode.
  Future<void> insertProduct(FoodItem item) async {
    final dbInstance = await database;
    await dbInstance
        .into(dbInstance.products)
        .insert(_mapModelToCompanion(item), mode: InsertMode.insertOrReplace);
  }

  /// Updates an existing product's information in the database.
  Future<void> updateProduct(FoodItem item) async {
    final dbInstance = await database;
    await (dbInstance.update(dbInstance.products)
          ..where((tbl) => tbl.barcode.equals(item.barcode)))
        .write(_mapModelToCompanion(item));

    final overrideCompanion = db.UserFoodOverridesCompanion(
      barcode: Value(item.barcode),
      name: Value(item.name),
      nameDe: Value(item.nameDe),
      nameEn: Value(item.nameEn),
      brand: Value(item.brand),
      calories: Value(item.calories),
      protein: Value(item.protein),
      carbs: Value(item.carbs),
      fat: Value(item.fat),
      sugar: Value(item.sugar),
      fiber: Value(item.fiber),
      salt: Value(item.salt),
      caffeine: Value(item.caffeineMgPer100ml),
      caffeineMgPer100g: Value(item.caffeineMgPer100g),
      ingredientsText: Value(item.ingredientsText),
      ingredientsAnalysisTags: Value(_listToJson(item.ingredientsAnalysisTags)),
      additivesTags: Value(_listToJson(item.additivesTags)),
      productQuantity: Value(item.productQuantity),
      productQuantityUnit: Value(item.productQuantityUnit),
      isFluid: Value(item.isFluid),
      isLiquid: Value(item.isLiquid ?? false),
      category: Value(item.category),
    );

    await dbInstance
        .into(dbInstance.userFoodOverrides)
        .insertOnConflictUpdate(overrideCompanion);
  }

  /// Retrieves a list of [FoodItem]s matching the provided [barcodes].
  Future<List<FoodItem>> getProductsByBarcodes(List<String> barcodes) async {
    if (barcodes.isEmpty) return [];
    final stopwatch = Stopwatch()..start();
    final dbInstance = await database;

    final rows = await (dbInstance.select(
      dbInstance.products,
    )..where((tbl) => tbl.barcode.isIn(barcodes)))
        .get();

    final result = await _enrichProductsWithOverrides(rows);
    PerfDebugTimer.logDuration(
      area: 'db',
      label: 'getProductsByBarcodes',
      elapsed: stopwatch.elapsed,
      fields: {'barcodes': barcodes.length, 'rows': rows.length},
    );
    return result;
  }

  /// Retrieves recently used products based on the user's consumption history.
  Future<List<FoodItem>> getRecentProducts() async {
    final dbInstance = await database;

    final maxDate = dbInstance.nutritionLogs.consumedAt.max();
    final query = dbInstance.selectOnly(dbInstance.nutritionLogs)
      ..addColumns([dbInstance.nutritionLogs.legacyBarcode, maxDate])
      ..groupBy([dbInstance.nutritionLogs.legacyBarcode])
      ..orderBy([
        OrderingTerm(expression: maxDate, mode: OrderingMode.desc),
      ])
      ..limit(100);

    final result = await query.get();

    final recentBarcodes = result
        .map((row) => row.read(dbInstance.nutritionLogs.legacyBarcode))
        .where((bc) => bc != null)
        .cast<String>()
        .toList();

    final products = await getProductsByBarcodes(recentBarcodes);
    
    // Sort products to match the exact descending order of recentBarcodes
    final barcodeToIndex = {
      for (var i = 0; i < recentBarcodes.length; i++) recentBarcodes[i]: i
    };
    products.sort((a, b) {
      final indexA = barcodeToIndex[a.barcode] ?? 9999;
      final indexB = barcodeToIndex[b.barcode] ?? 9999;
      return indexA.compareTo(indexB);
    });

    return products;
  }

  /// Retrieves all food categories from the database.
  Future<List<Map<String, dynamic>>> getBaseCategories() async {
    final db = await database;
    final rows = await (db.select(
      db.foodCategories,
    )..orderBy([(t) => OrderingTerm(expression: t.key)]))
        .get();

    return rows.map((row) {
      return {
        'key': row.key,
        'name_de': row.nameDe,
        'name_en': row.nameEn,
        'emoji': row.emoji,
      };
    }).toList();
  }

  /// Retrieves base foods from the katalog, optionally filtered by [categoryKey] or [search] term.
  Future<List<FoodItem>> getBaseFoods({
    String? categoryKey,
    int limit = 100,
    String? search,
  }) async {
    final db = await database;

    var query = db.select(db.products)
      ..where((t) => t.source.equals('base'))
      ..limit(limit);

    if (categoryKey != null) {
      query = query..where((t) => t.category.equals(categoryKey));
    }

    if (search != null && search.isNotEmpty) {
      final term = search.trim();
      query = query
        ..where(
          (t) =>
              t.name.like('%$term%') |
              t.nameDe.like('%$term%') |
              t.nameEn.like('%$term%'),
        );

      query = query
        ..orderBy([
          (t) => OrderingTerm(
                expression: CaseWhenExpression<int>(
                  cases: [
                    CaseWhen(
                        t.name.equals(term) |
                            t.nameDe.equals(term) |
                            t.nameEn.equals(term),
                        then: const Constant(0)),
                    CaseWhen(
                        t.name.like('$term%') |
                            t.nameDe.like('$term%') |
                            t.nameEn.like('$term%'),
                        then: const Constant(1)),
                  ],
                  orElse: const Constant(2),
                ),
                mode: OrderingMode.asc,
              ),
          (t) =>
              OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc),
          (t) =>
              OrderingTerm(expression: t.name.length, mode: OrderingMode.asc),
        ]);
    } else {
      query = query
        ..orderBy([
          (t) =>
              OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc),
          (t) =>
              OrderingTerm(expression: t.name.length, mode: OrderingMode.asc),
        ]);
    }

    final rows = await query.get();
    return _enrichProductsWithOverrides(rows);
  }

  /// Performs a global search across user-created, base, and Open Food Facts products.
  Future<List<FoodItem>> searchProducts(String keyword) async {
    final term = keyword.trim();
    if (term.isEmpty) return [];
    final dbInstance = await database;
    const int limit = 50;

    Expression<int> searchPriority(db.Products t) {
      return CaseWhenExpression<int>(
        cases: [
          CaseWhen(
            t.name.equals(term) | t.nameDe.equals(term) | t.nameEn.equals(term),
            then: const Constant(0),
          ),
          CaseWhen(
            t.name.like('$term%') |
                t.nameDe.like('$term%') |
                t.nameEn.like('$term%'),
            then: const Constant(1),
          ),
        ],
        orElse: const Constant(2),
      );
    }

    final priorityRows = await (dbInstance.select(dbInstance.products)
          ..where(
            (t) =>
                (t.name.like('%$term%') |
                    t.nameDe.like('%$term%') |
                    t.nameEn.like('%$term%') |
                    t.brand.like('%$term%')) &
                t.source.isIn(['user', 'base']),
          )
          ..orderBy([
            (t) => OrderingTerm(
                expression: searchPriority(t), mode: OrderingMode.asc),
            (t) =>
                OrderingTerm(expression: t.usageCount, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.name.length, mode: OrderingMode.asc),
          ])
          ..limit(limit))
        .get();

    final List<FoodItem> results = await _enrichProductsWithOverrides(priorityRows);

    if (results.length < limit) {
      final int remaining = limit - results.length;
      final offRows = await (dbInstance.select(dbInstance.products)
            ..where(
              (t) =>
                  (t.name.like('%$term%') |
                      t.nameDe.like('%$term%') |
                      t.nameEn.like('%$term%') |
                      t.brand.like('%$term%')) &
                  t.source.equals('off'),
            )
            ..orderBy([
              (t) => OrderingTerm(
                  expression: searchPriority(t), mode: OrderingMode.asc),
              (t) => OrderingTerm(
                  expression: t.usageCount, mode: OrderingMode.desc),
              (t) => OrderingTerm(
                  expression: t.name.length, mode: OrderingMode.asc),
            ])
            ..limit(remaining))
          .get();

      results.addAll(await _enrichProductsWithOverrides(offRows));
    }

    return results;
  }

  /// Retrieves a single product by its [barcode].
  Future<FoodItem?> getProductByBarcode(String barcode) async {
    final db = await database;
    final row = await (db.select(db.products)
          ..where((t) => t.barcode.equals(barcode))
          ..limit(1))
        .getSingleOrNull();

    if (row == null) return null;
    final enriched = await _enrichProductsWithOverrides([row]);
    return enriched.first;
  }

  /// Retrieves all products marked as favorites by the user.
  Future<List<FoodItem>> getFavoriteProducts() async {
    final db = await database;
    final query = db.select(db.products).join([
      innerJoin(
        db.favorites,
        db.favorites.barcode.equalsExp(db.products.barcode),
      ),
    ]);

    final result = await query.get();
    final products = result.map((row) => row.readTable(db.products)).toList();
    return _enrichProductsWithOverrides(products);
  }

  /// Fuzzy-matches an AI-detected food name against the products table.
  Future<List<FoodItem>> fuzzyMatchForAi(String aiName) async {
    final tokens = aiName
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1)
        .toList();
    if (tokens.isEmpty) return [];

    final dbInstance = await database;
    const int fetchLimit = 20;
    const int returnLimit = 5;

    Expression<int> sourcePriority(GeneratedColumn<String> source) {
      return CaseWhenExpression<int>(
        cases: [
          CaseWhen(source.equals('base'), then: const Constant(0)),
          CaseWhen(source.equals('user'), then: const Constant(1)),
        ],
        orElse: const Constant(2),
      );
    }

    List<db.Product> rows = [];

    if (tokens.length > 1) {
      var query = dbInstance.select(dbInstance.products)
        ..limit(fetchLimit)
        ..orderBy([
          (t) => OrderingTerm(
              expression: sourcePriority(t.source), mode: OrderingMode.asc),
          (t) =>
              OrderingTerm(expression: t.name.length, mode: OrderingMode.asc),
        ]);
      for (final token in tokens) {
        query = query..where((t) => t.name.like('%$token%'));
      }
      rows = await query.get();
    }

    if (rows.isEmpty) {
      tokens.sort((a, b) => b.length.compareTo(a.length));
      final bestToken = tokens.first;
      rows = await (dbInstance.select(dbInstance.products)
            ..where((t) => t.name.like('%$bestToken%'))
            ..orderBy([
              (t) => OrderingTerm(
                  expression: sourcePriority(t.source), mode: OrderingMode.asc),
              (t) => OrderingTerm(
                  expression: t.name.length, mode: OrderingMode.asc),
            ])
            ..limit(fetchLimit))
          .get();
    }

    if (rows.isEmpty) return [];

    final items = await _enrichProductsWithOverrides(rows);
    return const EvaluateFoodSourceUseCase().execute(
      candidates: items,
      searchTerm: aiName,
      limit: returnLimit,
    );
  }

  /// Returns up to [limit] fuzzy-match candidates for an AI-identified food name,
  /// enriched with macro density profiles for injection into repair prompts.
  ///
  /// Unlike [fuzzyMatchForAi] which returns the single best match for initial
  /// validation, this method returns a broader set of plausible alternatives
  /// sorted by a composite score of text similarity + macro plausibility.
  Future<List<FoodItem>> fuzzyMatchCandidatesForRepair(
    String aiName, {
    String? stateHint,
    int limit = 5,
  }) async {
    final tokens = aiName
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1)
        .toList();
    if (tokens.isEmpty) return [];

    final dbInstance = await database;
    const int fetchLimit = 30;

    Expression<int> sourcePriority(GeneratedColumn<String> source) {
      return CaseWhenExpression<int>(
        cases: [
          CaseWhen(source.equals('base'), then: const Constant(0)),
          CaseWhen(source.equals('user'), then: const Constant(1)),
        ],
        orElse: const Constant(2),
      );
    }

    List<db.Product> rows = [];

    if (tokens.length > 1) {
      var query = dbInstance.select(dbInstance.products)
        ..limit(fetchLimit)
        ..orderBy([
          (t) => OrderingTerm(
              expression: sourcePriority(t.source), mode: OrderingMode.asc),
          (t) =>
              OrderingTerm(expression: t.name.length, mode: OrderingMode.asc),
        ]);
      for (final token in tokens) {
        query = query..where((t) => t.name.like('%$token%'));
      }
      rows = await query.get();
    }

    if (rows.isEmpty) {
      tokens.sort((a, b) => b.length.compareTo(a.length));
      final bestToken = tokens.first;
      rows = await (dbInstance.select(dbInstance.products)
            ..where((t) => t.name.like('%$bestToken%'))
            ..orderBy([
              (t) => OrderingTerm(
                  expression: sourcePriority(t.source), mode: OrderingMode.asc),
              (t) => OrderingTerm(
                  expression: t.name.length, mode: OrderingMode.asc),
            ])
            ..limit(fetchLimit))
          .get();
    }

    if (rows.isEmpty) return [];

    final items = await _enrichProductsWithOverrides(rows);

    // Re-rank items incorporating stateHint
    items.sort((a, b) {
      final aName = a.getLocalizedName(null).toLowerCase();
      final bName = b.getLocalizedName(null).toLowerCase();

      // State hint scoring/boosting
      double stateBoost(String name) {
        if (stateHint != null) {
          final hint = stateHint.toLowerCase();
          if (hint == 'cooked') {
            if (name.contains('gekocht') || name.contains('zubereitet') || name.contains('gebraten') || name.contains('gebacken')) {
              return -2.0; // Lower is better in sort (ascending)
            }
            if (name.contains('roh')) {
              return 2.0; // raw is penalized when we expect cooked
            }
          } else if (hint == 'raw') {
            if (name.contains('roh')) {
              return -2.0;
            }
            if (name.contains('gekocht') || name.contains('zubereitet') || name.contains('gebraten')) {
              return 2.0;
            }
          }
        }
        return 0.0;
      }

      final scoreA = stateBoost(aName);
      final scoreB = stateBoost(bName);
      if (scoreA != scoreB) return scoreA.compareTo(scoreB);

      // Fallback to text matching
      final searchLower = aiName.trim().toLowerCase();
      int textScore(String name) {
        if (name == searchLower) return 0;
        if (name.startsWith(searchLower)) return 1;
        return 2;
      }

      final sa = textScore(aName);
      final sb = textScore(bName);
      if (sa != sb) return sa.compareTo(sb);

      int srcPri(FoodItemSource s) {
        switch (s) {
          case FoodItemSource.base:
            return 0;
          case FoodItemSource.user:
            return 1;
          case FoodItemSource.off:
            return 2;
        }
      }

      final spa = srcPri(a.source);
      final spb = srcPri(b.source);
      if (spa != spb) return spa.compareTo(spb);

      return aName.length.compareTo(bName.length);
    });

    return items.take(limit).toList();
  }

  // === Legacy / Compatibility ===
  Future<dynamic> get offDatabase async => null;

  Future<String> getBaseDbPath() async {
    final supportDir = await getApplicationSupportDirectory();
    return CatalogFileMigration.resolveCanonicalPath(
      directoryPath: supportDir.path,
      canonicalFileName: AppDataSources.baseFoodsDbFileName,
      legacyFileName: AppDataSources.legacyBaseFoodsDbFileName,
    );
  }

  Future<bool> isFavorite(String barcode) async {
    final dbInstance = await database;
    final count = await (dbInstance.select(
      dbInstance.favorites,
    )..where((t) => t.barcode.equals(barcode)))
        .get();
    return count.isNotEmpty;
  }

  Future<List<String>> getFavoriteBarcodes() async {
    final dbInstance = await database;
    final rows = await dbInstance.select(dbInstance.favorites).get();
    return rows.map((r) => r.barcode).toList();
  }

  Future<void> addFavorite(String barcode) async {
    final dbInstance = await database;
    await dbInstance.into(dbInstance.favorites).insert(
          db.FavoritesCompanion(barcode: Value(barcode)),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> removeFavorite(String barcode) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.favorites,
    )..where((t) => t.barcode.equals(barcode)))
        .go();
  }
}
