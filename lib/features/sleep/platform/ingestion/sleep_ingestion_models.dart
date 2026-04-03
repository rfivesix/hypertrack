/// Platform-agnostic raw ingestion payload for one import window.
class SleepRawIngestionBatch {
  const SleepRawIngestionBatch({
    required this.sessions,
    required this.stageSegments,
    required this.heartRateSamples,
  });

  final List<SleepIngestionSession> sessions;
  final List<SleepIngestionStageSegment> stageSegments;
  final List<SleepIngestionHeartRateSample> heartRateSamples;
}

class SleepIngestionSession {
  const SleepIngestionSession({
    required this.recordId,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.platformSessionType,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceDevice,
    this.sourceRecordHash,
    this.sourceConfidence,
  });

  final String recordId;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final String platformSessionType;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceDevice;
  final String? sourceRecordHash;
  final String? sourceConfidence;
}

class SleepIngestionStageSegment {
  const SleepIngestionStageSegment({
    required this.recordId,
    required this.sessionRecordId,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.platformStage,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceDevice,
    this.sourceRecordHash,
    this.sourceConfidence,
  });

  final String recordId;
  final String sessionRecordId;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final String platformStage;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceDevice;
  final String? sourceRecordHash;
  final String? sourceConfidence;
}

class SleepIngestionHeartRateSample {
  const SleepIngestionHeartRateSample({
    required this.recordId,
    required this.sessionRecordId,
    required this.sampledAtUtc,
    required this.bpm,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceDevice,
    this.sourceRecordHash,
    this.sourceConfidence,
  });

  final String recordId;
  final String sessionRecordId;
  final DateTime sampledAtUtc;
  final double bpm;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceDevice;
  final String? sourceRecordHash;
  final String? sourceConfidence;
}
