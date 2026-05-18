// lib/features/workout/data/sources/workout_local_data_source.dart
import '../../../../data/drift_database.dart' show AppDatabase;
import '../../../../data/workout_database_helper.dart';
import '../../../exercise_catalog/domain/models/exercise.dart';
import '../../domain/models/routine.dart';
import '../../domain/models/set_log.dart';
import '../../domain/models/workout_log.dart';

/// Isolated local data source for the Workout feature.
class WorkoutLocalDataSource {
  final AppDatabase db;
  final WorkoutDatabaseHelper _workoutDbHelper;

  WorkoutLocalDataSource(
    this.db, {
    WorkoutDatabaseHelper? workoutDbHelper,
  }) : _workoutDbHelper = workoutDbHelper ?? WorkoutDatabaseHelper.instance;

  Future<WorkoutLog?> getOngoingWorkout() {
    return _workoutDbHelper.getOngoingWorkout();
  }

  Future<int> insertSetLog(SetLog log) {
    return _workoutDbHelper.insertSetLog(log);
  }

  Future<List<SetLog>> getSetLogsForWorkout(int workoutLogId) async {
    final list = await _workoutDbHelper.getSetLogsForWorkout(workoutLogId);
    return list.cast<SetLog>();
  }

  Future<Routine?> getRoutineByName(String name) {
    return _workoutDbHelper.getRoutineByName(name);
  }

  Future<Exercise?> resolveExerciseForSetLog(SetLog log) {
    return _workoutDbHelper.resolveExerciseForSetLog(log);
  }

  Future<Exercise?> getExerciseByName(String name) {
    return _workoutDbHelper.getExerciseByName(name);
  }

  Future<String?> getExerciseUuidByLocalId(int localId) {
    return _workoutDbHelper.getExerciseUuidByLocalId(localId);
  }

  Future<Map<String, double>> getExerciseBests(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  }) {
    return _workoutDbHelper.getExerciseBests(
      exerciseName,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );
  }

  Future<void> updateSetLogs(List<SetLog> logs) {
    return _workoutDbHelper.updateSetLogs(logs);
  }

  Future<void> deleteSetLogs(List<int> ids) {
    return _workoutDbHelper.deleteSetLogs(ids);
  }

  Future<void> finishWorkout(int logId, {String? title, String? notes}) {
    return _workoutDbHelper.finishWorkout(logId, title: title, notes: notes);
  }

  Future<void> updatePauseTime(int routineExerciseId, int? seconds) {
    return _workoutDbHelper.updatePauseTime(routineExerciseId, seconds);
  }

  Future<List<SetLog>> getLastSetsForExercise(String exerciseName) async {
    final list = await _workoutDbHelper.getLastSetsForExercise(exerciseName);
    return list.cast<SetLog>();
  }
}
