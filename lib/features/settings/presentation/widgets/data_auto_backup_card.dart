import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';

class DataAutoBackupCard extends StatelessWidget {
  const DataAutoBackupCard({
    super.key,
    required this.autoBackupDir,
    required this.lastAutoBackupFilePath,
    required this.lastAutoBackupDirUsed,
    required this.lastAutoBackupUsedFallback,
    required this.onPickDirectory,
    required this.onCopyPath,
    required this.onRunNow,
  });

  final String? autoBackupDir;
  final String? lastAutoBackupFilePath;
  final String? lastAutoBackupDirUsed;
  final bool lastAutoBackupUsedFallback;
  final VoidCallback? onPickDirectory;
  final VoidCallback? onCopyPath;
  final VoidCallback? onRunNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.autoBackupTitle,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.autoBackupDescription,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignConstants.spacingS),
            SelectableText(
              autoBackupDir ?? l10n.autoBackupDefaultFolder,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: Text(l10n.autoBackupChooseFolder),
                    onPressed: onPickDirectory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: Text(l10n.autoBackupCopyPath),
                    onPressed: (autoBackupDir == null || autoBackupDir!.isEmpty)
                        ? null
                        : onCopyPath,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingM),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.backup),
                label: Text(l10n.autoBackupRunNow),
                onPressed: onRunNow,
              ),
            ),
            if (lastAutoBackupUsedFallback &&
                lastAutoBackupDirUsed != null &&
                lastAutoBackupDirUsed!.isNotEmpty) ...[
              const SizedBox(height: DesignConstants.spacingS),
              Text(
                'Fallback folder used:\n$lastAutoBackupDirUsed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (lastAutoBackupFilePath != null &&
                lastAutoBackupFilePath!.isNotEmpty) ...[
              const SizedBox(height: DesignConstants.spacingS),
              SelectableText(
                lastAutoBackupFilePath!,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
