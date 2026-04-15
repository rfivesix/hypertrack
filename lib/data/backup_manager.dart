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

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

/// Manager responsible for application backup, restoration, and data export.
///
/// Supports full JSON backups with optional encryption and CSV exports for
/// nutrition, workouts, and measurements.
class BackupManager {
  /// Singleton instance of [BackupManager].
  static final BackupManager instance = BackupManager();

  final DatabaseHelper _userDb;
  final ProductDatabaseHelper _productDb;
  final WorkoutDatabaseHelper _workoutDb;
  final SharedPreferencesLoader _prefsLoader;

  static const int currentSchemaVersion = 4;

  BackupManager({
    DatabaseHelper? userDb,
    ProductDatabaseHelper? productDb,
    WorkoutDatabaseHelper? workoutDb,
    SharedPreferencesLoader? prefsLoader,
  })  : _userDb = userDb ?? DatabaseHelper.instance,
        _productDb = productDb ?? ProductDatabaseHelper.instance,
        _workoutDb = workoutDb ?? WorkoutDatabaseHelper.instance,
        _prefsLoader = prefsLoader ?? SharedPreferences.getInstance;

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
    final foodEntries = await _userDb.getAllFoodEntriesForBackup();
    final mealTemplates = await _userDb.getMealTemplatesForBackup();
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

    final suppHistoryRows = await db.select(db.supplementSettingsHistory).join([
      drift.leftOuterJoin(
        db.supplements,
        db.supplements.id.equalsExp(db.supplementSettingsHistory.supplementId),
      ),
    ]).get();
    final supplementSettingsHistory = suppHistoryRows
        .map(
          (r) => {
            'supplementId':
                r.readTable(db.supplementSettingsHistory).supplementId,
            'supplementLegacyLocalId':
                r.readTableOrNull(db.supplements)?.localId,
            'isTracked': r.readTable(db.supplementSettingsHistory).isTracked,
            'dose': r.readTable(db.supplementSettingsHistory).dose,
            'dailyGoal': r.readTable(db.supplementSettingsHistory).dailyGoal,
            'dailyLimit': r.readTable(db.supplementSettingsHistory).dailyLimit,
            'createdAt': r
                .readTable(db.supplementSettingsHistory)
                .createdAt
                .toIso8601String(),
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
    final prefs = await _prefsLoader();
    final userPrefs = <String, dynamic>{};
    for (String key in prefs.getKeys()) {
      userPrefs[key] = prefs.get(key);
    }

    // 6) Build backup object.
    final backup = HypertrackBackup(
      schemaVersion: currentSchemaVersion,
      foodEntries: foodEntries,
      mealTemplates: mealTemplates,
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

  @visibleForTesting
  Future<Map<String, dynamic>> generateBackupPayloadForTesting() async {
    return jsonDecode(await _generateBackupJson()) as Map<String, dynamic>;
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

      return await _importBackupPayload(payload);
    } catch (e) {
      debugPrint("Backup import failed: $e");
      return false;
    }
  }

  @visibleForTesting
  Future<bool> importBackupPayloadForTesting(
    Map<String, dynamic> payload,
  ) async {
    return _importBackupPayload(payload);
  }

  Future<bool> _importBackupPayload(Map<String, dynamic> payload) async {
    final backup = HypertrackBackup.fromJson(payload);

    if (backup.schemaVersion > currentSchemaVersion) {
      debugPrint("Backup version is newer than supported schema.");
      return false;
    }

    final prefs = await _prefsLoader();
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
      } else if (val is List && val.every((e) => e is String)) {
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

    await _userDb.importMealTemplates(backup.mealTemplates);

    await _workoutDb.importWorkoutData(
      routines: backup.routines,
      workoutLogs: backup.workoutLogs,
    );

    await _workoutDb.importCustomExercises(backup.customExercises);

    // Import DailyGoalsHistory
    if (backup.dailyGoalsHistory.isNotEmpty) {
      for (final row in backup.dailyGoalsHistory) {
        final targetCalories = _asInt(row['targetCalories']);
        final targetProtein = _asInt(row['targetProtein']);
        final targetCarbs = _asInt(row['targetCarbs']);
        final targetFat = _asInt(row['targetFat']);
        final targetWater = _asInt(row['targetWater']);
        final createdAt = _asDateTime(row['createdAt']);
        if (targetCalories == null ||
            targetProtein == null ||
            targetCarbs == null ||
            targetFat == null ||
            targetWater == null ||
            createdAt == null) {
          debugPrint(
            'Skipping malformed daily_goals_history row during backup import.',
          );
          continue;
        }
        await db.into(db.dailyGoalsHistory).insert(
              DailyGoalsHistoryCompanion(
                targetCalories: drift.Value(targetCalories),
                targetProtein: drift.Value(targetProtein),
                targetCarbs: drift.Value(targetCarbs),
                targetFat: drift.Value(targetFat),
                targetWater: drift.Value(targetWater),
                targetSteps: drift.Value(
                  _asInt(row['targetSteps']) ??
                      StepsSyncService.defaultStepsGoal,
                ),
                createdAt: drift.Value(createdAt),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
      }
    }

    // Import SupplementSettingsHistory
    if (backup.supplementSettingsHistory.isNotEmpty) {
      final supplementRows = await db.select(db.supplements).get();
      final validSupplementIds = supplementRows.map((s) => s.id).toSet();
      final supplementIdByLegacyLocalId = <String, String>{
        for (final row in supplementRows) row.localId.toString(): row.id,
      };
      await db.batch((batch) {
        for (final row in backup.supplementSettingsHistory) {
          final supplementIdRaw = row['supplementId']?.toString().trim();
          final legacyLocalIdRaw = row['supplementLegacyLocalId'];
          final legacyLocalId = _asInt(legacyLocalIdRaw)?.toString() ??
              legacyLocalIdRaw?.toString().trim();
          final mappedId = (supplementIdRaw != null &&
                  validSupplementIds.contains(supplementIdRaw))
              ? supplementIdRaw
              : (legacyLocalId != null
                  ? supplementIdByLegacyLocalId[legacyLocalId]
                  : null);
          final isTracked = _asBool(row['isTracked']);
          final dose = _asDouble(row['dose']);
          final createdAt = _asDateTime(row['createdAt']);
          if (mappedId == null ||
              isTracked == null ||
              dose == null ||
              createdAt == null) {
            debugPrint(
              'Skipping malformed supplement_settings_history row during backup import.',
            );
            continue;
          }
          batch.insert(
            db.supplementSettingsHistory,
            SupplementSettingsHistoryCompanion(
              supplementId: drift.Value(mappedId),
              isTracked: drift.Value(isTracked),
              dose: drift.Value(dose),
              dailyGoal: drift.Value(_asDouble(row['dailyGoal'])),
              dailyLimit: drift.Value(_asDouble(row['dailyLimit'])),
              createdAt: drift.Value(createdAt),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
        }
      });
    }

    String? restoredUserId;

    // Import Profile
    if (backup.profile != null) {
      final p = backup.profile!;
      final profileId = p['id']?.toString().trim();
      if (profileId != null && profileId.isNotEmpty) {
        restoredUserId = profileId;
        await db.into(db.profiles).insert(
              ProfilesCompanion(
                id: drift.Value(profileId),
                username: drift.Value(p['username']?.toString()),
                isCoach: drift.Value(_asBool(p['isCoach']) ?? false),
                visibility: drift.Value(
                  p['visibility']?.toString() ?? 'private',
                ),
                birthday: drift.Value(_asDateTime(p['birthday'])),
                height: drift.Value(_asInt(p['height'])),
                gender: drift.Value(p['gender']?.toString()),
                profileImagePath: drift.Value(
                  p['profileImagePath']?.toString(),
                ),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
      }
    }

    // Import AppSettings
    if (backup.appSettings != null) {
      final s = backup.appSettings!;
      final candidateUserId = s['userId']?.toString().trim();
      if (restoredUserId == null &&
          candidateUserId != null &&
          candidateUserId.isNotEmpty) {
        restoredUserId = candidateUserId;
      }

      if (restoredUserId != null) {
        final userId = restoredUserId;
        final existingProfile = await (db.select(
          db.profiles,
        )..where((t) => t.id.equals(userId)))
            .getSingleOrNull();

        // Ensure FK target exists even when profile payload is absent.
        if (existingProfile == null) {
          await db.into(db.profiles).insert(
                ProfilesCompanion(
                  id: drift.Value(userId),
                  visibility: const drift.Value('private'),
                  isCoach: const drift.Value(false),
                ),
                mode: drift.InsertMode.insertOrReplace,
              );
        }

        await db.into(db.appSettings).insert(
              AppSettingsCompanion(
                userId: drift.Value(userId),
                themeMode: drift.Value(s['themeMode']?.toString() ?? 'system'),
                unitSystem:
                    drift.Value(s['unitSystem']?.toString() ?? 'metric'),
                targetCalories: drift.Value(
                  _asInt(s['targetCalories']) ?? 2500,
                ),
                targetProtein: drift.Value(_asInt(s['targetProtein']) ?? 180),
                targetCarbs: drift.Value(_asInt(s['targetCarbs']) ?? 250),
                targetFat: drift.Value(_asInt(s['targetFat']) ?? 80),
                targetWater: drift.Value(_asInt(s['targetWater']) ?? 3000),
                targetSteps: drift.Value(
                  _asInt(s['targetSteps']) ?? StepsSyncService.defaultStepsGoal,
                ),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
      }
    }

    if (backup.healthStepSegments.isNotEmpty) {
      final sanitizedSegments = _sanitizeHealthSegments(
        backup.healthStepSegments,
      );
      if (sanitizedSegments.isNotEmpty) {
        await _userDb.upsertHealthStepSegments(sanitizedSegments);
      }
    }

    debugPrint("Backup import succeeded.");
    return true;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final normalized = value.trim();
      return int.tryParse(normalized) ?? double.tryParse(normalized)?.toInt();
    }
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value.trim());
    return null;
  }

  List<Map<String, dynamic>> _sanitizeHealthSegments(
    List<Map<String, dynamic>> rawSegments,
  ) {
    final sanitized = <Map<String, dynamic>>[];
    for (final row in rawSegments) {
      final provider = row['provider']?.toString().trim();
      final externalKey = row['externalKey']?.toString().trim();
      final startAt = _asDateTime(row['startAt']);
      final endAt = _asDateTime(row['endAt']);
      final stepCount = _asInt(row['stepCount']);
      if (provider == null ||
          provider.isEmpty ||
          externalKey == null ||
          externalKey.isEmpty ||
          startAt == null ||
          endAt == null ||
          !endAt.isAfter(startAt) ||
          stepCount == null ||
          stepCount < 0) {
        debugPrint(
          'Skipping malformed health_step_segments row during backup import.',
        );
        continue;
      }
      final sourceId = row['sourceId']?.toString().trim();
      sanitized.add(<String, dynamic>{
        'provider': provider,
        'sourceId': (sourceId == null || sourceId.isEmpty) ? null : sourceId,
        'startAt': startAt.toUtc().toIso8601String(),
        'endAt': endAt.toUtc().toIso8601String(),
        'stepCount': stepCount,
        'externalKey': externalKey,
      });
    }
    return sanitized;
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
      final prefs = await _prefsLoader();
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
      final prefs = await _prefsLoader();
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
