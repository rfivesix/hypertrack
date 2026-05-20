// lib/features/diary/domain/repositories/diary_repository.dart
import '../models/daily_goal.dart';
import '../models/fluid_entry.dart';
import '../models/food_entry.dart';
import '../models/food_item.dart';

/// Abstract contract for Diary data persistence and operations.
abstract class IDiaryRepository {
  Stream<DailyGoal?> watchGoalsForDate(DateTime date);
  Stream<List<FoodEntry>> watchEntriesForDate(DateTime date);
  Stream<List<FluidEntry>> watchFluidEntriesForDate(DateTime date);

  @Deprecated('Use watchGoalsForDate instead')
  Future<DailyGoal?> getGoalsForDate(DateTime date);

  @Deprecated('Use watchEntriesForDate instead')
  Future<List<FoodEntry>> getEntriesForDate(DateTime date);

  @Deprecated('Use watchFluidEntriesForDate instead')
  Future<List<FluidEntry>> getFluidEntriesForDate(DateTime date);

  Future<List<FoodItem>> getProductsByBarcodes(List<String> barcodes);

  Future<void> deleteFoodEntry(int id);
  Future<void> deleteFluidEntry(int id);
  Future<void> deleteFluidEntryByLinkedFoodId(int linkedFoodId);

  Future<void> updateFluidEntry(FluidEntry entry);
  Future<void> updateFoodEntry(FoodEntry entry);
  Future<int> insertFluidEntry(FluidEntry entry);
  Future<int> insertFoodEntry(FoodEntry entry);
}
