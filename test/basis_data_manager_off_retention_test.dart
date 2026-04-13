import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/basis_data_manager.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart' as db;
import 'package:hypertrack/data/drift_database.dart';
import 'package:hypertrack/data/product_database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BasisDataManager OFF retention semantics', () {
    late AppDatabase database;
    late ProductDatabaseHelper productDb;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      productDb = ProductDatabaseHelper.forTesting(
        databaseHelper: DatabaseHelper.forTesting(database),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'replacement retains historically referenced OFF products and prunes orphaned rows',
      () async {
        await database.into(database.products).insert(
              const db.ProductsCompanion(
                id: drift.Value('off-a'),
                barcode: drift.Value('A'),
                name: drift.Value('Old A'),
                calories: drift.Value(100),
                protein: drift.Value(1),
                carbs: drift.Value(10),
                fat: drift.Value(1),
                source: drift.Value('off'),
              ),
            );
        await database.into(database.products).insert(
              const db.ProductsCompanion(
                id: drift.Value('off-b'),
                barcode: drift.Value('B'),
                name: drift.Value('Old B'),
                calories: drift.Value(110),
                protein: drift.Value(1),
                carbs: drift.Value(11),
                fat: drift.Value(1),
                source: drift.Value('off'),
              ),
            );
        await database.into(database.products).insert(
              const db.ProductsCompanion(
                id: drift.Value('off-c'),
                barcode: drift.Value('C'),
                name: drift.Value('Old C'),
                calories: drift.Value(120),
                protein: drift.Value(1),
                carbs: drift.Value(12),
                fat: drift.Value(1),
                source: drift.Value('off'),
              ),
            );
        await database.into(database.products).insert(
              const db.ProductsCompanion(
                id: drift.Value('off-d'),
                barcode: drift.Value('D'),
                name: drift.Value('Active D'),
                calories: drift.Value(130),
                protein: drift.Value(1),
                carbs: drift.Value(13),
                fat: drift.Value(1),
                source: drift.Value('off'),
              ),
            );

        await database.into(database.nutritionLogs).insert(
              db.NutritionLogsCompanion(
                legacyBarcode: const drift.Value('A'),
                consumedAt: drift.Value(DateTime(2026, 4, 12, 10, 0)),
                amount: const drift.Value(150),
                mealType: const drift.Value('Lunch'),
              ),
            );
        await database.into(database.favorites).insert(
              const db.FavoritesCompanion(barcode: drift.Value('B')),
            );

        await BasisDataManager.instance.retainHistoricallyNeededOffProducts(
          importedOffBarcodes: {'D'},
          testingDatabase: database,
        );

        final byA = await productDb.getProductByBarcode('A');
        final byB = await productDb.getProductByBarcode('B');
        final byC = await productDb.getProductByBarcode('C');
        final byD = await productDb.getProductByBarcode('D');
        final searchOld = await productDb.searchProducts('Old');

        expect(byA, isNotNull);
        expect(byB, isNotNull);
        expect(byC, isNull);
        expect(byD, isNotNull);

        final sourceByBarcode = {
          for (final row in await database.select(database.products).get())
            row.barcode: row.source,
        };
        expect(sourceByBarcode['A'], 'off_retained');
        expect(sourceByBarcode['B'], 'off_retained');
        expect(sourceByBarcode['D'], 'off');

        // Retained rows are excluded from active OFF search.
        expect(searchOld, isEmpty);
      },
    );

    test('empty imported set is non-destructive', () async {
      await database.into(database.products).insert(
            const db.ProductsCompanion(
              barcode: drift.Value('X'),
              name: drift.Value('Old X'),
              calories: drift.Value(100),
              protein: drift.Value(1),
              carbs: drift.Value(10),
              fat: drift.Value(1),
              source: drift.Value('off'),
            ),
          );

      await BasisDataManager.instance.retainHistoricallyNeededOffProducts(
        importedOffBarcodes: <String>{},
        testingDatabase: database,
      );

      final row = await (database.select(
        database.products,
      )..where((t) => t.barcode.equals('X')))
          .getSingleOrNull();
      expect(row, isNotNull);
      expect(row!.source, 'off');
    });

    test('reintroduced barcode remains in active OFF source', () async {
      await database.into(database.products).insert(
            const db.ProductsCompanion(
              id: drift.Value('off-z'),
              barcode: drift.Value('Z'),
              name: drift.Value('Retained Z'),
              calories: drift.Value(100),
              protein: drift.Value(1),
              carbs: drift.Value(10),
              fat: drift.Value(1),
              source: drift.Value('off_retained'),
            ),
          );

      // Simulate an import re-introducing Z as part of the active OFF dataset.
      await (database.update(database.products)
            ..where((t) => t.barcode.equals('Z')))
          .write(const db.ProductsCompanion(source: drift.Value('off')));

      await BasisDataManager.instance.retainHistoricallyNeededOffProducts(
        importedOffBarcodes: {'Z'},
        testingDatabase: database,
      );

      final row = await (database.select(
        database.products,
      )..where((t) => t.barcode.equals('Z')))
          .getSingle();
      expect(row.source, 'off');
    });
  });
}
