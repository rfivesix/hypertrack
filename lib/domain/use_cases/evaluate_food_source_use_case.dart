import '../../features/diary/domain/models/food_item.dart';

/// Use Case to score and prioritize food source candidates.
/// Prioritizes exact matches, starts-with prefixes, and specific source types
/// (base/user first, then OFF).
class EvaluateFoodSourceUseCase {
  const EvaluateFoodSourceUseCase();

  List<FoodItem> execute({
    required List<FoodItem> candidates,
    required String searchTerm,
    int limit = 5,
  }) {
    final searchLower = searchTerm.trim().toLowerCase();
    final items = List<FoodItem>.from(candidates);

    items.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();

      int score(String name) {
        if (name == searchLower) return 0;
        if (name.startsWith(searchLower)) return 1;
        return 2;
      }

      final sa = score(aName);
      final sb = score(bName);
      if (sa != sb) return sa.compareTo(sb);

      int srcPri(FoodItemSource s) {
        switch (s) {
          case FoodItemSource.base:
            return 0;
          case FoodItemSource.user:
            return 1;
          case FoodItemSource.off:
            return 2;
        }
      }

      final spa = srcPri(a.source);
      final spb = srcPri(b.source);
      if (spa != spb) return spa.compareTo(spb);

      return aName.length.compareTo(bName.length);
    });

    return items.take(limit).toList();
  }
}
