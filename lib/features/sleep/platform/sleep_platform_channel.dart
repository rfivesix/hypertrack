import 'package:flutter/services.dart';

import 'health_connect/health_connect_sleep_adapter.dart';
import 'healthkit/healthkit_sleep_adapter.dart';
import 'ingestion/sleep_ingestion_models.dart';
import 'permissions/health_connect_sleep_permissions_service.dart';
import 'permissions/healthkit_sleep_permissions_service.dart';

class HealthConnectSleepMethodChannelBridge
    implements HealthConnectPermissionBridge {
  const HealthConnectSleepMethodChannelBridge();

  static const MethodChannel _channel = MethodChannel(
    'hypertrack.health/sleep_health_connect',
  );

  @override
  Future<HealthConnectAvailability> getAvailability() async {
    try {
      final value = await _channel.invokeMethod<String>('getAvailability');
      return switch ((value ?? '').toLowerCase()) {
        'available' => HealthConnectAvailability.available,
        'not_installed' => HealthConnectAvailability.notInstalled,
        _ => HealthConnectAvailability.unavailable,
      };
    } on PlatformException catch (e) {
      if (e.code == 'not_installed') {
        return HealthConnectAvailability.notInstalled;
      }
      return HealthConnectAvailability.unavailable;
    }
  }

  @override
  Future<HealthConnectPermissionSnapshot> checkPermissions() async {
    final map =
        await _channel.invokeMapMethod<String, dynamic>('checkPermissions') ??
            const <String, dynamic>{};
    return HealthConnectPermissionSnapshot(
      sleepGranted: map['sleepGranted'] == true,
      heartRateGranted: map['heartRateGranted'] == true,
    );
  }

  @override
  Future<HealthConnectPermissionSnapshot> requestPermissions() async {
    final map =
        await _channel.invokeMapMethod<String, dynamic>('requestPermissions') ??
            const <String, dynamic>{};
    return HealthConnectPermissionSnapshot(
      sleepGranted: map['sleepGranted'] == true,
      heartRateGranted: map['heartRateGranted'] == true,
    );
  }
}

class HealthKitSleepMethodChannelBridge implements HealthKitPermissionBridge {
  const HealthKitSleepMethodChannelBridge();

  static const MethodChannel _channel = MethodChannel(
    'hypertrack.health/sleep_healthkit',
  );

  @override
  Future<bool> isAvailable() async {
    final available = await _channel.invokeMethod<bool>('getAvailability');
    return available == true;
  }

  @override
  Future<HealthKitAuthorizationSnapshot> checkAuthorization() async {
    final map =
        await _channel.invokeMapMethod<String, dynamic>('checkPermissions') ??
            const <String, dynamic>{};
    return HealthKitAuthorizationSnapshot(
      sleepGranted: map['sleepGranted'] == true,
      heartRateGranted: map['heartRateGranted'] == true,
    );
  }

  @override
  Future<HealthKitAuthorizationSnapshot> requestAuthorization() async {
    final map =
        await _channel.invokeMapMethod<String, dynamic>('requestPermissions') ??
            const <String, dynamic>{};
    return HealthKitAuthorizationSnapshot(
      sleepGranted: map['sleepGranted'] == true,
      heartRateGranted: map['heartRateGranted'] == true,
    );
  }
}

class HealthConnectSleepMethodChannelDataSource
    implements HealthConnectDataSource {
  const HealthConnectSleepMethodChannelDataSource();

  static const MethodChannel _channel = MethodChannel(
    'hypertrack.health/sleep_health_connect',
  );

  @override
  Future<SleepRawIngestionBatch> readSleepAndHeartRate({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
          'readSleepAndHeartRate',
          <String, dynamic>{
            'fromUtcIso': fromUtc.toUtc().toIso8601String(),
            'toUtcIso': toUtc.toUtc().toIso8601String(),
          },
        ) ??
        const <String, dynamic>{};
    return _mapBatch(response);
  }
}

class HealthKitSleepMethodChannelDataSource implements HealthKitDataSource {
  const HealthKitSleepMethodChannelDataSource();

  static const MethodChannel _channel = MethodChannel(
    'hypertrack.health/sleep_healthkit',
  );

  @override
  Future<SleepRawIngestionBatch> readSleepAndHeartRate({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
          'readSleepAndHeartRate',
          <String, dynamic>{
            'fromUtcIso': fromUtc.toUtc().toIso8601String(),
            'toUtcIso': toUtc.toUtc().toIso8601String(),
          },
        ) ??
        const <String, dynamic>{};
    return _mapBatch(response);
  }
}

SleepRawIngestionBatch _mapBatch(Map<String, dynamic> map) {
  final sessionRows = (map['sessions'] as List<dynamic>? ?? const <dynamic>[]);
  final segmentRows =
      (map['stageSegments'] as List<dynamic>? ?? const <dynamic>[]);
  final hrRows =
      (map['heartRateSamples'] as List<dynamic>? ?? const <dynamic>[]);

  return SleepRawIngestionBatch(
    sessions: sessionRows
        .map((row) => _mapSession(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false),
    stageSegments: segmentRows
        .map((row) => _mapSegment(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false),
    heartRateSamples: hrRows
        .map((row) => _mapHeartRate(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false),
  );
}

SleepIngestionSession _mapSession(Map<String, dynamic> row) {
  return SleepIngestionSession(
    recordId: row['recordId'] as String,
    startAtUtc: DateTime.parse(row['startAtUtcIso'] as String).toUtc(),
    endAtUtc: DateTime.parse(row['endAtUtcIso'] as String).toUtc(),
    platformSessionType: (row['platformSessionType'] as String?) ?? 'sleep',
    sourcePlatform: (row['sourcePlatform'] as String?) ?? 'unknown',
    sourceAppId: row['sourceAppId'] as String?,
    sourceDevice: row['sourceDevice'] as String?,
    sourceRecordHash: row['sourceRecordHash'] as String?,
    sourceConfidence: row['sourceConfidence'] as String?,
  );
}

SleepIngestionStageSegment _mapSegment(Map<String, dynamic> row) {
  return SleepIngestionStageSegment(
    recordId: row['recordId'] as String,
    sessionRecordId: row['sessionRecordId'] as String,
    startAtUtc: DateTime.parse(row['startAtUtcIso'] as String).toUtc(),
    endAtUtc: DateTime.parse(row['endAtUtcIso'] as String).toUtc(),
    platformStage: row['platformStage'] as String,
    sourcePlatform: (row['sourcePlatform'] as String?) ?? 'unknown',
    sourceAppId: row['sourceAppId'] as String?,
    sourceDevice: row['sourceDevice'] as String?,
    sourceRecordHash: row['sourceRecordHash'] as String?,
    sourceConfidence: row['sourceConfidence'] as String?,
  );
}

SleepIngestionHeartRateSample _mapHeartRate(Map<String, dynamic> row) {
  return SleepIngestionHeartRateSample(
    recordId: row['recordId'] as String,
    sessionRecordId: row['sessionRecordId'] as String,
    sampledAtUtc: DateTime.parse(row['sampledAtUtcIso'] as String).toUtc(),
    bpm: (row['bpm'] as num).toDouble(),
    sourcePlatform: (row['sourcePlatform'] as String?) ?? 'unknown',
    sourceAppId: row['sourceAppId'] as String?,
    sourceDevice: row['sourceDevice'] as String?,
    sourceRecordHash: row['sourceRecordHash'] as String?,
    sourceConfidence: row['sourceConfidence'] as String?,
  );
}
