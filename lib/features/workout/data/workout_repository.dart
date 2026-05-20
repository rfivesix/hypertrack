// lib/features/workout/data/workout_repository.dart
import '../../exercise_catalog/domain/models/exercise.dart';
import '../domain/models/routine.dart';
import '../domain/models/set_log.dart';
import '../domain/models/workout_log.dart';
import 'sources/workout_local_data_source.dart';
import '../domain/repositories/workout_repository.dart';

/// Concrete implementation of [IWorkoutRepository] implementing workout database transactions.
class WorkoutRepository implements IWorkoutRepository {
  final WorkoutLocalDataSource _localDataSource;

  WorkoutRepository({required WorkoutLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<WorkoutLog?> getOngoingWorkout() =>
      _localDataSource.getOngoingWorkout();

  @override
  Future<int> insertSetLog(SetLog log) => _localDataSource.insertSetLog(log);

  @override
  Future<List<SetLog>> getSetLogsForWorkout(int workoutLogId) =>
      _localDataSource.getSetLogsForWorkout(workoutLogId);

  @override
  Stream<List<SetLog>> watchSetLogsForWorkout(int workoutLogId) =>
      _localDataSource.watchSetLogsForWorkout(workoutLogId);

  @override
  Future<Routine?> getRoutineByName(String name) =>
      _localDataSource.getRoutineByName(name);

  @override
  Future<Exercise?> resolveExerciseForSetLog(SetLog log) =>
      _localDataSource.resolveExerciseForSetLog(log);

  @override
  Future<Exercise?> getExerciseByName(String name) =>
      _localDataSource.getExerciseByName(name);

  @override
  Future<String?> getExerciseUuidByLocalId(int localId) =>
      _localDataSource.getExerciseUuidByLocalId(localId);

  @override
  Future<Map<String, double>> getExerciseBests(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  }) =>
      _localDataSource.getExerciseBests(
        exerciseName,
        altName: altName,
        exerciseUuid: exerciseUuid,
      );

  @override
  Future<void> updateSetLogs(List<SetLog> logs) =>
      _localDataSource.updateSetLogs(logs);

  @override
  Future<void> deleteSetLogs(List<int> ids) =>
      _localDataSource.deleteSetLogs(ids);

  @override
  Future<void> finishWorkout(int logId, {String? title, String? notes}) =>
      _localDataSource.finishWorkout(logId, title: title, notes: notes);

  @override
  Future<void> updatePauseTime(int routineExerciseId, int? seconds) =>
      _localDataSource.updatePauseTime(routineExerciseId, seconds);

  @override
  Future<void> updateRoutineExerciseNotes(int routineExerciseId, String? notes) =>
      _localDataSource.updateRoutineExerciseNotes(routineExerciseId, notes);

  @override
  Future<void> saveWorkoutExerciseNote({
    required int workoutLogId,
    required String exerciseName,
    required String? notes,
  }) =>
      _localDataSource.saveWorkoutExerciseNote(
        workoutLogId: workoutLogId,
        exerciseName: exerciseName,
        notes: notes,
      );

  @override
  Future<Map<String, String>> getWorkoutExerciseNotes(int workoutLogId) =>
      _localDataSource.getWorkoutExerciseNotes(workoutLogId);

  @override
  Future<List<SetLog>> getLastSetsForExercise(String exerciseName) =>
      _localDataSource.getLastSetsForExercise(exerciseName);

  @override
  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(
          DateTime start, DateTime end) =>
      _localDataSource.getWorkoutLogsForDateRange(start, end);

  @override
  Stream<List<WorkoutLog>> watchFullWorkoutLogs() =>
      _localDataSource.watchFullWorkoutLogs();

  @override
  Stream<List<Routine>> watchAllRoutines() =>
      _localDataSource.watchAllRoutines();

  @override
  Stream<List<WorkoutLog>> watchWorkoutLogsForDateRange(
          DateTime start, DateTime end) =>
      _localDataSource.watchWorkoutLogsForDateRange(start, end);
}
