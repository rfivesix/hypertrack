// lib/features/diary/data/sources/diary_local_data_source.dart
import '../../../../data/drift_database.dart' show AppDatabase, DailyGoalsHistoryData;
import '../../../../data/database_helper.dart';
import '../../../../data/workout_database_helper.dart';
import '../../../../data/product_database_helper.dart';
import '../../domain/models/fluid_entry.dart';
import '../../domain/models/food_entry.dart';
import '../../domain/models/food_item.dart';
import '../../../supplements/domain/models/supplement.dart';
import '../../../supplements/domain/models/supplement_log.dart';
import '../../../workout/domain/models/workout_log.dart';

/// Isolated local data source for the Diary feature.
class DiaryLocalDataSource {
  final AppDatabase db;
  final DatabaseHelper _dbHelper;
  final ProductDatabaseHelper _productDbHelper;
  final WorkoutDatabaseHelper _workoutDbHelper;

  DiaryLocalDataSource(
    this.db, {
    DatabaseHelper? dbHelper,
    ProductDatabaseHelper? productDbHelper,
    WorkoutDatabaseHelper? workoutDbHelper,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _productDbHelper = productDbHelper ?? ProductDatabaseHelper.instance,
        _workoutDbHelper = workoutDbHelper ?? WorkoutDatabaseHelper.instance;

  Future<DailyGoalsHistoryData?> getGoalsForDate(DateTime date) {
    return _dbHelper.getGoalsForDate(date);
  }

  Future<List<FoodEntry>> getEntriesForDate(DateTime date) {
    return _dbHelper.getEntriesForDate(date);
  }

  Future<List<FluidEntry>> getFluidEntriesForDate(DateTime date) {
    return _dbHelper.getFluidEntriesForDate(date);
  }

  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(DateTime start, DateTime end) async {
    final list = await _workoutDbHelper.getWorkoutLogsForDateRange(start, end);
    return list.cast<WorkoutLog>();
  }

  Future<List<FoodItem>> getProductsByBarcodes(List<String> barcodes) async {
    final list = await _productDbHelper.getProductsByBarcodes(barcodes);
    return list.cast<FoodItem>();
  }

  Future<List<Supplement>> getSupplementsForDate(DateTime date) async {
    final list = await _dbHelper.getSupplementsForDate(date);
    return list.cast<Supplement>();
  }

  Future<List<Supplement>> getAllSupplements() async {
    final list = await _dbHelper.getAllSupplements();
    return list.cast<Supplement>();
  }

  Future<List<SupplementLog>> getSupplementLogsForDate(DateTime date) async {
    final list = await _dbHelper.getSupplementLogsForDate(date);
    return list.cast<SupplementLog>();
  }

  Future<void> deleteFoodEntry(int id) {
    return _dbHelper.deleteFoodEntry(id);
  }

  Future<void> deleteFluidEntry(int id) {
    return _dbHelper.deleteFluidEntry(id);
  }

  Future<void> deleteFluidEntryByLinkedFoodId(int linkedFoodId) {
    return _dbHelper.deleteFluidEntryByLinkedFoodId(linkedFoodId);
  }

  Future<void> updateFluidEntry(FluidEntry entry) {
    return _dbHelper.updateFluidEntry(entry);
  }

  Future<void> updateFoodEntry(FoodEntry entry) {
    return _dbHelper.updateFoodEntry(entry);
  }

  Future<int> insertFluidEntry(FluidEntry entry) {
    return _dbHelper.insertFluidEntry(entry);
  }

  Future<int> insertFoodEntry(FoodEntry entry) {
    return _dbHelper.insertFoodEntry(entry);
  }

  Future<SupplementLog> insertSupplementLog(SupplementLog log) {
    return _dbHelper.insertSupplementLog(log);
  }
}
