// lib/models/fluid_entry.dart

/// Represents a record of a fluid (beverage) consumption.
///
/// Contains information about the type of fluid, quantity, and its nutritional content.
class FluidEntry {
  /// Unique identifier for the fluid entry.
  final int? id;

  /// The exact time when the fluid was consumed.
  final DateTime timestamp;

  /// The quantity consumed in milliliters.
  final int quantityInMl;

  /// The name of the beverage.
  final String name;

  /// Calories per 100ml.
  final int? kcal;

  /// Sugar in grams per 100ml.
  final double? sugarPer100ml;

  /// Carbohydrates in grams per 100ml.
  final double? carbsPer100ml;

  /// Caffeine in milligrams per 100ml.
  final double? caffeinePer100ml;

  /// Optional identifier linking this fluid entry to a food entry.
  final int? linkedFoodEntryId; // *** NEU ***

  /// Last modification timestamp from persistence when available.
  final DateTime? updatedAt;

  /// Creates a new [FluidEntry] instance.
  FluidEntry({
    this.id,
    required this.timestamp,
    required this.quantityInMl,
    required this.name,
    this.kcal,
    this.sugarPer100ml,
    this.carbsPer100ml,
    this.caffeinePer100ml,
    this.linkedFoodEntryId, // *** NEU ***
    this.updatedAt,
  });

  /// Converts the [FluidEntry] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'quantity_in_ml': quantityInMl,
      'name': name,
      'kcal': kcal,
      'sugar_per_100ml': sugarPer100ml,
      'carbs_per_100ml': carbsPer100ml,
      'caffeine_per_100ml': caffeinePer100ml,
      'linked_food_entry_id': linkedFoodEntryId, // *** NEU ***
    };
  }

  /// Creates a [FluidEntry] instance from a Map, typically from a database row.
  static FluidEntry fromMap(Map<String, dynamic> map) {
    return FluidEntry(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      quantityInMl: map['quantity_in_ml'],
      name: map['name'],
      kcal: map['kcal'],
      sugarPer100ml: map['sugar_per_100ml'],
      carbsPer100ml: map['carbs_per_100ml'],
      caffeinePer100ml: map['caffeine_per_100ml'],
      linkedFoodEntryId: map['linked_food_entry_id'], // *** NEU ***
    );
  }
}
