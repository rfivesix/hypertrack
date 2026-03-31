/// Platform-agnostic query window used by ingestion adapters.
class SleepImportWindow {
  const SleepImportWindow({
    required this.fromUtc,
    required this.toUtc,
    this.cursor,
    this.limit = 200,
  });

  final DateTime fromUtc;
  final DateTime toUtc;
  final String? cursor;
  final int limit;
}

class SleepIngestionProvenance {
  const SleepIngestionProvenance({
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceDevice,
    this.sourceOrigin,
    this.sourceConfidence,
    this.sourceRecordHash,
  });

  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceDevice;
  final String? sourceOrigin;
  final String? sourceConfidence;
  final String? sourceRecordHash;
}

class SleepRawIngestionSessionRecord {
  const SleepRawIngestionSessionRecord({
    required this.recordId,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.platformSessionType,
    required this.provenance,
  });

  final String recordId;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final String platformSessionType;
  final SleepIngestionProvenance provenance;
}

class SleepRawIngestionStageRecord {
  const SleepRawIngestionStageRecord({
    required this.recordId,
    required this.sessionRecordId,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.platformStage,
    required this.provenance,
  });

  final String recordId;
  final String sessionRecordId;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final String platformStage;
  final SleepIngestionProvenance provenance;
}

class SleepRawIngestionHeartRateRecord {
  const SleepRawIngestionHeartRateRecord({
    required this.recordId,
    required this.sessionRecordId,
    required this.sampledAtUtc,
    required this.bpm,
    required this.provenance,
  });

  final String recordId;
  final String sessionRecordId;
  final DateTime sampledAtUtc;
  final double bpm;
  final SleepIngestionProvenance provenance;
}

class SleepIngestionPage<T> {
  const SleepIngestionPage({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
}

enum SleepIngestionErrorKind {
  permissionDenied,
  sourceUnavailable,
  sourceNotInstalled,
  throttled,
  malformedPayload,
  unknown,
}

class SleepIngestionError {
  const SleepIngestionError({
    required this.kind,
    required this.message,
    this.details,
  });

  final SleepIngestionErrorKind kind;
  final String message;
  final String? details;
}

enum SleepImportStatusKind { success, partial, failed }

class SleepImportStatus {
  const SleepImportStatus({
    required this.kind,
    this.error,
    required this.processedCount,
  });

  final SleepImportStatusKind kind;
  final SleepIngestionError? error;
  final int processedCount;
}

abstract class SleepRawIngestionSource {
  Future<SleepIngestionPage<SleepRawIngestionSessionRecord>> fetchSessions(
    SleepImportWindow window,
  );

  Future<SleepIngestionPage<SleepRawIngestionStageRecord>> fetchStageSegments(
    SleepImportWindow window,
  );

  Future<SleepIngestionPage<SleepRawIngestionHeartRateRecord>> fetchHeartRates(
    SleepImportWindow window,
  );
}
