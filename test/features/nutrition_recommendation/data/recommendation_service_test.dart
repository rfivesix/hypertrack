import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart'
    show AppDatabase, ProductsCompanion;
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_repository.dart';
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_service.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_estimation_mode.dart';
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
    late AdaptiveNutritionRecommendationService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
      repository = RecommendationRepository();
      service = AdaptiveNutritionRecommendationService(
        repository: repository,
        databaseHelper: dbHelper,
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
        await repository.getLastGeneratedDueWeekKeyForMode(
          mode: RecommendationEstimationMode.bayesianExperimental,
        ),
        '2026-04-06',
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
      await repository.saveLatestBayesianMaintenanceEstimate(
        estimate: const BayesianMaintenanceEstimate(
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
        ),
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
          await repository.getLatestGeneratedRecommendationForMode(
        mode: RecommendationEstimationMode.bayesianExperimental,
      );
      final storedHeuristic =
          await repository.getLatestGeneratedRecommendation();

      expect(result.recommendation.recommendedCalories, greaterThan(0));
      expect(
          result.maintenanceEstimate.posteriorStdDevCalories, greaterThan(0));
      expect(storedExperimental, isNotNull);
      expect(storedHeuristic, isNull);
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
