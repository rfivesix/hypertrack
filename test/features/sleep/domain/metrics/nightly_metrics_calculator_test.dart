import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/domain/metrics/nightly_metrics_calculator.dart';
import 'package:hypertrack/features/sleep/domain/sleep_domain.dart';

void main() {
  test('computes TIB, TST, SOL, WASO and interruptions deterministically', () {
    final session = SleepSession(
      id: 's1',
      startAtUtc: DateTime.utc(2026, 3, 1, 22),
      endAtUtc: DateTime.utc(2026, 3, 2, 6),
      sessionType: SleepSessionType.mainSleep,
      sourcePlatform: 'healthkit',
    );
    final metrics = calculateNightlySleepMetrics(
      session: session,
      repairedSegments: [
        SleepStageSegment(
          id: 'a',
          sessionId: 's1',
          stage: CanonicalSleepStage.awake,
          startAtUtc: DateTime.utc(2026, 3, 1, 22),
          endAtUtc: DateTime.utc(2026, 3, 1, 22, 10),
          sourcePlatform: 'healthkit',
        ),
        SleepStageSegment(
          id: 'b',
          sessionId: 's1',
          stage: CanonicalSleepStage.light,
          startAtUtc: DateTime.utc(2026, 3, 1, 22, 10),
          endAtUtc: DateTime.utc(2026, 3, 2, 1),
          sourcePlatform: 'healthkit',
        ),
        SleepStageSegment(
          id: 'c',
          sessionId: 's1',
          stage: CanonicalSleepStage.awake,
          startAtUtc: DateTime.utc(2026, 3, 2, 1),
          endAtUtc: DateTime.utc(2026, 3, 2, 1, 5),
          sourcePlatform: 'healthkit',
        ),
        SleepStageSegment(
          id: 'd',
          sessionId: 's1',
          stage: CanonicalSleepStage.deep,
          startAtUtc: DateTime.utc(2026, 3, 2, 1, 5),
          endAtUtc: DateTime.utc(2026, 3, 2, 6),
          sourcePlatform: 'healthkit',
        ),
      ],
    );

    expect(metrics.timeInBed.inMinutes, 480);
    expect(metrics.sleepOnsetLatency.inMinutes, 10);
    expect(metrics.totalSleepTime.inMinutes, 465);
    expect(metrics.wakeAfterSleepOnset.inMinutes, 5);
    expect(metrics.interruptionsCount, 1);
    expect(metrics.sleepEfficiencyPct, closeTo(96.9, 0.2));
  });

  test('mid-session unknown does not inflate WASO or interruptions', () {
    final session = _session();
    final metrics = calculateNightlySleepMetrics(
      session: session,
      repairedSegments: [
        _segment('sleep-1', CanonicalSleepStage.light, 22, 0, 1, 0),
        _segment('unknown', CanonicalSleepStage.unknown, 1, 0, 1, 20),
        _segment('sleep-2', CanonicalSleepStage.deep, 1, 20, 6, 0),
      ],
    );

    expect(metrics.totalSleepTime.inMinutes, 460);
    expect(metrics.wakeAfterSleepOnset.inMinutes, 0);
    expect(metrics.interruptionsCount, 0);
    expect(metrics.totalWakeDuration.inMinutes, 0);
    expect(metrics.sleepEfficiencyPct, closeTo(95.8, 0.2));
  });

  test('inBedOnly-only session is ambiguous, not definite wake', () {
    final session = _session();
    final metrics = calculateNightlySleepMetrics(
      session: session,
      repairedSegments: [
        _segment('in-bed', CanonicalSleepStage.inBedOnly, 22, 0, 6, 0),
      ],
    );

    expect(metrics.totalSleepTime, Duration.zero);
    expect(metrics.wakeAfterSleepOnset, Duration.zero);
    expect(metrics.interruptionsCount, 0);
    expect(metrics.totalWakeDuration, Duration.zero);
    expect(metrics.sleepEfficiencyPct, 0);
  });

  test('explicit awake still counts as wake and WASO', () {
    final session = _session();
    final metrics = calculateNightlySleepMetrics(
      session: session,
      repairedSegments: [
        _segment('sleep-1', CanonicalSleepStage.light, 22, 0, 1, 0),
        _segment('wake', CanonicalSleepStage.awake, 1, 0, 1, 10),
        _segment('sleep-2', CanonicalSleepStage.rem, 1, 10, 6, 0),
      ],
    );

    expect(metrics.wakeAfterSleepOnset.inMinutes, 10);
    expect(metrics.interruptionsCount, 1);
    expect(metrics.totalWakeDuration.inMinutes, 10);
  });
}

SleepSession _session() {
  return SleepSession(
    id: 's1',
    startAtUtc: DateTime.utc(2026, 3, 1, 22),
    endAtUtc: DateTime.utc(2026, 3, 2, 6),
    sessionType: SleepSessionType.mainSleep,
    sourcePlatform: 'healthkit',
  );
}

SleepStageSegment _segment(
  String id,
  CanonicalSleepStage stage,
  int startHour,
  int startMinute,
  int endHour,
  int endMinute,
) {
  final startDay = startHour >= 12 ? 1 : 2;
  final endDay = endHour >= 12 ? 1 : 2;
  return SleepStageSegment(
    id: id,
    sessionId: 's1',
    stage: stage,
    startAtUtc: DateTime.utc(2026, 3, startDay, startHour, startMinute),
    endAtUtc: DateTime.utc(2026, 3, endDay, endHour, endMinute),
    sourcePlatform: 'healthkit',
  );
}
