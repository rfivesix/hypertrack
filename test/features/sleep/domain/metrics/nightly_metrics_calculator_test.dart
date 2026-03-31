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
    expect(metrics.totalSleepTime.inMinutes, 470);
    expect(metrics.wakeAfterSleepOnset.inMinutes, 5);
    expect(metrics.interruptionsCount, 1);
    expect(metrics.sleepEfficiencyPct, closeTo(97.9, 0.2));
  });
}
