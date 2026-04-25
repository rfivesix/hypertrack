import '../healthkit/healthkit_sleep_adapter.dart';
import '../ingestion/sleep_ingestion_models.dart';
import '../permissions/sleep_permission_models.dart';
import '../permissions/sleep_permissions_service.dart';

abstract class HealthConnectDataSource {
  Future<SleepRawIngestionBatch> readSleepAndHeartRate({
    required DateTime fromUtc,
    required DateTime toUtc,
  });
}

class HealthConnectSleepAdapter {
  const HealthConnectSleepAdapter({
    required SleepPermissionsService permissionsService,
    required HealthConnectDataSource dataSource,
    this.heartRateFallbackPadding = const Duration(hours: 24),
  })  : _permissionsService = permissionsService,
        _dataSource = dataSource;

  final SleepPermissionsService _permissionsService;
  final HealthConnectDataSource _dataSource;
  final Duration heartRateFallbackPadding;

  Future<SleepIngestionResult> importRange({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final permission = await _permissionsService.checkStatus();
    if (permission.state == SleepPermissionState.notInstalled) {
      return const SleepIngestionResult.failure(
        SleepIngestionFailure(SleepPlatformServiceError.notInstalled),
      );
    }
    if (permission.state == SleepPermissionState.unavailable) {
      return const SleepIngestionResult.failure(
        SleepIngestionFailure(SleepPlatformServiceError.unavailable),
      );
    }
    if (permission.state == SleepPermissionState.denied) {
      return const SleepIngestionResult.failure(
        SleepIngestionFailure(SleepPlatformServiceError.permissionDenied),
      );
    }
    if (permission.state == SleepPermissionState.partial) {
      return const SleepIngestionResult.failure(
        SleepIngestionFailure(SleepPlatformServiceError.permissionPartial),
      );
    }
    if (permission.state == SleepPermissionState.technicalError) {
      return SleepIngestionResult.failure(
        SleepIngestionFailure(
          permission.error ?? SleepPlatformServiceError.unknown,
          message: permission.message,
        ),
      );
    }

    try {
      final batch = await _dataSource.readSleepAndHeartRate(
        fromUtc: fromUtc,
        toUtc: toUtc,
      );
      return SleepIngestionResult.success(
        await _withHeartRateFallbackIfNeeded(
          batch: batch,
          fromUtc: fromUtc,
          toUtc: toUtc,
        ),
      );
    } catch (error) {
      return SleepIngestionResult.failure(
        SleepIngestionFailure(
          SleepPlatformServiceError.queryFailed,
          message: error.toString(),
        ),
      );
    }
  }

  Future<SleepRawIngestionBatch> _withHeartRateFallbackIfNeeded({
    required SleepRawIngestionBatch batch,
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    if (batch.sessions.isEmpty ||
        batch.heartRateSamples.isNotEmpty ||
        heartRateFallbackPadding <= Duration.zero) {
      return batch;
    }

    final SleepRawIngestionBatch fallback;
    try {
      fallback = await _dataSource.readSleepAndHeartRate(
        fromUtc: fromUtc.subtract(heartRateFallbackPadding),
        toUtc: toUtc.add(heartRateFallbackPadding),
      );
    } catch (_) {
      return batch;
    }
    final sessionsById = {
      for (final session in batch.sessions) session.recordId: session,
    };
    final strictHeartRates = fallback.heartRateSamples.where((sample) {
      final session = sessionsById[sample.sessionRecordId];
      if (session == null) return false;
      final sampledAt = sample.sampledAtUtc.toUtc();
      return !sampledAt.isBefore(session.startAtUtc.toUtc()) &&
          !sampledAt.isAfter(session.endAtUtc.toUtc());
    }).toList(growable: false);

    final derivedHeartRates = strictHeartRates.isNotEmpty
        ? strictHeartRates
        : _deriveHeartRatesFromSleepWindows(
            samples: fallback.heartRateSamples,
            sessions: batch.sessions,
          );
    if (derivedHeartRates.isEmpty) return batch;
    return SleepRawIngestionBatch(
      sessions: batch.sessions,
      stageSegments: batch.stageSegments,
      heartRateSamples: derivedHeartRates,
    );
  }

  List<SleepIngestionHeartRateSample> _deriveHeartRatesFromSleepWindows({
    required List<SleepIngestionHeartRateSample> samples,
    required List<SleepIngestionSession> sessions,
  }) {
    if (samples.isEmpty || sessions.isEmpty) return const [];
    final sortedSessions = List<SleepIngestionSession>.from(sessions)
      ..sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));
    final resolved = <SleepIngestionHeartRateSample>[];
    for (final sample in samples) {
      final sampledAt = sample.sampledAtUtc.toUtc();
      for (final session in sortedSessions) {
        final startUtc = session.startAtUtc.toUtc();
        final endUtc = session.endAtUtc.toUtc();
        if (sampledAt.isBefore(startUtc)) break;
        final inWindow =
            !sampledAt.isBefore(startUtc) && !sampledAt.isAfter(endUtc);
        if (!inWindow) {
          continue;
        }
        resolved.add(
          SleepIngestionHeartRateSample(
            recordId: sample.recordId,
            sessionRecordId: session.recordId,
            sampledAtUtc: sample.sampledAtUtc,
            bpm: sample.bpm,
            sourcePlatform: sample.sourcePlatform,
            sourceAppId: sample.sourceAppId,
            sourceDevice: sample.sourceDevice,
            sourceRecordHash: sample.sourceRecordHash,
            sourceConfidence: sample.sourceConfidence,
          ),
        );
        break;
      }
    }
    return resolved;
  }
}
