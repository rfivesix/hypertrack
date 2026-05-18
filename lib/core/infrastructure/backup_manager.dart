// lib/core/infrastructure/backup_manager.dart

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

import '../../data/database_helper.dart';
import '../../data/drift_database.dart' as db;
import '../../features/diary/data/sources/diary_local_data_source.dart';
import '../../features/diary/data/sources/meal_local_data_source.dart';
import '../../features/profile/data/sources/profile_local_data_source.dart';
import '../../features/supplements/data/sources/supplement_local_data_source.dart';
import '../../features/steps/data/sources/steps_local_data_source.dart';
import '../../features/workout/data/sources/workout_local_data_source.dart';
import '../../features/diary/domain/models/food_item.dart';
import '../../features/app/domain/models/train_libre_backup.dart';
import '../../util/encryption_util.dart';
import '../../features/diary/data/sources/product_local_data_source.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

class BackupManager {
  static final BackupManager instance = BackupManager();
  static const String currentBackupAppName = 'Train Libre';
  static const String currentBackupFilePrefix = 'train-libre-backup';
  static const String currentAutoBackupFilePrefix = 'train-libre-auto';
  static const String currentApplicationId = 'com.rfivesix.trainlibre';

  // Backwards compatibility for tests
  static const int currentSchemaVersion = 4;
  static const List<String> legacyBackupAppNames = ['Hypertrack'];
  static const List<String> legacyApplicationIds = ['com.rfivesix.hypertrack'];
  static const List<String> legacyBackupFilePrefixes = ['hypertrack-backup'];

  final DatabaseHelper _dbHelper;
  final DiaryLocalDataSource _diaryDb;
  final ProductLocalDataSource _productDb;
  final WorkoutLocalDataSource _workoutDb;
  final ProfileLocalDataSource _profileDb;
  final SupplementLocalDataSource _supplementDb;
  final MealLocalDataSource _mealDb;
  final StepsLocalDataSource _stepsDb;
  final SharedPreferencesLoader _prefsLoader;

  BackupManager({
    DatabaseHelper? dbHelper,
    DatabaseHelper? userDb, // Backwards compatibility for tests
    DiaryLocalDataSource? diaryDb,
    ProductLocalDataSource? productDb,
    WorkoutLocalDataSource? workoutDb,
    ProfileLocalDataSource? profileDb,
    SupplementLocalDataSource? supplementDb,
    MealLocalDataSource? mealDb,
    StepsLocalDataSource? stepsDb,
    SharedPreferencesLoader? prefsLoader,
  })  : _dbHelper = dbHelper ?? userDb ?? DatabaseHelper.instance,
        _prefsLoader = prefsLoader ?? SharedPreferences.getInstance,
        _diaryDb = diaryDb ??
            DiaryLocalDataSource(
                (dbHelper ?? userDb ?? DatabaseHelper.instance).dbInstance),
        _productDb = productDb ??
            ProductLocalDataSource(
                (dbHelper ?? userDb ?? DatabaseHelper.instance).dbInstance),
        _workoutDb = workoutDb ??
            WorkoutLocalDataSource(
                (dbHelper ?? userDb ?? DatabaseHelper.instance).dbInstance),
        _profileDb = profileDb ??
            ProfileLocalDataSource(
                (dbHelper ?? userDb ?? DatabaseHelper.instance).dbInstance),
        _supplementDb = supplementDb ??
            SupplementLocalDataSource(
                (dbHelper ?? userDb ?? DatabaseHelper.instance).dbInstance),
        _mealDb = mealDb ??
            MealLocalDataSource(
                (dbHelper ?? userDb ?? DatabaseHelper.instance).dbInstance),
        _stepsDb = stepsDb ??
            StepsLocalDataSource(
                (dbHelper ?? userDb ?? DatabaseHelper.instance).dbInstance);

  ui.Rect _sharePositionOrigin() {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) return const ui.Rect.fromLTWH(0, 0, 1, 1);
    final view = views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    return ui.Rect.fromLTWH(
        0, 0, math.max(1, logicalSize.width), math.max(1, logicalSize.height));
  }

  Future<Map<String, dynamic>> generateBackupPayload() async {
    final dbInst = _dbHelper.dbInstance;
    final foodEntries = await _diaryDb.getAllFoodEntries();
    final mealTemplates = await _mealDb.getMealTemplatesForBackup();
    final fluidEntries = await _diaryDb.getAllFluidEntries();
    final favoriteBarcodes = await _productDb.getFavoriteBarcodes();
    final measurementSessions = await _profileDb.getMeasurementSessions();
    final customProductRows = await (dbInst.select(dbInst.products)
          ..where((t) => t.source.equals('user')))
        .get();
    final customFoodItems = customProductRows
        .map((row) => FoodItem(
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
            category: row.category))
        .toList();
    final routines = await _workoutDb.getAllRoutinesWithDetails();
    final workoutLogs = await _workoutDb.getFullWorkoutLogs();
    final supplements = await _supplementDb.getAllSupplements();
    final supplementLogs = await _supplementDb.getAllSupplementLogsForBackup();
    final customExercises = await _workoutDb.getCustomExercises();

    final goalsHistoryRows =
        await dbInst.select(dbInst.dailyGoalsHistory).get();
    final dailyGoalsHistory = goalsHistoryRows
        .map((r) => {
              'targetCalories': r.targetCalories,
              'targetProtein': r.targetProtein,
              'targetCarbs': r.targetCarbs,
              'targetFat': r.targetFat,
              'targetWater': r.targetWater,
              'targetSteps': r.targetSteps,
              'createdAt': r.createdAt.toIso8601String(),
            })
        .toList();

    final suppHistoryRows =
        await dbInst.select(dbInst.supplementSettingsHistory).join([
      drift.leftOuterJoin(
        dbInst.supplements,
        dbInst.supplements.id
            .equalsExp(dbInst.supplementSettingsHistory.supplementId),
      ),
    ]).get();
    final supplementSettingsHistory = suppHistoryRows.map((row) {
      final sHistory = row.readTable(dbInst.supplementSettingsHistory);
      final supplement = row.readTableOrNull(dbInst.supplements);
      return {
        'supplementId': sHistory.supplementId,
        'supplementLegacyLocalId': supplement?.localId,
        'isTracked': sHistory.isTracked,
        'dose': sHistory.dose,
        'dailyGoal': sHistory.dailyGoal,
        'dailyLimit': sHistory.dailyLimit,
        'createdAt': sHistory.createdAt.toIso8601String(),
      };
    }).toList();

    final settingsRows = await (dbInst.select(dbInst.appSettings)
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.localId, mode: drift.OrderingMode.desc)
          ]))
        .get();
    final settingsRow = settingsRows.isEmpty ? null : settingsRows.first;
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
            'targetSteps': settingsRow.targetSteps,
          }
        : null;

    final profileRows = await (dbInst.select(dbInst.profiles)
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.localId, mode: drift.OrderingMode.desc)
          ]))
        .get();
    final profileRow = profileRows.isEmpty ? null : profileRows.first;
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

    final healthStepRows = await dbInst.select(dbInst.healthStepSegments).get();
    final healthStepSegments = healthStepRows
        .map((r) => {
              'provider': r.provider,
              'sourceId': r.sourceId,
              'startAt': r.startAt.toUtc().toIso8601String(),
              'endAt': r.endAt.toUtc().toIso8601String(),
              'stepCount': r.stepCount,
              'externalKey': r.externalKey,
            })
        .toList();

    final prefs = await _prefsLoader();
    final userPrefs = <String, dynamic>{
      for (String key in prefs.getKeys()) key: prefs.get(key)
    };

    final backup = TrainLibreBackup(
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
        healthStepSegments: healthStepSegments);
    final payload = backup.toJson();
    payload['appName'] = currentBackupAppName;
    payload['applicationId'] = currentApplicationId;
    payload['backupFilePrefix'] = currentBackupFilePrefix;
    payload['generatedAtUtc'] = DateTime.now().toUtc().toIso8601String();
    return payload;
  }

  Future<Map<String, dynamic>> generateBackupPayloadForTesting() =>
      generateBackupPayload();

  Future<String> _generateBackupJson() async {
    final payload = await generateBackupPayload();
    return compute(jsonEncode, payload);
  }

  Future<bool> exportFullBackup() async {
    try {
      final jsonString = await _generateBackupJson();
      return await _writeAndShareFile(jsonString, currentBackupFilePrefix);
    } catch (e) {
      return false;
    }
  }

  Future<bool> exportFullBackupEncrypted(String passphrase) async {
    try {
      final jsonString = await _generateBackupJson();
      final wrapper =
          await EncryptionUtil.encryptString(jsonString, passphrase);
      final wrappedJson = await compute(jsonEncode, wrapper);
      return await _writeAndShareFile(
          wrappedJson, '$currentBackupFilePrefix-enc');
    } catch (e) {
      return false;
    }
  }

  Future<bool> _writeAndShareFile(String content, String baseName) async {
    final tempDir = await getTemporaryDirectory();
    final ts = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final file = File('${tempDir.path}/$baseName-[$ts].json');
    await file.writeAsString(content);
    final res = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: '$currentBackupAppName Backup $ts',
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
    if (await file.exists()) await file.delete();
    return res.status == ShareResultStatus.success;
  }

  Future<bool> importFullBackupAuto(String filePath,
      {String? passphrase}) async {
    try {
      final raw = await File(filePath).readAsString();
      final jsonMapRaw = await compute(jsonDecode, raw) as Map<String, dynamic>;
      Map<String, dynamic> payload;
      if (jsonMapRaw['enc'] != null) {
        final clearText =
            await EncryptionUtil.decryptToString(jsonMapRaw, passphrase ?? "");
        payload = await compute(jsonDecode, clearText) as Map<String, dynamic>;
      } else {
        payload = jsonMapRaw;
      }
      return await _importBackupPayload(payload);
    } catch (e) {
      return false;
    }
  }

  Future<bool> importBackupPayloadForTesting(Map<String, dynamic> payload) =>
      _importBackupPayload(payload);

  bool _isAcceptedBackupMetadata(Map<String, dynamic> payload) {
    final rawAppName = payload['appName']?.toString().trim();
    final rawApplicationId = payload['applicationId']?.toString().trim();
    final rawFilePrefix = payload['backupFilePrefix']?.toString().trim();

    final allowedAppNames = <String>{
      currentBackupAppName,
      ...legacyBackupAppNames,
    };
    final allowedApplicationIds = <String>{
      currentApplicationId,
      ...legacyApplicationIds,
    };
    final allowedFilePrefixes = <String>{
      currentBackupFilePrefix,
      ...legacyBackupFilePrefixes,
    };

    if (rawAppName != null &&
        rawAppName.isNotEmpty &&
        !allowedAppNames.contains(rawAppName)) {
      return false;
    }
    if (rawApplicationId != null &&
        rawApplicationId.isNotEmpty &&
        !allowedApplicationIds.contains(rawApplicationId)) {
      return false;
    }
    if (rawFilePrefix != null &&
        rawFilePrefix.isNotEmpty &&
        !allowedFilePrefixes.contains(rawFilePrefix)) {
      return false;
    }
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

  Future<bool> _importBackupPayload(Map<String, dynamic> payload) async {
    if (!_isAcceptedBackupMetadata(payload)) {
      debugPrint('Backup metadata rejected.');
      return false;
    }

    final backup = TrainLibreBackup.fromJson(payload);
    final prefs = await _prefsLoader();
    await prefs.clear();
    await _dbHelper.clearAllUserData();
    await _workoutDb.clearAllWorkoutData();

    final dbInst = _dbHelper.dbInstance;
    await (dbInst.delete(
      dbInst.products,
    )..where((t) => t.source.equals('user')))
        .go();

    for (final entry in backup.userPreferences.entries) {
      final k = entry.key, v = entry.value;
      if (v is bool) {
        await prefs.setBool(k, v);
      } else if (v is int) {
        await prefs.setInt(k, v);
      } else if (v is double) {
        await prefs.setDouble(k, v);
      } else if (v is String) {
        await prefs.setString(k, v);
      } else if (v is List && v.every((e) => e is String)) {
        await prefs.setStringList(k, v.cast<String>());
      }
    }

    await _dbHelper.importUserData(
        foodEntries: backup.foodEntries,
        fluidEntries: backup.fluidEntries,
        favoriteBarcodes: backup.favoriteBarcodes,
        measurementSessions: backup.measurementSessions,
        supplements: backup.supplements,
        supplementLogs: backup.supplementLogs);

    await dbInst.batch((batch) {
      for (final item in backup.customFoodItems) {
        batch.insert(
          dbInst.products,
          db.ProductsCompanion(
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

    await _mealDb.importMealTemplates(backup.mealTemplates);
    await _workoutDb.importWorkoutData(
        routines: backup.routines, workoutLogs: backup.workoutLogs);
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
        await dbInst.into(dbInst.dailyGoalsHistory).insert(
              db.DailyGoalsHistoryCompanion(
                targetCalories: drift.Value(targetCalories),
                targetProtein: drift.Value(targetProtein),
                targetCarbs: drift.Value(targetCarbs),
                targetFat: drift.Value(targetFat),
                targetWater: drift.Value(targetWater),
                targetSteps: drift.Value(
                  _asInt(row['targetSteps']) ?? 8000,
                ),
                createdAt: drift.Value(createdAt),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
      }
    }

    // Import SupplementSettingsHistory
    if (backup.supplementSettingsHistory.isNotEmpty) {
      final supplementRows = await dbInst.select(dbInst.supplements).get();
      final validSupplementIds = supplementRows.map((s) => s.id).toSet();
      final supplementIdByLegacyLocalId = <String, String>{
        for (final row in supplementRows) row.localId.toString(): row.id,
      };
      await dbInst.batch((batch) {
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
            dbInst.supplementSettingsHistory,
            db.SupplementSettingsHistoryCompanion(
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
        await dbInst.into(dbInst.profiles).insert(
              db.ProfilesCompanion(
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
        final existingProfile = await (dbInst.select(
          dbInst.profiles,
        )..where((t) => t.id.equals(userId)))
            .getSingleOrNull();

        // Ensure FK target exists even when profile payload is absent.
        if (existingProfile == null) {
          await dbInst.into(dbInst.profiles).insert(
                db.ProfilesCompanion(
                  id: drift.Value(userId),
                  visibility: const drift.Value('private'),
                  isCoach: const drift.Value(false),
                ),
                mode: drift.InsertMode.insertOrReplace,
              );
        }

        await dbInst.into(dbInst.appSettings).insert(
              db.AppSettingsCompanion(
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
                  _asInt(s['targetSteps']) ?? 8000,
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
        final companions = sanitizedSegments.map((row) {
          return db.HealthStepSegmentsCompanion.insert(
            provider: row['provider'],
            sourceId: drift.Value(row['sourceId']),
            startAt: DateTime.parse(row['startAt']),
            endAt: DateTime.parse(row['endAt']),
            stepCount: row['stepCount'],
            externalKey: row['externalKey'],
          );
        }).toList();
        await _stepsDb.upsertHealthStepSegments(companions);
      }
    }

    debugPrint("Backup import succeeded.");
    return true;
  }

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
      final lastBackupMillis = prefs.getInt('last_auto_backup_timestamp') ?? 0;
      final lastBackup = DateTime.fromMillisecondsSinceEpoch(lastBackupMillis);

      if (!force && DateTime.now().difference(lastBackup) < interval) {
        return false;
      }

      final jsonString = await _generateBackupJson();
      String content = jsonString;
      String suffix = '';

      if (encrypted && passphrase != null) {
        final wrapper =
            await EncryptionUtil.encryptString(jsonString, passphrase);
        content = await compute(jsonEncode, wrapper);
        suffix = '-enc';
      }

      final directory = dirPath != null
          ? Directory(dirPath)
          : await getApplicationDocumentsDirectory();
      final ts = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final file = File(p.join(
          directory.path, '$currentAutoBackupFilePrefix$suffix-[$ts].json'));

      await file.writeAsString(content);
      await prefs.setInt(
          'last_auto_backup_timestamp', DateTime.now().millisecondsSinceEpoch);

      // Handle retention
      if (retention > 0) {
        final files = directory
            .listSync()
            .whereType<File>()
            .where((f) =>
                p.basename(f.path).startsWith(currentAutoBackupFilePrefix))
            .toList();
        if (files.length > retention) {
          files.sort(
              (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
          for (var i = 0; i < files.length - retention; i++) {
            await files[i].delete();
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> exportNutritionAsCsv() async {
    final entries = await _diaryDb.getAllFoodEntries();
    if (entries.isEmpty) return false;
    final barcodes = entries.map((e) => e.barcode).toSet().toList();
    final products = await _productDb.getProductsByBarcodes(barcodes);
    final pMap = {for (var p in products) p.barcode: p};
    List<List<dynamic>> rows = [
      ['date', 'time', 'food', 'grams']
    ];
    for (final e in entries) {
      final p = pMap[e.barcode];
      if (p != null) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(e.timestamp),
          DateFormat('HH:mm').format(e.timestamp),
          p.name,
          e.quantityInGrams
        ]);
      }
    }
    return await _createAndShareCsv(rows, 'nutrition');
  }

  Future<bool> exportWorkoutsAsCsv() async {
    final logs = await _workoutDb.getFullWorkoutLogs();
    if (logs.isEmpty) return false;
    List<List<dynamic>> rows = [
      ['start', 'end', 'routine', 'exercise', 'weight', 'reps']
    ];
    for (final l in logs) {
      for (final s in l.sets) {
        rows.add([
          l.startTime.toIso8601String(),
          l.endTime?.toIso8601String() ?? '',
          l.routineName ?? '',
          s.exerciseName,
          s.weightKg ?? 0,
          s.reps ?? 0
        ]);
      }
    }
    return await _createAndShareCsv(rows, 'workouts');
  }

  Future<bool> exportMeasurementsAsCsv() async {
    final sessions = await _profileDb.getMeasurementSessions();
    if (sessions.isEmpty) return false;
    List<List<dynamic>> rows = [
      ['date', 'type', 'value', 'unit']
    ];
    for (final s in sessions) {
      for (final m in s.measurements) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(s.timestamp),
          m.type,
          m.value,
          m.unit
        ]);
      }
    }
    return await _createAndShareCsv(rows, 'measurements');
  }

  Future<bool> _createAndShareCsv(
      List<List<dynamic>> rows, String baseName) async {
    final csvData = csv.encode(rows);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$baseName.csv');
    await file.writeAsString(csvData);
    final res = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: baseName,
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
    await file.delete();
    return res.status == ShareResultStatus.success;
  }

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
        final probe = File(p.join(directory.path, '.train-libre-write-probe'));
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
}

@visibleForTesting
Future<String> encodeBackupJsonPayloadForTesting(
  Map<String, dynamic> payload,
) {
  return compute(jsonEncode, payload);
}

@visibleForTesting
Future<Map<String, dynamic>> decodeBackupJsonPayloadForTesting(
    String source) async {
  final decoded = await compute(jsonDecode, source);
  if (decoded is! Map) {
    throw const FormatException('Backup JSON root must be an object.');
  }
  return decoded.cast<String, dynamic>();
}
