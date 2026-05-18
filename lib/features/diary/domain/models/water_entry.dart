/// Represents a record of plain water consumption.
///
/// Tracks the quantity of water consumed and the time of intake.
class WaterEntry {
  /// Unique identifier for the water entry.
  final int? id;

  /// The exact time when the water was consumed.
  final DateTime timestamp;

  /// The quantity consumed in milliliters.
  final int quantityInMl;

  /// Creates a new [WaterEntry] instance.
  WaterEntry({this.id, required this.timestamp, required this.quantityInMl});

  /// Creates a [WaterEntry] instance from a Map, typically from a database row.
  factory WaterEntry.fromMap(Map<String, dynamic> map) {
    return WaterEntry(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      quantityInMl: map['quantity_in_ml'],
    );
  }

  /// Converts the [WaterEntry] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'quantity_in_ml': quantityInMl,
    };
  }
}
