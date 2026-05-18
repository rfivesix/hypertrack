import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import '../../../../data/drift_database.dart' as db;
import '../../../../data/database_helper.dart';
import '../../domain/models/measurement.dart';
import '../../domain/models/measurement_session.dart';

class ProfileLocalDataSource {
  final db.AppDatabase _dbInstance;
  ProfileLocalDataSource(this._dbInstance);
  db.AppDatabase get dbInstance => _dbInstance;
  static ProfileLocalDataSource get instance =>
      DatabaseHelper.instance.profileLocalDataSource;

  Future<db.Profile?> getUserProfile() async {
    final list = await (dbInstance.select(dbInstance.profiles)
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.localId, mode: drift.OrderingMode.desc)
          ]))
        .get();
    return list.isEmpty ? null : list.first;
  }

  Future<db.AppSetting?> getAppSettings() async {
    final list = await (dbInstance.select(dbInstance.appSettings)
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.localId, mode: drift.OrderingMode.desc)
          ]))
        .get();
    return list.isEmpty ? null : list.first;
  }

  Future<void> saveUserProfile({
    String? name,
    double? weight,
    double? height,
    int? age,
    String? gender,
    String? activityLevel,
    String? goal,
    DateTime? birthday,
  }) async {
    final finalBirthday = birthday ??
        (age != null
            ? DateTime.now().subtract(Duration(days: age * 365))
            : null);
    await dbInstance
        .into(dbInstance.profiles)
        .insertOnConflictUpdate(db.ProfilesCompanion.insert(
          username: drift.Value(name ?? 'User'),
          height: drift.Value((height ?? 175.0).toInt()),
          birthday: drift.Value(finalBirthday ?? DateTime(1990, 1, 1)),
          gender: drift.Value(gender ?? 'other'),
          visibility: const drift.Value('private'),
          updatedAt: drift.Value(DateTime.now()),
        ));
    if (weight != null) {
      await dbInstance.into(dbInstance.measurements).insert(
          db.MeasurementsCompanion.insert(
            type: 'weight',
            value: weight,
            unit: 'kg',
            date: DateTime.now(),
          ),
          mode: drift.InsertMode.insertOrReplace);
    }
  }

  Future<DateTime?> getEarliestMeasurementDate() async {
    final sessions = await getMeasurementSessions();
    return sessions.isEmpty ? null : sessions.last.timestamp;
  }

  Future<List<MeasurementSession>> getMeasurementSessions(
      {DateTime? updatedSince}) async {
    final rows = await dbInstance.select(dbInstance.measurements).get();
    final Map<int, List<Measurement>> sessionsMap = {};
    final Map<int, DateTime> sessionsTimeMap = {};
    final Map<int, DateTime> sessionsUpdateMap = {};
    for (final row in rows) {
      final sessionId = row.legacySessionId ?? row.date.millisecondsSinceEpoch;
      sessionsMap.putIfAbsent(sessionId, () => []);
      sessionsTimeMap.putIfAbsent(sessionId, () => row.date);
      sessionsMap[sessionId]!.add(Measurement(
        id: row.localId,
        sessionId: sessionId,
        type: row.type,
        value: row.value,
        unit: row.unit,
        updatedAt: row.updatedAt,
      ));
      final currentMaxUpdate = sessionsUpdateMap[sessionId];
      if (currentMaxUpdate == null || row.updatedAt.isAfter(currentMaxUpdate)) {
        sessionsUpdateMap[sessionId] = row.updatedAt;
      }
    }
    var result = sessionsMap.entries
        .map((e) => MeasurementSession(
              id: e.key,
              timestamp: sessionsTimeMap[e.key]!,
              measurements: e.value,
              updatedAt: sessionsUpdateMap[e.key],
            ))
        .toList();
    if (updatedSince != null) {
      result = result
          .where((s) =>
              s.updatedAt != null && !s.updatedAt!.isBefore(updatedSince))
          .toList();
    }
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  Future<List<Map<String, dynamic>>> getChartDataForTypeAndRange(
      String type, dynamic rangeOrStart,
      [DateTime? end]) async {
    DateTime s, e;
    if (rangeOrStart is DateTimeRange) {
      s = rangeOrStart.start;
      e = rangeOrStart.end;
    } else if (rangeOrStart is DateTime && end != null) {
      s = rangeOrStart;
      e = end;
    } else {
      throw ArgumentError('Invalid arguments');
    }
    final rows = await (dbInstance.select(dbInstance.measurements)
          ..where(
              (tbl) => tbl.type.equals(type) & tbl.date.isBetweenValues(s, e))
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.date, mode: drift.OrderingMode.asc)
          ]))
        .get();
    return rows
        .map((row) => {
              'value': row.value,
              'timestamp': row.date.millisecondsSinceEpoch,
              'date': row.date
            })
        .toList();
  }

  Future<void> saveUserGoals(
      {required int calories,
      required int protein,
      required int carbs,
      required int fat,
      required int water,
      required int steps}) async {
    // 1. Check if settings already exist
    final existingSettings = await (dbInstance.select(dbInstance.appSettings)
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.localId, mode: drift.OrderingMode.desc)
          ]))
        .get()
        .then((list) => list.isEmpty ? null : list.first);

    // IMPORTANT: Ensure a historical baseline exists before the old goals are overwritten.
    if (existingSettings != null) {
      final baseline = await (dbInstance.select(dbInstance.dailyGoalsHistory)
            ..where(
                (t) => t.createdAt.isSmallerOrEqualValue(DateTime(2010, 1, 1)))
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
      await (dbInstance.update(dbInstance.appSettings)
            ..where((t) => t.id.equals(existingSettings.id)))
          .write(
        db.AppSettingsCompanion(
          targetCalories: drift.Value(calories),
          targetProtein: drift.Value(protein),
          targetCarbs: drift.Value(carbs),
          targetFat: drift.Value(fat),
          targetWater: drift.Value(water),
          targetSteps: drift.Value(steps),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    } else {
      // INSERT (In case saveUserProfile hasn't created settings yet)
      final profile = await getUserProfile();
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
              updatedAt: drift.Value(DateTime.now()),
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

  Future<int> getCurrentTargetStepsOrDefault() async =>
      (await getAppSettings())?.targetSteps ?? 8000;

  Future<double?> getLatestBodyFatPercentageBefore(DateTime before) async {
    final row = await (dbInstance.select(dbInstance.measurements)
          ..where((tbl) =>
              tbl.type.equals('body_fat') & tbl.date.isSmallerThanValue(before))
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.date, mode: drift.OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> saveInitialWeight(double weightKg) async {
    final now = DateTime.now();
    await dbInstance.into(dbInstance.measurements).insert(
          db.MeasurementsCompanion(
            type: const drift.Value('weight'),
            value: drift.Value(weightKg),
            unit: const drift.Value('kg'),
            date: drift.Value(now),
            legacySessionId: drift.Value(now.millisecondsSinceEpoch),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
  }

  Future<void> saveInitialBodyFatPercentage(double bodyFat) async {
    final now = DateTime.now();
    await dbInstance.into(dbInstance.measurements).insert(
          db.MeasurementsCompanion(
            type: const drift.Value('body_fat'),
            value: drift.Value(bodyFat),
            unit: const drift.Value('%'),
            date: drift.Value(now),
            legacySessionId: drift.Value(now.millisecondsSinceEpoch),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
  }

  Future<void> deleteMeasurementSession(int sessionId) async {
    await (dbInstance.delete(dbInstance.measurements)
          ..where((tbl) =>
              tbl.legacySessionId.equals(sessionId) |
              tbl.date.equals(DateTime.fromMillisecondsSinceEpoch(sessionId))))
        .go();
  }

  Future<int> insertMeasurementSession(MeasurementSession session) async {
    await dbInstance.batch((batch) {
      for (final m in session.measurements) {
        batch.insert(
            dbInstance.measurements,
            db.MeasurementsCompanion.insert(
                type: m.type,
                value: m.value,
                unit: m.unit,
                date: session.timestamp,
                legacySessionId: drift.Value(session.id)),
            mode: drift.InsertMode.insertOrReplace);
      }
    });
    return session.id ?? DateTime.now().millisecondsSinceEpoch;
  }
}
