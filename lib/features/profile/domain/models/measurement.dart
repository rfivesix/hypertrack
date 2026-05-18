// lib/models/measurement.dart

/// Represents a single body measurement.
///
/// Contains information about the measurement type (e.g., "Weight"), value, and unit.
class Measurement {
  /// Unique identifier for the measurement.
  final int? id;

  /// The identifier of the [MeasurementSession] this measurement belongs to.
  final int sessionId;

  /// The type of measurement (e.g., "Weight", "Body Fat", "Biceps").
  final String type;

  /// The numeric value of the measurement.
  final double value;

  /// The unit of measurement (e.g., "kg", "%", "cm").
  final String unit;

  /// Last modification timestamp from persistence when available.
  final DateTime? updatedAt;

  /// Creates a new [Measurement] instance.
  Measurement({
    this.id,
    required this.sessionId,
    required this.type,
    required this.value,
    required this.unit,
    this.updatedAt,
  });

  /// Creates a [Measurement] instance from a Map, typically from a database row.
  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'],
      sessionId: map['session_id'],
      type: map['type'],
      value: map['value'],
      unit: map['unit'],
    );
  }

  /// Converts the [Measurement] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'type': type,
      'value': value,
      'unit': unit,
    };
  }
}
