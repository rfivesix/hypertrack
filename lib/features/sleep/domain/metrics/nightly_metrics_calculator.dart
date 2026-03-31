import '../sleep_domain.dart';

const Duration _interruptionWakeThreshold = Duration(minutes: 3);
const Duration _interruptionSleepGapThreshold = Duration(minutes: 2);

class NightlySleepMetrics {
  const NightlySleepMetrics({
    required this.timeInBed,
    required this.sleepOnsetLatency,
    required this.totalSleepTime,
    required this.wakeAfterSleepOnset,
    required this.sleepEfficiencyPct,
    required this.finalAwakeningAtUtc,
    required this.interruptionsCount,
    required this.totalWakeDuration,
    required this.stageDurations,
    required this.stagePercentages,
  });

  final Duration timeInBed;
  final Duration sleepOnsetLatency;
  final Duration totalSleepTime;
  final Duration wakeAfterSleepOnset;
  final double sleepEfficiencyPct;
  final DateTime? finalAwakeningAtUtc;
  final int interruptionsCount;
  final Duration totalWakeDuration;
  final Map<CanonicalSleepStage, Duration> stageDurations;
  final Map<CanonicalSleepStage, double> stagePercentages;
}

NightlySleepMetrics calculateNightlySleepMetrics({
  required SleepSession session,
  required List<SleepStageSegment> repairedSegments,
}) {
  final tib = session.endAtUtc.difference(session.startAtUtc);
  if (tib <= Duration.zero || repairedSegments.isEmpty) {
    return NightlySleepMetrics(
      timeInBed: tib,
      sleepOnsetLatency: tib.isNegative ? Duration.zero : tib,
      totalSleepTime: Duration.zero,
      wakeAfterSleepOnset: Duration.zero,
      sleepEfficiencyPct: 0,
      finalAwakeningAtUtc: null,
      interruptionsCount: 0,
      totalWakeDuration: Duration.zero,
      stageDurations: const <CanonicalSleepStage, Duration>{},
      stagePercentages: const <CanonicalSleepStage, double>{},
    );
  }

  final segments = List<SleepStageSegment>.from(repairedSegments)
    ..sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));
  final stageDurations = <CanonicalSleepStage, Duration>{};
  Duration tst = Duration.zero;
  Duration totalWake = Duration.zero;
  DateTime? sleepOnsetAt;

  for (final segment in segments) {
    final duration = segment.endAtUtc.difference(segment.startAtUtc);
    if (duration <= Duration.zero) continue;
    stageDurations[segment.stage] =
        (stageDurations[segment.stage] ?? Duration.zero) + duration;

    if (_isSleep(segment.stage)) {
      tst += duration;
      sleepOnsetAt ??= segment.startAtUtc;
    } else if (_isWake(segment.stage)) {
      totalWake += duration;
    }
  }

  final finalAwakeningAt = _findFinalAwakeningAt(segments);
  Duration waso = Duration.zero;
  if (sleepOnsetAt != null) {
    for (final segment in segments) {
      if (!_isWake(segment.stage)) continue;
      if (!segment.startAtUtc.isAfter(sleepOnsetAt)) continue;
      waso += segment.endAtUtc.difference(segment.startAtUtc);
    }
  }

  final interruptions = _countInterruptions(segments, sleepOnsetAt: sleepOnsetAt);
  final stagePercentages = <CanonicalSleepStage, double>{};
  if (tst > Duration.zero) {
    for (final entry in stageDurations.entries) {
      if (_isSleep(entry.key)) {
        stagePercentages[entry.key] =
            (entry.value.inSeconds / tst.inSeconds) * 100;
      }
    }
  }

  return NightlySleepMetrics(
    timeInBed: tib,
    sleepOnsetLatency: sleepOnsetAt == null
        ? tib
        : sleepOnsetAt.difference(session.startAtUtc),
    totalSleepTime: tst,
    wakeAfterSleepOnset: waso,
    sleepEfficiencyPct: tib.inSeconds == 0 ? 0 : (tst.inSeconds / tib.inSeconds) * 100,
    finalAwakeningAtUtc: finalAwakeningAt,
    interruptionsCount: interruptions,
    totalWakeDuration: totalWake,
    stageDurations: stageDurations,
    stagePercentages: stagePercentages,
  );
}

DateTime? _findFinalAwakeningAt(List<SleepStageSegment> sorted) {
  for (var i = sorted.length - 1; i >= 0; i--) {
    if (_isSleep(sorted[i].stage)) {
      for (var j = i + 1; j < sorted.length; j++) {
        if (_isWake(sorted[j].stage)) return sorted[j].startAtUtc;
      }
      return null;
    }
  }
  return null;
}

int _countInterruptions(
  List<SleepStageSegment> sorted, {
  required DateTime? sleepOnsetAt,
}) {
  if (sleepOnsetAt == null) return 0;

  final qualifyingWakeSegments = sorted.where((segment) {
    if (!_isWake(segment.stage)) return false;
    if (!segment.startAtUtc.isAfter(sleepOnsetAt)) return false;
    return segment.endAtUtc.difference(segment.startAtUtc) >=
        _interruptionWakeThreshold;
  }).toList(growable: false);

  if (qualifyingWakeSegments.isEmpty) return 0;
  var count = 1;
  for (var i = 1; i < qualifyingWakeSegments.length; i++) {
    final previous = qualifyingWakeSegments[i - 1];
    final current = qualifyingWakeSegments[i];
    final gap = current.startAtUtc.difference(previous.endAtUtc);
    if (gap > _interruptionSleepGapThreshold) {
      count += 1;
    }
  }
  return count;
}

bool _isSleep(CanonicalSleepStage stage) {
  return stage == CanonicalSleepStage.light ||
      stage == CanonicalSleepStage.deep ||
      stage == CanonicalSleepStage.rem ||
      stage == CanonicalSleepStage.asleepUnspecified;
}

bool _isWake(CanonicalSleepStage stage) {
  return stage == CanonicalSleepStage.awake ||
      stage == CanonicalSleepStage.outOfBed ||
      stage == CanonicalSleepStage.inBedOnly ||
      stage == CanonicalSleepStage.unknown;
}
