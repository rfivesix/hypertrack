import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/health/health_platform_heart_rate.dart';

abstract class PulseTrackingSettingsService {
  Future<bool> isTrackingEnabled();
  Future<void> setTrackingEnabled(bool enabled);
  Future<bool> requestPermissions();
}

class PulseTrackingService implements PulseTrackingSettingsService {
  PulseTrackingService({
    HealthPlatformHeartRate? platform,
  }) : _platform = platform ?? const HealthPlatformHeartRate();

  static const String trackingEnabledKey = 'pulse_tracking_enabled';
  static final ValueNotifier<bool?> trackingEnabledListenable =
      ValueNotifier<bool?>(null);

  final HealthPlatformHeartRate _platform;

  @override
  Future<bool> isTrackingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(trackingEnabledKey) ?? false;
    if (trackingEnabledListenable.value != enabled) {
      trackingEnabledListenable.value = enabled;
    }
    return enabled;
  }

  @override
  Future<void> setTrackingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(trackingEnabledKey, enabled);
    if (trackingEnabledListenable.value != enabled) {
      trackingEnabledListenable.value = enabled;
    }
  }

  @override
  Future<bool> requestPermissions() => _platform.requestPermissions();
}
