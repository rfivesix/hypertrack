import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart' as db;
import '../domain/bayesian_recommendation_engine.dart';
import '../domain/bayesian_tdee_estimator.dart';
import '../domain/goal_models.dart';
import '../domain/recommendation_engine.dart';
import '../domain/recommendation_estimation_mode.dart';
import '../domain/recommendation_models.dart';
import 'recommendation_input_adapter.dart';
import 'recommendation_repository.dart';
import 'recommendation_scheduler.dart';

class AdaptiveNutritionRecommendationState {
  final BodyweightGoal goal;
  final double targetRateKgPerWeek;
  final NutritionRecommendation? latestGeneratedRecommendation;
  final NutritionRecommendation? latestAppliedRecommendation;

  const AdaptiveNutritionRecommendationState({
    required this.goal,
    required this.targetRateKgPerWeek,
    required this.latestGeneratedRecommendation,
    required this.latestAppliedRecommendation,
  });
}

class RecommendationEstimatorComparison {
  final NutritionRecommendation heuristicRecommendation;
  final NutritionRecommendation bayesianRecommendation;
  final BayesianMaintenanceEstimate bayesianMaintenanceEstimate;

  const RecommendationEstimatorComparison({
    required this.heuristicRecommendation,
    required this.bayesianRecommendation,
    required this.bayesianMaintenanceEstimate,
  });

  int get maintenanceDeltaCalories {
    return bayesianRecommendation.estimatedMaintenanceCalories -
        heuristicRecommendation.estimatedMaintenanceCalories;
  }
}

class AdaptiveNutritionRecommendationService {
  static const String algorithmVersion = 'tdee_adaptive_recommendation_0_8_mvp';
  static const String bayesianExperimentalAlgorithmVersion =
      'tdee_adaptive_recommendation_0_8_bayesian_experimental_v1';

  final RecommendationRepository _repository;
  final RecommendationInputAdapter _inputAdapter;
  final DatabaseHelper _databaseHelper;
  final BayesianNutritionRecommendationEngine _bayesianEngine;

  AdaptiveNutritionRecommendationService({
    RecommendationRepository? repository,
    RecommendationInputAdapter? inputAdapter,
    DatabaseHelper? databaseHelper,
    BayesianNutritionRecommendationEngine? bayesianEngine,
  })  : _repository = repository ?? RecommendationRepository(),
        _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        _bayesianEngine =
            bayesianEngine ?? const BayesianNutritionRecommendationEngine(),
        _inputAdapter = inputAdapter ??
            RecommendationInputAdapter(
              databaseHelper: databaseHelper ?? DatabaseHelper.instance,
            );

  Future<void> saveGoalAndTargetRate({
    required BodyweightGoal goal,
    required double targetRateKgPerWeek,
  }) {
    return _repository.saveGoalAndTargetRate(
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
    );
  }

  Future<BodyweightGoal> getGoal() {
    return _repository.getGoal();
  }

  Future<double> getTargetRateKgPerWeek() {
    return _repository.getTargetRateKgPerWeek();
  }

  Future<PriorActivityLevel> getPriorActivityLevel() {
    return _repository.getPriorActivityLevel();
  }

  Future<void> savePriorActivityLevel(PriorActivityLevel level) {
    return _repository.savePriorActivityLevel(level);
  }

  Future<ExtraCardioHoursOption> getExtraCardioHoursOption() {
    return _repository.getExtraCardioHoursOption();
  }

  Future<void> saveExtraCardioHoursOption(ExtraCardioHoursOption option) {
    return _repository.saveExtraCardioHoursOption(option);
  }

  Future<NutritionRecommendation?> getLatestGeneratedRecommendation() {
    return _repository.getLatestGeneratedRecommendation();
  }

  Future<NutritionRecommendation?> getLatestAppliedRecommendation() {
    return _repository.getLatestAppliedRecommendation();
  }

  Future<AdaptiveNutritionRecommendationState> loadState({
    DateTime? now,
    bool refreshIfDue = true,
  }) async {
    if (refreshIfDue) {
      await refreshRecommendationIfDue(now: now);
    }

    final results = await Future.wait<dynamic>([
      _repository.getGoal(),
      _repository.getTargetRateKgPerWeek(),
      _repository.getLatestGeneratedRecommendation(),
      _repository.getLatestAppliedRecommendation(),
    ]);

    return AdaptiveNutritionRecommendationState(
      goal: results[0] as BodyweightGoal,
      targetRateKgPerWeek: results[1] as double,
      latestGeneratedRecommendation: results[2] as NutritionRecommendation?,
      latestAppliedRecommendation: results[3] as NutritionRecommendation?,
    );
  }

  Future<NutritionRecommendation?> refreshRecommendationIfDue({
    DateTime? now,
    bool force = false,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final dueWeekKey = RecommendationScheduler.dueWeekKeyFor(effectiveNow);
    final stableWindowEndDay =
        RecommendationScheduler.stableWindowEndDayForDueWeek(effectiveNow);
    final lastGeneratedDueWeekKey =
        await _repository.getLastGeneratedDueWeekKey();

    if (!force &&
        !RecommendationScheduler.shouldGenerateForWeek(
          dueWeekKey: dueWeekKey,
          lastGeneratedDueWeekKey: lastGeneratedDueWeekKey,
        )) {
      return _repository.getLatestGeneratedRecommendation();
    }
    final priorActivityLevel = await _repository.getPriorActivityLevel();
    final extraCardioHoursOption =
        await _repository.getExtraCardioHoursOption();

    final results = await Future.wait<dynamic>([
      _repository.getGoal(),
      _repository.getTargetRateKgPerWeek(),
      _repository.getLatestGeneratedRecommendation(),
      _inputAdapter.buildInput(
        now: stableWindowEndDay,
        declaredActivityLevel: priorActivityLevel,
        extraCardioHoursOption: extraCardioHoursOption,
      ),
    ]);

    final goal = results[0] as BodyweightGoal;
    final targetRateKgPerWeek = results[1] as double;
    final previousRecommendation = results[2] as NutritionRecommendation?;
    final input = results[3] as RecommendationGenerationInput;

    final recommendation = AdaptiveNutritionRecommendationEngine.generate(
      input: input,
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      generatedAt: effectiveNow,
      algorithmVersion: algorithmVersion,
      dueWeekKey: dueWeekKey,
      previousRecommendation: previousRecommendation,
    );

    await _repository.saveLatestGeneratedRecommendation(
      recommendation: recommendation,
    );
    await _repository.setLastGeneratedDueWeekKey(dueWeekKey);

    return recommendation;
  }

  Future<NutritionRecommendation?> refreshRecommendationIfDueForMode({
    DateTime? now,
    bool force = false,
    RecommendationEstimationMode mode = RecommendationEstimationMode.heuristic,
  }) async {
    switch (mode) {
      case RecommendationEstimationMode.heuristic:
        return refreshRecommendationIfDue(now: now, force: force);
      case RecommendationEstimationMode.bayesianExperimental:
        final result = await refreshBayesianExperimentalRecommendationIfDue(
          now: now,
          force: force,
        );
        return result?.recommendation;
    }
  }

  Future<BayesianNutritionRecommendationResult?>
      getLatestBayesianExperimentalRecommendation() async {
    final results = await Future.wait<dynamic>([
      _repository.getLatestGeneratedRecommendationForMode(
        mode: RecommendationEstimationMode.bayesianExperimental,
      ),
      _repository.getLatestBayesianMaintenanceEstimate(),
    ]);

    final recommendation = results[0] as NutritionRecommendation?;
    final estimate = results[1] as BayesianMaintenanceEstimate?;
    if (recommendation == null || estimate == null) {
      return null;
    }

    return BayesianNutritionRecommendationResult(
      recommendation: recommendation,
      maintenanceEstimate: estimate,
    );
  }

  Future<BayesianNutritionRecommendationResult?>
      refreshBayesianExperimentalRecommendationIfDue({
    DateTime? now,
    bool force = false,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final dueWeekKey = RecommendationScheduler.dueWeekKeyFor(effectiveNow);
    final stableWindowEndDay =
        RecommendationScheduler.stableWindowEndDayForDueWeek(effectiveNow);
    final lastGeneratedDueWeekKey =
        await _repository.getLastGeneratedDueWeekKeyForMode(
      mode: RecommendationEstimationMode.bayesianExperimental,
    );

    if (!force &&
        !RecommendationScheduler.shouldGenerateForWeek(
          dueWeekKey: dueWeekKey,
          lastGeneratedDueWeekKey: lastGeneratedDueWeekKey,
        )) {
      return getLatestBayesianExperimentalRecommendation();
    }

    final priorActivityLevel = await _repository.getPriorActivityLevel();
    final extraCardioHoursOption =
        await _repository.getExtraCardioHoursOption();

    final results = await Future.wait<dynamic>([
      _repository.getGoal(),
      _repository.getTargetRateKgPerWeek(),
      _repository.getLatestGeneratedRecommendationForMode(
        mode: RecommendationEstimationMode.bayesianExperimental,
      ),
      _inputAdapter.buildInput(
        now: stableWindowEndDay,
        declaredActivityLevel: priorActivityLevel,
        extraCardioHoursOption: extraCardioHoursOption,
      ),
    ]);

    final goal = results[0] as BodyweightGoal;
    final targetRateKgPerWeek = results[1] as double;
    final previousRecommendation = results[2] as NutritionRecommendation?;
    final input = results[3] as RecommendationGenerationInput;

    final bayesianResult = _bayesianEngine.generate(
      input: input,
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      generatedAt: effectiveNow,
      algorithmVersion: bayesianExperimentalAlgorithmVersion,
      dueWeekKey: dueWeekKey,
      previousRecommendation: previousRecommendation,
    );

    await _repository.saveLatestGeneratedRecommendationForMode(
      mode: RecommendationEstimationMode.bayesianExperimental,
      recommendation: bayesianResult.recommendation,
    );
    await _repository.saveLatestBayesianMaintenanceEstimate(
      estimate: bayesianResult.maintenanceEstimate,
    );

    return bayesianResult;
  }

  Future<RecommendationEstimatorComparison> generateEstimatorComparison({
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final dueWeekKey = RecommendationScheduler.dueWeekKeyFor(effectiveNow);
    final stableWindowEndDay =
        RecommendationScheduler.stableWindowEndDayForDueWeek(effectiveNow);

    final priorActivityLevel = await _repository.getPriorActivityLevel();
    final extraCardioHoursOption =
        await _repository.getExtraCardioHoursOption();

    final results = await Future.wait<dynamic>([
      _repository.getGoal(),
      _repository.getTargetRateKgPerWeek(),
      _repository.getLatestGeneratedRecommendation(),
      _repository.getLatestGeneratedRecommendationForMode(
        mode: RecommendationEstimationMode.bayesianExperimental,
      ),
      _inputAdapter.buildInput(
        now: stableWindowEndDay,
        declaredActivityLevel: priorActivityLevel,
        extraCardioHoursOption: extraCardioHoursOption,
      ),
    ]);

    final goal = results[0] as BodyweightGoal;
    final targetRateKgPerWeek = results[1] as double;
    final previousHeuristic = results[2] as NutritionRecommendation?;
    final previousBayesian = results[3] as NutritionRecommendation?;
    final input = results[4] as RecommendationGenerationInput;

    final heuristic = AdaptiveNutritionRecommendationEngine.generate(
      input: input,
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      generatedAt: effectiveNow,
      algorithmVersion: algorithmVersion,
      dueWeekKey: dueWeekKey,
      previousRecommendation: previousHeuristic,
    );

    final bayesian = _bayesianEngine.generate(
      input: input,
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      generatedAt: effectiveNow,
      algorithmVersion: bayesianExperimentalAlgorithmVersion,
      dueWeekKey: dueWeekKey,
      previousRecommendation: previousBayesian,
    );

    return RecommendationEstimatorComparison(
      heuristicRecommendation: heuristic,
      bayesianRecommendation: bayesian.recommendation,
      bayesianMaintenanceEstimate: bayesian.maintenanceEstimate,
    );
  }

  Future<NutritionRecommendation> generateOnboardingRecommendation({
    required BodyweightGoal goal,
    required double targetRateKgPerWeek,
    required double? weightKg,
    required int? heightCm,
    required DateTime? birthday,
    required String? gender,
    double? bodyFatPercent,
    PriorActivityLevel? declaredActivityLevel,
    ExtraCardioHoursOption? extraCardioHoursOption,
    DateTime? now,
    bool persistGenerated = false,
    bool markAsApplied = false,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final effectiveDeclaredActivityLevel =
        declaredActivityLevel ?? await _repository.getPriorActivityLevel();
    final effectiveExtraCardioHoursOption =
        extraCardioHoursOption ?? await _repository.getExtraCardioHoursOption();

    final virtualProfile = _VirtualProfile(
      birthday: birthday,
      height: heightCm,
      gender: gender,
    );

    final priorMaintenanceCalories =
        await _estimateMaintenanceForVirtualProfile(
      profile: virtualProfile,
      weightKg: weightKg,
      bodyFatPercent: bodyFatPercent,
      declaredActivityLevel: effectiveDeclaredActivityLevel,
      extraCardioHoursOption: effectiveExtraCardioHoursOption,
      now: effectiveNow,
    );

    final input = RecommendationGenerationInput(
      windowStart: RecommendationScheduler.normalizeDay(effectiveNow),
      windowEnd: RecommendationInputAdapter.endOfDay(effectiveNow),
      windowDays: 0,
      weightLogCount: weightKg != null ? 1 : 0,
      intakeLoggedDays: 0,
      smoothedWeightSlopeKgPerWeek: null,
      avgLoggedCalories: 0,
      currentWeightKg: weightKg ?? 75,
      priorMaintenanceCalories: priorMaintenanceCalories,
      activeTargetCalories: null,
      qualityFlags: const ['onboarding_prior_only'],
    );

    final recommendation = AdaptiveNutritionRecommendationEngine.generate(
      input: input,
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      generatedAt: effectiveNow,
      algorithmVersion: algorithmVersion,
      dueWeekKey: RecommendationScheduler.dueWeekKeyFor(effectiveNow),
    );

    if (persistGenerated) {
      await _repository.saveLatestGeneratedRecommendation(
        recommendation: recommendation,
      );
      await _repository.setLastGeneratedDueWeekKey(
        recommendation.dueWeekKey ??
            RecommendationScheduler.dueWeekKeyFor(effectiveNow),
      );
      if (markAsApplied) {
        await _repository.saveLatestAppliedRecommendation(
          recommendation: recommendation,
        );
      }
    }

    return recommendation;
  }

  Future<NutritionRecommendation> generateOnboardingRecommendationForMode({
    required BodyweightGoal goal,
    required double targetRateKgPerWeek,
    required double? weightKg,
    required int? heightCm,
    required DateTime? birthday,
    required String? gender,
    double? bodyFatPercent,
    PriorActivityLevel? declaredActivityLevel,
    ExtraCardioHoursOption? extraCardioHoursOption,
    DateTime? now,
    bool persistGenerated = false,
    bool markAsApplied = false,
    RecommendationEstimationMode mode = RecommendationEstimationMode.heuristic,
  }) async {
    switch (mode) {
      case RecommendationEstimationMode.heuristic:
        return generateOnboardingRecommendation(
          goal: goal,
          targetRateKgPerWeek: targetRateKgPerWeek,
          weightKg: weightKg,
          heightCm: heightCm,
          birthday: birthday,
          gender: gender,
          bodyFatPercent: bodyFatPercent,
          declaredActivityLevel: declaredActivityLevel,
          extraCardioHoursOption: extraCardioHoursOption,
          now: now,
          persistGenerated: persistGenerated,
          markAsApplied: markAsApplied,
        );
      case RecommendationEstimationMode.bayesianExperimental:
        final result =
            await generateBayesianExperimentalOnboardingRecommendation(
          goal: goal,
          targetRateKgPerWeek: targetRateKgPerWeek,
          weightKg: weightKg,
          heightCm: heightCm,
          birthday: birthday,
          gender: gender,
          bodyFatPercent: bodyFatPercent,
          declaredActivityLevel: declaredActivityLevel,
          extraCardioHoursOption: extraCardioHoursOption,
          now: now,
          persistGenerated: persistGenerated,
        );
        return result.recommendation;
    }
  }

  Future<BayesianNutritionRecommendationResult>
      generateBayesianExperimentalOnboardingRecommendation({
    required BodyweightGoal goal,
    required double targetRateKgPerWeek,
    required double? weightKg,
    required int? heightCm,
    required DateTime? birthday,
    required String? gender,
    double? bodyFatPercent,
    PriorActivityLevel? declaredActivityLevel,
    ExtraCardioHoursOption? extraCardioHoursOption,
    DateTime? now,
    bool persistGenerated = false,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final effectiveDeclaredActivityLevel =
        declaredActivityLevel ?? await _repository.getPriorActivityLevel();
    final effectiveExtraCardioHoursOption =
        extraCardioHoursOption ?? await _repository.getExtraCardioHoursOption();

    final virtualProfile = _VirtualProfile(
      birthday: birthday,
      height: heightCm,
      gender: gender,
    );

    final priorMaintenanceCalories =
        await _estimateMaintenanceForVirtualProfile(
      profile: virtualProfile,
      weightKg: weightKg,
      bodyFatPercent: bodyFatPercent,
      declaredActivityLevel: effectiveDeclaredActivityLevel,
      extraCardioHoursOption: effectiveExtraCardioHoursOption,
      now: effectiveNow,
    );

    final input = RecommendationGenerationInput(
      windowStart: RecommendationScheduler.normalizeDay(effectiveNow),
      windowEnd: RecommendationInputAdapter.endOfDay(effectiveNow),
      windowDays: 0,
      weightLogCount: weightKg != null ? 1 : 0,
      intakeLoggedDays: 0,
      smoothedWeightSlopeKgPerWeek: null,
      avgLoggedCalories: 0,
      currentWeightKg: weightKg ?? 75,
      priorMaintenanceCalories: priorMaintenanceCalories,
      activeTargetCalories: null,
      qualityFlags: const ['onboarding_prior_only'],
    );

    final recommendation = _bayesianEngine.generate(
      input: input,
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      generatedAt: effectiveNow,
      algorithmVersion: bayesianExperimentalAlgorithmVersion,
      dueWeekKey: RecommendationScheduler.dueWeekKeyFor(effectiveNow),
    );

    if (persistGenerated) {
      await _repository.saveLatestGeneratedRecommendationForMode(
        mode: RecommendationEstimationMode.bayesianExperimental,
        recommendation: recommendation.recommendation,
      );
      await _repository.setLastGeneratedDueWeekKeyForMode(
        mode: RecommendationEstimationMode.bayesianExperimental,
        dueWeekKey: recommendation.recommendation.dueWeekKey ??
            RecommendationScheduler.dueWeekKeyFor(effectiveNow),
      );
      await _repository.saveLatestBayesianMaintenanceEstimate(
        estimate: recommendation.maintenanceEstimate,
      );
    }

    return recommendation;
  }

  Future<void> persistGeneratedRecommendation({
    required NutritionRecommendation recommendation,
    bool markAsApplied = false,
  }) async {
    await _repository.saveLatestGeneratedRecommendation(
      recommendation: recommendation,
    );
    await _repository.setLastGeneratedDueWeekKey(
      recommendation.dueWeekKey ??
          RecommendationScheduler.dueWeekKeyFor(recommendation.generatedAt),
    );
    if (markAsApplied) {
      await _repository.saveLatestAppliedRecommendation(
        recommendation: recommendation,
      );
    }
  }

  Future<bool> applyLatestRecommendationToActiveTargets() async {
    final recommendation = await _repository.getLatestGeneratedRecommendation();
    if (recommendation == null) {
      return false;
    }

    final settings = await _databaseHelper.getAppSettings();
    final steps = settings?.targetSteps ??
        await _databaseHelper.getCurrentTargetStepsOrDefault();
    final water = settings?.targetWater ?? 3000;

    await _databaseHelper.saveUserGoals(
      calories: recommendation.recommendedCalories,
      protein: recommendation.recommendedProteinGrams,
      carbs: recommendation.recommendedCarbsGrams,
      fat: recommendation.recommendedFatGrams,
      water: water,
      steps: steps,
    );

    await _repository.saveLatestAppliedRecommendation(
      recommendation: recommendation,
    );

    return true;
  }

  Future<int> _estimateMaintenanceForVirtualProfile({
    required _VirtualProfile profile,
    required double? weightKg,
    required double? bodyFatPercent,
    required PriorActivityLevel declaredActivityLevel,
    required ExtraCardioHoursOption extraCardioHoursOption,
    required DateTime now,
  }) async {
    final persistedProfile = await _databaseHelper.getUserProfile();
    final persistedBodyFatPercent =
        await _databaseHelper.getLatestBodyFatPercentageBefore(now);
    final effectiveBodyFatPercent = bodyFatPercent ?? persistedBodyFatPercent;
    final averageCompletedWorkoutsPerWeek =
        await _databaseHelper.getAverageCompletedWorkoutsPerWeek(now: now);
    final targetSteps = (await _databaseHelper.getAppSettings())?.targetSteps ??
        await _databaseHelper.getCurrentTargetStepsOrDefault();
    final recentAverageActualSteps =
        await RecommendationInputAdapter.loadRecentAverageActualSteps(
      databaseHelper: _databaseHelper,
      endDay: RecommendationInputAdapter.normalizeDay(now),
      lookbackDays: RecommendationInputAdapter.defaultPriorStepsLookbackDays,
    );

    final mergedProfile = _VirtualProfile(
      birthday: profile.birthday ?? persistedProfile?.birthday,
      height: profile.height ?? persistedProfile?.height,
      gender: profile.gender ?? persistedProfile?.gender,
    );

    final asDbProfile = db.Profile(
      localId: 0,
      id: 'virtual',
      username: null,
      isCoach: false,
      visibility: 'private',
      birthday: mergedProfile.birthday,
      height: mergedProfile.height,
      gender: mergedProfile.gender,
      profileImagePath: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deletedAt: null,
    );

    return RecommendationInputAdapter.estimatePriorMaintenanceCalories(
      profile: asDbProfile,
      currentWeightKg: weightKg ?? 75,
      bodyFatPercent: effectiveBodyFatPercent,
      declaredActivityLevel: declaredActivityLevel,
      extraCardioHoursOption: extraCardioHoursOption,
      averageCompletedWorkoutsPerWeek: averageCompletedWorkoutsPerWeek,
      targetSteps: targetSteps,
      recentAverageSteps: recentAverageActualSteps,
      now: now,
    );
  }
}

class _VirtualProfile {
  final DateTime? birthday;
  final int? height;
  final String? gender;

  const _VirtualProfile({
    required this.birthday,
    required this.height,
    required this.gender,
  });
}
