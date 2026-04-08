import 'dart:math' as math;

import 'package:hypertrack/features/nutrition_recommendation/data/recommendation_scheduler.dart';
import 'package:hypertrack/features/nutrition_recommendation/domain/goal_models.dart';

import '../scenario_test_harness.dart';

typedef SyntheticIntakeForDay = double Function(SyntheticDayContext context);
typedef SyntheticOffsetForDay = double Function(SyntheticDayContext context);
typedef SyntheticLogPolicy = bool Function(SyntheticDayContext context);
typedef SyntheticStepsForDay = int Function(SyntheticDayContext context);

class GoalPhaseSegment {
  final int dayOffset;
  final BodyweightGoal goal;
  final double targetRateKgPerWeek;

  const GoalPhaseSegment({
    required this.dayOffset,
    required this.goal,
    required this.targetRateKgPerWeek,
  });
}

class SyntheticTruthScenario {
  final String name;
  final ScenarioProfile profile;
  final DateTime firstDueWeekStart;
  final int weekCount;
  final int warmupDays;
  final double initialWeightKg;
  final double initialTrueMaintenanceCalories;
  final double weeklyMaintenanceDriftCalories;
  final double kcalPerKgBodyMassChange;
  final List<GoalPhaseSegment> goalTimeline;
  final SyntheticIntakeForDay? intakeForDay;
  final SyntheticOffsetForDay? maintenanceOffsetForDay;
  final SyntheticOffsetForDay? waterOffsetKgForDay;
  final SyntheticLogPolicy? shouldLogIntake;
  final SyntheticLogPolicy? shouldLogWeight;
  final SyntheticStepsForDay? stepsForDay;
  final List<int> intakeNoisePatternCalories;
  final List<double> weightNoisePatternKg;

  const SyntheticTruthScenario({
    required this.name,
    required this.profile,
    required this.firstDueWeekStart,
    required this.weekCount,
    required this.warmupDays,
    required this.initialWeightKg,
    required this.initialTrueMaintenanceCalories,
    required this.weeklyMaintenanceDriftCalories,
    this.kcalPerKgBodyMassChange = 7700,
    this.goalTimeline = const <GoalPhaseSegment>[
      GoalPhaseSegment(
        dayOffset: 0,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
      ),
    ],
    this.intakeForDay,
    this.maintenanceOffsetForDay,
    this.waterOffsetKgForDay,
    this.shouldLogIntake,
    this.shouldLogWeight,
    this.stepsForDay,
    this.intakeNoisePatternCalories = const <int>[0, 35, -20, 30, -25, 20, -5],
    this.weightNoisePatternKg = const <double>[
      0.0,
      0.04,
      -0.03,
      0.05,
      -0.02,
      0.02,
      -0.01
    ],
  });

  int get totalDays => warmupDays + (weekCount * 7);

  DateTime get startDay =>
      firstDueWeekStart.subtract(Duration(days: warmupDays));
}

class SyntheticDayContext {
  final SyntheticTruthScenario scenario;
  final int dayIndex;
  final DateTime day;
  final BodyweightGoal goal;
  final double targetRateKgPerWeek;
  final double trueMaintenanceCalories;
  final double trueWeightKg;

  const SyntheticDayContext({
    required this.scenario,
    required this.dayIndex,
    required this.day,
    required this.goal,
    required this.targetRateKgPerWeek,
    required this.trueMaintenanceCalories,
    required this.trueWeightKg,
  });

  bool get isWeekend =>
      day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
}

class TruthTrajectoryPoint {
  final DateTime day;
  final double trueMaintenanceCalories;
  final double trueWeightKg;

  const TruthTrajectoryPoint({
    required this.day,
    required this.trueMaintenanceCalories,
    required this.trueWeightKg,
  });
}

class SyntheticWeekResult {
  final WeekScenarioOutput model;
  final TruthTrajectoryPoint truthAtStableAnchor;

  const SyntheticWeekResult({
    required this.model,
    required this.truthAtStableAnchor,
  });
}

Future<List<SyntheticWeekResult>> runSyntheticTruthScenario(
  SyntheticTruthScenario scenario,
) async {
  final harness =
      await AdaptiveScenarioHarness.create(profile: scenario.profile);
  final truthByDay = <String, TruthTrajectoryPoint>{};
  final stepRows = <Map<String, dynamic>>[];
  final generatedWeeks = <WeekScenarioOutput>[];

  try {
    final sortedGoals = [...scenario.goalTimeline]
      ..sort((a, b) => a.dayOffset.compareTo(b.dayOffset));
    if (sortedGoals.isEmpty || sortedGoals.first.dayOffset != 0) {
      throw ArgumentError('goalTimeline must contain a dayOffset=0 segment');
    }
    final dueWeeks = dueWeekStarts(
      firstDueWeekStart: scenario.firstDueWeekStart,
      weekCount: scenario.weekCount,
    );
    var nextDueWeekIndex = 0;

    var trueWeightKg = scenario.initialWeightKg;

    for (var dayIndex = 0; dayIndex < scenario.totalDays; dayIndex++) {
      final day = normalizeDay(scenario.startDay.add(Duration(days: dayIndex)));
      final activeGoal = _goalForDay(sortedGoals, dayIndex);
      final driftComponent =
          scenario.weeklyMaintenanceDriftCalories * (dayIndex / 7.0);
      final provisionalContext = SyntheticDayContext(
        scenario: scenario,
        dayIndex: dayIndex,
        day: day,
        goal: activeGoal.goal,
        targetRateKgPerWeek: activeGoal.targetRateKgPerWeek,
        trueMaintenanceCalories:
            scenario.initialTrueMaintenanceCalories + driftComponent,
        trueWeightKg: trueWeightKg,
      );

      final maintenanceOffset =
          scenario.maintenanceOffsetForDay?.call(provisionalContext) ?? 0;
      final trueMaintenanceCalories = scenario.initialTrueMaintenanceCalories +
          driftComponent +
          maintenanceOffset;

      final context = SyntheticDayContext(
        scenario: scenario,
        dayIndex: dayIndex,
        day: day,
        goal: activeGoal.goal,
        targetRateKgPerWeek: activeGoal.targetRateKgPerWeek,
        trueMaintenanceCalories: trueMaintenanceCalories,
        trueWeightKg: trueWeightKg,
      );

      // Phase confirmation logic is day-based (7 consecutive days). Apply the
      // active goal daily so scenario timelines exercise that path realistically.
      await harness.setGoalForDay(
        goal: activeGoal.goal,
        targetRateKgPerWeek: activeGoal.targetRateKgPerWeek,
        day: day,
      );

      final intakeNoise = scenario.intakeNoisePatternCalories[
          dayIndex % scenario.intakeNoisePatternCalories.length];
      final intakeBaseline = scenario.intakeForDay?.call(context) ??
          _defaultIntakeForGoal(
            trueMaintenanceCalories: trueMaintenanceCalories,
            targetRateKgPerWeek: activeGoal.targetRateKgPerWeek,
          );
      final observedIntakeCalories =
          (intakeBaseline + intakeNoise).round().clamp(800, 5000);

      final energyBalance = observedIntakeCalories - trueMaintenanceCalories;
      trueWeightKg += energyBalance / scenario.kcalPerKgBodyMassChange;

      final waterOffset = scenario.waterOffsetKgForDay?.call(context) ?? 0.0;
      final weightNoise = scenario.weightNoisePatternKg[
          dayIndex % scenario.weightNoisePatternKg.length];
      final observedWeightKg = trueWeightKg + waterOffset + weightNoise;

      final shouldLogIntake = scenario.shouldLogIntake?.call(context) ?? true;
      final shouldLogWeight = scenario.shouldLogWeight?.call(context) ?? true;

      if (shouldLogIntake) {
        await harness.logIntakeCalories(
          day: day,
          calories: observedIntakeCalories,
        );
      }
      if (shouldLogWeight) {
        await harness.logWeight(day: day, weightKg: observedWeightKg);
      }

      final steps = scenario.stepsForDay?.call(context);
      if (steps != null && steps > 0) {
        final startAt = DateTime(day.year, day.month, day.day, 12).toUtc();
        stepRows.add(<String, dynamic>{
          'provider': 'apple_healthkit',
          'sourceId': 'synthetic_steps',
          'startAt': startAt.toIso8601String(),
          'endAt': startAt.add(const Duration(hours: 1)).toIso8601String(),
          'stepCount': steps,
          'externalKey': 'synthetic_steps_${day.toIso8601String()}_$dayIndex',
        });
      }

      truthByDay[day.toIso8601String()] = TruthTrajectoryPoint(
        day: day,
        trueMaintenanceCalories: trueMaintenanceCalories,
        trueWeightKg: trueWeightKg,
      );

      if (nextDueWeekIndex < dueWeeks.length &&
          day == dueWeeks[nextDueWeekIndex]) {
        generatedWeeks.add(
          await harness.generateForDueWeek(
            dueWeekStart: day,
            force: true,
            now: DateTime(day.year, day.month, day.day, 10),
          ),
        );
        nextDueWeekIndex++;
      }
    }

    if (stepRows.isNotEmpty) {
      await harness.dbHelper.upsertHealthStepSegments(stepRows);
    }

    if (generatedWeeks.length != scenario.weekCount) {
      throw StateError(
        'Expected ${scenario.weekCount} generated weeks, got ${generatedWeeks.length}.',
      );
    }

    return generatedWeeks.map((week) {
      final anchorDay = RecommendationScheduler.stableWindowEndDayForDueWeek(
        week.dueWeekStart,
      );
      final truth = _truthForDay(
        truthByDay: truthByDay,
        day: anchorDay,
      );
      return SyntheticWeekResult(
        model: week,
        truthAtStableAnchor: truth,
      );
    }).toList(growable: false);
  } finally {
    await harness.dispose();
  }
}

GoalPhaseSegment _goalForDay(List<GoalPhaseSegment> timeline, int dayIndex) {
  var current = timeline.first;
  for (final segment in timeline) {
    if (segment.dayOffset <= dayIndex) {
      current = segment;
      continue;
    }
    break;
  }
  return current;
}

TruthTrajectoryPoint _truthForDay({
  required Map<String, TruthTrajectoryPoint> truthByDay,
  required DateTime day,
}) {
  final direct = truthByDay[normalizeDay(day).toIso8601String()];
  if (direct != null) {
    return direct;
  }

  final available = truthByDay.values.toList(growable: false)
    ..sort((a, b) => a.day.compareTo(b.day));
  if (available.isEmpty) {
    throw StateError('Synthetic truth trajectory is empty.');
  }

  var fallback = available.first;
  for (final point in available) {
    if (point.day.isAfter(day)) {
      break;
    }
    fallback = point;
  }
  return fallback;
}

double _defaultIntakeForGoal({
  required double trueMaintenanceCalories,
  required double targetRateKgPerWeek,
}) {
  final rateAdjustment = targetRateKgPerWeek * 7700 / 7.0;
  return math.max(800, trueMaintenanceCalories + rateAdjustment);
}
