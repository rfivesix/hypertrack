import 'package:flutter/services.dart';

class AppleHealthExportPlatform {
  const AppleHealthExportPlatform();

  static const MethodChannel _channel = MethodChannel(
    'hypertrack.health/export_apple_health',
  );

  Future<bool> isAvailable() async {
    final available = await _channel.invokeMethod<bool>('getAvailability');
    return available == true;
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
