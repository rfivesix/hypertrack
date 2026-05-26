import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';

/// Represents the user's biological gender preference.
enum UserGender {
  male,
  female,
  diverse;

  /// Maps a string value (likely from DB) to [UserGender].
  ///
  /// Defaults to [UserGender.male] if null or unknown.
  static UserGender fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'male':
        return UserGender.male;
      case 'female':
        return UserGender.female;
      case 'diverse':
        return UserGender.diverse;
      default:
        return UserGender.male;
    }
  }

  /// Maps [UserGender] to the package-specific [BodyGender].
  ///
  /// - [UserGender.female] ➔ [BodyGender.female]
  /// - [UserGender.male] ➔ [BodyGender.male]
  /// - [UserGender.diverse] ➔ [BodyGender.male] (fallback strictly to male)
  BodyGender toBodyGender() {
    switch (this) {
      case UserGender.female:
        return BodyGender.female;
      case UserGender.male:
      case UserGender.diverse:
        return BodyGender.male;
    }
  }
}
