import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart' as db;
import '../domain/goal_models.dart';
import '../domain/recommendation_engine.dart';
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

class AdaptiveNutritionRecommendationService {
  static const String algorithmVersion = 'tdee_adaptive_recommendation_0_8_mvp';

  final RecommendationRepository _repository;
  final RecommendationInputAdapter _inputAdapter;
  final DatabaseHelper _databaseHelper;

  AdaptiveNutritionRecommendationService({
    RecommendationRepository? repository,
    RecommendationInputAdapter? inputAdapter,
    DatabaseHelper? databaseHelper,
  })  : _repository = repository ?? RecommendationRepository(),
        _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
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

    final results = await Future.wait<dynamic>([
      _repository.getGoal(),
      _repository.getTargetRateKgPerWeek(),
      _repository.getLatestGeneratedRecommendation(),
      _inputAdapter.buildInput(now: stableWindowEndDay),
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

  Future<NutritionRecommendation> generateOnboardingRecommendation({
    required BodyweightGoal goal,
    required double targetRateKgPerWeek,
    required double? weightKg,
    required int? heightCm,
    required DateTime? birthday,
    required String? gender,
    DateTime? now,
    bool persistGenerated = false,
    bool markAsApplied = false,
  }) async {
    final effectiveNow = now ?? DateTime.now();

    final virtualProfile = _VirtualProfile(
      birthday: birthday,
      height: heightCm,
      gender: gender,
    );

    final priorMaintenanceCalories =
        await _estimateMaintenanceForVirtualProfile(
      profile: virtualProfile,
      weightKg: weightKg,
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
    required DateTime now,
  }) async {
    final persistedProfile = await _databaseHelper.getUserProfile();

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
