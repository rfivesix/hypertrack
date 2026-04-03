// lib/data/database_helper.dart

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
// Import mit Prefix
import 'drift_database.dart' as db;
import 'drift_database.dart' show FavoritesCompanion;

import '../models/chart_data_point.dart';
import '../models/fluid_entry.dart';
import '../models/food_entry.dart';
import '../models/measurement.dart';
import '../models/measurement_session.dart';
import '../models/supplement.dart';
import '../models/supplement_log.dart';
import '../services/health/steps_sync_service.dart';
import 'product_database_helper.dart';

/// Main helper for general application data persistence using the Drift database.
///
/// Manages user favorites, nutrition logs, fluid intake, body measurements,
/// supplements, and meal templates.
class DatabaseHelper {
  /// Singleton instance of [DatabaseHelper].
  static final DatabaseHelper instance = DatabaseHelper._init();

  static db.AppDatabase? _driftDb;
  final db.AppDatabase? _injectedDb;
  static const int _msPerSecond = 1000;

  DatabaseHelper._init() : _injectedDb = null;
  DatabaseHelper.forTesting(db.AppDatabase database) : _injectedDb = database;

  /// Returns the underlying [db.AppDatabase] instance.
  Future<db.AppDatabase> get database async {
    if (_injectedDb != null) return _injectedDb!;
    if (_driftDb != null) return _driftDb!;
    _driftDb = db.AppDatabase();
    return _driftDb!;
  }

  // --- INIT: STANDARD SUPPLEMENTS ---
  Future<void> ensureStandardSupplements() async {
    final dbInstance = await database;

    // Prüfen, ob Koffein (Code 'caffeine') schon existiert
    final exists = await (dbInstance.select(
      dbInstance.supplements,
    )..where((t) => t.code.equals('caffeine')))
        .getSingleOrNull();

    if (exists == null) {
      // Koffein anlegen
      await insertSupplement(
        Supplement(
          code: 'caffeine', // WICHTIG: Code muss exakt stimmen für die Logik
          name: 'Koffein',
          defaultDose: 0, // Hängt vom Getränk ab
          unit: 'mg',
          dailyGoal: null,
          dailyLimit: 400,
          isBuiltin: true,
        ),
      );
    }
  }

  // ===========================================================================
  // 1. DATA MAINTENANCE
  // ===========================================================================

  /// Deletes all user-specific data from the database, excluding base products.
  Future<void> clearAllUserData() async {
    final dbInstance = await database;

    // Wir deaktivieren kurzzeitig Foreign Keys, um sicher alles löschen zu können
    await dbInstance.customStatement('PRAGMA foreign_keys = OFF');

    try {
      // 1. History tables
      await dbInstance.delete(dbInstance.dailyGoalsHistory).go();
      await dbInstance.delete(dbInstance.supplementSettingsHistory).go();
      await dbInstance.customStatement('DELETE FROM health_step_segments');
      await dbInstance.customStatement('DELETE FROM health_export_records');

      // 2. Child tables (Logs) first
      await dbInstance.delete(dbInstance.supplementLogs).go();
      await dbInstance.delete(dbInstance.fluidLogs).go();
      await dbInstance.delete(dbInstance.nutritionLogs).go();
      await dbInstance.delete(dbInstance.measurements).go();
      await dbInstance.delete(dbInstance.mealItems).go();

      // 3. Parent tables (Definitions)
      await dbInstance.delete(dbInstance.favorites).go();
      await dbInstance.delete(dbInstance.supplements).go();
      await dbInstance.delete(dbInstance.meals).go();

      // 4. Settings & Profile
      await dbInstance.delete(dbInstance.appSettings).go();
      await dbInstance.delete(dbInstance.profiles).go();

      // 5. User products
      await (dbInstance.delete(
        dbInstance.products,
      )..where((t) => t.source.equals('user')))
          .go();
    } finally {
      // Foreign Keys wieder aktivieren
      await dbInstance.customStatement('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> importUserData({
    required List<FoodEntry> foodEntries,
    required List<FluidEntry> fluidEntries,
    required List<String> favoriteBarcodes,
    required List<MeasurementSession> measurementSessions,
    required List<Supplement> supplements,
    required List<SupplementLog> supplementLogs,
  }) async {
    final dbInstance = await database;

    await dbInstance.batch((batch) {
      // A. FAVORITEN
      for (final barcode in favoriteBarcodes) {
        batch.insert(
          dbInstance.favorites,
          FavoritesCompanion(
            barcode: drift.Value(barcode),
            createdAt: drift.Value(DateTime.now()),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }

      // B. NUTRITION LOGS (Essen)
      for (final entry in foodEntries) {
        batch.insert(
          dbInstance.nutritionLogs,
          db.NutritionLogsCompanion(
            legacyBarcode: drift.Value(entry.barcode),
            consumedAt: drift.Value(entry.timestamp),
            amount: drift.Value(entry.quantityInGrams.toDouble()),
            mealType: drift.Value(entry.mealType),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }

      // C. FLUID LOGS (Trinken)
      for (final entry in fluidEntries) {
        batch.insert(
          dbInstance.fluidLogs,
          db.FluidLogsCompanion(
            consumedAt: drift.Value(entry.timestamp),
            amountMl: drift.Value(entry.quantityInMl),
            name: drift.Value(entry.name),
            kcal: drift.Value(entry.kcal),
            sugarPer100ml: drift.Value(entry.sugarPer100ml),
            caffeinePer100ml: drift.Value(entry.caffeinePer100ml),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }

      // D. MEASUREMENTS
      for (final session in measurementSessions) {
        final legacyId = session.timestamp.millisecondsSinceEpoch;
        for (final m in session.measurements) {
          batch.insert(
            dbInstance.measurements,
            db.MeasurementsCompanion(
              date: drift.Value(session.timestamp),
              type: drift.Value(m.type),
              value: drift.Value(m.value),
              unit: drift.Value(m.unit),
              legacySessionId: drift.Value(legacyId),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
        }
      }

      // E. SUPPLEMENTS (Mit ID-Fix)
      for (final s in supplements) {
        // Konvertiere int-ID zu String, falls nötig, oder erstelle neue UUID
        final String fixedId =
            s.id != null ? s.id.toString() : const Uuid().v4();

        batch.insert(
          dbInstance.supplements,
          db.SupplementsCompanion(
            id: drift.Value(fixedId), // Explizite ID setzen!
            code: drift.Value(s.code),
            name: drift.Value(s.name),
            dose: drift.Value(s.defaultDose),
            unit: drift.Value(s.unit),
            dailyGoal: drift.Value(s.dailyGoal),
            dailyLimit: drift.Value(s.dailyLimit),
            notes: drift.Value(s.notes),
            isBuiltin: drift.Value(s.isBuiltin),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }
    });

    // F. SUPPLEMENT LOGS (Separat, um Referenzfehler zu vermeiden)
    await dbInstance.batch((batch) {
      for (final log in supplementLogs) {
        // Hier referenzieren wir die ID, die wir oben erzwungen haben (String)
        final String refId = log.supplementId.toString();

        batch.insert(
          dbInstance.supplementLogs,
          db.SupplementLogsCompanion(
            supplementId: drift.Value(refId),
            amount: drift.Value(log.dose),
            takenAt: drift.Value(log.timestamp),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }
    });
  }
  // ===========================================================================
  // NUTRITION LOGS
  // ===========================================================================

  /// Records a new [FoodEntry] in the nutrition logs.
  Future<int> insertFoodEntry(FoodEntry entry) async {
    final dbInstance = await database;

    final companion = db.NutritionLogsCompanion(
      legacyBarcode: drift.Value(entry.barcode),
      consumedAt: drift.Value(entry.timestamp),
      amount: drift.Value(entry.quantityInGrams.toDouble()),
      mealType: drift.Value(entry.mealType),
    );

    final row = await dbInstance
        .into(dbInstance.nutritionLogs)
        .insertReturning(companion);
    return row.localId;
  }

  Future<void> updateFoodEntry(FoodEntry entry) async {
    if (entry.id == null) return;
    final dbInstance = await database;

    final companion = db.NutritionLogsCompanion(
      legacyBarcode: drift.Value(entry.barcode),
      consumedAt: drift.Value(entry.timestamp),
      amount: drift.Value(entry.quantityInGrams.toDouble()),
      mealType: drift.Value(entry.mealType),
    );

    await (dbInstance.update(
      dbInstance.nutritionLogs,
    )..where((tbl) => tbl.localId.equals(entry.id!)))
        .write(companion);
  }

  Future<List<FoodEntry>> getEntriesForDate(DateTime date) async {
    final dbInstance = await database;

    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = dbInstance.select(dbInstance.nutritionLogs)
      ..where((tbl) => tbl.consumedAt.isBetweenValues(start, end));

    final rows = await query.get();

    return rows.map((row) {
      return FoodEntry(
        id: row.localId,
        barcode: row.legacyBarcode ?? 'UNKNOWN',
        timestamp: row.consumedAt,
        quantityInGrams: row.amount.toInt(),
        mealType: row.mealType,
        updatedAt: row.updatedAt,
      );
    }).toList();
  }

  Future<List<FoodEntry>> getEntriesForDateRange(DateTime start, DateTime end,
      {DateTime? updatedSince}) async {
    final dbInstance = await database;

    final effectiveStart = DateTime(start.year, start.month, start.day);
    final effectiveEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final query = dbInstance.select(dbInstance.nutritionLogs)
      ..where(
        (tbl) => tbl.consumedAt.isBetweenValues(effectiveStart, effectiveEnd),
      );
    if (updatedSince != null) {
      query.where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(updatedSince));
    }

    final rows = await query.get();

    return rows.map((row) {
      return FoodEntry(
        id: row.localId,
        barcode: row.legacyBarcode ?? 'UNKNOWN',
        timestamp: row.consumedAt,
        quantityInGrams: row.amount.toInt(),
        mealType: row.mealType,
        updatedAt: row.updatedAt,
      );
    }).toList();
  }

  Future<void> deleteFoodEntry(int id) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.nutritionLogs,
    )..where((tbl) => tbl.localId.equals(id)))
        .go();
  }

  Future<List<FoodEntry>> getAllFoodEntries() async {
    final dbInstance = await database;
    final rows = await dbInstance.select(dbInstance.nutritionLogs).get();
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

  // ===========================================================================
  // FLUID LOGS
  // ===========================================================================

  /// Records a new [FluidEntry].
  Future<int> insertFluidEntry(FluidEntry entry) async {
    final dbInstance = await database;

    // 1. Getränk speichern
    final companion = db.FluidLogsCompanion(
      consumedAt: drift.Value(entry.timestamp),
      amountMl: drift.Value(entry.quantityInMl),
      name: drift.Value(entry.name),
      kcal: drift.Value(entry.kcal),
      sugarPer100ml: drift.Value(entry.sugarPer100ml),
      caffeinePer100ml: drift.Value(entry.caffeinePer100ml),
    );

    final row =
        await dbInstance.into(dbInstance.fluidLogs).insertReturning(companion);

    return row.localId;
  }

  Future<List<FluidEntry>> getFluidEntriesForDate(DateTime date) async {
    final dbInstance = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final rows = await (dbInstance.select(
      dbInstance.fluidLogs,
    )..where((tbl) => tbl.consumedAt.isBetweenValues(start, end)))
        .get();

    return rows
        .map(
          (row) => FluidEntry(
            id: row.localId,
            timestamp: row.consumedAt,
            quantityInMl: row.amountMl,
            name: row.name,
            kcal: row.kcal,
            sugarPer100ml: row.sugarPer100ml,
            caffeinePer100ml: row.caffeinePer100ml,
            carbsPer100ml: row.sugarPer100ml,
            linked_food_entry_id: null,
            updatedAt: row.updatedAt,
          ),
        )
        .toList();
  }

  Future<List<FluidEntry>> getFluidEntriesForDateRange(
      DateTime start, DateTime end,
      {DateTime? updatedSince}) async {
    final dbInstance = await database;
    final effectiveStart = DateTime(start.year, start.month, start.day);
    final effectiveEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final query = dbInstance.select(dbInstance.fluidLogs)
      ..where(
        (tbl) => tbl.consumedAt.isBetweenValues(effectiveStart, effectiveEnd),
      );
    if (updatedSince != null) {
      query.where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(updatedSince));
    }

    final rows = await query.get();

    return rows
        .map(
          (row) => FluidEntry(
            id: row.localId,
            timestamp: row.consumedAt,
            quantityInMl: row.amountMl,
            name: row.name,
            kcal: row.kcal,
            sugarPer100ml: row.sugarPer100ml,
            caffeinePer100ml: row.caffeinePer100ml,
            carbsPer100ml: row.sugarPer100ml,
            linked_food_entry_id: null,
            updatedAt: row.updatedAt,
          ),
        )
        .toList();
  }

  Future<void> updateFluidEntry(FluidEntry entry) async {
    if (entry.id == null) return;
    final dbInstance = await database;

    await (dbInstance.update(
      dbInstance.fluidLogs,
    )..where((tbl) => tbl.localId.equals(entry.id!)))
        .write(
      db.FluidLogsCompanion(
        consumedAt: drift.Value(entry.timestamp),
        amountMl: drift.Value(entry.quantityInMl),
        name: drift.Value(entry.name),
        kcal: drift.Value(entry.kcal),
        sugarPer100ml: drift.Value(entry.sugarPer100ml),
        caffeinePer100ml: drift.Value(entry.caffeinePer100ml),
      ),
    );
  }

  Future<void> deleteFluidEntry(int id) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.fluidLogs,
    )..where((tbl) => tbl.localId.equals(id)))
        .go();
  }

  Future<void> deleteFluidEntryByLinkedFoodId(int foodEntryId) async {
    final dbInstance = await database;
    final nutritionLog = await (dbInstance.select(
      dbInstance.nutritionLogs,
    )..where((tbl) => tbl.localId.equals(foodEntryId)))
        .getSingleOrNull();

    if (nutritionLog != null) {
      await (dbInstance.delete(
        dbInstance.fluidLogs,
      )..where((tbl) => tbl.linkedNutritionLogId.equals(nutritionLog.id)))
          .go();
    }
  }

  Future<List<FluidEntry>> getAllFluidEntries() async {
    final dbInstance = await database;
    final rows = await dbInstance.select(dbInstance.fluidLogs).get();
    return rows
        .map(
          (row) => FluidEntry(
            id: row.localId,
            timestamp: row.consumedAt,
            quantityInMl: row.amountMl,
            name: row.name,
            kcal: row.kcal,
            sugarPer100ml: row.sugarPer100ml,
            caffeinePer100ml: row.caffeinePer100ml,
            carbsPer100ml: row.sugarPer100ml,
            linked_food_entry_id: null,
            updatedAt: row.updatedAt,
          ),
        )
        .toList();
  }

  // ===========================================================================
  // MEASUREMENTS
  // ===========================================================================

  Future<void> insertMeasurementSession(MeasurementSession session) async {
    final dbInstance = await database;
    final legacySessionId = session.timestamp.millisecondsSinceEpoch;

    await dbInstance.batch((batch) {
      for (final m in session.measurements) {
        batch.insert(
          dbInstance.measurements,
          db.MeasurementsCompanion(
            date: drift.Value(session.timestamp),
            type: drift.Value(m.type),
            value: drift.Value(m.value),
            unit: drift.Value(m.unit),
            legacySessionId: drift.Value(legacySessionId),
          ),
        );
      }
    });
  }

  Future<List<MeasurementSession>> getMeasurementSessions({
    DateTime? updatedSince,
  }) async {
    final dbInstance = await database;
    final query = dbInstance.select(dbInstance.measurements)
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.date,
              mode: drift.OrderingMode.desc,
            ),
      ]);
    if (updatedSince != null) {
      query.where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(updatedSince));
    }

    final rows = await query.get();

    final Map<String, List<Measurement>> grouped = {};
    final Map<String, DateTime> timestamps = {};
    final Map<String, int> ids = {};
    final Map<String, DateTime> lastUpdatedAt = {};

    for (final row in rows) {
      final key = row.legacySessionId?.toString() ?? row.date.toIso8601String();

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
        timestamps[key] = row.date;
        ids[key] = row.legacySessionId ?? row.localId;
        lastUpdatedAt[key] = row.updatedAt;
      }
      if (row.updatedAt.isAfter(lastUpdatedAt[key]!)) {
        lastUpdatedAt[key] = row.updatedAt;
      }

      grouped[key]!.add(
        Measurement(
          id: row.localId,
          sessionId: ids[key]!,
          type: row.type,
          value: row.value,
          unit: row.unit,
          updatedAt: row.updatedAt,
        ),
      );
    }

    return grouped.entries.map((entry) {
      return MeasurementSession(
        id: ids[entry.key],
        timestamp: timestamps[entry.key]!,
        measurements: entry.value,
        updatedAt: lastUpdatedAt[entry.key],
      );
    }).toList();
  }

  Future<void> deleteMeasurementSession(int id) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.measurements,
    )..where((tbl) => tbl.legacySessionId.equals(id)))
        .go();
  }

  Future<DateTime?> getEarliestMeasurementDate() async {
    final dbInstance = await database;
    final query = dbInstance.select(dbInstance.measurements)
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.date,
              mode: drift.OrderingMode.asc,
            ),
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.date;
  }

  Future<List<ChartDataPoint>> getChartDataForType(String type) async {
    final dbInstance = await database;
    final query = dbInstance.select(dbInstance.measurements)
      ..where((tbl) => tbl.type.equals(type))
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.date,
              mode: drift.OrderingMode.asc,
            ),
      ]);

    final rows = await query.get();
    return rows
        .map((r) => ChartDataPoint(date: r.date, value: r.value))
        .toList();
  }

  Future<List<ChartDataPoint>> getChartDataForTypeAndRange(
    String type,
    DateTimeRange range,
  ) async {
    final dbInstance = await database;
    final query = dbInstance.select(dbInstance.measurements)
      ..where((tbl) => tbl.type.equals(type))
      ..where((tbl) => tbl.date.isBetweenValues(range.start, range.end))
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.date,
              mode: drift.OrderingMode.asc,
            ),
      ]);

    final rows = await query.get();
    return rows
        .map((r) => ChartDataPoint(date: r.date, value: r.value))
        .toList();
  }

  // ===========================================================================
  // SUPPLEMENTS
  // ===========================================================================

  Future<Supplement> insertSupplement(Supplement s) async {
    final dbInstance = await database;
    final companion = db.SupplementsCompanion(
      code: drift.Value(s.code),
      name: drift.Value(s.name),
      dose: drift.Value(s.defaultDose),
      unit: drift.Value(s.unit),
      dailyGoal: drift.Value(s.dailyGoal),
      dailyLimit: drift.Value(s.dailyLimit),
      notes: drift.Value(s.notes),
      isBuiltin: drift.Value(s.isBuiltin),
      isTracked: drift.Value(s.isTracked),
    );

    final row = await dbInstance
        .into(dbInstance.supplements)
        .insertReturning(companion);

    await insertSupplementSettingsHistory(row.id, s);

    return Supplement(
      id: row.localId,
      code: row.code,
      name: row.name,
      defaultDose: row.dose,
      unit: row.unit,
      dailyGoal: row.dailyGoal,
      dailyLimit: row.dailyLimit,
      notes: row.notes,
      isBuiltin: row.isBuiltin,
      isTracked: row.isTracked,
    );
  }

  Future<List<Supplement>> getAllSupplements() async {
    final dbInstance = await database;
    final rows = await (dbInstance.select(
      dbInstance.supplements,
    )..orderBy([(t) => drift.OrderingTerm(expression: t.name)]))
        .get();

    return rows
        .map(
          (row) => Supplement(
            id: row.localId,
            code: row.code,
            name: row.name,
            defaultDose: row.dose,
            unit: row.unit,
            dailyGoal: row.dailyGoal,
            dailyLimit: row.dailyLimit,
            notes: row.notes,
            isBuiltin: row.isBuiltin,
            isTracked: row.isTracked,
          ),
        )
        .toList();
  }

  Future<void> updateSupplement(Supplement s) async {
    if (s.id == null) return;
    final dbInstance = await database;

    final original = await (dbInstance.select(
      dbInstance.supplements,
    )..where((tbl) => tbl.localId.equals(s.id!)))
        .getSingleOrNull();

    final companion = db.SupplementsCompanion(
      code: drift.Value(s.code),
      name: drift.Value(s.name),
      dose: drift.Value(s.defaultDose),
      unit: drift.Value(s.unit),
      dailyGoal: drift.Value(s.dailyGoal),
      dailyLimit: drift.Value(s.dailyLimit),
      notes: drift.Value(s.notes),
      isBuiltin: drift.Value(s.isBuiltin),
      isTracked: drift.Value(s.isTracked),
    );

    await (dbInstance.update(
      dbInstance.supplements,
    )..where((tbl) => tbl.localId.equals(s.id!)))
        .write(companion);

    if (original != null &&
        (original.isTracked != s.isTracked ||
            original.dose != s.defaultDose ||
            original.dailyGoal != s.dailyGoal ||
            original.dailyLimit != s.dailyLimit)) {
      await insertSupplementSettingsHistory(original.id, s);
    }
  }

  Future<void> insertSupplementSettingsHistory(
    String supplementUuid,
    Supplement s,
  ) async {
    final dbInstance = await database;
    await dbInstance.into(dbInstance.supplementSettingsHistory).insert(
          db.SupplementSettingsHistoryCompanion(
            supplementId: drift.Value(supplementUuid),
            isTracked: drift.Value(s.isTracked),
            dose: drift.Value(s.defaultDose),
            dailyGoal: drift.Value(s.dailyGoal),
            dailyLimit: drift.Value(s.dailyLimit),
          ),
        );
  }

  Future<List<Supplement>> getSupplementsForDate(DateTime date) async {
    final dbInstance = await database;
    final allSupplements = await (dbInstance.select(
      dbInstance.supplements,
    )..orderBy([(t) => drift.OrderingTerm(expression: t.name)]))
        .get();

    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final List<Supplement> result = [];

    for (final row in allSupplements) {
      final historyRow =
          await (dbInstance.select(dbInstance.supplementSettingsHistory)
                ..where((tbl) => tbl.supplementId.equals(row.id))
                ..where((tbl) => tbl.createdAt.isSmallerOrEqualValue(endOfDay))
                ..orderBy([
                  (t) => drift.OrderingTerm(
                        expression: t.createdAt,
                        mode: drift.OrderingMode.desc,
                      ),
                ])
                ..limit(1))
              .getSingleOrNull();

      if (historyRow != null) {
        result.add(
          Supplement(
            id: row.localId,
            code: row.code,
            name: row.name,
            defaultDose: historyRow.dose,
            unit: row.unit,
            dailyGoal: historyRow.dailyGoal,
            dailyLimit: historyRow.dailyLimit,
            notes: row.notes,
            isBuiltin: row.isBuiltin,
            isTracked: historyRow.isTracked,
          ),
        );
      } else if (row.createdAt.isBefore(endOfDay) ||
          row.createdAt.isAtSameMomentAs(endOfDay)) {
        result.add(
          Supplement(
            id: row.localId,
            code: row.code,
            name: row.name,
            defaultDose: row.dose,
            unit: row.unit,
            dailyGoal: row.dailyGoal,
            dailyLimit: row.dailyLimit,
            notes: row.notes,
            isBuiltin: row.isBuiltin,
            isTracked: row.isTracked,
          ),
        );
      }
    }

    return result;
  }

  Future<void> deleteSupplement(int id) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.supplements,
    )..where((tbl) => tbl.localId.equals(id)))
        .go();
  }

  // ===========================================================================
  // SUPPLEMENT LOGS
  // ===========================================================================

  Future<SupplementLog> insertSupplementLog(SupplementLog log) async {
    final dbInstance = await database;

    final supplementRow = await (dbInstance.select(
      dbInstance.supplements,
    )..where((tbl) => tbl.localId.equals(log.supplementId)))
        .getSingle();

    final companion = db.SupplementLogsCompanion(
      supplementId: drift.Value(supplementRow.id),
      amount: drift.Value(log.dose),
      takenAt: drift.Value(log.timestamp),
    );

    final row = await dbInstance
        .into(dbInstance.supplementLogs)
        .insertReturning(companion);

    return SupplementLog(
      id: row.localId,
      supplementId: log.supplementId,
      dose: row.amount,
      unit: 'mg',
      timestamp: row.takenAt,
    );
  }

  Future<List<SupplementLog>> getSupplementLogsForDate(DateTime date) async {
    final dbInstance = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = dbInstance.select(dbInstance.supplementLogs).join([
      drift.innerJoin(
        dbInstance.supplements,
        dbInstance.supplements.id.equalsExp(
          dbInstance.supplementLogs.supplementId,
        ),
      ),
    ])
      ..where(dbInstance.supplementLogs.takenAt.isBetweenValues(start, end))
      ..orderBy([
        drift.OrderingTerm(
          expression: dbInstance.supplementLogs.takenAt,
          mode: drift.OrderingMode.desc,
        ),
      ]);

    final rows = await query.get();

    return rows.map((row) {
      final log = row.readTable(dbInstance.supplementLogs);
      final supp = row.readTable(dbInstance.supplements);
      return SupplementLog(
        id: log.localId,
        supplementId: supp.localId,
        dose: log.amount,
        unit: supp.unit,
        timestamp: log.takenAt,
      );
    }).toList();
  }

  Future<void> updateSupplementLog(SupplementLog log) async {
    if (log.id == null) return;
    final dbInstance = await database;

    await (dbInstance.update(
      dbInstance.supplementLogs,
    )..where((tbl) => tbl.localId.equals(log.id!)))
        .write(
      db.SupplementLogsCompanion(
        amount: drift.Value(log.dose),
        takenAt: drift.Value(log.timestamp),
      ),
    );
  }

  Future<void> deleteSupplementLog(int id) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.supplementLogs,
    )..where((tbl) => tbl.localId.equals(id)))
        .go();
  }

  Future<List<SupplementLog>> getAllSupplementLogs() async {
    final dbInstance = await database;
    final query = dbInstance.select(dbInstance.supplementLogs).join([
      drift.innerJoin(
        dbInstance.supplements,
        dbInstance.supplements.id.equalsExp(
          dbInstance.supplementLogs.supplementId,
        ),
      ),
    ]);
    final rows = await query.get();

    return rows.map((row) {
      final log = row.readTable(dbInstance.supplementLogs);
      final supp = row.readTable(dbInstance.supplements);
      return SupplementLog(
        id: log.localId,
        supplementId: supp.localId,
        dose: log.amount,
        unit: supp.unit,
        timestamp: log.takenAt,
      );
    }).toList();
  }

  // ===========================================================================
  // MEALS
  // ===========================================================================

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

  Future<int> addMealItem(
    int mealLocalId, {
    required String barcode,
    required int grams,
  }) async {
    final dbInstance = await database;

    final mealRow = await (dbInstance.select(
      dbInstance.meals,
    )..where((t) => t.localId.equals(mealLocalId)))
        .getSingle();

    final row = await dbInstance.into(dbInstance.mealItems).insertReturning(
          db.MealItemsCompanion(
            mealId: drift.Value(mealRow.id),
            productBarcode: drift.Value(barcode),
            quantityInGrams: drift.Value(grams),
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

  // ===========================================================================
  // MISC
  // ===========================================================================

  Future<DateTime?> getEarliestFoodEntryDate() async {
    final dbInstance = await database;
    final query = dbInstance.select(dbInstance.nutritionLogs)
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.consumedAt,
              mode: drift.OrderingMode.asc,
            ),
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.consumedAt;
  }

  Future<DateTime?> getEarliestFluidEntryDate() async {
    final dbInstance = await database;
    final query = dbInstance.select(dbInstance.fluidLogs)
      ..orderBy([
        (t) => drift.OrderingTerm(
              expression: t.consumedAt,
              mode: drift.OrderingMode.asc,
            ),
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.consumedAt;
  }

  Future<Set<int>> getNutritionLogDaysInMonth(DateTime month) async {
    final dbInstance = await database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final rows = await (dbInstance.selectOnly(dbInstance.nutritionLogs)
          ..addColumns([dbInstance.nutritionLogs.consumedAt])
          ..where(
            dbInstance.nutritionLogs.consumedAt.isBetweenValues(start, end),
          ))
        .get();

    return rows
        .map((r) => r.read(dbInstance.nutritionLogs.consumedAt)!.day)
        .toSet();
  }

  Future<Set<int>> getSupplementLogDaysInMonth(DateTime month) async {
    final dbInstance = await database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final rows = await (dbInstance.selectOnly(dbInstance.supplementLogs)
          ..addColumns([dbInstance.supplementLogs.takenAt])
          ..where(
            dbInstance.supplementLogs.takenAt.isBetweenValues(start, end),
          ))
        .get();

    return rows
        .map((r) => r.read(dbInstance.supplementLogs.takenAt)!.day)
        .toSet();
  }

  // Diese Methode wird vom BackupManager vielleicht aufgerufen, kann aber leer bleiben,
  // da wir die Logik direkt im Fluid-Insert handeln können oder gar nicht brauchen.
  Future<void> upsertCaffeineForFoodEntry({
    required int foodEntryId,
    required DateTime timestamp,
    required double? caffeinePer100ml,
    required double quantityInMl,
  }) async {
    // Implementierung optional, wenn du automatische Caffeine-Logs willst
  }

  // ===========================================================================
  // FAVORITEN (Fehlende Methoden für BackupManager)
  // ===========================================================================

  Future<void> addFavorite(String barcode) async {
    final dbInstance = await database;
    await dbInstance.into(dbInstance.favorites).insert(
          FavoritesCompanion(barcode: drift.Value(barcode)),
          mode: drift.InsertMode.insertOrReplace,
        );
  }

  Future<void> removeFavorite(String barcode) async {
    final dbInstance = await database;
    await (dbInstance.delete(
      dbInstance.favorites,
    )..where((t) => t.barcode.equals(barcode)))
        .go();
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

  Future<List<String>> getRecentlyUsedBarcodes() async {
    final dbInstance = await database;

    final maxDate = dbInstance.nutritionLogs.consumedAt.max();
    final query = dbInstance.selectOnly(dbInstance.nutritionLogs)
      ..addColumns([dbInstance.nutritionLogs.legacyBarcode, maxDate])
      ..groupBy([dbInstance.nutritionLogs.legacyBarcode])
      ..orderBy([
        drift.OrderingTerm(expression: maxDate, mode: drift.OrderingMode.desc),
      ])
      ..limit(20);

    final result = await query.get();

    return result
        .map((row) => row.read(dbInstance.nutritionLogs.legacyBarcode))
        .where((bc) => bc != null)
        .cast<String>()
        .toList();
  }
  // ===========================================================================
  // ONBOARDING & PROFILE HELPER (FIXED)
  // ===========================================================================

  Future<db.Profile?> getUserProfile() async {
    final dbInstance = await database;
    return await dbInstance.select(dbInstance.profiles).getSingleOrNull();
  }

  Future<db.AppSetting?> getAppSettings() async {
    final dbInstance = await database;
    return await dbInstance.select(dbInstance.appSettings).getSingleOrNull();
  }

  /// Erstellt oder aktualisiert das Basis-Profil
  Future<void> saveUserProfile({
    required String name,
    required DateTime? birthday,
    required int? height,
    required String? gender,
  }) async {
    final dbInstance = await database;

    final existing =
        await dbInstance.select(dbInstance.profiles).getSingleOrNull();

    if (existing == null) {
      // NEU anlegen
      await dbInstance.into(dbInstance.profiles).insert(
            db.ProfilesCompanion(
              username: drift.Value(name),
              birthday: drift.Value(birthday),
              height: drift.Value(height),
              gender: drift.Value(gender),
              isCoach: const drift.Value(false),
              visibility: const drift.Value('private'),
            ),
          );
    } else {
      // UPDATE
      await (dbInstance.update(
        dbInstance.profiles,
      )..where((t) => t.id.equals(existing.id)))
          .write(
        db.ProfilesCompanion(
          username: drift.Value(name),
          birthday: drift.Value(birthday),
          height: drift.Value(height),
          gender: drift.Value(gender),
        ),
      );
    }
  }

  /// Saves the user goals (AppSettings) and records a historical snapshot
  Future<void> saveUserGoals({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required int water,
    required int steps,
  }) async {
    final dbInstance = await database;

    // 1. Check if settings already exist
    final existingSettings =
        await dbInstance.select(dbInstance.appSettings).getSingleOrNull();

    // IMPORTANT: Ensure a historical baseline exists before the old goals are overwritten.
    if (existingSettings != null) {
      final baseline = await (dbInstance.select(dbInstance.dailyGoalsHistory)
            ..where(
              (t) => t.createdAt.isSmallerOrEqualValue(DateTime(2010, 1, 1)),
            )
            ..limit(1))
          .getSingleOrNull();

      if (baseline == null) {
        final existingSteps = existingSettings.targetSteps;
        await dbInstance.into(dbInstance.dailyGoalsHistory).insertReturning(
              db.DailyGoalsHistoryCompanion(
                targetCalories: drift.Value(existingSettings.targetCalories),
                targetProtein: drift.Value(existingSettings.targetProtein),
                targetCarbs: drift.Value(existingSettings.targetCarbs),
                targetFat: drift.Value(existingSettings.targetFat),
                targetWater: drift.Value(existingSettings.targetWater),
                targetSteps: drift.Value(existingSteps),
                createdAt: drift.Value(
                  DateTime(2000, 1, 1),
                ), // Covers all older data
              ),
            );
      }
    }

    if (existingSettings != null) {
      // UPDATE
      await (dbInstance.update(
        dbInstance.appSettings,
      )..where((t) => t.id.equals(existingSettings.id)))
          .write(
        db.AppSettingsCompanion(
          targetCalories: drift.Value(calories),
          targetProtein: drift.Value(protein),
          targetCarbs: drift.Value(carbs),
          targetFat: drift.Value(fat),
          targetWater: drift.Value(water),
          targetSteps: drift.Value(steps),
        ),
      );
    } else {
      // INSERT (In case saveUserProfile hasn't created settings yet)
      // We need the user ID
      final profile =
          await dbInstance.select(dbInstance.profiles).getSingleOrNull();
      if (profile == null) return;

      await dbInstance.into(dbInstance.appSettings).insert(
            db.AppSettingsCompanion(
              userId: drift.Value(profile.id),
              targetCalories: drift.Value(calories),
              targetProtein: drift.Value(protein),
              targetCarbs: drift.Value(carbs),
              targetFat: drift.Value(fat),
              targetWater: drift.Value(water),
              targetSteps: drift.Value(steps),
              themeMode: const drift.Value('system'), // Defaults
              unitSystem: const drift.Value('metric'),
            ),
          );
    }

    // 2. Add historical entry
    await dbInstance.into(dbInstance.dailyGoalsHistory).insertReturning(
          db.DailyGoalsHistoryCompanion(
            targetCalories: drift.Value(calories),
            targetProtein: drift.Value(protein),
            targetCarbs: drift.Value(carbs),
            targetFat: drift.Value(fat),
            targetWater: drift.Value(water),
            targetSteps: drift.Value(steps),
            createdAt: drift.Value(DateTime.now()), // as valid-from timestamp
          ),
        );
  }

  /// Returns the active goals for a given date.
  /// Searches the history for the newest entry created before or at the end of the day.
  /// If nothing is found, it falls back to AppSettings.
  Future<db.DailyGoalsHistoryData?> getGoalsForDate(DateTime date) async {
    final dbInstance = await database;

    // End of the requested day
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = dbInstance.select(dbInstance.dailyGoalsHistory)
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

    // If no history entry exists *before* or *on* this date,
    // meaning the date is BEFORE the first record, we take the oldest known history entry.
    final oldestHistory = await (dbInstance.select(dbInstance.dailyGoalsHistory)
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.createdAt,
                  mode: drift.OrderingMode.asc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (oldestHistory != null) return oldestHistory;

    // Absolute fallback: Current AppSettings (if history is completely empty)
    final settings = await getAppSettings();
    if (settings != null) {
      return db.DailyGoalsHistoryData(
        id: 'fallback', // dummy id
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

  Future<void> upsertHealthStepSegments(
    List<Map<String, dynamic>> segments,
  ) async {
    if (segments.isEmpty) {
      return;
    }
    final dbInstance = await database;
    await dbInstance.batch((batch) {
      for (final segment in segments) {
        final startSeconds = DateTime.parse(
              segment['startAt'] as String,
            ).toUtc().millisecondsSinceEpoch ~/
            _msPerSecond;
        final endSeconds = DateTime.parse(
              segment['endAt'] as String,
            ).toUtc().millisecondsSinceEpoch ~/
            _msPerSecond;
        final externalKey = segment['externalKey'] as String;
        batch.customStatement(
          '''
          INSERT INTO health_step_segments
          (id, provider, source_id, start_at, end_at, step_count, external_key)
          VALUES (lower(hex(randomblob(16))), ?, ?, ?, ?, ?, ?)
          ON CONFLICT(external_key) DO UPDATE SET
            provider = excluded.provider,
            source_id = excluded.source_id,
            start_at = excluded.start_at,
            end_at = excluded.end_at,
            step_count = excluded.step_count
          ''',
          [
            segment['provider'],
            segment['sourceId'],
            startSeconds,
            endSeconds,
            segment['stepCount'],
            externalKey,
          ],
        );
      }
    });
  }

  Future<void> deleteHealthStepSegmentsInRange({
    required String provider,
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final dbInstance = await database;
    final fromSeconds = fromUtc.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;
    final toSeconds = toUtc.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;
    await dbInstance.customStatement(
      '''
      DELETE FROM health_step_segments
      WHERE provider = ? AND start_at < ? AND end_at >= ?
      ''',
      [provider, toSeconds, fromSeconds],
    );
  }

  Future<int?> getDailyStepsTotal({
    required DateTime dayLocal,
    String providerFilter = 'all',
    String sourcePolicy = 'auto_dominant',
  }) async {
    final dbInstance = await database;
    final dayStartLocal = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    final dayEndLocal = dayStartLocal.add(const Duration(days: 1));
    final dayStartUtcMs =
        dayStartLocal.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;
    final dayEndUtcMs =
        dayEndLocal.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;
    var sql = sourcePolicy == 'max_per_hour'
        ? '''
      WITH source_hour AS (
        SELECT
          CAST(strftime('%H', datetime(start_at, 'unixepoch', 'localtime')) AS INTEGER) AS hour_local,
          COALESCE(source_id, '') AS source_key,
          SUM(step_count) AS source_steps
        FROM health_step_segments
        WHERE start_at < ? AND end_at >= ?
    '''
        : '''
      WITH source_totals AS (
        SELECT
          COALESCE(source_id, '') AS source_key,
          SUM(step_count) AS source_total
        FROM health_step_segments
        WHERE start_at < ? AND end_at >= ?
    ''';
    final vars = <int>[dayEndUtcMs, dayStartUtcMs];
    if (providerFilter == 'apple') {
      sql += " AND provider = 'apple_healthkit'";
    } else if (providerFilter == 'google') {
      sql += " AND provider = 'google_health_connect'";
    }
    sql += sourcePolicy == 'max_per_hour'
        ? '''
        GROUP BY hour_local, source_key
      ),
      dedup_hour AS (
        SELECT hour_local, MAX(source_steps) AS hour_steps
        FROM source_hour
        GROUP BY hour_local
      )
      SELECT COALESCE(SUM(hour_steps), 0) AS total_steps
      FROM dedup_hour
    '''
        : '''
        GROUP BY source_key
      ),
      dominant_source AS (
        SELECT source_key
        FROM source_totals
        ORDER BY source_total DESC, source_key ASC
        LIMIT 1
      )
      SELECT COALESCE(SUM(step_count), 0) AS total_steps
      FROM health_step_segments
      WHERE start_at < ? AND end_at >= ?
        AND COALESCE(source_id, '') = (SELECT source_key FROM dominant_source)
    ''';

    final allVars = sourcePolicy == 'max_per_hour'
        ? vars
        : <int>[...vars, dayEndUtcMs, dayStartUtcMs];

    final rows = await dbInstance.customSelect(
      sql,
      variables: [
        for (final variable in allVars) drift.Variable.withInt(variable),
      ],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.read<int?>('total_steps');
  }

  Future<List<Map<String, dynamic>>> getHourlyStepsTotalsForDay({
    required DateTime dayLocal,
    String providerFilter = 'all',
    String sourcePolicy = 'auto_dominant',
  }) async {
    final dbInstance = await database;
    final startLocal = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    final endLocal = startLocal.add(const Duration(days: 1));
    final startUtc = startLocal.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;
    final endUtc = endLocal.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;

    var sql = sourcePolicy == 'max_per_hour'
        ? '''
      WITH source_hour AS (
        SELECT
          CAST(strftime('%H', datetime(start_at, 'unixepoch', 'localtime')) AS INTEGER) AS hour_local,
          COALESCE(source_id, '') AS source_key,
          SUM(step_count) AS source_steps
        FROM health_step_segments
        WHERE start_at < ? AND end_at >= ?
    '''
        : '''
      WITH source_totals AS (
        SELECT
          COALESCE(source_id, '') AS source_key,
          SUM(step_count) AS source_total
        FROM health_step_segments
        WHERE start_at < ? AND end_at >= ?
    ''';
    final vars = <int>[endUtc, startUtc];
    if (providerFilter == 'apple') {
      sql += " AND provider = 'apple_healthkit'";
    } else if (providerFilter == 'google') {
      sql += " AND provider = 'google_health_connect'";
    }
    sql += sourcePolicy == 'max_per_hour'
        ? '''
        GROUP BY hour_local, source_key
      )
      SELECT hour_local, MAX(source_steps) AS total_steps
      FROM source_hour
      GROUP BY hour_local
      ORDER BY hour_local ASC
    '''
        : '''
        GROUP BY source_key
      ),
      dominant_source AS (
        SELECT source_key
        FROM source_totals
        ORDER BY source_total DESC, source_key ASC
        LIMIT 1
      )
      SELECT
        CAST(strftime('%H', datetime(start_at, 'unixepoch', 'localtime')) AS INTEGER) AS hour_local,
        SUM(step_count) AS total_steps
      FROM health_step_segments
      WHERE start_at < ? AND end_at >= ?
        AND COALESCE(source_id, '') = (SELECT source_key FROM dominant_source)
      GROUP BY hour_local
      ORDER BY hour_local ASC
    ''';

    final allVars = sourcePolicy == 'max_per_hour'
        ? vars
        : <int>[...vars, endUtc, startUtc];

    final rows = await dbInstance.customSelect(
      sql,
      variables: [
        for (final variable in allVars) drift.Variable.withInt(variable),
      ],
    ).get();
    return rows
        .map(
          (row) => <String, dynamic>{
            'hour': row.read<int>('hour_local'),
            'totalSteps': row.read<int?>('total_steps') ?? 0,
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getDailyStepsTotalsForRange({
    required DateTime startLocal,
    required DateTime endLocal,
    String providerFilter = 'all',
    String sourcePolicy = 'auto_dominant',
  }) async {
    final dbInstance = await database;
    final normalizedStart = DateTime(
      startLocal.year,
      startLocal.month,
      startLocal.day,
    );
    final normalizedEnd = DateTime(endLocal.year, endLocal.month, endLocal.day);
    if (normalizedEnd.isBefore(normalizedStart)) return const [];

    var sql = sourcePolicy == 'max_per_hour'
        ? '''
      WITH source_hour AS (
        SELECT
          date(datetime(start_at, 'unixepoch', 'localtime')) AS day_local,
          CAST(strftime('%H', datetime(start_at, 'unixepoch', 'localtime')) AS INTEGER) AS hour_local,
          COALESCE(source_id, '') AS source_key,
          SUM(step_count) AS source_steps
        FROM health_step_segments
        WHERE start_at < ? AND end_at >= ?
    '''
        : '''
      WITH source_day AS (
        SELECT
          date(datetime(start_at, 'unixepoch', 'localtime')) AS day_local,
          COALESCE(source_id, '') AS source_key,
          SUM(step_count) AS source_steps
        FROM health_step_segments
        WHERE start_at < ? AND end_at >= ?
    ''';
    final endExclusiveUtc = normalizedEnd
            .add(const Duration(days: 1))
            .toUtc()
            .millisecondsSinceEpoch ~/
        _msPerSecond;
    final startUtc =
        normalizedStart.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;
    final vars = <int>[endExclusiveUtc, startUtc];

    if (providerFilter == 'apple') {
      sql += " AND provider = 'apple_healthkit'";
    } else if (providerFilter == 'google') {
      sql += " AND provider = 'google_health_connect'";
    }

    sql += sourcePolicy == 'max_per_hour'
        ? '''
        GROUP BY day_local, hour_local, source_key
      ),
      dedup_hour AS (
        SELECT day_local, hour_local, MAX(source_steps) AS hour_steps
        FROM source_hour
        GROUP BY day_local, hour_local
      )
      SELECT day_local, SUM(hour_steps) AS total_steps
      FROM dedup_hour
      GROUP BY day_local
      ORDER BY day_local ASC
    '''
        : '''
        GROUP BY day_local, source_key
      ),
      dominant_source_per_day AS (
        SELECT
          day_local,
          source_key
        FROM source_day s
        WHERE source_steps = (
          SELECT MAX(source_steps)
          FROM source_day s2
          WHERE s2.day_local = s.day_local
        )
      ),
      chosen_source_per_day AS (
        SELECT day_local, MIN(source_key) AS source_key
        FROM dominant_source_per_day
        GROUP BY day_local
      )
      SELECT s.day_local, s.source_steps AS total_steps
      FROM source_day s
      INNER JOIN chosen_source_per_day c
        ON c.day_local = s.day_local
       AND c.source_key = s.source_key
      ORDER BY s.day_local ASC
    ''';

    final rows = await dbInstance.customSelect(
      sql,
      variables: [
        for (final variable in vars) drift.Variable.withInt(variable),
      ],
    ).get();

    return rows
        .map(
          (row) => <String, dynamic>{
            'dayLocal': row.read<String>('day_local'),
            'totalSteps': row.read<int?>('total_steps') ?? 0,
          },
        )
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getDailyStepsTotalsBySource({
    required DateTime dayLocal,
    String providerFilter = 'all',
  }) async {
    final dbInstance = await database;
    final dayStartLocal = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    final dayEndLocal = dayStartLocal.add(const Duration(days: 1));
    final dayStartUtc =
        dayStartLocal.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;
    final dayEndUtc =
        dayEndLocal.toUtc().millisecondsSinceEpoch ~/ _msPerSecond;

    var sql = '''
      SELECT
        COALESCE(source_id, '') AS source_key,
        SUM(step_count) AS total_steps
      FROM health_step_segments
      WHERE start_at < ? AND end_at >= ?
    ''';
    final vars = <int>[dayEndUtc, dayStartUtc];
    if (providerFilter == 'apple') {
      sql += " AND provider = 'apple_healthkit'";
    } else if (providerFilter == 'google') {
      sql += " AND provider = 'google_health_connect'";
    }
    sql += '''
      GROUP BY source_key
      ORDER BY total_steps DESC, source_key ASC
    ''';

    final rows = await dbInstance.customSelect(
      sql,
      variables: [
        for (final variable in vars) drift.Variable.withInt(variable),
      ],
    ).get();

    return rows
        .map(
          (row) => <String, dynamic>{
            'sourceId': row.read<String>('source_key'),
            'totalSteps': row.read<int?>('total_steps') ?? 0,
          },
        )
        .toList(growable: false);
  }

  Future<void> markHealthExported({
    required String platform,
    required String domain,
    required List<String> idempotencyKeys,
  }) async {
    if (idempotencyKeys.isEmpty) return;
    final dbInstance = await database;
    await dbInstance.batch((batch) {
      for (final key in idempotencyKeys) {
        batch.customStatement(
          '''
          INSERT INTO health_export_records
          (id, platform, domain, idempotency_key, exported_at)
          VALUES (lower(hex(randomblob(16))), ?, ?, ?, ?)
          ON CONFLICT(platform, domain, idempotency_key) DO UPDATE SET
            exported_at = excluded.exported_at
          ''',
          [
            platform,
            domain,
            key,
            DateTime.now().toUtc().millisecondsSinceEpoch ~/ _msPerSecond,
          ],
        );
      }
    });
  }

  Future<List<String>> getExportedHealthKeys({
    required String platform,
    required String domain,
    required List<String> idempotencyKeys,
  }) async {
    if (idempotencyKeys.isEmpty) return const <String>[];
    final dbInstance = await database;
    final placeholders = List.filled(idempotencyKeys.length, '?').join(',');
    final rows = await dbInstance.customSelect(
      '''
      SELECT idempotency_key
      FROM health_export_records
      WHERE platform = ?
        AND domain = ?
        AND idempotency_key IN ($placeholders)
      ''',
      variables: [
        drift.Variable.withString(platform),
        drift.Variable.withString(domain),
        for (final key in idempotencyKeys) drift.Variable.withString(key),
      ],
    ).get();
    return rows
        .map((row) => row.read<String>('idempotency_key'))
        .toList(growable: false);
  }

  Future<int> getCurrentTargetStepsOrDefault() async {
    final dbInstance = await database;
    final rows = await (dbInstance.select(
      dbInstance.appSettings,
    )..limit(1))
        .get();
    if (rows.isEmpty) return StepsSyncService.defaultStepsGoal;
    return rows.first.targetSteps;
  }

  Future<DateTime?> getEarliestHealthStepsDateLocal({
    String providerFilter = 'all',
  }) async {
    final dbInstance = await database;
    var sql = '''
      SELECT MIN(start_at) AS min_start_at
      FROM health_step_segments
    ''';
    if (providerFilter == 'apple') {
      sql += " WHERE provider = 'apple_healthkit'";
    } else if (providerFilter == 'google') {
      sql += " WHERE provider = 'google_health_connect'";
    }
    final rows = await dbInstance.customSelect(sql).get();
    if (rows.isEmpty) return null;
    final minEpoch = rows.first.read<int?>('min_start_at');
    if (minEpoch == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      minEpoch * _msPerSecond,
      isUtc: true,
    ).toLocal();
  }

  /// Speichert das Startgewicht als Messung
  Future<void> saveInitialWeight(double weightKg) async {
    final dbInstance = await database;
    final now = DateTime.now();

    await dbInstance.into(dbInstance.measurements).insert(
          db.MeasurementsCompanion(
            date: drift.Value(now),
            type: const drift.Value('weight'),
            value: drift.Value(weightKg),
            unit: const drift.Value('kg'),
            legacySessionId: drift.Value(now.millisecondsSinceEpoch),
          ),
        );
  }

  // ===========================================================================
  // AI RECOMMENDATION HELPERS
  // ===========================================================================

  /// Calculates remaining macros for [date] (target − consumed), clamped to 0.
  ///
  /// Returns `{kcal, protein, carbs, fat}`.
  Future<Map<String, int>> getRemainingMacrosForDate(DateTime date) async {
    final goals = await getGoalsForDate(date);
    final targetKcal = goals?.targetCalories ?? 2500;
    final targetProtein = goals?.targetProtein ?? 180;
    final targetCarbs = goals?.targetCarbs ?? 250;
    final targetFat = goals?.targetFat ?? 80;

    int consumedKcal = 0;
    int consumedProtein = 0;
    int consumedCarbs = 0;
    int consumedFat = 0;

    final entries = await getEntriesForDate(date);
    final productDb = ProductDatabaseHelper.instance;

    for (final entry in entries) {
      final food = await productDb.getProductByBarcode(entry.barcode);
      if (food != null) {
        final factor = entry.quantityInGrams / 100.0;
        consumedKcal += (food.calories * factor).round();
        consumedProtein += (food.protein * factor).round();
        consumedCarbs += (food.carbs * factor).round();
        consumedFat += (food.fat * factor).round();
      }
    }

    return {
      'kcal': (targetKcal - consumedKcal).clamp(0, 99999),
      'protein': (targetProtein - consumedProtein).clamp(0, 99999),
      'carbs': (targetCarbs - consumedCarbs).clamp(0, 99999),
      'fat': (targetFat - consumedFat).clamp(0, 99999),
    };
  }

  /// Builds a brief, food-name-only summary of the last [days] days.
  ///
  /// Example: `"Mon: Oatmeal, Chicken Rice | Tue: Eggs, Salad"`.
  /// Keeps token count low for the AI prompt.
  Future<String> getMealHistorySummary({int days = 7}) async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days));
    final entries = await getEntriesForDateRange(start, now);

    if (entries.isEmpty) return '';

    final productDb = ProductDatabaseHelper.instance;

    // Group by day string
    final Map<String, Set<String>> dayFoods = {};
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (final entry in entries) {
      final dayKey =
          weekdays[entry.timestamp.weekday - 1]; // weekday is 1-based
      final food = await productDb.getProductByBarcode(entry.barcode);
      if (food != null) {
        dayFoods.putIfAbsent(dayKey, () => <String>{});
        dayFoods[dayKey]!.add(food.name);
      }
    }

    return dayFoods.entries
        .map((e) => '${e.key}: ${e.value.join(', ')}')
        .join(' | ');
  }
}
