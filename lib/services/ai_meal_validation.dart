import '../features/diary/data/sources/product_local_data_source.dart';
import '../features/diary/domain/models/food_item.dart';
import 'ai_meal_context.dart';
import 'ai_repair_candidate.dart';

part 'ai/validation/validation_models.dart';
part 'ai/validation/matching_logic.dart';
part 'ai/validation/rules_logic.dart';

class AiMealValidationEngine {
  final AiFoodMatchLoader _matchLoader;

  AiMealValidationEngine({
    AiFoodMatchLoader? matchLoader,
  }) : _matchLoader = matchLoader ?? defaultMatchLoader;

  static Future<List<FoodItem>> defaultMatchLoader(
    AiMealCandidateItem item,
  ) async {
    final helper = ProductLocalDataSource.instance;
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
        context: normalized.candidate.context,
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
