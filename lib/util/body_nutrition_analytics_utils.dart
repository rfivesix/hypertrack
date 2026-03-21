import '../data/database_helper.dart';
import '../data/product_database_helper.dart';
import '../features/statistics/data/body_nutrition_analytics_data_adapter.dart';
import '../features/statistics/domain/body_nutrition_analytics_engine.dart';
import '../features/statistics/domain/body_nutrition_analytics_models.dart';

export '../features/statistics/domain/body_nutrition_analytics_models.dart';

class BodyNutritionAnalyticsUtils {
  static DateTime normalizeDay(DateTime date) =>
      BodyNutritionAnalyticsDataAdapter.normalizeDay(date);

  static DateTime endOfDay(DateTime date) =>
      BodyNutritionAnalyticsDataAdapter.endOfDay(date);

  static int daysFromRangeIndex(int index) =>
      BodyNutritionAnalyticsDataAdapter.daysFromRangeIndex(index);

  static Future<BodyNutritionAnalyticsResult> build({
    required int rangeIndex,
  }) async {
    final adapter = BodyNutritionAnalyticsDataAdapter(
      databaseHelper: DatabaseHelper.instance,
      productDatabaseHelper: ProductDatabaseHelper.instance,
    );
    final raw = await adapter.fetch(rangeIndex: rangeIndex);
    return BodyNutritionAnalyticsEngine.build(
      range: raw.range,
      weightPoints: raw.weightPoints,
      caloriesByDay: raw.caloriesByDay,
    );
  }

  static List<DailyValuePoint> normalizedSeries(List<DailyValuePoint> points) =>
      BodyNutritionAnalyticsEngine.normalizedSeries(points);
}
