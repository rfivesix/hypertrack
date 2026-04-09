import 'dart:math' as math;

import 'package:hypertrack/features/nutrition_recommendation/domain/confidence_models.dart';

import '../scenario_test_harness.dart';
import 'synthetic_truth_simulation.dart';

class ErrorMilestone {
  final int weekIndex;
  final double absoluteErrorCalories;
  final double signedErrorCalories;

  const ErrorMilestone({
    required this.weekIndex,
    required this.absoluteErrorCalories,
    required this.signedErrorCalories,
  });
}

class RecoveryWindowSummary {
  final double preEventPosteriorMedian;
  final double eventPosteriorMedian;
  final double postEventPosteriorMedian;
  final double preEventVarianceMedian;
  final double eventVarianceMedian;
  final double postEventVarianceMedian;
  final double preEventConfidenceAverage;
  final double eventConfidenceAverage;
  final double postEventConfidenceAverage;

  const RecoveryWindowSummary({
    required this.preEventPosteriorMedian,
    required this.eventPosteriorMedian,
    required this.postEventPosteriorMedian,
    required this.preEventVarianceMedian,
    required this.eventVarianceMedian,
    required this.postEventVarianceMedian,
    required this.preEventConfidenceAverage,
    required this.eventConfidenceAverage,
    required this.postEventConfidenceAverage,
  });
}

List<double> posteriorSignedErrorSeries(List<SyntheticWeekResult> weeks) {
  return weeks
      .map(
        (week) =>
            week.model.maintenanceEstimate.posteriorMaintenanceCalories -
            week.truthAtStableAnchor.trueMaintenanceCalories,
      )
      .toList(growable: false);
}

List<double> posteriorAbsoluteErrorSeries(List<SyntheticWeekResult> weeks) {
  return posteriorSignedErrorSeries(weeks)
      .map((value) => value.abs())
      .toList(growable: false);
}

double initialAbsoluteError(List<SyntheticWeekResult> weeks) {
  if (weeks.isEmpty) {
    return 0;
  }
  return posteriorAbsoluteErrorSeries(weeks).first;
}

double absoluteErrorAtWeek(
  List<SyntheticWeekResult> weeks,
  int weekIndex,
) {
  if (weeks.isEmpty || weekIndex < 0 || weekIndex >= weeks.length) {
    return 0;
  }
  return posteriorAbsoluteErrorSeries(weeks)[weekIndex];
}

double signedErrorAtWeek(
  List<SyntheticWeekResult> weeks,
  int weekIndex,
) {
  if (weeks.isEmpty || weekIndex < 0 || weekIndex >= weeks.length) {
    return 0;
  }
  return posteriorSignedErrorSeries(weeks)[weekIndex];
}

double errorImprovementFromInitial(
  List<SyntheticWeekResult> weeks, {
  required int weekIndex,
}) {
  if (weeks.isEmpty || weekIndex < 0 || weekIndex >= weeks.length) {
    return 0;
  }
  final errors = posteriorAbsoluteErrorSeries(weeks);
  return errors.first - errors[weekIndex];
}

double errorImprovementRatio(
  List<SyntheticWeekResult> weeks, {
  required int weekIndex,
}) {
  if (weeks.isEmpty || weekIndex < 0 || weekIndex >= weeks.length) {
    return 0;
  }
  final initial = initialAbsoluteError(weeks);
  if (initial <= 0) {
    return 0;
  }
  return errorImprovementFromInitial(weeks, weekIndex: weekIndex) / initial;
}

int? settlingWeekIndex(
  List<SyntheticWeekResult> weeks, {
  required double toleranceCalories,
  int startWeek = 0,
}) {
  final errors = posteriorAbsoluteErrorSeries(weeks);
  if (errors.isEmpty || startWeek >= errors.length) {
    return null;
  }

  for (var i = math.max(0, startWeek); i < errors.length; i++) {
    final remainsInsideBand = errors.skip(i).every(
          (value) => value <= toleranceCalories,
        );
    if (remainsInsideBand) {
      return i;
    }
  }
  return null;
}

int? errorHalfLifeWeekIndex(List<SyntheticWeekResult> weeks) {
  final errors = posteriorAbsoluteErrorSeries(weeks);
  if (errors.isEmpty) {
    return null;
  }
  final threshold = errors.first * 0.5;
  for (var i = 0; i < errors.length; i++) {
    if (errors[i] <= threshold) {
      return i;
    }
  }
  return null;
}

ErrorMilestone milestoneAtWeek(
  List<SyntheticWeekResult> weeks, {
  required int weekIndex,
}) {
  final clamped = weekIndex.clamp(0, math.max(0, weeks.length - 1)).toInt();
  return ErrorMilestone(
    weekIndex: clamped,
    absoluteErrorCalories: absoluteErrorAtWeek(weeks, clamped),
    signedErrorCalories: signedErrorAtWeek(weeks, clamped),
  );
}

double medianAbsoluteError(
  List<SyntheticWeekResult> weeks, {
  int startWeek = 0,
}) {
  if (weeks.isEmpty || startWeek >= weeks.length) {
    return 0;
  }
  final values = posteriorAbsoluteErrorSeries(weeks).skip(startWeek).toList();
  return median(values);
}

bool didConvergeByWeek(
  List<SyntheticWeekResult> weeks, {
  required int weekIndex,
  required double maxAbsErrorCalories,
}) {
  if (weeks.isEmpty || weekIndex >= weeks.length) {
    return false;
  }
  final error = posteriorAbsoluteErrorSeries(weeks)[weekIndex];
  return error <= maxAbsErrorCalories;
}

double medianPosteriorCaloriesForWeeks(
  List<WeekScenarioOutput> weeks, {
  required int startInclusive,
  required int endExclusive,
}) {
  if (weeks.isEmpty || startInclusive >= weeks.length) {
    return 0;
  }
  final end = math.min(endExclusive, weeks.length);
  if (startInclusive >= end) {
    return 0;
  }
  final values = weeks
      .sublist(startInclusive, end)
      .map((w) => w.maintenanceEstimate.posteriorMaintenanceCalories)
      .toList(growable: false);
  return median(values);
}

double medianVarianceForWeeks(
  List<WeekScenarioOutput> weeks, {
  required int startInclusive,
  required int endExclusive,
}) {
  if (weeks.isEmpty || startInclusive >= weeks.length) {
    return 0;
  }
  final end = math.min(endExclusive, weeks.length);
  if (startInclusive >= end) {
    return 0;
  }
  final values = weeks
      .sublist(startInclusive, end)
      .map((w) => w.debugValue('posteriorVarianceCalories2'))
      .toList(growable: false);
  return median(values);
}

double averageConfidenceForWeeks(
  List<SyntheticWeekResult> weeks, {
  required int startInclusive,
  required int endExclusive,
}) {
  if (weeks.isEmpty || startInclusive >= weeks.length) {
    return 0;
  }
  final end = math.min(endExclusive, weeks.length);
  if (startInclusive >= end) {
    return 0;
  }
  final scoped = weeks.sublist(startInclusive, end);
  return averageConfidenceScore(scoped);
}

int? weeksUntilPosteriorRecoversToBand({
  required List<WeekScenarioOutput> weeks,
  required double baselineMedian,
  required double toleranceCalories,
  required int searchStartWeek,
  int sustainedWeeks = 2,
}) {
  if (weeks.isEmpty || searchStartWeek >= weeks.length) {
    return null;
  }

  final sustain = math.max(1, sustainedWeeks);
  for (var i = math.max(0, searchStartWeek); i < weeks.length; i++) {
    final end = i + sustain;
    if (end > weeks.length) {
      break;
    }
    final inBand = weeks.sublist(i, end).every(
          (week) =>
              (week.maintenanceEstimate.posteriorMaintenanceCalories -
                      baselineMedian)
                  .abs() <=
              toleranceCalories,
        );
    if (inBand) {
      return i - searchStartWeek;
    }
  }
  return null;
}

RecoveryWindowSummary summarizeRecoveryWindows({
  required List<SyntheticWeekResult> weeks,
  required int preStart,
  required int preEnd,
  required int eventStart,
  required int eventEnd,
  required int postStart,
  required int postEnd,
}) {
  final model = modelWeeks(weeks);
  return RecoveryWindowSummary(
    preEventPosteriorMedian: medianPosteriorCaloriesForWeeks(
      model,
      startInclusive: preStart,
      endExclusive: preEnd,
    ),
    eventPosteriorMedian: medianPosteriorCaloriesForWeeks(
      model,
      startInclusive: eventStart,
      endExclusive: eventEnd,
    ),
    postEventPosteriorMedian: medianPosteriorCaloriesForWeeks(
      model,
      startInclusive: postStart,
      endExclusive: postEnd,
    ),
    preEventVarianceMedian: medianVarianceForWeeks(
      model,
      startInclusive: preStart,
      endExclusive: preEnd,
    ),
    eventVarianceMedian: medianVarianceForWeeks(
      model,
      startInclusive: eventStart,
      endExclusive: eventEnd,
    ),
    postEventVarianceMedian: medianVarianceForWeeks(
      model,
      startInclusive: postStart,
      endExclusive: postEnd,
    ),
    preEventConfidenceAverage: averageConfidenceForWeeks(
      weeks,
      startInclusive: preStart,
      endExclusive: preEnd,
    ),
    eventConfidenceAverage: averageConfidenceForWeeks(
      weeks,
      startInclusive: eventStart,
      endExclusive: eventEnd,
    ),
    postEventConfidenceAverage: averageConfidenceForWeeks(
      weeks,
      startInclusive: postStart,
      endExclusive: postEnd,
    ),
  );
}

double? tryPosteriorDebugValue(
  WeekScenarioOutput week,
  String key,
) {
  final value = week.maintenanceEstimate.debugInfo[key];
  if (value is num) {
    return value.toDouble();
  }
  return null;
}

double maxOvershootCalories(
  List<SyntheticWeekResult> weeks, {
  int startWeek = 0,
}) {
  if (weeks.isEmpty || startWeek >= weeks.length) {
    return 0;
  }
  final signed = posteriorSignedErrorSeries(weeks).skip(startWeek);
  return signed.fold<double>(0, (maxValue, value) => math.max(maxValue, value));
}

double maxUndershootCalories(
  List<SyntheticWeekResult> weeks, {
  int startWeek = 0,
}) {
  if (weeks.isEmpty || startWeek >= weeks.length) {
    return 0;
  }
  final signed = posteriorSignedErrorSeries(weeks).skip(startWeek);
  return signed.fold<double>(
      0, (maxValue, value) => math.max(maxValue, -value));
}

int countTruthCrossings(
  List<SyntheticWeekResult> weeks, {
  double deadbandCalories = 50,
}) {
  final signed = posteriorSignedErrorSeries(weeks);
  if (signed.length < 2) {
    return 0;
  }

  int? priorSign;
  var crossings = 0;
  for (final value in signed) {
    final sign = _signWithDeadband(value, deadbandCalories);
    if (sign == 0) {
      continue;
    }
    if (priorSign != null && sign != priorSign) {
      crossings++;
    }
    priorSign = sign;
  }
  return crossings;
}

List<double> posteriorWeeklyDeltaSeries(List<SyntheticWeekResult> weeks) {
  if (weeks.length < 2) {
    return const <double>[];
  }

  final values = <double>[];
  for (var i = 1; i < weeks.length; i++) {
    final previous =
        weeks[i - 1].model.maintenanceEstimate.posteriorMaintenanceCalories;
    final current =
        weeks[i].model.maintenanceEstimate.posteriorMaintenanceCalories;
    values.add(current - previous);
  }
  return values;
}

double maxAbsoluteWeeklyDelta(
  List<SyntheticWeekResult> weeks, {
  int startDeltaIndex = 0,
}) {
  final deltas = posteriorWeeklyDeltaSeries(weeks);
  if (deltas.isEmpty || startDeltaIndex >= deltas.length) {
    return 0;
  }
  return deltas
      .skip(startDeltaIndex)
      .map((delta) => delta.abs())
      .fold<double>(0, math.max);
}

double medianPosteriorVariance(
  List<SyntheticWeekResult> weeks, {
  int startWeek = 0,
}) {
  if (weeks.isEmpty || startWeek >= weeks.length) {
    return 0;
  }
  final values = weeks
      .skip(startWeek)
      .map((week) => week.model.debugValue('posteriorVarianceCalories2'))
      .toList(growable: false);
  return median(values);
}

double averageConfidenceScore(
  List<SyntheticWeekResult> weeks, {
  int startWeek = 0,
}) {
  if (weeks.isEmpty || startWeek >= weeks.length) {
    return 0;
  }

  final rankTotal = weeks.skip(startWeek).fold<int>(
        0,
        (sum, week) =>
            sum + _confidenceRank(week.model.recommendation.confidence),
      );
  return rankTotal / (weeks.length - startWeek);
}

List<WeekScenarioOutput> modelWeeks(List<SyntheticWeekResult> weeks) {
  return weeks.map((week) => week.model).toList(growable: false);
}

int _signWithDeadband(double value, double deadbandCalories) {
  if (value.abs() <= deadbandCalories) {
    return 0;
  }
  return value > 0 ? 1 : -1;
}

int _confidenceRank(RecommendationConfidence confidence) {
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
