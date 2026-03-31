import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/data/mapping/health_connect_mapper.dart';
import 'package:hypertrack/features/sleep/domain/sleep_enums.dart';
import 'package:hypertrack/features/sleep/platform/ingestion/sleep_ingestion_models.dart';

void main() {
  const mapper = HealthConnectMapper();

  SleepRawIngestionBatch batchWithStages(List<String> stages) {
    final session = SleepIngestionSession(
      recordId: 'hc-s1',
      startAtUtc: DateTime.utc(2026, 1, 2, 22),
      endAtUtc: DateTime.utc(2026, 1, 3, 6),
      platformSessionType: 'sleep',
      sourcePlatform: 'health_connect',
      sourceRecordHash: 'hash-hc-s1',
    );
    final segments = <SleepIngestionStageSegment>[];
    for (var i = 0; i < stages.length; i += 1) {
      segments.add(
        SleepIngestionStageSegment(
          recordId: 'hc-seg-$i',
          sessionRecordId: 'hc-s1',
          startAtUtc: DateTime.utc(2026, 1, 2, 22 + i),
          endAtUtc: DateTime.utc(2026, 1, 2, 23 + i),
          platformStage: stages[i],
          sourcePlatform: 'health_connect',
          sourceRecordHash: 'hash-hc-seg-$i',
        ),
      );
    }

    return SleepRawIngestionBatch(
      sessions: [session],
      stageSegments: segments,
      heartRateSamples: const [],
    );
  }

  test('maps known health connect stages and out-of-bed', () {
    final result = mapper.map(
      batchWithStages(['awake', 'light', 'deep', 'REM', 'asleep', 'out_of_bed']),
    );

    expect(
      result.stageSegments.map((s) => s.stage).toList(growable: false),
      [
        CanonicalSleepStage.awake,
        CanonicalSleepStage.light,
        CanonicalSleepStage.deep,
        CanonicalSleepStage.rem,
        CanonicalSleepStage.asleepUnspecified,
        CanonicalSleepStage.outOfBed,
      ],
    );
  });

  test('maps unknown stage to unknown', () {
    final result = mapper.map(batchWithStages(['not_a_stage']));

    expect(result.stageSegments.single.stage, CanonicalSleepStage.unknown);
  });
}
