import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../../data/drift_database.dart';

/// Use Case to manage Open Food Facts (OFF) barcode lifecycle and retention:
/// - Retains historically referenced OFF barcodes by demoting them to `off_retained`
/// - Deletes unreferenced and no-longer-imported OFF barcodes
class RetainHistoricalOffProductsUseCase {
  const RetainHistoricalOffProductsUseCase();

  Future<void> execute({
    required AppDatabase database,
    required Set<String> importedOffBarcodes,
    void Function(String message, String detail, double progress)? onProgress,
  }) async {
    if (importedOffBarcodes.isEmpty) {
      debugPrint(
        'Skipping OFF retention pass because imported barcode set is empty.',
      );
      return;
    }

    final protectedBarcodes = await loadHistoricallyProtectedBarcodes(database);

    final offRows = await (database.select(
      database.products,
    )..where((t) => t.source.equals('off')))
        .get();

    final barcodesToRetain = <String>[];
    final barcodesToDelete = <String>[];

    for (final row in offRows) {
      final barcode = row.barcode.trim();
      if (barcode.isEmpty || importedOffBarcodes.contains(barcode)) continue;

      if (protectedBarcodes.contains(barcode)) {
        barcodesToRetain.add(barcode);
      } else {
        barcodesToDelete.add(barcode);
      }
    }

    await applyOffRetentionUpdates(
      database: database,
      barcodesToRetain: barcodesToRetain,
      barcodesToDelete: barcodesToDelete,
    );

    onProgress?.call(
      'Update Produktdatenbank',
      'OFF-Daten bereinigt: ${barcodesToRetain.length} behalten, ${barcodesToDelete.length} entfernt',
      1.0,
    );
  }

  Future<Set<String>> loadHistoricallyProtectedBarcodes(AppDatabase db) async {
    final protected = <String>{};

    final nutritionLegacyRows = await db.customSelect('''
      SELECT DISTINCT legacy_barcode AS barcode
      FROM nutrition_logs
      WHERE legacy_barcode IS NOT NULL AND TRIM(legacy_barcode) != ''
      ''').get();
    for (final row in nutritionLegacyRows) {
      final barcode = (row.data['barcode'] as String?)?.trim() ?? '';
      if (barcode.isNotEmpty) protected.add(barcode);
    }

    final favoritesRows = await db.customSelect('''
      SELECT DISTINCT barcode
      FROM favorites
      WHERE barcode IS NOT NULL AND TRIM(barcode) != ''
      ''').get();
    for (final row in favoritesRows) {
      final barcode = (row.data['barcode'] as String?)?.trim() ?? '';
      if (barcode.isNotEmpty) protected.add(barcode);
    }

    final mealBarcodeRows = await db.customSelect('''
      SELECT DISTINCT product_barcode AS barcode
      FROM meal_items
      WHERE product_barcode IS NOT NULL AND TRIM(product_barcode) != ''
      ''').get();
    for (final row in mealBarcodeRows) {
      final barcode = (row.data['barcode'] as String?)?.trim() ?? '';
      if (barcode.isNotEmpty) protected.add(barcode);
    }

    final productRefRows = await db.customSelect('''
      SELECT DISTINCT p.barcode AS barcode
      FROM products p
      WHERE p.barcode IS NOT NULL
        AND TRIM(p.barcode) != ''
        AND (
          EXISTS (
            SELECT 1 FROM nutrition_logs nl
            WHERE nl.product_id = p.id
          )
          OR EXISTS (
            SELECT 1 FROM meal_items mi
            WHERE mi.product_id = p.id
          )
        )
      ''').get();
    for (final row in productRefRows) {
      final barcode = (row.data['barcode'] as String?)?.trim() ?? '';
      if (barcode.isNotEmpty) protected.add(barcode);
    }

    return protected;
  }

  Future<void> applyOffRetentionUpdates({
    required AppDatabase database,
    required List<String> barcodesToRetain,
    required List<String> barcodesToDelete,
  }) async {
    const int chunkSize = 900;

    for (var i = 0; i < barcodesToRetain.length; i += chunkSize) {
      final chunk = barcodesToRetain.sublist(
        i,
        i + chunkSize > barcodesToRetain.length
            ? barcodesToRetain.length
            : i + chunkSize,
      );
      await (database.update(database.products)
            ..where((t) => t.source.equals('off') & t.barcode.isIn(chunk)))
          .write(const ProductsCompanion(source: Value('off_retained')));
    }

    for (var i = 0; i < barcodesToDelete.length; i += chunkSize) {
      final chunk = barcodesToDelete.sublist(
        i,
        i + chunkSize > barcodesToDelete.length
            ? barcodesToDelete.length
            : i + chunkSize,
      );
      await (database.delete(
        database.products,
      )..where((t) => t.source.equals('off') & t.barcode.isIn(chunk)))
          .go();
    }
  }
}
