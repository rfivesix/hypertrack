import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart';
import 'package:hypertrack/models/measurement.dart';
import 'package:hypertrack/models/measurement_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseHelper goals history persistence', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'getGoalsForDate falls back to oldest history entry for dates before first snapshot',
      () async {
        final now = DateTime.now().toUtc();
        final olderCreatedAt = now.subtract(const Duration(days: 6));
        final newerCreatedAt = now.subtract(const Duration(days: 1));

        await database.into(database.dailyGoalsHistory).insert(
              DailyGoalsHistoryCompanion(
                targetCalories: const drift.Value(2100),
                targetProtein: const drift.Value(150),
                targetCarbs: const drift.Value(220),
                targetFat: const drift.Value(70),
                targetWater: const drift.Value(2500),
                targetSteps: const drift.Value(8000),
                createdAt: drift.Value(olderCreatedAt),
              ),
            );
        await database.into(database.dailyGoalsHistory).insert(
              DailyGoalsHistoryCompanion(
                targetCalories: const drift.Value(2400),
                targetProtein: const drift.Value(180),
                targetCarbs: const drift.Value(260),
                targetFat: const drift.Value(80),
                targetWater: const drift.Value(3200),
                targetSteps: const drift.Value(10000),
                createdAt: drift.Value(newerCreatedAt),
              ),
            );

        final beforeFirst = await dbHelper.getGoalsForDate(
          olderCreatedAt.subtract(const Duration(days: 2)),
        );

        expect(beforeFirst, isNotNull);
        expect(beforeFirst!.targetCalories, 2100);
        expect(beforeFirst.targetProtein, 150);
        expect(beforeFirst.targetCarbs, 220);
        expect(beforeFirst.targetFat, 70);
        expect(beforeFirst.targetWater, 2500);
        expect(beforeFirst.targetSteps, 8000);
      },
    );

    test(
      'getGoalsForDate returns latest snapshot at or before end of requested day',
      () async {
        await database.into(database.dailyGoalsHistory).insert(
              DailyGoalsHistoryCompanion(
                targetCalories: const drift.Value(2200),
                targetProtein: const drift.Value(160),
                targetCarbs: const drift.Value(230),
                targetFat: const drift.Value(75),
                targetWater: const drift.Value(2700),
                targetSteps: const drift.Value(8500),
                createdAt: drift.Value(DateTime(2026, 4, 1, 9, 0)),
              ),
            );
        await database.into(database.dailyGoalsHistory).insert(
              DailyGoalsHistoryCompanion(
                targetCalories: const drift.Value(2600),
                targetProtein: const drift.Value(190),
                targetCarbs: const drift.Value(300),
                targetFat: const drift.Value(85),
                targetWater: const drift.Value(3300),
                targetSteps: const drift.Value(11000),
                createdAt: drift.Value(DateTime(2026, 4, 1, 20, 0)),
              ),
            );
        await database.into(database.dailyGoalsHistory).insert(
              DailyGoalsHistoryCompanion(
                targetCalories: const drift.Value(2000),
                targetProtein: const drift.Value(145),
                targetCarbs: const drift.Value(190),
                targetFat: const drift.Value(65),
                targetWater: const drift.Value(2400),
                targetSteps: const drift.Value(7000),
                createdAt: drift.Value(DateTime(2026, 4, 2, 8, 0)),
              ),
            );

        final goalsForApril1 = await dbHelper.getGoalsForDate(
          DateTime(2026, 4, 1, 10, 0),
        );
        final goalsForApril2 = await dbHelper.getGoalsForDate(
          DateTime(2026, 4, 2, 12, 0),
        );

        expect(goalsForApril1, isNotNull);
        expect(goalsForApril1!.targetCalories, 2600);
        expect(goalsForApril1.targetSteps, 11000);

        expect(goalsForApril2, isNotNull);
        expect(goalsForApril2!.targetCalories, 2000);
        expect(goalsForApril2.targetSteps, 7000);
      },
    );
  });

  group('DatabaseHelper weight/measurement history', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('measurement sessions are returned newest-first with grouped entries',
        () async {
      final olderTs = DateTime(2026, 4, 1, 7, 30);
      final newerTs = DateTime(2026, 4, 3, 7, 45);

      await dbHelper.insertMeasurementSession(
        MeasurementSession(
          timestamp: olderTs,
          measurements: [
            Measurement(
              sessionId: 0,
              type: 'weight',
              value: 79.0,
              unit: 'kg',
            ),
            Measurement(
              sessionId: 0,
              type: 'body_fat',
              value: 18.5,
              unit: '%',
            ),
          ],
        ),
      );
      await dbHelper.insertMeasurementSession(
        MeasurementSession(
          timestamp: newerTs,
          measurements: [
            Measurement(
              sessionId: 0,
              type: 'weight',
              value: 78.2,
              unit: 'kg',
            ),
          ],
        ),
      );

      final sessions = await dbHelper.getMeasurementSessions();

      expect(sessions.length, 2);
      expect(sessions[0].timestamp, newerTs);
      expect(sessions[0].measurements.length, 1);
      expect(sessions[0].measurements.first.type, 'weight');
      expect(sessions[0].measurements.first.value, 78.2);

      expect(sessions[1].timestamp, olderTs);
      expect(sessions[1].measurements.length, 2);
      expect(
        sessions[1].measurements.map((m) => m.type).toSet(),
        {'weight', 'body_fat'},
      );
    });

    test('getChartDataForTypeAndRange returns ordered, inclusive points', () async {
      final day1 = DateTime(2026, 4, 1, 7, 0);
      final day2 = DateTime(2026, 4, 2, 7, 0);
      final day3 = DateTime(2026, 4, 3, 7, 0);
      final day4 = DateTime(2026, 4, 4, 7, 0);

      await dbHelper.insertMeasurementSession(
        MeasurementSession(
          timestamp: day1,
          measurements: [
            Measurement(
              sessionId: 0,
              type: 'weight',
              value: 79.4,
              unit: 'kg',
            ),
          ],
        ),
      );
      await dbHelper.insertMeasurementSession(
        MeasurementSession(
          timestamp: day2,
          measurements: [
            Measurement(
              sessionId: 0,
              type: 'weight',
              value: 79.0,
              unit: 'kg',
            ),
          ],
        ),
      );
      await dbHelper.insertMeasurementSession(
        MeasurementSession(
          timestamp: day3,
          measurements: [
            Measurement(
              sessionId: 0,
              type: 'weight',
              value: 78.7,
              unit: 'kg',
            ),
          ],
        ),
      );
      await dbHelper.insertMeasurementSession(
        MeasurementSession(
          timestamp: day4,
          measurements: [
            Measurement(
              sessionId: 0,
              type: 'weight',
              value: 78.4,
              unit: 'kg',
            ),
          ],
        ),
      );

      final points = await dbHelper.getChartDataForTypeAndRange(
        'weight',
        DateTimeRange(start: day2, end: day3),
      );

      expect(points.length, 2);
      expect(points[0].date, day2);
      expect(points[0].value, 79.0);
      expect(points[1].date, day3);
      expect(points[1].value, 78.7);
    });

    test('saveInitialWeight persists a weight measurement in kg', () async {
      await dbHelper.saveInitialWeight(81.3);

      final rows = await database.select(database.measurements).get();
      expect(rows.length, 1);
      expect(rows.first.type, 'weight');
      expect(rows.first.unit, 'kg');
      expect(rows.first.value, 81.3);
      expect(rows.first.legacySessionId, isNotNull);
    });
  });
}
