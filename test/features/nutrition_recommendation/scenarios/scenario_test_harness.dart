import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/data/backup_manager.dart';
import 'package:hypertrack/data/database_helper.dart';
import 'package:hypertrack/data/drift_database.dart'
    show AppDatabase, ProductsCompanion;
import 'package:hypertrack/data/product_database_helper.dart';
import 'package:hypertrack/data/workout_database_helper.dart';
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_repository.dart';
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_scheduler.dart';
import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_service.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/adaptive_diet_phase.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/adaptive_recommendation_snapshot.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/bayesian_tdee_estimator.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/recommendation_models.dart';
import 'package:hypertrack/models/food_entry.dart';
import 'package:hypertrack/models/measurement.dart';
import 'package:hypertrack/models/measurement_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScenarioProfile {
  final String name;
  final DateTime? birthday;
  final int? heightCm;
  final String? gender;
  final double initialWeightKg;
  final double? bodyFatPercent;
  final PriorActivityLevel declaredActivityLevel;
  final ExtraCardioHoursOption extraCardioHoursOption;
  final int targetSteps;

  ScenarioProfile({
    required this.name,
    required this.birthday,
    required this.heightCm,
    required this.gender,
    required this.initialWeightKg,
    required this.bodyFatPercent,
    required this.declaredActivityLevel,
    required this.extraCardioHoursOption,
    required this.targetSteps,
  });

  ScenarioProfile.defaultProfile()
      : name = 'Scenario User',
        birthday = DateTime(1994, 5, 12),
        heightCm = 178,
        gender = 'male',
        initialWeightKg = 82,
        bodyFatPercent = null,
        declaredActivityLevel = PriorActivityLevel.moderate,
        extraCardioHoursOption = ExtraCardioHoursOption.h0,
        targetSteps = 8500;
}

class WeekScenarioOutput {
  final DateTime dueWeekStart;
  final NutritionRecommendation recommendation;
  final BayesianMaintenanceEstimate maintenanceEstimate;
  final BayesianEstimatorState recursiveState;
  final AdaptiveDietPhaseTrackingState phaseState;
  final AdaptiveRecommendationSnapshot snapshot;

  const WeekScenarioOutput({
    required this.dueWeekStart,
    required this.recommendation,
    required this.maintenanceEstimate,
    required this.recursiveState,
    required this.phaseState,
    required this.snapshot,
  });

  String get dueWeekKey => recommendation.dueWeekKey ?? '';

  double debugValue(String key) {
    return debugDouble(maintenanceEstimate, key);
  }

  Map<String, dynamic> toDeterministicJson() {
    return <String, dynamic>{
      'dueWeekStart': dueWeekStart.toIso8601String(),
      'dueWeekKey': dueWeekKey,
      'recommendation': recommendation.toJson(),
      'maintenanceEstimate': maintenanceEstimate.toJson(),
      'recursiveState': recursiveState.toJson(),
      'phaseState': phaseState.toJson(),
    };
  }
}

class SameWeekReplayOutput {
  final WeekScenarioOutput initial;
  final WeekScenarioOutput replay;

  const SameWeekReplayOutput({
    required this.initial,
    required this.replay,
  });
}

class AdaptiveScenarioHarness {
  static const String scenarioFoodBarcode = 'scenario-kcal-food';

  final ScenarioProfile profile;
  final AppDatabase database;
  final DatabaseHelper dbHelper;
  final ProductDatabaseHelper productDb;
  final WorkoutDatabaseHelper workoutDb;
  final BackupManager backupManager;

  late RecommendationRepository repository;
  late AdaptiveNutritionRecommendationService service;

  AdaptiveScenarioHarness._({
    required this.profile,
    required this.database,
    required this.dbHelper,
    required this.productDb,
    required this.workoutDb,
    required this.backupManager,
  }) {
    _rebuildAdaptiveLayer();
  }

  static Future<AdaptiveScenarioHarness> create({
    ScenarioProfile? profile,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final database = AppDatabase(NativeDatabase.memory());
    final dbHelper = DatabaseHelper.forTesting(database);
    final productDb =
        ProductDatabaseHelper.forTesting(databaseHelper: dbHelper);
    final workoutDb =
        WorkoutDatabaseHelper.forTesting(databaseHelper: dbHelper);
    final backupManager = BackupManager(
      userDb: dbHelper,
      productDb: productDb,
      workoutDb: workoutDb,
    );

    final harness = AdaptiveScenarioHarness._(
      profile: profile ?? ScenarioProfile.defaultProfile(),
      database: database,
      dbHelper: dbHelper,
      productDb: productDb,
      workoutDb: workoutDb,
      backupManager: backupManager,
    );

    await harness._bootstrapBaseState();
    return harness;
  }

  Future<void> _bootstrapBaseState() async {
    await dbHelper.saveUserProfile(
      name: profile.name,
      birthday: profile.birthday,
      height: profile.heightCm,
      gender: profile.gender,
    );
    await dbHelper.saveUserGoals(
      calories: 2400,
      protein: 170,
      carbs: 260,
      fat: 75,
      water: 3000,
      steps: profile.targetSteps,
    );
    await repository.saveGoalAndTargetRate(
      goal: BodyweightGoal.maintainWeight,
      targetRateKgPerWeek: 0,
    );

    await database.into(database.products).insert(
          const ProductsCompanion(
            barcode: drift.Value(scenarioFoodBarcode),
            name: drift.Value('Scenario Food 1kcal/g'),
            calories: drift.Value(100),
            protein: drift.Value(0),
            carbs: drift.Value(0),
            fat: drift.Value(0),
            source: drift.Value('base'),
          ),
        );
  }

  void _rebuildAdaptiveLayer() {
    repository = RecommendationRepository();
    service = AdaptiveNutritionRecommendationService(
      repository: repository,
      databaseHelper: dbHelper,
    );
  }

  Future<void> restartAdaptiveLayer() async {
    _rebuildAdaptiveLayer();
  }

  Future<void> dispose() async {
    await database.close();
  }

  Future<void> setGoalForDay({
    required BodyweightGoal goal,
    required double targetRateKgPerWeek,
    required DateTime day,
  }) {
    final now = DateTime(day.year, day.month, day.day, 8);
    return service.saveGoalAndTargetRate(
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      now: now,
    );
  }

  Future<void> logWeight({
    required DateTime day,
    required double weightKg,
  }) {
    final sessionTime = DateTime(day.year, day.month, day.day, 7);
    return dbHelper.insertMeasurementSession(
      MeasurementSession(
        timestamp: sessionTime,
        measurements: <Measurement>[
          Measurement(
            sessionId: 0,
            type: 'weight',
            value: weightKg,
            unit: 'kg',
          ),
        ],
      ),
    );
  }

  Future<void> logIntakeCalories({
    required DateTime day,
    required int calories,
    String mealType = 'mealtypeLunch',
  }) {
    if (calories <= 0) {
      return Future<void>.value();
    }
    final intakeTime = DateTime(day.year, day.month, day.day, 12);
    return dbHelper.insertFoodEntry(
      FoodEntry(
        barcode: scenarioFoodBarcode,
        timestamp: intakeTime,
        quantityInGrams: calories,
        mealType: mealType,
      ),
    );
  }

  Future<void> seedDailyHistory({
    required DateTime startDay,
    required int dayCount,
    required double startWeightKg,
    required double weeklyWeightChangeKg,
    required int averageIntakeCalories,
    bool Function(int dayIndex, DateTime day)? shouldLogWeight,
    bool Function(int dayIndex, DateTime day)? shouldLogIntake,
    double Function(int dayIndex, DateTime day, double baselineWeightKg)?
        weightForDay,
    int Function(int dayIndex, DateTime day, int baselineCalories)?
        intakeForDay,
    Set<DateTime> noLogDays = const <DateTime>{},
  }) async {
    final blockedDayKeys =
        noLogDays.map((day) => normalizeDay(day).toIso8601String()).toSet();

    for (var i = 0; i < dayCount; i++) {
      final day = normalizeDay(startDay.add(Duration(days: i)));
      final dayKey = day.toIso8601String();
      if (blockedDayKeys.contains(dayKey)) {
        continue;
      }

      final baselineWeight = startWeightKg + ((weeklyWeightChangeKg * i) / 7);
      final defaultWeight = baselineWeight + _defaultWeightNoiseKg(i);
      final resolvedWeight =
          weightForDay?.call(i, day, baselineWeight) ?? defaultWeight;

      final baselineCalories = averageIntakeCalories + _defaultCalorieNoise(i);
      final resolvedCalories =
          intakeForDay?.call(i, day, baselineCalories) ?? baselineCalories;

      final writeWeight = shouldLogWeight?.call(i, day) ?? true;
      final writeIntake = shouldLogIntake?.call(i, day) ?? true;

      if (writeWeight) {
        await logWeight(day: day, weightKg: resolvedWeight);
      }
      if (writeIntake) {
        final clampedCalories = math.max(resolvedCalories, 800);
        await logIntakeCalories(day: day, calories: clampedCalories);
      }
    }
  }

  Future<void> seedDailySteps({
    required DateTime startDay,
    required int dayCount,
    required int dailySteps,
    String provider = 'apple_healthkit',
    String sourceId = 'scenario_source',
  }) {
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < dayCount; i++) {
      final localDay = normalizeDay(startDay.add(Duration(days: i)));
      final startAt = DateTime(
        localDay.year,
        localDay.month,
        localDay.day,
        12,
      ).toUtc();
      final endAt = startAt.add(const Duration(hours: 1));
      rows.add(<String, dynamic>{
        'provider': provider,
        'sourceId': sourceId,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'stepCount': dailySteps,
        'externalKey': 'scenario_steps_${localDay.toIso8601String()}_$i',
      });
    }
    return dbHelper.upsertHealthStepSegments(rows);
  }

  Future<WeekScenarioOutput> generateForDueWeek({
    required DateTime dueWeekStart,
    bool force = true,
    DateTime? now,
  }) async {
    final dueStart = normalizeDay(dueWeekStart);
    final effectiveNow =
        now ?? DateTime(dueStart.year, dueStart.month, dueStart.day, 10);

    final recommendation = await service.refreshRecommendationIfDue(
      now: effectiveNow,
      force: force,
    );
    if (recommendation == null) {
      throw StateError(
          'Expected recommendation for ${dueWeekKeyFor(dueStart)}');
    }

    final snapshot = await repository.getLatestRecommendationSnapshot();
    final state = await repository.getLatestEstimatorState();
    final phase = await repository.getDietPhaseTrackingState();

    if (snapshot == null || state == null || phase == null) {
      throw StateError(
          'Missing persisted adaptive state for ${dueWeekKeyFor(dueStart)}');
    }

    return WeekScenarioOutput(
      dueWeekStart: dueStart,
      recommendation: recommendation,
      maintenanceEstimate: snapshot.maintenanceEstimate,
      recursiveState: state,
      phaseState: phase,
      snapshot: snapshot,
    );
  }

  Future<SameWeekReplayOutput> generateAndReplaySameDueWeek({
    required DateTime dueWeekStart,
    Future<void> Function()? onBeforeReplay,
  }) async {
    final dueStart = normalizeDay(dueWeekStart);
    final initial = await generateForDueWeek(
      dueWeekStart: dueStart,
      force: true,
      now: DateTime(dueStart.year, dueStart.month, dueStart.day, 10),
    );

    if (onBeforeReplay != null) {
      await onBeforeReplay();
    }

    final replayNow = DateTime(
      dueStart.year,
      dueStart.month,
      dueStart.day,
      10,
    ).add(const Duration(days: 2));

    final replay = await generateForDueWeek(
      dueWeekStart: dueStart,
      force: true,
      now: replayNow,
    );

    return SameWeekReplayOutput(initial: initial, replay: replay);
  }

  Future<List<WeekScenarioOutput>> runDueWeekSeries({
    required DateTime firstDueWeekStart,
    required int weekCount,
  }) async {
    final weeks = <WeekScenarioOutput>[];
    for (var i = 0; i < weekCount; i++) {
      final dueWeek =
          normalizeDay(firstDueWeekStart.add(Duration(days: 7 * i)));
      weeks.add(
        await generateForDueWeek(dueWeekStart: dueWeek, force: true),
      );
    }
    return weeks;
  }

  Future<Map<String, dynamic>> createBackupPayload() {
    return backupManager.generateBackupPayloadForTesting();
  }

  Future<bool> restoreFromBackupPayload(Map<String, dynamic> payload) {
    return backupManager.importBackupPayloadForTesting(payload);
  }
}

DateTime normalizeDay(DateTime day) => DateTime(day.year, day.month, day.day);

String dueWeekKeyFor(DateTime day) {
  return RecommendationScheduler.dueWeekKeyFor(day);
}

List<DateTime> dueWeekStarts({
  required DateTime firstDueWeekStart,
  required int weekCount,
}) {
  return List<DateTime>.generate(
    weekCount,
    (index) => normalizeDay(firstDueWeekStart.add(Duration(days: index * 7))),
    growable: false,
  );
}

void expectNoAbsurdMaintenanceJumps(
  List<WeekScenarioOutput> weeks, {
  double maxJumpCalories = 600,
  int ignoreInitialWeeks = 1,
}) {
  if (weeks.length < 2) {
    return;
  }
  for (var i = math.max(ignoreInitialWeeks, 1); i < weeks.length; i++) {
    final previous =
        weeks[i - 1].maintenanceEstimate.posteriorMaintenanceCalories;
    final current = weeks[i].maintenanceEstimate.posteriorMaintenanceCalories;
    final delta = (current - previous).abs();
    expect(
      delta,
      lessThanOrEqualTo(maxJumpCalories),
      reason:
          'Posterior maintenance jump too large at week $i: Δ=${delta.toStringAsFixed(1)} kcal/day',
    );
  }
}

void expectVarianceBoundedByCap(List<WeekScenarioOutput> weeks) {
  for (final week in weeks) {
    final cap = week.debugValue('varianceCapCalories2');
    final posterior = week.debugValue('posteriorVarianceCalories2');
    expect(
      posterior,
      lessThanOrEqualTo(cap + 0.0001),
      reason: 'Variance exceeded cap for dueWeek=${week.dueWeekKey}',
    );
  }
}

void expectDueWeekAnchorsStable(
  List<WeekScenarioOutput> weeks, {
  required DateTime firstDueWeekStart,
}) {
  for (var i = 0; i < weeks.length; i++) {
    final expectedDay = normalizeDay(
      firstDueWeekStart.add(Duration(days: i * 7)),
    );
    expect(weeks[i].dueWeekStart, expectedDay);
    expect(weeks[i].dueWeekKey, dueWeekKeyFor(expectedDay));
  }
}

void expectPhaseRampProgression(List<WeekScenarioOutput> weeks) {
  expect(weeks, isNotEmpty);

  final kcalPerKgByWeek =
      weeks.map((week) => week.debugValue('effectiveKcalPerKg')).toList();

  expect(kcalPerKgByWeek.first, closeTo(3000, 0.001));

  for (var i = 1; i < kcalPerKgByWeek.length; i++) {
    expect(
      kcalPerKgByWeek[i],
      greaterThanOrEqualTo(kcalPerKgByWeek[i - 1] - 0.001),
      reason: 'Phase ramp regressed at week index $i',
    );
  }

  if (kcalPerKgByWeek.length >= 9) {
    // Local-date arithmetic across DST boundaries can shift inclusive day
    // differences by one day in scenario tests. We assert week-9 is near mature
    // and week-10+ is at the mature cap.
    expect(kcalPerKgByWeek[8], greaterThanOrEqualTo(7400));
  }

  if (kcalPerKgByWeek.length >= 10) {
    expect(kcalPerKgByWeek[9], closeTo(7700, 0.001));
    for (var i = 9; i < kcalPerKgByWeek.length; i++) {
      expect(kcalPerKgByWeek[i], closeTo(7700, 0.001));
    }
  }
}

double debugDouble(BayesianMaintenanceEstimate estimate, String key) {
  final value = estimate.debugInfo[key];
  if (value is num) {
    return value.toDouble();
  }
  throw StateError('Missing numeric debug key: $key');
}

int confidenceRank(RecommendationConfidence confidence) {
  switch (confidence) {
    case RecommendationConfidence.notEnoughData:
      return 0;
    case RecommendationConfidence.low:
      return 1;
    case RecommendationConfidence.medium:
      return 2;
    case RecommendationConfidence.high:
      return 3;
  }
}

double averageConfidenceRank(List<WeekScenarioOutput> weeks) {
  if (weeks.isEmpty) {
    return 0;
  }
  final total = weeks.fold<int>(
    0,
    (sum, week) => sum + confidenceRank(week.recommendation.confidence),
  );
  return total / weeks.length;
}

double median(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  final sorted = values.toList()..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[middle];
  }
  return (sorted[middle - 1] + sorted[middle]) / 2;
}

String encodeDeterministicRun(List<WeekScenarioOutput> weeks) {
  final payload = weeks.map((week) => week.toDeterministicJson()).toList();
  return jsonEncode(payload);
}

int _defaultCalorieNoise(int dayIndex) {
  const pattern = <int>[-70, 40, -30, 55, -45, 60, -10];
  return pattern[dayIndex % pattern.length];
}

double _defaultWeightNoiseKg(int dayIndex) {
  const pattern = <double>[0.00, 0.04, -0.03, 0.05, -0.02, 0.02, -0.01];
  return pattern[dayIndex % pattern.length];
}
