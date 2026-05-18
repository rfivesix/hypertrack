import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/diary/domain/models/food_item.dart';
import 'package:train_libre/features/diary/presentation/add_food_screen.dart';

void main() {
  test('calculateMealCardNutritionTotals batches product data by barcode', () {
    final totals = calculateMealCardNutritionTotals(
      items: const [
        {
          'barcode': 'oats',
          'quantity_in_grams': 50,
        },
        {
          'barcode': 'milk',
          'quantity_in_grams': 200,
        },
        {
          'barcode': 'missing',
          'quantity_in_grams': 25,
        },
      ],
      productsByBarcode: {
        'oats': FoodItem(
          barcode: 'oats',
          name: 'Oats',
          calories: 380,
          protein: 13,
          carbs: 60,
          fat: 7,
        ),
        'milk': FoodItem(
          barcode: 'milk',
          name: 'Milk',
          calories: 50,
          protein: 3.4,
          carbs: 4.8,
          fat: 1.5,
        ),
      },
    );

    expect(totals.ingredientCount, 3);
    expect(totals.kcal, 290);
    expect(totals.carbs, closeTo(39.6, 0.001));
    expect(totals.fat, closeTo(6.5, 0.001));
    expect(totals.protein, closeTo(13.3, 0.001));
  });
}
