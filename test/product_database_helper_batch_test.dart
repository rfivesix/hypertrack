import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart'
    show AppDatabase, ProductsCompanion;
import 'package:train_libre/features/diary/data/sources/product_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getProductsByBarcodes returns matching products in one batch',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.into(database.products).insert(
          const ProductsCompanion(
            barcode: drift.Value('a'),
            name: drift.Value('Apple'),
            calories: drift.Value(52),
            protein: drift.Value(0.3),
            carbs: drift.Value(14),
            fat: drift.Value(0.2),
            source: drift.Value('base'),
          ),
        );
    await database.into(database.products).insert(
          const ProductsCompanion(
            barcode: drift.Value('b'),
            name: drift.Value('Bread'),
            calories: drift.Value(265),
            protein: drift.Value(9),
            carbs: drift.Value(49),
            fat: drift.Value(3.2),
            source: drift.Value('base'),
          ),
        );

    final helper = ProductLocalDataSource.forTesting(
      databaseHelper: DatabaseHelper.forTesting(database),
    );

    final products = await helper.getProductsByBarcodes([
      'a',
      'a',
      'missing',
      'b',
    ]);

    expect(products.map((product) => product.barcode),
        unorderedEquals(['a', 'b']));
  });
}
