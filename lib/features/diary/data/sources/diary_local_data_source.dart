// lib/features/diary/data/sources/diary_local_data_source.dart
import '../../../../data/drift_database.dart' as drift_db
    hide Supplement, SupplementLog, WorkoutLog;
import 'package:drift/drift.dart' as drift;
import '../../../../data/database_helper.dart';
import '../../domain/models/food_entry.dart';
import '../../domain/models/fluid_entry.dart';
import '../../../supplements/domain/models/supplement.dart' as domain;
import '../../../supplements/data/sources/supplement_local_data_source.dart';

class DiaryLocalDataSource {
  final drift_db.AppDatabase _db;
  drift_db.AppDatabase get db => _db;
  final SupplementLocalDataSource _supplementDbHelper;

  static DiaryLocalDataSource get instance =>
      DatabaseHelper.instance.diaryLocalDataSource;

  DiaryLocalDataSource(
    this._db, {
    SupplementLocalDataSource? supplementDbHelper,
  }) : _supplementDbHelper =
            supplementDbHelper ?? SupplementLocalDataSource(_db);

  Future<drift_db.DailyGoalsHistoryData?> getGoalsForDate(DateTime date) async {
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = _db.select(_db.dailyGoalsHistory)
      ..where((t) => t.createdAt.isSmallerOrEqualValue(endOfDay))
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.createdAt,
              mode: drift.OrderingMode.desc,
            ),
      ])
      ..limit(1);

    final historyGoal = await query.getSingleOrNull();
    if (historyGoal != null) return historyGoal;

    final oldestHistory = await (_db.select(_db.dailyGoalsHistory)
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.createdAt,
                  mode: drift.OrderingMode.asc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (oldestHistory != null) return oldestHistory;

    final settings = await _db.select(_db.appSettings).getSingleOrNull();
    if (settings != null) {
      return drift_db.DailyGoalsHistoryData(
        id: 'fallback',
        localId: 0,
        createdAt: settings.createdAt,
        updatedAt: settings.updatedAt,
        deletedAt: settings.deletedAt,
        targetCalories: settings.targetCalories,
        targetProtein: settings.targetProtein,
        targetCarbs: settings.targetCarbs,
        targetFat: settings.targetFat,
        targetWater: settings.targetWater,
        targetSteps: settings.targetSteps,
      );
    }
    return null;
  }

  Future<List<FoodEntry>> getEntriesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = _db.select(_db.nutritionLogs)
      ..where((tbl) => tbl.consumedAt.isBetweenValues(start, end));

    final rows = await query.get();
    return rows
        .map(
          (row) => FoodEntry(
            id: row.localId,
            barcode: row.legacyBarcode ?? 'UNKNOWN',
            timestamp: row.consumedAt,
            quantityInGrams: row.amount.toInt(),
            mealType: row.mealType,
            updatedAt: row.updatedAt,
          ),
        )
        .toList();
  }

  Future<List<FluidEntry>> getFluidEntriesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = _db.select(_db.fluidLogs)
      ..where((tbl) => tbl.consumedAt.isBetweenValues(start, end));

    final rows = await query.get();
    return rows
        .map(
          (row) => FluidEntry(
            id: row.localId,
            name: row.name,
            quantityInMl: row.amountMl,
            timestamp: row.consumedAt,
            kcal: row.kcal,
            sugarPer100ml: row.sugarPer100ml,
            carbsPer100ml: row.carbsPer100ml,
            caffeinePer100ml: row.caffeinePer100ml,
          ),
        )
        .toList();
  }

  Future<void> updateFluidEntry(FluidEntry entry) async {
    if (entry.id == null) return;
    final old = await (_db.select(_db.fluidLogs)
          ..where((t) => t.localId.equals(entry.id!)))
        .getSingleOrNull();

    await (_db.update(_db.fluidLogs)
          ..where((tbl) => tbl.localId.equals(entry.id!)))
        .write(
      drift_db.FluidLogsCompanion(
        name: drift.Value(entry.name),
        amountMl: drift.Value(entry.quantityInMl),
        consumedAt: drift.Value(entry.timestamp),
        kcal: drift.Value(entry.kcal),
        sugarPer100ml: drift.Value(entry.sugarPer100ml),
        carbsPer100ml: drift.Value(entry.carbsPer100ml),
        caffeinePer100ml: drift.Value(entry.caffeinePer100ml),
      ),
    );

    if (old != null && old.consumedAt != entry.timestamp) {
      await (_db.delete(_db.supplementLogs)
            ..where((t) => t.takenAt.equals(old.consumedAt)))
          .go();
    }
  }

  Future<void> updateFoodEntry(FoodEntry entry) async {
    if (entry.id == null) return;
    await (_db.update(_db.nutritionLogs)
          ..where((tbl) => tbl.localId.equals(entry.id!)))
        .write(
      drift_db.NutritionLogsCompanion(
        legacyBarcode: drift.Value(entry.barcode),
        consumedAt: drift.Value(entry.timestamp),
        amount: drift.Value(entry.quantityInGrams.toDouble()),
        mealType: drift.Value(entry.mealType),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  Future<int> insertFluidEntry(FluidEntry entry) async {
    return await _db.into(_db.fluidLogs).insert(
          drift_db.FluidLogsCompanion.insert(
            name: entry.name,
            amountMl: entry.quantityInMl,
            consumedAt: entry.timestamp,
            kcal: drift.Value(entry.kcal),
            sugarPer100ml: drift.Value(entry.sugarPer100ml),
            carbsPer100ml: drift.Value(entry.carbsPer100ml),
            caffeinePer100ml: drift.Value(entry.caffeinePer100ml),
          ),
        );
  }

  Future<int> insertFoodEntry(FoodEntry entry) async {
    final companion = drift_db.NutritionLogsCompanion(
      legacyBarcode: drift.Value(entry.barcode),
      consumedAt: drift.Value(entry.timestamp),
      amount: drift.Value(entry.quantityInGrams.toDouble()),
      mealType: drift.Value(entry.mealType),
    );
    return await _db.into(_db.nutritionLogs).insert(companion);
  }

  Future<void> deleteFluidEntry(int id) async {
    final fluidLog = await (_db.select(_db.fluidLogs)
          ..where((t) => t.localId.equals(id)))
        .getSingleOrNull();
    if (fluidLog == null) return;

    if (fluidLog.linkedNutritionLogId != null) {
      await (_db.delete(_db.nutritionLogs)
            ..where((t) => t.id.equals(fluidLog.linkedNutritionLogId!)))
          .go();
    }
    await (_db.delete(_db.supplementLogs)
          ..where((t) => t.takenAt.equals(fluidLog.consumedAt)))
        .go();
    await (_db.delete(_db.fluidLogs)..where((tbl) => tbl.localId.equals(id)))
        .go();
  }

  Future<void> deleteFoodEntry(int id) async {
    await (_db.delete(_db.nutritionLogs)
          ..where((tbl) => tbl.localId.equals(id)))
        .go();
  }

  Future<FoodEntry?> getFoodEntryByLinkedFoodId(int linkedFoodId) async {
    final row = await (_db.select(_db.nutritionLogs)
          ..where((tbl) => tbl.localId.equals(linkedFoodId)))
        .getSingleOrNull();
    if (row == null) return null;
    return FoodEntry(
      id: row.localId,
      barcode: row.legacyBarcode ?? 'UNKNOWN',
      timestamp: row.consumedAt,
      quantityInGrams: row.amount.toInt(),
      mealType: row.mealType,
      updatedAt: row.updatedAt,
    );
  }

  Future<void> deleteFluidEntryByLinkedFoodId(int id) async {
    final log = await (_db.select(_db.nutritionLogs)
          ..where((t) => t.localId.equals(id)))
        .getSingleOrNull();
    if (log != null) {
      await (_db.delete(_db.fluidLogs)
            ..where((t) => t.linkedNutritionLogId.equals(log.id)))
          .go();
    }
  }

  Future<Map<String, int>> getRemainingMacrosForDate(DateTime date) async {
    final res = await getFoodCaloriesByDayForDateRange(date, date);
    final kcal = res.caloriesByDay.values.fold(0.0, (a, b) => a + b);

    final goals = await getGoalsForDate(date);
    final targetKcal = goals?.targetCalories ?? 2000;

    return {
      'kcal': (targetKcal - kcal).toInt().clamp(0, 99999),
      'protein': 0,
      'carbs': 0,
      'fat': 0,
    };
  }

  Future<List<FluidEntry>> getAllFluidEntries() async {
    final rows = await _db.select(_db.fluidLogs).get();
    return rows
        .map(
          (row) => FluidEntry(
            id: row.localId,
            name: row.name,
            quantityInMl: row.amountMl,
            timestamp: row.consumedAt,
            kcal: row.kcal,
            sugarPer100ml: row.sugarPer100ml,
            carbsPer100ml: row.carbsPer100ml,
            caffeinePer100ml: row.caffeinePer100ml,
          ),
        )
        .toList();
  }

  Future<List<FoodEntry>> getAllFoodEntries() async {
    final rows = await _db.select(_db.nutritionLogs).get();
    return rows
        .map(
          (row) => FoodEntry(
            id: row.localId,
            barcode: row.legacyBarcode ?? 'UNKNOWN',
            timestamp: row.consumedAt,
            quantityInGrams: row.amount.toInt(),
            mealType: row.mealType,
            updatedAt: row.updatedAt,
          ),
        )
        .toList();
  }

  Future<List<FoodEntry>> getAllFoodEntriesForBackup() async {
    final logs = await _db.select(_db.nutritionLogs).get();
    final List<FoodEntry> result = [];

    for (final log in logs) {
      String barcode =
          (log.legacyBarcode != null && log.legacyBarcode!.isNotEmpty)
              ? log.legacyBarcode!
              : 'UNKNOWN';

      if (barcode == 'UNKNOWN' && log.productId != null) {
        final productRow = await _db.customSelect(
          'SELECT barcode FROM products WHERE id = ?',
          variables: [drift.Variable.withString(log.productId!)],
        ).getSingleOrNull();
        if (productRow != null) {
          barcode = productRow.read<String>('barcode');
        }
      }

      result.add(FoodEntry(
        id: log.localId,
        barcode: barcode,
        timestamp: log.consumedAt,
        quantityInGrams: log.amount.toInt(),
        mealType: log.mealType,
        updatedAt: log.updatedAt,
      ));
    }
    return result;
  }

  Future<List<FoodEntry>> getEntriesForDateRange(
    DateTime start,
    DateTime end, {
    DateTime? updatedSince,
  }) async {
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final query = _db.select(_db.nutritionLogs)
      ..where((tbl) => tbl.consumedAt.isBetweenValues(startOfDay, endOfDay));

    if (updatedSince != null) {
      query.where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(updatedSince));
    }

    final rows = await query.get();
    return rows
        .map(
          (row) => FoodEntry(
            id: row.localId,
            barcode: row.legacyBarcode ?? 'UNKNOWN',
            timestamp: row.consumedAt,
            quantityInGrams: row.amount.toInt(),
            mealType: row.mealType,
            updatedAt: row.updatedAt,
          ),
        )
        .toList();
  }

  Future<List<FluidEntry>> getFluidEntriesForDateRange(
    DateTime start,
    DateTime end, {
    DateTime? updatedSince,
  }) async {
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final query = _db.select(_db.fluidLogs)
      ..where((tbl) => tbl.consumedAt.isBetweenValues(startOfDay, endOfDay));

    if (updatedSince != null) {
      query.where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(updatedSince));
    }

    final rows = await query.get();
    return rows
        .map(
          (row) => FluidEntry(
            id: row.localId,
            name: row.name,
            quantityInMl: row.amountMl,
            timestamp: row.consumedAt,
            kcal: row.kcal,
            sugarPer100ml: row.sugarPer100ml,
            carbsPer100ml: row.carbsPer100ml,
            caffeinePer100ml: row.caffeinePer100ml,
          ),
        )
        .toList();
  }

  Future<domain.Supplement?> getSupplementById(int id) async {
    final row = await (_db.select(_db.supplements)
          ..where((t) => t.localId.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return domain.Supplement(
        id: row.localId,
        name: row.name,
        defaultDose: row.dose,
        unit: row.unit,
        dailyLimit: row.dailyLimit,
        code: row.code);
  }

  Future<List<domain.Supplement>> getSupplementsForDate(DateTime date) =>
      _supplementDbHelper.getSupplementsForDate(date);

  Future<FoodCaloriesByDayResult> getFoodCaloriesByDayForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final productsByBarcode = _db.products.createAlias(
      'products_by_barcode',
    );

    final query = _db.select(_db.nutritionLogs).join([
      drift.leftOuterJoin(
        _db.products,
        _db.products.id.equalsExp(_db.nutritionLogs.productId),
      ),
      drift.leftOuterJoin(
        productsByBarcode,
        productsByBarcode.barcode.equalsExp(
          _db.nutritionLogs.legacyBarcode,
        ),
      ),
    ])
      ..where(_db.nutritionLogs.consumedAt.isBetweenValues(start, end));

    final rows = await query.get();

    final Map<DateTime, double> caloriesByDay = {};
    int unresolvedCount = 0;

    for (final row in rows) {
      final log = row.readTable(_db.nutritionLogs);
      final productByJoin = row.readTableOrNull(_db.products);
      final productByBarcode = row.readTableOrNull(productsByBarcode);

      final product = productByJoin ?? productByBarcode;
      final day = DateTime(
          log.consumedAt.year, log.consumedAt.month, log.consumedAt.day);

      if (product != null) {
        final ratio = log.amount / 100.0;
        final kcal = product.calories * ratio;
        caloriesByDay[day] = (caloriesByDay[day] ?? 0.0) + kcal;
      } else {
        unresolvedCount++;
      }
    }

    return FoodCaloriesByDayResult(
      caloriesByDay: caloriesByDay,
      unresolvedEntryCount: unresolvedCount,
    );
  }
}
