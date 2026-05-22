import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/ai_meal_validation.dart';
import '../../../../util/ai_validation_localization.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';

class MealReviewValidationSummary extends StatefulWidget {
  const MealReviewValidationSummary({
    super.key,
    required this.validation,
    required this.itemsCount,
  });

  final AiValidationResult validation;
  final int itemsCount;

  @override
  State<MealReviewValidationSummary> createState() => _MealReviewValidationSummaryState();
}

class _MealReviewValidationSummaryState extends State<MealReviewValidationSummary> {
  bool _validationExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final validation = widget.validation;
    
    final allActionableIssues = validation.allIssues
        .where((issue) => issue.severity != AiValidationSeverity.info)
        .toList(growable: false);
    final color = validation.passed
        ? Colors.green
        : validation.errors.isNotEmpty
            ? theme.colorScheme.error
            : Colors.orange;

    final shouldAutoExpand =
        !validation.passed || validation.errors.isNotEmpty;
    final isExpanded = _validationExpanded || shouldAutoExpand;

    final compactTotals =
        '${validation.totals.kcalRounded} kcal · '
        'P${validation.totals.proteinRounded} · '
        'C${validation.totals.carbsRounded} · '
        'F${validation.totals.fatRounded}';

    return SummaryCard(
      child: InkWell(
        onTap: shouldAutoExpand
            ? null
            : () => setState(
                  () => _validationExpanded = !_validationExpanded,
                ),
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    validation.passed
                        ? Icons.verified_rounded
                        : Icons.warning_amber_rounded,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${validation.score}/100',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      compactTotals,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!shouldAutoExpand)
                    Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 26),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.toll_rounded,
                      size: 11,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Kosten: ~${1200 + (widget.itemsCount * 80)} Tokens',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                if (validation.repairLimitReached) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.aiValidationRepairLimitReachedReview,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (allActionableIssues.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...allActionableIssues.take(4).map(
                        (issue) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '\u2022 ${aiValidationIssueText(l10n, issue)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                  if (allActionableIssues.length > 4) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () => _showAllIssues(allActionableIssues, l10n),
                        child: Text(
                          'Show all (${allActionableIssues.length})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAllIssues(
    List<AiValidationIssue> issues,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.aiValidationReviewSuggestedTitle,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...issues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '\u2022 ${aiValidationIssueText(l10n, issue)}',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
