import '../../domain/sleep_domain.dart';

/// Repairs stage timelines for a single selected canonical session.
///
/// Deterministic rules:
/// - Trim to session bounds.
/// - Drop zero-length intervals.
/// - Resolve overlaps by splitting on boundaries and selecting the highest
///   priority stage:
///   awake/rem/deep/light > asleep_unspecified > in_bed_only > unknown.
/// - Merge adjacent intervals with the same stage.
List<SleepStageSegment> repairSleepTimeline({
  required SleepSession session,
  required List<SleepStageSegment> segments,
}) {
  final trimmed = <_IndexedSegment>[];
  for (var i = 0; i < segments.length; i++) {
    final segment = segments[i];
    final start = segment.startAtUtc.isBefore(session.startAtUtc)
        ? session.startAtUtc
        : segment.startAtUtc;
    final end = segment.endAtUtc.isAfter(session.endAtUtc)
        ? session.endAtUtc
        : segment.endAtUtc;
    if (!end.isAfter(start)) continue;
    trimmed.add(
      _IndexedSegment(
        index: i,
        segment: SleepStageSegment(
          id: segment.id,
          sessionId: segment.sessionId,
          stage: segment.stage,
          startAtUtc: start,
          endAtUtc: end,
          sourcePlatform: segment.sourcePlatform,
          sourceAppId: segment.sourceAppId,
          sourceRecordHash: segment.sourceRecordHash,
          sourceConfidence: segment.sourceConfidence,
          stageConfidence: segment.stageConfidence,
        ),
      ),
    );
  }

  if (trimmed.isEmpty) return const <SleepStageSegment>[];

  trimmed.sort(
    (a, b) =>
        a.segment.startAtUtc.compareTo(b.segment.startAtUtc) != 0
            ? a.segment.startAtUtc.compareTo(b.segment.startAtUtc)
            : a.segment.endAtUtc.compareTo(b.segment.endAtUtc),
  );

  final boundaries = <DateTime>{session.startAtUtc, session.endAtUtc};
  for (final item in trimmed) {
    boundaries.add(item.segment.startAtUtc);
    boundaries.add(item.segment.endAtUtc);
  }
  final orderedBoundaries = boundaries.toList()..sort();
  final output = <SleepStageSegment>[];

  for (var i = 0; i < orderedBoundaries.length - 1; i++) {
    final start = orderedBoundaries[i];
    final end = orderedBoundaries[i + 1];
    if (!end.isAfter(start)) continue;
    final covering = trimmed.where(
      (item) =>
          item.segment.startAtUtc.isBefore(end) &&
          item.segment.endAtUtc.isAfter(start),
    );
    if (covering.isEmpty) continue;
    final selected = covering.toList()
      ..sort((a, b) {
        final priorityDelta =
            _stagePriority(b.segment.stage) - _stagePriority(a.segment.stage);
        if (priorityDelta != 0) return priorityDelta;
        return a.index.compareTo(b.index);
      });
    final winner = selected.first.segment;
    output.add(
      SleepStageSegment(
        id: '${session.id}:timeline:$i',
        sessionId: session.id,
        stage: winner.stage,
        startAtUtc: start,
        endAtUtc: end,
        sourcePlatform: winner.sourcePlatform,
        sourceAppId: winner.sourceAppId,
        sourceRecordHash: winner.sourceRecordHash,
        sourceConfidence: winner.sourceConfidence,
        stageConfidence: winner.stageConfidence,
      ),
    );
  }

  if (output.isEmpty) return const <SleepStageSegment>[];
  final merged = <SleepStageSegment>[output.first];
  for (final current in output.skip(1)) {
    final previous = merged.last;
    if (previous.stage == current.stage &&
        previous.endAtUtc == current.startAtUtc) {
      merged[merged.length - 1] = SleepStageSegment(
        id: previous.id,
        sessionId: previous.sessionId,
        stage: previous.stage,
        startAtUtc: previous.startAtUtc,
        endAtUtc: current.endAtUtc,
        sourcePlatform: previous.sourcePlatform,
        sourceAppId: previous.sourceAppId,
        sourceRecordHash: previous.sourceRecordHash,
        sourceConfidence: previous.sourceConfidence,
        stageConfidence: previous.stageConfidence,
      );
    } else {
      merged.add(current);
    }
  }
  return merged;
}

int _stagePriority(CanonicalSleepStage stage) {
  return switch (stage) {
    CanonicalSleepStage.awake ||
    CanonicalSleepStage.rem ||
    CanonicalSleepStage.deep ||
    CanonicalSleepStage.light =>
      4,
    CanonicalSleepStage.asleepUnspecified => 3,
    CanonicalSleepStage.inBedOnly => 2,
    _ => 1,
  };
}

class _IndexedSegment {
  const _IndexedSegment({required this.index, required this.segment});

  final int index;
  final SleepStageSegment segment;
}
