// lib/util/l10n_ext.dart
import 'package:flutter/widgets.dart';
import '../generated/app_localizations.dart';

// Extension on BuildContext for concise localization access.
/// Convenience extension for accessing [AppLocalizations] from [BuildContext].
extension L10nX on BuildContext {
  /// Returns the [AppLocalizations] instance for the current context.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

// Extension on AppLocalizations for dynamic measurement-name lookup.
/// Extension for [AppLocalizations] to provide dynamic lookup for localized names.
extension AppLocalizationsX on AppLocalizations {
  String getLocalizedMeasurementName(String key) {
    switch (key) {
      case 'weight':
        return measurementWeight;
      case 'fat_percent':
        return measurementFatPercent;
      case 'neck':
        return measurementNeck;
      case 'shoulder':
        return measurementShoulder;
      case 'chest':
        return measurementChest;
      case 'left_bicep':
        return measurementLeftBicep;
      case 'right_bicep':
        return measurementRightBicep;
      case 'left_forearm':
        return measurementLeftForearm;
      case 'right_forearm':
        return measurementRightForearm;
      case 'abdomen':
        return measurementAbdomen;
      case 'waist':
        return measurementWaist;
      case 'hips':
        return measurementHips;
      case 'left_thigh':
        return measurementLeftThigh;
      case 'right_thigh':
        return measurementRightThigh;
      case 'left_calf':
        return measurementLeftCalf;
      case 'right_calf':
        return measurementRightCalf;
      default:
        return key;
    }
  }
}
