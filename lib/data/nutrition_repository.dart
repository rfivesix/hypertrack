import '../data/database_helper.dart';
import '../data/product_database_helper.dart';
import '../data/workout_database_helper.dart';
import '../models/fluid_entry.dart';
import '../models/food_entry.dart';
import '../models/food_item.dart';
import '../models/supplement.dart';
import '../models/supplement_log.dart';
import '../models/workout_log.dart';
import 'drift_database.dart' as db;

class NutritionRepository {
  static final NutritionRepository instance = NutritionRepository._init();
  NutritionRepository._init();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final ProductDatabaseHelper _productDb = ProductDatabaseHelper.instance;
  final WorkoutDatabaseHelper _workoutDb = WorkoutDatabaseHelper.instance;

  Future<db.DailyGoalsHistoryData?> getGoalsForDate(DateTime date) => _db.getGoalsForDate(date);
  Future<List<FoodEntry>> getEntriesForDate(DateTime date) => _db.getEntriesForDate(date);
  Future<List<FluidEntry>> getFluidEntriesForDate(DateTime date) => _db.getFluidEntriesForDate(date);
  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(DateTime start, DateTime end) => _workoutDb.getWorkoutLogsForDateRange(start, end);
  Future<List<FoodItem>> getProductsByBarcodes(List<String> barcodes) => _productDb.getProductsByBarcodes(barcodes);
  Future<List<Supplement>> getSupplementsForDate(DateTime date) => _db.getSupplementsForDate(date);
  Future<List<Supplement>> getAllSupplements() => _db.getAllSupplements();
  Future<List<SupplementLog>> getSupplementLogsForDate(DateTime date) => _db.getSupplementLogsForDate(date);

  Future<void> deleteFoodEntry(int id) => _db.deleteFoodEntry(id);
  Future<void> deleteFluidEntry(int id) => _db.deleteFluidEntry(id);
  Future<void> deleteFluidEntryByLinkedFoodId(int linkedFoodId) => _db.deleteFluidEntryByLinkedFoodId(linkedFoodId);

  Future<void> updateFluidEntry(FluidEntry entry) => _db.updateFluidEntry(entry);
  Future<void> updateFoodEntry(FoodEntry entry) => _db.updateFoodEntry(entry);
  Future<int> insertFluidEntry(FluidEntry entry) => _db.insertFluidEntry(entry);
  Future<int> insertFoodEntry(FoodEntry entry) => _db.insertFoodEntry(entry);
  Future<SupplementLog> insertSupplementLog(SupplementLog log) async {
    return _db.insertSupplementLog(log);
  }
}
