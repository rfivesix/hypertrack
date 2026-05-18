// lib/models/set_template.dart

/// Represents a template for a workout set in a routine.
///
/// Stores target values for repetitions, weight, and RIR to guide the user during a session.
class SetTemplate {
  /// Unique identifier for the set template.
  final int? id;

  /// The type of set (e.g., "Normal", "Warm-up").
  final String setType;

  /// The target number of repetitions (e.g., "8-12").
  final String? targetReps;

  /// The target weight to use in kilograms.
  final double? targetWeight;

  /// The target Reps in Reserve (RIR).
  final int? targetRir;

  /// Creates a new [SetTemplate] instance.
  SetTemplate({
    this.id,
    required this.setType,
    this.targetReps,
    this.targetWeight,
    this.targetRir,
  });

  /// Creates a [SetTemplate] instance from a Map, typically from a database row.
  factory SetTemplate.fromMap(Map<String, dynamic> map) {
    return SetTemplate(
      id: map['id'],
      setType: map['set_type'] ?? 'normal',
      targetReps: map['target_reps'],
      targetWeight: map['target_weight'],
      targetRir: map['target_rir'],
    );
  }

  /// Converts the [SetTemplate] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'set_type': setType,
      'target_reps': targetReps,
      'target_weight': targetWeight,
      'target_rir': targetRir,
    };
  }

  /// Creates a copy of this [SetTemplate] with the given fields replaced by the new values.
  SetTemplate copyWith({
    int? id,
    String? setType,
    String? targetReps,
    double? targetWeight,
    int? targetRir,
    bool clearTargetRir = false,
  }) {
    return SetTemplate(
      id: id ?? this.id,
      setType: setType ?? this.setType,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      targetRir: clearTargetRir ? null : (targetRir ?? this.targetRir),
    );
  }
}
