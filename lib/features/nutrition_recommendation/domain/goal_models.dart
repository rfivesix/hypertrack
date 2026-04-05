enum BodyweightGoal {
  loseWeight,
  maintainWeight,
  gainWeight,
}

enum PriorActivityLevel {
  low,
  moderate,
  high,
}

class PriorActivityLevelCatalog {
  const PriorActivityLevelCatalog._();

  static const PriorActivityLevel defaultLevel = PriorActivityLevel.moderate;
}

enum ExtraCardioHoursOption {
  h0,
  h1,
  h2,
  h3,
  h5,
  h7Plus,
}

class ExtraCardioHoursCatalog {
  const ExtraCardioHoursCatalog._();

  static const ExtraCardioHoursOption defaultOption = ExtraCardioHoursOption.h0;

  static const List<ExtraCardioHoursOption> supportedOptions = [
    ExtraCardioHoursOption.h0,
    ExtraCardioHoursOption.h1,
    ExtraCardioHoursOption.h2,
    ExtraCardioHoursOption.h3,
    ExtraCardioHoursOption.h5,
    ExtraCardioHoursOption.h7Plus,
  ];

  static double hoursPerWeek(ExtraCardioHoursOption option) {
    switch (option) {
      case ExtraCardioHoursOption.h0:
        return 0;
      case ExtraCardioHoursOption.h1:
        return 1;
      case ExtraCardioHoursOption.h2:
        return 2;
      case ExtraCardioHoursOption.h3:
        return 3;
      case ExtraCardioHoursOption.h5:
        return 5;
      case ExtraCardioHoursOption.h7Plus:
        return 7;
    }
  }
}

class WeeklyTargetRateOption {
  final BodyweightGoal goal;
  final double kgPerWeek;
  final bool isDefault;

  const WeeklyTargetRateOption({
    required this.goal,
    required this.kgPerWeek,
    this.isDefault = false,
  });
}

class WeeklyTargetRateCatalog {
  const WeeklyTargetRateCatalog._();

  static const List<WeeklyTargetRateOption> supportedOptions = [
    WeeklyTargetRateOption(
      goal: BodyweightGoal.loseWeight,
      kgPerWeek: -0.25,
    ),
    WeeklyTargetRateOption(
      goal: BodyweightGoal.loseWeight,
      kgPerWeek: -0.50,
      isDefault: true,
    ),
    WeeklyTargetRateOption(
      goal: BodyweightGoal.loseWeight,
      kgPerWeek: -0.75,
    ),
    WeeklyTargetRateOption(
      goal: BodyweightGoal.loseWeight,
      kgPerWeek: -1.00,
    ),
    WeeklyTargetRateOption(
      goal: BodyweightGoal.maintainWeight,
      kgPerWeek: 0,
      isDefault: true,
    ),
    WeeklyTargetRateOption(
      goal: BodyweightGoal.gainWeight,
      kgPerWeek: 0.10,
    ),
    WeeklyTargetRateOption(
      goal: BodyweightGoal.gainWeight,
      kgPerWeek: 0.25,
      isDefault: true,
    ),
    WeeklyTargetRateOption(
      goal: BodyweightGoal.gainWeight,
      kgPerWeek: 0.50,
    ),
  ];

  static List<WeeklyTargetRateOption> optionsForGoal(BodyweightGoal goal) {
    return supportedOptions
        .where((option) => option.goal == goal)
        .toList(growable: false);
  }

  static WeeklyTargetRateOption defaultForGoal(BodyweightGoal goal) {
    return optionsForGoal(goal).firstWhere((option) => option.isDefault);
  }

  static bool isSupported({
    required BodyweightGoal goal,
    required double kgPerWeek,
  }) {
    return supportedOptions.any(
      (option) => option.goal == goal && option.kgPerWeek == kgPerWeek,
    );
  }

  static double coerceTargetRate({
    required BodyweightGoal goal,
    required double kgPerWeek,
  }) {
    if (isSupported(goal: goal, kgPerWeek: kgPerWeek)) {
      return kgPerWeek;
    }
    return defaultForGoal(goal).kgPerWeek;
  }
}
