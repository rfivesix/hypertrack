// lib/services/ai_repair_candidate.dart

import '../features/diary/domain/models/food_item.dart';

/// A compact representation of a real database food entity,
/// formatted for injection into an AI repair prompt.
class AiRepairCandidate {
  final String exactName;     // The exact DB product name the AI must use
  final String? barcode;      // For direct barcode matching after repair
  final int kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final String source;        // "base" | "user" | "off"

  const AiRepairCandidate({
    required this.exactName,
    this.barcode,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.source,
  });

  /// Formats this candidate as a single line for prompt injection.
  /// Example: '  - "Hahnchenfleisch, zubereitet" (165 kcal | P31 C0 F4 per 100g) [base]'
  String toPromptLine() {
    return '  - "$exactName" ($kcalPer100g kcal | '
        'P${proteinPer100g.round()} C${carbsPer100g.round()} '
        'F${fatPer100g.round()} per 100g) [$source]';
  }

  /// Creates from a FoodItem.
  factory AiRepairCandidate.fromFoodItem(FoodItem food) {
    String src = 'base';
    if (food.source == FoodItemSource.user) {
      src = 'user';
    } else if (food.source == FoodItemSource.off) {
      src = 'off';
    }

    return AiRepairCandidate(
      exactName: food.getLocalizedName(null),
      barcode: food.barcode,
      kcalPer100g: food.calories.round(),
      proteinPer100g: food.protein,
      carbsPer100g: food.carbs,
      fatPer100g: food.fat,
      source: src,
    );
  }
}
