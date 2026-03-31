import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/data/processing/timeline_repair.dart';
import 'package:hypertrack/features/sleep/domain/sleep_domain.dart';

void main() {
  SleepSession session() => SleepSession(
    id: 's1',
    startAtUtc: DateTime.utc(2026, 3, 1, 22),
    endAtUtc: DateTime.utc(2026, 3, 2, 6),
    sessionType: SleepSessionType.mainSleep,
    sourcePlatform: 'healthkit',
  );

  test('repairs overlaps using stage priority', () {
    final repaired = repairSleepTimeline(
      session: session(),
      segments: [
        SleepStageSegment(
          id: 'a',
          sessionId: 's1',
          stage: CanonicalSleepStage.asleepUnspecified,
          startAtUtc: DateTime.utc(2026, 3, 1, 22),
          endAtUtc: DateTime.utc(2026, 3, 1, 23),
          sourcePlatform: 'healthkit',
        ),
        SleepStageSegment(
          id: 'b',
          sessionId: 's1',
          stage: CanonicalSleepStage.deep,
          startAtUtc: DateTime.utc(2026, 3, 1, 22, 30),
          endAtUtc: DateTime.utc(2026, 3, 1, 23, 30),
          sourcePlatform: 'healthkit',
        ),
      ],
    );

    expect(repaired.length, 3);
    expect(repaired[1].stage, CanonicalSleepStage.deep);
    expect(repaired[1].startAtUtc, DateTime.utc(2026, 3, 1, 22, 30));
    expect(repaired[1].endAtUtc, DateTime.utc(2026, 3, 1, 23));
  });

  test('drops zero-length and merges adjacent same-stage segments', () {
    final repaired = repairSleepTimeline(
      session: session(),
      segments: [
        SleepStageSegment(
          id: 'a',
          sessionId: 's1',
          stage: CanonicalSleepStage.light,
          startAtUtc: DateTime.utc(2026, 3, 1, 22),
          endAtUtc: DateTime.utc(2026, 3, 1, 23),
          sourcePlatform: 'healthkit',
        ),
        SleepStageSegment(
          id: 'b',
          sessionId: 's1',
          stage: CanonicalSleepStage.light,
          startAtUtc: DateTime.utc(2026, 3, 1, 23),
          endAtUtc: DateTime.utc(2026, 3, 2, 0),
          sourcePlatform: 'healthkit',
        ),
        SleepStageSegment(
          id: 'z',
          sessionId: 's1',
          stage: CanonicalSleepStage.rem,
          startAtUtc: DateTime.utc(2026, 3, 2, 0),
          endAtUtc: DateTime.utc(2026, 3, 2, 0),
          sourcePlatform: 'healthkit',
        ),
      ],
    );

    expect(repaired.length, 1);
    expect(repaired.single.stage, CanonicalSleepStage.light);
    expect(repaired.single.endAtUtc, DateTime.utc(2026, 3, 2, 0));
  });
}

