import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/models/food_item.dart';
import 'package:hypertrack/services/ai_meal_validation.dart';
import 'package:hypertrack/services/ai_service.dart';

FoodItem food(
  String name, {
  String? barcode,
  int kcal = 100,
  double protein = 10,
  double carbs = 10,
  double fat = 2,
}) {
  return FoodItem(
    barcode: barcode ?? name,
    name: name,
    nameDe: name,
    nameEn: name,
    calories: kcal,
    protein: protein,
    carbs: carbs,
    fat: fat,
    source: FoodItemSource.base,
  );
}

AiMealValidationEngine engineWith(Map<String, List<FoodItem>> matches) {
  return AiMealValidationEngine(
    matchLoader: (item) async => matches[item.name.toLowerCase()] ?? const [],
  );
}

void main() {
  group('AiMealValidationEngine', () {
    test('computes local totals from matched database entries', () async {
      final engine = engineWith({
        'chicken breast': [
          food(
            'Chicken breast',
            kcal: 120,
            protein: 24,
            carbs: 0,
            fat: 2,
          ),
        ],
        'rice': [
          food(
            'Rice',
            kcal: 130,
            protein: 3,
            carbs: 28,
            fat: 0.3,
          ),
        ],
      });

      final result = await engine.validateMealCandidate(
        candidate: const AiMealCandidate(
          items: [
            AiMealCandidateItem(name: 'Chicken breast', grams: 200),
            AiMealCandidateItem(name: 'Rice', grams: 150),
          ],
        ),
        mode: AiValidationMode.capture,
      );

      expect(result.totals.kcalRounded, 435);
      expect(result.totals.proteinRounded, 53);
      expect(result.totals.carbsRounded, 42);
      expect(result.totals.fatRounded, 4);
      expect(result.passed, isTrue);
    });

    test('flags invalid and extreme quantities', () async {
      final engine = engineWith({
        'rice': [food('Rice')],
        'pasta': [food('Pasta')],
      });

      final result = await engine.validateMealCandidate(
        candidate: const AiMealCandidate(
          items: [
            AiMealCandidateItem(name: 'Rice', grams: 0),
            AiMealCandidateItem(name: 'Pasta', grams: 4000),
          ],
        ),
        mode: AiValidationMode.capture,
      );

      expect(
        result.allIssues.map((issue) => issue.code),
        containsAll({'invalid_quantity', 'extreme_quantity'}),
      );
      expect(result.passed, isFalse);
    });

    test('flags unmatched and weak database matches', () async {
      final engine = engineWith({
        'mystery bowl': const [],
        'apple': [food('Fruit mix')],
      });

      final result = await engine.validateMealCandidate(
        candidate: const AiMealCandidate(
          items: [
            AiMealCandidateItem(name: 'Mystery bowl', grams: 200),
            AiMealCandidateItem(name: 'Apple', grams: 100),
          ],
        ),
        mode: AiValidationMode.capture,
      );

      expect(
        result.allIssues.map((issue) => issue.code),
        containsAll({'unmatched_item', 'weak_db_match'}),
      );
      expect(result.unmatchedItemCount, 1);
      expect(result.passed, isFalse);
    });

    test('evaluates recommendation target fit with explicit tolerances',
        () async {
      final engine = engineWith({
        'macro bowl': [
          food(
            'Macro bowl',
            kcal: 500,
            protein: 40,
            carbs: 60,
            fat: 15,
          ),
        ],
      });

      final pass = await engine.validateMealCandidate(
        candidate: const AiMealCandidate(
          items: [AiMealCandidateItem(name: 'Macro bowl', grams: 100)],
        ),
        targetContext: const AiMacroTargetContext(
          kcal: 520,
          protein: 42,
          carbs: 58,
          fat: 16,
        ),
        mode: AiValidationMode.recommendation,
      );

      expect(pass.macroFit!.overallFit, isTrue);
      expect(pass.passed, isTrue);

      final fail = await engine.validateMealCandidate(
        candidate: const AiMealCandidate(
          items: [AiMealCandidateItem(name: 'Macro bowl', grams: 100)],
        ),
        targetContext: const AiMacroTargetContext(
          kcal: 900,
          protein: 90,
          carbs: 120,
          fat: 45,
        ),
        mode: AiValidationMode.recommendation,
      );

      expect(fail.macroFit!.overallFit, isFalse);
      expect(
        fail.errors.map((issue) => issue.code),
        containsAll({
          'target_kcal_mismatch',
          'target_protein_mismatch',
          'target_carbs_mismatch',
          'target_fat_mismatch',
        }),
      );
      expect(
        fail.errors
            .firstWhere((issue) => issue.code == 'target_kcal_mismatch')
            .parameters['delta'],
        -400,
      );
      expect(fail.passed, isFalse);
    });

    test('creates save plans that expose partial unmatched saves', () async {
      final engine = engineWith({
        'rice': [food('Rice')],
        'unknown': const [],
      });

      final result = await engine.validateMealCandidate(
        candidate: const AiMealCandidate(
          items: [
            AiMealCandidateItem(name: 'Rice', grams: 100),
            AiMealCandidateItem(name: 'Unknown', grams: 100),
          ],
        ),
        mode: AiValidationMode.capture,
      );
      final plan = AiDiarySavePlan.fromValidation(result);

      expect(plan.canSaveAny, isTrue);
      expect(plan.isPartial, isTrue);
      expect(plan.matchedItems.length, 1);
      expect(plan.unmatchedItems.length, 1);
    });

    test(
        'meal target planner does not invent a calorie floor at zero remaining',
        () {
      final target = AiMealTargetPlanner.computeMealTarget(
        remaining: const AiMacroTargetContext(
          kcal: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
        ),
        dailyGoal: const AiMacroTargetContext(
          kcal: 2400,
          protein: 160,
          carbs: 260,
          fat: 80,
        ),
        mealType: 'mealtypeSnack',
      );

      expect(target.kcal, 0);
      expect(target.protein, 0);
      expect(target.carbs, 0);
      expect(target.fat, 0);
    });
  });

  group('AiRepairOrchestrator', () {
    test('returns immediately when the first candidate passes', () async {
      final engine = engineWith({
        'rice': [food('Rice')],
      });
      var repairs = 0;

      final outcome = await AiRepairOrchestrator(
        validationEngine: engine,
      ).run(
        initialCandidate: const AiMealCandidate(
          items: [AiMealCandidateItem(name: 'Rice', grams: 100)],
        ),
        mode: AiValidationMode.capture,
        repairer: (_, __, ___) async {
          repairs += 1;
          return const AiMealCandidate(items: []);
        },
      );

      expect(outcome.validation.passed, isTrue);
      expect(outcome.repairPassesUsed, 0);
      expect(repairs, 0);
    });

    test('uses a repair pass and returns the repaired validation', () async {
      final engine = engineWith({
        'unknown': const [],
        'rice': [food('Rice')],
      });

      final outcome = await AiRepairOrchestrator(
        validationEngine: engine,
      ).run(
        initialCandidate: const AiMealCandidate(
          items: [AiMealCandidateItem(name: 'Unknown', grams: 100)],
        ),
        mode: AiValidationMode.capture,
        repairer: (_, __, ___) async {
          return const AiMealCandidate(
            items: [AiMealCandidateItem(name: 'Rice', grams: 100)],
          );
        },
      );

      expect(outcome.validation.passed, isTrue);
      expect(outcome.repairPassesUsed, 1);
      expect(outcome.repairLimitReached, isFalse);
      expect(outcome.validation.items.single.candidate.name, 'Rice');
    });

    test('repairs recommendation candidates after poor target fit', () async {
      final engine = engineWith({
        'tiny snack': [
          food(
            'Tiny snack',
            kcal: 100,
            protein: 5,
            carbs: 10,
            fat: 2,
          ),
        ],
        'target bowl': [
          food(
            'Target bowl',
            kcal: 500,
            protein: 40,
            carbs: 55,
            fat: 15,
          ),
        ],
      });

      final outcome = await AiRepairOrchestrator(
        validationEngine: engine,
      ).run(
        initialCandidate: const AiMealCandidate(
          mealName: 'Tiny snack',
          items: [AiMealCandidateItem(name: 'Tiny snack', grams: 100)],
        ),
        targetContext: const AiMacroTargetContext(
          kcal: 500,
          protein: 40,
          carbs: 55,
          fat: 15,
        ),
        mode: AiValidationMode.recommendation,
        repairer: (_, __, ___) async {
          return const AiMealCandidate(
            mealName: 'Target bowl',
            items: [AiMealCandidateItem(name: 'Target bowl', grams: 100)],
          );
        },
      );

      expect(outcome.repairPassesUsed, 1);
      expect(outcome.validation.passed, isTrue);
      expect(outcome.validation.macroFit!.overallFit, isTrue);
    });

    test('stops after maxRepairPasses and returns the latest candidate',
        () async {
      final engine = engineWith({
        'unknown': const [],
      });
      var attempts = 0;

      final outcome = await AiRepairOrchestrator(
        validationEngine: engine,
      ).run(
        initialCandidate: const AiMealCandidate(
          items: [AiMealCandidateItem(name: 'Unknown', grams: 100)],
        ),
        mode: AiValidationMode.capture,
        repairer: (_, __, ___) async {
          attempts += 1;
          return AiMealCandidate(
            items: [
              AiMealCandidateItem(
                name: 'Unknown',
                grams: 100 + attempts,
              ),
            ],
          );
        },
      );

      expect(attempts, maxRepairPasses);
      expect(outcome.repairLimitReached, isTrue);
      expect(outcome.validation.passed, isFalse);
      expect(outcome.validation.items.single.candidate.grams, 103);
    });
  });

  group('AI recommendation prompt context', () {
    test('omits recent meal history when context sharing is disabled', () {
      final prompt = AiService.buildMealRecommendationUserPromptForTesting(
        targetMacros: const {
          'kcal': 500,
          'protein': 40,
          'carbs': 50,
          'fat': 15,
        },
        preferences: const [],
        recentHistory: null,
        mealTypeLabel: 'Lunch',
      );

      expect(prompt, contains('No recent meal history was shared'));
      expect(prompt, isNot(contains('Mon: Oatmeal')));
    });

    test('includes recent meal history only when explicitly provided', () {
      final prompt = AiService.buildMealRecommendationUserPromptForTesting(
        targetMacros: const {
          'kcal': 500,
          'protein': 40,
          'carbs': 50,
          'fat': 15,
        },
        preferences: const ['Vegetarian'],
        recentHistory: 'Mon: Oatmeal',
        mealTypeLabel: 'Lunch',
      );

      expect(prompt, contains('Recent meals shared by the user'));
      expect(prompt, contains('Mon: Oatmeal'));
    });
  });
}
