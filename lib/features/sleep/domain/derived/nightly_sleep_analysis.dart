import '../sleep_enums.dart';

/// Derived nightly aggregate.
///
/// Ownership is in `domain/derived` because this model is not a canonical
/// ingestion artifact and is expected to evolve with analysis versions.
class NightlySleepAnalysis {
  const NightlySleepAnalysis({
    required this.id,
    required this.sessionId,
    required this.nightDate,
    required this.analysisVersion,
    required this.normalizationVersion,
    required this.analyzedAtUtc,
    this.score,
    this.totalSleepMinutes,
    this.sleepEfficiencyPct,
    this.restingHeartRateBpm,
    this.interruptionsCount,
    this.interruptionsWakeMinutes,
    this.scoreCompleteness,
    this.regularitySri,
    this.regularityValidDays,
    this.regularityStable,
    this.sleepQuality = SleepQualityBucket.unavailable,
    this.sessionStartAtUtc,
    this.sessionEndAtUtc,
    this.sourcePlatform,
    this.sourceAppId,
    this.sourceRecordHash,
  });

  final String id;
  final String sessionId;
  final DateTime nightDate;
  final String analysisVersion;
  final String normalizationVersion;
  final DateTime analyzedAtUtc;
  final double? score;
  final int? totalSleepMinutes;
  final double? sleepEfficiencyPct;
  final double? restingHeartRateBpm;
  final int? interruptionsCount;
  final int? interruptionsWakeMinutes;
  final double? scoreCompleteness;
  final double? regularitySri;
  final int? regularityValidDays;
  final bool? regularityStable;
  final SleepQualityBucket sleepQuality;
  final DateTime? sessionStartAtUtc;
  final DateTime? sessionEndAtUtc;
  final String? sourcePlatform;
  final String? sourceAppId;
  final String? sourceRecordHash;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'sessionId': sessionId,
        'nightDate': nightDate.toIso8601String(),
        'analysisVersion': analysisVersion,
        'normalizationVersion': normalizationVersion,
        'analyzedAtUtc': analyzedAtUtc.toIso8601String(),
        'score': score,
        'totalSleepMinutes': totalSleepMinutes,
        'sleepEfficiencyPct': sleepEfficiencyPct,
        'restingHeartRateBpm': restingHeartRateBpm,
        'interruptionsCount': interruptionsCount,
        'interruptionsWakeMinutes': interruptionsWakeMinutes,
        'scoreCompleteness': scoreCompleteness,
        'regularitySri': regularitySri,
        'regularityValidDays': regularityValidDays,
        'regularityStable': regularityStable,
        'sleepQuality': sleepQuality.name,
        'sessionStartAtUtc': sessionStartAtUtc?.toIso8601String(),
        'sessionEndAtUtc': sessionEndAtUtc?.toIso8601String(),
        'sourcePlatform': sourcePlatform,
        'sourceAppId': sourceAppId,
        'sourceRecordHash': sourceRecordHash,
      };
}
