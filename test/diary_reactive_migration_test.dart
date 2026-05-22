import 'dart:async';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart'
    hide SupplementLog, Supplement, WorkoutLog, SetLog, Routine, Exercise;
import 'package:train_libre/features/diary/data/sources/diary_local_data_source.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/diary/data/nutrition_repository.dart';
import 'package:train_libre/features/diary/domain/repositories/diary_repository.dart';
import 'package:train_libre/features/diary/domain/models/food_entry.dart';
import 'package:train_libre/features/diary/domain/models/fluid_entry.dart';
import 'package:train_libre/features/diary/presentation/diary_view_model.dart';
import 'package:train_libre/features/supplements/domain/repositories/supplement_repository.dart';
import 'package:train_libre/features/supplements/domain/models/supplement.dart';
import 'package:train_libre/features/supplements/domain/models/supplement_log.dart';
import 'package:train_libre/features/workout/domain/repositories/workout_repository.dart';
import 'package:train_libre/features/workout/domain/models/workout_log.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/routine.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/data/workout_repository.dart';

class FakeSupplementRepository implements SupplementRepository {
  final supplementsController = StreamController<List<Supplement>>.broadcast();
  final supplementLogsController = StreamController<List<SupplementLog>>.broadcast();

  @override
  Stream<List<Supplement>> watchAllSupplements() => Stream.value([]);
  @override
  Stream<List<Supplement>> watchSupplementsForDate(DateTime date) => supplementsController.stream;
  @override
  Stream<List<SupplementLog>> watchSupplementLogsForDate(DateTime date) => supplementLogsController.stream;

  @override
  Future<List<Supplement>> getAllSupplements() async => [];
  @override
  Future<List<Supplement>> getSupplementsForDate(DateTime date) async => [];
  @override
  Future<List<SupplementLog>> getSupplementLogsForDate(DateTime date) async => [];

  @override
  Future<int> insertSupplement(Supplement supplement) async => 0;
  @override
  Future<void> updateSupplement(Supplement supplement) async {}
  @override
  Future<void> deleteSupplement(int id) async {}
  @override
  Future<void> insertSupplementLog(SupplementLog log) async {}
  @override
  Future<void> updateSupplementLog(SupplementLog log) async {}
  @override
  Future<void> deleteSupplementLog(int id) async {}
  @override
  Future<void> deleteCaffeineLogByFoodEntryId(int foodEntryId) async {}
  @override
  Future<void> deleteCaffeineLogByFluidEntryId(int fluidEntryId) async {}
}

class FakeWorkoutRepository implements IWorkoutRepository {
  final workoutLogsController = StreamController<List<WorkoutLog>>.broadcast();

  @override
  Future<WorkoutLog?> getOngoingWorkout() async => null;
  @override
  Future<int> insertSetLog(SetLog log) async => 0;
  @override
  Future<List<SetLog>> getSetLogsForWorkout(int workoutLogId) async => [];
  @override
  Future<Routine?> getRoutineByName(String name) async => null;
  @override
  Future<Exercise?> resolveExerciseForSetLog(SetLog log) async => null;
  @override
  Future<Exercise?> getExerciseByName(String name) async => null;
  @override
  Future<String?> getExerciseUuidByLocalId(int localId) async => null;
  @override
  Future<Map<String, double>> getExerciseBests(String name, {String? altName, String? exerciseUuid}) async => {};
  @override
  Future<void> updateSetLogs(List<SetLog> logs) async {}
  @override
  Future<void> deleteSetLogs(List<int> ids) async {}
  @override
  Future<void> finishWorkout(int logId, {String? title, String? notes}) async {}
  @override
  Future<void> updatePauseTime(int routineExerciseId, int? seconds) async {}
  @override
  Future<void> updateRoutineExerciseNotes(int routineExerciseId, String? notes) async {}
  @override
  Future<void> saveWorkoutExerciseNote({required int workoutLogId, required String exerciseName, required String? notes}) async {}
  @override
  Future<Map<String, String>> getWorkoutExerciseNotes(int workoutLogId) async => {};
  @override
  Future<List<SetLog>> getLastSetsForExercise(String exerciseName) async => [];
  @override
  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(DateTime start, DateTime end) async => [];
  @override
  Stream<List<WorkoutLog>> watchFullWorkoutLogs() => Stream.value([]);
  @override
  Stream<List<SetLog>> watchSetLogsForWorkout(int workoutLogId) => Stream.value([]);
  @override
  Stream<List<Routine>> watchAllRoutines() => Stream.value([]);
  Stream<List<WorkoutLog>> Function(DateTime start, DateTime end)? watchWorkoutLogsForDateRangeMock;

  @override
  Stream<List<WorkoutLog>> watchWorkoutLogsForDateRange(DateTime start, DateTime end) {
    if (watchWorkoutLogsForDateRangeMock != null) {
      return watchWorkoutLogsForDateRangeMock!(start, end);
    }
    return workoutLogsController.stream;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Diary Module Reactive Migration Pass', () {
    late AppDatabase database;
    late DiaryLocalDataSource localDataSource;
    late IDiaryRepository repository;
    late DiaryViewModel viewModel;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      DatabaseHelper.setDriftDb(database);
      localDataSource = DiaryLocalDataSource(database);
      repository = NutritionRepository(localDataSource: localDataSource);
      final workoutDataSource = WorkoutLocalDataSource(database);
      viewModel = DiaryViewModel(
        nutritionRepo: repository,
        supplementRepo: FakeSupplementRepository(),
        workoutRepo: WorkoutRepository(localDataSource: workoutDataSource),
      );
    });

    tearDown(() async {
      viewModel.dispose();
      await database.close();
    });

    test('DiaryLocalDataSource.watchEntriesForDate propagates writes reactively', () async {
      final date = DateTime(2026, 5, 19);
      final stream = localDataSource.watchEntriesForDate(date);
      final emissions = [];
      final sub = stream.listen((event) => emissions.add(event));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, isEmpty);

      await localDataSource.insertFoodEntry(
        FoodEntry(
          barcode: '12345678',
          timestamp: date,
          quantityInGrams: 150,
          mealType: 'mealtypeBreakfast',
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, hasLength(1));

      await sub.cancel();
    });

    test('DiaryLocalDataSource.watchFluidEntriesForDate propagates writes reactively', () async {
      final date = DateTime(2026, 5, 19);
      final stream = localDataSource.watchFluidEntriesForDate(date);
      final emissions = [];
      final sub = stream.listen((event) => emissions.add(event));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, isEmpty);

      await localDataSource.insertFluidEntry(
        FluidEntry(
          name: 'Water',
          quantityInMl: 250,
          timestamp: date,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, hasLength(1));

      await sub.cancel();
    });

    test('DiaryViewModel updates nutrition and fluid entries reactively without manual triggers', () async {
      final date = DateTime(2026, 5, 19);
      viewModel.setSelectedDate(date);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(viewModel.fluidEntries, isEmpty);

      // Mutate water via view model - does NOT call manual reload
      await viewModel.insertFluidEntry(
        FluidEntry(
          name: 'Water',
          quantityInMl: 250,
          timestamp: date,
        ),
      );

      // Wait a moment for stream delivery
      await Future.delayed(const Duration(milliseconds: 100));

      expect(viewModel.fluidEntries, hasLength(1));
      expect(viewModel.fluidEntries.first.quantityInMl, 250);
    });

    test('DiaryViewModel updates completed workouts reactively on local database insert', () async {
      final date = DateTime(2026, 5, 19);
      viewModel.setSelectedDate(date);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(viewModel.workoutSummary, isNull);

      // Insert completed workout directly into real test Drift DB
      await database.into(database.workoutLogs).insert(
        WorkoutLogsCompanion(
          startTime: drift.Value(date),
          endTime: drift.Value(date.add(const Duration(minutes: 60))),
          status: const drift.Value('completed'),
          routineNameSnapshot: const drift.Value('Reactive Hypertrophy'),
        ),
      );

      // Wait for Drift stream emission
      await Future.delayed(const Duration(milliseconds: 100));

      expect(viewModel.workoutSummary, isNotNull);
      expect(viewModel.workoutSummary!['count'], equals(1));
    });

    test('DiaryViewModel updates supplements reactively when supplement logs emit', () async {
      final date = DateTime(2026, 5, 19);
      viewModel.setSelectedDate(date);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(viewModel.trackedSupplements, isEmpty);

      // Setup fake streams to emit items
      final repo = viewModel.supplementRepo;
      if (repo is FakeSupplementRepository) {
        repo.supplementsController.add([
          Supplement(id: 1, name: 'Creatine', defaultDose: 5, unit: 'g', code: 'creatine_monohydrate'),
        ]);
        repo.supplementLogsController.add([
          SupplementLog(id: 1, supplementId: 1, dose: 5, unit: 'g', timestamp: date),
        ]);
      }

      // Wait for stream emission and use case calculation
      await Future.delayed(const Duration(milliseconds: 150));

      expect(viewModel.trackedSupplements, isNotEmpty);
      expect(viewModel.trackedSupplements.first.supplement.name, equals('Creatine'));
      expect(viewModel.trackedSupplements.first.totalDosedToday, equals(5.0));
    });

    test('watchFullWorkoutLogs emits completed logs reactively on DB insert', () async {
      final date = DateTime(2026, 5, 19);
      final workoutDataSource = WorkoutLocalDataSource(database);
      final stream = workoutDataSource.watchFullWorkoutLogs();

      final emissions = <List<WorkoutLog>>[];
      final sub = stream.listen(emissions.add);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, isEmpty);

      // Insert a completed workout
      await database.into(database.workoutLogs).insert(
        WorkoutLogsCompanion(
          startTime: drift.Value(date),
          endTime: drift.Value(date.add(const Duration(minutes: 60))),
          status: const drift.Value('completed'),
          routineNameSnapshot: const drift.Value('Reactive Hypertrophy'),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      expect(emissions.last, hasLength(1));
      expect(emissions.last.first.routineName, equals('Reactive Hypertrophy'));

      await sub.cancel();
    });

    test('watchAllRoutines emits routines reactively on DB insert', () async {
      final workoutDataSource = WorkoutLocalDataSource(database);
      final stream = workoutDataSource.watchAllRoutines();

      final emissions = <List<Routine>>[];
      final sub = stream.listen(emissions.add);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emissions.last, isEmpty);

      // Insert a new routine
      await database.into(database.routines).insert(
        RoutinesCompanion(
          name: const drift.Value('Powerbuilding Day A'),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      expect(emissions.last, hasLength(1));
      expect(emissions.last.first.name, equals('Powerbuilding Day A'));

      await sub.cancel();
    });

    test('DiaryViewModel rapid date switches cancel old subscriptions and prevent stale processing', () async {
      final dateA = DateTime(2026, 5, 19);
      final dateB = DateTime(2026, 5, 20);

      final workoutControllerA = StreamController<List<WorkoutLog>>.broadcast();
      final workoutControllerB = StreamController<List<WorkoutLog>>.broadcast();

      final fakeWorkoutRepo = FakeWorkoutRepository();
      fakeWorkoutRepo.watchWorkoutLogsForDateRangeMock = (start, end) {
        if (start.year == dateA.year && start.month == dateA.month && start.day == dateA.day) {
          return workoutControllerA.stream;
        } else {
          return workoutControllerB.stream;
        }
      };

      final testVM = DiaryViewModel(
        nutritionRepo: repository,
        supplementRepo: FakeSupplementRepository(),
        workoutRepo: fakeWorkoutRepo,
        initialDate: dateA,
      );

      // Initially selected dateA
      await Future.delayed(const Duration(milliseconds: 10));

      // Switch rapidly to dateB
      testVM.setSelectedDate(dateB);
      await Future.delayed(const Duration(milliseconds: 10));

      // Emission on old dateA should NOT update view model
      workoutControllerA.add([
        WorkoutLog(
          id: 1,
          routineName: 'Stale Workout',
          startTime: dateA,
          endTime: dateA.add(const Duration(minutes: 45)),
        )
      ]);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(testVM.workoutSummary, isNull);

      // Emission on new dateB should update view model
      workoutControllerB.add([
        WorkoutLog(
          id: 2,
          routineName: 'Current Workout',
          startTime: dateB,
          endTime: dateB.add(const Duration(minutes: 45)),
        )
      ]);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(testVM.workoutSummary, isNotNull);
      expect(testVM.workoutSummary!['count'], equals(1));

      await workoutControllerA.close();
      await workoutControllerB.close();
      testVM.dispose();
    });
  });
}
