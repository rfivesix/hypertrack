// lib/features/exercise_catalog/data/exercise_catalog_repository.dart
import '../../workout/domain/models/set_log.dart';
import '../domain/models/exercise.dart';
import 'sources/exercise_catalog_local_data_source.dart';
import '../domain/repositories/exercise_catalog_repository.dart';

/// Concrete implementation of [IExerciseCatalogRepository] for managing exercises in database.
class ExerciseCatalogRepository implements IExerciseCatalogRepository {
  final ExerciseCatalogLocalDataSource _localDataSource;

  ExerciseCatalogRepository({required ExerciseCatalogLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<List<Exercise>> searchExercises({
    String query = '',
    List<String> categories = const [],
    List<String> forceLevels = const [],
    String sortOrder = 'alphabetical',
  }) {
    return _localDataSource.searchExercises(
      query: query,
      selectedCategories: categories,
    );
  }

  @override
  Future<Exercise?> getExerciseByName(String name) {
    return _localDataSource.getExerciseByName(name);
  }

  @override
  Future<Exercise?> getExerciseByUuid(String exerciseUuid) {
    return _localDataSource.getExerciseByUuid(exerciseUuid);
  }

  @override
  Future<Exercise> insertExercise(Exercise exercise) {
    return _localDataSource.insertExercise(exercise);
  }

  @override
  Future<List<Exercise>> getCustomExercises() {
    return _localDataSource.getCustomExercises();
  }

  @override
  Future<void> importCustomExercises(List<Exercise> exercises) {
    return _localDataSource.importCustomExercises(exercises);
  }

  @override
  Future<void> applyExerciseNameMapping(Map<String, String> mapping) {
    return _localDataSource.applyExerciseNameMapping(mapping);
  }

  @override
  Future<String?> getExerciseUuidByLocalId(int id) {
    return _localDataSource.getExerciseUuidByLocalId(id);
  }

  @override
  Future<Map<String, SetLog?>> getExercisePRs(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  }) {
    return _localDataSource.getExercisePRs(
      exerciseName,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  }) {
    return _localDataSource.getExerciseTimeSeriesData(
      exerciseName,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );
  }

  @override
  Future<List<String>> getAllCategories() {
    return _localDataSource.getAllCategories();
  }

  @override
  Future<List<String>> getAllMuscleGroups() {
    return _localDataSource.getAllMuscleGroups();
  }
}
