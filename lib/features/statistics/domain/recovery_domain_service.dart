class RecoveryWindowProfile {
  final int recoveringUpperHours;
  final int readyUpperHours;

  const RecoveryWindowProfile({
    required this.recoveringUpperHours,
    required this.readyUpperHours,
  });
}

enum RecoveryPressureLevel { low, moderate, high, veryHigh }

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

  /// Maps normalised minor muscle names to one of the 10 canonical major
  /// muscle groups. A null value means the muscle should be discarded (e.g.
  /// abs, core, forearms are not major strength-training groups).
  static const Map<String, String?> _majorGroupMap = {
    // Chest
    'chest': 'chest',
    'pecs': 'chest',
    'upper chest': 'chest',
    'lower chest': 'chest',
    'pectorals': 'chest',
    // Back (including traps)
    'back': 'back',
    'lats': 'back',
    'latissimus': 'back',
    'upper back': 'back',
    'mid back': 'back',
    'middle back': 'back',
    'rhomboids': 'back',
    'serratus': 'back',
    'traps': 'back',
    'trapezius': 'back',
    // Shoulders
    'shoulder': 'shoulders',
    'shoulders': 'shoulders',
    'delt': 'shoulders',
    'delts': 'shoulders',
    'front delt': 'shoulders',
    'front delts': 'shoulders',
    'rear delt': 'shoulders',
    'rear delts': 'shoulders',
    'side delt': 'shoulders',
    'side delts': 'shoulders',
    'lateral delt': 'shoulders',
    'lateral delts': 'shoulders',
    'anterior delts': 'shoulders',
    'posterior delts': 'shoulders',
    // Biceps
    'biceps': 'biceps',
    'brachialis': 'biceps',
    // Triceps
    'triceps': 'triceps',
    // Quads
    'quads': 'quads',
    'quadriceps': 'quads',
    // Hamstrings
    'hamstrings': 'hamstrings',
    // Glutes (includes hip muscles)
    'glutes': 'glutes',
    'gluteus': 'glutes',
    'hip flexors': 'glutes',
    // Adductors
    'adductor': 'adductors',
    'adductors': 'adductors',
    'hip adductor': 'adductors',
    'hip adductors': 'adductors',
    // Calves
    'calves': 'calves',
    'calf': 'calves',
    'gastrocnemius': 'calves',
    'soleus': 'calves',
    'tibialis': 'calves',
    'tibialis anterior': 'calves',
    'tibialis_anterior': 'calves',
    // Lower Back
    'lower back': 'lower back',
    'spinal erectors': 'lower back',
    'erectors': 'lower back',
    'erector spinae': 'lower back',
    // Core / Abs (includes muscles that have no wger name_en)
    'abs': 'abs',
    'abdominals': 'abs',
    'core': 'abs',
    'obliques': 'abs',
    'obliquus externus abdominis': null, // discard — not a primary strength group
    // Back (additional wger fallback names)
    'serratus anterior': 'back',
    // Forearms
    'forearm': 'forearms',
    'forearms': 'forearms',
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

  /// Returns the canonical major muscle group key for [rawName], or null if
  /// the muscle does not map to any tracked major group and should be
  /// discarded (e.g. abs, core, obliques, forearms).
  ///
  /// The input is normalised (trimmed, lowercased, whitespace-collapsed) before
  /// the map lookup. Unknown muscles not present in [_majorGroupMap] are treated
  /// as null (discard).
  static String? majorMuscleGroupFor(String rawName) {
    final normalized = normalizeMuscleName(rawName);
    if (normalized.isEmpty) return null;
    // containsKey distinguishes "key is present with null value" (discard)
    // from "key is absent" (also discard — unknown muscle).
    if (_majorGroupMap.containsKey(normalized)) {
      return _majorGroupMap[normalized]; // may be null (discard signal)
    }
    return null; // unknown muscle → discard
  }

  static double readinessScore({
    required double hoursSinceLastSignificantLoad,
    required double recoveringUpperHours,
    required double readyUpperHours,
  }) {
    final hours = hoursSinceLastSignificantLoad.isFinite
        ? hoursSinceLastSignificantLoad
        : 0.0;
    final recoveringUpper = recoveringUpperHours.isFinite
        ? recoveringUpperHours.clamp(0.0, double.infinity).toDouble()
        : 0.0;
    final readyUpper = readyUpperHours.isFinite
        ? readyUpperHours.clamp(recoveringUpper, double.infinity).toDouble()
        : recoveringUpper;

    if (hours <= 0) return 5.0;

    if (hours <= recoveringUpper) {
      final progress = recoveringUpper <= 0 ? 1.0 : hours / recoveringUpper;
      return _lerp(10.0, 60.0, progress);
    }

    if (hours <= readyUpper) {
      final span = readyUpper - recoveringUpper;
      final progress = span <= 0 ? 1.0 : (hours - recoveringUpper) / span;
      return _lerp(60.0, 85.0, progress);
    }

    final overtime = hours - readyUpper;
    final extraProgress = (overtime / 48.0).clamp(0.0, 1.0).toDouble();
    return _lerp(85.0, 100.0, extraProgress);
  }

  static double lastLoadPressureScore({
    required double lastEquivalentSets,
    required bool highSessionFatigue,
  }) {
    final loadComponent = _interpolateLoadPressure(lastEquivalentSets);
    final fatiguePenalty = highSessionFatigue ? 10.0 : 0.0;
    return (loadComponent + fatiguePenalty).clamp(0.0, 100.0).toDouble();
  }

  static RecoveryPressureLevel pressureLevelForScore(double score) {
    final normalized = score.isFinite ? score.clamp(0.0, 100.0) : 0.0;
    if (normalized < 25.0) return RecoveryPressureLevel.low;
    if (normalized < 50.0) return RecoveryPressureLevel.moderate;
    if (normalized < 75.0) return RecoveryPressureLevel.high;
    return RecoveryPressureLevel.veryHigh;
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

  static double _lerp(double start, double end, double progress) {
    final t = progress.clamp(0.0, 1.0).toDouble();
    return start + (end - start) * t;
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
