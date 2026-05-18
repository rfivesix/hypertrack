import '../../../models/set_log.dart';
import '../../../models/set_template.dart';

class LogSetResult {
  final SetLog updatedSet;
  final double volumeDelta;

  LogSetResult(this.updatedSet, this.volumeDelta);
}

class LogWorkoutSetUseCase {
  LogSetResult execute({
    required SetLog oldLog,
    SetTemplate? template,
    double? weight,
    bool clearWeight = false,
    int? reps,
    bool clearReps = false,
    bool? isCompleted,
    String? setType,
    int? rir,
    bool clearRir = false,
    double? distance,
    bool clearDistance = false,
    int? duration,
    bool clearDuration = false,
  }) {
    bool newlyCompleted = isCompleted == true && oldLog.isCompleted != true;
    double? finalWeight = weight;
    int? finalReps = reps;
    int? finalRir = rir;

    if (newlyCompleted) {
      final currentWeight = weight ?? oldLog.weightKg;
      final currentReps = reps ?? oldLog.reps;

      if (template != null) {
        if (currentWeight == null && !clearWeight) {
          finalWeight = template.targetWeight ?? 0.0;
        }
        if (currentReps == null && !clearReps) {
          if (template.targetReps != null && template.targetReps!.isNotEmpty) {
            if (template.targetReps!.contains('-')) {
              final parts = template.targetReps!.split('-');
              final min = int.tryParse(parts[0]) ?? 0;
              final max = int.tryParse(parts[1]) ?? 0;
              finalReps = ((min + max) / 2).round();
            } else {
              finalReps = int.tryParse(template.targetReps!) ?? 0;
            }
          } else {
            finalReps = 0;
          }
        }
      }
    }

    double volumeDelta = 0.0;
    if (finalWeight != null || finalReps != null || clearWeight || clearReps) {
      final oldVol = (oldLog.weightKg ?? 0) * (oldLog.reps ?? 0);
      final newWeight =
          clearWeight ? 0.0 : (finalWeight ?? oldLog.weightKg ?? 0.0);
      final newReps = clearReps ? 0 : (finalReps ?? oldLog.reps ?? 0);
      volumeDelta = (newWeight * newReps) - oldVol;
    }

    final newLog = oldLog.copyWith(
      weightKg: finalWeight,
      clearWeight: clearWeight,
      reps: finalReps,
      clearReps: clearReps,
      isCompleted: isCompleted,
      setType: setType,
      rir: finalRir,
      clearRir: clearRir,
      distanceKm: distance,
      clearDistance: clearDistance,
      durationSeconds: duration,
      clearDuration: clearDuration,
    );

    return LogSetResult(newLog, volumeDelta);
  }
}
