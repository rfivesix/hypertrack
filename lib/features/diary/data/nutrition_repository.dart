// lib/features/diary/data/nutrition_repository.dart
import '../domain/models/daily_goal.dart';
import 'sources/diary_local_data_source.dart';
import 'sources/product_local_data_source.dart';
import '../domain/models/fluid_entry.dart';
import '../domain/models/food_entry.dart';
import '../domain/models/food_item.dart';
import '../domain/repositories/diary_repository.dart';

/// Concrete implementation of [IDiaryRepository] implementing database transaction logic.
class NutritionRepository implements IDiaryRepository {
  final DiaryLocalDataSource _localDataSource;

  NutritionRepository({
    required DiaryLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Stream<DailyGoal?> watchGoalsForDate(DateTime date) {
    return _localDataSource.watchGoalsForDate(date).map((data) {
      if (data == null) return null;
      return DailyGoal(
        targetCalories: data.targetCalories,
        targetProtein: data.targetProtein,
        targetCarbs: data.targetCarbs,
        targetFat: data.targetFat,
        targetWater: data.targetWater,
        targetSteps: data.targetSteps,
        createdAt: data.createdAt,
      );
    });
  }

  @override
  Stream<List<FoodEntry>> watchEntriesForDate(DateTime date) =>
      _localDataSource.watchEntriesForDate(date);

  @override
  Stream<List<FluidEntry>> watchFluidEntriesForDate(DateTime date) =>
      _localDataSource.watchFluidEntriesForDate(date);

  @override
  @Deprecated('Use watchGoalsForDate instead')
  Future<DailyGoal?> getGoalsForDate(DateTime date) async {
    final data = await _localDataSource.getGoalsForDate(date);
    if (data == null) return null;
    return DailyGoal(
      targetCalories: data.targetCalories,
      targetProtein: data.targetProtein,
      targetCarbs: data.targetCarbs,
      targetFat: data.targetFat,
      targetWater: data.targetWater,
      targetSteps: data.targetSteps,
      createdAt: data.createdAt,
    );
  }

  @override
  @Deprecated('Use watchEntriesForDate instead')
  Future<List<FoodEntry>> getEntriesForDate(DateTime date) =>
      _localDataSource.getEntriesForDate(date);

  @override
  @Deprecated('Use watchFluidEntriesForDate instead')
  Future<List<FluidEntry>> getFluidEntriesForDate(DateTime date) =>
      _localDataSource.getFluidEntriesForDate(date);

  @override
  Future<List<FoodItem>> getProductsByBarcodes(List<String> barcodes) {
    return ProductLocalDataSource(_localDataSource.db)
        .getProductsByBarcodes(barcodes);
  }

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
}
