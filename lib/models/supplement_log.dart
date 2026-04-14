// lib/models/supplement_log.dart

/// Represents a record of a supplement being consumed.
///
/// Tracks the supplement consumed, the dose, and the time of consumption.
class SupplementLog {
  /// Unique identifier for the supplement log.
  final int? id;

  /// The identifier of the supplement consumed.
  final int supplementId;

  /// The dose amount consumed.
  final double dose;

  /// The unit of measurement for the dose.
  final String unit;

  /// The exact time when the supplement was consumed.
  final DateTime timestamp;

  /// Optional identifier linking this log to a food entry.
  final int? sourceFoodEntryId;

  /// Optional identifier linking this log to a fluid entry.
  final int? sourceFluidEntryId;

  /// Creates a new [SupplementLog] instance.
  SupplementLog({
    this.id,
    required this.supplementId,
    required this.dose,
    required this.unit,
    required this.timestamp,
    this.sourceFoodEntryId, // Jetzt als optionaler Parameter verfügbar
    this.sourceFluidEntryId, // Jetzt als optionaler Parameter verfügbar
  });

  /// Converts the [SupplementLog] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplement_id': supplementId,
      'dose': dose,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'source_food_entry_id': sourceFoodEntryId,
      'source_fluid_entry_id': sourceFluidEntryId,
    };
  }

  /// Creates a [SupplementLog] instance from a Map, typically from a database row.
  factory SupplementLog.fromMap(Map<String, dynamic> map) {
    return SupplementLog(
      id: map['id'],
      supplementId: map['supplement_id'],
      dose: map['dose'],
      unit: map['unit'],
      timestamp: DateTime.parse(map['timestamp']),
      sourceFoodEntryId: map['source_food_entry_id'],
      sourceFluidEntryId: map['source_fluid_entry_id'],
    );
  }
}
