import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database_helper.dart';
import '../models/export_models.dart';

class HealthExportStatusStore {
  static const String _statusKey = 'health_export_status_v1';
  static const String _appleEnabledKey = 'health_export_apple_enabled';
  static const String _healthConnectEnabledKey =
      'health_export_health_connect_enabled';

  HealthExportStatusStore({DatabaseHelper? databaseHelper})
      : _dbHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<bool> isPlatformEnabled(HealthExportPlatform platform) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey(platform)) ?? false;
  }

  Future<void> setPlatformEnabled(
    HealthExportPlatform platform,
    bool enabled,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey(platform), enabled);
  }

  Future<Map<HealthExportPlatform, HealthExportPlatformStatus>>
      readStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statusKey);
    return decodePlatformStatusMap(raw);
  }

  Future<void> writeStatuses(
    Map<HealthExportPlatform, HealthExportPlatformStatus> statuses,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, encodePlatformStatusMap(statuses));
  }

  Future<void> markDomainState({
    required HealthExportPlatform platform,
    required HealthExportDomain domain,
    required HealthExportState state,
    String? lastError,
    DateTime? lastSuccessUtc,
  }) async {
    final statuses = await readStatuses();
    final current =
        statuses[platform] ?? HealthExportPlatformStatus.initial(platform);
    final byDomain = Map<HealthExportDomain, HealthExportDomainStatus>.from(
      current.byDomain,
    );
    final previous = byDomain[domain] ?? HealthExportDomainStatus.idle();
    byDomain[domain] = HealthExportDomainStatus(
      state: state,
      lastError: lastError,
      lastSuccessfulExportAtUtc:
          lastSuccessUtc ?? previous.lastSuccessfulExportAtUtc,
    );
    statuses[platform] = HealthExportPlatformStatus(
      platform: platform,
      byDomain: byDomain,
    );
    await writeStatuses(statuses);
  }

  Future<void> markExported({
    required HealthExportPlatform platform,
    required HealthExportDomain domain,
    required Iterable<String> idempotencyKeys,
  }) {
    return _dbHelper.markHealthExported(
      platform: platform.name,
      domain: domain.name,
      idempotencyKeys: idempotencyKeys.toList(growable: false),
    );
  }

  Future<Set<String>> getAlreadyExported({
    required HealthExportPlatform platform,
    required HealthExportDomain domain,
    required Iterable<String> idempotencyKeys,
  }) async {
    final rows = await _dbHelper.getExportedHealthKeys(
      platform: platform.name,
      domain: domain.name,
      idempotencyKeys: idempotencyKeys.toList(growable: false),
    );
    return rows.toSet();
  }

  String _enabledKey(HealthExportPlatform platform) {
    return platform == HealthExportPlatform.appleHealth
        ? _appleEnabledKey
        : _healthConnectEnabledKey;
  }
}
