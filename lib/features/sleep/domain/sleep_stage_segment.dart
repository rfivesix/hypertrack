import 'sleep_enums.dart';

/// Canonical stage segment belonging to a [SleepSession].
class SleepStageSegment {
  const SleepStageSegment({
    required this.id,
    required this.sessionId,
    required this.stage,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceRecordHash,
    this.sourceConfidence,
    this.stageConfidence = SleepStageConfidence.unknown,
  });

  final String id;
  final String sessionId;
  final CanonicalSleepStage stage;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceRecordHash;
  final String? sourceConfidence;
  final SleepStageConfidence stageConfidence;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'sessionId': sessionId,
        'stage': stage.name,
        'startAtUtc': startAtUtc.toIso8601String(),
        'endAtUtc': endAtUtc.toIso8601String(),
        'sourcePlatform': sourcePlatform,
        'sourceAppId': sourceAppId,
        'sourceRecordHash': sourceRecordHash,
        'sourceConfidence': sourceConfidence,
        'stageConfidence': stageConfidence.name,
      };
}
