import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database_helper.dart';
import 'health_models.dart';
import 'health_platform_steps.dart';

class StepsSyncService {
  static const String trackingEnabledKey = 'steps_tracking_enabled';
  static const String providerFilterKey = 'steps_provider_filter';
  static const String lastSyncAtIsoKey = 'steps_last_sync_at_iso';

  static const Duration _overlap = Duration(hours: 48);
  static const Duration _initialLookback = Duration(days: 30);

  final HealthPlatformSteps _platform;
  final DatabaseHelper _dbHelper;

  StepsSyncService({
    HealthPlatformSteps? platform,
    DatabaseHelper? dbHelper,
  })  : _platform = platform ?? const HealthPlatformSteps(),
        _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<bool> isTrackingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(trackingEnabledKey) ?? true;
  }

  Future<void> setTrackingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(trackingEnabledKey, enabled);
  }

  Future<StepsProviderFilter> getProviderFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(providerFilterKey) ?? 'all';
    switch (value) {
      case 'apple':
        return StepsProviderFilter.apple;
      case 'google':
        return StepsProviderFilter.google;
      default:
        return StepsProviderFilter.all;
    }
  }

  Future<void> setProviderFilter(StepsProviderFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = switch (filter) {
      StepsProviderFilter.all => 'all',
      StepsProviderFilter.apple => 'apple',
      StepsProviderFilter.google => 'google',
    };
    await prefs.setString(providerFilterKey, raw);
  }

  Future<DateTime?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(lastSyncAtIsoKey);
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso)?.toUtc();
  }

  Future<void> _setLastSyncAt(DateTime valueUtc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastSyncAtIsoKey, valueUtc.toUtc().toIso8601String());
  }

  Future<StepsAvailability> getAvailability() => _platform.getAvailability();

  Future<bool> requestPermissions() => _platform.requestPermissions();

  Future<StepsSyncResult> sync({DateTime? now}) async {
    final enabled = await isTrackingEnabled();
    if (!enabled) {
      return const StepsSyncResult(skipped: true, fetchedCount: 0, upsertedCount: 0);
    }

    final availability = await _platform.getAvailability();
    if (availability == StepsAvailability.notAvailable) {
      return const StepsSyncResult(skipped: true, fetchedCount: 0, upsertedCount: 0);
    }

    final granted = await _platform.requestPermissions();
    if (!granted) {
      return const StepsSyncResult(skipped: true, fetchedCount: 0, upsertedCount: 0);
    }

    final nowUtc = (now ?? DateTime.now()).toUtc();
    final lastSync = await getLastSyncAt();
    final fromUtc = (lastSync == null)
        ? nowUtc.subtract(_initialLookback)
        : lastSync.subtract(_overlap);

    final provider = HealthPlatformSteps.providerForPlatform();
    final segments = await _platform.readStepSegments(fromUtc: fromUtc, toUtc: nowUtc);
    final rows = segments.map((segment) {
      final source = segment.sourceId ?? '';
      final fallback = sha1
          .convert(
            utf8.encode(
              '$source|${segment.startAtUtc.toIso8601String()}|${segment.endAtUtc.toIso8601String()}|${segment.stepCount}',
            ),
          )
          .toString();
      final externalKey = segment.nativeId != null && segment.nativeId!.isNotEmpty
          ? '$provider:${segment.nativeId}'
          : '$provider:$fallback';
      return <String, dynamic>{
        'provider': provider,
        'sourceId': segment.sourceId,
        'startAt': segment.startAtUtc.toIso8601String(),
        'endAt': segment.endAtUtc.toIso8601String(),
        'stepCount': segment.stepCount,
        'externalKey': externalKey,
      };
    }).toList();

    await _dbHelper.upsertHealthStepSegments(rows);
    await _setLastSyncAt(nowUtc);

    return StepsSyncResult(
      skipped: false,
      fetchedCount: segments.length,
      upsertedCount: rows.length,
    );
  }
}
