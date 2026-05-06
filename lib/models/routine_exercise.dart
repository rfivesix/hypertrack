// lib/models/routine_exercise.dart

import 'exercise.dart';
import 'set_template.dart';

/// Represents an exercise associated with a specific routine.
///
/// Links an [Exercise] to a [Routine] and includes templates for sets and pause duration.
class RoutineExercise {
  /// Unique identifier for the routine-exercise association.
  final int? id;

  /// The underlying [Exercise] definition.
  final Exercise exercise;

  /// A list of template sets to be pre-filled when starting a workout with this routine.
  List<SetTemplate> setTemplates;

  /// The recommended pause duration between sets in seconds.
  final int? pauseSeconds; // New field

  /// Creates a new [RoutineExercise] instance.
  RoutineExercise({
    this.id,
    required this.exercise,
    this.setTemplates = const [],
    this.pauseSeconds, // New field
  });

  /// Converts the [RoutineExercise] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise': exercise.toMap(), // Assumption: Exercise has a toMap method
      'setTemplates': setTemplates.map((st) => st.toMap()).toList(),
      'pause_seconds': pauseSeconds,
    };
  }
}
