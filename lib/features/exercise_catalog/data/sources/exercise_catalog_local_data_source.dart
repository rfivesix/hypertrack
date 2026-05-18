// lib/features/exercise_catalog/data/sources/exercise_catalog_local_data_source.dart
import '../../../../data/drift_database.dart' show AppDatabase;
import '../../../../data/workout_database_helper.dart';
import '../../../workout/domain/models/set_log.dart';
import '../../domain/models/exercise.dart';

/// Isolated local data source for the Exercise Catalog feature.
class ExerciseCatalogLocalDataSource {
  final AppDatabase db;
  final WorkoutDatabaseHelper _workoutDbHelper;

  ExerciseCatalogLocalDataSource(
    this.db, {
    WorkoutDatabaseHelper? workoutDbHelper,
  }) : _workoutDbHelper = workoutDbHelper ?? WorkoutDatabaseHelper.instance;

  Future<List<Exercise>> searchExercises({
    String query = '',
    List<String> selectedCategories = const [],
  }) async {
    final list = await _workoutDbHelper.searchExercises(
      query: query,
      selectedCategories: selectedCategories,
    );
    return list.cast<Exercise>();
  }

  Future<Exercise?> getExerciseById(String id) {
    return _workoutDbHelper.getExerciseByUuid(id);
  }

  Future<Exercise?> getExerciseByUuid(String uuid) {
    return _workoutDbHelper.getExerciseByUuid(uuid);
  }

  Future<Exercise?> getExerciseByName(String name) {
    return _workoutDbHelper.getExerciseByName(name);
  }

  Future<Exercise> insertExercise(Exercise exercise) {
    return _workoutDbHelper.insertExercise(exercise);
  }

  Future<List<Exercise>> getCustomExercises() async {
    final list = await _workoutDbHelper.getCustomExercises();
    return list.cast<Exercise>();
  }

  Future<void> importCustomExercises(List<Exercise> exercises) {
    return _workoutDbHelper.importCustomExercises(exercises);
  }

  Future<void> applyExerciseNameMapping(Map<String, String> mapping) {
    return _workoutDbHelper.applyExerciseNameMapping(mapping);
  }

  Future<String?> getExerciseUuidByLocalId(int id) {
    return _workoutDbHelper.getExerciseUuidByLocalId(id);
  }

  Future<Map<String, SetLog?>> getExercisePRs(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  }) async {
    final res = await _workoutDbHelper.getExercisePRs(
      exerciseName,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );
    return res.cast<String, SetLog?>();
  }

  Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  }) {
    return _workoutDbHelper.getExerciseTimeSeriesData(
      exerciseName,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );
  }

  Future<List<String>> getAllCategories() {
    return _workoutDbHelper.getAllCategories();
  }

  Future<List<String>> getAllMuscleGroups() {
    return _workoutDbHelper.getAllMuscleGroups();
  }
}
