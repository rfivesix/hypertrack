import 'package:flutter/material.dart';

/// Custom theme extension for application-specific surface colors.
///
/// Use this to define colors that aren't natively supported by the standard
/// [ThemeData], such as specific card backgrounds for summaries.
@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  final Color summaryCard;
  const AppSurfaces({required this.summaryCard});

  @override
  AppSurfaces copyWith({Color? summaryCard}) =>
      AppSurfaces(summaryCard: summaryCard ?? this.summaryCard);

  @override
  AppSurfaces lerp(ThemeExtension<AppSurfaces>? other, double t) {
    if (other is! AppSurfaces) return this;
    return AppSurfaces(
      summaryCard: Color.lerp(summaryCard, other.summaryCard, t)!,
    );
  }
}

/// Custom theme extension for consistent macro-nutrient and hydration colors.
@immutable
class MacroColors extends ThemeExtension<MacroColors> {
  final Color calories;
  final Color protein;
  final Color carbs;
  final Color fat;
  final Color water;
  final Color sugar;
  final Color fiber;
  final Color salt;
  final Color caffeine;

  const MacroColors({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.water,
    required this.sugar,
    required this.fiber,
    required this.salt,
    required this.caffeine,
  });

  @override
  MacroColors copyWith({
    Color? calories,
    Color? protein,
    Color? carbs,
    Color? fat,
    Color? water,
    Color? sugar,
    Color? fiber,
    Color? salt,
    Color? caffeine,
  }) {
    return MacroColors(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      water: water ?? this.water,
      sugar: sugar ?? this.sugar,
      fiber: fiber ?? this.fiber,
      salt: salt ?? this.salt,
      caffeine: caffeine ?? this.caffeine,
    );
  }

  @override
  MacroColors lerp(ThemeExtension<MacroColors>? other, double t) {
    if (other is! MacroColors) return this;
    return MacroColors(
      calories: Color.lerp(calories, other.calories, t)!,
      protein: Color.lerp(protein, other.protein, t)!,
      carbs: Color.lerp(carbs, other.carbs, t)!,
      fat: Color.lerp(fat, other.fat, t)!,
      water: Color.lerp(water, other.water, t)!,
      sugar: Color.lerp(sugar, other.sugar, t)!,
      fiber: Color.lerp(fiber, other.fiber, t)!,
      salt: Color.lerp(salt, other.salt, t)!,
      caffeine: Color.lerp(caffeine, other.caffeine, t)!,
    );
  }
}
