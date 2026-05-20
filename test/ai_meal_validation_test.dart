import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/diary/domain/models/food_item.dart';
import 'package:train_libre/services/ai_meal_validation.dart';

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
}
