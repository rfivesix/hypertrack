// lib/models/food_entry.dart

/// Represents a single food intake record.
///
/// Links a [FoodItem] (via [barcode]) to a specific time, quantity, and meal type.
class FoodEntry {
  /// Unique identifier for the food entry.
  final int? id;

  /// The barcode of the consumed [FoodItem].
  final String barcode;

  /// The exact time when the food was consumed.
  final DateTime timestamp;

  /// The amount consumed in grams.
  final int quantityInGrams;

  /// The type of meal (e.g., "Breakfast", "Lunch", "Dinner", "Snack").
  final String mealType;

  /// Last modification timestamp from persistence when available.
  final DateTime? updatedAt;

  /// Creates a new [FoodEntry] instance.
  FoodEntry({
    this.id,
    required this.barcode,
    required this.timestamp,
    required this.quantityInGrams,
    required this.mealType,
    this.updatedAt,
  });

  /// Converts the [FoodEntry] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'timestamp': timestamp.toIso8601String(),
      'quantity_in_grams': quantityInGrams,
      'meal_type': mealType,
    };
  }
}
