import 'food_entry.dart';
import 'food_item.dart';

// DOC: Diese Klasse ist ein reines "Anzeige-Modell". Sie kombiniert die Daten
// aus zwei verschiedenen Quellen (unserem Tagebucheintrag und dem Produktkatalog),
// damit die UI sie einfach an einem Ort abgreifen kann.
class TrackedFoodItem {
  final FoodEntry
  entry; // Der eigentliche Tagebucheintrag (mit ID, Menge, Zeit)
  final FoodItem
  item; // Die Details des Lebensmittels (mit Name, Kalorien etc.)

  TrackedFoodItem({required this.entry, required this.item});

  // Eine kleine Helfer-Eigenschaft, um die berechneten Kalorien für diesen Eintrag zu bekommen.
  int get calculatedCalories {
    return (item.calories / 100 * entry.quantityInGrams).round();
  }
}
