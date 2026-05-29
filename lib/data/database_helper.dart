// lib/data/database_helper.dart

import 'package:drift/drift.dart' as drift;
import 'drift_database.dart' as db;
import '../features/diary/domain/models/fluid_entry.dart';
import '../features/diary/domain/models/food_entry.dart';
import '../features/profile/domain/models/measurement_session.dart';
import '../features/supplements/domain/models/supplement.dart';
import '../features/supplements/domain/models/supplement_log.dart';
import '../features/analytics/domain/models/chart_data_point.dart';

import '../features/diary/data/sources/diary_local_data_source.dart';
import '../features/diary/data/sources/meal_local_data_source.dart';
import '../features/profile/data/sources/profile_local_data_source.dart';
import '../features/supplements/data/sources/supplement_local_data_source.dart';
import '../features/steps/data/sources/steps_local_data_source.dart';
import '../features/diary/data/sources/product_local_data_source.dart';
import '../features/workout/data/sources/workout_local_data_source.dart';

class FoodCaloriesByDayResult {
  final Map<DateTime, double> caloriesByDay;
  final int unresolvedEntryCount;

  const FoodCaloriesByDayResult({
    required this.caloriesByDay,
    required this.unresolvedEntryCount,
  });
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static db.AppDatabase? _driftDb;
  final db.AppDatabase? _injectedDb;
  DatabaseHelper._init() : _injectedDb = null;
  DatabaseHelper.forTesting(db.AppDatabase database) : _injectedDb = database;

  static void setDriftDb(db.AppDatabase database) {
    _driftDb = database;
  }

  db.AppDatabase get dbInstance =>
      _injectedDb ?? (_driftDb ??= db.AppDatabase());

  Future<db.AppDatabase> get database async => dbInstance;

  Future<void> clearAllUserData() async {
    final dbInst = dbInstance;
    await dbInst.customStatement('PRAGMA foreign_keys = OFF');
    try {
      await dbInst.transaction(() async {
        await dbInst.delete(dbInst.dailyGoalsHistory).go();
        await dbInst.delete(dbInst.supplementSettingsHistory).go();
        await dbInst.customStatement('DELETE FROM health_step_segments');
        await dbInst.customStatement('DELETE FROM health_export_records');
        await dbInst.delete(dbInst.supplementLogs).go();
        await dbInst.delete(dbInst.fluidLogs).go();
        await dbInst.delete(dbInst.nutritionLogs).go();
        await dbInst.delete(dbInst.measurements).go();
        await dbInst.delete(dbInst.mealItems).go();
        await dbInst.delete(dbInst.favorites).go();
        await dbInst.delete(dbInst.supplements).go();
        await dbInst.delete(dbInst.meals).go();
        await dbInst.delete(dbInst.appSettings).go();
        await dbInst.delete(dbInst.profiles).go();
        await (dbInst.delete(dbInst.products)
              ..where((t) => t.source.equals('user')))
            .go();
      });
    } finally {
      await dbInst.customStatement('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> importUserData(
      {required List<FoodEntry> foodEntries,
      required List<FluidEntry> fluidEntries,
      required List<String> favoriteBarcodes,
      required List<MeasurementSession> measurementSessions,
      required List<Supplement> supplements,
      required List<SupplementLog> supplementLogs}) async {
    final dbInst = dbInstance;
    await dbInst.batch((batch) {
      for (final b in favoriteBarcodes) {
        batch.insert(
            dbInst.favorites,
            db.FavoritesCompanion.insert(
                barcode: b, createdAt: drift.Value(DateTime.now())),
            mode: drift.InsertMode.insertOrReplace);
      }
      for (final s in supplements) {
        batch.insert(
          dbInst.supplements,
          db.SupplementsCompanion(
            name: drift.Value(s.name),
            dose: drift.Value(s.defaultDose),
            unit: drift.Value(s.unit),
            dailyGoal: drift.Value(s.dailyGoal),
            dailyLimit: drift.Value(s.dailyLimit),
            isTracked: drift.Value(s.isTracked),
            createdAt: drift.Value(DateTime.now()),
            updatedAt: drift.Value(DateTime.now()),
            id: s.id != null
                ? drift.Value(s.id.toString())
                : const drift.Value.absent(),
            localId:
                s.id != null ? drift.Value(s.id!) : const drift.Value.absent(),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }
      for (final e in foodEntries) {
        batch.insert(
            dbInst.nutritionLogs,
            db.NutritionLogsCompanion.insert(
                legacyBarcode: drift.Value(e.barcode),
                consumedAt: e.timestamp,
                amount: e.quantityInGrams.toDouble(),
                mealType: drift.Value(e.mealType)),
            mode: drift.InsertMode.insertOrReplace);
      }
      for (final e in fluidEntries) {
        batch.insert(
            dbInst.fluidLogs,
            db.FluidLogsCompanion.insert(
                consumedAt: e.timestamp,
                amountMl: e.quantityInMl,
                name: e.name,
                kcal: drift.Value(e.kcal),
                sugarPer100ml: drift.Value(e.sugarPer100ml),
                caffeinePer100ml: drift.Value(e.caffeinePer100ml)),
            mode: drift.InsertMode.insertOrReplace);
      }
      for (final s in measurementSessions) {
        for (final m in s.measurements) {
          batch.insert(
              dbInst.measurements,
              db.MeasurementsCompanion.insert(
                  type: m.type,
                  value: m.value,
                  unit: m.unit,
                  date: s.timestamp),
              mode: drift.InsertMode.insertOrReplace);
        }
      }
      for (final l in supplementLogs) {
        batch.insert(
            dbInst.supplementLogs,
            db.SupplementLogsCompanion.insert(
                supplementId: l.supplementId.toString(),
                amount: l.dose,
                takenAt: l.timestamp),
            mode: drift.InsertMode.insertOrReplace);
      }
    });
  }

  // --- Dynamic Local Data Source Getters ---
  DiaryLocalDataSource get diaryLocalDataSource =>
      DiaryLocalDataSource(dbInstance);

  ProductLocalDataSource get productLocalDataSource =>
      ProductLocalDataSource(dbInstance);

  WorkoutLocalDataSource get workoutLocalDataSource =>
      WorkoutLocalDataSource(dbInstance);

  ProfileLocalDataSource get profileLocalDataSource =>
      ProfileLocalDataSource(dbInstance);

  SupplementLocalDataSource get supplementLocalDataSource =>
      SupplementLocalDataSource(dbInstance);

  MealLocalDataSource get mealLocalDataSource =>
      MealLocalDataSource(dbInstance);

  StepsLocalDataSource get stepsLocalDataSource =>
      StepsLocalDataSource(dbInstance);

  // Proxies
  Future<int> insertFoodEntry(FoodEntry entry) =>
      diaryLocalDataSource.insertFoodEntry(entry);
  Future<int> insertFluidEntry(FluidEntry entry) =>
      diaryLocalDataSource.insertFluidEntry(entry);
  Future<void> deleteFluidEntryByLinkedFoodId(int id) =>
      diaryLocalDataSource.deleteFluidEntryByLinkedFoodId(id);
  Future<db.DailyGoalsHistoryData?> getGoalsForDate(DateTime date) =>
      diaryLocalDataSource.getGoalsForDate(date);
  Future<Map<String, int>> getRemainingMacrosForDate(DateTime date) =>
      diaryLocalDataSource.getRemainingMacrosForDate(date);
  Future<List<FoodEntry>> getAllFoodEntries() =>
      diaryLocalDataSource.getAllFoodEntries();
  Future<List<FluidEntry>> getAllFluidEntries() =>
      diaryLocalDataSource.getAllFluidEntries();
  Future<List<FoodEntry>> getEntriesForDateRange(DateTime start, DateTime end,
          {DateTime? updatedSince}) =>
      diaryLocalDataSource.getEntriesForDateRange(start, end,
          updatedSince: updatedSince);
  Future<List<FluidEntry>> getFluidEntriesForDateRange(
          DateTime start, DateTime end, {DateTime? updatedSince}) =>
      diaryLocalDataSource.getFluidEntriesForDateRange(start, end,
          updatedSince: updatedSince);
  Future<FoodCaloriesByDayResult> getFoodCaloriesByDayForDateRange(
          DateTime start, DateTime end) =>
      diaryLocalDataSource.getFoodCaloriesByDayForDateRange(start, end);
  Future<DateTime?> getEarliestFoodEntryDate() async {
    final logs = await getAllFoodEntries();
    if (logs.isEmpty) return null;
    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return logs.first.timestamp;
  }

  Future<DateTime?> getEarliestFluidEntryDate() async {
    final logs = await getAllFluidEntries();
    if (logs.isEmpty) return null;
    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return logs.first.timestamp;
  }

  // Restored proxy methods for test backward compatibility
  Future<List<FoodEntry>> getEntriesForDate(DateTime date) =>
      diaryLocalDataSource.getEntriesForDate(date);
  Future<List<FoodEntry>> getAllFoodEntriesForBackup() =>
      diaryLocalDataSource.getAllFoodEntriesForBackup();
  Future<List<Supplement>> getSupplementsForDate(DateTime date) =>
      diaryLocalDataSource.getSupplementsForDate(date);
  Future<void> deleteFluidEntry(int id) =>
      diaryLocalDataSource.deleteFluidEntry(id);
  Future<void> updateFluidEntry(FluidEntry entry) =>
      diaryLocalDataSource.updateFluidEntry(entry);
  Future<void> deleteFoodEntry(int id) =>
      diaryLocalDataSource.deleteFoodEntry(id);
  Future<void> updateFoodEntry(FoodEntry entry) =>
      diaryLocalDataSource.updateFoodEntry(entry);

  Future<void> ensureStandardSupplements() =>
      supplementLocalDataSource.ensureStandardSupplements();
  Future<void> logSupplement(dynamic id, [double? d, DateTime? t]) =>
      (id is int && d != null)
          ? supplementLocalDataSource.logSupplement(
              supplementId: id, dose: d, takenAt: t)
          : supplementLocalDataSource.insertSupplementLog(id as dynamic);
  Future<void> insertSupplementLog(dynamic id, [double? d, DateTime? t]) =>
      (id is SupplementLog)
          ? supplementLocalDataSource.insertSupplementLog(id)
          : supplementLocalDataSource.logSupplement(
              supplementId: id as int, dose: d!, takenAt: t);
  Future<List<Supplement>> getAllSupplements() =>
      supplementLocalDataSource.getAllSupplements();
  Future<int> insertSupplement(dynamic n, [double? d, String? u, double? l]) =>
      (n is Supplement)
          ? supplementLocalDataSource.insertSupplement(n)
          : supplementLocalDataSource.insertSupplement(Supplement(
              name: n as String,
              defaultDose: d!,
              unit: u!,
              dailyLimit: l,
            ));

  Future<bool> isFavorite(String b) => productLocalDataSource.isFavorite(b);
  Future<void> addFavorite(String b) => productLocalDataSource.addFavorite(b);
  Future<void> removeFavorite(String b) =>
      productLocalDataSource.removeFavorite(b);
  Future<List<String>> getFavoriteBarcodes() =>
      productLocalDataSource.getFavoriteBarcodes();

  Future<List<Map<String, dynamic>>> getMeals() =>
      mealLocalDataSource.getMeals();
  Future<List<Map<String, dynamic>>> getMealItems(int id) =>
      mealLocalDataSource.getMealItems(id);
  Future<int> insertMeal({dynamic name, String? notes}) => (name is String)
      ? mealLocalDataSource.insertMeal(name: name, notes: notes)
      : mealLocalDataSource.insertMeal(
          name: (name as dynamic).name, notes: (name as dynamic).notes);
  Future<void> updateMeal(dynamic id, {String? name, String? notes}) =>
      (id is int && name != null)
          ? mealLocalDataSource.updateMeal(id, name: name, notes: notes)
          : mealLocalDataSource.updateMeal((id as dynamic).id,
              name: (id as dynamic).name, notes: (id as dynamic).notes);
  Future<void> deleteMeal(int id) => mealLocalDataSource.deleteMeal(id);
  Future<void> clearMealItems(int id) => mealLocalDataSource.clearMealItems(id);
  Future<int> addMealItem(
          {required int mealId,
          required String barcode,
          required double amount}) =>
      mealLocalDataSource.addMealItem(
          mealId: mealId, barcode: barcode, amount: amount);
  Future<List<Map<String, dynamic>>> getMealTemplatesForBackup() =>
      mealLocalDataSource.getMealTemplatesForBackup();

  Future<int?> getDailyStepsTotal(
          {dynamic dayLocal,
          String providerFilter = 'all',
          String sourcePolicy = 'all'}) =>
      (dayLocal is DateTime)
          ? stepsLocalDataSource.getDailyStepsTotal(
              dayLocal: dayLocal,
              providerFilter: providerFilter,
              sourcePolicy: sourcePolicy)
          : stepsLocalDataSource.getDailyStepsTotal(
              dayLocal: (dayLocal as dynamic).dayLocal,
              providerFilter:
                  (dayLocal as dynamic).providerFilter ?? providerFilter,
              sourcePolicy: (dayLocal as dynamic).sourcePolicy ?? sourcePolicy);
  Future<void> upsertHealthStepSegments(
          List<db.HealthStepSegmentsCompanion> s) =>
      stepsLocalDataSource.upsertHealthStepSegments(s);
  Future<void> markHealthExported(
          {String? key,
          String? type,
          String? platform,
          String? domain,
          List<String>? idempotencyKeys}) =>
      stepsLocalDataSource.markHealthExported(
          platform: platform ?? 'ios',
          domain: domain ?? type ?? '',
          idempotencyKeys: idempotencyKeys ?? (key != null ? [key] : []));
  Future<List<String>> getExportedHealthKeys(
          {String? type,
          String? platform,
          String? domain,
          List<String>? idempotencyKeys}) =>
      stepsLocalDataSource.getExportedHealthKeys(
          platform: platform ?? 'ios',
          domain: domain ?? type ?? '',
          idempotencyKeys: idempotencyKeys ?? []);
  Future<List<Map<String, dynamic>>> getDailyStepsTotalsForRange(
          {required DateTime startLocal,
          required DateTime endLocal,
          String providerFilter = 'all',
          String sourcePolicy = 'all'}) =>
      stepsLocalDataSource.getDailyStepsTotalsForRange(
          startLocal: startLocal,
          endLocal: endLocal,
          providerFilter: providerFilter,
          sourcePolicy: sourcePolicy);
  Future<List<Map<String, dynamic>>> getHourlyStepsTotalsForDay(
          {required DateTime dayLocal,
          String providerFilter = 'all',
          String sourcePolicy = 'all'}) =>
      stepsLocalDataSource.getHourlyStepsTotalsForDay(
          dayLocal: dayLocal,
          providerFilter: providerFilter,
          sourcePolicy: sourcePolicy);
  Future<DateTime?> getEarliestHealthStepsDateLocal(
          {String providerFilter = 'all'}) =>
      stepsLocalDataSource.getEarliestHealthStepsDateLocal(
          providerFilter: providerFilter);

  Future<List<MeasurementSession>> getMeasurementSessions(
          {DateTime? updatedSince}) =>
      profileLocalDataSource.getMeasurementSessions(updatedSince: updatedSince);
  Future<List<ChartDataPoint>> getChartDataForTypeAndRange(String t, dynamic r,
      [DateTime? e]) async {
    final raw =
        await profileLocalDataSource.getChartDataForTypeAndRange(t, r, e);
    return raw
        .map((item) => ChartDataPoint(
              date: item['date'] as DateTime,
              value: (item['value'] as num).toDouble(),
            ))
        .toList();
  }

  Future<db.Profile?> getUserProfile() =>
      profileLocalDataSource.getUserProfile();
  Future<db.AppSetting?> getAppSettings() =>
      profileLocalDataSource.getAppSettings();
  Future<int> getCurrentTargetStepsOrDefault() =>
      profileLocalDataSource.getCurrentTargetStepsOrDefault();
  Future<void> saveUserGoals(
          {int? calorieGoal,
          int? proteinGoal,
          int? carbGoal,
          int? fatGoal,
          int? waterGoal,
          int? stepsGoal,
          int? calories,
          int? protein,
          int? carbs,
          int? fat,
          int? water,
          int? steps}) =>
      profileLocalDataSource.saveUserGoals(
          calories: calorieGoal ?? calories ?? 2000,
          protein: proteinGoal ?? protein ?? 150,
          carbs: carbGoal ?? carbs ?? 250,
          fat: fatGoal ?? fat ?? 70,
          water: waterGoal ?? water ?? 2000,
          steps: stepsGoal ?? steps ?? 8000);
  Future<double?> getLatestWeight() async {
    final sessions = await getMeasurementSessions();
    for (final session in sessions) {
      final m = session.measurements.where((m) => m.type == 'weight').firstOrNull;
      if (m != null) return m.value;
    }
    return null;
  }

  Future<double?> getLatestBodyFatPercentageBefore(DateTime b) =>
      profileLocalDataSource.getLatestBodyFatPercentageBefore(b);
  Future<void> saveUserProfile(
          {String? name,
          double? weight,
          int? height,
          int? age,
          String? gender,
          String? activityLevel,
          String? goal,
          DateTime? birthday,
          String? username}) =>
      profileLocalDataSource.saveUserProfile(
          name: name ?? username ?? 'User',
          weight: weight ?? 70.0,
          height: (height ?? 175).toDouble(),
          age: age ?? 30,
          gender: gender ?? 'other',
          activityLevel: activityLevel ?? 'sedentary',
          goal: goal ?? 'maintenance',
          birthday: birthday);
  Future<void> saveInitialWeight(double w) =>
      profileLocalDataSource.saveInitialWeight(w);
  Future<void> saveInitialBodyFatPercentage(double b) =>
      profileLocalDataSource.saveInitialBodyFatPercentage(b);
  Future<DateTime?> getEarliestMeasurementDate() =>
      profileLocalDataSource.getEarliestMeasurementDate();
  Future<void> deleteMeasurementSession(int id) =>
      profileLocalDataSource.deleteMeasurementSession(id);
  Future<int> insertMeasurementSession(MeasurementSession s) =>
      profileLocalDataSource.insertMeasurementSession(s);

  Future<double> getAverageCompletedWorkoutsPerWeek(
          {int weeksBack = 4, DateTime? now}) =>
      workoutLocalDataSource.getAverageCompletedWorkoutsPerWeek(
          weeksBack: weeksBack, now: now);
}
