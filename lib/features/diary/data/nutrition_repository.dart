// lib/features/diary/data/nutrition_repository.dart
import 'sources/diary_local_data_source.dart';
import '../domain/models/fluid_entry.dart';
import '../domain/models/food_entry.dart';
import '../domain/models/food_item.dart';
import '../domain/repositories/diary_repository.dart';
import '../../supplements/domain/models/supplement.dart';
import '../../supplements/domain/models/supplement_log.dart';
import '../../workout/domain/models/workout_log.dart';
import '../../../data/drift_database.dart' as db;

/// Concrete implementation of [IDiaryRepository] implementing database transaction logic.
class NutritionRepository implements IDiaryRepository {
  final DiaryLocalDataSource _localDataSource;

  NutritionRepository({
    required DiaryLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<db.DailyGoalsHistoryData?> getGoalsForDate(DateTime date) =>
      _localDataSource.getGoalsForDate(date);

  @override
  Future<List<FoodEntry>> getEntriesForDate(DateTime date) =>
      _localDataSource.getEntriesForDate(date);

  @override
  Future<List<FluidEntry>> getFluidEntriesForDate(DateTime date) =>
      _localDataSource.getFluidEntriesForDate(date);

  @override
  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(
          DateTime start, DateTime end) =>
      _localDataSource.getWorkoutLogsForDateRange(start, end);

  @override
  Future<List<FoodItem>> getProductsByBarcodes(List<String> barcodes) =>
      _localDataSource.getProductsByBarcodes(barcodes);

  @override
  Future<List<Supplement>> getSupplementsForDate(DateTime date) =>
      _localDataSource.getSupplementsForDate(date);

  @override
  Future<List<Supplement>> getAllSupplements() =>
      _localDataSource.getAllSupplements();

  @override
  Future<List<SupplementLog>> getSupplementLogsForDate(DateTime date) =>
      _localDataSource.getSupplementLogsForDate(date);

  @override
  Future<void> deleteFoodEntry(int id) => _localDataSource.deleteFoodEntry(id);

  @override
  Future<void> deleteFluidEntry(int id) =>
      _localDataSource.deleteFluidEntry(id);

  @override
  Future<void> deleteFluidEntryByLinkedFoodId(int linkedFoodId) =>
      _localDataSource.deleteFluidEntryByLinkedFoodId(linkedFoodId);

  @override
  Future<void> updateFluidEntry(FluidEntry entry) =>
      _localDataSource.updateFluidEntry(entry);

  @override
  Future<void> updateFoodEntry(FoodEntry entry) =>
      _localDataSource.updateFoodEntry(entry);

  @override
  Future<int> insertFluidEntry(FluidEntry entry) =>
      _localDataSource.insertFluidEntry(entry);

  @override
  Future<int> insertFoodEntry(FoodEntry entry) =>
      _localDataSource.insertFoodEntry(entry);

  @override
  Future<SupplementLog> insertSupplementLog(SupplementLog log) async {
    return _localDataSource.insertSupplementLog(log);
  }
}
