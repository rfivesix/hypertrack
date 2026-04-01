import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart';
import '../data/mapping/health_connect_mapper.dart';
import '../data/mapping/healthkit_mapper.dart';
import '../data/persistence/dao/sleep_canonical_dao.dart';
import '../data/persistence/dao/sleep_nightly_analyses_dao.dart';
import '../data/persistence/dao/sleep_raw_imports_dao.dart';
import '../data/persistence/sleep_persistence_models.dart';
import '../domain/heart_rate_sample.dart';
import '../domain/sleep_session.dart';
import '../domain/sleep_stage_segment.dart';
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
  SleepCanonicalSessionsDao? _sessionsDao;
  SleepCanonicalStageSegmentsDao? _stagesDao;
  SleepCanonicalHeartRateSamplesDao? _hrDao;
  SleepNightlyAnalysesDao? _analysesDao;
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
    final mapping = const HealthConnectMapper().map(import.batch!);
    await _persistBatch(
      import.batch!,
      mapping.sessions,
      mapping.stageSegments,
      mapping.heartRateSamples,
    );
    return SleepSyncResult(
      success: true,
      permissionState: SleepPermissionState.ready,
      importedSessions: mapping.sessions.length,
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
    final mapping = const HealthKitMapper().map(import.batch!);
    await _persistBatch(
      import.batch!,
      mapping.sessions,
      mapping.stageSegments,
      mapping.heartRateSamples,
    );
    return SleepSyncResult(
      success: true,
      permissionState: SleepPermissionState.ready,
      importedSessions: mapping.sessions.length,
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

  Future<void> _persistBatch(
    SleepRawIngestionBatch batch,
    List<SleepSession> sessions,
    List<SleepStageSegment> stageSegments,
    List<HeartRateSample> heartRateSamples,
  ) async {
    await _ensureDaos();
    final importedAt = DateTime.now().toUtc();
    const normalizationVersion = 'sleep-import-v1';
    const analysisVersion = 'sleep-analysis-v1';
    await _database!.transaction(() async {
      final rawRows = batch.sessions
          .map(
            (session) => SleepRawImportCompanion(
              id: 'raw:${session.recordId}',
              sourcePlatform: session.sourcePlatform,
              sourceAppId: session.sourceAppId,
              sourceConfidence: session.sourceConfidence,
              sourceRecordHash: _hashRecord(
                [
                  session.sourcePlatform,
                  session.recordId,
                  session.startAtUtc.toIso8601String(),
                  session.endAtUtc.toIso8601String(),
                ].join('|'),
              ),
              importStatus: 'success',
              importedAt: importedAt,
              payloadJson: jsonEncode(<String, dynamic>{
                'recordId': session.recordId,
                'startAtUtc': session.startAtUtc.toIso8601String(),
                'endAtUtc': session.endAtUtc.toIso8601String(),
                'platformSessionType': session.platformSessionType,
              }),
            ),
          )
          .toList(growable: false);
      await _rawDao!.upsertBatch(rawRows);

      final canonicalSessionRows = sessions
          .map<SleepCanonicalSessionCompanion>(
            (session) => SleepCanonicalSessionCompanion(
              id: session.id,
              rawImportId: 'raw:${session.id}',
              sourcePlatform: session.sourcePlatform,
              sourceAppId: session.sourceAppId,
              sourceConfidence: session.sourceConfidence,
              sourceRecordHash: session.sourceRecordHash ??
                  _hashRecord('session:${session.id}'),
              normalizationVersion: normalizationVersion,
              sessionType: session.sessionType.name,
              startedAt: session.startAtUtc,
              endedAt: session.endAtUtc,
              timezone: null,
              importedAt: importedAt,
              normalizedAt: importedAt,
            ),
          )
          .toList(growable: false);
      await _sessionsDao!.upsertBatch(canonicalSessionRows);

      final stageRows = stageSegments
          .map<SleepCanonicalStageSegmentCompanion>(
            (segment) => SleepCanonicalStageSegmentCompanion(
              id: segment.id,
              sessionId: segment.sessionId,
              sourcePlatform: segment.sourcePlatform,
              sourceAppId: segment.sourceAppId,
              sourceConfidence: segment.sourceConfidence,
              sourceRecordHash: segment.sourceRecordHash ??
                  _hashRecord('segment:${segment.id}'),
              normalizationVersion: normalizationVersion,
              stage: segment.stage.name,
              startedAt: segment.startAtUtc,
              endedAt: segment.endAtUtc,
              importedAt: importedAt,
              normalizedAt: importedAt,
            ),
          )
          .toList(growable: false);
      await _stagesDao!.upsertBatch(stageRows);

      final hrRows = heartRateSamples
          .map<SleepCanonicalHeartRateSampleCompanion>(
            (sample) => SleepCanonicalHeartRateSampleCompanion(
              id: sample.id,
              sessionId: sample.sessionId,
              sourcePlatform: sample.sourcePlatform,
              sourceAppId: sample.sourceAppId,
              sourceConfidence: sample.sourceConfidence,
              sourceRecordHash:
                  sample.sourceRecordHash ?? _hashRecord('hr:${sample.id}'),
              normalizationVersion: normalizationVersion,
              sampledAt: sample.sampledAtUtc,
              bpm: sample.bpm,
              importedAt: importedAt,
              normalizedAt: importedAt,
            ),
          )
          .toList(growable: false);
      await _hrDao!.upsertBatch(hrRows);

      if (sessions.isNotEmpty) {
        final hrBySession = <String, List<HeartRateSample>>{};
        for (final sample in heartRateSamples) {
          hrBySession.putIfAbsent(sample.sessionId, () => []).add(sample);
        }

        final analysisRows = sessions
            .map<SleepNightlyAnalysisCompanion>(
              (session) => SleepNightlyAnalysisCompanion(
                id: 'analysis:${session.id}',
                sessionId: session.id,
                sourcePlatform: session.sourcePlatform,
                sourceAppId: session.sourceAppId,
                sourceConfidence: session.sourceConfidence,
                sourceRecordHash: session.sourceRecordHash ??
                    _hashRecord('analysis:${session.id}'),
                normalizationVersion: normalizationVersion,
                analysisVersion: analysisVersion,
                nightDate: _nightKey(session.endAtUtc),
                score: null,
                totalSleepMinutes:
                    session.endAtUtc.difference(session.startAtUtc).inMinutes,
                sleepEfficiencyPct: null,
                restingHeartRateBpm: _averageBpm(hrBySession[session.id]),
                analyzedAt: importedAt,
              ),
            )
            .toList(growable: false);

        await _analysesDao!.upsertBatch(analysisRows);
      }
    });
  }

  double? _averageBpm(List<HeartRateSample>? samples) {
    if (samples == null || samples.isEmpty) return null;
    final total = samples.fold<double>(0, (sum, sample) => sum + sample.bpm);
    return total / samples.length;
  }

  String _nightKey(DateTime utcDate) {
    final local = utcDate.toLocal();
    final normalized = DateTime(local.year, local.month, local.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  String _hashRecord(String value) =>
      sha1.convert(utf8.encode(value)).toString();

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
    _sessionsDao = SleepCanonicalSessionsDao(db);
    _stagesDao = SleepCanonicalStageSegmentsDao(db);
    _hrDao = SleepCanonicalHeartRateSamplesDao(db);
    _analysesDao = SleepNightlyAnalysesDao(db);
  }
}
