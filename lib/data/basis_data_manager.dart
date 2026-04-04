// lib/data/basis_data_manager.dart

import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'database_helper.dart';
import 'drift_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:drift/drift.dart' as drift;

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
  static const String _keyVersionOff = 'installed_off_version';
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
      await prefs.remove(_keyVersionOff);
      await prefs.remove(_keyVersionCats);
    }

    // Hilfsfunktion, um den Code lesbarer zu halten
    Future<void> process(
      String label,
      String asset,
      String key,
      String table,
      Function(Map<String, dynamic>) mapper, {
      String? driftTable,
    }) async {
      await _updateDatabaseFromAsset(
        assetPath: asset,
        prefKey: key,
        prefs: prefs,
        tableName: table,
        driftTableName: driftTable,
        mapFunction: mapper,
        taskLabel: label,
        onProgress: onProgress,
        forceImport: force,
      );
    }

    // 1. Übungen
    await process(
      'Übungen',
      'assets/db/hypertrack_training.db',
      _keyVersionTraining,
      'exercises',
      _mapExerciseRow,
    );

    // 2a. Base Foods
    await process(
      'Basis-Produkte',
      'assets/db/hypertrack_base_foods.db',
      _keyVersionFood,
      'products',
      (row) => _mapProductRow(row, sourceLabel: 'base'),
    );

    // 2b. Kategorien
    await process(
      'Kategorien',
      'assets/db/hypertrack_base_foods.db',
      _keyVersionCats,
      'categories',
      _mapCategoryRow,
      driftTable: 'food_categories',
    );

    // 3. OFF Datenbank (Das große File)
    await process(
      'Produktdatenbank',
      'assets/db/hypertrack_prep_de.db',
      _keyVersionOff,
      'products',
      (row) => _mapProductRow(row, sourceLabel: 'off'),
    );
  }

  Future<void> _updateDatabaseFromAsset({
    required String assetPath,
    required String prefKey,
    required SharedPreferences prefs,
    required String tableName,
    String? driftTableName,
    required Function(Map<String, dynamic>) mapFunction,
    required String taskLabel,
    ProgressCallback? onProgress,
    required bool forceImport,
  }) async {
    File? tempFile;
    sqflite.Database? assetDb;

    try {
      // Initiale Meldung (0%)
      onProgress?.call("Prüfe $taskLabel...", "Initialisiere...", 0.0);

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
        return;
      }

      assetDb = await sqflite.openDatabase(tempPath, readOnly: true);

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

        await _performBatchImport(
          assetDb,
          checkTable,
          mapFunction,
          onProgress,
          taskLabel,
        );

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
      case _keyVersionOff:
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
        return false;
    }
  }

  Future<void> _performBatchImport(
    sqflite.Database assetDb,
    String tableName,
    Function(Map<String, dynamic>) mapRowToCompanion,
    ProgressCallback? onProgress,
    String taskLabel,
  ) async {
    final mainDb = await DatabaseHelper.instance.database;
    const int batchSize = 2000;
    int offset = 0;

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

    if (totalCount == 0) return; // Nichts zu tun

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
              batch.insert(
                mainDb.products,
                companion,
                mode: drift.InsertMode.insertOrReplace,
              );
            } else if (companion is ExercisesCompanion) {
              batch.insert(
                mainDb.exercises,
                companion,
                mode: drift.InsertMode.insertOrReplace,
              );
            } else if (companion is FoodCategoriesCompanion) {
              batch.insert(
                mainDb.foodCategories,
                companion,
                mode: drift.InsertMode.insertOrReplace,
              );
            }
          } catch (e) {}
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
