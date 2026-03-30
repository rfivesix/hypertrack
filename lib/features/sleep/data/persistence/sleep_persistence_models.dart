class SleepRawImportRecord {
  const SleepRawImportRecord({
    required this.id,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceConfidence,
    required this.sourceRecordHash,
    required this.importStatus,
    this.errorCode,
    this.errorMessage,
    required this.importedAt,
    required this.payloadJson,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceConfidence;
  final String sourceRecordHash;
  final String importStatus;
  final String? errorCode;
  final String? errorMessage;
  final DateTime importedAt;
  final String payloadJson;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class SleepRawImportCompanion {
  const SleepRawImportCompanion({
    required this.id,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceConfidence,
    required this.sourceRecordHash,
    required this.importStatus,
    this.errorCode,
    this.errorMessage,
    required this.importedAt,
    required this.payloadJson,
  });

  final String id;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceConfidence;
  final String sourceRecordHash;
  final String importStatus;
  final String? errorCode;
  final String? errorMessage;
  final DateTime importedAt;
  final String payloadJson;
}

class SleepCanonicalSessionRecord {
  const SleepCanonicalSessionRecord({
    required this.id,
    this.rawImportId,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceConfidence,
    required this.sourceRecordHash,
    required this.normalizationVersion,
    required this.sessionType,
    required this.startedAt,
    required this.endedAt,
    this.timezone,
    required this.importedAt,
    required this.normalizedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? rawImportId;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceConfidence;
  final String sourceRecordHash;
  final String normalizationVersion;
  final String sessionType;
  final DateTime startedAt;
  final DateTime endedAt;
  final String? timezone;
  final DateTime importedAt;
  final DateTime normalizedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class SleepCanonicalSessionCompanion {
  const SleepCanonicalSessionCompanion({
    required this.id,
    this.rawImportId,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceConfidence,
    required this.sourceRecordHash,
    required this.normalizationVersion,
    required this.sessionType,
    required this.startedAt,
    required this.endedAt,
    this.timezone,
    required this.importedAt,
    required this.normalizedAt,
  });

  final String id;
  final String? rawImportId;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceConfidence;
  final String sourceRecordHash;
  final String normalizationVersion;
  final String sessionType;
  final DateTime startedAt;
  final DateTime endedAt;
  final String? timezone;
  final DateTime importedAt;
  final DateTime normalizedAt;
}

class SleepCanonicalStageSegmentRecord {
  const SleepCanonicalStageSegmentRecord({
    required this.id,
    required this.sessionId,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceConfidence,
    required this.sourceRecordHash,
    required this.normalizationVersion,
    required this.stage,
    required this.startedAt,
    required this.endedAt,
    required this.importedAt,
    required this.normalizedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceConfidence;
  final String sourceRecordHash;
  final String normalizationVersion;
  final String stage;
  final DateTime startedAt;
  final DateTime endedAt;
  final DateTime importedAt;
  final DateTime normalizedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class SleepCanonicalStageSegmentCompanion {
  const SleepCanonicalStageSegmentCompanion({
    required this.id,
    required this.sessionId,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceConfidence,
    required this.sourceRecordHash,
    required this.normalizationVersion,
    required this.stage,
    required this.startedAt,
    required this.endedAt,
    required this.importedAt,
    required this.normalizedAt,
  });

  final String id;
  final String sessionId;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceConfidence;
  final String sourceRecordHash;
  final String normalizationVersion;
  final String stage;
  final DateTime startedAt;
  final DateTime endedAt;
  final DateTime importedAt;
  final DateTime normalizedAt;
}

class SleepCanonicalHeartRateSampleRecord {
  const SleepCanonicalHeartRateSampleRecord({
    required this.id,
    required this.sessionId,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceConfidence,
    required this.sourceRecordHash,
    required this.normalizationVersion,
    required this.sampledAt,
    required this.bpm,
    required this.importedAt,
    required this.normalizedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceConfidence;
  final String sourceRecordHash;
  final String normalizationVersion;
  final DateTime sampledAt;
  final double bpm;
  final DateTime importedAt;
  final DateTime normalizedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class SleepCanonicalHeartRateSampleCompanion {
  const SleepCanonicalHeartRateSampleCompanion({
    required this.id,
    required this.sessionId,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceConfidence,
    required this.sourceRecordHash,
    required this.normalizationVersion,
    required this.sampledAt,
    required this.bpm,
    required this.importedAt,
    required this.normalizedAt,
  });

  final String id;
  final String sessionId;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceConfidence;
  final String sourceRecordHash;
  final String normalizationVersion;
  final DateTime sampledAt;
  final double bpm;
  final DateTime importedAt;
  final DateTime normalizedAt;
}

class SleepNightlyAnalysisRecord {
  const SleepNightlyAnalysisRecord({
    required this.id,
    required this.sessionId,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceConfidence,
    required this.sourceRecordHash,
    required this.normalizationVersion,
    required this.analysisVersion,
    required this.nightDate,
    this.score,
    this.totalSleepMinutes,
    this.sleepEfficiencyPct,
    this.restingHeartRateBpm,
    required this.analyzedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceConfidence;
  final String sourceRecordHash;
  final String normalizationVersion;
  final String analysisVersion;
  final String nightDate;
  final double? score;
  final int? totalSleepMinutes;
  final double? sleepEfficiencyPct;
  final double? restingHeartRateBpm;
  final DateTime analyzedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class SleepNightlyAnalysisCompanion {
  const SleepNightlyAnalysisCompanion({
    required this.id,
    required this.sessionId,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceConfidence,
    required this.sourceRecordHash,
    required this.normalizationVersion,
    required this.analysisVersion,
    required this.nightDate,
    this.score,
    this.totalSleepMinutes,
    this.sleepEfficiencyPct,
    this.restingHeartRateBpm,
    required this.analyzedAt,
  });

  final String id;
  final String sessionId;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceConfidence;
  final String sourceRecordHash;
  final String normalizationVersion;
  final String analysisVersion;
  final String nightDate;
  final double? score;
  final int? totalSleepMinutes;
  final double? sleepEfficiencyPct;
  final double? restingHeartRateBpm;
  final DateTime analyzedAt;
}
