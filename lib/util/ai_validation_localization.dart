import '../generated/app_localizations.dart';
import '../services/ai_meal_validation.dart';

String aiValidationIssueText(
  AppLocalizations l10n,
  AiValidationIssue issue,
) {
  switch (issue.code) {
    case 'empty_item_name':
      return l10n.aiValidationEmptyItemName;
    case 'duplicate_item_merged':
      return l10n.aiValidationDuplicateItemMerged(
        issue.parameters['name'] as String? ?? '',
      );
    case 'invalid_quantity':
      return l10n.aiValidationInvalidQuantity;
    case 'tiny_quantity':
      return l10n.aiValidationTinyQuantity;
    case 'extreme_quantity':
      return l10n.aiValidationExtremeQuantity;
    case 'large_quantity':
      return l10n.aiValidationLargeQuantity;
    case 'low_ai_confidence':
      return l10n.aiValidationLowAiConfidence;
    case 'unmatched_item':
      return l10n.aiValidationUnmatchedItem;
    case 'weak_db_match':
      return l10n.aiValidationWeakDbMatch;
    case 'partial_db_match':
      return l10n.aiValidationPartialDbMatch;
    case 'ambiguous_db_match':
      return l10n.aiValidationAmbiguousDbMatch;
    case 'state_mismatch':
      return l10n.aiValidationStateMismatch;
    case 'zero_nutrition_match':
      return l10n.aiValidationZeroNutritionMatch;
    case 'implausible_food_density':
      return l10n.aiValidationImplausibleFoodDensity;
    case 'macro_energy_mismatch':
      return l10n.aiValidationMacroEnergyMismatch;
    case 'implausible_item_nutrition':
      return l10n.aiValidationImplausibleItemNutrition;
    case 'empty_meal':
      return l10n.aiValidationEmptyMeal;
    case 'all_items_unmatched':
      return l10n.aiValidationAllItemsUnmatched;
    case 'partial_unmatched_items':
      return l10n.aiValidationPartialUnmatchedItems(
        issue.parameters['count'] as int? ?? 0,
      );
    case 'zero_total_kcal':
      return l10n.aiValidationZeroTotalKcal;
    case 'capture_total_kcal_extreme':
      return l10n.aiValidationCaptureTotalKcalExtreme;
    case 'capture_total_kcal_high':
      return l10n.aiValidationCaptureTotalKcalHigh;
    case 'macro_total_extreme':
      return l10n.aiValidationMacroTotalExtreme;
    case 'macro_total_high':
      return l10n.aiValidationMacroTotalHigh;
    case 'target_kcal_mismatch':
      return l10n.aiValidationTargetKcalMismatch(
        issue.parameters['delta'] as int? ?? 0,
      );
    case 'target_protein_mismatch':
      return l10n.aiValidationTargetProteinMismatch(
        issue.parameters['delta'] as int? ?? 0,
      );
    case 'target_carbs_mismatch':
      return l10n.aiValidationTargetCarbsMismatch(
        issue.parameters['delta'] as int? ?? 0,
      );
    case 'target_fat_mismatch':
      return l10n.aiValidationTargetFatMismatch(
        issue.parameters['delta'] as int? ?? 0,
      );
    default:
      return l10n.aiValidationUnknownIssue(issue.code);
  }
}
