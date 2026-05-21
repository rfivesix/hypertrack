// lib/services/base_food_language_service.dart

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_data_sources.dart';

/// Possible display-language choices for base food names.
enum BaseFoodLanguage {
  /// Follow the app's current locale (default).
  auto,

  /// Always show English names.
  en,

  /// Always show German names.
  de,
}

/// Persists and resolves the user's preferred display language for base foods.
///
/// The resolved language considers three inputs:
/// 1. The explicit user choice (auto / en / de).
/// 2. The app's current locale (when auto is selected).
/// 3. The selected food-database region as a sensible fallback.
class BaseFoodLanguageService {
  const BaseFoodLanguageService._();

  static const String _preferenceKey = 'base_food_display_language';

  /// Read the persisted choice. Returns [BaseFoodLanguage.auto] if unset.
  static Future<BaseFoodLanguage> readChoice({
    SharedPreferences? prefs,
  }) async {
    final resolved = prefs ?? await SharedPreferences.getInstance();
    return _parse(resolved.getString(_preferenceKey));
  }

  /// Write a new choice.
  static Future<void> writeChoice(
    BaseFoodLanguage choice, {
    SharedPreferences? prefs,
  }) async {
    final resolved = prefs ?? await SharedPreferences.getInstance();
    await resolved.setString(_preferenceKey, choice.name);
  }

  /// Resolve the effective language code (`'en'` or `'de'`) to use for display.
  ///
  /// When [choice] is [BaseFoodLanguage.auto]:
  ///   - If the app locale is German → `'de'`.
  ///   - If the food-database region is UK/US → `'en'`.
  ///   - Otherwise → follow app locale, fallback `'en'`.
  static String resolveLanguageCode({
    required BaseFoodLanguage choice,
    required BuildContext context,
    OffCatalogCountry? activeCountry,
  }) {
    if (choice == BaseFoodLanguage.en) return 'en';
    if (choice == BaseFoodLanguage.de) return 'de';

    final locale = Localizations.localeOf(context).languageCode;
    return resolveLanguageCodeFromLocale(
      choice: choice,
      locale: locale,
      activeCountry: activeCountry,
    );
  }

  /// Version of [resolveLanguageCode] that takes a [locale] string instead
  /// of a [BuildContext].
  static String resolveLanguageCodeFromLocale({
    required BaseFoodLanguage choice,
    required String locale,
    OffCatalogCountry? activeCountry,
  }) {
    if (choice == BaseFoodLanguage.en) return 'en';
    if (choice == BaseFoodLanguage.de) return 'de';

    // Auto mode: follow locale with region fallback.
    if (locale == 'de') return 'de';

    // Non-German locale: check region for a sensible default.
    if (activeCountry == OffCatalogCountry.uk ||
        activeCountry == OffCatalogCountry.us) {
      return 'en';
    }

    // Fallback: use English.
    return 'en';
  }

  static BaseFoodLanguage _parse(String? value) {
    if (value == null) return BaseFoodLanguage.auto;
    return BaseFoodLanguage.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BaseFoodLanguage.auto,
    );
  }
}
