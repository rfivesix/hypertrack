import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/steps/data/steps_aggregation_repository.dart';
import 'package:train_libre/features/steps/presentation/steps_module_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/features/workout/presentation/live_workout_view_model.dart';
import 'package:train_libre/features/workout/domain/repositories/workout_repository.dart';
import 'package:train_libre/features/workout/domain/models/workout_log.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/routine.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/steps/presentation/statistics_steps_card.dart';
import 'package:provider/provider.dart';

class FakeWorkoutRepository implements IWorkoutRepository {
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
  Future<Map<String, double>> getExerciseBests(String exerciseName,
          {String? altName, String? exerciseUuid}) async =>
      {};
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
  Future<void> saveWorkoutExerciseNote({
    required int workoutLogId,
    required String exerciseName,
    required String? notes,
  }) async {}
  @override
  Future<Map<String, String>> getWorkoutExerciseNotes(int workoutLogId) async => {};
  @override
  Future<List<SetLog>> getLastSetsForExercise(String exerciseName) async => [];
  @override
  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(
          DateTime start, DateTime end) async =>
      [];
}

Future<void> _pumpUntilScopeLoaded(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      return;
    }
  }
  throw TestFailure('Steps scope did not finish loading in test');
}

Future<void> _pumpScopeTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await _pumpUntilScopeLoaded(tester);
}

void main() {
  testWidgets('scope switching updates trend canvas and card label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<LiveWorkoutViewModel>.value(
        value: LiveWorkoutViewModel(repository: FakeWorkoutRepository()),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StepsModuleScreen(
            repository: InMemoryStepsAggregationRepository(),
            targetStepsLoader: _fakeTargetSteps,
            stepsProviderNameLoader: _fakeProviderName,
          ),
        ),
      ),
    );

    await _pumpUntilScopeLoaded(tester);

    expect(find.text('Hourly Timeline'), findsOneWidget);
    expect(find.byType(StatisticsStepsCard), findsNothing);

    await tester.tap(find.text('Week'));
    await _pumpScopeTransition(tester);

    expect(find.text('Hourly Timeline'), findsNothing);
    expect(find.byType(StatisticsStepsCard), findsNothing);

    await tester.tap(find.text('Month'));
    await _pumpScopeTransition(tester);

    expect(find.byType(StatisticsStepsCard), findsOneWidget);
    expect(find.textContaining('This Month •'), findsOneWidget);
  });
}

Future<int> _fakeTargetSteps() async => 8000;

Future<String> _fakeProviderName() async => 'Local';
