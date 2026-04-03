import '../../domain/sleep_domain.dart';
import '../../platform/ingestion/sleep_ingestion_models.dart';

class HealthConnectCanonicalMappingResult {
  const HealthConnectCanonicalMappingResult({
    required this.sessions,
    required this.stageSegments,
    required this.heartRateSamples,
  });

  final List<SleepSession> sessions;
  final List<SleepStageSegment> stageSegments;
  final List<HeartRateSample> heartRateSamples;
}

class HealthConnectMapper {
  const HealthConnectMapper();

  HealthConnectCanonicalMappingResult map(SleepRawIngestionBatch batch) {
    final sessionIds = batch.sessions.map((s) => s.recordId).toSet();

    final sessions = batch.sessions
        .map(
          (session) => SleepSession(
            id: session.recordId,
            startAtUtc: session.startAtUtc,
            endAtUtc: session.endAtUtc,
            // Session typing is intentionally deferred to normalization
            // (winner-selection + night classification), so ingestion mapping
            // stays deterministic and source-faithful in this batch.
            sessionType: SleepSessionType.unknown,
            sourcePlatform: session.sourcePlatform,
            sourceAppId: session.sourceAppId,
            sourceRecordHash: session.sourceRecordHash,
            sourceConfidence: session.sourceConfidence,
          ),
        )
        .toList(growable: false);

    final stageSegments = batch.stageSegments
        .where((segment) => sessionIds.contains(segment.sessionRecordId))
        .map(
          (segment) => SleepStageSegment(
            id: segment.recordId,
            sessionId: segment.sessionRecordId,
            stage: _mapStage(segment.platformStage),
            startAtUtc: segment.startAtUtc,
            endAtUtc: segment.endAtUtc,
            sourcePlatform: segment.sourcePlatform,
            sourceAppId: segment.sourceAppId,
            sourceRecordHash: segment.sourceRecordHash,
            sourceConfidence: segment.sourceConfidence,
          ),
        )
        .toList(growable: false);

    final heartRates = batch.heartRateSamples
        .where((sample) => sessionIds.contains(sample.sessionRecordId))
        .map(
          (sample) => HeartRateSample(
            id: sample.recordId,
            sessionId: sample.sessionRecordId,
            sampledAtUtc: sample.sampledAtUtc,
            bpm: sample.bpm,
            sourcePlatform: sample.sourcePlatform,
            sourceAppId: sample.sourceAppId,
            sourceRecordHash: sample.sourceRecordHash,
            sourceConfidence: sample.sourceConfidence,
          ),
        )
        .toList(growable: false);

    return HealthConnectCanonicalMappingResult(
      sessions: sessions,
      stageSegments: stageSegments,
      heartRateSamples: heartRates,
    );
  }

  CanonicalSleepStage _mapStage(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'awake':
      case 'awake_in_bed':
      case 'awake in bed':
        return CanonicalSleepStage.awake;
      case 'light':
        return CanonicalSleepStage.light;
      case 'deep':
        return CanonicalSleepStage.deep;
      case 'rem':
        return CanonicalSleepStage.rem;
      case 'asleep':
      case 'asleep_unspecified':
        return CanonicalSleepStage.asleepUnspecified;
      case 'out_of_bed':
      case 'outofbed':
      case 'out of bed':
        return CanonicalSleepStage.outOfBed;
      default:
        return CanonicalSleepStage.unknown;
    }
  }
}
