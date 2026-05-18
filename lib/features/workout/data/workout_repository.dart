import '../../../models/exercise.dart';
import '../../../models/routine.dart';
import '../../../models/set_log.dart';
import '../../../models/workout_log.dart';
import '../../../data/workout_database_helper.dart';

class WorkoutRepository {
  final WorkoutDatabaseHelper _db;

  WorkoutRepository({WorkoutDatabaseHelper? db})
      : _db = db ?? WorkoutDatabaseHelper.instance;

  Future<WorkoutLog?> getOngoingWorkout() => _db.getOngoingWorkout();

  Future<int> insertSetLog(SetLog log) => _db.insertSetLog(log);

  Future<List<SetLog>> getSetLogsForWorkout(int workoutLogId) =>
      _db.getSetLogsForWorkout(workoutLogId);

  Future<Routine?> getRoutineByName(String name) => _db.getRoutineByName(name);

  Future<Exercise?> resolveExerciseForSetLog(SetLog log) =>
      _db.resolveExerciseForSetLog(log);

  Future<Exercise?> getExerciseByName(String name) =>
      _db.getExerciseByName(name);

  Future<String?> getExerciseUuidByLocalId(int localId) =>
      _db.getExerciseUuidByLocalId(localId);

  Future<Map<String, double>> getExerciseBests(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  }) =>
      _db.getExerciseBests(
        exerciseName,
        altName: altName,
        exerciseUuid: exerciseUuid,
      );

  Future<void> updateSetLogs(List<SetLog> logs) => _db.updateSetLogs(logs);

  Future<void> deleteSetLogs(List<int> ids) => _db.deleteSetLogs(ids);

  Future<void> finishWorkout(int logId, {String? title, String? notes}) =>
      _db.finishWorkout(logId, title: title, notes: notes);

  Future<void> updatePauseTime(int routineExerciseId, int? seconds) =>
      _db.updatePauseTime(routineExerciseId, seconds);

  Future<List<SetLog>> getLastSetsForExercise(String exerciseName) =>
      _db.getLastSetsForExercise(exerciseName);
}
