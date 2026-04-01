import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart';
import '../data/processing/sleep_pipeline_service.dart';
import '../data/persistence/dao/sleep_raw_imports_dao.dart';
import '../data/persistence/sleep_persistence_models.dart';
import 'health_connect/health_connect_sleep_adapter.dart';
import 'healthkit/healthkit_sleep_adapter.dart';
import 'ingestion/sleep_ingestion_models.dart';
import 'permissions/health_connect_sleep_permissions_service.dart';
import 'permissions/healthkit_sleep_permissions_service.dart';
import 'permissions/sleep_permission_controller.dart';
import 'permissions/sleep_permission_models.dart';
import 'permissions/sleep_permissions_service.dart';
import 'sleep_platform_channel.dart';

class SleepSyncResult {
  const SleepSyncResult({
    required this.success,
    required this.permissionState,
    required this.importedSessions,
    this.message,
  });

  final bool success;
  final SleepPermissionState permissionState;
  final int importedSessions;
  final String? message;
}

abstract class SleepImportService {
  Future<SleepSyncResult> importRecent({int lookbackDays = 30});
  Future<void> dispose();
}

abstract class SleepSettingsService implements SleepImportService {
  SleepPermissionController buildPermissionController();
  Future<bool> isTrackingEnabled();
  Future<void> setTrackingEnabled(bool enabled);
}

class SleepSyncService implements SleepSettingsService {
  static const String trackingEnabledKey = 'sleep_tracking_enabled';
  static final ValueNotifier<DateTime?> lastImportAtListenable =
      ValueNotifier<DateTime?>(null);

  SleepSyncService({
    AppDatabase? database,
    DatabaseHelper? databaseHelper,
    bool ownsDatabase = false,
  })  : _databaseFuture = database != null
            ? Future.value(database)
            : (databaseHelper ?? DatabaseHelper.instance).database,
        _ownsDatabase = ownsDatabase && database != null,
        _iosPermissionsService = null,
        _androidPermissionsService = null,
        _iosDataSource = null,
        _androidDataSource = null;

  SleepSyncService.withOverrides({
    required SleepPermissionsService iosPermissionsService,
    required SleepPermissionsService androidPermissionsService,
    required HealthKitDataSource iosDataSource,
    required HealthConnectDataSource androidDataSource,
    AppDatabase? database,
    DatabaseHelper? databaseHelper,
    bool ownsDatabase = false,
  })  : _databaseFuture = database != null
            ? Future.value(database)
            : (databaseHelper ?? DatabaseHelper.instance).database,
        _ownsDatabase = ownsDatabase && database != null,
        _iosPermissionsService = iosPermissionsService,
        _androidPermissionsService = androidPermissionsService,
        _iosDataSource = iosDataSource,
        _androidDataSource = androidDataSource;

  final Future<AppDatabase> _databaseFuture;
  final bool _ownsDatabase;
  AppDatabase? _database;
  SleepRawImportsDao? _rawDao;
  final SleepPermissionsService? _iosPermissionsService;
  final SleepPermissionsService? _androidPermissionsService;
  final HealthKitDataSource? _iosDataSource;
  final HealthConnectDataSource? _androidDataSource;

  @override
  SleepPermissionController buildPermissionController() {
    if (Platform.isIOS) {
      return SleepPermissionController(
        _iosPermissionsService ??
            const HealthKitSleepPermissionsService(
              HealthKitSleepMethodChannelBridge(),
            ),
      );
    }
    return SleepPermissionController(
      _androidPermissionsService ??
          const HealthConnectSleepPermissionsService(
            HealthConnectSleepMethodChannelBridge(),
          ),
    );
  }

  @override
  Future<bool> isTrackingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(trackingEnabledKey) ?? false;
  }

  @override
  Future<void> setTrackingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(trackingEnabledKey, enabled);
  }

  @override
  Future<SleepSyncResult> importRecent({int lookbackDays = 30}) async {
    final trackingEnabled = await isTrackingEnabled();
    if (!trackingEnabled) {
      return const SleepSyncResult(
        success: false,
        permissionState: SleepPermissionState.denied,
        importedSessions: 0,
        message: 'Sleep tracking is disabled in settings.',
      );
    }

    final permissionController = buildPermissionController();
    await permissionController.refresh();
    final permission = permissionController.state.value;
    if (permission.state != SleepPermissionState.ready) {
      return SleepSyncResult(
        success: false,
        permissionState: permission.state,
        importedSessions: 0,
        message: permission.message,
      );
    }

    await _ensureDaos();

    final nowUtc = DateTime.now().toUtc();
    final fromUtc = nowUtc.subtract(Duration(days: lookbackDays));
    final result = Platform.isIOS
        ? await _importWithHealthKit(fromUtc: fromUtc, toUtc: nowUtc)
        : await _importWithHealthConnect(fromUtc: fromUtc, toUtc: nowUtc);

    if (result.success) {
      lastImportAtListenable.value = DateTime.now().toUtc();
    }
    return result;
  }

  Future<List<SleepRawImportRecord>> fetchRecentRawImports({
    int lookbackDays = 7,
    int limit = 50,
  }) async {
    await _ensureDaos();
    final nowUtc = DateTime.now().toUtc();
    final fromUtc = nowUtc.subtract(Duration(days: lookbackDays));
    final toExclusive = nowUtc.add(const Duration(seconds: 1));
    final rows = await _rawDao!.findByDateRange(
      fromInclusive: fromUtc,
      toExclusive: toExclusive,
    );
    rows.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    if (rows.length <= limit) return rows;
    return rows.sublist(0, limit);
  }

  Future<SleepSyncResult> _importWithHealthConnect({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final permissionService = _androidPermissionsService ??
        const HealthConnectSleepPermissionsService(
          HealthConnectSleepMethodChannelBridge(),
        );
    final adapter = HealthConnectSleepAdapter(
      permissionsService: permissionService,
      dataSource: _androidDataSource ??
          const HealthConnectSleepMethodChannelDataSource(),
    );
    final import = await adapter.importRange(fromUtc: fromUtc, toUtc: toUtc);
    if (!import.isSuccess) {
      return SleepSyncResult(
        success: false,
        permissionState: _failureToPermissionState(import.failure?.error),
        importedSessions: 0,
        message: import.failure?.message,
      );
    }
    final run = await _runPipelineImport(import.batch!);
    return SleepSyncResult(
      success: true,
      permissionState: SleepPermissionState.ready,
      importedSessions: run.importedSessions,
    );
  }

  Future<SleepSyncResult> _importWithHealthKit({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final permissionService = _iosPermissionsService ??
        const HealthKitSleepPermissionsService(
          HealthKitSleepMethodChannelBridge(),
        );
    final adapter = HealthKitSleepAdapter(
      permissionsService: permissionService,
      dataSource:
          _iosDataSource ?? const HealthKitSleepMethodChannelDataSource(),
    );
    final import = await adapter.importRange(fromUtc: fromUtc, toUtc: toUtc);
    if (!import.isSuccess) {
      return SleepSyncResult(
        success: false,
        permissionState: _failureToPermissionState(import.failure?.error),
        importedSessions: 0,
        message: import.failure?.message,
      );
    }
    final run = await _runPipelineImport(import.batch!);
    return SleepSyncResult(
      success: true,
      permissionState: SleepPermissionState.ready,
      importedSessions: run.importedSessions,
    );
  }

  SleepPermissionState _failureToPermissionState(
    SleepPlatformServiceError? error,
  ) {
    return switch (error) {
      SleepPlatformServiceError.notInstalled =>
        SleepPermissionState.notInstalled,
      SleepPlatformServiceError.unavailable => SleepPermissionState.unavailable,
      SleepPlatformServiceError.permissionDenied => SleepPermissionState.denied,
      SleepPlatformServiceError.permissionPartial =>
        SleepPermissionState.partial,
      _ => SleepPermissionState.technicalError,
    };
  }

  Future<SleepPipelineRunResult> _runPipelineImport(
    SleepRawIngestionBatch batch,
  ) async {
    final db = _database ??= await _databaseFuture;
    final pipeline = SleepPipelineService(database: db);
    return pipeline.runImport(batch: batch);
  }

  @override
  Future<void> dispose() async {
    if (_ownsDatabase) {
      final db = _database ?? await _databaseFuture;
      await db.close();
    }
  }

  Future<void> _ensureDaos() async {
    if (_rawDao != null) return;
    final db = _database ??= await _databaseFuture;
    _rawDao = SleepRawImportsDao(db);
  }
}
