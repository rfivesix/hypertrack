// lib/models/routine_exercise.dart

import '../../../exercise_catalog/domain/models/exercise.dart';
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

  /// Optional notes or instructional reminders for the exercise.
  final String? notes;

  /// Creates a new [RoutineExercise] instance.
  RoutineExercise({
    this.id,
    required this.exercise,
    this.setTemplates = const [],
    this.pauseSeconds, // New field
    this.notes,
  });

  /// Converts the [RoutineExercise] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise': exercise.toMap(), // Assumption: Exercise has a toMap method
      'setTemplates': setTemplates.map((st) => st.toMap()).toList(),
      'pause_seconds': pauseSeconds,
      'notes': notes,
    };
  }

  /// Creates a copy of this [RoutineExercise] with the given fields replaced by the new values.
  RoutineExercise copyWith({
    int? id,
    Exercise? exercise,
    List<SetTemplate>? setTemplates,
    int? pauseSeconds,
    String? notes,
    bool clearNotes = false,
  }) {
    return RoutineExercise(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      setTemplates: setTemplates ?? this.setTemplates,
      pauseSeconds: pauseSeconds ?? this.pauseSeconds,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }
}
