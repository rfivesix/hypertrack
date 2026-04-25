import '../data/product_database_helper.dart';
import '../models/food_item.dart';

const int maxRepairPasses = 3;

enum AiValidationMode { capture, recommendation }

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

  const AiMealCandidate({
    this.mealName,
    this.description,
    required this.items,
  });

  AiMealCandidate copyWith({
    String? mealName,
    String? description,
    List<AiMealCandidateItem>? items,
  }) {
    return AiMealCandidate(
      mealName: mealName ?? this.mealName,
      description: description ?? this.description,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (mealName != null) 'meal_name': mealName,
      if (description != null) 'description': description,
      'items': items.map((item) => item.toJson()).toList(growable: false),
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

class AiMealTargetPlanner {
  const AiMealTargetPlanner._();

  static AiMacroTargetContext computeMealTarget({
    required AiMacroTargetContext remaining,
    required AiMacroTargetContext dailyGoal,
    required String mealType,
  }) {
    int pct(num value, double ratio) => (value * ratio).round();

    AiMacroTargetContext planned;
    switch (mealType) {
      case 'mealtypeBreakfast':
        planned = AiMacroTargetContext(
          kcal: pct(dailyGoal.kcal, 1 / 3),
          protein: pct(dailyGoal.protein, 1 / 3),
          carbs: pct(dailyGoal.carbs, 1 / 3),
          fat: pct(dailyGoal.fat, 1 / 3),
        );
        break;
      case 'mealtypeLunch':
        planned = AiMacroTargetContext(
          kcal: remaining.kcal - pct(dailyGoal.kcal, 1 / 3),
          protein: remaining.protein - pct(dailyGoal.protein, 1 / 3),
          carbs: remaining.carbs - pct(dailyGoal.carbs, 1 / 3),
          fat: remaining.fat - pct(dailyGoal.fat, 1 / 3),
        );
        break;
      case 'mealtypeSnack':
        planned = AiMacroTargetContext(
          kcal: pct(dailyGoal.kcal, 0.1),
          protein: pct(dailyGoal.protein, 0.1),
          carbs: pct(dailyGoal.carbs, 0.1),
          fat: pct(dailyGoal.fat, 0.1),
        );
        break;
      case 'mealtypeDinner':
      default:
        planned = remaining;
        break;
    }

    final clamped = AiMacroTargetContext(
      kcal: _clampTarget(planned.kcal, remaining.kcal),
      protein: _clampTarget(planned.protein, remaining.protein),
      carbs: _clampTarget(planned.carbs, remaining.carbs),
      fat: _clampTarget(planned.fat, remaining.fat),
    );

    if (mealType == 'mealtypeLunch' &&
        clamped.kcal <= 0 &&
        remaining.kcal > 50) {
      return AiMacroTargetContext(
        kcal: _clampTarget((remaining.kcal * 0.5).round(), remaining.kcal),
        protein: _clampTarget(
          (remaining.protein * 0.5).round(),
          remaining.protein,
        ),
        carbs: _clampTarget((remaining.carbs * 0.5).round(), remaining.carbs),
        fat: _clampTarget((remaining.fat * 0.5).round(), remaining.fat),
      );
    }

    return clamped;
  }

  static int _clampTarget(int value, int remaining) {
    if (remaining <= 0) return 0;
    if (value <= 0) return 0;
    return value > remaining ? remaining : value;
  }
}

class AiMealValidationEngine {
  final AiFoodMatchLoader _matchLoader;

  AiMealValidationEngine({
    AiFoodMatchLoader? matchLoader,
  }) : _matchLoader = matchLoader ?? defaultMatchLoader;

  static Future<List<FoodItem>> defaultMatchLoader(
    AiMealCandidateItem item,
  ) async {
    final helper = ProductDatabaseHelper.instance;
    final matches = <FoodItem>[];
    final barcode = item.matchedBarcode?.trim();
    if (barcode != null && barcode.isNotEmpty) {
      final selected = await helper.getProductByBarcode(barcode);
      if (selected != null) {
        matches.add(selected);
      }
    }
    final fuzzy = await helper.fuzzyMatchForAi(item.name);
    for (final food in fuzzy) {
      if (!matches.any((existing) => existing.barcode == food.barcode)) {
        matches.add(food);
      }
    }
    return matches;
  }

  Future<AiValidationResult> validateMealCandidate({
    required AiMealCandidate candidate,
    required AiValidationMode mode,
    AiMacroTargetContext? targetContext,
  }) async {
    final normalized = _normalize(candidate);
    final mealIssues = <AiValidationIssue>[...normalized.issues];
    final validatedItems = <AiValidatedMealItem>[];

    for (var i = 0; i < normalized.candidate.items.length; i++) {
      final item = normalized.candidate.items[i];
      final matches = await _matchLoader(item);
      final match = _evaluateMatch(item, matches);
      final nutrition = match.bestMatch == null
          ? AiNutritionTotals.zero
          : AiNutritionTotals.fromFood(match.bestMatch!, item.grams);
      final issues = _validateItem(
        index: i,
        item: item,
        match: match,
        nutrition: nutrition,
        mode: mode,
      );
      validatedItems.add(
        AiValidatedMealItem(
          candidate: item,
          match: match,
          nutrition: nutrition,
          issues: issues,
        ),
      );
    }

    final totals = validatedItems.fold<AiNutritionTotals>(
      AiNutritionTotals.zero,
      (sum, item) => sum + item.nutrition,
    );
    final macroFit = targetContext == null
        ? null
        : evaluateTargetFit(totals: totals, target: targetContext);
    mealIssues.addAll(
      _validateMeal(
        items: validatedItems,
        totals: totals,
        targetContext: targetContext,
        macroFit: macroFit,
        mode: mode,
      ),
    );

    final allIssues = [
      ...mealIssues,
      for (final item in validatedItems) ...item.issues,
    ];
    final score = _computeValidationScore(allIssues, macroFit);
    final passed = _isGoodEnough(
      issues: allIssues,
      score: score,
      macroFit: macroFit,
      mode: mode,
    );

    return AiValidationResult(
      candidate: normalized.candidate,
      mode: mode,
      items: validatedItems,
      totals: totals,
      macroFit: macroFit,
      issues: mealIssues,
      score: score,
      passed: passed,
    );
  }

  AiTargetFitResult evaluateTargetFit({
    required AiNutritionTotals totals,
    required AiMacroTargetContext target,
  }) {
    final kcalTolerance = kcalToleranceFor(target.kcal);
    final proteinTolerance = macroToleranceFor(target.protein);
    final carbsTolerance = macroToleranceFor(target.carbs);
    final fatTolerance = fatToleranceFor(target.fat);

    final kcalDelta = totals.kcal - target.kcal;
    final proteinDelta = totals.protein - target.protein;
    final carbsDelta = totals.carbs - target.carbs;
    final fatDelta = totals.fat - target.fat;

    return AiTargetFitResult(
      kcalDelta: kcalDelta,
      proteinDelta: proteinDelta,
      carbsDelta: carbsDelta,
      fatDelta: fatDelta,
      kcalTolerance: kcalTolerance,
      proteinTolerance: proteinTolerance,
      carbsTolerance: carbsTolerance,
      fatTolerance: fatTolerance,
      kcalWithinTolerance: kcalDelta.abs() <= kcalTolerance,
      proteinWithinTolerance: proteinDelta.abs() <= proteinTolerance,
      carbsWithinTolerance: carbsDelta.abs() <= carbsTolerance,
      fatWithinTolerance: fatDelta.abs() <= fatTolerance,
    );
  }

  static int kcalToleranceFor(int targetKcal) {
    if (targetKcal <= 0) return 80;
    return _maxInt(80, (targetKcal * 0.2).round());
  }

  static int macroToleranceFor(int targetGrams) {
    if (targetGrams <= 0) return 8;
    return _maxInt(10, (targetGrams * 0.25).round());
  }

  static int fatToleranceFor(int targetGrams) {
    if (targetGrams <= 0) return 6;
    return _maxInt(8, (targetGrams * 0.30).round());
  }

  _NormalizedCandidate _normalize(AiMealCandidate candidate) {
    final issues = <AiValidationIssue>[];
    final byKey = <String, AiMealCandidateItem>{};
    final duplicateNames = <String>{};

    for (var rawIndex = 0; rawIndex < candidate.items.length; rawIndex++) {
      final raw = candidate.items[rawIndex];
      final name = raw.name.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (name.isEmpty) {
        issues.add(
          const AiValidationIssue(
            severity: AiValidationSeverity.error,
            code: 'empty_item_name',
            message: 'An item has no food name.',
          ),
        );
      }
      final normalized = raw.copyWith(
        name: name.isEmpty ? 'Unknown food' : name,
        confidence: raw.confidence?.clamp(0.0, 1.0).toDouble(),
      );
      final baseKey =
          '${_normalizeText(normalized.name)}|${normalized.matchedBarcode ?? ''}';
      final key = normalized.grams > 0 ? baseKey : '$baseKey|$rawIndex';
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = normalized;
      } else {
        duplicateNames.add(normalized.name);
        byKey[key] = existing.copyWith(
          grams: existing.grams + normalized.grams,
          confidence: _maxDouble(
            existing.confidence ?? 0,
            normalized.confidence ?? 0,
          ),
        );
      }
    }

    for (final name in duplicateNames) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.info,
          code: 'duplicate_item_merged',
          message: 'Duplicate "$name" entries were merged before validation.',
          parameters: {'name': name},
        ),
      );
    }

    return _NormalizedCandidate(
      candidate: candidate.copyWith(
        mealName: candidate.mealName?.trim(),
        description: candidate.description?.trim(),
        items: byKey.values.toList(growable: false),
      ),
      issues: issues,
    );
  }

  AiMatchResult _evaluateMatch(
    AiMealCandidateItem item,
    List<FoodItem> matches,
  ) {
    final query = item.name.trim();
    if (matches.isEmpty) {
      return AiMatchResult(
        query: query,
        bestMatch: null,
        alternatives: const [],
        quality: AiMatchQuality.unmatched,
        isAmbiguous: false,
        score: 0,
      );
    }

    final selectedBarcode = item.matchedBarcode?.trim();
    if (selectedBarcode != null && selectedBarcode.isNotEmpty) {
      final selectedMatches = matches
          .where((food) => food.barcode == selectedBarcode)
          .toList(growable: false);
      if (selectedMatches.isNotEmpty) {
        return AiMatchResult(
          query: query,
          bestMatch: selectedMatches.first,
          alternatives: matches,
          quality: AiMatchQuality.exact,
          isAmbiguous: false,
          score: 1.0,
        );
      }
    }

    final scored = matches
        .map((food) => _ScoredFood(food: food, score: _matchScore(query, food)))
        .toList(growable: false)
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return _sourcePriority(a.food.source).compareTo(
          _sourcePriority(b.food.source),
        );
      });

    final best = scored.first;
    final alternatives = scored.map((e) => e.food).toList(growable: false);
    final secondScore = scored.length > 1 ? scored[1].score : 0.0;
    final isAmbiguous = scored.length > 1 &&
        best.score < 0.95 &&
        (best.score - secondScore).abs() <= 0.08;

    final quality = switch (best.score) {
      >= 0.95 => AiMatchQuality.exact,
      >= 0.78 => AiMatchQuality.strong,
      >= 0.55 => AiMatchQuality.partial,
      >= 0.35 => AiMatchQuality.weak,
      _ => AiMatchQuality.weak,
    };

    return AiMatchResult(
      query: query,
      bestMatch: best.food,
      alternatives: alternatives,
      quality: quality,
      isAmbiguous: isAmbiguous,
      score: best.score,
    );
  }

  List<AiValidationIssue> _validateItem({
    required int index,
    required AiMealCandidateItem item,
    required AiMatchResult match,
    required AiNutritionTotals nutrition,
    required AiValidationMode mode,
  }) {
    final issues = <AiValidationIssue>[];

    if (item.grams <= 0) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.error,
          code: 'invalid_quantity',
          message: 'Quantity must be greater than 0g.',
          itemIndex: index,
        ),
      );
    } else if (item.grams <= 5) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'tiny_quantity',
          message: 'Quantity is very small; review the gram amount.',
          itemIndex: index,
        ),
      );
    } else if (item.grams > 3000) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.error,
          code: 'extreme_quantity',
          message: 'Quantity is implausibly high for one meal item.',
          itemIndex: index,
        ),
      );
    } else if (item.grams > 1200) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'large_quantity',
          message: 'Quantity is unusually large; review the gram amount.',
          itemIndex: index,
        ),
      );
    }

    if ((item.confidence ?? 1.0) < 0.5) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'low_ai_confidence',
          message: 'AI confidence is low for this item.',
          itemIndex: index,
        ),
      );
    }

    if (match.bestMatch == null) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.error,
          code: 'unmatched_item',
          message: 'No local database match was found.',
          itemIndex: index,
        ),
      );
      return issues;
    }

    if (match.quality == AiMatchQuality.weak) {
      issues.add(
        AiValidationIssue(
          severity: mode == AiValidationMode.recommendation
              ? AiValidationSeverity.error
              : AiValidationSeverity.warning,
          code: 'weak_db_match',
          message: 'The local database match is weak.',
          itemIndex: index,
        ),
      );
    } else if (match.quality == AiMatchQuality.partial) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.info,
          code: 'partial_db_match',
          message: 'The local database match is partial.',
          itemIndex: index,
        ),
      );
    }

    if (match.isAmbiguous) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'ambiguous_db_match',
          message: 'Several local database matches look similarly plausible.',
          itemIndex: index,
        ),
      );
    }

    if (_hasStateMismatch(item.name, match.bestMatch!.name)) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'state_mismatch',
          message: 'The AI item state may not match the database entry.',
          itemIndex: index,
        ),
      );
    }

    final food = match.bestMatch!;
    if (food.calories <= 0 &&
        food.protein <= 0 &&
        food.carbs <= 0 &&
        food.fat <= 0) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'zero_nutrition_match',
          message: 'The matched database entry has no usable nutrition data.',
          itemIndex: index,
        ),
      );
    }

    if (food.calories > 950) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'implausible_food_density',
          message: 'Matched food has unusually high kcal per 100g.',
          itemIndex: index,
        ),
      );
    }

    final macroEnergy = (food.protein * 4) + (food.carbs * 4) + (food.fat * 9);
    if (food.calories > 0 && macroEnergy > food.calories + 180) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'macro_energy_mismatch',
          message: 'Matched food macros do not align well with kcal.',
          itemIndex: index,
        ),
      );
    }

    if (nutrition.kcal > 2500 ||
        nutrition.protein > 250 ||
        nutrition.carbs > 500 ||
        nutrition.fat > 220) {
      issues.add(
        AiValidationIssue(
          severity: mode == AiValidationMode.recommendation
              ? AiValidationSeverity.error
              : AiValidationSeverity.warning,
          code: 'implausible_item_nutrition',
          message: 'Nutrition for this quantity is unusually high.',
          itemIndex: index,
        ),
      );
    }

    return issues;
  }

  List<AiValidationIssue> _validateMeal({
    required List<AiValidatedMealItem> items,
    required AiNutritionTotals totals,
    required AiMacroTargetContext? targetContext,
    required AiTargetFitResult? macroFit,
    required AiValidationMode mode,
  }) {
    final issues = <AiValidationIssue>[];

    if (items.isEmpty) {
      issues.add(
        const AiValidationIssue(
          severity: AiValidationSeverity.error,
          code: 'empty_meal',
          message: 'The AI returned no meal items.',
        ),
      );
      return issues;
    }

    final unmatched = items.where((item) => !item.isMatched).length;
    if (unmatched == items.length) {
      issues.add(
        const AiValidationIssue(
          severity: AiValidationSeverity.error,
          code: 'all_items_unmatched',
          message: 'No item could be matched to the local food database.',
        ),
      );
    } else if (unmatched > 0) {
      issues.add(
        AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'partial_unmatched_items',
          message: '$unmatched item(s) cannot be saved until matched.',
          parameters: {'count': unmatched},
        ),
      );
    }

    if (totals.kcal <= 0 && unmatched < items.length) {
      issues.add(
        const AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'zero_total_kcal',
          message: 'Matched items produce 0 kcal.',
        ),
      );
    }

    if (mode == AiValidationMode.capture) {
      if (totals.kcal > 5000) {
        issues.add(
          const AiValidationIssue(
            severity: AiValidationSeverity.error,
            code: 'capture_total_kcal_extreme',
            message: 'Total kcal is implausibly high for one captured meal.',
          ),
        );
      } else if (totals.kcal > 3500) {
        issues.add(
          const AiValidationIssue(
            severity: AiValidationSeverity.warning,
            code: 'capture_total_kcal_high',
            message: 'Total kcal is unusually high; review portions.',
          ),
        );
      }
    }

    if (totals.protein > 350 || totals.carbs > 700 || totals.fat > 300) {
      issues.add(
        const AiValidationIssue(
          severity: AiValidationSeverity.error,
          code: 'macro_total_extreme',
          message: 'Total macros are implausibly high.',
        ),
      );
    } else if (totals.protein > 250 || totals.carbs > 550 || totals.fat > 220) {
      issues.add(
        const AiValidationIssue(
          severity: AiValidationSeverity.warning,
          code: 'macro_total_high',
          message: 'Total macros are unusually high; review portions.',
        ),
      );
    }

    if (mode == AiValidationMode.recommendation && macroFit != null) {
      if (!macroFit.kcalWithinTolerance) {
        issues.add(
          AiValidationIssue(
            severity: AiValidationSeverity.error,
            code: 'target_kcal_mismatch',
            message:
                'Calories miss the target by ${macroFit.kcalDelta.round()} kcal.',
            parameters: {'delta': macroFit.kcalDelta.round()},
          ),
        );
      }
      if (!macroFit.proteinWithinTolerance) {
        issues.add(
          AiValidationIssue(
            severity: AiValidationSeverity.error,
            code: 'target_protein_mismatch',
            message:
                'Protein misses the target by ${macroFit.proteinDelta.round()}g.',
            parameters: {'delta': macroFit.proteinDelta.round()},
          ),
        );
      }
      if (!macroFit.carbsWithinTolerance) {
        issues.add(
          AiValidationIssue(
            severity: AiValidationSeverity.error,
            code: 'target_carbs_mismatch',
            message:
                'Carbs miss the target by ${macroFit.carbsDelta.round()}g.',
            parameters: {'delta': macroFit.carbsDelta.round()},
          ),
        );
      }
      if (!macroFit.fatWithinTolerance) {
        issues.add(
          AiValidationIssue(
            severity: AiValidationSeverity.error,
            code: 'target_fat_mismatch',
            message: 'Fat misses the target by ${macroFit.fatDelta.round()}g.',
            parameters: {'delta': macroFit.fatDelta.round()},
          ),
        );
      }
    }

    return issues;
  }

  int _computeValidationScore(
    List<AiValidationIssue> issues,
    AiTargetFitResult? macroFit,
  ) {
    var score = 100;
    for (final issue in issues) {
      score -= switch (issue.severity) {
        AiValidationSeverity.info => 2,
        AiValidationSeverity.warning => 8,
        AiValidationSeverity.error => 24,
      };
    }
    if (macroFit != null && !macroFit.overallFit) {
      score -= 12;
    }
    return score.clamp(0, 100).toInt();
  }

  bool _isGoodEnough({
    required List<AiValidationIssue> issues,
    required int score,
    required AiTargetFitResult? macroFit,
    required AiValidationMode mode,
  }) {
    if (issues.any((issue) => issue.severity == AiValidationSeverity.error)) {
      return false;
    }
    if (mode == AiValidationMode.recommendation &&
        macroFit != null &&
        !macroFit.overallFit) {
      return false;
    }
    return score >= 70;
  }

  double _matchScore(String query, FoodItem food) {
    final normalizedQuery = _normalizeText(query);
    if (normalizedQuery.isEmpty) return 0;
    final names = {
      food.name,
      food.nameDe,
      food.nameEn,
    }.where((name) => name.trim().isNotEmpty).map(_normalizeText).toSet();

    if (names.any((name) => name == normalizedQuery)) return 1.0;
    if (names.any((name) => name.startsWith(normalizedQuery))) return 0.86;
    if (names.any((name) => normalizedQuery.startsWith(name))) return 0.78;

    final queryTokens = normalizedQuery.split(' ').where((t) => t.length > 1);
    var best = 0.0;
    for (final name in names) {
      if (name.contains(normalizedQuery)) {
        best = _maxDouble(best, 0.70);
      }
      final nameTokens = name.split(' ').where((t) => t.length > 1).toSet();
      if (nameTokens.isEmpty) continue;
      final overlap = queryTokens.where(nameTokens.contains).length;
      if (overlap > 0) {
        best = _maxDouble(best, overlap / queryTokens.length * 0.65);
      }
    }
    return best;
  }

  bool _hasStateMismatch(String aiName, String dbName) {
    final ai = _normalizeText(aiName);
    final db = _normalizeText(dbName);
    const stateGroups = [
      ['raw', 'roh'],
      ['cooked', 'boiled', 'gekocht'],
      ['fried', 'gebraten'],
      ['dry', 'dried', 'trocken', 'getrocknet'],
    ];

    String? stateFor(String text) {
      for (final group in stateGroups) {
        if (group.any(text.contains)) return group.first;
      }
      return null;
    }

    final aiState = stateFor(ai);
    final dbState = stateFor(db);
    return aiState != null && dbState != null && aiState != dbState;
  }

  int _sourcePriority(FoodItemSource source) {
    return switch (source) {
      FoodItemSource.base => 0,
      FoodItemSource.user => 1,
      FoodItemSource.off => 2,
    };
  }

  static String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9äöüß ]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static int _maxInt(int a, int b) => a > b ? a : b;
  static double _maxDouble(double a, double b) => a > b ? a : b;
}

class AiRepairOrchestrator {
  final AiMealValidationEngine validationEngine;

  const AiRepairOrchestrator({
    required this.validationEngine,
  });

  Future<AiRepairOutcome> run({
    required AiMealCandidate initialCandidate,
    required AiValidationMode mode,
    required AiCandidateRepairer repairer,
    AiMacroTargetContext? targetContext,
    int maxPasses = maxRepairPasses,
  }) async {
    var candidate = initialCandidate;
    var validation = await validationEngine.validateMealCandidate(
      candidate: candidate,
      mode: mode,
      targetContext: targetContext,
    );
    var repairPasses = 0;

    while (!validation.passed && repairPasses < maxPasses) {
      repairPasses += 1;
      candidate = await repairer(candidate, validation, repairPasses);
      validation = await validationEngine.validateMealCandidate(
        candidate: candidate,
        mode: mode,
        targetContext: targetContext,
      );
    }

    final limitReached = !validation.passed && repairPasses >= maxPasses;
    return AiRepairOutcome(
      validation: validation.copyWithRepairMetadata(
        repairPassesUsed: repairPasses,
        repairLimitReached: limitReached,
      ),
      repairPassesUsed: repairPasses,
      repairLimitReached: limitReached,
    );
  }
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
