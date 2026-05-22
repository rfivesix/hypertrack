import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';

class LocalDataDeletionCard extends StatelessWidget {
  const LocalDataDeletionCard({
    super.key,
    required this.isLocalResetRunning,
    required this.onDeletePressed,
  });

  final bool isLocalResetRunning;
  final VoidCallback? onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.localDataDeletionCardTitle,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.localDataDeletionCardDescription,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignConstants.spacingL),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('delete_all_local_app_data_button'),
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(l10n.deleteAllLocalAppData),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                onPressed: isLocalResetRunning ? null : onDeletePressed,
              ),
            ),
            if (isLocalResetRunning)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
