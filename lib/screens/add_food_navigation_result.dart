import '../models/food_item.dart';

/// Interprets values returned by [AddFoodScreen] routes.
class AddFoodNavigationResult {
  final bool shouldRefresh;
  final FoodItem? selectedFoodItem;

  const AddFoodNavigationResult({
    required this.shouldRefresh,
    required this.selectedFoodItem,
  });

  factory AddFoodNavigationResult.fromRouteResult(Object? result) {
    if (result == true) {
      return const AddFoodNavigationResult(
        shouldRefresh: true,
        selectedFoodItem: null,
      );
    }
    if (result is FoodItem) {
      return AddFoodNavigationResult(
        shouldRefresh: false,
        selectedFoodItem: result,
      );
    }
    return const AddFoodNavigationResult(
      shouldRefresh: false,
      selectedFoodItem: null,
    );
  }
}
