// lib/features/exercise_catalog/domain/repositories/exercise_catalog_repository.dart
import '../../../workout/domain/models/set_log.dart';
import '../models/exercise.dart';

/// Abstract contract for Exercise Catalog data persistence and operations.
abstract class IExerciseCatalogRepository {
  Future<List<Exercise>> searchExercises({
    String query = '',
    List<String> categories = const [],
    List<String> forceLevels = const [],
    String sortOrder = 'alphabetical',
  });
  Future<Exercise?> getExerciseByName(String name);
  Future<Exercise?> getExerciseByUuid(String exerciseUuid);
  Future<Exercise> insertExercise(Exercise exercise);
  Future<List<Exercise>> getCustomExercises();
  Future<void> importCustomExercises(List<Exercise> exercises);
  Future<void> applyExerciseNameMapping(Map<String, String> mapping);
  Future<String?> getExerciseUuidByLocalId(int id);
  Future<Map<String, SetLog?>> getExercisePRs(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  });
  Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
  });
  Future<List<String>> getAllCategories();
  Future<List<String>> getAllMuscleGroups();
}
