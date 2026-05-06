import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:sqflite/sqflite.dart';

import '../config/app_data_sources.dart';
import 'catalog_file_migration.dart';

/// Service responsible for managing the local SQLite database.
///
/// Handles database initialization, asset copying for pre-populated data,
/// and providing access to the database instance.
class DbService {
  static Database? _db;

  /// Singleton instance of [DbService].
  static final DbService I = DbService._();
  DbService._();

  /// Returns the [Database] instance, initializing it if necessary.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  /// Initializes the database by copying it from assets if it doesn't already exist.
  Future<Database> _init() async {
    final dbDir = await getDatabasesPath();
    final dbPath = await CatalogFileMigration.resolveCanonicalPath(
      directoryPath: dbDir,
      canonicalFileName: AppDataSources.trainingDbFileName,
      legacyFileName: AppDataSources.legacyTrainingDbFileName,
    );

    // If file does not exist yet: copy it from assets.
    if (!await File(dbPath).exists()) {
      final bytes = await _loadTrainingAsset();
      await File(dbPath).writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }

    // readOnly is optional; omit it if migration is needed later.
    return openDatabase(dbPath, readOnly: true);
  }

  Future<ByteData> _loadTrainingAsset() async {
    try {
      return await rootBundle.load(AppDataSources.trainingAssetDbPath);
    } catch (_) {
      // Legacy fallback keeps older packaged beta builds restorable/runnable.
      return rootBundle.load(AppDataSources.legacyTrainingAssetDbPath);
    }
  }
}
