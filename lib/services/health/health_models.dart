enum StepsAvailability { available, notAvailable }

enum StepsProviderFilter { all, apple, google }

enum StepsSourcePolicy { autoDominant, maxPerHour }

class HealthStepSegmentDto {
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final int stepCount;
  final String? sourceId;
  final String? nativeId;

  const HealthStepSegmentDto({
    required this.startAtUtc,
    required this.endAtUtc,
    required this.stepCount,
    this.sourceId,
    this.nativeId,
  });

  factory HealthStepSegmentDto.fromMap(Map<dynamic, dynamic> map) {
    return HealthStepSegmentDto(
      startAtUtc: DateTime.parse(map['startAtUtcIso'] as String).toUtc(),
      endAtUtc: DateTime.parse(map['endAtUtcIso'] as String).toUtc(),
      stepCount: (map['stepCount'] as num).toInt(),
      sourceId: map['sourceId'] as String?,
      nativeId: map['nativeId'] as String?,
    );
  }
}

class StepsSyncResult {
  final bool skipped;
  final int fetchedCount;
  final int upsertedCount;

  const StepsSyncResult({
    required this.skipped,
    required this.fetchedCount,
    required this.upsertedCount,
  });
}
