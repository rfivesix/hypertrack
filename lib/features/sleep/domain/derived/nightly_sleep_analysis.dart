import '../sleep_enums.dart';

class SleepRegularityNight {
  const SleepRegularityNight({
    required this.nightDate,
    required this.bedtimeMinutes,
    required this.wakeMinutes,
  });

  final DateTime nightDate;
  final int bedtimeMinutes;
  final int wakeMinutes;
}

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
    this.sleepQuality = SleepQualityBucket.unavailable,
    this.sourcePlatform,
    this.sourceAppId,
    this.sourceRecordHash,
    this.totalSleepMinutes,
    this.sleepHrAvg,
    this.baselineSleepHr,
    this.deltaSleepHr,
    this.isHrBaselineEstablished = false,
    this.interruptionsCount,
    this.interruptionsWakeDuration,
    this.deepSleepMinutes,
    this.lightSleepMinutes,
    this.remSleepMinutes,
    this.hasSufficientStageData = false,
    this.regularityNights = const <SleepRegularityNight>[],
  });

  final String id;
  final String sessionId;
  final DateTime nightDate;
  final String analysisVersion;
  final String normalizationVersion;
  final DateTime analyzedAtUtc;
  final double? score;
  final SleepQualityBucket sleepQuality;
  final String? sourcePlatform;
  final String? sourceAppId;
  final String? sourceRecordHash;
  final int? totalSleepMinutes;
  final double? sleepHrAvg;
  final double? baselineSleepHr;
  final double? deltaSleepHr;
  final bool isHrBaselineEstablished;
  final int? interruptionsCount;
  final Duration? interruptionsWakeDuration;
  final int? deepSleepMinutes;
  final int? lightSleepMinutes;
  final int? remSleepMinutes;
  final bool hasSufficientStageData;
  final List<SleepRegularityNight> regularityNights;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'sessionId': sessionId,
        'nightDate': nightDate.toIso8601String(),
        'analysisVersion': analysisVersion,
        'normalizationVersion': normalizationVersion,
        'analyzedAtUtc': analyzedAtUtc.toIso8601String(),
        'score': score,
        'sleepQuality': sleepQuality.name,
        'sourcePlatform': sourcePlatform,
        'sourceAppId': sourceAppId,
        'sourceRecordHash': sourceRecordHash,
        'totalSleepMinutes': totalSleepMinutes,
        'sleepHrAvg': sleepHrAvg,
        'baselineSleepHr': baselineSleepHr,
        'deltaSleepHr': deltaSleepHr,
        'isHrBaselineEstablished': isHrBaselineEstablished,
        'interruptionsCount': interruptionsCount,
        'interruptionsWakeDurationMinutes': interruptionsWakeDuration?.inMinutes,
        'deepSleepMinutes': deepSleepMinutes,
        'lightSleepMinutes': lightSleepMinutes,
        'remSleepMinutes': remSleepMinutes,
        'hasSufficientStageData': hasSufficientStageData,
        'regularityNights': regularityNights
            .map((night) => <String, dynamic>{
                  'nightDate': night.nightDate.toIso8601String(),
                  'bedtimeMinutes': night.bedtimeMinutes,
                  'wakeMinutes': night.wakeMinutes,
                })
            .toList(growable: false),
      };
}
