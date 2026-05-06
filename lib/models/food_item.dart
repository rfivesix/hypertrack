// lib/models/food_item.dart
import 'package:flutter/widgets.dart'; // Added for BuildContext

enum FoodItemSource {
  off, // Open Food Facts
  base, // Base foods DB
  user, // Created by the user (default)
}

/// Represents a food item in the system.
///
/// Contains nutritional information, branding, and localized names.
class FoodItem {
  /// The barcode of the food item.
  final String barcode;

  /// The generic name of the food item.
  final String name; // Keep as fallback

  /// The name of the food item in German.
  final String nameDe; // New

  /// The name of the food item in English.
  final String nameEn; // New

  /// The brand or manufacturer of the food item.
  final String brand;

  /// Calories per 100g or 100ml.
  final int calories; // pro 100g

  /// Protein in grams per 100g or 100ml.
  final double protein; // pro 100g

  /// Carbohydrates in grams per 100g or 100ml.
  final double carbs; // pro 100g

  /// Fat in grams per 100g or 100ml.
  final double fat; // pro 100g

  /// The source of the food item data (e.g., Open Food Facts, Internal DB).
  final FoodItemSource source;

  /// The category or group the food belongs to.
  final String? category;

  /// Energy in kilojoules per 100g or 100ml.
  final double? kj;

  /// Fiber in grams per 100g or 100ml.
  final double? fiber;

  /// Sugar in grams per 100g or 100ml.
  final double? sugar;

  /// Salt in grams per 100g or 100ml.
  final double? salt;

  /// Sodium in grams per 100g or 100ml.
  final double? sodium;

  /// Calcium in milligrams per 100g or 100ml.
  final double? calcium;

  /// Whether the food item is a liquid (volume-based) instead of solid (weight-based).
  final bool? isLiquid;

  /// Caffeine content in milligrams per 100ml.
  final double? caffeineMgPer100ml;

  /// Creates a new [FoodItem] instance.
  FoodItem({
    required this.barcode,
    required this.name,
    this.nameDe = '', // New
    this.nameEn = '', // New
    this.brand = '',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.source = FoodItemSource.user,
    this.category,
    this.kj,
    this.fiber,
    this.sugar,
    this.salt,
    this.sodium,
    this.calcium,
    this.isLiquid,
    this.caffeineMgPer100ml,
  });

  /// Returns the name of the food item localized to the user's language.
  ///
  /// Priority: [nameDe] for German, [nameEn] for other languages, then [name] as fallback.
  String getLocalizedName(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'de' && nameDe.isNotEmpty) {
      return nameDe;
    }
    // Fall back to English if 'en' exists or the language is not German
    if (nameEn.isNotEmpty) {
      return nameEn;
    }
    // Final fallback to the generic name
    return name;
  }

  /// Creates a [FoodItem] instance from a Map, typically from a database row.
  ///
  /// The [source] must be explicitly provided.
  factory FoodItem.fromMap(
    Map<String, dynamic> map, {
    required FoodItemSource source,
  }) {
    return FoodItem(
      barcode: map['barcode'] ?? '',
      // FIXED LOGIC: Read all name variants
      name: map['name'] ?? '',
      nameDe: map['name_de'] ?? '',
      nameEn: map['name_en'] ?? '',
      brand: map['brand'] ?? '',
      calories: (map['calories_100g'] as num?)?.round() ?? 0,
      protein: (map['protein_100g'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs_100g'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat_100g'] as num?)?.toDouble() ?? 0.0,
      source: source,
      kj: (map['kj_100g'] as num?)?.toDouble(),
      fiber: (map['fiber_100g'] as num?)?.toDouble(),
      sugar: (map['sugar_100g'] as num?)?.toDouble(),
      salt: (map['salt_100g'] as num?)?.toDouble(),
      sodium: (map['sodium_100g'] as num?)?.toDouble(),
      calcium: (map['calcium_100g'] as num?)?.toDouble(),
      isLiquid: _readBool(map['is_liquid']),
      caffeineMgPer100ml: _toDoubleOrNull(map['caffeine_mg_per_100ml']),
    );
  }

  /// Converts the [FoodItem] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'name_de': nameDe, // New
      'name_en': nameEn, // New
      'brand': brand,
      'calories_100g': calories,
      'protein_100g': protein,
      'carbs_100g': carbs,
      'fat_100g': fat,
      'kj_100g': kj,
      'fiber_100g': fiber,
      'sugar_100g': sugar,
      'salt_100g': salt,
      'sodium_100g': sodium,
      'calcium_100g': calcium,
      'is_liquid': (isLiquid == null) ? null : (isLiquid! ? 1 : 0),
      'caffeine_mg_per_100ml': caffeineMgPer100ml,
    };
  }

  static bool? _readBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == '1' || s == 'true' || s == 'yes';
    }
    return null;
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }
}
