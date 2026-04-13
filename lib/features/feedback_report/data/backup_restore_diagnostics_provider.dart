import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/backup_manager.dart';
import '../domain/feedback_report_builder.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

class BackupRestoreDiagnosticsProvider
    implements FeedbackReportDiagnosticsProvider {
  final SharedPreferencesLoader _prefsLoader;

  BackupRestoreDiagnosticsProvider({
    SharedPreferencesLoader? prefsLoader,
  }) : _prefsLoader = prefsLoader ?? SharedPreferences.getInstance;

  @override
  Future<List<String>> buildLines({required DateTime now}) async {
    final prefs = await _prefsLoader();

    final lastAutoBackupMs = prefs.getInt('auto_backup_last_ms');
    final lastAutoBackupFilePath =
        prefs.getString('auto_backup_last_file_path');
    final lastAutoBackupError = prefs.getString('auto_backup_last_error');
    final autoBackupDir = prefs.getString('auto_backup_dir');
    final autoBackupTreeUri = prefs.getString('auto_backup_tree_uri');
    final usedFallback =
        prefs.getBool('auto_backup_last_used_fallback') ?? false;

    final hasConfiguredFolder = (autoBackupDir?.trim().isNotEmpty ?? false) ||
        (autoBackupTreeUri?.trim().isNotEmpty ?? false);

    final lines = <String>[
      'feature_available: yes',
      'backup_schema_version: ${BackupManager.currentSchemaVersion}',
      'auto_backup_folder_configured: ${_yesNo(hasConfiguredFolder)}',
      'auto_backup_last_run_at: ${_fromEpochMs(lastAutoBackupMs)}',
      'auto_backup_last_export_file: ${_basenameOrUnavailable(lastAutoBackupFilePath)}',
      'auto_backup_last_used_fallback: ${_yesNo(usedFallback)}',
      'last_backup_or_export_timestamp: ${_fromEpochMs(lastAutoBackupMs)}',
      'last_restore_or_import_timestamp: unavailable (not tracked)',
      'last_restore_or_import_status: unavailable (not tracked)',
    ];

    final hasSuccessfulAutoBackup =
        lastAutoBackupMs != null && lastAutoBackupMs > 0;
    final hasError = (lastAutoBackupError?.trim().isNotEmpty ?? false);
    final status = hasError
        ? 'failed'
        : hasSuccessfulAutoBackup
            ? 'success'
            : 'unavailable';
    lines.add('last_backup_status: $status');

    if (hasError) {
      lines.add('last_error_summary: ${_sanitizeError(lastAutoBackupError!)}');
    }

    return lines;
  }

  String _yesNo(bool value) => value ? 'yes' : 'no';

  String _fromEpochMs(int? epochMs) {
    if (epochMs == null || epochMs <= 0) {
      return 'unavailable';
    }
    return DateTime.fromMillisecondsSinceEpoch(epochMs)
        .toUtc()
        .toIso8601String();
  }

  String _basenameOrUnavailable(String? filePath) {
    final trimmed = filePath?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'unavailable';
    }
    return p.basename(trimmed);
  }

  String _sanitizeError(String error) {
    final compact = error.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 180) {
      return compact;
    }
    return '${compact.substring(0, 180)}...';
  }
}
