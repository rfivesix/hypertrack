// lib/models/workout_log.dart

import 'set_log.dart';

/// Represents a completed or ongoing workout session.
///
/// Tracks the start time, end time, and all sets performed during the session.
class WorkoutLog {
  /// Unique identifier for the workout log.
  final int? id;

  /// The name of the routine used for this workout, if any.
  final String? routineName;

  /// The exact time when the workout session started.
  final DateTime startTime;

  /// The exact time when the workout session ended.
  ///
  /// Can be null if the workout is still in progress.
  final DateTime? endTime;

  /// Optional notes or reflections on the workout session.
  final String? notes;

  /// Original start zone offset in minutes when available.
  final int? startZoneOffsetMinutes;

  /// Original end zone offset in minutes when available.
  final int? endZoneOffsetMinutes;

  /// A list of all [SetLog] entries recorded during this workout.
  final List<SetLog> sets;

  /// Creates a new [WorkoutLog] instance.
  WorkoutLog({
    this.id,
    this.routineName,
    required this.startTime,
    this.endTime,
    this.notes,
    this.startZoneOffsetMinutes,
    this.endZoneOffsetMinutes,
    this.sets = const [],
  });

  /// Creates a [WorkoutLog] instance from a Map, typically from a database row.
  ///
  /// The [sets] list is optional and can be provided if already fetched.
  factory WorkoutLog.fromMap(
    Map<String, dynamic> map, {
    List<SetLog> sets = const [],
  }) {
    return WorkoutLog(
      id: map['id'],
      routineName: map['routine_name'],
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      notes: map['notes'],
      sets: sets,
    );
  }

  /// Converts the [WorkoutLog] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routine_name': routineName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'notes': notes,
    };
  }
}
