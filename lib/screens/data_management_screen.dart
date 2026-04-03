// lib/screens/data_management_screen.dart (Final & Vollständig)

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../data/backup_manager.dart';
import '../data/import_manager.dart';
import '../generated/app_localizations.dart';
import 'exercise_mapping_screen.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import '../data/workout_database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEU
import 'package:flutter/services.dart'; // NEU (Clipboard)
import '../widgets/glass_bottom_menu.dart';
import '../services/storage/saf_storage_service.dart';

/// A screen for managing application data and backups.
///
/// Provides tools for manual and automated backups (JSON), CSV exports for
/// nutrition and workouts, and importing data from third-party services like Hevy.
class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  // Lade-Zustände für die verschiedenen Aktionen
  bool _isFullBackupRunning = false;
  bool _isCsvExportRunning = false;
  bool _isMigrationRunning = false;
  String? _autoBackupDir; // NEU
  String? _lastAutoBackupFilePath;
  String? _lastAutoBackupDirUsed;
  String? _lastAutoBackupError;
  bool _lastAutoBackupUsedFallback = false;
  @override
  void initState() {
    super.initState();
    _loadAutoBackupDir(); // NEU
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

  // --- UNVERÄNDERT: Logik für Komplett-Backup ---
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDeleteConfirmation(
      context,
      title: l10n.dialogConfirmTitle,
      content: l10n.dialogConfirmImportContent,
      confirmLabel:
          l10n.dialogButtonOverwrite, // Roter Button passt hier gut (Warnung)
    );

    if (confirmed == true) {
      setState(() => _isFullBackupRunning = true);
      bool success = await BackupManager.instance.importFullBackupAuto(
        filePath,
      );
      if (!success) {
        // Datei könnte verschlüsselt sein – Passwort abfragen (leer = “kein Passwort” versuchen)
        final pw = await _askPassword(title: l10n.dialogEnterPasswordImport);
        if (pw != null) {
          // <-- wichtig: leer zulassen
          success = await BackupManager.instance.importFullBackupAuto(
            filePath,
            passphrase: pw,
          );
        }
      }

      if (!mounted) return;
      setState(() => _isFullBackupRunning = false); // nur einmal

      if (success) {
        // Neu: Unbekannte Übungsnamen ermitteln und ggf. Mapping anbieten
        final unknown =
            await WorkoutDatabaseHelper.instance.findUnknownExerciseNames();
        if (mounted && unknown.isNotEmpty) {
          /*final bool? changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => ExerciseMappingScreen(unknownNames: unknown),
            ),
          );
          */
          // Optional: Nach Anwendung erneut prüfen/refreshen, aber keine Pflicht.
        }

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(l10n.snackbarImportSuccessTitle),
            content: Text(l10n.snackbarImportSuccessContent),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.snackbarButtonOK),
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

  // --- UNVERÄNDERT: Logik für Hevy-Import ---
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

  // --- NEU: Helfer-Methode für alle CSV-Exporte ---
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

    // Diese Berechnung ist korrekt.
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        // l10n.dataHubTitle wäre hier ideal, aber "Data Hub" ist auch ok
        title: l10n.dataHubTitle,
      ),
      // Das SafeArea-Widget wurde hier entfernt. Der Body ist jetzt direkt der SingleChildScrollView.
      body: SingleChildScrollView(
        // Ihre Padding-Logik ist korrekt und wird beibehalten.
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Ihr gesamter Inhalt bleibt hier unverändert ---
            _buildFullBackupCard(context, l10n, theme),
            const SizedBox(height: DesignConstants.spacingL),
            _buildAutoBackupCard(context, l10n, theme),
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
            // NEU: Verschlüsselt exportieren
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
                        ScaffoldMessenger.of(context).showSnackBar(
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

  // lib/screens/data_management_screen.dart – Auszug: neue Card
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
                    force: true, // NEU: sofort ausführen
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
                  ScaffoldMessenger.of(context).showSnackBar(
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
    final l10n = AppLocalizations.of(context)!;
    if (!mounted) return;
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
          const SnackBar(
            content: Text(
              'Storage picker unavailable. Please fully restart/reinstall the app after updating.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } on PlatformException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Folder picker failed: ${e.message ?? e.code}'),
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
    final path = await FilePicker.platform.getDirectoryPath();
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
