// lib/features/workout/domain/repositories/workout_repository.dart
import '../../../exercise_catalog/domain/models/exercise.dart';
import '../models/routine.dart';
import '../models/set_log.dart';
import '../models/workout_log.dart';

/// Abstract contract for Workout data persistence and operations.
abstract class IWorkoutRepository {
  Future<WorkoutLog?> getOngoingWorkout();
  Future<int> insertSetLog(SetLog log);
  Future<List<SetLog>> getSetLogsForWorkout(int workoutLogId);
  Future<Routine?> getRoutineByName(String name);
  Future<Exercise?> resolveExerciseForSetLog(SetLog log);
  Future<Exercise?> getExerciseByName(String name);
  Future<String?> getExerciseUuidByLocalId(int localId);
  Future<Map<String, double>> getExerciseBests(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  });
  Future<void> updateSetLogs(List<SetLog> logs);
  Future<void> deleteSetLogs(List<int> ids);
  Future<void> finishWorkout(int logId, {String? title, String? notes});
  Future<void> updatePauseTime(int routineExerciseId, int? seconds);
  Future<List<SetLog>> getLastSetsForExercise(String exerciseName);
  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(
      DateTime start, DateTime end);
}
