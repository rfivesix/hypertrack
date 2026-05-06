// lib/models/supplement.dart
/// Represents a supplement that can be tracked by the user.
///
/// Contains basic information about the supplement, such as its name,
/// default dose, and unit of measurement.
class Supplement {
  /// Unique identifier for the supplement.
  final int? id;

  /// An optional unique code for the supplement (e.g., for barcode scanning).
  final String? code; // New, optional

  /// The name of the supplement (e.g., "Creatine Monohydrate").
  final String name;

  /// The default dose amount for this supplement.
  final double defaultDose;

  /// The unit of measurement for the dose (e.g., "g", "mg", "pill").
  final String unit;

  /// An optional daily goal for the amount of supplement to consume.
  final double? dailyGoal;

  /// An optional daily limit for the amount of supplement to consume.
  final double? dailyLimit;

  /// Optional notes or information about the supplement.
  final String? notes;

  /// Whether the supplement is a built-in default or created by the user.
  final bool isBuiltin;

  /// Whether the supplement is currently actively tracked by the user.
  final bool isTracked;

  /// Creates a new [Supplement] instance.
  Supplement({
    this.id,
    this.code,
    required this.name,
    required this.defaultDose,
    required this.unit,
    this.dailyGoal,
    this.dailyLimit,
    this.notes,
    this.isBuiltin = false,
    this.isTracked = true,
  });

  /// Creates a [Supplement] instance from a Map, typically from a database row.
  factory Supplement.fromMap(Map<String, dynamic> map) {
    return Supplement(
      id: map['id'] as int?,
      code: map['code'] as String?, // New
      name: map['name'] as String,
      defaultDose: (map['default_dose'] as num).toDouble(),
      unit: map['unit'] as String,
      dailyGoal: (map['daily_goal'] as num?)?.toDouble(),
      dailyLimit: (map['daily_limit'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      isBuiltin: (map['is_builtin'] as int? ?? 0) == 1,
      isTracked: (map['is_tracked'] as int? ?? 1) == 1,
    );
  }

  /// Converts the [Supplement] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code, // New
      'name': name,
      'default_dose': defaultDose,
      'unit': unit,
      'daily_goal': dailyGoal,
      'daily_limit': dailyLimit,
      'notes': notes,
      'is_builtin': isBuiltin ? 1 : 0,
      'is_tracked': isTracked ? 1 : 0,
    };
  }
}
