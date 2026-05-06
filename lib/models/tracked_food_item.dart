import 'food_entry.dart';
import 'food_item.dart';

// DOC: This class is a pure display model. It combines data
// from two different sources (the diary entry and the product catalog),
// so the UI can read everything from one place.
class TrackedFoodItem {
  final FoodEntry
      entry; // The actual diary entry (with ID, amount, and time)
  final FoodItem
      item; // Food details (with name, calories, etc.)

  TrackedFoodItem({required this.entry, required this.item});

  // Small helper property for the calculated calories of this entry.
  int get calculatedCalories {
    return (item.calories / 100 * entry.quantityInGrams).round();
  }
}
