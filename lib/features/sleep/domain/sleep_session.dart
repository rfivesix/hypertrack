import 'sleep_enums.dart';

/// Canonical, platform-agnostic sleep session entity.
class SleepSession {
  const SleepSession({
    required this.id,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.sessionType,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceRecordHash,
    this.sourceConfidence,
    this.stageConfidence = SleepStageConfidence.unknown,
    this.overallConfidence = SleepOverallConfidence.unknown,
    this.normalizationVersion,
  });

  final String id;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final SleepSessionType sessionType;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceRecordHash;
  final String? sourceConfidence;
  final SleepStageConfidence stageConfidence;
  final SleepOverallConfidence overallConfidence;
  final String? normalizationVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'startAtUtc': startAtUtc.toIso8601String(),
        'endAtUtc': endAtUtc.toIso8601String(),
        'sessionType': sessionType.name,
        'sourcePlatform': sourcePlatform,
        'sourceAppId': sourceAppId,
        'sourceRecordHash': sourceRecordHash,
        'sourceConfidence': sourceConfidence,
        'stageConfidence': stageConfidence.name,
        'overallConfidence': overallConfidence.name,
        'normalizationVersion': normalizationVersion,
      };
}
