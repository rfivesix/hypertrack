import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/ai_meal_validation.dart';
import '../../../../util/ai_validation_localization.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../domain/models/food_item.dart';
import 'meal_review_macros_bar.dart';

/// A card representing an AI suggested meal item compared against database matches.
class MealReviewComparisonCard extends StatelessWidget {
  final Key dismissibleKey;
  final String name;
  final int estimatedGrams;
  final double confidence;
  final FoodItem? matchedFood;
  final List<AiValidationIssue> issues;
  final AiNutritionTotals nutrition;
  final VoidCallback onDismissed;
  final VoidCallback onTap;
  final VoidCallback onReplace;
  final VoidCallback onEditQuantity;

  const MealReviewComparisonCard({
    required this.dismissibleKey,
    required this.name,
    required this.estimatedGrams,
    required this.confidence,
    required this.matchedFood,
    required this.issues,
    required this.nutrition,
    required this.onDismissed,
    required this.onTap,
    required this.onReplace,
    required this.onEditQuantity,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasMatch = matchedFood != null;

    final Color confidenceColor;
    if (confidence >= 0.8) {
      confidenceColor = Colors.green;
    } else if (confidence >= 0.5) {
      confidenceColor = Colors.orange;
    } else {
      confidenceColor = Colors.red;
    }

    return Dismissible(
      key: dismissibleKey,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismissed(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SummaryCard(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Left: food info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (hasMatch)
                          Text(
                            '${matchedFood!.getLocalizedName(context)} • ${matchedFood!.calories} kcal/100g',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        else
                          Text(
                            l10n.aiReviewNoMatch,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        // Macro badges row
                        const SizedBox(height: 6),
                        MealReviewMacrosBar(nutrition: nutrition),
                        const SizedBox(height: 4),
                        // Confidence chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: confidenceColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(confidence * 100).round()}%',
                            style: TextStyle(
                              color: confidenceColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (issues
                            .where(
                              (issue) =>
                                  issue.severity != AiValidationSeverity.info,
                            )
                            .isNotEmpty) ...[
                          const SizedBox(height: 6),
                          ...issues
                              .where(
                                (issue) =>
                                    issue.severity != AiValidationSeverity.info,
                              )
                              .take(2)
                              .map(
                                (issue) => Text(
                                  aiValidationIssueText(l10n, issue),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: issue.severity ==
                                            AiValidationSeverity.error
                                        ? theme.colorScheme.error
                                        : Colors.orange[800],
                                  ),
                                ),
                              ),
                        ],
                      ],
                    ),
                  ),
                  // Center-right: swap icon
                  IconButton(
                    icon: Icon(
                      Icons.swap_horiz_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: l10n.aiReviewReplaceItem,
                    onPressed: onReplace,
                    visualDensity: VisualDensity.compact,
                  ),
                  // Right: quantity
                  GestureDetector(
                    onTap: onEditQuantity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${estimatedGrams}g',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
