import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../domain/models/routine_exercise.dart';
import '../../domain/models/set_log.dart';
import '../live_workout_view_model.dart';

/// A widget that calculates and displays the best Estimated 1-Rep Max (e1RM)
/// for the current session and compares it against the previous session.
class ExerciseE1rmSummary extends StatelessWidget {
  final RoutineExercise routineExercise;
  final LiveWorkoutViewModel manager;

  const ExerciseE1rmSummary({
    super.key,
    required this.routineExercise,
    required this.manager,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.read<UnitService>();

    final sessionBest = _getSessionBestE1rm(routineExercise, manager);
    if (sessionBest == null) return const SizedBox.shrink();

    final lastSessionBest = _getLastSessionBestE1rm(
      routineExercise.exercise.nameEn,
    );
    final hasDelta = lastSessionBest != null;
    final delta = hasDelta ? sessionBest - lastSessionBest : null;

    final theme = Theme.of(context);
    final isPositive = (delta ?? 0) >= 0;
    final deltaPrefix = isPositive ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.liveWorkoutE1rmBestSession(
                _formatDisplayWeightValue(sessionBest, unitService),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (hasDelta)
            Text(
              l10n.liveWorkoutE1rmVsLastSession(
                '$deltaPrefix${_formatDisplayWeightValue(delta!.abs(), unitService)}',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isPositive
                    ? Colors.green.shade700
                    : theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  // --- e1RM Calculation Helpers ---

  bool _isQualifyingSetForE1rm(
    SetLog setLog, {
    required bool requireCompleted,
  }) {
    final reps = setLog.reps;
    final weight = setLog.weightKg;
    final isWarmup = setLog.setType == 'warmup';
    final isCompleted = setLog.isCompleted == true;

    if (isWarmup) return false;
    if (requireCompleted && !isCompleted) return false;
    if (weight == null || weight <= 0) return false;
    if (reps == null || reps <= 0 || reps > 10) return false;

    return true;
  }

  double? _calculateBrzyckiE1rm(
    SetLog setLog, {
    required bool requireCompleted,
  }) {
    if (!_isQualifyingSetForE1rm(setLog, requireCompleted: requireCompleted)) {
      return null;
    }

    final reps = setLog.reps!;
    final weight = setLog.weightKg!;
    return weight * (36 / (37 - reps));
  }

  double? _getSessionBestE1rm(
    RoutineExercise routineExercise,
    LiveWorkoutViewModel manager,
  ) {
    double? best;

    for (final template in routineExercise.setTemplates) {
      final setLog = manager.setLogs[template.id];
      if (setLog == null) continue;

      final value = _calculateBrzyckiE1rm(setLog, requireCompleted: true);
      if (value == null) continue;

      if (best == null || value > best) {
        best = value;
      }
    }

    return best;
  }

  double? _getLastSessionBestE1rm(String exerciseName) {
    final lastSets = manager.lastPerformances[exerciseName] ?? const <SetLog>[];
    double? best;

    for (final setLog in lastSets) {
      final value = _calculateBrzyckiE1rm(setLog, requireCompleted: true);
      if (value == null) continue;

      if (best == null || value > best) {
        best = value;
      }
    }

    return best;
  }

  String _formatDisplayWeightValue(
    double metricValue,
    UnitService unitService, {
    int fractionDigits = 1,
  }) {
    return unitService
        .convertDisplayValue(metricValue, UnitDimension.weight)
        .toStringAsFixed(fractionDigits)
        .replaceAll('.0', '');
  }
}
