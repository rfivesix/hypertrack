import 'sleep_enums.dart';

/// Canonical heart-rate sample associated with a sleep session.
class HeartRateSample {
  const HeartRateSample({
    required this.id,
    required this.sessionId,
    required this.sampledAtUtc,
    required this.bpm,
    required this.sourcePlatform,
    this.sourceAppId,
    this.sourceRecordHash,
    this.sourceConfidence,
    this.heartRateConfidence = HeartRateConfidence.unknown,
  });

  final String id;
  final String sessionId;
  final DateTime sampledAtUtc;
  final double bpm;
  final String sourcePlatform;
  final String? sourceAppId;
  final String? sourceRecordHash;
  final String? sourceConfidence;
  final HeartRateConfidence heartRateConfidence;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'sessionId': sessionId,
        'sampledAtUtc': sampledAtUtc.toIso8601String(),
        'bpm': bpm,
        'sourcePlatform': sourcePlatform,
        'sourceAppId': sourceAppId,
        'sourceRecordHash': sourceRecordHash,
        'sourceConfidence': sourceConfidence,
        'heartRateConfidence': heartRateConfidence.name,
      };
}
