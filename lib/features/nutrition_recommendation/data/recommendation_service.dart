import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart' as db;
import '../domain/bayesian_recommendation_engine.dart';
import '../domain/bayesian_experimental_snapshot.dart';
import '../domain/bayesian_tdee_estimator.dart';
import '../domain/confidence_models.dart';
import '../domain/goal_models.dart';
import '../domain/recommendation_engine.dart';
import '../domain/recommendation_estimation_mode.dart';
import '../domain/recommendation_models.dart';
import 'recommendation_due_notification.dart';
import 'recommendation_input_adapter.dart';
import 'recommendation_repository.dart';
import 'recommendation_scheduler.dart';

class AdaptiveNutritionRecommendationState {
  final BodyweightGoal goal;
  final double targetRateKgPerWeek;
  final NutritionRecommendation? latestGeneratedRecommendation;
  final NutritionRecommendation? latestAppliedRecommendation;
  final DateTime? latestGeneratedAt;
  final DateTime nextAdaptiveRecommendationDueAt;
  final bool isAdaptiveRecommendationDueNow;
  final String currentDueWeekKey;

  const AdaptiveNutritionRecommendationState({
    required this.goal,
    required this.targetRateKgPerWeek,
    required this.latestGeneratedRecommendation,
    required this.latestAppliedRecommendation,
    required this.latestGeneratedAt,
    required this.nextAdaptiveRecommendationDueAt,
    required this.isAdaptiveRecommendationDueNow,
    required this.currentDueWeekKey,
  });
}

class RecommendationEstimatorComparison {
  final String dueWeekKey;
  final DateTime generatedAt;
  final NutritionRecommendation heuristicRecommendation;
  final NutritionRecommendation bayesianRecommendation;
  final BayesianMaintenanceEstimate bayesianMaintenanceEstimate;

  const RecommendationEstimatorComparison({
    required this.dueWeekKey,
    required this.generatedAt,
    required this.heuristicRecommendation,
    required this.bayesianRecommendation,
    required this.bayesianMaintenanceEstimate,
  });

  int get maintenanceDeltaCalories {
    return maintenanceDeltaVsHeuristicCalories;
  }

  int get heuristicEstimatedMaintenanceCalories {
    return heuristicRecommendation.estimatedMaintenanceCalories;
  }

  int get bayesianPosteriorMaintenanceCalories {
    return bayesianRecommendation.estimatedMaintenanceCalories;
  }

  double get bayesianProfilePriorCalories {
    return bayesianMaintenanceEstimate.profilePriorMaintenanceCalories;
  }

  double get bayesianPriorMeanCalories {
    return bayesianMaintenanceEstimate.priorMeanUsedCalories;
  }

  double get bayesianPriorStdDevCalories {
    return bayesianMaintenanceEstimate.priorStdDevUsedCalories;
  }

  double get bayesianPosteriorStdDevCalories {
    return bayesianMaintenanceEstimate.posteriorStdDevCalories;
  }

  double? get bayesianObservationImpliedMaintenanceCalories {
    return bayesianMaintenanceEstimate.observationImpliedMaintenanceCalories;
  }

  int get maintenanceDeltaVsHeuristicCalories {
    return bayesianRecommendation.estimatedMaintenanceCalories -
        heuristicRecommendation.estimatedMaintenanceCalories;
  }

  double get maintenanceDeltaVsBayesianPriorCalories {
    return bayesianRecommendation.estimatedMaintenanceCalories -
        bayesianMaintenanceEstimate.priorMeanUsedCalories;
  }

  double get bayesianEffectiveSampleSize {
    return bayesianMaintenanceEstimate.effectiveSampleSize;
  }

  RecommendationConfidence get bayesianConfidenceBucket {
    return bayesianMaintenanceEstimate.confidence;
  }

  List<String> get bayesianQualityFlags {
    return bayesianMaintenanceEstimate.qualityFlags;
  }

  int get windowDays {
    return bayesianRecommendation.inputSummary.windowDays;
  }

  int get weightLogCount {
    return bayesianRecommendation.inputSummary.weightLogCount;
  }

  int get intakeLoggedDays {
    return bayesianRecommendation.inputSummary.intakeLoggedDays;
  }

  double? get smoothedWeightSlopeKgPerWeek {
    return bayesianRecommendation.inputSummary.smoothedWeightSlopeKgPerWeek;
  }

  double get avgLoggedCalories {
    return bayesianRecommendation.inputSummary.avgLoggedCalories;
  }

  Map<String, Object?> toDebugTrace() {
    return <String, Object?>{
      'dueWeekKey': dueWeekKey,
      'generatedAt': generatedAt.toIso8601String(),
      'heuristicEstimatedMaintenanceCalories':
          heuristicEstimatedMaintenanceCalories,
      'bayesianProfilePriorCalories': bayesianProfilePriorCalories,
      'bayesianPriorMeanCalories': bayesianPriorMeanCalories,
      'bayesianPriorStdDevCalories': bayesianPriorStdDevCalories,
      'bayesianPosteriorMaintenanceCalories':
          bayesianMaintenanceEstimate.posteriorMaintenanceCalories,
      'bayesianPosteriorStdDevCalories': bayesianPosteriorStdDevCalories,
      'bayesianObservationImpliedMaintenanceCalories':
          bayesianObservationImpliedMaintenanceCalories,
      'bayesianEffectiveSampleSize': bayesianEffectiveSampleSize,
      'bayesianConfidenceBucket': bayesianConfidenceBucket.name,
      'bayesianQualityFlags': bayesianQualityFlags,
      'maintenanceDeltaVsHeuristicCalories':
          maintenanceDeltaVsHeuristicCalories,
      'maintenanceDeltaVsBayesianPriorCalories':
          maintenanceDeltaVsBayesianPriorCalories,
      'windowDays': windowDays,
      'weightLogCount': weightLogCount,
      'intakeLoggedDays': intakeLoggedDays,
      'smoothedWeightSlopeKgPerWeek': smoothedWeightSlopeKgPerWeek,
      'avgLoggedCalories': avgLoggedCalories,
    };
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

  /// Scheduler-oriented notification hook (simple first version).
  ///
  /// Notification is sent only when all conditions are true:
  /// 1. a recommendation is currently due for this due week,
  /// 2. no recommendation has been generated for this due week yet,
  /// 3. no due-notification has been sent for this due week yet.
  ///
  /// This remains strictly scheduler-based (no model-delta logic),
  /// and does not auto-apply goals.
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
      _repository.getLatestGeneratedRecommendation(),
      _repository.getLatestAppliedRecommendation(),
      _repository.getLastGeneratedDueWeekKey(),
    ]);

    final latestGeneratedRecommendation =
        results[2] as NutritionRecommendation?;
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
    final snapshot = await _repository.getLatestBayesianExperimentalSnapshot();
    if (snapshot == null) {
      return null;
    }

    return BayesianNutritionRecommendationResult(
      recommendation: snapshot.recommendation,
      maintenanceEstimate: snapshot.maintenanceEstimate,
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
    // Stable previous-Sunday anchoring is the first determinism guard:
    // all generations inside the same due week use the same data window
    // regardless of app-open timing.
    final latestSnapshot =
        await _repository.getLatestBayesianExperimentalSnapshot();
    final coherentLatest = latestSnapshot == null
        ? null
        : BayesianNutritionRecommendationResult(
            recommendation: latestSnapshot.recommendation,
            maintenanceEstimate: latestSnapshot.maintenanceEstimate,
          );
    final lastGeneratedDueWeekKey = latestSnapshot?.dueWeekKey;

    if (!force &&
        !RecommendationScheduler.shouldGenerateForWeek(
          dueWeekKey: dueWeekKey,
          lastGeneratedDueWeekKey: lastGeneratedDueWeekKey,
        )) {
      // Same due week: return the already generated coherent snapshot.
      if (coherentLatest != null) {
        return coherentLatest;
      }
    }

    final priorActivityLevel = await _repository.getPriorActivityLevel();
    final extraCardioHoursOption =
        await _repository.getExtraCardioHoursOption();

    final results = await Future.wait<dynamic>([
      _repository.getGoal(),
      _repository.getTargetRateKgPerWeek(),
      _inputAdapter.buildInput(
        // Stable previous-Sunday boundary keeps in-week window data fixed.
        // This is the first guard against in-week drift, independent of
        // recursive-prior replay behavior.
        now: stableWindowEndDay,
        declaredActivityLevel: priorActivityLevel,
        extraCardioHoursOption: extraCardioHoursOption,
      ),
    ]);

    final goal = results[0] as BodyweightGoal;
    final targetRateKgPerWeek = results[1] as double;
    final previousRecommendation = coherentLatest?.recommendation;
    final latestEstimate = coherentLatest?.maintenanceEstimate;
    final input = results[2] as RecommendationGenerationInput;
    final chainedPrior = _resolveChainedBayesianPrior(
      input: input,
      latestEstimate: latestEstimate,
      dueWeekKey: dueWeekKey,
    );

    final bayesianResult = _bayesianEngine.generate(
      input: input,
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      generatedAt: effectiveNow,
      algorithmVersion: bayesianExperimentalAlgorithmVersion,
      dueWeekKey: dueWeekKey,
      chainedPrior: chainedPrior,
      previousRecommendation: previousRecommendation,
    );

    final snapshot = BayesianExperimentalRecommendationSnapshot(
      recommendation: bayesianResult.recommendation,
      maintenanceEstimate: bayesianResult.maintenanceEstimate,
      dueWeekKey: dueWeekKey,
      algorithmVersion: bayesianExperimentalAlgorithmVersion,
    );

    await _repository.saveLatestBayesianExperimentalSnapshot(
      snapshot: snapshot,
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
      _repository.getLatestBayesianExperimentalSnapshot(),
      _inputAdapter.buildInput(
        now: stableWindowEndDay,
        declaredActivityLevel: priorActivityLevel,
        extraCardioHoursOption: extraCardioHoursOption,
      ),
    ]);

    final goal = results[0] as BodyweightGoal;
    final targetRateKgPerWeek = results[1] as double;
    final previousHeuristic = results[2] as NutritionRecommendation?;
    final latestBayesianSnapshot =
        results[3] as BayesianExperimentalRecommendationSnapshot?;
    final previousBayesian = latestBayesianSnapshot?.recommendation;
    final latestBayesianEstimate = latestBayesianSnapshot?.maintenanceEstimate;
    final input = results[4] as RecommendationGenerationInput;
    final chainedPrior = _resolveChainedBayesianPrior(
      input: input,
      latestEstimate: latestBayesianEstimate,
      dueWeekKey: dueWeekKey,
    );

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
      chainedPrior: chainedPrior,
      previousRecommendation: previousBayesian,
    );

    return RecommendationEstimatorComparison(
      dueWeekKey: dueWeekKey,
      generatedAt: effectiveNow,
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
        if (markAsApplied) {
          throw ArgumentError.value(
            markAsApplied,
            'markAsApplied',
            'markAsApplied is not supported in bayesianExperimental mode; '
                'experimental onboarding generation cannot apply active targets.',
          );
        }
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
      final dueWeekKey = recommendation.recommendation.dueWeekKey ??
          RecommendationScheduler.dueWeekKeyFor(effectiveNow);
      await _repository.saveLatestBayesianExperimentalSnapshot(
        snapshot: BayesianExperimentalRecommendationSnapshot(
          recommendation: recommendation.recommendation,
          maintenanceEstimate: recommendation.maintenanceEstimate,
          dueWeekKey: dueWeekKey,
          algorithmVersion: bayesianExperimentalAlgorithmVersion,
        ),
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

  BayesianMaintenancePrior _resolveChainedBayesianPrior({
    required RecommendationGenerationInput input,
    required BayesianMaintenanceEstimate? latestEstimate,
    required String dueWeekKey,
  }) {
    // Bootstrap fallback path:
    // use profile/activity/body-fat prior when there is no valid prior
    // experimental state (missing/corrupt/unreadable/invalid).
    final profileBootstrapPrior = BayesianMaintenancePrior(
      meanCalories: input.priorMaintenanceCalories.toDouble(),
      stdDevCalories: const BayesianEstimatorConfig().priorStdDevCalories,
      source: BayesianPriorSource.profilePriorBootstrap,
    );

    if (latestEstimate == null ||
        !_isValidEstimateForChaining(latestEstimate)) {
      return profileBootstrapPrior;
    }

    if (latestEstimate.dueWeekKey == dueWeekKey) {
      // Same due week forced regeneration:
      // replay the prior-used fields that were stored for this week instead of
      // chaining from a same-week posterior. This avoids in-week drift when
      // force-regenerating repeatedly.
      final replayPrior = BayesianMaintenancePrior(
        meanCalories: latestEstimate.priorMeanUsedCalories,
        stdDevCalories: latestEstimate.priorStdDevUsedCalories,
        source: latestEstimate.priorSource,
      );
      if (_isValidPrior(replayPrior)) {
        return replayPrior;
      }
      return profileBootstrapPrior;
    }

    // Previous due week -> new due week recursive chaining:
    // previous posterior becomes current prior, then process-noise inflation
    // happens inside the Bayesian estimator before update.
    final chainedPrior = BayesianMaintenancePrior(
      meanCalories: latestEstimate.posteriorMaintenanceCalories,
      stdDevCalories: latestEstimate.posteriorStdDevCalories,
      source: BayesianPriorSource.chainedPosterior,
    );
    if (_isValidPrior(chainedPrior)) {
      return chainedPrior;
    }

    return profileBootstrapPrior;
  }

  bool _isValidEstimateForChaining(BayesianMaintenanceEstimate estimate) {
    return estimate.posteriorMaintenanceCalories.isFinite &&
        estimate.posteriorStdDevCalories.isFinite &&
        estimate.posteriorStdDevCalories > 0 &&
        estimate.priorMeanUsedCalories.isFinite &&
        estimate.priorStdDevUsedCalories.isFinite &&
        estimate.priorStdDevUsedCalories > 0;
  }

  bool _isValidPrior(BayesianMaintenancePrior prior) {
    return prior.meanCalories.isFinite &&
        prior.stdDevCalories.isFinite &&
        prior.stdDevCalories > 0;
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
