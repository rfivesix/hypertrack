import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart';
import 'package:hypertrack/health_export/contracts/health_export_adapter.dart';
import 'package:hypertrack/health_export/data/health_export_data_source.dart';
import 'package:hypertrack/health_export/data/health_export_status_store.dart';
import 'package:hypertrack/health_export/export_service.dart';
import 'package:hypertrack/health_export/models/export_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAdapter implements HealthExportAdapter {
  _FakeAdapter(
    this.platform, {
    this.failWorkout = false,
    this.failNutrition = false,
    this.failHydration = false,
    this.failMeasurementAtWriteCount,
  });

  @override
  final HealthExportPlatform platform;

  final bool failWorkout;
  final bool failNutrition;
  final bool failHydration;
  int? failMeasurementAtWriteCount;

  int measurementWrites = 0;
  int nutritionWrites = 0;
  int hydrationWrites = 0;
  int workoutWrites = 0;
  int measurementBatchWrites = 0;
  int nutritionBatchWrites = 0;
  int hydrationBatchWrites = 0;
  int workoutBatchWrites = 0;

  @override
  Future<HealthExportAvailability> getAvailability() async =>
      HealthExportAvailability.available;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> writeHydration(ExportHydrationRecord record) async {
    hydrationWrites += 1;
    if (failHydration) {
      throw Exception('hydration failure');
    }
  }

  @override
  Future<void> writeMeasurement(ExportMeasurementRecord record) async {
    measurementWrites += 1;
    final failAt = failMeasurementAtWriteCount;
    if (failAt != null && measurementWrites == failAt) {
      throw Exception('measurement failure at $failAt');
    }
  }

  @override
  Future<void> writeNutrition(ExportNutritionRecord record) async {
    nutritionWrites += 1;
    if (failNutrition) {
      throw Exception('nutrition failure');
    }
  }

  @override
  Future<void> writeWorkout(ExportWorkoutRecord record) async {
    workoutWrites += 1;
    if (failWorkout) {
      throw Exception('workout failure');
    }
  }

  @override
  Future<void> writeMeasurementsBatch(
    List<ExportMeasurementRecord> records,
  ) async {
    measurementBatchWrites += 1;
    for (final record in records) {
      await writeMeasurement(record);
    }
  }

  @override
  Future<void> writeNutritionBatch(List<ExportNutritionRecord> records) async {
    nutritionBatchWrites += 1;
    for (final record in records) {
      await writeNutrition(record);
    }
  }

  @override
  Future<void> writeHydrationBatch(List<ExportHydrationRecord> records) async {
    hydrationBatchWrites += 1;
    for (final record in records) {
      await writeHydration(record);
    }
  }

  @override
  Future<void> writeWorkoutsBatch(List<ExportWorkoutRecord> records) async {
    workoutBatchWrites += 1;
    for (final record in records) {
      await writeWorkout(record);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthExportService', () {
    late AppDatabase db;
    late DatabaseHelper dbHelper;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      db = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(db);
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS health_export_records (
          local_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          id TEXT NOT NULL UNIQUE,
          platform TEXT NOT NULL,
          domain TEXT NOT NULL,
          idempotency_key TEXT NOT NULL,
          exported_at INTEGER NOT NULL,
          UNIQUE(platform, domain, idempotency_key)
        )
      ''');
      await _seedExportData(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('tracks disabled state until permission granted', () async {
      final adapter = _FakeAdapter(HealthExportPlatform.appleHealth);
      final service = HealthExportService(
        adapters: [adapter],
        dataSource: HealthExportDataSource(databaseHelper: dbHelper),
        statusStore: HealthExportStatusStore(databaseHelper: dbHelper),
      );

      final enabledBefore = await service.isPlatformEnabled(
        HealthExportPlatform.appleHealth,
      );
      expect(enabledBefore, isFalse);

      final permission = await service.requestPermissions(
        HealthExportPlatform.appleHealth,
      );
      expect(permission.success, isTrue);

      final enabledAfter = await service.isPlatformEnabled(
        HealthExportPlatform.appleHealth,
      );
      expect(enabledAfter, isTrue);
    });

    test('persists successful status and idempotent retries', () async {
      final adapter = _FakeAdapter(HealthExportPlatform.appleHealth);
      final service = HealthExportService(
        adapters: [adapter],
        dataSource: HealthExportDataSource(databaseHelper: dbHelper),
        statusStore: HealthExportStatusStore(databaseHelper: dbHelper),
      );

      await service.requestPermissions(HealthExportPlatform.appleHealth);
      final first = await service.exportNow(
        HealthExportPlatform.appleHealth,
        lookbackDays: 1,
      );
      expect(first.success, isTrue);

      final writesFirst = {
        'm': adapter.measurementWrites,
        'n': adapter.nutritionWrites,
        'h': adapter.hydrationWrites,
        'w': adapter.workoutWrites,
      };
      expect(writesFirst['m'], greaterThan(0));
      expect(writesFirst['n'], greaterThan(0));
      expect(writesFirst['h'], greaterThan(0));
      expect(writesFirst['w'], greaterThan(0));

      final second = await service.exportNow(
        HealthExportPlatform.appleHealth,
        lookbackDays: 1,
      );
      expect(second.success, isTrue);

      expect(adapter.measurementWrites, writesFirst['m']);
      expect(adapter.nutritionWrites, writesFirst['n']);
      expect(adapter.hydrationWrites, writesFirst['h']);
      expect(adapter.workoutWrites, writesFirst['w']);

      final statuses = await service.getStatuses();
      final platformStatus = statuses[HealthExportPlatform.appleHealth]!;
      for (final domain in HealthExportDomain.values) {
        expect(
          platformStatus.statusFor(domain).state,
          HealthExportState.success,
        );
      }
    });

    test('manual export defaults to full-history backfill', () async {
      final oldTimestamp = DateTime.now().toUtc().subtract(
            const Duration(days: 120),
          );
      await db.into(db.measurements).insert(
            MeasurementsCompanion(
              date: drift.Value(oldTimestamp),
              type: const drift.Value('weight'),
              value: const drift.Value(70),
              unit: const drift.Value('kg'),
              legacySessionId: const drift.Value(9999),
            ),
          );

      final adapter = _FakeAdapter(HealthExportPlatform.appleHealth);
      final service = HealthExportService(
        adapters: [adapter],
        dataSource: HealthExportDataSource(databaseHelper: dbHelper),
        statusStore: HealthExportStatusStore(databaseHelper: dbHelper),
      );

      await service.requestPermissions(HealthExportPlatform.appleHealth);
      final result = await service.exportNow(HealthExportPlatform.appleHealth);

      expect(result.success, isTrue);
      expect(adapter.measurementWrites, 2);
    });

    test(
      'after initial backfill, later export is incremental for new records',
      () async {
        final adapter = _FakeAdapter(HealthExportPlatform.appleHealth);
        final service = HealthExportService(
          adapters: [adapter],
          dataSource: HealthExportDataSource(databaseHelper: dbHelper),
          statusStore: HealthExportStatusStore(databaseHelper: dbHelper),
        );

        await service.requestPermissions(HealthExportPlatform.appleHealth);
        final first = await service.exportNow(HealthExportPlatform.appleHealth);
        expect(first.success, isTrue);
        final firstMeasurementWrites = adapter.measurementWrites;

        await db.into(db.measurements).insert(
              MeasurementsCompanion(
                date: drift.Value(DateTime.now().toUtc()),
                type: const drift.Value('weight'),
                value: const drift.Value(81),
                unit: const drift.Value('kg'),
                legacySessionId: const drift.Value(3001),
              ),
            );

        final second = await service.exportNow(
          HealthExportPlatform.appleHealth,
        );
        expect(second.success, isTrue);
        expect(adapter.measurementWrites, firstMeasurementWrites + 1);
        expect(adapter.measurementBatchWrites, greaterThan(0));
      },
    );

    test(
      'chunked export marks progress and retry resumes after 1000 writes',
      () async {
        final now = DateTime.now().toUtc();
        for (var i = 0; i < 1500; i++) {
          await db.into(db.measurements).insert(
                MeasurementsCompanion(
                  date: drift.Value(now.subtract(Duration(minutes: i))),
                  type: const drift.Value('weight'),
                  value: drift.Value(60 + (i % 30).toDouble()),
                  unit: const drift.Value('kg'),
                  legacySessionId: drift.Value(5000 + i),
                ),
              );
        }

        final adapter = _FakeAdapter(
          HealthExportPlatform.appleHealth,
          failMeasurementAtWriteCount: 1001,
        );
        final service = HealthExportService(
          adapters: [adapter],
          dataSource: HealthExportDataSource(databaseHelper: dbHelper),
          statusStore: HealthExportStatusStore(databaseHelper: dbHelper),
        );

        await service.requestPermissions(HealthExportPlatform.appleHealth);
        final first = await service.exportNow(HealthExportPlatform.appleHealth);
        expect(first.success, isFalse);
        expect(adapter.measurementWrites, 1001);

        adapter.failMeasurementAtWriteCount = null;
        final second = await service.exportNow(
          HealthExportPlatform.appleHealth,
        );
        expect(second.success, isTrue);
        expect(adapter.measurementWrites, 1502);
        expect(
          adapter.measurementBatchWrites,
          4,
          reason:
              'Two export attempts across >1000 records should split into chunked batch calls',
        );
      },
    );

    test('marks failed domain while keeping others successful', () async {
      final adapter = _FakeAdapter(
        HealthExportPlatform.healthConnect,
        failWorkout: true,
      );
      final service = HealthExportService(
        adapters: [adapter],
        dataSource: HealthExportDataSource(databaseHelper: dbHelper),
        statusStore: HealthExportStatusStore(databaseHelper: dbHelper),
      );

      await service.requestPermissions(HealthExportPlatform.healthConnect);
      final result = await service.exportNow(
        HealthExportPlatform.healthConnect,
        lookbackDays: 1,
      );

      expect(result.success, isFalse);
      final statuses = await service.getStatuses();
      final platformStatus = statuses[HealthExportPlatform.healthConnect]!;
      expect(
        platformStatus.statusFor(HealthExportDomain.measurements).state,
        HealthExportState.success,
      );
      expect(
        platformStatus.statusFor(HealthExportDomain.nutritionHydration).state,
        HealthExportState.success,
      );
      expect(
        platformStatus.statusFor(HealthExportDomain.workouts).state,
        HealthExportState.failed,
      );
      expect(
        platformStatus.statusFor(HealthExportDomain.workouts).lastError,
        isNotNull,
      );
    });

    test(
      'keeps hydration writes running and reports split diagnostics',
      () async {
        final adapter = _FakeAdapter(
          HealthExportPlatform.healthConnect,
          failNutrition: true,
        );
        final service = HealthExportService(
          adapters: [adapter],
          dataSource: HealthExportDataSource(databaseHelper: dbHelper),
          statusStore: HealthExportStatusStore(databaseHelper: dbHelper),
        );

        await service.requestPermissions(HealthExportPlatform.healthConnect);
        final result = await service.exportNow(
          HealthExportPlatform.healthConnect,
          lookbackDays: 1,
        );

        expect(result.success, isFalse);
        expect(adapter.nutritionWrites, greaterThan(0));
        expect(adapter.hydrationWrites, greaterThan(0));

        final statuses = await service.getStatuses();
        final platformStatus = statuses[HealthExportPlatform.healthConnect]!;
        final grouped = platformStatus.statusFor(
          HealthExportDomain.nutritionHydration,
        );
        expect(grouped.state, HealthExportState.failed);
        expect(grouped.lastError, contains('nutrition=failed'));
        expect(grouped.lastError, contains('hydration=success'));
        expect(grouped.lastError, contains('1/1'));
      },
    );

    test(
      'split diagnostics keep truthful counts for opposite failure direction',
      () async {
        final adapter = _FakeAdapter(
          HealthExportPlatform.healthConnect,
          failHydration: true,
        );
        final service = HealthExportService(
          adapters: [adapter],
          dataSource: HealthExportDataSource(databaseHelper: dbHelper),
          statusStore: HealthExportStatusStore(databaseHelper: dbHelper),
        );

        await service.requestPermissions(HealthExportPlatform.healthConnect);
        final result = await service.exportNow(
          HealthExportPlatform.healthConnect,
          lookbackDays: 1,
        );

        expect(result.success, isFalse);
        final statuses = await service.getStatuses();
        final grouped = statuses[HealthExportPlatform.healthConnect]!.statusFor(
          HealthExportDomain.nutritionHydration,
        );
        expect(grouped.lastError, contains('nutrition=success(1/1)'));
        expect(grouped.lastError, contains('hydration=failed(0/1'));
      },
    );

    test(
      'domain failure no longer forces full-history reload for all domains',
      () async {
        final failingWorkouts = _FakeAdapter(
          HealthExportPlatform.healthConnect,
          failWorkout: true,
        );
        final serviceWithFailure = HealthExportService(
          adapters: [failingWorkouts],
          dataSource: HealthExportDataSource(databaseHelper: dbHelper),
          statusStore: HealthExportStatusStore(databaseHelper: dbHelper),
        );

        await serviceWithFailure.requestPermissions(
          HealthExportPlatform.healthConnect,
        );
        final first = await serviceWithFailure.exportNow(
          HealthExportPlatform.healthConnect,
        );
        expect(first.success, isFalse);
        expect(failingWorkouts.measurementWrites, 1);
        expect(failingWorkouts.nutritionWrites, 1);
        expect(failingWorkouts.hydrationWrites, 1);

        final succeeding = _FakeAdapter(HealthExportPlatform.healthConnect);
        final serviceAfterFailure = HealthExportService(
          adapters: [succeeding],
          dataSource: HealthExportDataSource(databaseHelper: dbHelper),
          statusStore: HealthExportStatusStore(databaseHelper: dbHelper),
        );
        await serviceAfterFailure.requestPermissions(
          HealthExportPlatform.healthConnect,
        );
        final second = await serviceAfterFailure.exportNow(
          HealthExportPlatform.healthConnect,
        );
        expect(second.success, isTrue);
        expect(
          succeeding.measurementWrites,
          0,
          reason: 'Measurements keep their checkpoint and stay incremental',
        );
        expect(
          succeeding.nutritionWrites,
          0,
          reason: 'Nutrition keeps its checkpoint and stays incremental',
        );
        expect(
          succeeding.hydrationWrites,
          0,
          reason: 'Hydration keeps its checkpoint and stays incremental',
        );
        expect(
          succeeding.workoutWrites,
          1,
          reason: 'Only failed workouts domain backfills/retries',
        );
      },
    );

    test('skips BMI writes for Health Connect measurement export', () async {
      final now = DateTime.now().toUtc();
      await db.into(db.measurements).insert(
            MeasurementsCompanion(
              date: drift.Value(now.subtract(const Duration(hours: 3))),
              type: const drift.Value('bmi'),
              value: const drift.Value(25),
              unit: const drift.Value('kg/m2'),
              legacySessionId: const drift.Value(1002),
            ),
          );

      final adapter = _FakeAdapter(HealthExportPlatform.healthConnect);
      final service = HealthExportService(
        adapters: [adapter],
        dataSource: HealthExportDataSource(databaseHelper: dbHelper),
        statusStore: HealthExportStatusStore(databaseHelper: dbHelper),
      );

      await service.requestPermissions(HealthExportPlatform.healthConnect);
      final result = await service.exportNow(
        HealthExportPlatform.healthConnect,
        lookbackDays: 1,
      );

      expect(result.success, isTrue);
      expect(adapter.measurementWrites, 1);
    });
  });
}

Future<void> _seedExportData(AppDatabase db) async {
  final now = DateTime.now().toUtc();
  final measurementAt = now.subtract(const Duration(hours: 4));
  final nutritionAt = now.subtract(const Duration(hours: 3));
  final hydrationAt = now.subtract(const Duration(hours: 2));
  final workoutStart = now.subtract(const Duration(hours: 1));
  final workoutEnd = now.subtract(const Duration(minutes: 15));

  await db.into(db.products).insert(
        const ProductsCompanion(
          barcode: drift.Value('export-product-1'),
          name: drift.Value('Export Product'),
          calories: drift.Value(200),
          protein: drift.Value(20),
          carbs: drift.Value(30),
          fat: drift.Value(10),
          fiber: drift.Value(5),
          sugar: drift.Value(7),
          salt: drift.Value(2),
          source: drift.Value('user'),
        ),
      );

  await db.into(db.nutritionLogs).insert(
        NutritionLogsCompanion(
          consumedAt: drift.Value(nutritionAt),
          amount: const drift.Value(150),
          mealType: const drift.Value('Snack'),
          legacyBarcode: const drift.Value('export-product-1'),
        ),
      );

  await db.into(db.fluidLogs).insert(
        FluidLogsCompanion(
          consumedAt: drift.Value(hydrationAt),
          amountMl: const drift.Value(500),
          name: const drift.Value('Water'),
        ),
      );

  await db.into(db.measurements).insert(
        MeasurementsCompanion(
          date: drift.Value(measurementAt),
          type: const drift.Value('weight'),
          value: const drift.Value(80),
          unit: const drift.Value('kg'),
          legacySessionId: const drift.Value(1001),
        ),
      );

  await db.into(db.workoutLogs).insert(
        WorkoutLogsCompanion(
          startTime: drift.Value(workoutStart),
          endTime: drift.Value(workoutEnd),
          status: const drift.Value('completed'),
          routineNameSnapshot: const drift.Value('Strength Session'),
        ),
      );
}
