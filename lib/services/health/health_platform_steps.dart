import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'health_models.dart';

class HealthPlatformSteps {
  static const MethodChannel _channel = MethodChannel('hypertrack.health/steps');

  const HealthPlatformSteps();

  Future<StepsAvailability> getAvailability() async {
    try {
      final available = await _channel.invokeMethod<bool>('getAvailability');
      return available == true
          ? StepsAvailability.available
          : StepsAvailability.notAvailable;
    } on PlatformException catch (e) {
      if (e.code == 'not_available') {
        return StepsAvailability.notAvailable;
      }
      rethrow;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermissions');
      return granted == true;
    } on PlatformException catch (e) {
      if (e.code == 'permission_denied') return false;
      if (e.code == 'not_available') return false;
      rethrow;
    }
  }

  Future<List<HealthStepSegmentDto>> readStepSegments({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final response = await _channel.invokeMethod<List<dynamic>>(
      'readStepSegments',
      <String, dynamic>{
        'fromUtcIso': fromUtc.toUtc().toIso8601String(),
        'toUtcIso': toUtc.toUtc().toIso8601String(),
      },
    );
    final rows = response ?? const <dynamic>[];
    return rows
        .map((row) => HealthStepSegmentDto.fromMap(row as Map<dynamic, dynamic>))
        .where((segment) => segment.stepCount > 0)
        .toList();
  }

  static String providerForPlatform() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'apple_healthkit';
    }
    return 'google_health_connect';
  }
}

