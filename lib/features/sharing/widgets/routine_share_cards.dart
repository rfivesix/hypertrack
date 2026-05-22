part of '../share_card_renderer.dart';

class _RoutineSummaryCard extends StatelessWidget {
  const _RoutineSummaryCard({
    required this.routine,
    required this.formatter,
    required this.labels,
  });

  final Routine routine;
  final RoutineShareFormatter formatter;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    final typeCounts = formatter.setTypeCounts(routine);
    return _ShareScaffold(
      labels: labels,
      children: [
        _Kicker(labels.shareImageSummary),
        const SizedBox(height: 30),
        _Title(routine.name),
        const SizedBox(height: 68),
        _MetricGrid(
          metrics: [
            _Metric(labels.exercises, '${routine.exercises.length}'),
            _Metric(labels.sets, '${formatter.plannedSetCount(routine)}'),
            _Metric(
              labels.warmupSuffix,
              '${typeCounts[ShareSetType.warmup] ?? 0}',
            ),
            _Metric(labels.failureSuffix,
                '${typeCounts[ShareSetType.failure] ?? 0}'),
          ],
        ),
      ],
    );
  }
}

class _RoutineExerciseListCard extends StatelessWidget {
  const _RoutineExerciseListCard({
    required this.routine,
    required this.formatter,
    required this.labels,
  });

  final Routine routine;
  final RoutineShareFormatter formatter;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    final rows = formatter.imageExerciseSummaries(
      routine,
      visibleExerciseLimit: ShareCardRenderer.visibleRoutineExerciseLimit,
    );
    final remaining = formatter.remainingExerciseCount(
      routine,
      ShareCardRenderer.visibleRoutineExerciseLimit,
    );
    return _ShareScaffold(
      labels: labels,
      children: [
        _Kicker(labels.shareImageExercises),
        const SizedBox(height: 26),
        _Title(routine.name, maxLines: 2),
        const SizedBox(height: 42),
        _RoutineExerciseGrid(
          rows: rows,
          remainingCount: remaining,
          labels: labels,
        ),
      ],
    );
  }
}
