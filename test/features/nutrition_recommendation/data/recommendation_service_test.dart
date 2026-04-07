import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart'
    show AppDatabase, ProductsCompanion;
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_due_notification.dart';
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_repository.dart';
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_service.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_estimation_mode.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_models.dart';
import 'package:hypertrack/models/food_entry.dart';
import 'package:hypertrack/models/measurement.dart';
import 'package:hypertrack/models/measurement_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdaptiveNutritionRecommendationService', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;
    late RecommendationRepository repository;
    late _FakeDueNotifier dueNotifier;
    late AdaptiveNutritionRecommendationService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
      repository = RecommendationRepository();
      dueNotifier = _FakeDueNotifier();
      service = AdaptiveNutritionRecommendationService(
        repository: repository,
        databaseHelper: dbHelper,
        dueNotifier: dueNotifier,
      );

      await dbHelper.saveUserProfile(
        name: 'Jordan',
        birthday: DateTime(1994, 5, 12),
        height: 178,
        gender: 'male',
      );
      await dbHelper.saveUserGoals(
        calories: 2400,
        protein: 170,
        carbs: 260,
        fat: 75,
        water: 3000,
        steps: 8500,
      );
      await repository.saveGoalAndTargetRate(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
      );

      await database.into(database.products).insert(
            const ProductsCompanion(
              barcode: drift.Value('test-food'),
              name: drift.Value('Test Food'),
              calories: drift.Value(250),
              protein: drift.Value(10),
              carbs: drift.Value(30),
              fat: drift.Value(5),
              source: drift.Value('base'),
            ),
          );

      final start = DateTime(2026, 3, 16);
      for (var i = 0; i < 21; i++) {
        final day = start.add(Duration(days: i));
        await dbHelper.insertMeasurementSession(
          MeasurementSession(
            timestamp: DateTime(day.year, day.month, day.day, 7, 0),
            measurements: [
              Measurement(
                sessionId: 0,
                type: 'weight',
                value: 82.5 - (i * 0.05),
                unit: 'kg',
              ),
            ],
          ),
        );

        await dbHelper.insertFoodEntry(
          FoodEntry(
            barcode: 'test-food',
            timestamp: DateTime(day.year, day.month, day.day, 12, 0),
            quantityInGrams: 900,
            mealType: 'mealtypeLunch',
          ),
        );
      }
    });

    tearDown(() async {
      await database.close();
    });

    test('refreshRecommendationIfDue is idempotent per due week', () async {
      final monday = DateTime(2026, 4, 6, 10, 0);
      final first = await service.refreshRecommendationIfDue(now: monday);
      final second = await service.refreshRecommendationIfDue(
        now: monday.add(const Duration(days: 2)),
      );

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.generatedAt, second!.generatedAt);
      expect(first.dueWeekKey, '2026-04-06');
      expect(await repository.getLastGeneratedDueWeekKey(), '2026-04-06');
    });

    test(
        'forced regeneration stays stable within due week even with new in-week logs',
        () async {
      final monday = DateTime(2026, 4, 6, 10, 0);
      final first =
          await service.refreshRecommendationIfDue(now: monday, force: true);

      await dbHelper.insertMeasurementSession(
        MeasurementSession(
          timestamp: DateTime(2026, 4, 7, 7, 0),
          measurements: [
            Measurement(
              sessionId: 0,
              type: 'weight',
              value: 70,
              unit: 'kg',
            ),
          ],
        ),
      );
      await dbHelper.insertFoodEntry(
        FoodEntry(
          barcode: 'test-food',
          timestamp: DateTime(2026, 4, 7, 12, 0),
          quantityInGrams: 4000,
          mealType: 'mealtypeLunch',
        ),
      );

      final second = await service.refreshRecommendationIfDue(
        now: DateTime(2026, 4, 8, 10, 0),
        force: true,
      );

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.dueWeekKey, '2026-04-06');
      expect(second!.dueWeekKey, '2026-04-06');
      expect(first.windowEnd, DateTime(2026, 4, 5, 23, 59, 59));
      expect(second.windowEnd, DateTime(2026, 4, 5, 23, 59, 59));
      expect(second.recommendedCalories, first.recommendedCalories);
      expect(second.estimatedMaintenanceCalories,
          first.estimatedMaintenanceCalories);
      expect(second.inputSummary.intakeLoggedDays,
          first.inputSummary.intakeLoggedDays);
    });

    test('refresh does not overwrite active goals until explicit apply',
        () async {
      final monday = DateTime(2026, 4, 6, 10, 0);
      final beforeRefreshSettings = await dbHelper.getAppSettings();
      expect(beforeRefreshSettings, isNotNull);
      expect(beforeRefreshSettings!.targetCalories, 2400);

      final recommendation =
          await service.refreshRecommendationIfDue(now: monday);
      final afterRefreshSettings = await dbHelper.getAppSettings();

      expect(recommendation, isNotNull);
      expect(afterRefreshSettings, isNotNull);
      expect(afterRefreshSettings!.targetCalories, 2400);

      final applied = await service.applyLatestRecommendationToActiveTargets();
      final afterApplySettings = await dbHelper.getAppSettings();

      expect(applied, isTrue);
      expect(afterApplySettings, isNotNull);
      expect(
        afterApplySettings!.targetCalories,
        recommendation!.recommendedCalories,
      );
      expect(
        afterApplySettings.targetProtein,
        recommendation.recommendedProteinGrams,
      );
    });

    test('experimental refresh is idempotent per due week', () async {
      final monday = DateTime(2026, 4, 6, 10, 0);
      final first =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: monday,
      );
      final second =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: monday.add(const Duration(days: 2)),
      );

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.recommendation.generatedAt,
          second!.recommendation.generatedAt);
      expect(first.recommendation.dueWeekKey, '2026-04-06');
      expect(
        (await repository.getLatestBayesianExperimentalSnapshot())?.dueWeekKey,
        '2026-04-06',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(
          'adaptive_nutrition_recommendation.last_generated_due_week_key_bayesian_experimental',
        ),
        isNull,
      );
      expect(
        second.maintenanceEstimate.posteriorMaintenanceCalories,
        closeTo(first.maintenanceEstimate.posteriorMaintenanceCalories, 0.0001),
      );
      expect(
        second.maintenanceEstimate.priorMeanUsedCalories,
        closeTo(first.maintenanceEstimate.priorMeanUsedCalories, 0.0001),
      );
      expect(
        second.maintenanceEstimate.priorStdDevUsedCalories,
        closeTo(first.maintenanceEstimate.priorStdDevUsedCalories, 0.0001),
      );
    });

    test('experimental refresh persists recursive estimator state', () async {
      final first =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: DateTime(2026, 4, 6, 10, 0),
        force: true,
      );
      expect(first, isNotNull);

      final persistedState = await repository.getLatestBayesianEstimatorState();
      expect(persistedState, isNotNull);
      expect(persistedState!.lastDueWeekKey, '2026-04-06');
      expect(
        persistedState.posteriorMeanCalories,
        closeTo(first!.maintenanceEstimate.posteriorMaintenanceCalories, 0.001),
      );

      // Simulate app restore/reload by creating a new service instance
      // that must consume persisted recursive state.
      final restoredService = AdaptiveNutritionRecommendationService(
        repository: repository,
        databaseHelper: dbHelper,
        dueNotifier: dueNotifier,
      );
      final nextWeek =
          await restoredService.refreshBayesianExperimentalRecommendationIfDue(
        now: DateTime(2026, 4, 13, 10, 0),
        force: true,
      );

      expect(nextWeek, isNotNull);
      expect(
        nextWeek!.maintenanceEstimate.priorSource,
        BayesianPriorSource.chainedPosterior,
      );
      expect(
        nextWeek.maintenanceEstimate.priorMeanUsedCalories,
        closeTo(first.maintenanceEstimate.posteriorMaintenanceCalories, 0.0001),
      );
    });

    test('experimental retrieval returns coherent pair when dueWeek keys match',
        () async {
      final generated =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: DateTime(2026, 4, 6, 10, 0),
        force: true,
      );
      final latest =
          await service.getLatestBayesianExperimentalRecommendation();

      expect(generated, isNotNull);
      expect(latest, isNotNull);
      expect(
        latest!.recommendation.dueWeekKey,
        latest.maintenanceEstimate.dueWeekKey,
      );
    });

    test('experimental retrieval returns null for mismatched dueWeek payloads',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'adaptive_nutrition_recommendation.latest_generated_bayesian_experimental',
        jsonEncode(_recommendationForDueWeek('2026-04-06').toJson()),
      );
      await prefs.setString(
        'adaptive_nutrition_recommendation.latest_bayesian_maintenance_estimate',
        jsonEncode(_estimateForDueWeek('2026-04-13').toJson()),
      );
      await prefs.remove(
        'adaptive_nutrition_recommendation.latest_bayesian_experimental_snapshot',
      );

      final latest =
          await service.getLatestBayesianExperimentalRecommendation();
      expect(latest, isNull);
    });

    test('experimental retrieval returns null for incoherent snapshot payload',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'adaptive_nutrition_recommendation.latest_bayesian_experimental_snapshot',
        '{"dueWeekKey":"2026-04-06","algorithmVersion":"bayesian_test",'
            '"recommendation":${_encodedRecommendationJson("2026-04-06", "bayesian_test")},'
            '"maintenanceEstimate":${_encodedEstimateJson("2026-04-13")}}',
      );

      final latest =
          await service.getLatestBayesianExperimentalRecommendation();
      expect(latest, isNull);
    });

    test(
        'experimental forced regeneration stays stable in due week despite new logs',
        () async {
      final monday = DateTime(2026, 4, 6, 10, 0);
      final first =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: monday,
        force: true,
      );

      await dbHelper.insertMeasurementSession(
        MeasurementSession(
          timestamp: DateTime(2026, 4, 7, 7, 0),
          measurements: [
            Measurement(
              sessionId: 0,
              type: 'weight',
              value: 68,
              unit: 'kg',
            ),
          ],
        ),
      );
      await dbHelper.insertFoodEntry(
        FoodEntry(
          barcode: 'test-food',
          timestamp: DateTime(2026, 4, 7, 12, 0),
          quantityInGrams: 4200,
          mealType: 'mealtypeLunch',
        ),
      );

      final second =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: DateTime(2026, 4, 8, 10, 0),
        force: true,
      );

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.recommendation.windowEnd, DateTime(2026, 4, 5, 23, 59, 59));
      expect(
          second!.recommendation.windowEnd, DateTime(2026, 4, 5, 23, 59, 59));
      expect(
        second.recommendation.estimatedMaintenanceCalories,
        first.recommendation.estimatedMaintenanceCalories,
      );
      expect(
        second.maintenanceEstimate.posteriorStdDevCalories,
        closeTo(first.maintenanceEstimate.posteriorStdDevCalories, 0.0001),
      );
      expect(
        second.maintenanceEstimate.priorMeanUsedCalories,
        closeTo(first.maintenanceEstimate.priorMeanUsedCalories, 0.0001),
      );
    });

    test('experimental next due week chains from previous posterior', () async {
      final firstWeekMonday = DateTime(2026, 4, 6, 10, 0);
      final firstWeek =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: firstWeekMonday,
        force: true,
      );

      final secondWeek =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: DateTime(2026, 4, 13, 10, 0),
        force: true,
      );

      expect(firstWeek, isNotNull);
      expect(secondWeek, isNotNull);
      expect(
        secondWeek!.maintenanceEstimate.priorSource,
        BayesianPriorSource.chainedPosterior,
      );
      expect(
        secondWeek.maintenanceEstimate.priorMeanUsedCalories,
        closeTo(
          firstWeek!.maintenanceEstimate.posteriorMaintenanceCalories,
          0.0001,
        ),
      );
      expect(
        secondWeek.maintenanceEstimate.priorMeanUsedCalories,
        isNot(closeTo(
          secondWeek.maintenanceEstimate.profilePriorMaintenanceCalories,
          0.0001,
        )),
      );
      expect(
        secondWeek.maintenanceEstimate.priorStdDevUsedCalories,
        closeTo(firstWeek.maintenanceEstimate.posteriorStdDevCalories, 0.0001),
      );
    });

    test(
        'experimental long-gap behavior increases uncertainty but avoids near-unity reset',
        () async {
      final firstWeek =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: DateTime(2026, 4, 6, 10, 0),
        force: true,
      );
      expect(firstWeek, isNotNull);

      final longGapPredictionOnly =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: DateTime(2026, 8, 31, 10, 0),
        force: true,
      );
      expect(longGapPredictionOnly, isNotNull);
      expect(
        longGapPredictionOnly!
            .maintenanceEstimate.observationImpliedMaintenanceCalories,
        isNull,
      );

      final start = DateTime(2026, 8, 17);
      for (var i = 0; i < 21; i++) {
        final day = start.add(Duration(days: i));
        await dbHelper.insertMeasurementSession(
          MeasurementSession(
            timestamp: DateTime(day.year, day.month, day.day, 7, 0),
            measurements: [
              Measurement(
                sessionId: 0,
                type: 'weight',
                value: 80.0 - (i * 0.03),
                unit: 'kg',
              ),
            ],
          ),
        );
        await dbHelper.insertFoodEntry(
          FoodEntry(
            barcode: 'test-food',
            timestamp: DateTime(day.year, day.month, day.day, 12, 0),
            quantityInGrams: 850,
            mealType: 'mealtypeLunch',
          ),
        );
      }

      final afterGapWithObservation =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: DateTime(2026, 9, 7, 10, 0),
        force: true,
      );
      expect(afterGapWithObservation, isNotNull);

      final gain = _debugDouble(
        afterGapWithObservation!.maintenanceEstimate,
        'kalmanGain',
      );
      final cap = _debugDouble(
        afterGapWithObservation.maintenanceEstimate,
        'varianceCapCalories2',
      );
      final postVar = _debugDouble(
        afterGapWithObservation.maintenanceEstimate,
        'posteriorVarianceCalories2',
      );
      expect(gain, lessThan(0.93));
      expect(postVar, lessThanOrEqualTo(cap + 0.0001));
    });

    test('experimental refresh chains from atomic snapshot context', () async {
      final firstWeek =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: DateTime(2026, 4, 6, 10, 0),
        force: true,
      );
      expect(firstWeek, isNotNull);

      // Legacy fragmented keys are ignored for chaining once an atomic snapshot
      // exists; this should not perturb prior resolution.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'adaptive_nutrition_recommendation.latest_bayesian_maintenance_estimate',
        '{ legacy_corrupt_payload',
      );

      final secondWeek =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: DateTime(2026, 4, 13, 10, 0),
        force: true,
      );

      expect(secondWeek, isNotNull);
      expect(
        secondWeek!.maintenanceEstimate.priorSource,
        BayesianPriorSource.chainedPosterior,
      );
      expect(
        secondWeek.maintenanceEstimate.priorMeanUsedCalories,
        closeTo(
          firstWeek!.maintenanceEstimate.posteriorMaintenanceCalories,
          0.0001,
        ),
      );
    });

    test('experimental bootstrap uses profile prior when no previous state',
        () async {
      final result =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: DateTime(2026, 4, 6, 10, 0),
        force: true,
      );

      expect(result, isNotNull);
      expect(
        result!.maintenanceEstimate.priorSource,
        BayesianPriorSource.profilePriorBootstrap,
      );
      expect(
        result.maintenanceEstimate.priorMeanUsedCalories,
        closeTo(
          result.maintenanceEstimate.profilePriorMaintenanceCalories,
          0.0001,
        ),
      );
    });

    test(
        'experimental falls back to profile prior when stored state is corrupt',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'adaptive_nutrition_recommendation.latest_bayesian_experimental_snapshot',
        '{ definitely_not_json',
      );
      await prefs.setString(
        'adaptive_nutrition_recommendation.latest_bayesian_maintenance_estimate',
        '{ definitely_not_json',
      );

      final result =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: DateTime(2026, 4, 6, 10, 0),
        force: true,
      );

      expect(result, isNotNull);
      expect(
        result!.maintenanceEstimate.priorSource,
        BayesianPriorSource.profilePriorBootstrap,
      );
      expect(
        result.maintenanceEstimate.priorMeanUsedCalories,
        closeTo(
          result.maintenanceEstimate.profilePriorMaintenanceCalories,
          0.0001,
        ),
      );
    });

    test('experimental falls back when persisted prior stats are invalid',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'adaptive_nutrition_recommendation.latest_bayesian_maintenance_estimate',
        jsonEncode(
          const BayesianMaintenanceEstimate(
            posteriorMaintenanceCalories: 2500,
            posteriorStdDevCalories: -10,
            profilePriorMaintenanceCalories: 2400,
            priorMeanUsedCalories: 2400,
            priorStdDevUsedCalories: 0,
            priorSource: BayesianPriorSource.chainedPosterior,
            observedIntakeCalories: 2300,
            observedWeightSlopeKgPerWeek: 0,
            observationImpliedMaintenanceCalories: 2300,
            effectiveSampleSize: 10,
            confidence: RecommendationConfidence.medium,
            qualityFlags: <String>[],
            debugInfo: <String, Object>{},
            dueWeekKey: '2026-03-30',
          ).toJson(),
        ),
      );
      await prefs.remove(
        'adaptive_nutrition_recommendation.latest_bayesian_experimental_snapshot',
      );

      final result =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: DateTime(2026, 4, 6, 10, 0),
        force: true,
      );

      expect(result, isNotNull);
      expect(
        result!.maintenanceEstimate.priorSource,
        BayesianPriorSource.profilePriorBootstrap,
      );
    });

    test('experimental refresh does not mutate active goals', () async {
      final monday = DateTime(2026, 4, 6, 10, 0);
      final beforeRefreshSettings = await dbHelper.getAppSettings();
      expect(beforeRefreshSettings, isNotNull);
      expect(beforeRefreshSettings!.targetCalories, 2400);

      final generated =
          await service.refreshBayesianExperimentalRecommendationIfDue(
        now: monday,
      );
      final generatedHeuristic =
          await repository.getLatestGeneratedRecommendation();
      final afterRefreshSettings = await dbHelper.getAppSettings();

      expect(generated, isNotNull);
      expect(generatedHeuristic, isNull);
      expect(afterRefreshSettings, isNotNull);
      expect(afterRefreshSettings!.targetCalories, 2400);

      // Explicit apply continues to only use production (heuristic) snapshots.
      final applied = await service.applyLatestRecommendationToActiveTargets();
      expect(applied, isFalse);
    });

    test(
        'manual recalculate now uses stable window and does not auto-apply goals',
        () async {
      final monday = DateTime(2026, 4, 6, 10, 0);
      final first = await service.refreshRecommendationIfDue(
        now: monday,
        force: true,
      );
      expect(first, isNotNull);

      await repository.saveGoalAndTargetRate(
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -0.5,
      );

      final recalculated = await service.recalculateRecommendationNow(
        now: DateTime(2026, 4, 8, 12, 30),
      );
      final settingsAfter = await dbHelper.getAppSettings();

      expect(recalculated, isNotNull);
      expect(recalculated!.dueWeekKey, '2026-04-06');
      expect(recalculated.windowEnd, DateTime(2026, 4, 5, 23, 59, 59));
      expect(recalculated.generatedAt, DateTime(2026, 4, 8, 12, 30));
      expect(recalculated.goal, BodyweightGoal.loseWeight);
      expect(settingsAfter, isNotNull);
      expect(settingsAfter!.targetCalories, 2400);
    });

    test('loadState exposes recommendation freshness and next-due metadata',
        () async {
      final monday = DateTime(2026, 4, 6, 10, 0);
      final before = await service.loadState(
        now: monday,
        refreshIfDue: false,
      );
      expect(before.latestGeneratedAt, isNull);
      expect(before.isAdaptiveRecommendationDueNow, isTrue);
      expect(before.nextAdaptiveRecommendationDueAt, DateTime(2026, 4, 6));
      expect(before.currentDueWeekKey, '2026-04-06');

      final generated = await service.refreshRecommendationIfDue(now: monday);
      final after = await service.loadState(
        now: DateTime(2026, 4, 8, 10, 0),
        refreshIfDue: false,
      );

      expect(generated, isNotNull);
      expect(after.latestGeneratedAt, generated!.generatedAt);
      expect(after.isAdaptiveRecommendationDueNow, isFalse);
      expect(after.nextAdaptiveRecommendationDueAt, DateTime(2026, 4, 13));
      expect(after.currentDueWeekKey, '2026-04-06');
    });

    test('scheduler-based due notification is emitted once per due week',
        () async {
      final firstNotified = await service.notifyIfNewRecommendationDue(
        now: DateTime(2026, 4, 6, 8, 0),
      );
      final duplicateNotified = await service.notifyIfNewRecommendationDue(
        now: DateTime(2026, 4, 8, 8, 0),
      );

      await service.refreshRecommendationIfDue(
          now: DateTime(2026, 4, 6, 10, 0));
      final notDueAfterGeneration = await service.notifyIfNewRecommendationDue(
        now: DateTime(2026, 4, 10, 9, 0),
      );

      final nextWeekNotified = await service.notifyIfNewRecommendationDue(
        now: DateTime(2026, 4, 13, 8, 0),
      );

      expect(firstNotified, isTrue);
      expect(duplicateNotified, isFalse);
      expect(notDueAfterGeneration, isFalse);
      expect(nextWeekNotified, isTrue);
      expect(dueNotifier.notifications, hasLength(2));
      expect(dueNotifier.notifications[0].dueWeekKey, '2026-04-06');
      expect(dueNotifier.notifications[1].dueWeekKey, '2026-04-13');
    });

    test(
        'scheduler due notification requires due + not-generated + not-notified',
        () async {
      final dueMonday = DateTime(2026, 4, 6, 8, 0);
      final first = await service.notifyIfNewRecommendationDue(now: dueMonday);
      expect(first, isTrue);
      expect(dueNotifier.notifications, hasLength(1));

      final second = await service.notifyIfNewRecommendationDue(
        now: DateTime(2026, 4, 6, 9, 0),
      );
      expect(second, isFalse);
      expect(dueNotifier.notifications, hasLength(1));
    });

    test(
        'scheduler due notification does not fire when due-week recommendation already exists even without due-week marker key',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'adaptive_nutrition_recommendation.latest_generated',
        jsonEncode(_recommendationForDueWeek('2026-04-06').toJson()),
      );
      await prefs.remove(
        'adaptive_nutrition_recommendation.last_generated_due_week_key',
      );
      await prefs.remove(
        'adaptive_nutrition_recommendation.last_due_notification_week_key',
      );

      final notified = await service.notifyIfNewRecommendationDue(
        now: DateTime(2026, 4, 6, 8, 0),
      );
      expect(notified, isFalse);
      expect(dueNotifier.notifications, isEmpty);
    });

    test('experimental onboarding can generate and persist safely', () async {
      final result =
          await service.generateBayesianExperimentalOnboardingRecommendation(
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.25,
        weightKg: 80,
        heightCm: 180,
        birthday: DateTime(1996, 1, 2),
        gender: 'male',
        now: DateTime(2026, 4, 5, 9, 0),
        persistGenerated: true,
      );

      final storedExperimental =
          await repository.getLatestBayesianExperimentalSnapshot();
      final storedHeuristic =
          await repository.getLatestGeneratedRecommendation();

      expect(result.recommendation.recommendedCalories, greaterThan(0));
      expect(
          result.maintenanceEstimate.posteriorStdDevCalories, greaterThan(0));
      expect(storedExperimental, isNotNull);
      expect(
        storedExperimental!.maintenanceEstimate.posteriorMaintenanceCalories,
        closeTo(
          result.maintenanceEstimate.posteriorMaintenanceCalories,
          0.001,
        ),
      );
      expect(storedHeuristic, isNull);
    });

    test(
        'experimental mode onboarding rejects markAsApplied to keep apply semantics explicit',
        () async {
      await expectLater(
        () => service.generateOnboardingRecommendationForMode(
          goal: BodyweightGoal.maintainWeight,
          targetRateKgPerWeek: 0,
          weightKg: 80,
          heightCm: 180,
          birthday: DateTime(1996, 1, 2),
          gender: 'male',
          now: DateTime(2026, 4, 5, 9, 0),
          persistGenerated: true,
          markAsApplied: true,
          mode: RecommendationEstimationMode.bayesianExperimental,
        ),
        throwsArgumentError,
      );
    });

    test('mode separation keeps production refresh behavior unchanged',
        () async {
      final monday = DateTime(2026, 4, 6, 10, 0);
      final experimental = await service.refreshRecommendationIfDueForMode(
        now: monday,
        mode: RecommendationEstimationMode.bayesianExperimental,
      );
      final heuristic = await service.refreshRecommendationIfDueForMode(
        now: monday,
        mode: RecommendationEstimationMode.heuristic,
      );

      expect(experimental, isNotNull);
      expect(heuristic, isNotNull);
      expect(await repository.getLastGeneratedDueWeekKey(), '2026-04-06');
      expect(
        (await repository.getLatestBayesianExperimentalSnapshot())?.dueWeekKey,
        '2026-04-06',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(
          'adaptive_nutrition_recommendation.latest_generated_bayesian_experimental',
        ),
        isNull,
      );
      expect(experimental!.dueWeekKey, heuristic!.dueWeekKey);
      expect(
        heuristic.algorithmVersion,
        AdaptiveNutritionRecommendationService.algorithmVersion,
      );
      expect(
        experimental.algorithmVersion,
        AdaptiveNutritionRecommendationService
            .bayesianExperimentalAlgorithmVersion,
      );
    });

    test('comparison helper returns side-by-side estimator outputs', () async {
      final comparison = await service.generateEstimatorComparison(
        now: DateTime(2026, 4, 6, 10, 0),
      );
      final trace = comparison.toDebugTrace();

      expect(comparison.heuristicRecommendation.recommendedCalories,
          greaterThan(0));
      expect(comparison.bayesianRecommendation.recommendedCalories,
          greaterThan(0));
      expect(comparison.bayesianMaintenanceEstimate.posteriorStdDevCalories,
          greaterThan(0));
      expect(comparison.maintenanceDeltaCalories.abs(), lessThan(500));
      expect(comparison.bayesianPriorMeanCalories, greaterThan(0));
      expect(comparison.bayesianPriorStdDevCalories, greaterThan(0));
      expect(comparison.bayesianPosteriorStdDevCalories, greaterThan(0));
      expect(
        comparison.maintenanceDeltaVsBayesianPriorCalories.abs(),
        lessThan(800),
      );
      expect(
        comparison.bayesianObservationImpliedMaintenanceCalories,
        isNotNull,
      );
      expect(comparison.dueWeekKey, '2026-04-06');
      expect(comparison.generatedAt, DateTime(2026, 4, 6, 10, 0));
      expect(comparison.bayesianProfilePriorCalories, greaterThan(0));
      expect(comparison.bayesianEffectiveSampleSize, greaterThan(0));
      expect(comparison.bayesianQualityFlags, isNotEmpty);
      expect(comparison.windowDays, greaterThan(0));
      expect(comparison.weightLogCount, greaterThan(0));
      expect(comparison.intakeLoggedDays, greaterThan(0));
      expect(comparison.avgLoggedCalories, greaterThan(0));
      expect(trace['dueWeekKey'], '2026-04-06');
      expect(trace['heuristicEstimatedMaintenanceCalories'], isNotNull);
      expect(trace['bayesianPosteriorStdDevCalories'], isNotNull);
      expect(trace['smoothedWeightSlopeKgPerWeek'], isNotNull);
      expect(
        comparison.bayesianRecursiveStateAfter?.lastDueWeekKey,
        '2026-04-06',
      );
      expect(
        trace['bayesianRecursiveStateAfterDueWeekKey'],
        '2026-04-06',
      );
    });

    test('onboarding recommendation can be persisted and marked as applied',
        () async {
      final recommendation = await service.generateOnboardingRecommendation(
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.25,
        weightKg: 80,
        heightCm: 180,
        birthday: DateTime(1996, 1, 2),
        gender: 'male',
        now: DateTime(2026, 4, 5, 9, 0),
      );

      await service.persistGeneratedRecommendation(
        recommendation: recommendation,
        markAsApplied: true,
      );

      final generated = await repository.getLatestGeneratedRecommendation();
      final applied = await repository.getLatestAppliedRecommendation();

      expect(generated, isNotNull);
      expect(applied, isNotNull);
      expect(generated!.goal, BodyweightGoal.gainWeight);
      expect(generated.targetRateKgPerWeek, 0.25);
      expect(applied!.recommendedCalories, generated.recommendedCalories);
    });

    test(
        'onboarding prior differentiates body-fat percentage and declared activity level',
        () async {
      final lowerBodyFat = await service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 95,
        heightCm: 180,
        birthday: DateTime(1994, 5, 12),
        gender: 'male',
        bodyFatPercent: 15,
        declaredActivityLevel: PriorActivityLevel.moderate,
        now: DateTime(2026, 4, 5, 9, 0),
      );
      final higherBodyFat = await service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 95,
        heightCm: 180,
        birthday: DateTime(1994, 5, 12),
        gender: 'male',
        bodyFatPercent: 30,
        declaredActivityLevel: PriorActivityLevel.moderate,
        now: DateTime(2026, 4, 5, 9, 0),
      );

      final lowActivity = await service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 80,
        heightCm: 180,
        birthday: DateTime(1994, 5, 12),
        gender: 'male',
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.low,
        extraCardioHoursOption: ExtraCardioHoursOption.h0,
        now: DateTime(2026, 4, 5, 9, 0),
      );
      final highActivity = await service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 80,
        heightCm: 180,
        birthday: DateTime(1994, 5, 12),
        gender: 'male',
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.high,
        extraCardioHoursOption: ExtraCardioHoursOption.h0,
        now: DateTime(2026, 4, 5, 9, 0),
      );
      final veryHighActivity = await service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 80,
        heightCm: 180,
        birthday: DateTime(1994, 5, 12),
        gender: 'male',
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.veryHigh,
        extraCardioHoursOption: ExtraCardioHoursOption.h0,
        now: DateTime(2026, 4, 5, 9, 0),
      );
      final lowActivityHighExtraCardio =
          await service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: 80,
        heightCm: 180,
        birthday: DateTime(1994, 5, 12),
        gender: 'male',
        bodyFatPercent: null,
        declaredActivityLevel: PriorActivityLevel.low,
        extraCardioHoursOption: ExtraCardioHoursOption.h7Plus,
        now: DateTime(2026, 4, 5, 9, 0),
      );

      expect(
        lowerBodyFat.estimatedMaintenanceCalories,
        greaterThan(higherBodyFat.estimatedMaintenanceCalories),
      );
      expect(
        highActivity.estimatedMaintenanceCalories,
        greaterThan(lowActivity.estimatedMaintenanceCalories),
      );
      expect(
        veryHighActivity.estimatedMaintenanceCalories,
        greaterThan(highActivity.estimatedMaintenanceCalories),
      );
      expect(
        lowActivityHighExtraCardio.estimatedMaintenanceCalories,
        greaterThan(lowActivity.estimatedMaintenanceCalories),
      );
    });

    test('onboarding recommendation handles missing optional inputs safely',
        () async {
      final recommendation = await service.generateOnboardingRecommendation(
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        weightKg: null,
        heightCm: null,
        birthday: null,
        gender: null,
        bodyFatPercent: null,
        declaredActivityLevel: null,
        extraCardioHoursOption: null,
        now: DateTime(2026, 4, 5, 9, 0),
      );

      expect(recommendation.recommendedCalories, greaterThan(0));
      expect(recommendation.estimatedMaintenanceCalories, greaterThan(0));
    });
  });
}

NutritionRecommendation _recommendationForDueWeek(String dueWeekKey) {
  return NutritionRecommendation(
    recommendedCalories: 2400,
    recommendedProteinGrams: 170,
    recommendedCarbsGrams: 260,
    recommendedFatGrams: 75,
    estimatedMaintenanceCalories: 2400,
    goal: BodyweightGoal.maintainWeight,
    targetRateKgPerWeek: 0,
    confidence: RecommendationConfidence.medium,
    warningState: RecommendationWarningState.none,
    generatedAt: DateTime(2026, 4, 6, 10, 0),
    windowStart: DateTime(2026, 3, 16),
    windowEnd: DateTime(2026, 4, 5, 23, 59, 59),
    algorithmVersion: AdaptiveNutritionRecommendationService
        .bayesianExperimentalAlgorithmVersion,
    inputSummary: const RecommendationInputSummary(
      windowDays: 21,
      weightLogCount: 9,
      intakeLoggedDays: 15,
      smoothedWeightSlopeKgPerWeek: -0.2,
      avgLoggedCalories: 2300,
    ),
    baselineCalories: 2400,
    dueWeekKey: dueWeekKey,
  );
}

BayesianMaintenanceEstimate _estimateForDueWeek(String dueWeekKey) {
  return BayesianMaintenanceEstimate(
    posteriorMaintenanceCalories: 2400,
    posteriorStdDevCalories: 180,
    profilePriorMaintenanceCalories: 2350,
    priorMeanUsedCalories: 2350,
    priorStdDevUsedCalories: 220,
    priorSource: BayesianPriorSource.profilePriorBootstrap,
    observedIntakeCalories: 2300,
    observedWeightSlopeKgPerWeek: -0.1,
    observationImpliedMaintenanceCalories: 2410,
    effectiveSampleSize: 8,
    confidence: RecommendationConfidence.medium,
    qualityFlags: const <String>[],
    debugInfo: const <String, Object>{},
    dueWeekKey: dueWeekKey,
  );
}

String _encodedRecommendationJson(String dueWeekKey, String algorithmVersion) {
  return jsonEncode(
    _recommendationForDueWeek(dueWeekKey)
        .copyWith(algorithmVersion: algorithmVersion)
        .toJson(),
  );
}

String _encodedEstimateJson(String dueWeekKey) {
  return jsonEncode(_estimateForDueWeek(dueWeekKey).toJson());
}

double _debugDouble(BayesianMaintenanceEstimate estimate, String key) {
  final value = estimate.debugInfo[key];
  if (value is num) {
    return value.toDouble();
  }
  throw StateError('Missing numeric debug key: $key');
}

class _FakeDueNotifier implements AdaptiveRecommendationDueNotifier {
  final List<({String dueWeekKey, DateTime dueAt})> notifications = [];

  @override
  Future<void> notifyRecommendationDue({
    required String dueWeekKey,
    required DateTime dueAt,
  }) async {
    notifications.add((dueWeekKey: dueWeekKey, dueAt: dueAt));
  }
}

extension on NutritionRecommendation {
  NutritionRecommendation copyWith({
    int? recommendedCalories,
    int? recommendedProteinGrams,
    int? recommendedCarbsGrams,
    int? recommendedFatGrams,
    int? estimatedMaintenanceCalories,
    BodyweightGoal? goal,
    double? targetRateKgPerWeek,
    RecommendationConfidence? confidence,
    RecommendationWarningState? warningState,
    DateTime? generatedAt,
    DateTime? windowStart,
    DateTime? windowEnd,
    String? algorithmVersion,
    RecommendationInputSummary? inputSummary,
    int? baselineCalories,
    String? dueWeekKey,
  }) {
    return NutritionRecommendation(
      recommendedCalories: recommendedCalories ?? this.recommendedCalories,
      recommendedProteinGrams:
          recommendedProteinGrams ?? this.recommendedProteinGrams,
      recommendedCarbsGrams:
          recommendedCarbsGrams ?? this.recommendedCarbsGrams,
      recommendedFatGrams: recommendedFatGrams ?? this.recommendedFatGrams,
      estimatedMaintenanceCalories:
          estimatedMaintenanceCalories ?? this.estimatedMaintenanceCalories,
      goal: goal ?? this.goal,
      targetRateKgPerWeek: targetRateKgPerWeek ?? this.targetRateKgPerWeek,
      confidence: confidence ?? this.confidence,
      warningState: warningState ?? this.warningState,
      generatedAt: generatedAt ?? this.generatedAt,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
      inputSummary: inputSummary ?? this.inputSummary,
      baselineCalories: baselineCalories ?? this.baselineCalories,
      dueWeekKey: dueWeekKey ?? this.dueWeekKey,
    );
  }
}
