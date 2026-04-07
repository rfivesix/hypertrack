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
import 'package:hypertrack/features/nutrition_recommendation/domain/adaptive_recommendation_snapshot.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
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
      expect(
        second.estimatedMaintenanceCalories,
        first.estimatedMaintenanceCalories,
      );
      expect(
        second.inputSummary.intakeLoggedDays,
        first.inputSummary.intakeLoggedDays,
      );
    });

    test('refresh persists coherent snapshot and recursive state', () async {
      final generated = await service.refreshRecommendationIfDue(
        now: DateTime(2026, 4, 6, 10, 0),
        force: true,
      );

      final snapshot = await repository.getLatestRecommendationSnapshot();
      final state = await repository.getLatestEstimatorState();
      final prefs = await SharedPreferences.getInstance();

      expect(generated, isNotNull);
      expect(snapshot, isNotNull);
      expect(snapshot!.isCoherent, isTrue);
      expect(snapshot.dueWeekKey, '2026-04-06');
      expect(snapshot.recommendation.dueWeekKey, snapshot.dueWeekKey);
      expect(snapshot.maintenanceEstimate.dueWeekKey, snapshot.dueWeekKey);
      expect(state, isNotNull);
      expect(state!.lastDueWeekKey, '2026-04-06');
      expect(
        state.posteriorMeanCalories,
        closeTo(
            snapshot.maintenanceEstimate.posteriorMaintenanceCalories, 0.001),
      );

      // Legacy experimental persistence keys stay migration-only (not written).
      expect(
        prefs.getString(
          'adaptive_nutrition_recommendation.latest_generated_bayesian_experimental',
        ),
        isNull,
      );
      expect(
        prefs.getString(
          'adaptive_nutrition_recommendation.latest_bayesian_experimental_snapshot',
        ),
        isNull,
      );
    });

    test('recursive state is restored and chained across service restart',
        () async {
      final first = await service.refreshRecommendationIfDue(
        now: DateTime(2026, 4, 6, 10, 0),
        force: true,
      );

      final restoredService = AdaptiveNutritionRecommendationService(
        repository: repository,
        databaseHelper: dbHelper,
        dueNotifier: dueNotifier,
      );
      final second = await restoredService.refreshRecommendationIfDue(
        now: DateTime(2026, 4, 13, 10, 0),
        force: true,
      );

      final snapshot = await repository.getLatestRecommendationSnapshot();

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(snapshot, isNotNull);
      expect(snapshot!.dueWeekKey, '2026-04-13');
      expect(
        snapshot.maintenanceEstimate.priorSource,
        BayesianPriorSource.chainedPosterior,
      );
      expect(
        snapshot.maintenanceEstimate.priorMeanUsedCalories,
        closeTo(
          first!.estimatedMaintenanceCalories.toDouble(),
          400,
        ),
      );
    });

    test(
        'missing-observation week runs prediction-only (no jump, higher uncertainty)',
        () async {
      await service.refreshRecommendationIfDue(
        now: DateTime(2026, 4, 6, 10, 0),
        force: true,
      );
      final weekWithNoLogs = await service.refreshRecommendationIfDue(
        now: DateTime(2026, 8, 31, 10, 0),
        force: true,
      );
      final snapshot = await repository.getLatestRecommendationSnapshot();

      expect(weekWithNoLogs, isNotNull);
      expect(snapshot, isNotNull);
      expect(
        snapshot!.maintenanceEstimate.observationImpliedMaintenanceCalories,
        isNull,
      );
      expect(
        snapshot.maintenanceEstimate.qualityFlags,
        contains('bayesian_prediction_only_no_observation'),
      );
      expect(
        _debugDouble(snapshot.maintenanceEstimate, 'kalmanGain'),
        closeTo(0, 0.000001),
      );
      expect(
        _debugDouble(
            snapshot.maintenanceEstimate, 'posteriorVarianceCalories2'),
        greaterThan(_debugDouble(
            snapshot.maintenanceEstimate, 'priorVarianceCalories2')),
      );
    });

    test('long-gap behavior increases uncertainty but avoids near-unity reset',
        () async {
      await service.refreshRecommendationIfDue(
        now: DateTime(2026, 4, 6, 10, 0),
        force: true,
      );

      await service.refreshRecommendationIfDue(
        now: DateTime(2026, 8, 31, 10, 0),
        force: true,
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

      final afterGap = await service.refreshRecommendationIfDue(
        now: DateTime(2026, 9, 7, 10, 0),
        force: true,
      );
      final snapshot = await repository.getLatestRecommendationSnapshot();

      expect(afterGap, isNotNull);
      expect(snapshot, isNotNull);

      final gain = _debugDouble(snapshot!.maintenanceEstimate, 'kalmanGain');
      final cap =
          _debugDouble(snapshot.maintenanceEstimate, 'varianceCapCalories2');
      final postVar = _debugDouble(
          snapshot.maintenanceEstimate, 'posteriorVarianceCalories2');
      expect(gain, lessThan(0.93));
      expect(postVar, lessThanOrEqualTo(cap + 0.0001));
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

    test(
        'applyLatestRecommendationToActiveTargets returns false when missing generated recommendation',
        () async {
      final applied = await service.applyLatestRecommendationToActiveTargets();
      expect(applied, isFalse);
    });

    test('manual recalculate uses stable window and does not auto-apply goals',
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
        'due notification does not fire when current due-week snapshot exists even without due-week marker key',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final snapshot = AdaptiveRecommendationSnapshot(
        recommendation: _recommendationForDueWeek('2026-04-06'),
        maintenanceEstimate: _estimateForDueWeek('2026-04-06'),
        dueWeekKey: '2026-04-06',
        algorithmVersion:
            AdaptiveNutritionRecommendationService.algorithmVersion,
      );
      await prefs.setString(
        'adaptive_nutrition_recommendation.latest_snapshot',
        jsonEncode(snapshot.toJson()),
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
      final snapshot = await repository.getLatestRecommendationSnapshot();

      expect(generated, isNotNull);
      expect(applied, isNotNull);
      expect(snapshot, isNotNull);
      expect(generated!.goal, BodyweightGoal.gainWeight);
      expect(generated.targetRateKgPerWeek, 0.25);
      expect(applied!.recommendedCalories, generated.recommendedCalories);
      expect(snapshot!.isCoherent, isTrue);
    });

    test('onboarding bootstrap handles missing optional profile inputs safely',
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
      expect(recommendation.dueWeekKey, '2026-03-30');
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

      expect(
        lowerBodyFat.estimatedMaintenanceCalories,
        greaterThan(higherBodyFat.estimatedMaintenanceCalories),
      );
      expect(
        highActivity.estimatedMaintenanceCalories,
        greaterThan(lowActivity.estimatedMaintenanceCalories),
      );
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
    algorithmVersion: AdaptiveNutritionRecommendationService.algorithmVersion,
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
