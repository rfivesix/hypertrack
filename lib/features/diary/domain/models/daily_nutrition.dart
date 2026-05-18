// lib/models/daily_nutrition.dart

/// Represents the nutritional totals and goals for a single day.
///
/// Aggregates data from [FoodEntry] and [WaterEntry] to show progress against targets.
class DailyNutrition {
  // Consumed nutrients
  /// Total calories consumed today.
  int calories;

  /// Total water consumed today in milliliters.
  int water;

  /// Total protein consumed today in grams.
  int protein;

  /// Total carbohydrates consumed today in grams.
  int carbs;

  /// Total fat consumed today in grams.
  int fat;

  /// Total fiber consumed today in grams.
  double fiber;

  /// Total sugar consumed today in grams.
  double sugar;

  /// Total salt consumed today in grams.
  double salt;

  /// Total caffeine consumed today in milligrams.
  double caffeine;

  // Goals
  /// Target daily calorie intake.
  int targetCalories;

  /// Target daily water intake in milliliters.
  int targetWater;

  /// Target daily protein intake in grams.
  int targetProtein;

  /// Target daily carbohydrate intake in grams.
  int targetCarbs;

  /// Target daily fat intake in grams.
  int targetFat;

  // DOC: New target fields
  /// Target daily sugar intake in grams.
  int targetSugar;

  /// Target daily fiber intake in grams.
  int targetFiber;

  /// Target daily salt intake in grams.
  int targetSalt;

  /// Target daily caffeine intake in milligrams.
  int targetCaffeine;

  /// Creates a new [DailyNutrition] instance with default values.
  DailyNutrition({
    this.calories = 0,
    this.water = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0.0,
    this.sugar = 0.0,
    this.salt = 0.0,
    this.caffeine = 0.0,
    this.targetCalories = 0,
    this.targetWater = 0,
    this.targetProtein = 0,
    this.targetCarbs = 0,
    this.targetFat = 0,

    // DOC: Initialize the new goals
    this.targetSugar = 0,
    this.targetFiber = 0,
    this.targetSalt = 0,
    this.targetCaffeine = 0,
  });
}
