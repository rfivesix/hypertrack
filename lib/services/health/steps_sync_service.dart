import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database_helper.dart';
import 'health_models.dart';
import 'health_platform_steps.dart';

class StepsSyncService {
  static const int defaultStepsGoal = 8000;
  static const String trackingEnabledKey = 'steps_tracking_enabled';
  static const String providerFilterKey = 'steps_provider_filter';
  static const String sourcePolicyKey = 'steps_source_policy';
  static const String lastSyncAtIsoKey = 'steps_last_sync_at_iso';

  static const Duration _overlap = Duration(hours: 48);
  static const Duration _initialLookback = Duration(days: 30);

  final HealthPlatformSteps _platform;
  final DatabaseHelper _dbHelper;

  StepsSyncService({HealthPlatformSteps? platform, DatabaseHelper? dbHelper})
      : _platform = platform ?? const HealthPlatformSteps(),
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
    return providerFilterFromRaw(value);
  }

  Future<void> setProviderFilter(StepsProviderFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = providerFilterToRaw(filter);
    await prefs.setString(providerFilterKey, raw);
  }

  Future<StepsSourcePolicy> getSourcePolicy() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(sourcePolicyKey) ?? 'auto_dominant';
    return sourcePolicyFromRaw(raw);
  }

  Future<void> setSourcePolicy(StepsSourcePolicy policy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(sourcePolicyKey, sourcePolicyToRaw(policy));
  }

  static StepsProviderFilter providerFilterFromRaw(String raw) {
    switch (raw) {
      case 'apple':
        return StepsProviderFilter.apple;
      case 'google':
        return StepsProviderFilter.google;
      default:
        return StepsProviderFilter.all;
    }
  }

  static String providerFilterToRaw(StepsProviderFilter filter) {
    return switch (filter) {
      StepsProviderFilter.all => 'all',
      StepsProviderFilter.apple => 'apple',
      StepsProviderFilter.google => 'google',
    };
  }

  static StepsSourcePolicy sourcePolicyFromRaw(String raw) {
    switch (raw) {
      case 'max_per_hour':
        return StepsSourcePolicy.maxPerHour;
      default:
        return StepsSourcePolicy.autoDominant;
    }
  }

  static String sourcePolicyToRaw(StepsSourcePolicy policy) {
    return switch (policy) {
      StepsSourcePolicy.autoDominant => 'auto_dominant',
      StepsSourcePolicy.maxPerHour => 'max_per_hour',
    };
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

  Future<void> clearLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(lastSyncAtIsoKey);
  }

  Future<StepsAvailability> getAvailability() => _platform.getAvailability();

  Future<bool> requestPermissions() => _platform.requestPermissions();

  Future<StepsSyncResult> sync(
      {DateTime? now, bool forceRefresh = false}) async {
    final enabled = await isTrackingEnabled();
    if (!enabled) {
      return const StepsSyncResult(
        skipped: true,
        fetchedCount: 0,
        upsertedCount: 0,
      );
    }

    final availability = await _platform.getAvailability();
    if (availability == StepsAvailability.notAvailable) {
      return const StepsSyncResult(
        skipped: true,
        fetchedCount: 0,
        upsertedCount: 0,
      );
    }

    // Issue 3 Fix: Don't request permissions on every sync.
    // Permissions are requested once when the user enables tracking (in SettingsScreen).
    // If permissions are missing, readStepSegments will throw and we skip gracefully.

    final nowUtc = (now ?? DateTime.now()).toUtc();
    final lastSync = await getLastSyncAt();
    final fromUtc = _resolveSyncWindowStart(
      forceRefresh: forceRefresh,
      nowUtc: nowUtc,
      lastSync: lastSync,
    );
    if (kDebugMode) {
      debugPrint(
        '[StepsSync] sync start force=$forceRefresh from=${fromUtc.toIso8601String()} to=${nowUtc.toIso8601String()} lastSync=${lastSync?.toIso8601String()}',
      );
    }

    final provider = HealthPlatformSteps.providerForPlatform();

    // Gracefully handle missing permissions – don't crash, just skip.
    final List<HealthStepSegmentDto> segments;
    try {
      segments = await _platform.readStepSegments(
        fromUtc: fromUtc,
        toUtc: nowUtc,
      );
    } on PlatformException catch (e) {
      if (e.code == 'permission_denied' || e.code == 'not_available') {
        return const StepsSyncResult(
          skipped: true,
          fetchedCount: 0,
          upsertedCount: 0,
        );
      }
      rethrow;
    }

    final rows = segments.map((segment) {
      final source = segment.sourceId ?? '';
      final fallback = sha1
          .convert(
            utf8.encode(
              [
                source,
                segment.startAtUtc.toIso8601String(),
                segment.endAtUtc.toIso8601String(),
                segment.stepCount.toString(),
              ].join('\u0000'),
            ),
          )
          .toString();
      final externalKey =
          segment.nativeId != null && segment.nativeId!.isNotEmpty
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

    await _dbHelper.deleteHealthStepSegmentsInRange(
      provider: provider,
      fromUtc: fromUtc,
      toUtc: nowUtc,
    );
    await _dbHelper.upsertHealthStepSegments(rows);
    await _setLastSyncAt(nowUtc);
    if (kDebugMode) {
      final sourceTotals = await _dbHelper.getDailyStepsTotalsBySource(
        dayLocal: nowUtc.toLocal(),
      );
      final sourceDebug = sourceTotals
          .map((row) => '${row['sourceId']}:${row['totalSteps']}')
          .join(', ');
      debugPrint(
        '[StepsSync] sync done fetched=${segments.length} upserted=${rows.length} todaySources=[$sourceDebug]',
      );
    }

    return StepsSyncResult(
      skipped: false,
      fetchedCount: segments.length,
      upsertedCount: rows.length,
    );
  }

  DateTime _resolveSyncWindowStart({
    required bool forceRefresh,
    required DateTime nowUtc,
    required DateTime? lastSync,
  }) {
    if (forceRefresh || lastSync == null) {
      return nowUtc.subtract(_initialLookback);
    }
    return lastSync.subtract(_overlap);
  }
}
