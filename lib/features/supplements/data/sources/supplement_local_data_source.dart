import 'package:drift/drift.dart' as drift;
import '../../../../data/drift_database.dart' as db;
import '../../../../data/database_helper.dart';
import '../../domain/models/supplement.dart';
import '../../domain/models/supplement_log.dart';

class SupplementLocalDataSource {
  final db.AppDatabase _dbInstance;
  SupplementLocalDataSource(this._dbInstance);
  db.AppDatabase get dbInstance => _dbInstance;
  static SupplementLocalDataSource get instance =>
      DatabaseHelper.instance.supplementLocalDataSource;

  Future<List<Supplement>> getAllSupplements() async {
    final rows = await dbInstance.select(dbInstance.supplements).get();
    return rows
        .map((row) => Supplement(
            id: row.localId,
            name: row.name,
            defaultDose: row.dose,
            unit: row.unit,
            dailyLimit: row.dailyLimit,
            code: row.code))
        .toList();
  }

  Future<int> insertSupplement(Supplement s) async {
    return await dbInstance.into(dbInstance.supplements).insert(
        db.SupplementsCompanion.insert(
            name: s.name,
            dose: s.defaultDose,
            unit: s.unit,
            dailyLimit: drift.Value(s.dailyLimit),
            code: drift.Value(s.code),
            createdAt: drift.Value(DateTime.now()),
            updatedAt: drift.Value(DateTime.now())));
  }

  Future<void> updateSupplement(Supplement s) async {
    if (s.id == null) return;
    await (dbInstance.update(dbInstance.supplements)
          ..where((tbl) => tbl.localId.equals(s.id!)))
        .write(db.SupplementsCompanion(
            name: drift.Value(s.name),
            dose: drift.Value(s.defaultDose),
            unit: drift.Value(s.unit),
            dailyLimit: drift.Value(s.dailyLimit),
            code: drift.Value(s.code),
            updatedAt: drift.Value(DateTime.now())));
  }

  Future<void> deleteSupplement(int id) async {
    await (dbInstance.delete(dbInstance.supplements)
          ..where((tbl) => tbl.localId.equals(id)))
        .go();
  }

  Future<List<SupplementLog>> getSupplementLogsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day),
        end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final query = dbInstance.select(dbInstance.supplementLogs).join([
      drift.innerJoin(
        dbInstance.supplements,
        dbInstance.supplements.id
            .equalsExp(dbInstance.supplementLogs.supplementId),
      )
    ])
      ..where(dbInstance.supplementLogs.takenAt.isBetweenValues(start, end));

    final rows = await query.get();
    return rows.map((row) {
      final log = row.readTable(dbInstance.supplementLogs);
      final s = row.readTable(dbInstance.supplements);
      return SupplementLog(
        id: log.localId,
        supplementId: s.localId,
        dose: log.amount,
        unit: s.unit,
        timestamp: log.takenAt,
        sourceFoodEntryId: null, // Add if available in table
        sourceFluidEntryId: null, // Add if available in table
      );
    }).toList();
  }

  Future<List<Supplement>> getSupplementsForDate(DateTime date) async {
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = dbInstance.select(dbInstance.supplements).join([
      drift.leftOuterJoin(
        dbInstance.supplementSettingsHistory,
        dbInstance.supplementSettingsHistory.supplementId
            .equalsExp(dbInstance.supplements.id),
      ),
    ]);

    final rows = await query.get();
    final Map<String, Supplement> latestMap = {};
    final Map<String, DateTime?> latestDateMap = {};

    for (final row in rows) {
      final s = row.readTable(dbInstance.supplements);
      final h = row.readTableOrNull(dbInstance.supplementSettingsHistory);

      final currentBestDate = latestDateMap[s.id];

      if (h == null) {
        if (!latestMap.containsKey(s.id)) {
          latestMap[s.id] = Supplement(
              id: s.localId,
              name: s.name,
              defaultDose: s.dose,
              unit: s.unit,
              dailyLimit: s.dailyLimit,
              code: s.code);
        }
      } else if (h.createdAt.isBefore(end) ||
          h.createdAt.isAtSameMomentAs(end)) {
        if (currentBestDate == null || h.createdAt.isAfter(currentBestDate)) {
          latestDateMap[s.id] = h.createdAt;
          latestMap[s.id] = Supplement(
            id: s.localId,
            name: s.name,
            defaultDose: h.dose,
            unit: s.unit,
            dailyGoal: h.dailyGoal,
            dailyLimit: h.dailyLimit,
            code: s.code,
            isTracked: h.isTracked,
          );
        }
      } else {
        if (!latestMap.containsKey(s.id)) {
          latestMap[s.id] = Supplement(
              id: s.localId,
              name: s.name,
              defaultDose: s.dose,
              unit: s.unit,
              dailyLimit: s.dailyLimit,
              code: s.code);
        }
      }
    }
    return latestMap.values.toList();
  }

  Future<void> logSupplement(
      {required int supplementId,
      required double dose,
      DateTime? takenAt}) async {
    final s = await (dbInstance.select(dbInstance.supplements)
          ..where((tbl) => tbl.localId.equals(supplementId)))
        .getSingleOrNull();
    if (s != null) {
      await dbInstance.into(dbInstance.supplementLogs).insert(
          db.SupplementLogsCompanion.insert(
              supplementId: s.id,
              amount: dose,
              takenAt: takenAt ?? DateTime.now()));
    }
  }

  Future<void> insertSupplementLog(SupplementLog log) async {
    await logSupplement(
        supplementId: log.supplementId, dose: log.dose, takenAt: log.timestamp);
  }

  Future<void> updateSupplementLog(SupplementLog log) async {
    if (log.id == null) return;
    await (dbInstance.update(dbInstance.supplementLogs)
          ..where((tbl) => tbl.localId.equals(log.id!)))
        .write(db.SupplementLogsCompanion(
            amount: drift.Value(log.dose),
            takenAt: drift.Value(log.timestamp)));
  }

  Future<void> deleteSupplementLog(int logId) async {
    await (dbInstance.delete(dbInstance.supplementLogs)
          ..where((tbl) => tbl.localId.equals(logId)))
        .go();
  }

  Future<void> ensureStandardSupplements() async {
    final rows = await dbInstance.select(dbInstance.supplements).get();
    if (rows.isEmpty) {
      final now = DateTime.now();
      await dbInstance.batch((batch) {
        batch.insertAll(dbInstance.supplements, [
          db.SupplementsCompanion.insert(
              name: 'Creatine',
              dose: 5.0,
              unit: 'g',
              createdAt: drift.Value(now),
              updatedAt: drift.Value(now)),
          db.SupplementsCompanion.insert(
              name: 'Protein',
              dose: 30.0,
              unit: 'g',
              createdAt: drift.Value(now),
              updatedAt: drift.Value(now)),
          db.SupplementsCompanion.insert(
              name: 'Caffeine',
              dose: 100.0,
              unit: 'mg',
              code: const drift.Value('caffeine'),
              createdAt: drift.Value(now),
              updatedAt: drift.Value(now)),
        ]);
      });
    }
  }

  Future<List<SupplementLog>> getAllSupplementLogsForBackup() async {
    final query = dbInstance.select(dbInstance.supplementLogs).join([
      drift.innerJoin(
        dbInstance.supplements,
        dbInstance.supplements.id
            .equalsExp(dbInstance.supplementLogs.supplementId),
      )
    ]);
    final rows = await query.get();
    return rows.map((row) {
      final log = row.readTable(dbInstance.supplementLogs);
      final s = row.readTable(dbInstance.supplements);
      return SupplementLog(
        id: log.localId,
        supplementId: s.localId,
        dose: log.amount,
        unit: s.unit,
        timestamp: log.takenAt,
      );
    }).toList();
  }
}
