import 'contracts/health_export_adapter.dart';
import 'data/health_export_data_source.dart';
import 'data/health_export_status_store.dart';
import 'models/export_models.dart';

class HealthExportResult {
  const HealthExportResult({
    required this.platform,
    required this.success,
    this.message,
  });

  final HealthExportPlatform platform;
  final bool success;
  final String? message;
}

class HealthExportService {
  HealthExportService({
    required List<HealthExportAdapter> adapters,
    HealthExportDataSource? dataSource,
    HealthExportStatusStore? statusStore,
  })  : _adapters = {for (final adapter in adapters) adapter.platform: adapter},
        _dataSource = dataSource ?? HealthExportDataSource(),
        _statusStore = statusStore ?? HealthExportStatusStore();

  final Map<HealthExportPlatform, HealthExportAdapter> _adapters;
  final HealthExportDataSource _dataSource;
  final HealthExportStatusStore _statusStore;

  Future<void> setPlatformEnabled(
    HealthExportPlatform platform,
    bool enabled,
  ) async {
    await _statusStore.setPlatformEnabled(platform, enabled);
    for (final domain in HealthExportDomain.values) {
      await _statusStore.markDomainState(
        platform: platform,
        domain: domain,
        state: enabled ? HealthExportState.idle : HealthExportState.disabled,
        lastError: null,
      );
    }
  }

  Future<bool> isPlatformEnabled(HealthExportPlatform platform) {
    return _statusStore.isPlatformEnabled(platform);
  }

  Future<Map<HealthExportPlatform, HealthExportPlatformStatus>> getStatuses() {
    return _statusStore.readStatuses();
  }

  Future<HealthExportResult> requestPermissions(HealthExportPlatform platform) async {
    final adapter = _adapters[platform];
    if (adapter == null) {
      return HealthExportResult(
        platform: platform,
        success: false,
        message: 'Adapter unavailable',
      );
    }

    final availability = await adapter.getAvailability();
    if (availability != HealthExportAvailability.available) {
      await setPlatformEnabled(platform, false);
      return HealthExportResult(
        platform: platform,
        success: false,
        message: availability == HealthExportAvailability.notInstalled
            ? 'Platform not installed'
            : 'Platform unavailable',
      );
    }

    final granted = await adapter.requestPermissions();
    if (!granted) {
      await setPlatformEnabled(platform, false);
      return HealthExportResult(
        platform: platform,
        success: false,
        message: 'Permission denied',
      );
    }

    await setPlatformEnabled(platform, true);
    return HealthExportResult(platform: platform, success: true);
  }

  Future<HealthExportResult> exportNow(
    HealthExportPlatform platform, {
    int lookbackDays = 30,
  }) async {
    final adapter = _adapters[platform];
    if (adapter == null) {
      return HealthExportResult(
        platform: platform,
        success: false,
        message: 'Adapter unavailable',
      );
    }

    final enabled = await _statusStore.isPlatformEnabled(platform);
    if (!enabled) {
      return HealthExportResult(
        platform: platform,
        success: false,
        message: 'Export disabled',
      );
    }

    final availability = await adapter.getAvailability();
    if (availability != HealthExportAvailability.available) {
      await setPlatformEnabled(platform, false);
      return HealthExportResult(
        platform: platform,
        success: false,
        message: availability == HealthExportAvailability.notInstalled
            ? 'Platform not installed'
            : 'Platform unavailable',
      );
    }

    final payload = await _dataSource.loadPayload(lookbackDays: lookbackDays);

    final domainOutcomes = <HealthExportDomain, bool>{};

    domainOutcomes[HealthExportDomain.measurements] = await _exportDomain(
      platform: platform,
      domain: HealthExportDomain.measurements,
      keys: payload.measurements.map((record) => record.idempotencyKey),
      writer: (alreadyExported) async {
        final pending = payload.measurements
            .where((record) => !alreadyExported.contains(record.idempotencyKey))
            .toList(growable: false);
        for (final record in pending) {
          await adapter.writeMeasurement(record);
        }
        await _statusStore.markExported(
          platform: platform,
          domain: HealthExportDomain.measurements,
          idempotencyKeys: pending.map((record) => record.idempotencyKey),
        );
      },
    );

    domainOutcomes[HealthExportDomain.nutritionHydration] = await _exportDomain(
      platform: platform,
      domain: HealthExportDomain.nutritionHydration,
      keys: [
        ...payload.nutrition.map((record) => record.idempotencyKey),
        ...payload.hydration.map((record) => record.idempotencyKey),
      ],
      writer: (alreadyExported) async {
        final pendingNutrition = payload.nutrition
            .where((record) => !alreadyExported.contains(record.idempotencyKey))
            .toList(growable: false);
        final pendingHydration = payload.hydration
            .where((record) => !alreadyExported.contains(record.idempotencyKey))
            .toList(growable: false);

        for (final record in pendingNutrition) {
          await adapter.writeNutrition(record);
        }
        for (final record in pendingHydration) {
          await adapter.writeHydration(record);
        }

        await _statusStore.markExported(
          platform: platform,
          domain: HealthExportDomain.nutritionHydration,
          idempotencyKeys: [
            ...pendingNutrition.map((record) => record.idempotencyKey),
            ...pendingHydration.map((record) => record.idempotencyKey),
          ],
        );
      },
    );

    domainOutcomes[HealthExportDomain.workouts] = await _exportDomain(
      platform: platform,
      domain: HealthExportDomain.workouts,
      keys: payload.workouts.map((record) => record.idempotencyKey),
      writer: (alreadyExported) async {
        final pending = payload.workouts
            .where((record) => !alreadyExported.contains(record.idempotencyKey))
            .toList(growable: false);
        for (final record in pending) {
          await adapter.writeWorkout(record);
        }
        await _statusStore.markExported(
          platform: platform,
          domain: HealthExportDomain.workouts,
          idempotencyKeys: pending.map((record) => record.idempotencyKey),
        );
      },
    );

    final success = domainOutcomes.values.every((value) => value);
    return HealthExportResult(
      platform: platform,
      success: success,
      message: success ? null : 'One or more domains failed',
    );
  }

  Future<bool> _exportDomain({
    required HealthExportPlatform platform,
    required HealthExportDomain domain,
    required Iterable<String> keys,
    required Future<void> Function(Set<String> alreadyExported) writer,
  }) async {
    try {
      await _statusStore.markDomainState(
        platform: platform,
        domain: domain,
        state: HealthExportState.exporting,
        lastError: null,
      );
      final allKeys = keys.toList(growable: false);
      final alreadyExported = await _statusStore.getAlreadyExported(
        platform: platform,
        domain: domain,
        idempotencyKeys: allKeys,
      );
      await writer(alreadyExported);
      await _statusStore.markDomainState(
        platform: platform,
        domain: domain,
        state: HealthExportState.success,
        lastError: null,
        lastSuccessUtc: DateTime.now().toUtc(),
      );
      return true;
    } catch (error) {
      await _statusStore.markDomainState(
        platform: platform,
        domain: domain,
        state: HealthExportState.failed,
        lastError: error.toString(),
      );
      return false;
    }
  }
}
