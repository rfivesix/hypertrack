import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/glass_progress_bar.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../steps/presentation/steps_module_screen.dart';
import '../../../steps/domain/steps_models.dart';
import '../../../../services/health/steps_sync_service.dart';
import '../diary_view_model.dart';

class StepsSummaryCard extends StatelessWidget {
  const StepsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DiaryViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (viewModel.isStepsWidgetLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SummaryCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(l10n.diarySyncingSteps),
              ],
            ),
          ),
        ),
      );
    }

    if ((viewModel.stepsForSelectedDay ?? 0) <= 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StepsModuleScreen(
                initialScope: StepsScope.day,
                initialDate: viewModel.selectedDate,
              ),
            ),
          );
        },
        child: GlassProgressBar(
          label: l10n.steps,
          unit: 'steps',
          value: (viewModel.stepsForSelectedDay ?? 0).toDouble(),
          target: (viewModel.targetSteps > 0
                  ? viewModel.targetSteps
                  : StepsSyncService.defaultStepsGoal)
              .toDouble(),
          color: theme.colorScheme.primary,
          height: 54,
          borderRadius: DesignConstants.borderRadiusL,
        ),
      ),
    );
  }
}
