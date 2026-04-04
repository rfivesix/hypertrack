import 'package:flutter/services.dart';

class HealthConnectExportPlatform {
  const HealthConnectExportPlatform();

  static const MethodChannel _channel = MethodChannel(
    'hypertrack.health/export_health_connect',
  );

  Future<String> getAvailability() async {
    final value = await _channel.invokeMethod<String>('getAvailability');
    return (value ?? 'unavailable').toLowerCase();
  }

  Future<bool> requestPermissions() async {
    final granted = await _channel.invokeMethod<bool>('requestPermissions');
    return granted == true;
  }

  Future<void> writeMeasurement(Map<String, dynamic> payload) async {
    await _channel.invokeMethod<void>('writeMeasurement', payload);
  }

  Future<void> writeMeasurementsBatch(
    List<Map<String, dynamic>> payloads,
  ) async {
    await _channel.invokeMethod<void>('writeMeasurementsBatch', {
      'records': payloads,
    });
  }

  Future<void> writeNutrition(Map<String, dynamic> payload) async {
    await _channel.invokeMethod<void>('writeNutrition', payload);
  }

  Future<void> writeNutritionBatch(List<Map<String, dynamic>> payloads) async {
    await _channel.invokeMethod<void>('writeNutritionBatch', {
      'records': payloads,
    });
  }

  Future<void> writeHydration(Map<String, dynamic> payload) async {
    await _channel.invokeMethod<void>('writeHydration', payload);
  }

  Future<void> writeHydrationBatch(List<Map<String, dynamic>> payloads) async {
    await _channel.invokeMethod<void>('writeHydrationBatch', {
      'records': payloads,
    });
  }

  Future<void> writeWorkout(Map<String, dynamic> payload) async {
    await _channel.invokeMethod<void>('writeWorkout', payload);
  }

  Future<void> writeWorkoutsBatch(List<Map<String, dynamic>> payloads) async {
    await _channel.invokeMethod<void>('writeWorkoutsBatch', {
      'records': payloads,
    });
  }
}
