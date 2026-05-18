// lib/features/diary/data/sources/meal_local_data_source.dart

import 'package:drift/drift.dart' as drift;
import '../../../../data/database_helper.dart';
import '../../../../data/drift_database.dart' as db;

class MealLocalDataSource {
  final db.AppDatabase _dbInstance;

  MealLocalDataSource(this._dbInstance);

  static MealLocalDataSource get instance =>
      DatabaseHelper.instance.mealLocalDataSource;

  db.AppDatabase get dbInstance => _dbInstance;

  Future<db.AppDatabase> get database async {
    return _dbInstance;
  }

  Future<int> insertMeal({required String name, String? notes}) async {
    final dbInstance = await database;
    final row = await dbInstance.into(dbInstance.meals).insertReturning(
          db.MealsCompanion(name: drift.Value(name), notes: drift.Value(notes)),
        );
    return row.localId;
  }

  Future<void> updateMeal(int id, {required String name, String? notes}) async {
    final dbInstance = await database;
    await (dbInstance.update(
      dbInstance.meals,
    )..where((t) => t.localId.equals(id)))
        .write(
      db.MealsCompanion(name: drift.Value(name), notes: drift.Value(notes)),
    );
  }

  Future<void> deleteMeal(int id) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.meals,
    )..where((t) => t.localId.equals(id)))
        .go();
  }

  Future<List<Map<String, dynamic>>> getMeals() async {
    final dbInstance = await database;
    final rows = await dbInstance.select(dbInstance.meals).get();

    return rows
        .map((r) => {'id': r.localId, 'name': r.name, 'notes': r.notes})
        .toList();
  }

  Future<int> addMealItem({
    required int mealId,
    required String barcode,
    required double amount,
  }) async {
    final dbInstance = await database;

    final mealRow = await (dbInstance.select(
      dbInstance.meals,
    )..where((t) => t.localId.equals(mealId)))
        .getSingle();

    final row = await dbInstance.into(dbInstance.mealItems).insertReturning(
          db.MealItemsCompanion(
            mealId: drift.Value(mealRow.id),
            productBarcode: drift.Value(barcode),
            quantityInGrams: drift.Value(amount.round()),
          ),
        );
    return row.localId;
  }

  Future<List<Map<String, dynamic>>> getMealItems(int mealLocalId) async {
    final dbInstance = await database;

    final mealRow = await (dbInstance.select(
      dbInstance.meals,
    )..where((t) => t.localId.equals(mealLocalId)))
        .getSingleOrNull();
    if (mealRow == null) return [];

    final rows = await (dbInstance.select(
      dbInstance.mealItems,
    )..where((t) => t.mealId.equals(mealRow.id)))
        .get();

    return rows
        .map(
          (r) => {
            'id': r.localId,
            'meal_id': mealLocalId,
            'barcode': r.productBarcode,
            'quantity_in_grams': r.quantityInGrams,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMealTemplatesForBackup() async {
    final dbInstance = await database;
    final mealRows = await (dbInstance.select(dbInstance.meals)
          ..orderBy([(t) => drift.OrderingTerm(expression: t.localId)]))
        .get();

    final result = <Map<String, dynamic>>[];
    for (final meal in mealRows) {
      final itemQuery = dbInstance.select(dbInstance.mealItems).join([
        drift.leftOuterJoin(
          dbInstance.products,
          dbInstance.products.id.equalsExp(dbInstance.mealItems.productId),
        ),
      ])
        ..where(dbInstance.mealItems.mealId.equals(meal.id))
        ..orderBy(
            [drift.OrderingTerm(expression: dbInstance.mealItems.localId)]);
      final itemRows = await itemQuery.get();

      final items = itemRows
          .map((row) {
            final item = row.readTable(dbInstance.mealItems);
            final product = row.readTableOrNull(dbInstance.products);
            final barcode =
                (item.productBarcode != null && item.productBarcode!.isNotEmpty)
                    ? item.productBarcode!
                    : product?.barcode;
            return <String, dynamic>{
              'barcode': barcode,
              'quantityInGrams': item.quantityInGrams,
            };
          })
          .where((row) => row['barcode'] != null)
          .toList();

      result.add(<String, dynamic>{
        'name': meal.name,
        'notes': meal.notes,
        'items': items,
      });
    }
    return result;
  }

  Future<void> importMealTemplates(
    List<Map<String, dynamic>> mealTemplates,
  ) async {
    if (mealTemplates.isEmpty) return;
    final dbInstance = await database;

    await dbInstance.transaction(() async {
      for (final template in mealTemplates) {
        final name = (template['name'] as String?)?.trim();
        if (name == null || name.isEmpty) continue;
        final notes = template['notes'] as String?;

        final mealRow = await dbInstance.into(dbInstance.meals).insertReturning(
              db.MealsCompanion(
                name: drift.Value(name),
                notes: drift.Value(notes),
              ),
            );

        final itemsRaw = template['items'];
        if (itemsRaw is! List) continue;
        for (final raw in itemsRaw) {
          if (raw is! Map) continue;
          final item = Map<String, dynamic>.from(raw);
          final barcode = (item['barcode'] as String?)?.trim();
          final gramsRaw = item['quantityInGrams'] ?? item['quantity_in_grams'];
          final grams = (gramsRaw is num) ? gramsRaw.toInt() : null;
          if (barcode == null ||
              barcode.isEmpty ||
              grams == null ||
              grams <= 0) {
            continue;
          }

          await dbInstance.into(dbInstance.mealItems).insert(
                db.MealItemsCompanion(
                  mealId: drift.Value(mealRow.id),
                  productBarcode: drift.Value(barcode),
                  quantityInGrams: drift.Value(grams),
                ),
                mode: drift.InsertMode.insertOrReplace,
              );
        }
      }
    });
  }

  Future<void> removeMealItem(int itemLocalId) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.mealItems,
    )..where((t) => t.localId.equals(itemLocalId)))
        .go();
  }

  Future<void> clearMealItems(int mealLocalId) async {
    final dbInstance = await database;
    final mealRow = await (dbInstance.select(
      dbInstance.meals,
    )..where((t) => t.localId.equals(mealLocalId)))
        .getSingleOrNull();
    if (mealRow != null) {
      await (dbInstance.delete(
        dbInstance.mealItems,
      )..where((t) => t.mealId.equals(mealRow.id)))
          .go();
    }
  }
}
