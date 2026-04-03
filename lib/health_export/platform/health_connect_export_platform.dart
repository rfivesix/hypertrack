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

  Future<void> writeNutrition(Map<String, dynamic> payload) async {
    await _channel.invokeMethod<void>('writeNutrition', payload);
  }

  Future<void> writeHydration(Map<String, dynamic> payload) async {
    await _channel.invokeMethod<void>('writeHydration', payload);
  }

  Future<void> writeWorkout(Map<String, dynamic> payload) async {
    await _channel.invokeMethod<void>('writeWorkout', payload);
  }
}
