class RecoveryWindowProfile {
  final int recoveringUpperHours;
  final int readyUpperHours;

  const RecoveryWindowProfile({
    required this.recoveringUpperHours,
    required this.readyUpperHours,
  });
}

class RecoveryDomainService {
  static const String stateRecovering = 'recovering';
  static const String stateReady = 'ready';
  static const String stateFresh = 'fresh';
  static const String stateUnknown = 'unknown';

  static const String overallMostlyRecovered = 'mostlyRecovered';
  static const String overallMixedRecovery = 'mixedRecovery';
  static const String overallSeveralRecovering = 'severalRecovering';
  static const String overallInsufficientData = 'insufficientData';

  static const int recoveryLookbackDays = 14;
  static const double minimumSignificantEquivalentSets = 1.0;
  static const double highFatigueRirThreshold = 0.5;
  static const double highFatigueRpeThreshold = 8.5;
  static const int highFatigueExtensionHours = 24;

  static const RecoveryWindowProfile defaultRecoveryWindowProfile =
      RecoveryWindowProfile(recoveringUpperHours: 48, readyUpperHours: 72);

  static const Map<String, RecoveryWindowProfile> _recoveryProfiles = {
    'shoulder': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'shoulders': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'delt':
        RecoveryWindowProfile(recoveringUpperHours: 36, readyUpperHours: 60),
    'delts': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'front delt': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'front delts': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'side delt': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'side delts': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'lateral delt': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'lateral delts': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'rear delt': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'rear delts': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'anterior delts': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'posterior delts': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'biceps': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'triceps': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'forearms': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'calves': RecoveryWindowProfile(
      recoveringUpperHours: 36,
      readyUpperHours: 60,
    ),
    'chest': defaultRecoveryWindowProfile,
    'pecs': defaultRecoveryWindowProfile,
    'lats': defaultRecoveryWindowProfile,
    'latissimus': defaultRecoveryWindowProfile,
    'upper back': defaultRecoveryWindowProfile,
    'back': defaultRecoveryWindowProfile,
    'traps': defaultRecoveryWindowProfile,
    'abs': defaultRecoveryWindowProfile,
    'abdominals': defaultRecoveryWindowProfile,
    'core': defaultRecoveryWindowProfile,
    'obliques': defaultRecoveryWindowProfile,
    'quads': RecoveryWindowProfile(
      recoveringUpperHours: 60,
      readyUpperHours: 96,
    ),
    'quadriceps': RecoveryWindowProfile(
      recoveringUpperHours: 60,
      readyUpperHours: 96,
    ),
    'hamstrings': RecoveryWindowProfile(
      recoveringUpperHours: 60,
      readyUpperHours: 96,
    ),
    'glutes': RecoveryWindowProfile(
      recoveringUpperHours: 60,
      readyUpperHours: 96,
    ),
    'adductors': RecoveryWindowProfile(
      recoveringUpperHours: 60,
      readyUpperHours: 96,
    ),
    'lower back': RecoveryWindowProfile(
      recoveringUpperHours: 72,
      readyUpperHours: 120,
    ),
    'spinal erectors': RecoveryWindowProfile(
      recoveringUpperHours: 72,
      readyUpperHours: 120,
    ),
    'erectors': RecoveryWindowProfile(
      recoveringUpperHours: 72,
      readyUpperHours: 120,
    ),
    'erector spinae': RecoveryWindowProfile(
      recoveringUpperHours: 72,
      readyUpperHours: 120,
    ),
  };

  static const List<_PressureAnchor> _loadPressureAnchors = [
    _PressureAnchor(0.0, 0.0),
    _PressureAnchor(1.0, 10.0),
    _PressureAnchor(2.0, 18.0),
    _PressureAnchor(3.0, 26.0),
    _PressureAnchor(4.0, 34.0),
    _PressureAnchor(5.0, 41.0),
    _PressureAnchor(6.0, 47.0),
    _PressureAnchor(8.0, 55.0),
    _PressureAnchor(10.0, 60.0),
    _PressureAnchor(12.0, 65.0),
  ];

  const RecoveryDomainService._();

  static bool hasHighSessionFatigue({
    required double? avgRir,
    required double? avgRpe,
  }) {
    return (avgRir != null && avgRir <= highFatigueRirThreshold) ||
        (avgRpe != null && avgRpe >= highFatigueRpeThreshold);
  }

  static String normalizeMuscleName(String? name) {
    if (name == null) return '';
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[/\\]+'), ' ')
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static RecoveryWindowProfile recoveryWindowProfileFor(String? muscleGroup) {
    final normalized = normalizeMuscleName(muscleGroup);
    return _recoveryProfiles[normalized] ?? defaultRecoveryWindowProfile;
  }

  static int loadBasedExtensionHours(double lastEquivalentSets) {
    if (lastEquivalentSets < minimumSignificantEquivalentSets) {
      return 0;
    }
    if (lastEquivalentSets < 3.0) return 0;
    if (lastEquivalentSets < 5.0) return 6;
    if (lastEquivalentSets < 8.0) return 12;
    if (lastEquivalentSets < 11.0) return 24;
    return 36;
  }

  static int intensityBasedExtensionHours({
    required bool highSessionFatigue,
  }) {
    return highSessionFatigue ? highFatigueExtensionHours : 0;
  }

  static int recoveringUpperHours({
    required bool highSessionFatigue,
    String? muscleGroup,
    double lastEquivalentSets = minimumSignificantEquivalentSets,
  }) {
    final profile = recoveryWindowProfileFor(muscleGroup);
    return profile.recoveringUpperHours +
        loadBasedExtensionHours(lastEquivalentSets) +
        intensityBasedExtensionHours(highSessionFatigue: highSessionFatigue);
  }

  static int readyUpperHours({
    required bool highSessionFatigue,
    String? muscleGroup,
    double lastEquivalentSets = minimumSignificantEquivalentSets,
  }) {
    final profile = recoveryWindowProfileFor(muscleGroup);
    return profile.readyUpperHours +
        loadBasedExtensionHours(lastEquivalentSets) +
        intensityBasedExtensionHours(highSessionFatigue: highSessionFatigue);
  }

  static String muscleState({
    required double hoursSinceLastSignificantLoad,
    required bool highSessionFatigue,
    String? muscleGroup,
    double lastEquivalentSets = minimumSignificantEquivalentSets,
  }) {
    final recoveringUpper = recoveringUpperHours(
      highSessionFatigue: highSessionFatigue,
      muscleGroup: muscleGroup,
      lastEquivalentSets: lastEquivalentSets,
    );
    final readyUpper = readyUpperHours(
      highSessionFatigue: highSessionFatigue,
      muscleGroup: muscleGroup,
      lastEquivalentSets: lastEquivalentSets,
    );

    if (hoursSinceLastSignificantLoad <= recoveringUpper) {
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
    if (recoveringCount / totalTrackedMuscles >= 0.4) {
      return overallSeveralRecovering;
    }
    if (recoveringCount == 0) {
      return overallMostlyRecovered;
    }
    return overallMixedRecovery;
  }

  static bool shouldHideMuscle(String name) {
    final normalized = normalizeMuscleName(name);
    return normalized == 'brachialis';
  }

  static double recoveryPressureScore(Map<String, dynamic> muscle) {
    final eqSets = (muscle['lastEquivalentSets'] as num?)?.toDouble() ?? 0.0;
    final hours =
        (muscle['hoursSinceLastSignificantLoad'] as num?)?.toDouble() ?? 999.0;
    final highFatigue = (muscle['highSessionFatigue'] as bool?) ?? false;

    final loadComponent = _interpolateLoadPressure(eqSets);
    final recencyComponent = _recencyPressure(hours);
    final fatiguePenalty = highFatigue ? 10.0 : 0.0;
    return (loadComponent + recencyComponent + fatiguePenalty).clamp(
      0.0,
      100.0,
    );
  }

  static double _interpolateLoadPressure(double equivalentSets) {
    final sets = equivalentSets.isFinite ? equivalentSets : 0.0;
    if (sets <= _loadPressureAnchors.first.equivalentSets) {
      return _loadPressureAnchors.first.score;
    }

    for (var i = 1; i < _loadPressureAnchors.length; i++) {
      final left = _loadPressureAnchors[i - 1];
      final right = _loadPressureAnchors[i];
      if (sets <= right.equivalentSets) {
        final span = right.equivalentSets - left.equivalentSets;
        final progress = (sets - left.equivalentSets) / span;
        return left.score + (right.score - left.score) * progress;
      }
    }

    return _loadPressureAnchors.last.score;
  }

  static double _recencyPressure(double hoursSinceLastSignificantLoad) {
    final hours = hoursSinceLastSignificantLoad.isFinite
        ? hoursSinceLastSignificantLoad
        : 999.0;
    final remaining = (96.0 - hours).clamp(0.0, 96.0).toDouble();
    return (remaining / 96.0) * 25.0;
  }
}

class _PressureAnchor {
  final double equivalentSets;
  final double score;

  const _PressureAnchor(this.equivalentSets, this.score);
}
