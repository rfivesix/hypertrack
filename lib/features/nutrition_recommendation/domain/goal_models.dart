enum BodyweightGoal {
  loseWeight,
  maintainWeight,
  gainWeight,
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

  static String goalLabel(BodyweightGoal goal) {
    switch (goal) {
      case BodyweightGoal.loseWeight:
        return 'Lose';
      case BodyweightGoal.maintainWeight:
        return 'Maintain';
      case BodyweightGoal.gainWeight:
        return 'Gain';
    }
  }

  static String rateLabel(double kgPerWeek) {
    final sign = kgPerWeek > 0 ? '+' : '';
    return '$sign${kgPerWeek.toStringAsFixed(2)} kg/week';
  }
}
