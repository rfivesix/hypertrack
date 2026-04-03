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

class _DomainExportOutcome {
  const _DomainExportOutcome({
    required this.success,
    this.error,
  });

  final bool success;
  final String? error;
}

class HealthExportService {
  static const int maxWriteBatchSize = 1000;

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

  Future<HealthExportResult> requestPermissions(
      HealthExportPlatform platform) async {
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
    int? lookbackDays,
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

    final statuses = await _statusStore.readStatuses();
    final platformStatus =
        statuses[platform] ?? HealthExportPlatformStatus.initial(platform);
    final checkpoints = _domainIncrementalCheckpoints(platformStatus);

    final measurementsPayload = await _dataSource.loadMeasurements(
      options: HealthExportLoadOptions(
        // Per-domain incremental cutoff:
        // null checkpoint => full-history backfill only for this domain.
        lookbackDays: checkpoints[HealthExportDomain.measurements] == null
            ? null
            : lookbackDays,
        updatedSinceUtc: checkpoints[HealthExportDomain.measurements],
      ),
    );
    final nutritionPayload = await _dataSource.loadNutrition(
      options: HealthExportLoadOptions(
        lookbackDays: checkpoints[HealthExportDomain.nutritionHydration] == null
            ? null
            : lookbackDays,
        updatedSinceUtc: checkpoints[HealthExportDomain.nutritionHydration],
      ),
    );
    final hydrationPayload = await _dataSource.loadHydration(
      options: HealthExportLoadOptions(
        lookbackDays: checkpoints[HealthExportDomain.nutritionHydration] == null
            ? null
            : lookbackDays,
        updatedSinceUtc: checkpoints[HealthExportDomain.nutritionHydration],
      ),
    );
    final workoutsPayload = await _dataSource.loadWorkouts(
      options: HealthExportLoadOptions(
        lookbackDays: checkpoints[HealthExportDomain.workouts] == null
            ? null
            : lookbackDays,
        updatedSinceUtc: checkpoints[HealthExportDomain.workouts],
      ),
    );
    final payload = HealthExportPayload(
      measurements: measurementsPayload,
      nutrition: nutritionPayload,
      hydration: hydrationPayload,
      workouts: workoutsPayload,
    );

    final domainOutcomes = <HealthExportDomain, _DomainExportOutcome>{};

    domainOutcomes[HealthExportDomain.measurements] = await _exportDomain(
      platform: platform,
      domain: HealthExportDomain.measurements,
      keys: payload.measurements.map((record) => record.idempotencyKey),
      writer: (alreadyExported) async {
        final pending = payload.measurements
            .where((record) => !alreadyExported.contains(record.idempotencyKey))
            .toList(growable: false);
        final writeable = platform == HealthExportPlatform.healthConnect
            ? pending
                .where((record) => record.type != ExportMeasurementType.bmi)
                .toList(growable: false)
            : pending;
        // Android Health Connect currently does not support BMI in this writer path.
        for (final batch in _chunkRecords(writeable)) {
          await adapter.writeMeasurementsBatch(batch);
          await _statusStore.markExported(
            platform: platform,
            domain: HealthExportDomain.measurements,
            idempotencyKeys: batch.map((record) => record.idempotencyKey),
          );
        }
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

        var nutritionExportedCount = 0;
        var hydrationExportedCount = 0;
        final nutritionChunkExportedKeys = <String>[];
        final hydrationChunkExportedKeys = <String>[];
        final nutritionFailures = <String>[];
        final hydrationFailures = <String>[];

        for (final batch in _chunkRecords(pendingNutrition)) {
          try {
            await adapter.writeNutritionBatch(batch);
            nutritionChunkExportedKeys
                .addAll(batch.map((record) => record.idempotencyKey));
            nutritionExportedCount += batch.length;
          } catch (error) {
            for (final record in batch) {
              try {
                await adapter.writeNutrition(record);
                nutritionChunkExportedKeys.add(record.idempotencyKey);
                nutritionExportedCount += 1;
              } catch (recordError) {
                nutritionFailures.add('${record.idempotencyKey}: $recordError');
              }
            }
          }
          await _statusStore.markExported(
            platform: platform,
            domain: HealthExportDomain.nutritionHydration,
            idempotencyKeys: [
              ...nutritionChunkExportedKeys,
              ...hydrationChunkExportedKeys,
            ],
          );
          nutritionChunkExportedKeys.clear();
          hydrationChunkExportedKeys.clear();
        }
        for (final batch in _chunkRecords(pendingHydration)) {
          try {
            await adapter.writeHydrationBatch(batch);
            hydrationChunkExportedKeys
                .addAll(batch.map((record) => record.idempotencyKey));
            hydrationExportedCount += batch.length;
          } catch (error) {
            for (final record in batch) {
              try {
                await adapter.writeHydration(record);
                hydrationChunkExportedKeys.add(record.idempotencyKey);
                hydrationExportedCount += 1;
              } catch (recordError) {
                hydrationFailures.add('${record.idempotencyKey}: $recordError');
              }
            }
          }
          await _statusStore.markExported(
            platform: platform,
            domain: HealthExportDomain.nutritionHydration,
            idempotencyKeys: [
              ...nutritionChunkExportedKeys,
              ...hydrationChunkExportedKeys,
            ],
          );
          nutritionChunkExportedKeys.clear();
          hydrationChunkExportedKeys.clear();
        }

        if (nutritionFailures.isNotEmpty || hydrationFailures.isNotEmpty) {
          final nutritionSummary = nutritionFailures.isEmpty
              ? 'nutrition=success($nutritionExportedCount/${pendingNutrition.length})'
              : 'nutrition=failed(${pendingNutrition.length - nutritionFailures.length}/${pendingNutrition.length}, first=${nutritionFailures.first})';
          final hydrationSummary = hydrationFailures.isEmpty
              ? 'hydration=success($hydrationExportedCount/${pendingHydration.length})'
              : 'hydration=failed(${pendingHydration.length - hydrationFailures.length}/${pendingHydration.length}, first=${hydrationFailures.first})';
          throw StateError(
            'Nutrition/Hydration export details: $nutritionSummary; $hydrationSummary',
          );
        }
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
        for (final batch in _chunkRecords(pending)) {
          await adapter.writeWorkoutsBatch(batch);
          await _statusStore.markExported(
            platform: platform,
            domain: HealthExportDomain.workouts,
            idempotencyKeys: batch.map((record) => record.idempotencyKey),
          );
        }
      },
    );

    final success = domainOutcomes.values.every((value) => value.success);
    final message = success
        ? null
        : domainOutcomes.entries
            .where((entry) => !entry.value.success)
            .map(
              (entry) =>
                  '${entry.key.name} failed${entry.value.error == null ? '' : ': ${entry.value.error}'}',
            )
            .join(' | ');
    return HealthExportResult(
      platform: platform,
      success: success,
      message: message,
    );
  }

  Future<_DomainExportOutcome> _exportDomain({
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
      return const _DomainExportOutcome(success: true);
    } catch (error) {
      await _statusStore.markDomainState(
        platform: platform,
        domain: domain,
        state: HealthExportState.failed,
        lastError: error.toString(),
      );
      return _DomainExportOutcome(
        success: false,
        error: error.toString(),
      );
    }
  }

  Map<HealthExportDomain, DateTime?> _domainIncrementalCheckpoints(
    HealthExportPlatformStatus status,
  ) {
    // Conservative per-domain checkpointing:
    // each domain advances independently; a failed/missing domain checkpoint
    // only triggers full-history reload for that domain, not all domains.
    final checkpoints = <HealthExportDomain, DateTime?>{};
    for (final domain in HealthExportDomain.values) {
      checkpoints[domain] = status.statusFor(domain).lastSuccessfulExportAtUtc;
    }
    return checkpoints;
  }

  List<List<T>> _chunkRecords<T>(List<T> records) {
    if (records.isEmpty) return <List<T>>[];
    final chunks = <List<T>>[];
    for (var i = 0; i < records.length; i += maxWriteBatchSize) {
      final end = (i + maxWriteBatchSize) > records.length
          ? records.length
          : (i + maxWriteBatchSize);
      chunks.add(records.sublist(i, end));
    }
    return chunks;
  }
}
