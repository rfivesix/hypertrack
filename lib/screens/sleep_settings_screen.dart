import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../features/sleep/data/persistence/sleep_persistence_models.dart';
import '../features/sleep/platform/permissions/sleep_permission_controller.dart';
import '../features/sleep/platform/permissions/sleep_permission_models.dart';
import '../features/sleep/platform/sleep_sync_service.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';

class SleepSettingsScreen extends StatefulWidget {
  const SleepSettingsScreen({
    super.key,
    SleepSettingsService? sleepSyncService,
    SleepPermissionController? sleepPermissionController,
  })  : _sleepSyncService = sleepSyncService,
        _sleepPermissionController = sleepPermissionController;

  final SleepSettingsService? _sleepSyncService;
  final SleepPermissionController? _sleepPermissionController;

  @override
  State<SleepSettingsScreen> createState() => _SleepSettingsScreenState();
}

class _SleepSettingsScreenState extends State<SleepSettingsScreen> {
  late final SleepSettingsService _sleepSyncService;
  late final SleepPermissionController _sleepPermissionController;
  late final bool _ownsSleepSyncService;
  late final bool _ownsSleepPermissionController;

  bool _sleepTrackingEnabled = false;
  bool _isSleepImporting = false;
  bool _isSleepRawLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _ownsSleepSyncService = widget._sleepSyncService == null;
    _sleepSyncService = widget._sleepSyncService ?? SleepSyncService();
    _ownsSleepPermissionController = widget._sleepPermissionController == null;
    _sleepPermissionController = widget._sleepPermissionController ??
        _sleepSyncService.buildPermissionController();
    _loadSleepSettings();
  }

  @override
  void dispose() {
    if (_ownsSleepPermissionController) {
      _sleepPermissionController.state.dispose();
    }
    if (_ownsSleepSyncService) {
      unawaited(_sleepSyncService.dispose());
    }
    super.dispose();
  }

  Future<void> _loadSleepSettings() async {
    final enabled = await _sleepSyncService.isTrackingEnabled();
    if (!mounted) return;
    setState(() => _sleepTrackingEnabled = enabled);
    await _sleepPermissionController.refresh();
  }

  Future<List<SleepRawImportRecord>> _loadRawSleepImports() async {
    final service = _sleepSyncService;
    if (service is! SleepSyncService) return const <SleepRawImportRecord>[];
    return service.fetchRecentRawImports();
  }

  String _formatRawImport(SleepRawImportRecord record, AppLocalizations l10n) {
    final importedAt = record.importedAt.toLocal().toIso8601String();
    final header = [
      '${l10n.sleepRawImportImportedAt}: $importedAt',
      '${l10n.sleepRawImportStatus}: ${record.importStatus}',
      '${l10n.sleepRawImportSource}: ${record.sourcePlatform}',
      if (record.sourceAppId != null)
        '${l10n.sleepRawImportApp}: ${record.sourceAppId}',
      if (record.sourceConfidence != null)
        '${l10n.sleepRawImportConfidence}: ${record.sourceConfidence}',
    ].join('\n');
    final payload = () {
      try {
        final decoded = jsonDecode(record.payloadJson);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return record.payloadJson;
      }
    }();
    return '$header\n${l10n.sleepRawImportPayload}:\n$payload';
  }

  Future<void> _showRawSleepImports() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isSleepRawLoading) return;
    setState(() => _isSleepRawLoading = true);
    final records = await _loadRawSleepImports();
    if (!mounted) return;
    setState(() => _isSleepRawLoading = false);

    if (records.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.sleepNoRawImportsFound)));
      return;
    }

    final formatted = records
        .map((record) => _formatRawImport(record, l10n))
        .join('\n\n---\n\n');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sleepRawImportsSheetTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      formatted,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _sleepStatusSubtitle(
    SleepPermissionStatus status,
    AppLocalizations l10n,
  ) {
    final custom = status.message;
    if (custom != null && custom.isNotEmpty) return custom;
    return switch (status.state) {
      SleepPermissionState.loading => l10n.sleepStatusChecking,
      SleepPermissionState.ready => l10n.sleepStatusReady,
      SleepPermissionState.denied => l10n.sleepStatusDenied,
      SleepPermissionState.partial => l10n.sleepStatusPartial,
      SleepPermissionState.unavailable => l10n.sleepStatusUnavailable,
      SleepPermissionState.notInstalled => l10n.sleepStatusNotInstalled,
      SleepPermissionState.technicalError => l10n.sleepStatusTechnicalError,
    };
  }

  IconData _sleepStatusIcon(SleepPermissionState state) {
    return switch (state) {
      SleepPermissionState.ready => Icons.check_circle_outline,
      SleepPermissionState.loading => Icons.hourglass_bottom,
      SleepPermissionState.denied => Icons.block_outlined,
      SleepPermissionState.partial => Icons.warning_amber_outlined,
      SleepPermissionState.unavailable => Icons.mobiledata_off_outlined,
      SleepPermissionState.notInstalled => Icons.download_outlined,
      SleepPermissionState.technicalError => Icons.error_outline,
    };
  }

  Color _sleepStatusColor(BuildContext context, SleepPermissionState state) {
    final scheme = Theme.of(context).colorScheme;
    return switch (state) {
      SleepPermissionState.ready => Colors.green,
      SleepPermissionState.loading => scheme.outline,
      SleepPermissionState.denied => scheme.error,
      SleepPermissionState.partial => Colors.orange,
      SleepPermissionState.unavailable => scheme.outline,
      SleepPermissionState.notInstalled => scheme.secondary,
      SleepPermissionState.technicalError => scheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_hasChanges);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlobalAppBar(
          title: l10n.sleepSettingsSectionTitle,
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
        ),
        body: ListView(
          padding: DesignConstants.cardPadding.copyWith(
            top: DesignConstants.cardPadding.top + topPadding,
          ),
          children: [
            _buildSectionTitle(context, l10n.sleepSettingsSectionTitle),
            ValueListenableBuilder<SleepPermissionStatus>(
              valueListenable: _sleepPermissionController.state,
              builder: (context, permission, _) {
                return SummaryCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.bedtime_outlined),
                        title: Text(
                          l10n.sleepEnableTrackingTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(l10n.sleepEnableTrackingSubtitle),
                        value: _sleepTrackingEnabled,
                        onChanged: (value) async {
                          final wasEnabled = _sleepTrackingEnabled;
                          await _sleepSyncService.setTrackingEnabled(value);
                          if (value && !wasEnabled) {
                            await _sleepPermissionController.requestAccess();
                          }
                          await _sleepPermissionController.refresh();
                          if (!mounted) return;
                          setState(() {
                            _sleepTrackingEnabled = value;
                            _hasChanges = true;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.health_and_safety_outlined),
                        title: Text(
                          l10n.sleepHealthConnectionStatusTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(_sleepStatusSubtitle(permission, l10n)),
                        trailing: Icon(
                          _sleepStatusIcon(permission.state),
                          color: _sleepStatusColor(context, permission.state),
                        ),
                      ),
                      if (permission.state == SleepPermissionState.ready)
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: Text(
                            l10n.sleepDataStatusTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(l10n.sleepDataStatusSubtitle),
                        ),
                      if (permission.state == SleepPermissionState.denied ||
                          permission.state == SleepPermissionState.partial)
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: Text(
                            l10n.sleepNoPermissionTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(l10n.sleepNoPermissionSubtitle),
                        ),
                      if (permission.state ==
                              SleepPermissionState.unavailable ||
                          permission.state == SleepPermissionState.notInstalled)
                        ListTile(
                          leading: const Icon(Icons.mobiledata_off_outlined),
                          title: Text(
                            l10n.sleepFeatureUnavailableTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(l10n.sleepFeatureUnavailableSubtitle),
                        ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_open_outlined),
                        title: Text(l10n.sleepRequestAccessTitle),
                        subtitle: Text(l10n.sleepRequestAccessSubtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await _sleepPermissionController.requestAccess();
                          if (!mounted) return;
                          setState(() {});
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.sync),
                        title: Text(l10n.sleepImportNowTitle),
                        subtitle: Text(l10n.sleepImportNowSubtitle),
                        trailing: _isSleepImporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _isSleepImporting
                            ? null
                            : () async {
                                setState(() => _isSleepImporting = true);
                                final result =
                                    await _sleepSyncService.importRecent(
                                  lookbackDays: 36500,
                                );
                                if (!mounted) return;
                                setState(() {
                                  _isSleepImporting = false;
                                  _hasChanges = true;
                                });
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result.success
                                          ? l10n.sleepImportFinishedSessions(
                                              result.importedSessions,
                                            )
                                          : (result.message ??
                                              l10n.sleepImportUnavailableCheckPermissions),
                                    ),
                                  ),
                                );
                                await _sleepPermissionController.refresh();
                              },
                      ),
                      ListTile(
                        leading: const Icon(Icons.data_object_outlined),
                        title: Text(l10n.sleepRawImportsTitle),
                        subtitle: Text(l10n.sleepRawImportsSubtitle),
                        trailing: _isSleepRawLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _isSleepRawLoading ? null : _showRawSleepImports,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
