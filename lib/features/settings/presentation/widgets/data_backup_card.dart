import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';

class DataBackupCard extends StatelessWidget {
  const DataBackupCard({
    super.key,
    required this.isFullBackupRunning,
    required this.onExportPressed,
    required this.onImportPressed,
    required this.onExportEncryptedPressed,
  });

  final bool isFullBackupRunning;
  final VoidCallback? onExportPressed;
  final VoidCallback? onImportPressed;
  final VoidCallback? onExportEncryptedPressed;

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
              l10n.dataManagementBackupTitle,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.dataManagementBackupDescription,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: Text(l10n.data_export_button),
                    onPressed: isFullBackupRunning ? null : onExportPressed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download_for_offline),
                    label: Text(l10n.data_import_button),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                    ),
                    onPressed: isFullBackupRunning ? null : onImportPressed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingS),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.lock_outline),
                label: Text(l10n.exportEncrypted),
                onPressed: isFullBackupRunning ? null : onExportEncryptedPressed,
              ),
            ),
            if (isFullBackupRunning)
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
