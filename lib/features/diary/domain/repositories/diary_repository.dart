// lib/features/diary/domain/repositories/diary_repository.dart
import '../../../../data/drift_database.dart' as db;
import '../models/fluid_entry.dart';
import '../models/food_entry.dart';
import '../models/food_item.dart';
import '../../../supplements/domain/models/supplement.dart';
import '../../../supplements/domain/models/supplement_log.dart';
import '../../../workout/domain/models/workout_log.dart';

/// Abstract contract for Diary data persistence and operations.
abstract class IDiaryRepository {
  Future<db.DailyGoalsHistoryData?> getGoalsForDate(DateTime date);
  Future<List<FoodEntry>> getEntriesForDate(DateTime date);
  Future<List<FluidEntry>> getFluidEntriesForDate(DateTime date);
  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(
      DateTime start, DateTime end);
  Future<List<FoodItem>> getProductsByBarcodes(List<String> barcodes);
  Future<List<Supplement>> getSupplementsForDate(DateTime date);
  Future<List<Supplement>> getAllSupplements();
  Future<List<SupplementLog>> getSupplementLogsForDate(DateTime date);

  Future<void> deleteFoodEntry(int id);
  Future<void> deleteFluidEntry(int id);
  Future<void> deleteFluidEntryByLinkedFoodId(int linkedFoodId);

  Future<void> updateFluidEntry(FluidEntry entry);
  Future<void> updateFoodEntry(FoodEntry entry);
  Future<int> insertFluidEntry(FluidEntry entry);
  Future<int> insertFoodEntry(FoodEntry entry);
  Future<SupplementLog> insertSupplementLog(SupplementLog log);
}
