import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';

class StepsPeriodNavigator extends StatelessWidget {
  const StepsPeriodNavigator({
    super.key,
    required this.periodLabel,
    required this.onPrevious,
    required this.onNext,
    required this.canForward,
  });

  final String periodLabel;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final bool canForward;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: AppLocalizations.of(context)!.stepsModulePrevious,
          ),
          Expanded(
            child: Text(
              periodLabel,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: canForward ? onNext : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: AppLocalizations.of(context)!.stepsModuleNext,
          ),
        ],
      ),
    );
  }
}
