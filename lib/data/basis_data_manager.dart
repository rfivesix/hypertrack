// lib/data/basis_data_manager.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'database_helper.dart';
import 'drift_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:drift/drift.dart' as drift;

import '../config/app_data_sources.dart';
import '../services/exercise_catalog_refresh_service.dart';
import '../services/off_catalog_country_service.dart';
import '../services/off_catalog_refresh_service.dart';

// Typ-Definition für den Callback
typedef ProgressCallback = void Function(
    String task, String detail, double progress);

/// Manager responsible for initializing and updating the application's base data.
///
/// Handles importing exercises, food products, and categories from asset databases
/// into the main application database.
class BasisDataManager {
  /// Singleton instance of [BasisDataManager].
  static final BasisDataManager instance = BasisDataManager._init();
  BasisDataManager._init();

  static const String _keyVersionTraining = 'installed_training_version';
  static const String _keyVersionFood = 'installed_food_version';
  static const String _keyVersionCats = 'installed_cats_version';
  static const String _fallbackInstalledVersion = '000000000001';

  int _parseInt(dynamic value) => (value as num?)?.toInt() ?? 0;
  double _parseDouble(dynamic value) => (value as num?)?.toDouble() ?? 0.0;
  String _parseString(dynamic value) => value?.toString() ?? '';

  /// Checks for updates to the basis data and performs an import if necessary.
  ///
  /// The [force] parameter triggers a re-import regardless of version mismatch.
  /// The [onProgress] callback reports the ongoing task, details, and percentage.
  Future<void> checkForBasisDataUpdate({
    bool force = false,
    ProgressCallback? onProgress, // NEU: Callback
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (force) {
      await prefs.remove(_keyVersionTraining);
      await prefs.remove(_keyVersionFood);
      await _clearOffVersionPreferences(prefs);
      await prefs.remove(_keyVersionCats);
    }

    final activeOffSource =
        OffCatalogCountryService.activeSourceFromPrefs(prefs);
    final activeOffCountry =
        OffCatalogCountryCodec.parseOrDefault(activeOffSource.countryCode);
    await _migrateLegacyOffVersionPreference(
      prefs: prefs,
      country: activeOffCountry,
    );
    final activeOffVersionKey =
        OffCatalogCountryService.installedVersionKeyForCountry(
      activeOffCountry,
    );

    // Hilfsfunktion, um den Code lesbarer zu halten
    Future<void> process(
      String label,
      String asset,
      String key,
      String table,
      Function(Map<String, dynamic>) mapper, {
      String? sourceFilePath,
      String? driftTable,
      bool enableOffReplacementRetention = false,
    }) async {
      await _updateDatabaseFromSource(
        assetPath: asset,
        sourceFilePath: sourceFilePath,
        prefKey: key,
        prefs: prefs,
        tableName: table,
        driftTableName: driftTable,
        mapFunction: mapper,
        taskLabel: label,
        onProgress: onProgress,
        forceImport: force,
        enableOffReplacementRetention: enableOffReplacementRetention,
      );
    }

    String? remoteTrainingDbPath;
    final installedTrainingVersion =
        prefs.getString(_keyVersionTraining) ?? '0';
    try {
      onProgress?.call(
        "Prüfe Übungen...",
        "Suche nach Remote-Katalog-Updates...",
        0.0,
      );
      final remoteCandidate =
          await ExerciseCatalogRefreshService.instance.prepareUpdateCandidate(
        installedVersion: installedTrainingVersion,
        force: force,
      );
      if (remoteCandidate != null) {
        remoteTrainingDbPath = remoteCandidate.localDbPath;
        onProgress?.call(
          "Update Übungen",
          "Remote-Katalog ${remoteCandidate.version} gefunden.",
          0.02,
        );
      }
    } catch (e) {
      debugPrint('Remote exercise catalog check skipped safely: $e');
    }

    // 1. Übungen (Remote-Candidate wenn verfügbar, sonst Asset)
    await process(
      'Übungen',
      AppDataSources.trainingAssetDbPath,
      _keyVersionTraining,
      'exercises',
      _mapExerciseRow,
      sourceFilePath: remoteTrainingDbPath,
    );

    // 2a. Base Foods
    await process(
      'Basis-Produkte',
      AppDataSources.baseFoodsAssetDbPath,
      _keyVersionFood,
      'products',
      (row) => _mapProductRow(row, sourceLabel: 'base'),
    );

    // 2b. Kategorien
    await process(
      'Kategorien',
      AppDataSources.foodCategoriesAssetDbPath,
      _keyVersionCats,
      'categories',
      _mapCategoryRow,
      driftTable: 'food_categories',
    );

    String? remoteOffDbPath;
    final installedOffVersion = prefs.getString(activeOffVersionKey) ?? '0';
    try {
      onProgress?.call(
        'Prüfe Produktdatenbank (${activeOffCountry.upperCode})...',
        'Suche nach Remote-OFF-Katalog-Updates...',
        0.0,
      );
      final remoteOffCandidate =
          await OffCatalogRefreshService.instance.prepareUpdateCandidate(
        installedVersion: installedOffVersion,
        force: force,
      );
      if (remoteOffCandidate != null) {
        remoteOffDbPath = remoteOffCandidate.localDbPath;
        onProgress?.call(
          'Update Produktdatenbank (${activeOffCountry.upperCode})',
          'Remote-OFF-Katalog ${remoteOffCandidate.version} gefunden.',
          0.02,
        );
      }
    } catch (e) {
      debugPrint('Remote OFF catalog check skipped safely: $e');
    }

    final hasBundledOffAsset =
        await OffCatalogCountryService.bundledAssetAvailableForCountry(
      activeOffCountry,
    );

    if (remoteOffDbPath == null && !hasBundledOffAsset) {
      onProgress?.call(
        'Produktdatenbank (${activeOffCountry.upperCode})',
        'Kein OFF-Bundle/Remote verfügbar. Vorhandene lokale OFF-Daten bleiben unverändert.',
        1.0,
      );
      return;
    }

    // 3. OFF Datenbank (Das große File)
    await process(
      'Produktdatenbank (${activeOffCountry.upperCode})',
      activeOffSource.bundledAssetDbPath,
      activeOffVersionKey,
      'products',
      (row) => _mapProductRow(row, sourceLabel: 'off'),
      sourceFilePath: remoteOffDbPath,
      enableOffReplacementRetention: true,
    );
  }

  Future<void> _clearOffVersionPreferences(SharedPreferences prefs) async {
    await prefs.remove(OffCatalogCountryService.legacyInstalledVersionKey);
    final offVersionKeys = prefs
        .getKeys()
        .where(
          (key) => key
              .startsWith(OffCatalogCountryService.installedVersionKeyPrefix),
        )
        .toList(growable: false);
    for (final key in offVersionKeys) {
      await prefs.remove(key);
    }
  }

  Future<void> _migrateLegacyOffVersionPreference({
    required SharedPreferences prefs,
    required OffCatalogCountry country,
  }) async {
    // Keep existing DE installations stable when upgrading from a single OFF
    // version key to country-scoped OFF version keys.
    if (country != OffCatalogCountry.de) return;
    final targetKey = OffCatalogCountryService.installedVersionKeyForCountry(
      country,
    );
    if (prefs.containsKey(targetKey)) return;
    final legacyValue = prefs
        .getString(OffCatalogCountryService.legacyInstalledVersionKey)
        ?.trim();
    if (legacyValue == null || legacyValue.isEmpty) return;
    await prefs.setString(targetKey, legacyValue);
  }

  Future<void> _updateDatabaseFromSource({
    required String assetPath,
    String? sourceFilePath,
    required String prefKey,
    required SharedPreferences prefs,
    required String tableName,
    String? driftTableName,
    required Function(Map<String, dynamic>) mapFunction,
    required String taskLabel,
    ProgressCallback? onProgress,
    required bool forceImport,
    required bool enableOffReplacementRetention,
  }) async {
    File? tempFile;
    sqflite.Database? assetDb;

    try {
      // Initiale Meldung (0%)
      onProgress?.call("Prüfe $taskLabel...", "Initialisiere...", 0.0);

      if (sourceFilePath != null &&
          sourceFilePath.isNotEmpty &&
          await File(sourceFilePath).exists()) {
        try {
          assetDb = await sqflite.openDatabase(sourceFilePath, readOnly: true);
        } catch (e) {
          debugPrint(
            'Falling back to bundled asset for $taskLabel (remote source failed): $e',
          );
        }
      }

      if (assetDb == null) {
        final tempDir = await getTemporaryDirectory();
        final tempPath = p.join(tempDir.path, p.basename(assetPath));

        try {
          final byteData = await rootBundle.load(assetPath);
          tempFile = File(tempPath);
          await tempFile.writeAsBytes(
            byteData.buffer.asUint8List(
              byteData.offsetInBytes,
              byteData.lengthInBytes,
            ),
          );
        } catch (e) {
          debugPrint(
            'Skipping import for $taskLabel because asset source could not be loaded: $assetPath ($e)',
          );
          return;
        }

        assetDb = await sqflite.openDatabase(tempPath, readOnly: true);
      }

      var checkTable = tableName;
      if (tableName == 'exercises') {
        final tables = await assetDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='exercises'",
        );
        if (tables.isEmpty) checkTable = 'exercise';
      } else {
        final tables = await assetDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
        );
        if (tables.isEmpty) {
          return;
        }
      }

      String assetVersion = '0';
      try {
        final metaRows = await assetDb.query(
          'metadata',
          where: 'key = ?',
          whereArgs: ['version'],
        );
        if (metaRows.isNotEmpty) {
          assetVersion = _normalizeVersion(metaRows.first['value']);
        }
      } catch (_) {}

      final String installedVersion = prefs.getString(prefKey) ?? '0';
      final mainDb = await DatabaseHelper.instance.database;
      final hasExistingData = await _hasInitializedData(
        mainDb: mainDb,
        prefKey: prefKey,
      );

      final shouldImport = shouldImportAsset(
        forceImport: forceImport,
        assetVersion: assetVersion,
        installedVersion: installedVersion,
        hasExistingDataForVersionlessAsset: hasExistingData,
      );

      // Wenn Update nötig ist:
      if (shouldImport) {
        onProgress?.call("Update $taskLabel", "Vorbereitung...", 0.05);

        final importedBarcodes = await _performBatchImport(
          assetDb,
          checkTable,
          mapFunction,
          onProgress,
          taskLabel,
          collectProductBarcodes: enableOffReplacementRetention,
        );

        if (enableOffReplacementRetention) {
          await retainHistoricallyNeededOffProducts(
            importedOffBarcodes: importedBarcodes,
            onProgress: onProgress,
          );
        }

        await prefs.setString(
          prefKey,
          storedVersionAfterImport(assetVersion: assetVersion),
        );
      } else {
        // Falls aktuell, kurz 100% anzeigen, damit es nicht hängt
        if (installedVersion == '0' &&
            assetVersion == '0' &&
            hasExistingData &&
            !forceImport) {
          await prefs.setString(prefKey, _fallbackInstalledVersion);
        }
        onProgress?.call("$taskLabel aktuell", "Bereit", 1.0);
      }
    } finally {
      await assetDb?.close();
      if (tempFile != null && await tempFile.exists()) await tempFile.delete();
    }
  }

  static bool shouldImportAsset({
    required bool forceImport,
    required String assetVersion,
    required String installedVersion,
    required bool hasExistingDataForVersionlessAsset,
  }) {
    if (forceImport) return true;
    if (assetVersion.compareTo(installedVersion) > 0) return true;
    if (installedVersion != '0') return false;

    // Guard: Wenn Asset keine Version liefert, aber Daten bereits vorhanden sind,
    // nicht bei jedem Start erneut importieren.
    if (assetVersion == '0' && hasExistingDataForVersionlessAsset) {
      return false;
    }
    return true;
  }

  static String storedVersionAfterImport({required String assetVersion}) {
    return assetVersion == '0' ? _fallbackInstalledVersion : assetVersion;
  }

  String _normalizeVersion(dynamic value) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? '0' : normalized;
  }

  Future<bool> _hasInitializedData({
    required AppDatabase mainDb,
    required String prefKey,
  }) async {
    switch (prefKey) {
      case _keyVersionTraining:
        final row = await mainDb
            .customSelect('SELECT 1 FROM exercises LIMIT 1')
            .getSingleOrNull();
        return row != null;
      case _keyVersionFood:
        final row = await mainDb.customSelect(
          'SELECT 1 FROM products WHERE source = ? LIMIT 1',
          variables: [drift.Variable.withString('base')],
        ).getSingleOrNull();
        return row != null;
      case OffCatalogCountryService.legacyInstalledVersionKey:
        final row = await mainDb.customSelect(
          'SELECT 1 FROM products WHERE source = ? LIMIT 1',
          variables: [drift.Variable.withString('off')],
        ).getSingleOrNull();
        return row != null;
      case _keyVersionCats:
        final row = await mainDb
            .customSelect('SELECT 1 FROM food_categories LIMIT 1')
            .getSingleOrNull();
        return row != null;
      default:
        if (prefKey
            .startsWith(OffCatalogCountryService.installedVersionKeyPrefix)) {
          final row = await mainDb.customSelect(
            'SELECT 1 FROM products WHERE source = ? LIMIT 1',
            variables: [drift.Variable.withString('off')],
          ).getSingleOrNull();
          return row != null;
        }
        return false;
    }
  }

  Future<Set<String>> _performBatchImport(
    sqflite.Database assetDb,
    String tableName,
    dynamic Function(Map<String, dynamic>) mapRowToCompanion,
    ProgressCallback? onProgress,
    String taskLabel, {
    required bool collectProductBarcodes,
  }) async {
    final mainDb = await DatabaseHelper.instance.database;
    const int batchSize = 2000;
    int offset = 0;
    final importedProductBarcodes = <String>{};

    // 1. Gesamtanzahl ermitteln für Progress Bar
    int totalCount = 0;
    try {
      final countResult = await assetDb.rawQuery(
        'SELECT COUNT(*) as c FROM $tableName',
      );
      totalCount = sqflite.Sqflite.firstIntValue(countResult) ?? 0;
    } catch (_) {
      totalCount = 0;
    }

    if (totalCount == 0) return importedProductBarcodes; // Nichts zu tun

    int processed = 0;

    while (true) {
      final rows = await assetDb.query(
        tableName,
        limit: batchSize,
        offset: offset,
      );
      if (rows.isEmpty) break;

      await mainDb.batch((batch) {
        for (final row in rows) {
          try {
            final companion = mapRowToCompanion(row);
            if (companion is ProductsCompanion) {
              if (collectProductBarcodes &&
                  companion.barcode.present &&
                  companion.barcode.value.trim().isNotEmpty) {
                importedProductBarcodes.add(companion.barcode.value.trim());
              }
              batch.insert(
                mainDb.products,
                companion,
                mode: drift.InsertMode.insertOrReplace,
              );
            } else if (companion is ExercisesCompanion) {
              batch.insert(
                mainDb.exercises,
                companion,
                onConflict: drift.DoUpdate(
                  (_) => companion,
                  target: [mainDb.exercises.id],
                ),
              );
            } else if (companion is FoodCategoriesCompanion) {
              batch.insert(
                mainDb.foodCategories,
                companion,
                mode: drift.InsertMode.insertOrReplace,
              );
            }
          } catch (e) {
            debugPrint('Skipping malformed import row for $taskLabel: $e');
          }
        }
      });

      processed += rows.length;
      offset += batchSize;

      // Progress melden
      if (onProgress != null) {
        final double progress = (processed / totalCount).clamp(0.0, 1.0);
        onProgress(
          "Update $taskLabel",
          "$processed / $totalCount Einträge",
          progress,
        );
      }

      // UI-Thread atmen lassen
      await Future.delayed(const Duration(milliseconds: 1));
    }

    return importedProductBarcodes;
  }

  /// Applies OFF replacement semantics with historical retention:
  /// - Keep imported barcodes active (`source='off'` via import mapping)
  /// - Demote historically protected, no-longer-imported rows to `off_retained`
  /// - Delete no-longer-imported rows that are not historically referenced
  @visibleForTesting
  Future<void> retainHistoricallyNeededOffProducts({
    required Set<String> importedOffBarcodes,
    ProgressCallback? onProgress,
    AppDatabase? testingDatabase,
  }) async {
    if (importedOffBarcodes.isEmpty) {
      debugPrint(
        'Skipping OFF retention pass because imported barcode set is empty.',
      );
      return;
    }

    final mainDb = testingDatabase ?? await DatabaseHelper.instance.database;
    final protectedBarcodes = await _loadHistoricallyProtectedBarcodes(mainDb);

    final offRows = await (mainDb.select(mainDb.products)
          ..where((t) => t.source.equals('off')))
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

    await _applyOffRetentionUpdates(
      mainDb: mainDb,
      barcodesToRetain: barcodesToRetain,
      barcodesToDelete: barcodesToDelete,
    );

    onProgress?.call(
      'Update Produktdatenbank',
      'OFF-Daten bereinigt: ${barcodesToRetain.length} behalten, ${barcodesToDelete.length} entfernt',
      1.0,
    );
  }

  Future<Set<String>> _loadHistoricallyProtectedBarcodes(
    AppDatabase mainDb,
  ) async {
    final protected = <String>{};

    final nutritionLegacyRows = await mainDb.customSelect(
      '''
      SELECT DISTINCT legacy_barcode AS barcode
      FROM nutrition_logs
      WHERE legacy_barcode IS NOT NULL AND TRIM(legacy_barcode) != ''
      ''',
    ).get();
    for (final row in nutritionLegacyRows) {
      final barcode = (row.data['barcode'] as String?)?.trim() ?? '';
      if (barcode.isNotEmpty) protected.add(barcode);
    }

    final favoritesRows = await mainDb.customSelect(
      '''
      SELECT DISTINCT barcode
      FROM favorites
      WHERE barcode IS NOT NULL AND TRIM(barcode) != ''
      ''',
    ).get();
    for (final row in favoritesRows) {
      final barcode = (row.data['barcode'] as String?)?.trim() ?? '';
      if (barcode.isNotEmpty) protected.add(barcode);
    }

    final mealBarcodeRows = await mainDb.customSelect(
      '''
      SELECT DISTINCT product_barcode AS barcode
      FROM meal_items
      WHERE product_barcode IS NOT NULL AND TRIM(product_barcode) != ''
      ''',
    ).get();
    for (final row in mealBarcodeRows) {
      final barcode = (row.data['barcode'] as String?)?.trim() ?? '';
      if (barcode.isNotEmpty) protected.add(barcode);
    }

    final productRefRows = await mainDb.customSelect(
      '''
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
      ''',
    ).get();
    for (final row in productRefRows) {
      final barcode = (row.data['barcode'] as String?)?.trim() ?? '';
      if (barcode.isNotEmpty) protected.add(barcode);
    }

    return protected;
  }

  Future<void> _applyOffRetentionUpdates({
    required AppDatabase mainDb,
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
      await (mainDb.update(mainDb.products)
            ..where((t) => t.source.equals('off') & t.barcode.isIn(chunk)))
          .write(const ProductsCompanion(source: drift.Value('off_retained')));
    }

    for (var i = 0; i < barcodesToDelete.length; i += chunkSize) {
      final chunk = barcodesToDelete.sublist(
        i,
        i + chunkSize > barcodesToDelete.length
            ? barcodesToDelete.length
            : i + chunkSize,
      );
      await (mainDb.delete(mainDb.products)
            ..where((t) => t.source.equals('off') & t.barcode.isIn(chunk)))
          .go();
    }
  }

  // --- MAPPING FUNKTIONEN (Unverändert) ---

  dynamic _mapProductRow(
    Map<String, dynamic> row, {
    required String sourceLabel,
  }) {
    var barcode = _parseString(row['barcode']);
    String id;
    if (row['id'] != null) {
      id = _parseString(row['id']);
    } else if (barcode.isNotEmpty) {
      id = 'manual_$barcode';
    } else {
      id = 'manual_${_parseString(row['name']).replaceAll(RegExp(r'\s+'), '')}';
    }

    if (barcode.isEmpty) {
      barcode = id;
    }

    return ProductsCompanion(
      id: drift.Value(id),
      barcode: drift.Value(barcode),
      name: drift.Value(_parseString(row['name_de'] ?? row['name'])),
      brand: drift.Value(_parseString(row['brand'])),
      calories: drift.Value(_parseInt(row['calories'])),
      protein: drift.Value(_parseDouble(row['protein'])),
      carbs: drift.Value(_parseDouble(row['carbs'])),
      fat: drift.Value(_parseDouble(row['fat'])),
      sugar: drift.Value(_parseDouble(row['sugar'])),
      fiber: drift.Value(_parseDouble(row['fiber'])),
      salt: drift.Value(_parseDouble(row['salt'])),
      source: drift.Value(sourceLabel),
      isLiquid: drift.Value(_parseInt(row['is_liquid']) == 1),
      category: drift.Value(row['category']?.toString()),
    );
  }

  dynamic _mapCategoryRow(Map<String, dynamic> row) {
    return FoodCategoriesCompanion(
      key: drift.Value(_parseString(row['key'])),
      nameDe: drift.Value(row['name_de'] as String?),
      nameEn: drift.Value(row['name_en'] as String?),
      emoji: drift.Value(row['emoji'] as String?),
    );
  }

  dynamic _mapExerciseRow(Map<String, dynamic> row) {
    return ExercisesCompanion(
      id: drift.Value(_parseString(row['id'])),
      nameDe: drift.Value(_parseString(row['name_de'] ?? row['name_en'])),
      nameEn: drift.Value(_parseString(row['name_en'])),
      descriptionDe: drift.Value(_parseString(row['description_de'])),
      descriptionEn: drift.Value(_parseString(row['description_en'])),
      categoryName: drift.Value(_parseString(row['category_name'])),
      musclesPrimary: drift.Value(_parseString(row['muscles_primary'])),
      musclesSecondary: drift.Value(_parseString(row['muscles_secondary'])),
      isCustom: const drift.Value(false),
      createdBy: const drift.Value('system'),
      source: const drift.Value('base'),
    );
  }
}
