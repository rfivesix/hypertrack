import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/summary_card.dart';
import '../domain/bayesian_tdee_estimator.dart';
import '../domain/confidence_models.dart';
import '../domain/goal_models.dart';
import '../domain/recommendation_models.dart';
import 'recommendation_ui_copy.dart';

class NutritionRecommendationCard extends StatelessWidget {
  final BodyweightGoal goal;
  final double targetRateKgPerWeek;
  final NutritionRecommendation? recommendation;
  final BayesianMaintenanceEstimate? maintenanceEstimate;
  final DateTime? generatedAt;
  final DateTime nextAdaptiveRecommendationDueAt;
  final bool isAdaptiveRecommendationDueNow;
  final int activeTargetCalories;
  final bool isRecalculating;
  final bool isApplying;
  final VoidCallback? onRecalculate;
  final VoidCallback? onApply;

  const NutritionRecommendationCard({
    super.key,
    required this.goal,
    required this.targetRateKgPerWeek,
    required this.recommendation,
    required this.maintenanceEstimate,
    required this.generatedAt,
    required this.nextAdaptiveRecommendationDueAt,
    required this.isAdaptiveRecommendationDueNow,
    required this.activeTargetCalories,
    required this.isRecalculating,
    required this.isApplying,
    required this.onRecalculate,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recommendationWarning = recommendation == null
        ? null
        : RecommendationUiCopy.warningMessage(l10n, recommendation!);

    return SummaryCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.cardPaddingInternal),
        child: SingleChildScrollView(
          child: recommendation == null
              ? _EmptyRecommendationContent(
                  goalLine: l10n.adaptiveRecommendationGoalLine(
                    _goalLabel(l10n, goal),
                    _rateLabel(l10n, targetRateKgPerWeek),
                  ),
                  nextDueLine: l10n.adaptiveRecommendationNextDueLine(
                    _formatDate(context, nextAdaptiveRecommendationDueAt),
                  ),
                  isAdaptiveRecommendationDueNow:
                      isAdaptiveRecommendationDueNow,
                  isRecalculating: isRecalculating,
                  onRecalculate: onRecalculate,
                )
              : _GeneratedRecommendationContent(
                  recommendation: recommendation!,
                  maintenanceEstimate: maintenanceEstimate,
                  isAdaptiveRecommendationDueNow:
                      isAdaptiveRecommendationDueNow,
                  activeTargetCalories: activeTargetCalories,
                  recommendationWarning: recommendationWarning,
                  isRecalculating: isRecalculating,
                  isApplying: isApplying,
                  onRecalculate: onRecalculate,
                  onApply: onApply,
                  goalLabel: _goalLabel(l10n, recommendation!.goal),
                  rateLabel: _rateLabel(
                    l10n,
                    recommendation!.targetRateKgPerWeek,
                  ),
                  formattedGeneratedAt: _formatDateTime(
                    context,
                    generatedAt ?? recommendation!.generatedAt,
                  ),
                  formattedNextDue:
                      _formatDate(context, nextAdaptiveRecommendationDueAt),
                ),
        ),
      ),
    );
  }

  String _goalLabel(AppLocalizations l10n, BodyweightGoal goal) {
    switch (goal) {
      case BodyweightGoal.loseWeight:
        return l10n.adaptiveGoalLose;
      case BodyweightGoal.maintainWeight:
        return l10n.adaptiveGoalMaintain;
      case BodyweightGoal.gainWeight:
        return l10n.adaptiveGoalGain;
    }
  }

  String _rateLabel(AppLocalizations l10n, double kgPerWeek) {
    final sign = kgPerWeek > 0 ? '+' : '';
    return l10n.adaptiveRatePerWeek('$sign${kgPerWeek.toStringAsFixed(2)}');
  }

  String _formatDate(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
  }

  String _formatDateTime(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    final localValue = value.toLocal();
    final dateText = localizations.formatMediumDate(localValue);
    final timeText = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localValue),
      alwaysUse24HourFormat:
          MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
    );
    return '$dateText $timeText';
  }
}

class _EmptyRecommendationContent extends StatelessWidget {
  final String goalLine;
  final String nextDueLine;
  final bool isAdaptiveRecommendationDueNow;
  final bool isRecalculating;
  final VoidCallback? onRecalculate;

  const _EmptyRecommendationContent({
    required this.goalLine,
    required this.nextDueLine,
    required this.isAdaptiveRecommendationDueNow,
    required this.isRecalculating,
    required this.onRecalculate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.adaptiveRecommendationCardTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingS),
        _SoftPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.adaptiveRecommendationEmptyBody,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: DesignConstants.spacingM),
              _DetailLine(text: goalLine),
              const SizedBox(height: DesignConstants.spacingXS),
              _DetailLine(text: nextDueLine),
              if (isAdaptiveRecommendationDueNow)
                Padding(
                  padding:
                      const EdgeInsets.only(top: DesignConstants.spacingXS),
                  child: _DetailLine(
                    text: l10n.adaptiveRecommendationDueNowLine,
                    key: const Key('adaptive_recommendation_due_now_line'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: DesignConstants.spacingM),
        FilledButton.tonal(
          onPressed: isRecalculating ? null : onRecalculate,
          child: Text(
            isRecalculating
                ? l10n.adaptiveRecommendationRecalculating
                : l10n.adaptiveRecommendationRecalculateNowAction,
          ),
        ),
      ],
    );
  }
}

class _GeneratedRecommendationContent extends StatelessWidget {
  final NutritionRecommendation recommendation;
  final BayesianMaintenanceEstimate? maintenanceEstimate;
  final bool isAdaptiveRecommendationDueNow;
  final int activeTargetCalories;
  final String? recommendationWarning;
  final bool isRecalculating;
  final bool isApplying;
  final VoidCallback? onRecalculate;
  final VoidCallback? onApply;
  final String goalLabel;
  final String rateLabel;
  final String formattedGeneratedAt;
  final String formattedNextDue;

  const _GeneratedRecommendationContent({
    required this.recommendation,
    required this.maintenanceEstimate,
    required this.isAdaptiveRecommendationDueNow,
    required this.activeTargetCalories,
    required this.recommendationWarning,
    required this.isRecalculating,
    required this.isApplying,
    required this.onRecalculate,
    required this.onApply,
    required this.goalLabel,
    required this.rateLabel,
    required this.formattedGeneratedAt,
    required this.formattedNextDue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rangeLine = maintenanceEstimate == null
        ? null
        : l10n.adaptiveRecommendationMaintenanceRangeLine(
            maintenanceEstimate!.credibleIntervalLowerCalories(),
            maintenanceEstimate!.credibleIntervalUpperCalories(),
          );
    final confidenceLabel = RecommendationUiCopy.confidenceLabel(
      l10n,
      recommendation.confidence,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _RecommendationHeader(
          title: l10n.adaptiveRecommendationCardTitle,
          goalLine: l10n.adaptiveRecommendationGoalLine(goalLabel, rateLabel),
          statusText: isAdaptiveRecommendationDueNow
              ? l10n.adaptiveRecommendationDueNowShort
              : l10n.adaptiveRecommendationNextDueShort(formattedNextDue),
          isDueNow: isAdaptiveRecommendationDueNow,
        ),
        if (isAdaptiveRecommendationDueNow)
          Padding(
            padding: const EdgeInsets.only(top: DesignConstants.spacingS),
            child: Text(
              l10n.adaptiveRecommendationDueNowLine,
              key: const Key('adaptive_recommendation_due_now_line'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
        const SizedBox(height: DesignConstants.spacingM),
        _MaintenanceHero(
          value: recommendation.estimatedMaintenanceCalories,
          rangeLine: rangeLine,
          confidenceLabel: confidenceLabel,
          confidence: recommendation.confidence,
        ),
        if (maintenanceEstimate != null) ...[
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            RecommendationUiCopy.uncertaintyHint(
              l10n,
              maintenanceEstimate!,
            ),
            key: const Key('adaptive_recommendation_uncertainty_hint'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
          if (RecommendationUiCopy.isStabilizing(maintenanceEstimate!))
            Padding(
              padding: const EdgeInsets.only(top: DesignConstants.spacingXS),
              child: Text(
                l10n.adaptiveRecommendationStabilizingHint,
                key: const Key('adaptive_recommendation_stabilizing_hint'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ),
        ],
        const SizedBox(height: DesignConstants.spacingS),
        _MacroTargetGrid(recommendation: recommendation),
        const SizedBox(height: DesignConstants.spacingS),
        _RecommendationContextPanel(
          dataBasisLine: l10n.adaptiveRecommendationDataBasisLine(
            recommendation.inputSummary.windowDays,
            recommendation.inputSummary.weightLogCount,
            recommendation.inputSummary.intakeLoggedDays,
          ),
          dataBasisMessage: RecommendationUiCopy.dataBasisMessage(
            l10n,
            recommendation,
          ),
          activeCaloriesLine: l10n.adaptiveRecommendationActiveCaloriesLine(
            activeTargetCalories,
          ),
          calculatedAtLine: l10n.adaptiveRecommendationCalculatedAtLine(
            formattedGeneratedAt,
          ),
          nextDueLine: l10n.adaptiveRecommendationNextDueLine(formattedNextDue),
        ),
        if (recommendationWarning != null)
          Padding(
            padding: const EdgeInsets.only(top: DesignConstants.spacingM),
            child: _RecommendationWarningPanel(
              text: recommendationWarning!,
              warningLevel: recommendation.warningState.warningLevel,
            ),
          ),
        const SizedBox(height: DesignConstants.spacingM),
        _RecommendationActions(
          isRecalculating: isRecalculating,
          isApplying: isApplying,
          onRecalculate: onRecalculate,
          onApply: onApply,
        ),
      ],
    );
  }
}

class _RecommendationHeader extends StatelessWidget {
  final String title;
  final String goalLine;
  final String statusText;
  final bool isDueNow;

  const _RecommendationHeader({
    required this.title,
    required this.goalLine,
    required this.statusText,
    required this.isDueNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: DesignConstants.spacingXS),
              Text(
                goalLine,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: DesignConstants.spacingS),
        _StatusPill(text: statusText, emphasized: isDueNow),
      ],
    );
  }
}

class _MaintenanceHero extends StatelessWidget {
  final int value;
  final String? rangeLine;
  final String confidenceLabel;
  final RecommendationConfidence confidence;

  const _MaintenanceHero({
    required this.value,
    required this.rangeLine,
    required this.confidenceLabel,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = colorScheme.primary;
    final panelColor = isDark
        ? Colors.black.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.42);
    final borderColor = colorScheme.onSurface.withValues(alpha: 0.10);

    return Semantics(
      label: l10n.adaptiveRecommendationMaintenanceLine(value),
      child: Container(
        padding: const EdgeInsets.all(DesignConstants.spacingM),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adaptiveRecommendationMaintenanceLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.adaptiveRecommendationMaintenanceSourceLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$value',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      height: 0.98,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: DesignConstants.spacingS),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      l10n.adaptiveRecommendationMaintenanceUnit,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Row(
              children: [
                if (rangeLine != null)
                  Expanded(
                    child: _MetricCaption(
                      text: rangeLine!,
                      key: const Key('adaptive_recommendation_range_line'),
                    ),
                  ),
                if (rangeLine != null)
                  const SizedBox(width: DesignConstants.spacingS),
                Flexible(
                  child: Align(
                    alignment: rangeLine == null
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: _MetricCaption(text: confidenceLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Semantics(
              label: confidenceLabel,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _confidenceProgress(confidence),
                  minHeight: 8,
                  backgroundColor: colorScheme.onSurface
                      .withValues(alpha: isDark ? 0.14 : 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _confidenceProgress(RecommendationConfidence confidence) {
    // These are ordinal visual fractions (not probabilities or posterior
    // percentages).  They map each discrete data-quality tier to a
    // representative fill level so the bar conveys relative data-basis
    // strength at a glance.  notEnoughData is non-zero so users always
    // see a visible bar rather than an invisible one.
    switch (confidence) {
      case RecommendationConfidence.notEnoughData:
        return 0.22;
      case RecommendationConfidence.low:
        return 0.42;
      case RecommendationConfidence.medium:
        return 0.68;
      case RecommendationConfidence.high:
        return 0.90;
    }
  }
}

class _MetricCaption extends StatelessWidget {
  final String text;

  const _MetricCaption({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _MacroTargetGrid extends StatelessWidget {
  final NutritionRecommendation recommendation;

  const _MacroTargetGrid({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      _MacroTarget(
        label: l10n.adaptiveRecommendationTargetCaloriesLabel,
        value: l10n.adaptiveRecommendationCaloriesValue(
          recommendation.recommendedCalories,
        ),
      ),
      _MacroTarget(
        label: l10n.protein,
        value: l10n.adaptiveRecommendationProteinValue(
          recommendation.recommendedProteinGrams,
        ),
      ),
      _MacroTarget(
        label: l10n.carbs,
        value: l10n.adaptiveRecommendationCarbsValue(
          recommendation.recommendedCarbsGrams,
        ),
      ),
      _MacroTarget(
        label: l10n.fat,
        value: l10n.adaptiveRecommendationFatValue(
          recommendation.recommendedFatGrams,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.adaptiveRecommendationMacroTargetsLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 430 ? 2 : 4;
            return GridView.count(
              padding: EdgeInsets.only(
                  top: DesignConstants.spacingM), //EdgeInsets.zero,
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: DesignConstants.spacingS,
              mainAxisSpacing: DesignConstants.spacingS,
              childAspectRatio: crossAxisCount == 2 ? 2.45 : 2.65,
              children: [
                for (final item in items)
                  _MacroTile(label: item.label, value: item.value),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MacroTarget {
  final String label;
  final String value;

  const _MacroTarget({required this.label, required this.value});
}

class _MacroTile extends StatelessWidget {
  final String label;
  final String value;

  const _MacroTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _SoftPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingM,
        vertical: DesignConstants.spacingS,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.58),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationContextPanel extends StatelessWidget {
  final String dataBasisLine;
  final String dataBasisMessage;
  final String activeCaloriesLine;
  final String calculatedAtLine;
  final String nextDueLine;

  const _RecommendationContextPanel({
    required this.dataBasisLine,
    required this.dataBasisMessage,
    required this.activeCaloriesLine,
    required this.calculatedAtLine,
    required this.nextDueLine,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adaptiveRecommendationDataQualityLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          _DetailLine(text: dataBasisLine),
          const SizedBox(height: DesignConstants.spacingXS),
          _DetailLine(
            text: dataBasisMessage,
            key: const Key('adaptive_recommendation_data_basis_message'),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Wrap(
            spacing: DesignConstants.spacingS,
            runSpacing: DesignConstants.spacingXS,
            children: [
              _CompactChip(text: activeCaloriesLine),
              _CompactChip(text: calculatedAtLine),
              _CompactChip(text: nextDueLine),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationWarningPanel extends StatelessWidget {
  final String text;
  final RecommendationWarningLevel warningLevel;

  const _RecommendationWarningPanel({
    required this.text,
    required this.warningLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isHigh = warningLevel == RecommendationWarningLevel.high;
    final backgroundColor = isHigh
        ? colorScheme.errorContainer
        : colorScheme.primary.withValues(alpha: 0.14);
    final foregroundColor =
        isHigh ? colorScheme.onErrorContainer : colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(DesignConstants.spacingM),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        border: Border.all(
          color: (isHigh ? colorScheme.error : colorScheme.primary).withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Text(
        text,
        key: const Key('adaptive_recommendation_warning_text'),
        style: theme.textTheme.bodySmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecommendationActions extends StatelessWidget {
  final bool isRecalculating;
  final bool isApplying;
  final VoidCallback? onRecalculate;
  final VoidCallback? onApply;

  const _RecommendationActions({
    required this.isRecalculating,
    required this.isApplying,
    required this.onRecalculate,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: DesignConstants.spacingS,
      runSpacing: DesignConstants.spacingS,
      alignment: WrapAlignment.start,
      children: [
        FilledButton.tonal(
          onPressed: isRecalculating ? null : onRecalculate,
          child: Text(
            isRecalculating
                ? l10n.adaptiveRecommendationRecalculating
                : l10n.adaptiveRecommendationRecalculateNowAction,
          ),
        ),
        ElevatedButton(
          onPressed: isApplying ? null : onApply,
          child: Text(
            isApplying
                ? l10n.adaptiveRecommendationApplying
                : l10n.adaptiveRecommendationApplyAction,
          ),
        ),
      ],
    );
  }
}

class _SoftPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SoftPanel({
    required this.child,
    this.padding = const EdgeInsets.all(DesignConstants.spacingM),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark
        ? Colors.white.withValues(alpha: 0.045)
        : Colors.white.withValues(alpha: 0.50);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(
            alpha: isDark ? 0.08 : 0.10,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final bool emphasized;

  const _StatusPill({required this.text, required this.emphasized});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = emphasized
        ? colorScheme.primary.withValues(alpha: 0.18)
        : colorScheme.onSurface.withValues(alpha: 0.07);
    final foregroundColor = emphasized
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.68);

    return Container(
      constraints: const BoxConstraints(maxWidth: 132),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingS,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CompactChip extends StatelessWidget {
  final String text;

  const _CompactChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingS,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.74),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String text;

  const _DetailLine({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
