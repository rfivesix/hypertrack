import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';

class PriorActivityHelpBlock extends StatelessWidget {
  final AppLocalizations l10n;

  const PriorActivityHelpBlock({
    super.key,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adaptivePriorActivityHelpIntro,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _helpLine(context, l10n.adaptivePriorActivityHelpLowLine),
          const SizedBox(height: 4),
          _helpLine(context, l10n.adaptivePriorActivityHelpModerateLine),
          const SizedBox(height: 4),
          _helpLine(context, l10n.adaptivePriorActivityHelpHighLine),
          const SizedBox(height: 4),
          _helpLine(context, l10n.adaptivePriorActivityHelpVeryHighLine),
        ],
      ),
    );
  }

  Widget _helpLine(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Icon(
            Icons.circle,
            size: 6,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
