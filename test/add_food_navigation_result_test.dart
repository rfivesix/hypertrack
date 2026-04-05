import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/models/food_item.dart';
import 'package:hypertrack/screens/add_food_navigation_result.dart';

void main() {
  group('AddFoodNavigationResult.fromRouteResult', () {
    test('returns refresh=true for AI save signal', () {
      final result = AddFoodNavigationResult.fromRouteResult(true);

      expect(result.shouldRefresh, isTrue);
      expect(result.selectedFoodItem, isNull);
    });

    test('returns selected FoodItem for picker flow', () {
      final foodItem = FoodItem(
        barcode: '123',
        name: 'Test Food',
        calories: 100,
        protein: 1,
        carbs: 2,
        fat: 3,
      );

      final result = AddFoodNavigationResult.fromRouteResult(foodItem);

      expect(result.shouldRefresh, isFalse);
      expect(result.selectedFoodItem, same(foodItem));
    });

    test('returns no-op for unsupported route results', () {
      final result = AddFoodNavigationResult.fromRouteResult('unexpected');

      expect(result.shouldRefresh, isFalse);
      expect(result.selectedFoodItem, isNull);
    });
  });
}
