import '../../generated/app_localizations.dart';

/// Supported metric types for the Today in focus home-screen widget.
enum TodayFocusMetricType {
  calories,
  protein,
  water,
  carbohydrates,
  sugar,
  fat,
  caffeine,
  creatine,
  otherSupplements,
  steps,
  workouts,
  sleep,
}

extension TodayFocusMetricTypeX on TodayFocusMetricType {
  static const List<TodayFocusMetricType> stableOrder = <TodayFocusMetricType>[
    TodayFocusMetricType.calories,
    TodayFocusMetricType.protein,
    TodayFocusMetricType.water,
    TodayFocusMetricType.carbohydrates,
    TodayFocusMetricType.sugar,
    TodayFocusMetricType.fat,
    TodayFocusMetricType.caffeine,
    TodayFocusMetricType.creatine,
    TodayFocusMetricType.otherSupplements,
    TodayFocusMetricType.steps,
    TodayFocusMetricType.workouts,
    TodayFocusMetricType.sleep,
  ];

  String get key => name;

  static TodayFocusMetricType? fromKey(String raw) {
    for (final type in TodayFocusMetricType.values) {
      if (type.name == raw) return type;
    }
    return null;
  }

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case TodayFocusMetricType.calories:
        return l10n.calories;
      case TodayFocusMetricType.protein:
        return l10n.protein;
      case TodayFocusMetricType.water:
        return l10n.water;
      case TodayFocusMetricType.carbohydrates:
        return l10n.carbs;
      case TodayFocusMetricType.sugar:
        return l10n.sugar;
      case TodayFocusMetricType.fat:
        return l10n.fat;
      case TodayFocusMetricType.caffeine:
        return l10n.supplement_caffeine;
      case TodayFocusMetricType.creatine:
        return l10n.widgetMetricCreatine;
      case TodayFocusMetricType.otherSupplements:
        return l10n.widgetMetricSupplements;
      case TodayFocusMetricType.steps:
        return l10n.steps;
      case TodayFocusMetricType.workouts:
        return l10n.workoutsLabel;
      case TodayFocusMetricType.sleep:
        return l10n.sleepSectionTitle;
    }
  }

  int get accentColorArgb {
    switch (this) {
      case TodayFocusMetricType.calories:
        return 0xFFFF9800;
      case TodayFocusMetricType.protein:
        return 0xFFE53935;
      case TodayFocusMetricType.water:
        return 0xFF2196F3;
      case TodayFocusMetricType.carbohydrates:
        return 0xFF43A047;
      case TodayFocusMetricType.sugar:
        return 0xFFE91E63;
      case TodayFocusMetricType.fat:
        return 0xFF8E24AA;
      case TodayFocusMetricType.caffeine:
        return 0xFF6D4C41;
      case TodayFocusMetricType.creatine:
        return 0xFF00ACC1;
      case TodayFocusMetricType.otherSupplements:
        return 0xFF5E35B1;
      case TodayFocusMetricType.steps:
        return 0xFF26A69A;
      case TodayFocusMetricType.workouts:
        return 0xFFEF6C00;
      case TodayFocusMetricType.sleep:
        return 0xFF3F51B5;
    }
  }
}

class TodayFocusWidgetItem {
  const TodayFocusWidgetItem({
    required this.type,
    required this.label,
    required this.valueText,
    required this.accentColorArgb,
  });

  final TodayFocusMetricType type;
  final String label;
  final String valueText;
  final int accentColorArgb;

  Map<String, Object> toJson() {
    return {
      'key': type.key,
      'label': label,
      'valueText': valueText,
      'accentColor': accentColorArgb,
    };
  }
}
