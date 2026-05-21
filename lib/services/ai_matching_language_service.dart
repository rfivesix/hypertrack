// lib/services/ai_matching_language_service.dart

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'base_food_language_service.dart';

/// Possible language choices for AI food-name matching.
///
/// This setting controls which language the AI uses for food names when
/// querying the local database. It is intentionally **decoupled** from
/// the app UI language so that a user running the app in German can
/// match against an English food database, or vice versa.
enum AiMatchingLanguage {
  /// Follow the base-food display language (default).
  auto,

  /// Always match in English.
  en,

  /// Always match in German.
  de,
}

/// Persists and resolves the user's preferred AI matching language.
///
/// Mirrors the [BaseFoodLanguageService] pattern: preference stored
/// in [SharedPreferences], resolved at runtime.
class AiMatchingLanguageService {
  const AiMatchingLanguageService._();

  static const String _preferenceKey = 'ai_matching_language';

  /// Read the persisted choice. Returns [AiMatchingLanguage.auto] if unset.
  static Future<AiMatchingLanguage> readChoice({
    SharedPreferences? prefs,
  }) async {
    final resolved = prefs ?? await SharedPreferences.getInstance();
    return _parse(resolved.getString(_preferenceKey));
  }

  /// Write a new choice.
  static Future<void> writeChoice(
    AiMatchingLanguage choice, {
    SharedPreferences? prefs,
  }) async {
    final resolved = prefs ?? await SharedPreferences.getInstance();
    await resolved.setString(_preferenceKey, choice.name);
  }

  /// Resolve the effective language code (`'en'` or `'de'`) for AI matching.
  ///
  /// When [choice] is [AiMatchingLanguage.auto]:
  ///   - Delegates to [BaseFoodLanguageService.resolveLanguageCode] so the
  ///     AI matching language stays in sync with the base-food display
  ///     language (and ultimately the app locale).
  static Future<String> resolveLanguageCode({
    required AiMatchingLanguage choice,
    required BuildContext context,
  }) async {
    if (choice == AiMatchingLanguage.en) return 'en';
    if (choice == AiMatchingLanguage.de) return 'de';

    // Capture locale before async gap to avoid linter warning
    final locale = Localizations.localeOf(context).languageCode;

    // Auto mode: follow base-food display language.
    final baseFoodChoice = await BaseFoodLanguageService.readChoice();
    return BaseFoodLanguageService.resolveLanguageCodeFromLocale(
      choice: baseFoodChoice,
      locale: locale,
    );
  }

  static AiMatchingLanguage _parse(String? value) {
    if (value == null) return AiMatchingLanguage.auto;
    return AiMatchingLanguage.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AiMatchingLanguage.auto,
    );
  }
}
