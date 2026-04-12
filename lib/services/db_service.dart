import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../config/app_data_sources.dart';

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
    final dbPath = p.join(dbDir, 'hypertrack_training.db');

    // Falls Datei noch nicht existiert: aus Assets kopieren
    if (!await File(dbPath).exists()) {
      final bytes = await rootBundle.load(AppDataSources.trainingAssetDbPath);
      await File(dbPath).writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }

    // readOnly ist optional – wenn du später migrieren willst, weglassen.
    return openDatabase(dbPath, readOnly: true);
  }
}
