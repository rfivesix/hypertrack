class RecoveryDomainService {
  static const String stateRecovering = 'recovering';
  static const String stateReady = 'ready';
  static const String stateFresh = 'fresh';
  static const String stateUnknown = 'unknown';

  static const String overallMostlyRecovered = 'mostlyRecovered';
  static const String overallMixedRecovery = 'mixedRecovery';
  static const String overallSeveralRecovering = 'severalRecovering';
  static const String overallInsufficientData = 'insufficientData';

  const RecoveryDomainService._();

  static bool hasHighSessionFatigue({
    required double? avgRir,
    required double? avgRpe,
  }) {
    return (avgRir != null && avgRir == 0) || (avgRpe != null && avgRpe >= 9);
  }

  static int recoveringUpperHours({required bool highSessionFatigue}) {
    return 48 + (highSessionFatigue ? 24 : 0);
  }

  static int readyUpperHours({required bool highSessionFatigue}) {
    return 72 + (highSessionFatigue ? 24 : 0);
  }

  static String muscleState({
    required double hoursSinceLastSignificantLoad,
    required bool highSessionFatigue,
  }) {
    final recoveringUpper = recoveringUpperHours(
      highSessionFatigue: highSessionFatigue,
    );
    final readyUpper = readyUpperHours(highSessionFatigue: highSessionFatigue);

    if (hoursSinceLastSignificantLoad < recoveringUpper) {
      return stateRecovering;
    }
    if (hoursSinceLastSignificantLoad <= readyUpper) {
      return stateReady;
    }
    return stateFresh;
  }

  static String overallState({
    required int totalTrackedMuscles,
    required int recoveringCount,
  }) {
    if (totalTrackedMuscles == 0) {
      return overallInsufficientData;
    }
    if (recoveringCount >= 3 || recoveringCount / totalTrackedMuscles >= 0.4) {
      return overallSeveralRecovering;
    }
    if (recoveringCount == 0) {
      return overallMostlyRecovered;
    }
    return overallMixedRecovery;
  }

  static bool shouldHideMuscle(String name) {
    final normalized = name.trim().toLowerCase();
    return normalized == 'brachialis';
  }

  static double recoveryPressureScore(Map<String, dynamic> muscle) {
    final eqSets = (muscle['lastEquivalentSets'] as num?)?.toDouble() ?? 0.0;
    final hours =
        (muscle['hoursSinceLastSignificantLoad'] as num?)?.toDouble() ?? 999.0;
    final highFatigue = (muscle['highSessionFatigue'] as bool?) ?? false;

    final loadComponent = (eqSets * 24).clamp(0, 45);
    final freshnessPenalty = ((96 - hours).clamp(0, 96) / 96) * 45;
    final fatiguePenalty = highFatigue ? 10.0 : 0.0;
    return (loadComponent + freshnessPenalty + fatiguePenalty).clamp(
      0.0,
      100.0,
    );
  }
}
