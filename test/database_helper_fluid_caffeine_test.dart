import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart' hide SupplementLog;
import 'package:train_libre/features/diary/domain/models/fluid_entry.dart';
import 'package:train_libre/features/supplements/domain/models/supplement_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseHelper.insertFluidEntry', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
      await dbHelper.ensureStandardSupplements();
    });

    tearDown(() async {
      await database.close();
    });

    test('does not auto-create caffeine supplement logs', () async {
      await dbHelper.insertFluidEntry(
        FluidEntry(
          timestamp: DateTime(2026, 3, 30, 10, 0),
          quantityInMl: 250,
          name: 'Coffee',
          kcal: null,
          sugarPer100ml: null,
          carbsPer100ml: null,
          caffeinePer100ml: 40,
        ),
      );

      final db = await dbHelper.database;
      final logs = await db.select(db.supplementLogs).get();
      expect(logs, isEmpty);
    });

    test(
        'deleting a fluid entry deletes its associated caffeine logs by timestamp',
        () async {
      final timestamp = DateTime(2026, 3, 30, 10, 0);
      final fluidId = await dbHelper.insertFluidEntry(
        FluidEntry(
          timestamp: timestamp,
          quantityInMl: 250,
          name: 'Energy Drink',
          kcal: null,
          sugarPer100ml: null,
          carbsPer100ml: null,
          caffeinePer100ml: 32,
        ),
      );

      // Simulate UI creating the caffeine log
      final supplements = await dbHelper.getAllSupplements();
      final caffeine = supplements.firstWhere((s) => s.code == 'caffeine');
      await dbHelper.insertSupplementLog(
        SupplementLog(
          supplementId: caffeine.id!,
          dose: 80,
          unit: 'mg',
          timestamp: timestamp,
        ),
      );

      final db = await dbHelper.database;
      var logs = await db.select(db.supplementLogs).get();
      expect(logs.length, 1);

      await dbHelper.deleteFluidEntry(fluidId);

      logs = await db.select(db.supplementLogs).get();
      expect(logs, isEmpty);
    });

    test('updating a fluid entry deletes old caffeine logs by timestamp',
        () async {
      final oldTimestamp = DateTime(2026, 3, 30, 10, 0);
      final newTimestamp = DateTime(2026, 3, 30, 11, 0);
      final fluidId = await dbHelper.insertFluidEntry(
        FluidEntry(
          timestamp: oldTimestamp,
          quantityInMl: 250,
          name: 'Energy Drink',
          kcal: null,
          sugarPer100ml: null,
          carbsPer100ml: null,
          caffeinePer100ml: 32,
        ),
      );

      // Simulate UI creating the caffeine log
      final supplements = await dbHelper.getAllSupplements();
      final caffeine = supplements.firstWhere((s) => s.code == 'caffeine');
      await dbHelper.insertSupplementLog(
        SupplementLog(
          supplementId: caffeine.id!,
          dose: 80,
          unit: 'mg',
          timestamp: oldTimestamp,
        ),
      );

      final db = await dbHelper.database;
      var logs = await db.select(db.supplementLogs).get();
      expect(logs.length, 1);

      await dbHelper.updateFluidEntry(FluidEntry(
        id: fluidId,
        timestamp: newTimestamp,
        quantityInMl: 500,
        name: 'Energy Drink',
        kcal: null,
        sugarPer100ml: null,
        carbsPer100ml: null,
        caffeinePer100ml: 32,
      ));

      logs = await db.select(db.supplementLogs).get();
      expect(logs, isEmpty); // Old caffeine log is deleted
    });
  });
}
