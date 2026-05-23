import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../nutrition_recommendation/domain/goal_models.dart';
import '../../../nutrition_recommendation/presentation/prior_activity_help_block.dart';

class AdaptiveGoalSlide extends StatelessWidget {
  final BodyweightGoal selectedGoal;
  final PriorActivityLevel selectedPriorActivityLevel;
  final ExtraCardioHoursOption selectedExtraCardioHoursOption;
  final double selectedTargetRateKgPerWeek;

  final ValueChanged<BodyweightGoal> onGoalChanged;
  final ValueChanged<PriorActivityLevel> onPriorActivityLevelChanged;
  final ValueChanged<ExtraCardioHoursOption> onExtraCardioHoursOptionChanged;
  final ValueChanged<double> onTargetRateKgPerWeekChanged;

  const AdaptiveGoalSlide({
    super.key,
    required this.selectedGoal,
    required this.selectedPriorActivityLevel,
    required this.selectedExtraCardioHoursOption,
    required this.selectedTargetRateKgPerWeek,
    required this.onGoalChanged,
    required this.onPriorActivityLevelChanged,
    required this.onExtraCardioHoursOptionChanged,
    required this.onTargetRateKgPerWeekChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      key: const Key('onboarding_adaptive_goal_page'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            l10n.onboardingAdaptiveGoalTitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingAdaptiveGoalSubtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<BodyweightGoal>(
            initialValue: selectedGoal,
            decoration: InputDecoration(
              labelText: l10n.adaptiveGoalDirectionLabel,
            ),
            items: BodyweightGoal.values
                .map(
                  (goal) => DropdownMenuItem<BodyweightGoal>(
                    value: goal,
                    child: Text(_goalLabel(l10n, goal)),
                  ),
                )
                .toList(growable: false),
            onChanged: (goal) {
              if (goal != null) onGoalChanged(goal);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PriorActivityLevel>(
            key: const Key('onboarding_prior_activity_dropdown'),
            initialValue: selectedPriorActivityLevel,
            decoration: InputDecoration(
              labelText: l10n.adaptivePriorActivityLabel,
            ),
            items: PriorActivityLevel.values
                .map(
                  (level) => DropdownMenuItem<PriorActivityLevel>(
                    value: level,
                    child: Text(_priorActivityLabel(l10n, level)),
                  ),
                )
                .toList(growable: false),
            onChanged: (level) {
              if (level != null) onPriorActivityLevelChanged(level);
            },
          ),
          const SizedBox(height: 12),
          PriorActivityHelpBlock(
            key: const Key('onboarding_prior_activity_help_block'),
            l10n: l10n,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExtraCardioHoursOption>(
            key: const Key('onboarding_extra_cardio_dropdown'),
            initialValue: selectedExtraCardioHoursOption,
            decoration: InputDecoration(
              labelText: l10n.adaptiveExtraCardioLabel,
            ),
            items: ExtraCardioHoursCatalog.supportedOptions
                .map(
                  (option) => DropdownMenuItem<ExtraCardioHoursOption>(
                    value: option,
                    child: Text(_extraCardioLabel(l10n, option)),
                  ),
                )
                .toList(growable: false),
            onChanged: (option) {
              if (option != null) onExtraCardioHoursOptionChanged(option);
            },
          ),
          const SizedBox(height: 8),
          Text(
            l10n.adaptiveExtraCardioHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WeeklyTargetRateCatalog.optionsForGoal(selectedGoal)
                .map((option) {
              final isSelected =
                  option.kgPerWeek == selectedTargetRateKgPerWeek;
              return ChoiceChip(
                label: Text(
                  _rateLabel(l10n, option.kgPerWeek),
                ),
                selected: isSelected,
                onSelected: (_) {
                  onTargetRateKgPerWeekChanged(option.kgPerWeek);
                },
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 20),
        ],
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

  String _priorActivityLabel(
    AppLocalizations l10n,
    PriorActivityLevel level,
  ) {
    switch (level) {
      case PriorActivityLevel.low:
        return l10n.adaptivePriorActivityLow;
      case PriorActivityLevel.moderate:
        return l10n.adaptivePriorActivityModerate;
      case PriorActivityLevel.high:
        return l10n.adaptivePriorActivityHigh;
      case PriorActivityLevel.veryHigh:
        return l10n.adaptivePriorActivityVeryHigh;
    }
  }

  String _extraCardioLabel(
    AppLocalizations l10n,
    ExtraCardioHoursOption option,
  ) {
    switch (option) {
      case ExtraCardioHoursOption.h0:
        return l10n.adaptiveExtraCardioOption0;
      case ExtraCardioHoursOption.h1:
        return l10n.adaptiveExtraCardioOption1;
      case ExtraCardioHoursOption.h2:
        return l10n.adaptiveExtraCardioOption2;
      case ExtraCardioHoursOption.h3:
        return l10n.adaptiveExtraCardioOption3;
      case ExtraCardioHoursOption.h5:
        return l10n.adaptiveExtraCardioOption5;
      case ExtraCardioHoursOption.h7Plus:
        return l10n.adaptiveExtraCardioOption7Plus;
    }
  }
}
