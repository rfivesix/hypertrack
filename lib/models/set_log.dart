// lib/models/set_log.dart
// Complete code

/// Represents a single set performed during an exercise.
///
/// Contains data about weight, repetitions, rest time, and completion status.
class SetLog {
  /// Unique identifier for the set log.
  final int? id;

  /// The identifier of the workout session this set belongs to.
  final int workoutLogId;

  /// The name of the exercise performed in this set.
  final String exerciseName;

  /// The type of set (e.g., "Normal", "Warm-up", "Dropset").
  final String setType;

  /// The weight used for the set in kilograms.
  final double? weightKg;

  /// The number of repetitions performed.
  final int? reps;

  /// The rest time taken after this set in seconds.
  final int? restTimeSeconds;

  /// Whether the set has been completed by the user.
  final bool? isCompleted;

  /// The order in which this set appears in the workout log.
  final int? logOrder;

  /// Optional notes about the set.
  final String? notes;

  /// The distance covered during the set (for cardio exercises) in kilometers.
  final double? distanceKm;

  /// The duration of the set in seconds.
  final int? durationSeconds;

  /// Rate of Perceived Exertion (1-10 scale).
  final int? rpe;

  /// Identifier for supersets if this set is part of one.
  final int? supersetId;

  /// Reps in Reserve (how many more reps could have been performed).
  final int? rir;

  /// Temporary flag: True if this set is a Max Weight PR.
  final bool isMaxWeightPR;

  /// Temporary flag: True if this set is a Max Volume PR.
  final bool isMaxVolumePR;

  /// Temporary flag: True if this set is an Estimated 1RM PR.
  final bool isMaxEst1RMPR;

  /// Temporary value: Difference to previous Weight PR.
  final double? weightPRDiff;

  /// Temporary value: Difference to previous Volume PR.
  final double? volumePRDiff;

  /// Temporary value: Difference to previous Estimated 1RM PR.
  final double? est1rmPRDiff;

  /// Creates a new [SetLog] instance.
  SetLog({
    this.id,
    required this.workoutLogId,
    required this.exerciseName,
    required this.setType,
    this.weightKg,
    this.reps,
    this.restTimeSeconds,
    this.isCompleted,
    this.logOrder,
    this.notes,
    this.distanceKm,
    this.durationSeconds,
    this.rpe,
    this.rir,
    this.supersetId,
    this.isMaxWeightPR = false,
    this.isMaxVolumePR = false,
    this.isMaxEst1RMPR = false,
    this.weightPRDiff,
    this.volumePRDiff,
    this.est1rmPRDiff,
  });

  /// Creates a [SetLog] instance from a Map, typically from a database row.
  factory SetLog.fromMap(Map<String, dynamic> map) {
    return SetLog(
      id: map['id'],
      workoutLogId: map['workout_log_id'],
      exerciseName: map['exercise_name'],
      setType: map['set_type'],
      weightKg: map['weight_kg'],
      reps: map['reps'],
      restTimeSeconds: map['rest_time_seconds'],
      // MODIFICATION: isCompleted can be null; map 1 to true and everything else (0, null) to false.
      isCompleted: map['is_completed'] == 1,
      logOrder: map['log_order'],
      notes: map['notes'],
      distanceKm: map['distance_km'],
      durationSeconds: map['duration_seconds'],
      rpe: map['rpe'],
      rir: map['rir'],
      supersetId: map['superset_id'],
      // Note: PR flags are not stored in the database.
    );
  }

  /// Converts the [SetLog] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_log_id': workoutLogId,
      'exercise_name': exerciseName,
      'set_type': setType,
      'weight_kg': weightKg,
      'reps': reps,
      'rest_time_seconds': restTimeSeconds,
      // MODIFICATION: Store true as 1, false/null as 0.
      'is_completed': isCompleted == true ? 1 : 0,
      'log_order': logOrder,
      'notes': notes,
      'distance_km': distanceKm,
      'duration_seconds': durationSeconds,
      'rpe': rpe,
      'rir': rir,
      'superset_id': supersetId,
    };
  }

  /// Creates a copy of this [SetLog] with the given fields replaced by the new values.
  ///
  /// Use optional [clearWeight], [clearReps], [clearRir], [clearDistance], and [clearDuration]
  /// flags to explicitly set those fields to null.
  SetLog copyWith({
    int? id,
    int? workoutLogId,
    String? exerciseName,
    String? setType,
    double? weightKg,
    int? reps,
    int? restTimeSeconds,
    bool? isCompleted,
    int? logOrder,
    String? notes,
    double? distanceKm,
    int? durationSeconds,
    int? rpe,
    int? rir,
    int? supersetId,
    bool? isMaxWeightPR,
    bool? isMaxVolumePR,
    bool? isMaxEst1RMPR,
    double? weightPRDiff,
    double? volumePRDiff,
    double? est1rmPRDiff,
    bool clearWeight = false,
    bool clearReps = false,
    bool clearRir = false,
    bool clearDistance = false,
    bool clearDuration = false,
  }) {
    return SetLog(
      id: id ?? this.id,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      exerciseName: exerciseName ?? this.exerciseName,
      setType: setType ?? this.setType,
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      reps: clearReps ? null : (reps ?? this.reps),
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      logOrder: logOrder ?? this.logOrder,
      notes: notes ?? this.notes,
      distanceKm: clearDistance ? null : (distanceKm ?? this.distanceKm),
      durationSeconds:
          clearDuration ? null : (durationSeconds ?? this.durationSeconds),
      rpe: rpe ?? this.rpe,
      rir: clearRir ? null : (rir ?? this.rir),
      supersetId: supersetId ?? this.supersetId,
      isMaxWeightPR: isMaxWeightPR ?? this.isMaxWeightPR,
      isMaxVolumePR: isMaxVolumePR ?? this.isMaxVolumePR,
      isMaxEst1RMPR: isMaxEst1RMPR ?? this.isMaxEst1RMPR,
      weightPRDiff: weightPRDiff ?? this.weightPRDiff,
      volumePRDiff: volumePRDiff ?? this.volumePRDiff,
      est1rmPRDiff: est1rmPRDiff ?? this.est1rmPRDiff,
    );
  }
}
