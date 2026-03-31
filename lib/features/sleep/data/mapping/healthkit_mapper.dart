import '../../domain/sleep_domain.dart';
import '../../platform/ingestion/sleep_ingestion_models.dart';

class HealthKitCanonicalMappingResult {
  const HealthKitCanonicalMappingResult({
    required this.sessions,
    required this.stageSegments,
    required this.heartRateSamples,
  });

  final List<SleepSession> sessions;
  final List<SleepStageSegment> stageSegments;
  final List<HeartRateSample> heartRateSamples;
}

class HealthKitMapper {
  const HealthKitMapper();

  HealthKitCanonicalMappingResult map(SleepRawIngestionBatch batch) {
    final sessionIds = batch.sessions.map((s) => s.recordId).toSet();

    final sessions = batch.sessions
        .map(
          (session) => SleepSession(
            id: session.recordId,
            startAtUtc: session.startAtUtc,
            endAtUtc: session.endAtUtc,
            // Session typing is intentionally deferred to normalization
            // (winner-selection + night classification) owned by the
            // normalization processing orchestrator in a later batch, so
            // ingestion mapping stays deterministic and source-faithful here.
            sessionType: SleepSessionType.unknown,
            sourcePlatform: session.sourcePlatform,
            sourceAppId: session.sourceAppId,
            sourceRecordHash: session.sourceRecordHash,
            sourceConfidence: session.sourceConfidence,
            stageConfidence: SleepStageConfidence.unknown,
          ),
        )
        .toList(growable: false);

    final stageSegments = batch.stageSegments
        .where((segment) => sessionIds.contains(segment.sessionRecordId))
        .map((segment) {
      final stage = _mapStage(segment.platformStage);
      return SleepStageSegment(
        id: segment.recordId,
        sessionId: segment.sessionRecordId,
        stage: stage,
        startAtUtc: segment.startAtUtc,
        endAtUtc: segment.endAtUtc,
        sourcePlatform: segment.sourcePlatform,
        sourceAppId: segment.sourceAppId,
        sourceRecordHash: segment.sourceRecordHash,
        sourceConfidence: segment.sourceConfidence,
        stageConfidence: stage == CanonicalSleepStage.inBedOnly
            ? SleepStageConfidence.low
            : SleepStageConfidence.unknown,
      );
    }).toList(growable: false);

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

    return HealthKitCanonicalMappingResult(
      sessions: sessions,
      stageSegments: stageSegments,
      heartRateSamples: heartRates,
    );
  }

  CanonicalSleepStage _mapStage(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'awake':
        return CanonicalSleepStage.awake;
      case 'core':
        return CanonicalSleepStage.light;
      case 'deep':
        return CanonicalSleepStage.deep;
      case 'rem':
        return CanonicalSleepStage.rem;
      case 'in_bed':
      case 'inbed':
      case 'in bed':
        return CanonicalSleepStage.inBedOnly;
      default:
        return CanonicalSleepStage.unknown;
    }
  }
}
