import 'dart:math' as math;

import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart' as db;
import '../domain/adaptive_recommendation_snapshot.dart';
import '../domain/bayesian_recommendation_engine.dart';
import '../domain/bayesian_tdee_estimator.dart';
import '../domain/goal_models.dart';
import '../domain/recommendation_models.dart';
import 'recommendation_due_notification.dart';
import 'recommendation_input_adapter.dart';
import 'recommendation_repository.dart';
import 'recommendation_scheduler.dart';

class AdaptiveNutritionRecommendationState {
  final BodyweightGoal goal;
  final double targetRateKgPerWeek;
  final NutritionRecommendation? latestGeneratedRecommendation;
  final BayesianMaintenanceEstimate? latestMaintenanceEstimate;
  final NutritionRecommendation? latestAppliedRecommendation;
  final DateTime? latestGeneratedAt;
  final DateTime nextAdaptiveRecommendationDueAt;
  final bool isAdaptiveRecommendationDueNow;
  final String currentDueWeekKey;

  const AdaptiveNutritionRecommendationState({
    required this.goal,
    required this.targetRateKgPerWeek,
    required this.latestGeneratedRecommendation,
    required this.latestMaintenanceEstimate,
    required this.latestAppliedRecommendation,
    required this.latestGeneratedAt,
    required this.nextAdaptiveRecommendationDueAt,
    required this.isAdaptiveRecommendationDueNow,
    required this.currentDueWeekKey,
  });
}

class AdaptiveNutritionRecommendationService {
  static const String algorithmVersion =
      'tdee_adaptive_recommendation_1_0_bayesian_recursive';

  final RecommendationRepository _repository;
  final RecommendationInputAdapter _inputAdapter;
  final DatabaseHelper _databaseHelper;
  final BayesianNutritionRecommendationEngine _bayesianEngine;
  final AdaptiveRecommendationDueNotifier _dueNotifier;

  AdaptiveNutritionRecommendationService({
    RecommendationRepository? repository,
    RecommendationInputAdapter? inputAdapter,
    DatabaseHelper? databaseHelper,
    BayesianNutritionRecommendationEngine? bayesianEngine,
    AdaptiveRecommendationDueNotifier? dueNotifier,
  })  : _repository = repository ?? RecommendationRepository(),
        _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
        _bayesianEngine =
            bayesianEngine ?? const BayesianNutritionRecommendationEngine(),
        _dueNotifier =
            dueNotifier ?? const LocalAdaptiveRecommendationDueNotifier(),
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

  /// Manual product action:
  /// - recompute immediately
  /// - still anchored to the stable due-week input window (previous Sunday)
  /// - does not apply active targets
  Future<NutritionRecommendation?> recalculateRecommendationNow({
    DateTime? now,
  }) {
    return refreshRecommendationIfDue(now: now, force: true);
  }

  /// Scheduler-oriented notification hook.
  ///
  /// Notification is sent only when all conditions are true:
  /// 1. recommendation is currently due for this due week
  /// 2. no recommendation has been generated for this due week yet
  /// 3. no due-notification has been sent for this due week yet
  Future<bool> notifyIfNewRecommendationDue({
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final dueWeekKey = RecommendationScheduler.dueWeekKeyFor(effectiveNow);
    final lastGeneratedDueWeekKey =
        await _repository.getLastGeneratedDueWeekKey();
    final latestGeneratedRecommendation =
        await _repository.getLatestGeneratedRecommendation();
    final generatedDueWeekFromSnapshot =
        latestGeneratedRecommendation?.dueWeekKey;

    final isDueForCurrentWeek = RecommendationScheduler.shouldGenerateForWeek(
      dueWeekKey: dueWeekKey,
      lastGeneratedDueWeekKey: lastGeneratedDueWeekKey,
    );
    if (!isDueForCurrentWeek) {
      return false;
    }

    final hasGeneratedForCurrentDueWeek =
        lastGeneratedDueWeekKey == dueWeekKey ||
            generatedDueWeekFromSnapshot == dueWeekKey;
    if (hasGeneratedForCurrentDueWeek) {
      return false;
    }

    final lastNotifiedDueWeekKey =
        await _repository.getLastDueNotificationWeekKey();
    if (lastNotifiedDueWeekKey == dueWeekKey) {
      return false;
    }

    await _dueNotifier.notifyRecommendationDue(
      dueWeekKey: dueWeekKey,
      dueAt: RecommendationScheduler.dueWeekStart(effectiveNow),
    );
    await _repository.setLastDueNotificationWeekKey(dueWeekKey);
    return true;
  }

  Future<AdaptiveNutritionRecommendationState> loadState({
    DateTime? now,
    bool refreshIfDue = true,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    if (refreshIfDue) {
      await refreshRecommendationIfDue(now: effectiveNow);
    }

    final results = await Future.wait<dynamic>([
      _repository.getGoal(),
      _repository.getTargetRateKgPerWeek(),
      _repository.getLatestRecommendationSnapshot(),
      _repository.getLatestAppliedRecommendation(),
      _repository.getLastGeneratedDueWeekKey(),
    ]);

    final latestSnapshot = results[2] as AdaptiveRecommendationSnapshot?;
    final latestGeneratedRecommendation = latestSnapshot?.recommendation;
    final latestMaintenanceEstimate = latestSnapshot?.maintenanceEstimate;
    final lastGeneratedDueWeekKey = results[4] as String?;
    final currentDueWeekKey =
        RecommendationScheduler.dueWeekKeyFor(effectiveNow);
    final isAdaptiveRecommendationDueNow = RecommendationScheduler.isDueNow(
      now: effectiveNow,
      lastGeneratedDueWeekKey: lastGeneratedDueWeekKey,
    );
    final nextAdaptiveRecommendationDueAt = RecommendationScheduler.nextDueAt(
      now: effectiveNow,
      lastGeneratedDueWeekKey: lastGeneratedDueWeekKey,
    );

    return AdaptiveNutritionRecommendationState(
      goal: results[0] as BodyweightGoal,
      targetRateKgPerWeek: results[1] as double,
      latestGeneratedRecommendation: latestGeneratedRecommendation,
      latestMaintenanceEstimate: latestMaintenanceEstimate,
      latestAppliedRecommendation: results[3] as NutritionRecommendation?,
      latestGeneratedAt: latestGeneratedRecommendation?.generatedAt,
      nextAdaptiveRecommendationDueAt: nextAdaptiveRecommendationDueAt,
      isAdaptiveRecommendationDueNow: isAdaptiveRecommendationDueNow,
      currentDueWeekKey: currentDueWeekKey,
    );
  }

  Future<NutritionRecommendation?> refreshRecommendationIfDue({
    DateTime? now,
    bool force = false,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final dueWeekKey = RecommendationScheduler.dueWeekKeyFor(effectiveNow);
    // Keep the adaptive input window stable within one due week by anchoring to
    // the previous Sunday end-of-day. This makes in-week force refreshes
    // deterministic instead of drifting with "today".
    final stableWindowEndDay =
        RecommendationScheduler.stableWindowEndDayForDueWeek(effectiveNow);
    final latestContext = await Future.wait<dynamic>([
      _repository.getLatestRecommendationSnapshot(),
      _repository.getLatestEstimatorState(),
    ]);
    final latestSnapshot = latestContext[0] as AdaptiveRecommendationSnapshot?;
    final latestRecursiveState = latestContext[1] as BayesianEstimatorState?;
    final lastGeneratedDueWeekKey = latestSnapshot?.dueWeekKey ??
        await _repository.getLastGeneratedDueWeekKey();

    if (!force &&
        !RecommendationScheduler.shouldGenerateForWeek(
          dueWeekKey: dueWeekKey,
          lastGeneratedDueWeekKey: lastGeneratedDueWeekKey,
        )) {
      // No regeneration for the same due week unless explicitly forced.
      return latestSnapshot?.recommendation;
    }

    final priorActivityLevel = await _repository.getPriorActivityLevel();
    final extraCardioHoursOption =
        await _repository.getExtraCardioHoursOption();

    final results = await Future.wait<dynamic>([
      _repository.getGoal(),
      _repository.getTargetRateKgPerWeek(),
      _inputAdapter.buildInput(
        now: stableWindowEndDay,
        declaredActivityLevel: priorActivityLevel,
        extraCardioHoursOption: extraCardioHoursOption,
      ),
    ]);

    final goal = results[0] as BodyweightGoal;
    final targetRateKgPerWeek = results[1] as double;
    final input = results[2] as RecommendationGenerationInput;
    final previousRecommendation = latestSnapshot?.recommendation;

    final result = _bayesianEngine.generate(
      input: input,
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      generatedAt: effectiveNow,
      algorithmVersion: algorithmVersion,
      dueWeekKey: dueWeekKey,
      recursiveState: latestRecursiveState,
      previousRecommendation: previousRecommendation,
    );

    await _repository.saveLatestRecommendationSnapshot(
      snapshot: AdaptiveRecommendationSnapshot(
        recommendation: result.recommendation,
        maintenanceEstimate: result.maintenanceEstimate,
        dueWeekKey: dueWeekKey,
        algorithmVersion: algorithmVersion,
      ),
    );
    if (result.recursiveState != null && result.recursiveState!.isValid) {
      await _repository.saveLatestEstimatorState(state: result.recursiveState!);
    }
    // Generation only updates adaptive recommendation state.
    // It never mutates active goals; apply remains an explicit user action.

    return result.recommendation;
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
    final preview = await generateOnboardingRecommendationPreview(
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
    return preview.recommendation;
  }

  Future<BayesianNutritionRecommendationResult>
      generateOnboardingRecommendationPreview({
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
      // Onboarding has no adaptive observation history yet. We bootstrap the
      // recursive filter from a profile-based prior and let weekly updates
      // refine from real logs later.
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

    final dueWeekKey = RecommendationScheduler.dueWeekKeyFor(effectiveNow);
    final result = _bayesianEngine.generate(
      input: input,
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      generatedAt: effectiveNow,
      algorithmVersion: algorithmVersion,
      dueWeekKey: dueWeekKey,
      recursiveState: null,
      previousRecommendation: null,
    );

    if (persistGenerated) {
      await _repository.saveLatestRecommendationSnapshot(
        snapshot: AdaptiveRecommendationSnapshot(
          recommendation: result.recommendation,
          maintenanceEstimate: result.maintenanceEstimate,
          dueWeekKey: dueWeekKey,
          algorithmVersion: algorithmVersion,
        ),
      );
      if (result.recursiveState != null && result.recursiveState!.isValid) {
        await _repository.saveLatestEstimatorState(
            state: result.recursiveState!);
      }
      if (markAsApplied) {
        await _repository.saveLatestAppliedRecommendation(
          recommendation: result.recommendation,
        );
      }
    }

    return result;
  }

  Future<void> persistGeneratedRecommendation({
    required NutritionRecommendation recommendation,
    bool markAsApplied = false,
  }) async {
    final dueWeekKey = recommendation.dueWeekKey ??
        RecommendationScheduler.dueWeekKeyFor(recommendation.generatedAt);
    final syntheticEstimate = BayesianMaintenanceEstimate(
      posteriorMaintenanceCalories:
          recommendation.estimatedMaintenanceCalories.toDouble(),
      posteriorStdDevCalories:
          const BayesianEstimatorConfig().priorStdDevCalories,
      profilePriorMaintenanceCalories:
          recommendation.estimatedMaintenanceCalories.toDouble(),
      priorMeanUsedCalories:
          recommendation.estimatedMaintenanceCalories.toDouble(),
      priorStdDevUsedCalories:
          const BayesianEstimatorConfig().priorStdDevCalories,
      priorSource: BayesianPriorSource.profilePriorBootstrap,
      observedIntakeCalories: null,
      observedWeightSlopeKgPerWeek: null,
      observationImpliedMaintenanceCalories: null,
      effectiveSampleSize: 0,
      confidence: recommendation.confidence,
      qualityFlags: const ['persisted_recommendation_without_estimate'],
      debugInfo: const {'persistedFrom': 'persistGeneratedRecommendation'},
      dueWeekKey: dueWeekKey,
    );
    final state = BayesianEstimatorState(
      posteriorMeanCalories:
          recommendation.estimatedMaintenanceCalories.toDouble(),
      posteriorVarianceCalories2: math
          .pow(const BayesianEstimatorConfig().priorStdDevCalories, 2)
          .toDouble(),
      lastDueWeekKey: dueWeekKey,
      lastPriorMeanCalories:
          recommendation.estimatedMaintenanceCalories.toDouble(),
      lastPriorVarianceCalories2: math
          .pow(const BayesianEstimatorConfig().priorStdDevCalories, 2)
          .toDouble(),
      lastPriorSource: BayesianPriorSource.profilePriorBootstrap,
      lastObservationUsed: false,
    );

    await _repository.saveLatestGeneratedRecommendation(
      recommendation: recommendation,
      maintenanceEstimate: syntheticEstimate,
      recursiveState: state,
    );
    await _repository.setLastGeneratedDueWeekKey(dueWeekKey);
    if (markAsApplied) {
      await _repository.saveLatestAppliedRecommendation(
        recommendation: recommendation,
      );
    }
  }

  Future<bool> applyLatestRecommendationToActiveTargets() async {
    // Explicit apply action only. If nothing is generated yet, do nothing.
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
