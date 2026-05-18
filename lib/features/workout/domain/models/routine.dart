// lib/models/routine.dart
import 'routine_exercise.dart';

/// Represents a structured workout plan or routine.
///
/// A routine consists of a name and a sequence of exercises to be performed.
class Routine {
  /// Unique identifier for the routine.
  final int? id;

  /// The name of the routine (e.g., "Leg Day", "Push A").
  final String name;

  /// The list of exercises included in this routine.
  final List<RoutineExercise> exercises;

  /// Creates a new [Routine] instance.
  Routine({this.id, required this.name, this.exercises = const []});

  /// Converts the [Routine] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((re) => re.toMap()).toList(),
    };
  }
}
