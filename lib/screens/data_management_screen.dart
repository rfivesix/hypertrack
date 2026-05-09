// lib/screens/data_management_screen.dart (final and complete)

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../data/backup_manager.dart';
import '../data/import_manager.dart';
import '../generated/app_localizations.dart';
import '../screens/app_initializer_screen.dart';
import 'exercise_mapping_screen.dart';
import '../services/local_app_data_reset_service.dart';
import '../services/workout_session_manager.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import '../data/workout_database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart'; // New
import 'package:flutter/services.dart'; // New (Clipboard)
import '../widgets/glass_bottom_menu.dart';
import '../services/storage/saf_storage_service.dart';

/// A screen for managing application data and backups.
///
/// Provides tools for manual and automated backups (JSON), CSV exports for
/// nutrition and workouts, and importing data from third-party services like Hevy.
class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({
    super.key,
    LocalAppDataResetter? localDataResetter,
    VoidCallback? onResetComplete,
  })  : _localDataResetter = localDataResetter,
        _onResetComplete = onResetComplete;

  final LocalAppDataResetter? _localDataResetter;
  final VoidCallback? _onResetComplete;

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  // Loading states for the different actions
  bool _isFullBackupRunning = false;
  bool _isCsvExportRunning = false;
  bool _isMigrationRunning = false;
  bool _isLocalResetRunning = false;
  String? _autoBackupDir; // New
  String? _lastAutoBackupFilePath;
  String? _lastAutoBackupDirUsed;
  String? _lastAutoBackupError;
  bool _lastAutoBackupUsedFallback = false;
  @override
  void initState() {
    super.initState();
    _loadAutoBackupDir(); // New
  }

  Future<void> _loadAutoBackupDir() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoBackupDir = prefs.getString('auto_backup_dir');
      _lastAutoBackupFilePath = prefs.getString('auto_backup_last_file_path');
      _lastAutoBackupDirUsed = prefs.getString('auto_backup_last_dir_used');
      _lastAutoBackupError = prefs.getString('auto_backup_last_error');
      _lastAutoBackupUsedFallback =
          prefs.getBool('auto_backup_last_used_fallback') ?? false;
    });
  }

  // --- Unchanged: full-backup logic ---
  void _performFullExport() async {
    setState(() => _isFullBackupRunning = true);
    final success = await BackupManager.instance.exportFullBackup();
    if (!mounted) return;
    setState(() => _isFullBackupRunning = false);

    final l10n = AppLocalizations.of(context)!;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.snackbarExportSuccess)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.snackbarExportFailed),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _performFullImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;

    final filePath = result.files.single.path!;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDeleteConfirmation(
      context,
      title: l10n.dialogConfirmTitle,
      content: l10n.dialogConfirmImportContent,
      confirmLabel:
          l10n.dialogButtonOverwrite, // Red button fits well here (warning)
    );

    if (confirmed == true) {
      setState(() => _isFullBackupRunning = true);
      bool success = await BackupManager.instance.importFullBackupAuto(
        filePath,
      );
      if (!success) {
        // File may be encrypted; ask for password (empty = try no password).
        final pw = await _askPassword(title: l10n.dialogEnterPasswordImport);
        if (pw != null) {
          // <-- Important: allow empty values.
          success = await BackupManager.instance.importFullBackupAuto(
            filePath,
            passphrase: pw,
          );
        }
      }

      if (!mounted) return;
      setState(() => _isFullBackupRunning = false); // only once

      if (success) {
        // New: detect unknown exercise names and offer mapping if needed.
        final unknown =
            await WorkoutDatabaseHelper.instance.findUnknownExerciseNames();
        if (!mounted) return;
        if (mounted && unknown.isNotEmpty) {
          /*final bool? changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => ExerciseMappingScreen(unknownNames: unknown),
            ),
          );
          */
          // Optional: check/refresh again after applying, but not required.
        }

        await showGlassBottomMenu<void>(
          context: context,
          title: l10n.snackbarImportSuccessTitle,
          isDismissible: false,
          enableDrag: false,
          contentBuilder: (ctx, close) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.snackbarImportSuccessContent,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.snackbarButtonOK),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.snackbarImportError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Unchanged: Hevy import logic ---
  void _performHevyImport() async {
    setState(() => _isMigrationRunning = true);
    final count = await ImportManager().importHevyCsv();
    if (!mounted) return;
    setState(() => _isMigrationRunning = false);

    if (count > 0) {
      final unknown =
          await WorkoutDatabaseHelper.instance.findUnknownExerciseNames();
      if (mounted && unknown.isNotEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExerciseMappingScreen(unknownNames: unknown),
          ),
        );
      }
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (count > 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.hevyImportSuccess(count))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.hevyImportFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- New: helper method for all CSV exports ---
  void _exportCsv(
    Future<bool> Function() exportFunction,
    String successMessage,
    String failureMessage,
  ) async {
    setState(() => _isCsvExportRunning = true);
    final success = await exportFunction();
    if (!mounted) return;
    setState(() => _isCsvExportRunning = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureMessage), backgroundColor: Colors.orange),
      );
    }
  }
  // lib/screens/data_management_screen.dart

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // This calculation is correct.
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        // l10n.dataHubTitle would be ideal here, but "Data Hub" is also ok.
        title: l10n.dataHubTitle,
      ),
      // SafeArea was removed here. The body is now the SingleChildScrollView directly.
      body: SingleChildScrollView(
        // Its padding logic is correct and preserved.
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- All existing content remains unchanged here ---
            _buildFullBackupCard(context, l10n, theme),
            const SizedBox(height: DesignConstants.spacingL),
            _buildAutoBackupCard(context, l10n, theme),
            const SizedBox(height: DesignConstants.spacingL),
            _buildLocalDataDeletionCard(context, l10n, theme),
            const SizedBox(height: DesignConstants.spacingL),
            _buildCsvExportCard(context, l10n, theme),
            const SizedBox(height: DesignConstants.spacingL),
            _buildMigrationCard(context, l10n, theme),
            const SizedBox(height: DesignConstants.spacingL),
            _buildExerciseMappingCard(context, l10n, theme),
          ],
        ),
      ),
    );
  }
  // --- WIDGET BUILDER ---

  Widget _buildFullBackupCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dataManagementBackupTitle,
              style: theme.textTheme.headlineSmall,
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
                    onPressed: _isFullBackupRunning ? null : _performFullExport,
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
                    onPressed: _isFullBackupRunning ? null : _performFullImport,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingS),
            // New: export encrypted
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.lock_outline),
                label: Text(l10n.exportEncrypted),
                onPressed: _isFullBackupRunning
                    ? null
                    : () async {
                        final pw = await _askPassword(
                          title: l10n.dialogPasswordForExport,
                        );
                        if (pw == null || pw.isEmpty) return;
                        setState(() => _isFullBackupRunning = true);
                        final ok = await BackupManager.instance
                            .exportFullBackupEncrypted(pw);
                        if (!mounted) return;
                        setState(() => _isFullBackupRunning = false);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? l10n.snackbarEncryptedBackupShared
                                  : l10n.exportFailed,
                            ),
                          ),
                        );
                      },
              ),
            ),

            if (_isFullBackupRunning)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCsvExportCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.csvExportTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: DesignConstants.spacingS),
            Text(l10n.csvExportDescription, style: theme.textTheme.bodyMedium),
            const SizedBox(height: DesignConstants.spacingS),
            _buildExportTile(
              icon: Icons.restaurant_menu,
              title: l10n.nutritionDiary,
              onTap: _isCsvExportRunning
                  ? null
                  : () => _exportCsv(
                        BackupManager.instance.exportNutritionAsCsv,
                        l10n.snackbarSharingNutrition,
                        l10n.snackbarExportFailedNoEntries,
                      ),
            ),
            _buildExportTile(
              icon: Icons.monitor_weight_outlined,
              title: l10n.drawerMeasurements,
              onTap: _isCsvExportRunning
                  ? null
                  : () => _exportCsv(
                        BackupManager.instance.exportMeasurementsAsCsv,
                        l10n.snackbarSharingMeasurements,
                        l10n.snackbarExportFailedNoEntries,
                      ),
            ),
            _buildExportTile(
              icon: Icons.fitness_center,
              title: l10n.workoutHistoryTitle,
              onTap: _isCsvExportRunning
                  ? null
                  : () => _exportCsv(
                        BackupManager.instance.exportWorkoutsAsCsv,
                        l10n.snackbarSharingWorkouts,
                        l10n.snackbarExportFailedNoEntries,
                      ),
            ),
            if (_isCsvExportRunning)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMigrationCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.hevyImportTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: DesignConstants.spacingS),
            Text(l10n.hevyImportDescription, style: theme.textTheme.bodyMedium),
            const SizedBox(height: DesignConstants.spacingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sync_alt),
                label: Text(l10n.hevyImportButton),
                onPressed: _isMigrationRunning ? null : _performHevyImport,
              ),
            ),
            if (_isMigrationRunning)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalDataDeletionCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.localDataDeletionCardTitle,
              style: theme.textTheme.headlineSmall,
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
                onPressed:
                    _isLocalResetRunning ? null : _confirmAndDeleteLocalData,
              ),
            ),
            if (_isLocalResetRunning)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteLocalData() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _showLocalDataDeletionConfirmation(l10n);
    if (!confirmed || !mounted) return;

    WorkoutSessionManager? sessionManager;
    try {
      sessionManager = context.read<WorkoutSessionManager>();
    } catch (_) {
      sessionManager = null;
    }

    setState(() => _isLocalResetRunning = true);
    try {
      final resetter = widget._localDataResetter ?? LocalAppDataResetService();
      await resetter.deleteAllLocalAppData();
      await sessionManager?.clearLocalSessionState();

      if (!mounted) return;
      setState(() => _isLocalResetRunning = false);

      if (widget._onResetComplete != null) {
        widget._onResetComplete!();
        return;
      }

      await showGlassBottomMenu<void>(
        context: context,
        title: l10n.localDataDeletionSuccessTitle,
        isDismissible: false,
        enableDrag: false,
        contentBuilder: (ctx, close) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.localDataDeletionSuccessBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.snackbarButtonOK),
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppInitializerScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLocalResetRunning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.localDataDeletionFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showLocalDataDeletionConfirmation(
    AppLocalizations l10n,
  ) async {
    final controller = TextEditingController();
    final result = await showGlassBottomMenu<bool>(
      context: context,
      title: l10n.localDataDeletionConfirmTitle,
      contentBuilder: (ctx, close) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final canConfirm = controller.text.trim() == 'DELETE';
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.localDataDeletionConfirmBody,
                  key: const Key('delete_local_data_warning_copy'),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('delete_local_data_confirmation_field'),
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.localDataDeletionTypeDeleteLabel,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('cancel_delete_local_data_button'),
                        onPressed: () {
                          close();
                          Navigator.of(ctx).pop(false);
                        },
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('confirm_delete_local_data_button'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: canConfirm
                            ? () {
                                close();
                                Navigator.of(ctx).pop(true);
                              }
                            : null,
                        child: Text(l10n.delete),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
    return result ?? false;
  }

  Widget _buildExportTile({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildExerciseMappingCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.mapExercisesTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              l10n.mapExercisesDescription,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignConstants.spacingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.rule_folder_outlined),
                label: Text(l10n.mapExercisesButton),
                onPressed: _openExerciseMapping,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // lib/screens/data_management_screen.dart - excerpt: new card
  Widget _buildAutoBackupCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.autoBackupTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: DesignConstants.spacingS),
            Text(l10n.autoBackupDescription, style: theme.textTheme.bodyMedium),
            const SizedBox(height: DesignConstants.spacingS),
            SelectableText(
              _autoBackupDir ?? l10n.autoBackupDefaultFolder,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: Text(l10n.autoBackupChooseFolder),
                    onPressed: _pickAutoBackupDirectory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: Text(l10n.autoBackupCopyPath),
                    onPressed:
                        (_autoBackupDir == null || _autoBackupDir!.isEmpty)
                            ? null
                            : _copyAutoBackupPathToClipboard,
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
                onPressed: () async {
                  final ok = await BackupManager.instance.runAutoBackupIfDue(
                    interval: const Duration(days: 1),
                    encrypted: false,
                    passphrase: null,
                    retention: 7,
                    dirPath: _autoBackupDir,
                    force: true, // New: run immediately
                  );
                  await _loadAutoBackupDir();
                  if (!mounted) return;
                  final successText = ok
                      ? (_lastAutoBackupFilePath != null &&
                              _lastAutoBackupFilePath!.isNotEmpty
                          ? '${l10n.snackbarAutoBackupSuccess}\n$_lastAutoBackupFilePath'
                          : l10n.snackbarAutoBackupSuccess)
                      : (_lastAutoBackupError != null &&
                              _lastAutoBackupError!.isNotEmpty
                          ? '${l10n.snackbarAutoBackupFailed}\n$_lastAutoBackupError'
                          : l10n.snackbarAutoBackupFailed);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(successText),
                      backgroundColor: ok
                          ? (_lastAutoBackupUsedFallback ? Colors.orange : null)
                          : Colors.red,
                    ),
                  );
                },
              ),
            ),
            if (_lastAutoBackupUsedFallback &&
                _lastAutoBackupDirUsed != null &&
                _lastAutoBackupDirUsed!.isNotEmpty) ...[
              const SizedBox(height: DesignConstants.spacingS),
              Text(
                'Fallback folder used:\n$_lastAutoBackupDirUsed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (_lastAutoBackupFilePath != null &&
                _lastAutoBackupFilePath!.isNotEmpty) ...[
              const SizedBox(height: DesignConstants.spacingS),
              SelectableText(
                _lastAutoBackupFilePath!,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openExerciseMapping() async {
    final unknown =
        await WorkoutDatabaseHelper.instance.findUnknownExerciseNames();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (unknown.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noUnknownExercisesFound)));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseMappingScreen(unknownNames: unknown),
      ),
    );
  }

  Future<void> _pickAutoBackupDirectory() async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    if (Platform.isAndroid) {
      SafPickedDirectory? picked;
      try {
        picked = await SafStorageService.instance.pickDirectory();
      } on MissingPluginException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.autoBackupStoragePickerUnavailable),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } on PlatformException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.autoBackupFolderPickerFailed(e.message ?? e.code),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (picked == null) return;
      final selected = picked;
      await prefs.setString('auto_backup_dir', selected.displayPath);
      await prefs.setString('auto_backup_tree_uri', selected.treeUri);
      setState(() => _autoBackupDir = selected.displayPath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.snackbarAutoBackupFolderSet(selected.displayPath)),
        ),
      );
      return;
    }

    // Non-Android fallback: directory path picker.
    final path = await FilePicker.getDirectoryPath();
    if (path == null) return;
    await prefs.setString('auto_backup_dir', path);
    await prefs.remove('auto_backup_tree_uri');
    setState(() => _autoBackupDir = path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.snackbarAutoBackupFolderSet(path))),
    );
  }

  Future<void> _copyAutoBackupPathToClipboard() async {
    final path = _autoBackupDir;
    final l10n = AppLocalizations.of(context)!;
    if (path == null || path.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: path));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.snackbarPathCopied)));
  }

  Future<String?> _askPassword({required String title}) async {
    final controller = TextEditingController();
    bool obscure = true;
    final l10n = AppLocalizations.of(context)!;

    return showGlassBottomMenu<String?>(
      context: context,
      title: title,
      contentBuilder: (ctx, close) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          close();
                          Navigator.of(ctx).pop(null);
                        },
                        child: Text(l10n.dialogButtonCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final value = controller.text.trim();
                          close();
                          Navigator.of(ctx).pop(value);
                        },
                        child: Text(l10n.snackbarButtonOK),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
