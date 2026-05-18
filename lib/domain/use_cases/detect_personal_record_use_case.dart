import '../../models/set_log.dart';

class PRDetectionResult {
  final SetLog updatedSetLog;
  final List<PRAlert> alerts;

  PRDetectionResult(this.updatedSetLog, this.alerts);
}

class PRAlert {
  final String exerciseName;
  final String recordType;
  final String achievementValue;
  final double? diff;

  PRAlert({
    required this.exerciseName,
    required this.recordType,
    required this.achievementValue,
    this.diff,
  });
}

class DetectPersonalRecordUseCase {
  PRDetectionResult execute({
    required SetLog currentSet,
    required Map<String, double> historicalBests,
  }) {
    final currentWeight = currentSet.weightKg ?? 0.0;
    final currentReps = currentSet.reps ?? 0;
    final currentVolume = currentWeight * currentReps;

    double currentEst1rm = 0.0;
    if (currentReps > 0 && currentReps <= 10) {
      currentEst1rm = currentWeight * (36 / (37 - currentReps));
    }

    bool isMaxWeightPR = false;
    bool isMaxVolumePR = false;
    bool isMaxEst1RMPR = false;

    double? weightDiff;
    double? volumeDiff;
    double? est1rmDiff;

    if (currentWeight > 0) {
      final oldMaxWeight = historicalBests['maxWeight'] ?? 0.0;
      if (currentWeight > oldMaxWeight) {
        isMaxWeightPR = true;
        weightDiff = oldMaxWeight > 0 ? currentWeight - oldMaxWeight : null;
        historicalBests['maxWeight'] = currentWeight; // Updating local map
      }

      final oldMaxVolume = historicalBests['maxVolume'] ?? 0.0;
      if (currentVolume > oldMaxVolume) {
        isMaxVolumePR = true;
        volumeDiff = oldMaxVolume > 0 ? currentVolume - oldMaxVolume : null;
        historicalBests['maxVolume'] = currentVolume;
      }

      final oldMaxEst1rm = historicalBests['maxEst1rm'] ?? 0.0;
      if (currentEst1rm > oldMaxEst1rm) {
        isMaxEst1RMPR = true;
        est1rmDiff = oldMaxEst1rm > 0 ? currentEst1rm - oldMaxEst1rm : null;
        historicalBests['maxEst1rm'] = currentEst1rm;
      }
    }

    final alerts = <PRAlert>[];

    if (isMaxWeightPR || isMaxVolumePR || isMaxEst1RMPR) {
      if (isMaxWeightPR) {
        alerts.add(PRAlert(
          exerciseName: currentSet.exerciseName,
          recordType: "Best Max Weight",
          achievementValue: "${currentWeight.toStringAsFixed(1).replaceAll('.0', '')} kg",
          diff: weightDiff,
        ));
      }
      if (isMaxVolumePR) {
        alerts.add(PRAlert(
          exerciseName: currentSet.exerciseName,
          recordType: "Best Volume Set",
          achievementValue: "${currentVolume.toStringAsFixed(0)} kg",
          diff: volumeDiff,
        ));
      }
      if (isMaxEst1RMPR) {
        alerts.add(PRAlert(
          exerciseName: currentSet.exerciseName,
          recordType: "Best 1-Rep Max",
          achievementValue: "${currentEst1rm.toStringAsFixed(1).replaceAll('.0', '')} kg",
          diff: est1rmDiff,
        ));
      }
    }

    final updatedLog = currentSet.copyWith(
      isMaxWeightPR: isMaxWeightPR,
      isMaxVolumePR: isMaxVolumePR,
      isMaxEst1RMPR: isMaxEst1RMPR,
      weightPRDiff: weightDiff,
      volumePRDiff: volumeDiff,
      est1rmPRDiff: est1rmDiff,
    );

    return PRDetectionResult(updatedLog, alerts);
  }
}
