import 'package:flutter/material.dart';

import '../../../data/database_helper.dart';
import '../../nutrition_recommendation/data/recommendation_repository.dart';
import '../../nutrition_recommendation/data/recommendation_service.dart';
import '../../nutrition_recommendation/domain/adaptive_diet_phase.dart';
import '../../nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
import '../../nutrition_recommendation/domain/recommendation_models.dart';
import '../domain/feedback_report_builder.dart';

class AdaptiveNutritionDiagnosticsProvider
    implements FeedbackReportDiagnosticsProvider {
  final AdaptiveNutritionRecommendationService _recommendationService;
  final RecommendationRepository _repository;
  final DatabaseHelper _databaseHelper;

  AdaptiveNutritionDiagnosticsProvider({
    AdaptiveNutritionRecommendationService? recommendationService,
    RecommendationRepository? repository,
    DatabaseHelper? databaseHelper,
  })  : _recommendationService =
            recommendationService ?? AdaptiveNutritionRecommendationService(),
        _repository = repository ?? RecommendationRepository(),
        _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  @override
  Future<List<String>> buildLines({required DateTime now}) async {
    final lines = <String>[];

    final recommendationState =
        await _recommendationService.loadState(now: now, refreshIfDue: false);
    final snapshot = await _repository.getLatestRecommendationSnapshot();
    final estimatorState = await _repository.getLatestEstimatorState();
    final phaseState = await _repository.getDietPhaseTrackingState();
    final goals = await _databaseHelper.getGoalsForDate(now);
    final latestWeight = await _loadLatestWeight(now);
    final priorActivityLevel = await _repository.getPriorActivityLevel();
    final extraCardioHours = await _repository.getExtraCardioHoursOption();
    final lastDueNotificationWeekKey =
        await _repository.getLastDueNotificationWeekKey();

    lines.add('feature_available: yes');
    lines.add('goal_direction: ${recommendationState.goal.name}');
    lines.add(
      'target_rate_kg_per_week: ${recommendationState.targetRateKgPerWeek.toStringAsFixed(2)}',
    );
    lines.add('prior_activity_level: ${priorActivityLevel.name}');
    lines.add('extra_cardio_hours_option: ${extraCardioHours.name}');
    lines.add('current_due_week_key: ${recommendationState.currentDueWeekKey}');
    lines.add(
      'is_recommendation_due_now: ${_yesNo(recommendationState.isAdaptiveRecommendationDueNow)}',
    );
    lines.add(
      'next_recommendation_due_at: ${_iso(recommendationState.nextAdaptiveRecommendationDueAt)}',
    );
    lines.add(
      'last_due_notification_week_key: ${_valueOrUnavailable(lastDueNotificationWeekKey)}',
    );

    if (goals != null) {
      lines.add('active_target_calories_kcal: ${goals.targetCalories}');
      lines.add('active_target_protein_g: ${goals.targetProtein}');
    } else {
      lines.add('active_targets: unavailable');
    }

    if (latestWeight != null) {
      lines.add(
          'latest_logged_weight_kg: ${latestWeight.$1.toStringAsFixed(2)}');
      lines.add('latest_logged_weight_at: ${_iso(latestWeight.$2)}');
    } else {
      lines.add('latest_logged_weight_kg: unavailable');
    }

    final generated = recommendationState.latestGeneratedRecommendation;
    final applied = recommendationState.latestAppliedRecommendation;
    final maintenance = recommendationState.latestMaintenanceEstimate;

    lines.add('latest_recommendation_available: ${_yesNo(generated != null)}');
    lines.add(
        'latest_recommendation_generated_at: ${_isoOrUnavailable(recommendationState.latestGeneratedAt)}');

    if (generated != null) {
      lines.add(
          'recommendation_due_week_key: ${_valueOrUnavailable(generated.dueWeekKey)}');
      lines.add('recommended_calories_kcal: ${generated.recommendedCalories}');
      lines.add('recommended_protein_g: ${generated.recommendedProteinGrams}');
      lines.add('recommended_carbs_g: ${generated.recommendedCarbsGrams}');
      lines.add('recommended_fat_g: ${generated.recommendedFatGrams}');
      lines.add(
        'estimated_maintenance_kcal: ${generated.estimatedMaintenanceCalories}',
      );
      lines.add('recommendation_confidence: ${generated.confidence.name}');
      lines.add('warning_level: ${generated.warningState.warningLevel.name}');
      lines.add(
        'warning_reasons: ${_listOrUnavailable(generated.warningState.warningReasons)}',
      );
      lines.add('input_window_days: ${generated.inputSummary.windowDays}');
      lines.add(
          'input_weight_log_count: ${generated.inputSummary.weightLogCount}');
      lines.add(
          'input_intake_logged_days: ${generated.inputSummary.intakeLoggedDays}');
      lines.add(
        'input_avg_logged_calories_kcal: ${generated.inputSummary.avgLoggedCalories.toStringAsFixed(1)}',
      );
      lines.add(
        'input_smoothed_weight_slope_kg_per_week: ${_doubleOrUnavailable(generated.inputSummary.smoothedWeightSlopeKgPerWeek, fractionDigits: 4)}',
      );
      lines.add(
        'input_quality_flags: ${_listOrUnavailable(generated.inputSummary.qualityFlags)}',
      );
      lines.add(
        'input_weight_reference_kg: unavailable (not persisted in recommendation snapshot)',
      );
      if (generated.baselineCalories != null) {
        lines.add('baseline_calories_kcal: ${generated.baselineCalories}');
      }
    }

    final manualApplyPending =
        generated != null && !_isSameRecommendation(generated, applied);
    lines.add('latest_applied_available: ${_yesNo(applied != null)}');
    lines.add('manual_apply_pending: ${_yesNo(manualApplyPending)}');

    if (applied != null) {
      lines.add(
          'latest_applied_due_week_key: ${_valueOrUnavailable(applied.dueWeekKey)}');
      lines.add('latest_applied_generated_at: ${_iso(applied.generatedAt)}');
      lines.add('latest_applied_calories_kcal: ${applied.recommendedCalories}');
      lines.add('latest_applied_protein_g: ${applied.recommendedProteinGrams}');
    }

    if (snapshot != null) {
      lines.add('snapshot_due_week_key: ${snapshot.dueWeekKey}');
      lines.add('snapshot_algorithm_version: ${snapshot.algorithmVersion}');
      lines.add('snapshot_generated_at: ${_iso(snapshot.generatedAt)}');
    }

    if (maintenance != null) {
      lines.add(
        'posterior_maintenance_kcal: ${maintenance.posteriorMaintenanceCalories.toStringAsFixed(1)}',
      );
      lines.add(
        'posterior_stddev_kcal: ${maintenance.posteriorStdDevCalories.toStringAsFixed(1)}',
      );
      lines.add(
        'posterior_range_kcal: ${maintenance.credibleIntervalLowerCalories()}..${maintenance.credibleIntervalUpperCalories()}',
      );
      lines.add(
        'prior_source: ${maintenance.priorSource.name}',
      );
      lines.add(
        'effective_sample_size: ${maintenance.effectiveSampleSize.toStringAsFixed(2)}',
      );
      lines.add(
        'observed_intake_kcal: ${_doubleOrUnavailable(maintenance.observedIntakeCalories)}',
      );
      lines.add(
        'observed_weight_slope_kg_per_week: ${_doubleOrUnavailable(maintenance.observedWeightSlopeKgPerWeek, fractionDigits: 4)}',
      );
      lines.add(
        'observation_implied_maintenance_kcal: ${_doubleOrUnavailable(maintenance.observationImpliedMaintenanceCalories)}',
      );
      lines.add(
        'estimate_quality_flags: ${_listOrUnavailable(maintenance.qualityFlags)}',
      );
      _appendDebugInfoSummary(lines, maintenance);
    }

    if (estimatorState != null) {
      lines
          .add('estimator_last_due_week_key: ${estimatorState.lastDueWeekKey}');
      lines.add(
        'estimator_posterior_mean_kcal: ${estimatorState.posteriorMeanCalories.toStringAsFixed(1)}',
      );
      lines.add(
        'estimator_posterior_stddev_kcal: ${estimatorState.posteriorStdDevCalories.toStringAsFixed(1)}',
      );
      lines.add(
        'estimator_last_prior_source: ${estimatorState.lastPriorSource?.name ?? 'unavailable'}',
      );
      lines.add(
          'estimator_has_replay_prior: ${_yesNo(estimatorState.hasReplayPrior)}');
      lines.add(
        'estimator_last_observation_used: ${_yesNo(estimatorState.lastObservationUsed)}',
      );
      lines.add(
        'estimator_recent_residual_samples: ${estimatorState.recentObservationResidualsCalories.length}',
      );
      lines.add(
        'estimator_recent_implied_maintenance_samples: ${estimatorState.recentObservationImpliedMaintenanceCalories.length}',
      );
    }

    _appendPhaseSummary(lines, phaseState, now, maintenance);

    return lines;
  }

  Future<(double, DateTime)?> _loadLatestWeight(DateTime now) async {
    final range = DateTimeRange(
      start: now.subtract(const Duration(days: 3650)),
      end: now,
    );
    final points = await _databaseHelper.getChartDataForTypeAndRange(
      'weight',
      range,
    );
    if (points.isEmpty) {
      return null;
    }

    points.sort((a, b) => a.date.compareTo(b.date));
    final latest = points.last;
    return (latest.value, latest.date);
  }

  bool _isSameRecommendation(
    NutritionRecommendation generated,
    NutritionRecommendation? applied,
  ) {
    if (applied == null) {
      return false;
    }

    return generated.recommendedCalories == applied.recommendedCalories &&
        generated.recommendedProteinGrams == applied.recommendedProteinGrams &&
        generated.recommendedCarbsGrams == applied.recommendedCarbsGrams &&
        generated.recommendedFatGrams == applied.recommendedFatGrams &&
        generated.dueWeekKey == applied.dueWeekKey;
  }

  void _appendDebugInfoSummary(
    List<String> lines,
    BayesianMaintenanceEstimate maintenance,
  ) {
    final debugInfo = maintenance.debugInfo;

    void addIfPresent(String key, String lineKey) {
      final value = debugInfo[key];
      if (value == null) {
        return;
      }
      lines.add('$lineKey: $value');
    }

    addIfPresent('effectiveKcalPerKg', 'phase_effective_kcal_per_kg');
    addIfPresent('effectiveKcalPerKgMode', 'phase_effective_kcal_mode');
    addIfPresent('confirmedPhase', 'phase_confirmed');
    addIfPresent('confirmedPhaseAgeDays', 'phase_confirmed_age_days');
    addIfPresent('confirmedPhaseWeekIndex', 'phase_confirmed_week_index');
    addIfPresent('isPhaseChangePending', 'phase_pending_change');
    addIfPresent('pendingPhase', 'phase_pending');
    addIfPresent('pendingPhaseAgeDays', 'phase_pending_age_days');
    addIfPresent('stabilizationIsActive', 'stabilization_active');
    addIfPresent('stabilizationFlags', 'stabilization_flags');
  }

  void _appendPhaseSummary(
    List<String> lines,
    AdaptiveDietPhaseTrackingState? phaseState,
    DateTime now,
    BayesianMaintenanceEstimate? maintenance,
  ) {
    if (phaseState == null) {
      lines.add('phase_tracking_state: unavailable');
      return;
    }

    lines.add('phase_confirmed_state: ${phaseState.confirmedPhase.name}');
    lines.add(
      'phase_confirmed_start_day: ${_iso(phaseState.confirmedPhaseStartDay)}',
    );
    lines.add(
      'phase_confirmed_age_days: ${phaseState.confirmedPhaseAgeDays(now)}',
    );

    final fallbackWeek = ((phaseState.confirmedPhaseAgeDays(now) - 1) ~/ 7) + 1;
    final debugWeekIndex = maintenance?.debugInfo['confirmedPhaseWeekIndex'];
    lines.add(
      'phase_current_ramp_week: ${debugWeekIndex ?? fallbackWeek}',
    );

    if (phaseState.pendingPhase != null) {
      lines.add('phase_pending_state: ${phaseState.pendingPhase!.name}');
      lines.add(
        'phase_pending_first_seen_day: ${_isoOrUnavailable(phaseState.pendingPhaseFirstSeenDay)}',
      );
      lines.add(
        'phase_pending_age_days: ${phaseState.pendingPhaseAgeDays(now) ?? 'unavailable'}',
      );
    } else {
      lines.add('phase_pending_state: none');
    }
  }

  String _yesNo(bool value) => value ? 'yes' : 'no';

  String _listOrUnavailable(List<String> values) {
    if (values.isEmpty) {
      return 'unavailable';
    }
    return values.join(', ');
  }

  String _doubleOrUnavailable(
    double? value, {
    int fractionDigits = 1,
  }) {
    if (value == null) {
      return 'unavailable';
    }
    return value.toStringAsFixed(fractionDigits);
  }

  String _valueOrUnavailable(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'unavailable';
    }
    return trimmed;
  }

  String _iso(DateTime value) => value.toUtc().toIso8601String();

  String _isoOrUnavailable(DateTime? value) {
    if (value == null) {
      return 'unavailable';
    }
    return _iso(value);
  }
}
