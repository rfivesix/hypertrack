// lib/features/exercise_catalog/data/exercise_catalog_repository.dart
import '../../../data/workout_database_helper.dart';
import '../../workout/domain/models/set_log.dart';
import '../domain/models/exercise.dart';

class ExerciseCatalogRepository {
  final WorkoutDatabaseHelper _dbHelper;

  WorkoutDatabaseHelper get dbHelper => _dbHelper;

  ExerciseCatalogRepository({WorkoutDatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? WorkoutDatabaseHelper.instance;

  Future<List<Exercise>> searchExercises({
    String query = '',
    List<String> categories = const [],
    List<String> forceLevels = const [],
    String sortOrder = 'alphabetical',
  }) {
    return _dbHelper.searchExercises(
      query: query,
      selectedCategories: categories,
    );
  }

  Future<Exercise?> getExerciseByName(String name) {
    return _dbHelper.getExerciseByName(name);
  }

  Future<Exercise?> getExerciseByUuid(String exerciseUuid) {
    return _dbHelper.getExerciseByUuid(exerciseUuid);
  }

  Future<Exercise> insertExercise(Exercise exercise) {
    return _dbHelper.insertExercise(exercise);
  }

  Future<List<Exercise>> getCustomExercises() {
    return _dbHelper.getCustomExercises();
  }

  Future<void> importCustomExercises(List<Exercise> exercises) {
    return _dbHelper.importCustomExercises(exercises);
  }

  Future<void> applyExerciseNameMapping(Map<String, String> mapping) {
    return _dbHelper.applyExerciseNameMapping(mapping);
  }

  Future<String?> getExerciseUuidByLocalId(int id) {
    return _dbHelper.getExerciseUuidByLocalId(id);
  }

  Future<Map<String, SetLog?>> getExercisePRs(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  }) {
    return _dbHelper.getExercisePRs(
      exerciseName,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );
  }

  Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  }) {
    return _dbHelper.getExerciseTimeSeriesData(
      exerciseName,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );
  }

  Future<List<String>> getAllCategories() {
    return _dbHelper.getAllCategories();
  }
}
