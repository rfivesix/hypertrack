// lib/data/product_database_helper.dart

import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'database_helper.dart';
import 'drift_database.dart' as db;
import 'drift_database.dart';
import '../config/app_data_sources.dart';
import '../models/food_item.dart';
import '../services/catalog_file_migration.dart';
import '../util/perf_debug_timer.dart';

/// Helper class for managing food product data in the Drift database.
///
/// Provides methods for searching products, managing favorites, and retrieving
/// base foods from the katalog.
class ProductDatabaseHelper {
  /// Singleton instance of [ProductDatabaseHelper].
  static final ProductDatabaseHelper instance = ProductDatabaseHelper._init();

  final DatabaseHelper _databaseHelper;

  ProductDatabaseHelper._init() : _databaseHelper = DatabaseHelper.instance;
  ProductDatabaseHelper.forTesting({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  // Access to the central Drift instance
  Future<db.AppDatabase> get database async => _databaseHelper.database;

  // --- MAPPING HELPER ---

  FoodItem _mapRowToModel(db.Product row) {
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
      name: row.name,
      // nameDe/nameEn are not stored in the current schema,
      // so fall back to name or empty strings if the model requires it.
      nameDe: row.name,
      nameEn: row.name,
      brand: row.brand ?? '',
      calories: row.calories,
      protein: row.protein,
      carbs: row.carbs,
      fat: row.fat,
      source: source,
      sugar: row.sugar,
      fiber: row.fiber,
      salt: row.salt,
      // Sodium is not in the Drift schema; estimate it from salt or leave it null.
      sodium: row.salt != null ? row.salt! / 2.5 : null,
      // kJ is not in the schema, calculate it:
      kj: (row.calories * 4.184),
      // Calcium is not in the schema:
      calcium: null,
      isLiquid: row.isLiquid,
      caffeineMgPer100ml: row.caffeine,
    );
  }

  db.ProductsCompanion _mapModelToCompanion(FoodItem item) {
    return db.ProductsCompanion(
      barcode: Value(item.barcode),
      name: Value(item.name),
      brand: Value(item.brand),
      calories: Value(item.calories),
      protein: Value(item.protein),
      carbs: Value(item.carbs),
      fat: Value(item.fat),
      sugar: Value(item.sugar),
      fiber: Value(item.fiber),
      salt: Value(item.salt),
      caffeine: Value(item.caffeineMgPer100ml),
      isLiquid: Value(item.isLiquid ?? false),
      source: Value(_sourceToString(item.source)),
    );
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
    // In Drift, insertOrReplace (see above) is often enough,
    // but use an explicit update here:
    final dbInstance = await database;
    await (dbInstance.update(dbInstance.products)
          ..where((tbl) => tbl.barcode.equals(item.barcode)))
        .write(_mapModelToCompanion(item));
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

    final result = rows.map(_mapRowToModel).toList();
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
    final recentBarcodes =
        await DatabaseHelper.instance.getRecentlyUsedBarcodes();
    return await getProductsByBarcodes(recentBarcodes);
  }

  // === Base foods ===
  /// Retrieves all food categories from the database.
  Future<List<Map<String, dynamic>>> getBaseCategories() async {
    final db = await database;

    // Query the real 'food_categories' table now.
    // Sort by 'key' or adjust as needed.
    final rows = await (db.select(
      db.foodCategories,
    )..orderBy([(t) => OrderingTerm(expression: t.key)]))
        .get();

    return rows.map((row) {
      return {
        'key': row.key,
        'name_de': row.nameDe, // Real name from DB
        'name_en': row.nameEn, // Real name from DB
        'emoji': row.emoji, // Real emoji from DB
      };
    }).toList();
  }

  // --- 2. Load base foods (catalog & base search) ---
  // FIX: categoryKey is now optional (String?).
  /// Retrieves base foods from the katalog, optionally filtered by [categoryKey] or [search] term.
  Future<List<FoodItem>> getBaseFoods({
    String? categoryKey, // <--- No longer required
    int limit = 100,
    String? search,
  }) async {
    final db = await database;

    var query = db.select(db.products)
      ..where((t) => t.source.equals('base'))
      ..limit(limit);

    // Filter only when a category is specified.
    if (categoryKey != null) {
      query = query..where((t) => t.category.equals(categoryKey));
    }

    if (search != null && search.isNotEmpty) {
      query = query
        ..where(
          (t) =>
              t.name.like('%$search%') |
              t.nameDe.like('%$search%') |
              t.nameEn.like('%$search%'),
        );
    }

    final rows = await query.get();
    return rows.map((row) => _mapRowToFoodItem(row)).toList();
  }

  // --- 3. Global search (base + OFF + user) ---
  /// Performs a global search across user-created, base, and Open Food Facts products.
  Future<List<FoodItem>> searchProducts(String keyword) async {
    final term = keyword.trim();
    if (term.isEmpty) return [];
    final db = await database;
    const int limit = 50;

    // 1. Prioritized search: user foods and base foods
    // These are most important and should always be at the top.
    final priorityRows = await (db.select(db.products)
          ..where(
            (t) =>
                (t.name.like('%$term%') |
                    t.nameDe.like('%$term%') |
                    t.nameEn.like('%$term%') |
                    t.brand.like('%$term%')) &
                t.source.isIn(['user', 'base']),
          )
          ..orderBy([
            // Shorter names first (exact matches to the top).
            (t) => OrderingTerm(
                  expression: t.name.length,
                  mode: OrderingMode.asc,
                ),
          ])
          ..limit(limit))
        .get();

    final List<FoodItem> results = priorityRows.map(_mapRowToFoodItem).toList();

    // 2. Fill with Open Food Facts (OFF) if there is still space in the list.
    if (results.length < limit) {
      final int remaining = limit - results.length;
      final offRows = await (db.select(db.products)
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
                    expression: t.name.length,
                    mode: OrderingMode.asc,
                  ),
            ])
            ..limit(remaining))
          .get();

      results.addAll(offRows.map(_mapRowToFoodItem));
    }

    return results;
  }

  // --- 4. SCANNER ---
  /// Retrieves a single product by its [barcode].
  Future<FoodItem?> getProductByBarcode(String barcode) async {
    final db = await database;
    final row = await (db.select(db.products)
          ..where((t) => t.barcode.equals(barcode))
          ..limit(1))
        .getSingleOrNull();

    if (row == null) return null;
    return _mapRowToFoodItem(row);
  }

  // --- 5. Favorites ---
  /// Retrieves all products marked as favorites by the user.
  Future<List<FoodItem>> getFavoriteProducts() async {
    final db = await database;

    // Join Products with Favorites
    final query = db.select(db.products).join([
      innerJoin(
        db.favorites,
        db.favorites.barcode.equalsExp(db.products.barcode),
      ),
    ]);

    final result = await query.get();

    return result.map((row) {
      final product = row.readTable(db.products);
      return _mapRowToFoodItem(product);
    }).toList();
  }

  // --- HELPER ---
  FoodItem _mapRowToFoodItem(Product row) {
    return FoodItem(
      barcode: row.barcode,
      name: row.name,
      nameDe: row.nameDe ?? '',
      nameEn: row.nameEn ?? '',
      brand: row.brand ?? '',
      calories: row.calories,
      protein: row.protein,
      carbs: row.carbs,
      fat: row.fat,
      sugar: row.sugar,
      fiber: row.fiber,
      salt: row.salt,
      isLiquid: row.isLiquid,
      source: _mapSource(row.source),
      category: row.category,
    );
  }

  FoodItemSource _mapSource(String sourceString) {
    switch (sourceString) {
      case 'base':
        return FoodItemSource.base;
      case 'off':
      case 'off_retained':
        return FoodItemSource.off;
      case 'user':
        return FoodItemSource.user;
      default:
        return FoodItemSource.off;
    }
  }

  /// Fuzzy-matches an AI-detected food name against the products table.
  ///
  /// Splits [aiName] into tokens and requires all tokens to match via
  /// `LIKE '%token%'`. Falls back to single-token search if multi-token
  /// finds nothing. Returns up to 5 matches, re-ranked in Dart:
  ///   1. Exact match (case-insensitive)
  ///   2. Name starts with the search term
  ///   3. Other partial matches (shortest name first = most specific)
  Future<List<FoodItem>> fuzzyMatchForAi(String aiName) async {
    final tokens = aiName
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1)
        .toList();
    if (tokens.isEmpty) return [];

    final dbInstance = await database;
    // Fetch more candidates so we can re-rank properly in Dart
    const int fetchLimit = 20;
    const int returnLimit = 5;
    final searchTerm = aiName.trim().toLowerCase();

    // Source priority expression: base=0 (highest), user=1, off=2
    Expression<int> sourcePriority(GeneratedColumn<String> source) {
      return CaseWhenExpression<int>(
        cases: [
          CaseWhen(source.equals('base'), then: const Constant(0)),
          CaseWhen(source.equals('user'), then: const Constant(1)),
        ],
        orElse: const Constant(2),
      );
    }

    List<Product> rows = [];

    // Attempt multi-token search: all tokens must appear in the name
    if (tokens.length > 1) {
      var query = dbInstance.select(dbInstance.products)
        ..limit(fetchLimit)
        ..orderBy([
          (t) => OrderingTerm(
                expression: sourcePriority(t.source),
                mode: OrderingMode.asc,
              ),
          (t) =>
              OrderingTerm(expression: t.name.length, mode: OrderingMode.asc),
        ]);
      for (final token in tokens) {
        query = query..where((t) => t.name.like('%$token%'));
      }
      rows = await query.get();
    }

    // Fallback: single-token search with longest token
    if (rows.isEmpty) {
      tokens.sort((a, b) => b.length.compareTo(a.length));
      final bestToken = tokens.first;
      rows = await (dbInstance.select(dbInstance.products)
            ..where((t) => t.name.like('%$bestToken%'))
            ..orderBy([
              (t) => OrderingTerm(
                    expression: sourcePriority(t.source),
                    mode: OrderingMode.asc,
                  ),
              (t) => OrderingTerm(
                    expression: t.name.length,
                    mode: OrderingMode.asc,
                  ),
            ])
            ..limit(fetchLimit))
          .get();
    }

    if (rows.isEmpty) return [];

    // Re-rank in Dart for best accuracy
    final items = rows.map(_mapRowToFoodItem).toList();
    items.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();

      // Score: 0 = exact match, 1 = starts with, 2 = partial
      int score(String name) {
        if (name == searchTerm) return 0;
        if (name.startsWith(searchTerm)) return 1;
        return 2;
      }

      final sa = score(aName);
      final sb = score(bName);
      if (sa != sb) return sa.compareTo(sb);

      // Same score tier → prefer base source
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

      // Same source → shorter name is more specific
      return aName.length.compareTo(bName.length);
    });

    return items.take(returnLimit).toList();
  }

  // === Legacy / Compatibility Getter ===

  // For BackupManager if direct access is needed (deprecated).
  // Since everything is now in one DB, a separate offDatabase concept is obsolete.
  // Return null because BackupManager should use Drift in the new code.
  Future<dynamic> get offDatabase async {
    return null;
  }

  Future<String> getBaseDbPath() async {
    final supportDir = await getApplicationSupportDirectory();
    return CatalogFileMigration.resolveCanonicalPath(
      directoryPath: supportDir.path,
      canonicalFileName: AppDataSources.baseFoodsDbFileName,
      legacyFileName: AppDataSources.legacyBaseFoodsDbFileName,
    );
  }
}
