import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/data/mapping/healthkit_mapper.dart';
import 'package:hypertrack/features/sleep/domain/sleep_enums.dart';
import 'package:hypertrack/features/sleep/platform/ingestion/sleep_ingestion_models.dart';

void main() {
  const mapper = HealthKitMapper();

  SleepRawIngestionBatch batchWithStages(List<String> stages) {
    final session = SleepIngestionSession(
      recordId: 's1',
      startAtUtc: DateTime.utc(2026, 1, 1, 22),
      endAtUtc: DateTime.utc(2026, 1, 2, 6),
      platformSessionType: 'sleep',
      sourcePlatform: 'healthkit',
      sourceRecordHash: 'hash-s1',
    );
    final segments = <SleepIngestionStageSegment>[];
    for (var i = 0; i < stages.length; i += 1) {
      segments.add(
        SleepIngestionStageSegment(
          recordId: 'seg-$i',
          sessionRecordId: 's1',
          startAtUtc: DateTime.utc(2026, 1, 1, 22 + i),
          endAtUtc: DateTime.utc(2026, 1, 1, 23 + i),
          platformStage: stages[i],
          sourcePlatform: 'healthkit',
          sourceRecordHash: 'hash-seg-$i',
        ),
      );
    }

    return SleepRawIngestionBatch(
      sessions: [session],
      stageSegments: segments,
      heartRateSamples: const [],
    );
  }

  test('maps in-bed-only to inBedOnly with low confidence', () {
    final result = mapper.map(batchWithStages(['in bed']));

    expect(result.stageSegments.single.stage, CanonicalSleepStage.inBedOnly);
    expect(
      result.stageSegments.single.stageConfidence,
      SleepStageConfidence.low,
    );
  });

  test('maps mixed healthkit stages deterministically', () {
    final result = mapper.map(
      batchWithStages(['awake', 'core', 'deep', 'REM']),
    );

    expect(result.stageSegments.map((s) => s.stage).toList(growable: false), [
      CanonicalSleepStage.awake,
      CanonicalSleepStage.light,
      CanonicalSleepStage.deep,
      CanonicalSleepStage.rem,
    ]);
  });

  test('maps unknown category to unknown stage', () {
    final result = mapper.map(batchWithStages(['mystery_stage']));

    expect(result.stageSegments.single.stage, CanonicalSleepStage.unknown);
  });
}
