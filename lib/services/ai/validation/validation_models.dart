part of '../../ai_meal_validation.dart';

const int maxRepairPasses = 3;

enum AiValidationMode { capture }

enum AiValidationSeverity { info, warning, error }

enum AiMatchQuality { exact, strong, partial, weak, unmatched }

typedef AiFoodMatchLoader = Future<List<FoodItem>> Function(
  AiMealCandidateItem item,
);

typedef AiCandidateRepairer = Future<AiMealCandidate> Function(
  AiMealCandidate candidate,
  AiValidationResult validation,
  int repairAttempt,
);

class AiMealCandidate {
  final String? mealName;
  final String? description;
  final List<AiMealCandidateItem> items;
  final AiMealContext? context;

  const AiMealCandidate({
    this.mealName,
    this.description,
    required this.items,
    this.context,
  });

  AiMealCandidate copyWith({
    String? mealName,
    String? description,
    List<AiMealCandidateItem>? items,
    AiMealContext? context,
  }) {
    return AiMealCandidate(
      mealName: mealName ?? this.mealName,
      description: description ?? this.description,
      items: items ?? this.items,
      context: context ?? this.context,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (mealName != null) 'meal_name': mealName,
      if (description != null) 'description': description,
      'items': items.map((item) => item.toJson()).toList(growable: false),
      if (context != null) 'mealContext': context!.toJson(),
    };
  }
}

class AiMealCandidateItem {
  final String name;
  final int grams;
  final double? confidence;
  final String? matchedBarcode;
  final String? stateHint;

  const AiMealCandidateItem({
    required this.name,
    required this.grams,
    this.confidence,
    this.matchedBarcode,
    this.stateHint,
  });

  AiMealCandidateItem copyWith({
    String? name,
    int? grams,
    double? confidence,
    String? matchedBarcode,
    String? stateHint,
  }) {
    return AiMealCandidateItem(
      name: name ?? this.name,
      grams: grams ?? this.grams,
      confidence: confidence ?? this.confidence,
      matchedBarcode: matchedBarcode ?? this.matchedBarcode,
      stateHint: stateHint ?? this.stateHint,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'grams': grams,
      if (confidence != null) 'confidence': confidence,
      if (matchedBarcode != null) 'matchedBarcode': matchedBarcode,
      if (stateHint != null) 'stateHint': stateHint,
    };
  }
}

class AiNutritionTotals {
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  const AiNutritionTotals({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  static const zero = AiNutritionTotals(
    kcal: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
  );

  factory AiNutritionTotals.fromFood(FoodItem food, int grams) {
    final factor = grams / 100.0;
    return AiNutritionTotals(
      kcal: food.calories * factor,
      protein: food.protein * factor,
      carbs: food.carbs * factor,
      fat: food.fat * factor,
    );
  }

  AiNutritionTotals operator +(AiNutritionTotals other) {
    return AiNutritionTotals(
      kcal: kcal + other.kcal,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
    );
  }

  int get kcalRounded => kcal.round();
  int get proteinRounded => protein.round();
  int get carbsRounded => carbs.round();
  int get fatRounded => fat.round();

  Map<String, int> toRoundedMap() {
    return {
      'kcal': kcalRounded,
      'protein': proteinRounded,
      'carbs': carbsRounded,
      'fat': fatRounded,
    };
  }
}

class AiMacroTargetContext {
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  const AiMacroTargetContext({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory AiMacroTargetContext.fromMap(Map<String, int> map) {
    return AiMacroTargetContext(
      kcal: map['kcal'] ?? 0,
      protein: map['protein'] ?? 0,
      carbs: map['carbs'] ?? 0,
      fat: map['fat'] ?? 0,
    );
  }

  Map<String, int> toMap() {
    return {
      'kcal': kcal,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  bool get isEffectivelyEmpty =>
      kcal <= 0 && protein <= 0 && carbs <= 0 && fat <= 0;
}

class AiTargetFitResult {
  final double kcalDelta;
  final double proteinDelta;
  final double carbsDelta;
  final double fatDelta;
  final int kcalTolerance;
  final int proteinTolerance;
  final int carbsTolerance;
  final int fatTolerance;
  final bool kcalWithinTolerance;
  final bool proteinWithinTolerance;
  final bool carbsWithinTolerance;
  final bool fatWithinTolerance;

  const AiTargetFitResult({
    required this.kcalDelta,
    required this.proteinDelta,
    required this.carbsDelta,
    required this.fatDelta,
    required this.kcalTolerance,
    required this.proteinTolerance,
    required this.carbsTolerance,
    required this.fatTolerance,
    required this.kcalWithinTolerance,
    required this.proteinWithinTolerance,
    required this.carbsWithinTolerance,
    required this.fatWithinTolerance,
  });

  bool get overallFit =>
      kcalWithinTolerance &&
      proteinWithinTolerance &&
      carbsWithinTolerance &&
      fatWithinTolerance;
}

class AiMatchResult {
  final String query;
  final FoodItem? bestMatch;
  final List<FoodItem> alternatives;
  final AiMatchQuality quality;
  final bool isAmbiguous;
  final double score;

  const AiMatchResult({
    required this.query,
    required this.bestMatch,
    required this.alternatives,
    required this.quality,
    required this.isAmbiguous,
    required this.score,
  });

  bool get hasMatch => bestMatch != null;
}

class AiValidationIssue {
  final AiValidationSeverity severity;
  final String code;
  final String message;
  final int? itemIndex;
  final Map<String, Object?> parameters;

  const AiValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.itemIndex,
    this.parameters = const {},
  });
}

class AiValidatedMealItem {
  final AiMealCandidateItem candidate;
  final AiMatchResult match;
  final AiNutritionTotals nutrition;
  final List<AiValidationIssue> issues;

  const AiValidatedMealItem({
    required this.candidate,
    required this.match,
    required this.nutrition,
    required this.issues,
  });

  bool get isMatched => match.bestMatch != null;
  bool get hasError =>
      issues.any((issue) => issue.severity == AiValidationSeverity.error);

  /// Returns the top-N database alternatives as repair candidates.
  /// Used during Phase D to inject real DB entities into the repair prompt.
  List<AiRepairCandidate> getRepairCandidates({int limit = 5}) {
    return match.alternatives
        .take(limit)
        .map(AiRepairCandidate.fromFoodItem)
        .toList(growable: false);
  }
}

class AiValidationResult {
  final AiMealCandidate candidate;
  final AiValidationMode mode;
  final List<AiValidatedMealItem> items;
  final AiNutritionTotals totals;
  final AiTargetFitResult? macroFit;
  final List<AiValidationIssue> issues;
  final int score;
  final bool passed;
  final int repairPassesUsed;
  final bool repairLimitReached;

  const AiValidationResult({
    required this.candidate,
    required this.mode,
    required this.items,
    required this.totals,
    required this.macroFit,
    required this.issues,
    required this.score,
    required this.passed,
    this.repairPassesUsed = 0,
    this.repairLimitReached = false,
  });

  List<AiValidationIssue> get allIssues {
    return [
      ...issues,
      for (final item in items) ...item.issues,
    ];
  }

  List<AiValidationIssue> get errors => allIssues
      .where((issue) => issue.severity == AiValidationSeverity.error)
      .toList(growable: false);

  List<AiValidationIssue> get warnings => allIssues
      .where((issue) => issue.severity == AiValidationSeverity.warning)
      .toList(growable: false);

  int get unmatchedItemCount =>
      items.where((item) => item.match.bestMatch == null).length;

  AiValidationResult copyWithRepairMetadata({
    required int repairPassesUsed,
    required bool repairLimitReached,
  }) {
    return AiValidationResult(
      candidate: candidate,
      mode: mode,
      items: items,
      totals: totals,
      macroFit: macroFit,
      issues: issues,
      score: score,
      passed: passed,
      repairPassesUsed: repairPassesUsed,
      repairLimitReached: repairLimitReached,
    );
  }

  String toRepairFeedback() {
    final buffer = StringBuffer()
      ..writeln('Validation score: $score/100')
      ..writeln('Passed: $passed')
      ..writeln(
        'Local nutrition totals: ${totals.kcalRounded} kcal, '
        '${totals.proteinRounded}g protein, '
        '${totals.carbsRounded}g carbs, ${totals.fatRounded}g fat.',
      );

    if (macroFit != null) {
      final fit = macroFit!;
      buffer
        ..writeln('Target-fit deltas:')
        ..writeln(
          '- kcal: ${fit.kcalDelta.round()} '
          '(tolerance ${fit.kcalTolerance})',
        )
        ..writeln(
          '- protein: ${fit.proteinDelta.round()}g '
          '(tolerance ${fit.proteinTolerance}g)',
        )
        ..writeln(
          '- carbs: ${fit.carbsDelta.round()}g '
          '(tolerance ${fit.carbsTolerance}g)',
        )
        ..writeln(
          '- fat: ${fit.fatDelta.round()}g '
          '(tolerance ${fit.fatTolerance}g)',
        );
    }

    final actionable = allIssues
        .where((issue) => issue.severity != AiValidationSeverity.info)
        .toList(growable: false);
    if (actionable.isNotEmpty) {
      buffer.writeln('Validation issues to fix:');
      for (final issue in actionable) {
        final prefix = issue.itemIndex == null
            ? '- meal'
            : '- item ${issue.itemIndex! + 1}';
        buffer.writeln('$prefix [${issue.code}]: ${issue.message}');
      }
    }

    // Per-item candidate injection
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final actionableIssues = item.issues
          .where((issue) => issue.severity != AiValidationSeverity.info);
      if (actionableIssues.isEmpty) continue;

      final candidates = item.getRepairCandidates(limit: 5);
      if (candidates.isEmpty) continue;

      buffer
        ..writeln('')
        ..writeln('CANDIDATES for item ${i + 1} ("${item.candidate.name}"):')
        ..writeln('Choose the EXACT name from one of these real database entries:');
      for (final candidate in candidates) {
        buffer.writeln(candidate.toPromptLine());
      }
      buffer.writeln(
        'Pick the entry whose macro density best fits the meal context. '
        'Use the EXACT name string as your "name" value.',
      );
    }

    buffer.writeln(
      'Return the same JSON schema with corrected food names and gram amounts. '
      'Do not add nutrition values.',
    );
    return buffer.toString();
  }
}

class AiRepairOutcome {
  final AiValidationResult validation;
  final int repairPassesUsed;
  final bool repairLimitReached;

  const AiRepairOutcome({
    required this.validation,
    required this.repairPassesUsed,
    required this.repairLimitReached,
  });
}

class AiDiarySavePlan {
  final List<AiValidatedMealItem> matchedItems;
  final List<AiValidatedMealItem> unmatchedItems;

  const AiDiarySavePlan({
    required this.matchedItems,
    required this.unmatchedItems,
  });

  factory AiDiarySavePlan.fromValidation(AiValidationResult validation) {
    final matched = <AiValidatedMealItem>[];
    final unmatched = <AiValidatedMealItem>[];
    for (final item in validation.items) {
      if (item.match.bestMatch == null) {
        unmatched.add(item);
      } else {
        matched.add(item);
      }
    }
    return AiDiarySavePlan(
      matchedItems: matched,
      unmatchedItems: unmatched,
    );
  }

  bool get canSaveAny => matchedItems.isNotEmpty;
  bool get isPartial => matchedItems.isNotEmpty && unmatchedItems.isNotEmpty;
}

class _NormalizedCandidate {
  final AiMealCandidate candidate;
  final List<AiValidationIssue> issues;

  const _NormalizedCandidate({
    required this.candidate,
    required this.issues,
  });
}

class _ScoredFood {
  final FoodItem food;
  final double score;

  const _ScoredFood({
    required this.food,
    required this.score,
  });
}
