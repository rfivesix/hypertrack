import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart';
import 'package:hypertrack/models/fluid_entry.dart';

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
  });
}
