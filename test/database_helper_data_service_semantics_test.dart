import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/data/drift_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseHelper data-layer semantics', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
      DatabaseHelper.setDriftDb(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('getAllFoodEntriesForBackup falls back to linked product barcode',
        () async {
      final product = await database.into(database.products).insertReturning(
            const db.ProductsCompanion(
              barcode: drift.Value('p-123'),
              name: drift.Value('Protein Bar'),
              calories: drift.Value(400),
              protein: drift.Value(30),
              carbs: drift.Value(40),
              fat: drift.Value(15),
              source: drift.Value('user'),
            ),
          );

      await database.into(database.nutritionLogs).insert(
            db.NutritionLogsCompanion(
              productId: drift.Value(product.id),
              consumedAt: drift.Value(DateTime(2026, 4, 1, 12, 00)),
              amount: const drift.Value(75),
              mealType: const drift.Value('Snack'),
            ),
          );

      await (database.select(database.products)
            ..where((tbl) => tbl.id.equals(product.id)))
          .getSingleOrNull();

      final rows = await dbHelper.getAllFoodEntriesForBackup();

      expect(rows.length, 1);
      expect(rows.first.barcode, 'p-123');
      expect(rows.first.quantityInGrams, 75);
    });

    test(
        'getAllFoodEntriesForBackup uses UNKNOWN when no barcode source exists',
        () async {
      await database.into(database.nutritionLogs).insert(
            db.NutritionLogsCompanion(
              consumedAt: drift.Value(DateTime(2026, 4, 1, 8, 30)),
              amount: const drift.Value(120),
              mealType: const drift.Value('Breakfast'),
            ),
          );

      final rows = await dbHelper.getAllFoodEntriesForBackup();

      expect(rows.length, 1);
      expect(rows.first.barcode, 'UNKNOWN');
    });

    test(
      'getEntriesForDateRange is day-inclusive and respects updatedSince filter',
      () async {
        final start = DateTime(2026, 4, 2);
        final end = DateTime(2026, 4, 3);
        final cutoff = DateTime(2026, 4, 3, 0, 0, 0);

        await database.into(database.nutritionLogs).insert(
              db.NutritionLogsCompanion(
                legacyBarcode: const drift.Value('early'),
                consumedAt: drift.Value(DateTime(2026, 4, 2, 0, 0, 0)),
                amount: const drift.Value(100),
                mealType: const drift.Value('Breakfast'),
                updatedAt: drift.Value(DateTime(2026, 4, 2, 9, 0, 0)),
              ),
            );
        await database.into(database.nutritionLogs).insert(
              db.NutritionLogsCompanion(
                legacyBarcode: const drift.Value('late'),
                consumedAt: drift.Value(DateTime(2026, 4, 3, 23, 59, 59)),
                amount: const drift.Value(200),
                mealType: const drift.Value('Dinner'),
                updatedAt: drift.Value(DateTime(2026, 4, 3, 10, 0, 0)),
              ),
            );
        await database.into(database.nutritionLogs).insert(
              db.NutritionLogsCompanion(
                legacyBarcode: const drift.Value('outside'),
                consumedAt: drift.Value(DateTime(2026, 4, 4, 0, 0, 0)),
                amount: const drift.Value(300),
                mealType: const drift.Value('Breakfast'),
                updatedAt: drift.Value(DateTime(2026, 4, 4, 10, 0, 0)),
              ),
            );

        final ranged = await dbHelper.getEntriesForDateRange(start, end);
        final filtered = await dbHelper.getEntriesForDateRange(
          start,
          end,
          updatedSince: cutoff,
        );

        expect(ranged.map((e) => e.barcode).toSet(), {'early', 'late'});
        expect(filtered.map((e) => e.barcode).toSet(), {'late'});
      },
    );

    test(
      'getSupplementsForDate resolves latest history row or base row when absent',
      () async {
        const supplementUuid = 'supp-1';
        final supplementCreatedAt = DateTime(2026, 4, 1, 8, 0);

        await database.into(database.supplements).insert(
              db.SupplementsCompanion(
                id: const drift.Value(supplementUuid),
                name: const drift.Value('Creatine'),
                dose: const drift.Value(5.0),
                unit: const drift.Value('g'),
                isTracked: const drift.Value(true),
                createdAt: drift.Value(supplementCreatedAt),
              ),
            );

        await database.into(database.supplementSettingsHistory).insert(
              db.SupplementSettingsHistoryCompanion(
                supplementId: const drift.Value(supplementUuid),
                isTracked: const drift.Value(false),
                dose: const drift.Value(3.0),
                dailyGoal: const drift.Value(3.0),
                dailyLimit: const drift.Value(6.0),
                createdAt: drift.Value(DateTime(2026, 4, 3, 9, 0)),
              ),
            );
        await database.into(database.supplementSettingsHistory).insert(
              db.SupplementSettingsHistoryCompanion(
                supplementId: const drift.Value(supplementUuid),
                isTracked: const drift.Value(true),
                dose: const drift.Value(4.0),
                dailyGoal: const drift.Value(4.0),
                dailyLimit: const drift.Value(8.0),
                createdAt: drift.Value(DateTime(2026, 4, 5, 9, 0)),
              ),
            );

        final beforeHistory = await dbHelper.getSupplementsForDate(
          DateTime(2026, 4, 2, 12, 0),
        );
        final afterSecondHistory = await dbHelper.getSupplementsForDate(
          DateTime(2026, 4, 6, 12, 0),
        );

        expect(beforeHistory.length, 1);
        expect(beforeHistory.first.defaultDose, 5.0);
        expect(beforeHistory.first.isTracked, isTrue);

        expect(afterSecondHistory.length, 1);
        expect(afterSecondHistory.first.defaultDose, 4.0);
        expect(afterSecondHistory.first.dailyGoal, 4.0);
        expect(afterSecondHistory.first.dailyLimit, 8.0);
        expect(afterSecondHistory.first.isTracked, isTrue);
      },
    );

    test('deleteFluidEntry deletes linked nutrition log', () async {
      // Enable foreign keys for the memory database to test cascading
      await database.customStatement('PRAGMA foreign_keys = ON;');

      // 1. Create a food entry
      final foodLog =
          await database.into(database.nutritionLogs).insertReturning(
                db.NutritionLogsCompanion.insert(
                  legacyBarcode: const drift.Value('test-drink'),
                  consumedAt: DateTime(2026, 4, 1, 10, 0),
                  amount: 250,
                  mealType: const drift.Value('Snack'),
                ),
              );

      // 2. Create a linked fluid entry
      final fluidLogLocalId = await database.into(database.fluidLogs).insert(
            db.FluidLogsCompanion.insert(
              consumedAt: DateTime(2026, 4, 1, 10, 0),
              amountMl: 250,
              name: 'Test Drink',
              linkedNutritionLogId: drift.Value(foodLog.id),
            ),
          );

      // 3. Verify they both exist
      final fluidCountBefore =
          (await database.select(database.fluidLogs).get()).length;
      final foodCountBefore =
          (await database.select(database.nutritionLogs).get()).length;
      expect(fluidCountBefore, 1);
      expect(foodCountBefore, 1);

      // 4. Delete the fluid entry
      await dbHelper.deleteFluidEntry(fluidLogLocalId);

      // 5. Verify both are gone
      final fluidCountAfter =
          (await database.select(database.fluidLogs).get()).length;
      final foodCountAfter =
          (await database.select(database.nutritionLogs).get()).length;
      expect(fluidCountAfter, 0);
      expect(foodCountAfter, 0);
    });

    test('deleteFluidEntry handles standalone fluid without crashing',
        () async {
      final fluidLogLocalId = await database.into(database.fluidLogs).insert(
            db.FluidLogsCompanion(
              consumedAt: drift.Value(DateTime(2026, 4, 1, 10, 0)),
              amountMl: const drift.Value(250),
              name: const drift.Value('Water'),
            ),
          );

      await dbHelper.deleteFluidEntry(fluidLogLocalId);

      final fluidCountAfter =
          (await database.select(database.fluidLogs).get()).length;
      expect(fluidCountAfter, 0);
    });
  });
}
