// lib/models/food_item.dart
import 'dart:convert';

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

  /// Whether the product is inherently a fluid/beverage.
  final bool isFluid;

  /// Caffeine content in milligrams per 100ml.
  final double? caffeineMgPer100ml;

  /// Caffeine content in milligrams per 100g.
  final double? caffeineMgPer100g;

  /// Full ingredients text.
  final String? ingredientsText;

  /// Analysis tags like 'vegan', 'vegetarian'.
  final List<String>? ingredientsAnalysisTags;

  /// List of additives (tags).
  final List<String>? additivesTags;

  /// Net quantity of the product.
  final double? productQuantity;

  /// Unit of the quantity (e.g., 'g', 'ml').
  final String? productQuantityUnit;

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
    this.isFluid = false,
    this.caffeineMgPer100ml,
    this.caffeineMgPer100g,
    this.ingredientsText,
    this.ingredientsAnalysisTags,
    this.additivesTags,
    this.productQuantity,
    this.productQuantityUnit,
  });

  /// Returns the name of the food item localized to the user's language.
  ///
  /// If [languageCode] is provided it takes precedence over the app locale.
  /// Priority: [nameDe] for German, [nameEn] for other languages, then [name] as fallback.
  String getLocalizedName(BuildContext? context, {String? languageCode}) {
    final lang = languageCode ??
        (context != null
            ? Localizations.localeOf(context).languageCode
            : 'de');
    if (lang == 'de' && nameDe.isNotEmpty) {
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
    final item = FoodItem(
      barcode: map['barcode'] ?? '',
      // FIXED LOGIC: Read all name variants
      name: map['name'] ?? '',
      nameDe: map['name_de'] ?? map['name'] ?? '',
      nameEn: map['name_en'] ?? map['name'] ?? '',
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
      isFluid: _readBool(map['is_fluid']) ?? false,
      caffeineMgPer100ml: _toDoubleOrNull(map['caffeine_mg_per_100ml']) ??
          _toDoubleOrNull(map['caffeine']),
      // Robust naming: check both caffeine_mg_per_100g (Python/Asset) and caffeine_mg_per100g (Drift default)
      caffeineMgPer100g: _toDoubleOrNull(map['caffeine_mg_per_100g']) ??
          _toDoubleOrNull(map['caffeine_mg_per100g']),
      ingredientsText: map['ingredients_text'],

      ingredientsAnalysisTags: _toStringList(map['ingredients_analysis_tags']),
      additivesTags: _toStringList(map['additives_tags']),
      productQuantity: _toDoubleOrNull(map['product_quantity']),
      productQuantityUnit: map['product_quantity_unit'],
    );

    return item;
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
      'is_fluid': isFluid ? 1 : 0,
      'caffeine_mg_per_100ml': caffeineMgPer100ml,
      'caffeine_mg_per_100g': caffeineMgPer100g,
      'ingredients_text': ingredientsText,
      'ingredients_analysis_tags': _listToJson(ingredientsAnalysisTags),
      'additives_tags': _listToJson(additivesTags),
      'product_quantity': productQuantity,
      'product_quantity_unit': productQuantityUnit,
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

  static List<String>? _toStringList(dynamic v) {
    if (v == null) return null;
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String) {
      if (v.startsWith('[') && v.endsWith(']')) {
        try {
          final decoded = jsonDecode(v);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          // Fallback: manual split for non-standard JSON (e.g. single-quoted)
          return v
              .substring(1, v.length - 1)
              .split(',')
              .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ""))
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
      return [v];
    }
    return null;
  }

  static String? _listToJson(List<String>? list) {
    if (list == null) return null;
    return '[${list.map((e) => '"$e"').join(',')}]';
  }
}
