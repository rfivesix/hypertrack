// lib/services/ai_meal_context.dart

/// Holistic nutritional anchor that the AI provides before decomposing
/// a meal into individual ingredients.
///
/// This context lets the validation engine cross-check per-item nutrition
/// against the expected whole-meal profile, catching mismatches that
/// per-item validation alone cannot detect (e.g. raw-vs-cooked issues).
class AiMealContext {
  final String dishType;

  /// Expected total kcal range: [low, high].
  final List<int> expectedKcalRange;

  /// Expected macro profile as percentage ranges.
  ///
  /// Keys: `proteinPercent`, `carbsPercent`, `fatPercent`.
  /// Values: `[low, high]` percentage of total kcal (via Atwater 4/4/9).
  final Map<String, List<int>> expectedMacroProfile;

  final String? cookingMethod;
  final String? contextNotes;

  const AiMealContext({
    required this.dishType,
    required this.expectedKcalRange,
    required this.expectedMacroProfile,
    this.cookingMethod,
    this.contextNotes,
  });

  factory AiMealContext.fromJson(Map<String, dynamic> json) {
    // Parse expectedKcalRange
    final rawKcalRange = json['expectedKcalRange'];
    final expectedKcalRange = <int>[];
    if (rawKcalRange is List) {
      for (final v in rawKcalRange) {
        expectedKcalRange.add((v is num) ? v.toInt() : 0);
      }
    }
    if (expectedKcalRange.length < 2) {
      // Fallback: if the AI omitted or malformed the range
      expectedKcalRange
        ..clear()
        ..addAll([0, 9999]);
    }

    // Parse expectedMacroProfile
    final rawProfile = json['expectedMacroProfile'];
    final expectedMacroProfile = <String, List<int>>{};
    if (rawProfile is Map<String, dynamic>) {
      for (final entry in rawProfile.entries) {
        if (entry.value is List) {
          expectedMacroProfile[entry.key] = (entry.value as List)
              .map((v) => (v is num) ? v.toInt() : 0)
              .toList(growable: false);
        }
      }
    }

    return AiMealContext(
      dishType: (json['dishType'] as String?) ?? 'Unknown',
      expectedKcalRange: expectedKcalRange,
      expectedMacroProfile: expectedMacroProfile,
      cookingMethod: json['cookingMethod'] as String?,
      contextNotes: json['contextNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dishType': dishType,
      'expectedKcalRange': expectedKcalRange,
      'expectedMacroProfile': expectedMacroProfile,
      if (cookingMethod != null) 'cookingMethod': cookingMethod,
      if (contextNotes != null) 'contextNotes': contextNotes,
    };
  }
}
