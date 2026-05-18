// lib/features/diary/domain/repositories/diary_repository.dart
import '../models/daily_goal.dart';
import '../models/fluid_entry.dart';
import '../models/food_entry.dart';
import '../models/food_item.dart';

/// Abstract contract for Diary data persistence and operations.
abstract class IDiaryRepository {
  Future<DailyGoal?> getGoalsForDate(DateTime date);
  Future<List<FoodEntry>> getEntriesForDate(DateTime date);
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
