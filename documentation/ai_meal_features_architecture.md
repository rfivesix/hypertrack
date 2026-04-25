# AI Meal Features Architecture

This document describes the current AI meal capture and AI meal recommendation architecture after the validation rework.

## Scope

Hypertrack AI meal features remain optional and BYOK-based:

- global AI features are off by default
- provider/model/key selection stays in `AiService`
- API keys are stored with `flutter_secure_storage`
- recent meal history for recommendations is a separate opt-in setting and is off by default

The model is used to propose food names and gram amounts. Deterministic app code then validates, matches, computes nutrition, repairs when possible, and surfaces warnings before anything is saved.

## Main Files

- `lib/services/ai_service.dart`
  Provider calls, prompts, JSON parsing, capture repair calls, recommendation generation and repair calls.
- `lib/services/ai_meal_validation.dart`
  Shared deterministic validation domain, match quality, nutrition totals, target-fit checks, save planning, target planning, and bounded repair orchestration.
- `lib/screens/ai_meal_capture_screen.dart`
  Image/text capture entry point. Runs recognition, validation, and bounded auto-repair before review.
- `lib/screens/ai_meal_review_screen.dart`
  Review-first capture UI. Shows validation quality, item warnings, unmatched items, and partial-save confirmation.
- `lib/screens/ai_recommendation_screen.dart`
  Recommendation UI. Computes remaining meal target, branches on context opt-in, validates target fit, repairs, and shows warnings.
- `lib/screens/ai_settings_screen.dart`
  Global AI enablement, provider/model/API key setup, and the separate recommendation context-sharing switch.

## Shared Validation Domain

The shared validation layer is centered on these types:

- `AiMealCandidate`
- `AiMealCandidateItem`
- `AiMatchResult`
- `AiNutritionTotals`
- `AiMacroTargetContext`
- `AiTargetFitResult`
- `AiValidationIssue`
- `AiValidationSeverity`
- `AiValidationResult`
- `AiDiarySavePlan`
- `AiMealTargetPlanner`
- `AiMealValidationEngine`
- `AiRepairOrchestrator`

The engine is asynchronous because DB matching is asynchronous. It accepts an injectable match loader, which keeps tests deterministic and lets production use `ProductDatabaseHelper.instance`.

## Deterministic vs Model-Generated

Model-generated:

- capture ingredient names
- capture gram estimates
- recommendation meal name and description
- recommendation ingredient names
- recommendation gram amounts
- repair candidates after validation feedback

Deterministic:

- output normalization and duplicate merging
- local DB match selection and match-quality classification
- local nutrition computation from matched DB entries
- item-level warnings and errors
- meal-level warnings and errors
- recommendation target-fit validation for kcal/protein/carbs/fat
- repair retry bound (`maxRepairPasses = 3`)
- save planning for matched vs unmatched items
- context-sharing branch based on settings

## Validation Rules

Item-level checks include:

- quantity must be greater than 0g
- tiny quantities are flagged
- large and extreme quantities are flagged
- low AI confidence is flagged when provided
- unmatched local DB entries are errors
- weak and ambiguous DB matches are surfaced; weak recommendation matches fail validation
- simple food state mismatch checks are surfaced
- zero nutrition and implausible nutrition density are surfaced
- implausible nutrition for the selected quantity is surfaced

Meal-level checks include:

- empty meal
- all items unmatched
- partial unmatched items
- zero local kcal from matched items
- implausible capture meal totals
- implausible macro totals
- recommendation target mismatch for kcal/protein/carbs/fat

Recommendation target tolerances are explicit in `AiMealValidationEngine`:

- kcal: `max(80, target * 20%)`
- protein/carbs: `max(10g, target * 25%)`, with an 8g tolerance for zero targets
- fat: `max(8g, target * 30%)`, with a 6g tolerance for zero targets

## Capture Pipeline

```text
capture_meal(input):
    candidate = ai_recognition_pass(input)
    validation = validate_meal_candidate(
        candidate = candidate,
        target_context = null,
        mode = capture
    )
    repair_count = 0
    while not validation.passed and repair_count < 3:
        candidate = ai_repair_pass(
            candidate = candidate,
            validation_issues = validation.toRepairFeedback(),
            strict_mode = true,
            low_creativity = true
        )
        validation = validate_meal_candidate(
            candidate = candidate,
            target_context = null,
            mode = capture
        )
        repair_count += 1
    return build_capture_review_ui(validation)
```

The review UI remains manual and review-first. Users can edit quantities, replace matches, add foods, remove rows, and retry with manual feedback. Edits trigger revalidation. Saving uses `AiDiarySavePlan`; unmatched items are not silently treated as saved.

## Recommendation Pipeline

```text
generate_recommendation(request, context_opt_in):
    remaining = compute_remaining_targets(request.date)
    daily_goal = load_goal_for_date(request.date)
    target_context = AiMealTargetPlanner.computeMealTarget(
        remaining = remaining,
        daily_goal = daily_goal,
        meal_type = request.meal_type
    )
    optional_context = null
    if context_opt_in:
        optional_context = build_recent_meal_context(last_7_days)
    candidate = ai_generation_pass(
        target_context = target_context,
        optional_context = optional_context,
        preferences = request.preferences,
        constraints = request.constraints
    )
    validation = validate_meal_candidate(
        candidate = candidate,
        target_context = target_context,
        mode = recommendation
    )
    repair_count = 0
    while not validation.passed and repair_count < 3:
        candidate = ai_repair_pass(
            candidate = candidate,
            validation_issues = validation.toRepairFeedback(),
            strict_mode = true,
            low_creativity = true
        )
        validation = validate_meal_candidate(
            candidate = candidate,
            target_context = target_context,
            mode = recommendation
        )
        repair_count += 1
    return build_recommendation_ui(validation)
```

The recommendation UI displays locally recomputed totals, target deltas, validation score, warnings, whether recent meal context was shared, and repair-limit status.

## Shared Validation Algorithm

```text
validate_meal_candidate(candidate, target_context?, mode):
    normalized_candidate = normalize(candidate)
    matched_items = []
    for item in normalized_candidate.items:
        match_result = match_to_db(item.name, item.matched_barcode)
        nutrition = compute_local_nutrition(
            db_item = match_result.best_match,
            grams = item.grams
        )
        item_warnings = validate_item(
            item = item,
            match_result = match_result,
            nutrition = nutrition,
            mode = mode
        )
        matched_items.append(
            CandidateItem(
                ai_item = item,
                match = match_result,
                nutrition = nutrition,
                warnings = item_warnings
            )
        )
    totals = sum_nutrition(matched_items)
    macro_fit = null
    if target_context != null:
        macro_fit = evaluate_target_fit(
            totals = totals,
            target = target_context
        )
    meal_warnings = validate_meal(
        items = matched_items,
        totals = totals,
        target_context = target_context,
        macro_fit = macro_fit,
        mode = mode
    )
    return ValidationResult(
        items = matched_items,
        totals = totals,
        macro_fit = macro_fit,
        warnings = meal_warnings,
        score = compute_validation_score(...),
        passed = is_good_enough(...)
    )
```

## Target-Fit Algorithm

```text
evaluate_target_fit(totals, target):
    kcal_delta = totals.kcal - target.kcal
    protein_delta = totals.protein - target.protein
    carbs_delta = totals.carbs - target.carbs
    fat_delta = totals.fat - target.fat

    return TargetFit(
        kcal_delta = kcal_delta,
        protein_delta = protein_delta,
        carbs_delta = carbs_delta,
        fat_delta = fat_delta,
        kcal_within_tolerance =
            abs(kcal_delta) <= kcal_tolerance(target.kcal),
        protein_within_tolerance =
            abs(protein_delta) <= macro_tolerance(target.protein),
        carbs_within_tolerance =
            abs(carbs_delta) <= macro_tolerance(target.carbs),
        fat_within_tolerance =
            abs(fat_delta) <= fat_tolerance(target.fat),
        overall_fit = all constraints pass
    )
```

## Privacy Branch

Recommendation context sharing is controlled separately from global AI enablement:

- `ai_enabled`: global AI feature visibility/use
- `ai_recommendation_context_enabled`: whether a recent-meal summary may be included in recommendation prompts

When context sharing is off, recommendation prompts explicitly say no recent meal history was shared. Recommendations still work using target macros, preferences, constraints, and custom request only.

## Repair Bound

`AiRepairOrchestrator` uses `maxRepairPasses = 3`.

If validation still fails:

- the latest candidate is returned
- `repairLimitReached` is set
- warnings/errors remain visible in the UI
- save behavior remains explicit about unmatched items
