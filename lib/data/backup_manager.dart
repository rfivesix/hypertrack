// lib/data/backup_manager.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

// Internal imports
import 'database_helper.dart';
import 'drift_database.dart'; // Access to Drift tables and companions.
import 'product_database_helper.dart';
import 'workout_database_helper.dart';
import '../models/food_item.dart';
import '../models/hypertrack_backup.dart';
import '../services/health/steps_sync_service.dart';
import '../services/storage/saf_storage_service.dart';
import '../util/encryption_util.dart';

/// Manager responsible for application backup, restoration, and data export.
///
/// Supports full JSON backups with optional encryption and CSV exports for
/// nutrition, workouts, and measurements.
class BackupManager {
  // Singleton pattern
  /// Singleton instance of [BackupManager].
  static final BackupManager instance = BackupManager._init();
  BackupManager._init();

  final _userDb = DatabaseHelper.instance;
  final _productDb = ProductDatabaseHelper.instance;
  final _workoutDb = WorkoutDatabaseHelper.instance;

  static const int currentSchemaVersion = 3;

  ui.Rect _sharePositionOrigin() {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) {
      return const ui.Rect.fromLTWH(0, 0, 1, 1);
    }

    final view = views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    return ui.Rect.fromLTWH(
      0,
      0,
      math.max(1, logicalSize.width),
      math.max(1, logicalSize.height),
    );
  }

  @visibleForTesting
  static Future<Directory> resolveWritableBackupDirectory({
    required Directory docsDir,
    String? dirPath,
    String? savedDir,
    String? externalFallbackDir,
  }) async {
    final defaultDir = Directory(p.join(docsDir.path, 'Backups'));
    final candidates = <String>[
      if (dirPath != null && dirPath.trim().isNotEmpty) dirPath.trim(),
      if (savedDir != null && savedDir.trim().isNotEmpty) savedDir.trim(),
      if (externalFallbackDir != null && externalFallbackDir.trim().isNotEmpty)
        externalFallbackDir.trim(),
      defaultDir.path,
    ];

    for (final candidate in candidates) {
      final directory = Directory(candidate);
      try {
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final probe = File(p.join(directory.path, '.hypertrack_write_probe'));
        await probe.writeAsString('ok', flush: true);
        if (await probe.exists()) {
          await probe.delete();
        }
        return directory;
      } catch (e) {
        debugPrint('Auto-backup directory not writable ($candidate): $e');
      }
    }

    throw const FileSystemException('No writable auto-backup directory found');
  }

  // ---------------------------------------------------------------------------
  // EXPORT (JSON / FULL BACKUP)
  // ---------------------------------------------------------------------------

  /// Exports a complete application backup as an unencrypted JSON file and shares it.
  Future<bool> exportFullBackup() async {
    try {
      final jsonString = await _generateBackupJson();
      return await _writeAndShareFile(jsonString, 'hypertrack_backup');
    } catch (e) {
      debugPrint("Backup export failed: $e");
      return false;
    }
  }

  /// Exports a complete application backup as an encrypted JSON file and shares it.
  ///
  /// Uses [passphrase] for AES-256 encryption.
  Future<bool> exportFullBackupEncrypted(String passphrase) async {
    try {
      final jsonString = await _generateBackupJson();

      // Encrypt payload before sharing.
      final wrapper = await EncryptionUtil.encryptString(
        jsonString,
        passphrase,
      );
      final wrappedJson = jsonEncode(wrapper);

      return await _writeAndShareFile(wrappedJson, 'hypertrack_backup_enc');
    } catch (e) {
      debugPrint("Encrypted backup export failed: $e");
      return false;
    }
  }

  /// Helper method that collects all persisted entities and builds backup JSON.
  Future<String> _generateBackupJson() async {
    // 1) Collect data from helper layers.
    final foodEntries = await _userDb.getAllFoodEntries();
    final fluidEntries = await _userDb.getAllFluidEntries();
    final favoriteBarcodes = await _userDb.getFavoriteBarcodes();
    final measurementSessions = await _userDb.getMeasurementSessions();

    // 2) Load custom products directly from Drift.
    final db = await _userDb.database;
    final customProductRows = await (db.select(
      db.products,
    )..where((t) => t.source.equals('user')))
        .get();

    final customFoodItems = customProductRows.map((row) {
      return FoodItem(
        barcode: row.barcode,
        name: row.name,
        brand: row.brand ?? '',
        calories: row.calories,
        protein: row.protein,
        carbs: row.carbs,
        fat: row.fat,
        source: FoodItemSource.user,
        sugar: row.sugar ?? 0.0,
        fiber: row.fiber ?? 0.0,
        salt: row.salt ?? 0.0,
        isLiquid: row.isLiquid,
        category: row.category,
      );
    }).toList();

    final routines = await _workoutDb.getAllRoutinesWithDetails();
    final workoutLogs = await _workoutDb.getFullWorkoutLogs();

    final supplements = await _userDb.getAllSupplements();
    final supplementLogs = await _userDb.getAllSupplementLogs();
    final customExercises = await _workoutDb.getCustomExercises();

    // 3) Collect historical goals and supplement settings.
    final goalsHistoryRows = await db.customSelect('''
      SELECT target_calories, target_protein, target_carbs, target_fat, target_water, target_steps, created_at
      FROM daily_goals_history
      ''').get();
    final dailyGoalsHistory = goalsHistoryRows
        .map(
          (r) => {
            'targetCalories': r.read<int>('target_calories'),
            'targetProtein': r.read<int>('target_protein'),
            'targetCarbs': r.read<int>('target_carbs'),
            'targetFat': r.read<int>('target_fat'),
            'targetWater': r.read<int>('target_water'),
            'targetSteps': r.read<int>('target_steps'),
            'createdAt': DateTime.fromMillisecondsSinceEpoch(
              r.read<int>('created_at') * 1000,
            ).toIso8601String(),
          },
        )
        .toList();

    final suppHistoryRows = await db.select(db.supplementSettingsHistory).get();
    final supplementSettingsHistory = suppHistoryRows
        .map(
          (r) => {
            'supplementId': r.supplementId,
            'isTracked': r.isTracked,
            'dose': r.dose,
            'dailyGoal': r.dailyGoal,
            'dailyLimit': r.dailyLimit,
            'createdAt': r.createdAt.toIso8601String(),
          },
        )
        .toList();

    // 4) Collect app settings and profile.
    final settingsRow = await db.select(db.appSettings).getSingleOrNull();
    final appSettingsRawRows = await db
        .customSelect('SELECT target_steps FROM app_settings LIMIT 1')
        .get();
    final targetSteps = appSettingsRawRows.isNotEmpty
        ? appSettingsRawRows.first.read<int>('target_steps')
        : StepsSyncService.defaultStepsGoal;
    final Map<String, dynamic>? appSettingsMap = settingsRow != null
        ? {
            'userId': settingsRow.userId,
            'themeMode': settingsRow.themeMode,
            'unitSystem': settingsRow.unitSystem,
            'targetCalories': settingsRow.targetCalories,
            'targetProtein': settingsRow.targetProtein,
            'targetCarbs': settingsRow.targetCarbs,
            'targetFat': settingsRow.targetFat,
            'targetWater': settingsRow.targetWater,
            'targetSteps': targetSteps,
          }
        : null;

    final healthStepRows = await db.customSelect('''
      SELECT provider, source_id, start_at, end_at, step_count, external_key
      FROM health_step_segments
      ''').get();
    final healthStepSegments = healthStepRows
        .map(
          (r) => <String, dynamic>{
            'provider': r.read<String>('provider'),
            'sourceId': r.read<String?>('source_id'),
            'startAt': DateTime.fromMillisecondsSinceEpoch(
              r.read<int>('start_at') * 1000,
            ).toUtc().toIso8601String(),
            'endAt': DateTime.fromMillisecondsSinceEpoch(
              r.read<int>('end_at') * 1000,
            ).toUtc().toIso8601String(),
            'stepCount': r.read<int>('step_count'),
            'externalKey': r.read<String>('external_key'),
          },
        )
        .toList();

    final profileRow = await db.select(db.profiles).getSingleOrNull();
    final Map<String, dynamic>? profileMap = profileRow != null
        ? {
            'id': profileRow.id,
            'username': profileRow.username,
            'isCoach': profileRow.isCoach,
            'visibility': profileRow.visibility,
            'birthday': profileRow.birthday?.toIso8601String(),
            'height': profileRow.height,
            'gender': profileRow.gender,
            'profileImagePath': profileRow.profileImagePath,
          }
        : null;

    // 5) Collect shared preferences.
    final prefs = await SharedPreferences.getInstance();
    final userPrefs = <String, dynamic>{};
    for (String key in prefs.getKeys()) {
      userPrefs[key] = prefs.get(key);
    }

    // 6) Build backup object.
    final backup = HypertrackBackup(
      schemaVersion: currentSchemaVersion,
      foodEntries: foodEntries,
      fluidEntries: fluidEntries,
      favoriteBarcodes: favoriteBarcodes,
      customFoodItems: customFoodItems,
      measurementSessions: measurementSessions,
      routines: routines,
      workoutLogs: workoutLogs,
      userPreferences: userPrefs,
      supplements: supplements,
      supplementLogs: supplementLogs,
      customExercises: customExercises,
      dailyGoalsHistory: dailyGoalsHistory,
      supplementSettingsHistory: supplementSettingsHistory,
      appSettings: appSettingsMap,
      profile: profileMap,
      healthStepSegments: healthStepSegments,
    );

    return jsonEncode(backup.toJson());
  }

  Future<bool> _writeAndShareFile(String content, String baseName) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final tempFile = File(
      '${tempDir.path}/$baseName-v$currentSchemaVersion-[$timestamp].json',
    );
    await tempFile.writeAsString(content);

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(tempFile.path, mimeType: 'application/json'),
        ],
        subject: 'Hypertrack Backup $timestamp',
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );

    if (await tempFile.exists()) await tempFile.delete();
    return result.status == ShareResultStatus.success;
  }

  // ---------------------------------------------------------------------------
  // IMPORT
  // ---------------------------------------------------------------------------

  /// Imports a full application backup from the provided [filePath].
  Future<bool> importFullBackup(String filePath) async {
    return importFullBackupAuto(filePath, passphrase: null);
  }

  /// Imports a full application backup from [filePath], auto-detecting encryption.
  ///
  /// If the backup is encrypted, [passphrase] must be provided.
  Future<bool> importFullBackupAuto(
    String filePath, {
    String? passphrase,
  }) async {
    try {
      final file = File(filePath);
      final rawString = await file.readAsString();
      final jsonMapRaw = jsonDecode(rawString);

      Map<String, dynamic> payload;

      if (jsonMapRaw is Map &&
          (jsonMapRaw['enc'] == EncryptionUtil.wrapperVersionV1 ||
              jsonMapRaw['enc'] == EncryptionUtil.wrapperVersionV2)) {
        final effectivePw = passphrase ?? "";
        try {
          final clearText = await EncryptionUtil.decryptToString(
            Map<String, dynamic>.from(jsonMapRaw),
            effectivePw,
          );
          payload = jsonDecode(clearText) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Backup decryption failed: $e');
          return false;
        }
      } else {
        payload = (jsonMapRaw as Map).cast<String, dynamic>();
      }

      final backup = HypertrackBackup.fromJson(payload);

      if (backup.schemaVersion > currentSchemaVersion) {
        debugPrint("Backup version is newer than supported schema.");
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _userDb.clearAllUserData();
      await _workoutDb.clearAllWorkoutData();

      final db = await _userDb.database;
      await (db.delete(
        db.products,
      )..where((t) => t.source.equals('user')))
          .go();

      for (final entry in backup.userPreferences.entries) {
        final key = entry.key;
        final val = entry.value;
        if (val is bool) {
          await prefs.setBool(key, val);
        } else if (val is int) {
          await prefs.setInt(key, val);
        } else if (val is double) {
          await prefs.setDouble(key, val);
        } else if (val is String) {
          await prefs.setString(key, val);
        } else if (val is List) {
          await prefs.setStringList(key, val.cast<String>());
        }
      }

      await _userDb.importUserData(
        foodEntries: backup.foodEntries,
        fluidEntries: backup.fluidEntries,
        favoriteBarcodes: backup.favoriteBarcodes,
        measurementSessions: backup.measurementSessions,
        supplements: backup.supplements,
        supplementLogs: backup.supplementLogs,
      );

      await db.batch((batch) {
        for (final item in backup.customFoodItems) {
          batch.insert(
            db.products,
            ProductsCompanion(
              barcode: drift.Value(item.barcode),
              name: drift.Value(item.name),
              brand: drift.Value(item.brand),
              calories: drift.Value(item.calories),
              protein: drift.Value(item.protein),
              carbs: drift.Value(item.carbs),
              fat: drift.Value(item.fat),
              sugar: drift.Value(item.sugar),
              fiber: drift.Value(item.fiber),
              salt: drift.Value(item.salt),
              source: const drift.Value('user'),
              // Guard against nullable legacy values in older backups.
              isLiquid: drift.Value(item.isLiquid ?? false),
              category: drift.Value(item.category),
              id: drift.Value(
                item.barcode.startsWith('user_')
                    ? item.barcode
                    : 'user_${item.barcode}',
              ),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
        }
      });

      await _workoutDb.importWorkoutData(
        routines: backup.routines,
        workoutLogs: backup.workoutLogs,
      );

      await _workoutDb.importCustomExercises(backup.customExercises);

      // Import DailyGoalsHistory
      if (backup.dailyGoalsHistory.isNotEmpty) {
        for (final row in backup.dailyGoalsHistory) {
          final inserted = await db.into(db.dailyGoalsHistory).insertReturning(
                DailyGoalsHistoryCompanion(
                  targetCalories: drift.Value(row['targetCalories'] as int),
                  targetProtein: drift.Value(row['targetProtein'] as int),
                  targetCarbs: drift.Value(row['targetCarbs'] as int),
                  targetFat: drift.Value(row['targetFat'] as int),
                  targetWater: drift.Value(row['targetWater'] as int),
                  createdAt: drift.Value(
                    DateTime.parse(row['createdAt'] as String),
                  ),
                ),
                mode: drift.InsertMode.insertOrReplace,
              );
          await db.customStatement(
            'UPDATE daily_goals_history SET target_steps = ? WHERE local_id = ?',
            [
              (row['targetSteps'] as int?) ?? StepsSyncService.defaultStepsGoal,
              inserted.localId,
            ],
          );
        }
      }

      // Import SupplementSettingsHistory
      if (backup.supplementSettingsHistory.isNotEmpty) {
        await db.batch((batch) {
          for (final row in backup.supplementSettingsHistory) {
            batch.insert(
              db.supplementSettingsHistory,
              SupplementSettingsHistoryCompanion(
                supplementId: drift.Value(row['supplementId'] as String),
                isTracked: drift.Value(row['isTracked'] as bool),
                dose: drift.Value((row['dose'] as num).toDouble()),
                dailyGoal: drift.Value(
                  row['dailyGoal'] != null
                      ? (row['dailyGoal'] as num).toDouble()
                      : null,
                ),
                dailyLimit: drift.Value(
                  row['dailyLimit'] != null
                      ? (row['dailyLimit'] as num).toDouble()
                      : null,
                ),
                createdAt: drift.Value(
                  DateTime.parse(row['createdAt'] as String),
                ),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
          }
        });
      }

      // Import Profile
      if (backup.profile != null) {
        final p = backup.profile!;
        await db.into(db.profiles).insert(
              ProfilesCompanion(
                id: drift.Value(p['id'] as String),
                username: drift.Value(p['username'] as String?),
                isCoach: drift.Value(p['isCoach'] as bool? ?? false),
                visibility: drift.Value(
                  p['visibility'] as String? ?? 'private',
                ),
                birthday: drift.Value(
                  p['birthday'] != null
                      ? DateTime.parse(p['birthday'] as String)
                      : null,
                ),
                height: drift.Value(p['height'] as int?),
                gender: drift.Value(p['gender'] as String?),
                profileImagePath: drift.Value(p['profileImagePath'] as String?),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
      }

      // Import AppSettings
      if (backup.appSettings != null && backup.profile != null) {
        final s = backup.appSettings!;
        await db.into(db.appSettings).insert(
              AppSettingsCompanion(
                userId: drift.Value(backup.profile!['id'] as String),
                themeMode: drift.Value(s['themeMode'] as String? ?? 'system'),
                unitSystem: drift.Value(s['unitSystem'] as String? ?? 'metric'),
                targetCalories: drift.Value(
                  s['targetCalories'] as int? ?? 2500,
                ),
                targetProtein: drift.Value(s['targetProtein'] as int? ?? 180),
                targetCarbs: drift.Value(s['targetCarbs'] as int? ?? 250),
                targetFat: drift.Value(s['targetFat'] as int? ?? 80),
                targetWater: drift.Value(s['targetWater'] as int? ?? 3000),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
        await db.customStatement(
          'UPDATE app_settings SET target_steps = ? WHERE user_id = ?',
          [
            s['targetSteps'] as int? ?? StepsSyncService.defaultStepsGoal,
            backup.profile!['id'] as String,
          ],
        );
      }

      if (backup.healthStepSegments.isNotEmpty) {
        await _userDb.upsertHealthStepSegments(backup.healthStepSegments);
      }

      debugPrint("Backup import succeeded.");
      return true;
    } catch (e) {
      debugPrint("Backup import failed: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // AUTO BACKUP
  // ---------------------------------------------------------------------------

  /// Runs an automatic backup if the specified [interval] has passed since the last backup.
  ///
  /// Supports encryption via [passphrase] and keeps [retention] number of old backups.
  Future<bool> runAutoBackupIfDue({
    Duration interval = const Duration(days: 1),
    bool encrypted = false,
    String? passphrase,
    int retention = 7,
    String? dirPath,
    bool force = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt('auto_backup_last_ms') ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (!force && (nowMs - lastMs < interval.inMilliseconds)) {
        return false;
      }

      String content = await _generateBackupJson();
      String fileName = 'hypertrack_auto_v$currentSchemaVersion';

      // Only encrypt when explicitly requested.
      if (encrypted) {
        if (passphrase == null || passphrase.isEmpty) return false;
        final wrapper = await EncryptionUtil.encryptString(content, passphrase);
        content = jsonEncode(wrapper);
        fileName = 'hypertrack_auto_enc_v$currentSchemaVersion';
      }

      final ts = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final targetFileName = '$fileName-[$ts].json';
      final configuredDirPath = dirPath?.trim();
      final savedDir = prefs.getString('auto_backup_dir')?.trim();

      if (Platform.isAndroid) {
        final treeUri = prefs.getString('auto_backup_tree_uri');
        if (treeUri != null && treeUri.trim().isNotEmpty) {
          final displayPath =
              await SafStorageService.instance.writeTextFileToTree(
            treeUri: treeUri.trim(),
            fileName: targetFileName,
            content: content,
          );
          await SafStorageService.instance.pruneAutoBackupsInTree(
            treeUri: treeUri.trim(),
            filePrefix: 'hypertrack_auto',
            retention: retention,
          );
          await prefs.setInt('auto_backup_last_ms', nowMs);
          await prefs.setString(
            'auto_backup_last_file_path',
            displayPath ?? targetFileName,
          );
          await prefs.setString(
            'auto_backup_last_dir_used',
            savedDir ?? configuredDirPath ?? '',
          );
          await prefs.setBool('auto_backup_last_used_fallback', false);
          await prefs.remove('auto_backup_last_error');
          return true;
        }
        final hasConfiguredFolder =
            configuredDirPath != null && configuredDirPath.isNotEmpty;
        final hasSavedFolder = savedDir != null && savedDir.isNotEmpty;
        if (hasConfiguredFolder || hasSavedFolder) {
          await prefs.setString(
            'auto_backup_last_error',
            'Please re-select your auto-backup folder to grant Android folder access.',
          );
          return false;
        }
      }

      final docs = await getApplicationDocumentsDirectory();
      final external = await getExternalStorageDirectory();
      final externalFallbackDir =
          external != null ? p.join(external.path, 'Backups') : null;
      final baseDir = await resolveWritableBackupDirectory(
        docsDir: docs,
        dirPath: configuredDirPath,
        savedDir: savedDir,
        externalFallbackDir: externalFallbackDir,
      );
      final requestedDir = configuredDirPath;
      final usedFallback = requestedDir != null &&
          requestedDir.isNotEmpty &&
          p.normalize(requestedDir) != p.normalize(baseDir.path);

      final file = File(p.join(baseDir.path, targetFileName));
      await file.writeAsString(content);

      try {
        final files = baseDir
            .listSync()
            .whereType<File>()
            .where((f) => p.basename(f.path).startsWith('hypertrack_auto'))
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );

        if (files.length > retention) {
          for (var i = retention; i < files.length; i++) {
            files[i].deleteSync();
          }
        }
      } catch (_) {}

      await prefs.setInt('auto_backup_last_ms', nowMs);
      await prefs.setString('auto_backup_last_file_path', file.path);
      await prefs.setString('auto_backup_last_dir_used', baseDir.path);
      await prefs.setBool('auto_backup_last_used_fallback', usedFallback);
      await prefs.remove('auto_backup_last_error');
      return true;
    } catch (e, st) {
      debugPrint("Auto-backup failed: $e");
      debugPrint('$st');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auto_backup_last_error', e.toString());
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // CSV EXPORT
  // ---------------------------------------------------------------------------

  /// Exports all nutrition logs as a CSV file and shares it.
  Future<bool> exportNutritionAsCsv() async {
    try {
      final entries = await _userDb.getAllFoodEntries();
      if (entries.isEmpty) return false;

      final uniqueBarcodes = entries.map((e) => e.barcode).toSet().toList();
      final products = await _productDb.getProductsByBarcodes(uniqueBarcodes);
      final productMap = {for (var p in products) p.barcode: p};

      List<List<dynamic>> rows = [];
      rows.add([
        'date',
        'time',
        'meal_type',
        'food_name',
        'brand',
        'quantity_grams',
        'calories_kcal',
        'protein_g',
        'carbs_g',
        'fat_g',
        'barcode',
      ]);

      for (final entry in entries) {
        final product = productMap[entry.barcode];
        if (product == null) continue;

        final factor = entry.quantityInGrams / 100.0;
        rows.add([
          DateFormat('yyyy-MM-dd').format(entry.timestamp),
          DateFormat('HH:mm').format(entry.timestamp),
          entry.mealType,
          product.name,
          product.brand,
          entry.quantityInGrams,
          (product.calories * factor).round(),
          (product.protein * factor).toStringAsFixed(1),
          (product.carbs * factor).toStringAsFixed(1),
          (product.fat * factor).toStringAsFixed(1),
          entry.barcode,
        ]);
      }
      return await _createAndShareCsv(rows, 'hypertrack_nutrition_export');
    } catch (e) {
      debugPrint("CSV export failed (nutrition): $e");
      return false;
    }
  }

  /// Exports all workout logs as a CSV file and shares it.
  Future<bool> exportWorkoutsAsCsv() async {
    try {
      final logs = await _workoutDb.getFullWorkoutLogs();
      if (logs.isEmpty) return false;

      List<List<dynamic>> rows = [];
      rows.add([
        'start_time',
        'end_time',
        'routine',
        'exercise',
        'set_order',
        'type',
        'weight_kg',
        'reps',
        'rest_sec',
        'notes',
      ]);

      for (final log in logs) {
        int setOrder = 1;
        for (final set in log.sets) {
          rows.add([
            log.startTime.toIso8601String(),
            log.endTime?.toIso8601String() ?? '',
            log.routineName ?? 'Freies Training',
            set.exerciseName,
            setOrder++,
            set.setType,
            set.weightKg ?? 0,
            set.reps ?? 0,
            set.restTimeSeconds ?? 0,
            log.notes ?? '',
          ]);
        }
      }
      return await _createAndShareCsv(rows, 'hypertrack_workouts_export');
    } catch (e) {
      debugPrint("CSV export failed (workout): $e");
      return false;
    }
  }

  /// Exports all body measurements as a CSV file and shares it.
  Future<bool> exportMeasurementsAsCsv() async {
    try {
      final sessions = await _userDb.getMeasurementSessions();
      if (sessions.isEmpty) return false;

      List<List<dynamic>> rows = [];
      rows.add(['date', 'time', 'type', 'value', 'unit']);

      for (final session in sessions) {
        for (final m in session.measurements) {
          rows.add([
            DateFormat('yyyy-MM-dd').format(session.timestamp),
            DateFormat('HH:mm').format(session.timestamp),
            m.type,
            m.value,
            m.unit,
          ]);
        }
      }
      return await _createAndShareCsv(rows, 'hypertrack_measurements_export');
    } catch (e) {
      debugPrint("CSV export failed (measurements): $e");
      return false;
    }
  }

  Future<bool> _createAndShareCsv(
    List<List<dynamic>> rows,
    String baseName,
  ) async {
    final String csvData = Csv().encode(rows);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tempFile = File('${tempDir.path}/$baseName-$timestamp.csv');
    await tempFile.writeAsString(csvData);

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(tempFile.path, mimeType: 'text/csv')],
        subject: baseName,
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );

    await tempFile.delete();
    return result.status == ShareResultStatus.success;
  }
}
