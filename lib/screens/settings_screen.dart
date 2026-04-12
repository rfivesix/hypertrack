// lib/screens/settings_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import 'ai_settings_screen.dart';
import 'data_management_screen.dart';
import '../services/theme_service.dart';
import '../util/design_constants.dart';
import '../widgets/summary_card.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../widgets/global_app_bar.dart';
import '../services/health/health_models.dart';
import '../services/health/health_platform_steps.dart';
import '../services/health/steps_sync_service.dart';
import '../features/sleep/platform/sleep_sync_service.dart';
import '../features/sleep/platform/permissions/sleep_permission_controller.dart';
import '../features/sleep/platform/permissions/sleep_permission_models.dart';
import '../features/sleep/data/persistence/sleep_persistence_models.dart';
import '../health_export/adapters/apple_health/apple_health_export_adapter.dart';
import '../health_export/adapters/health_connect/health_connect_export_adapter.dart';
import '../health_export/export_service.dart';
import '../health_export/models/export_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A screen for configuring application-wide preferences.
///
/// Includes theme selection (light/dark/system), visual style toggles,
/// and navigation to data management (backup/import) and legal information.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    SleepSettingsService? sleepSyncService,
    SleepPermissionController? sleepPermissionController,
  })  : _sleepSyncService = sleepSyncService,
        _sleepPermissionController = sleepPermissionController;

  final SleepSettingsService? _sleepSyncService;
  final SleepPermissionController? _sleepPermissionController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _showSugarInDiaryOverviewPrefKey =
      'showSugarInDiaryOverview';
  String _appVersion = '';
  final StepsSyncService _stepsSyncService = StepsSyncService();
  late final SleepSettingsService _sleepSyncService;
  bool _stepsTrackingEnabled = true;
  bool _sleepTrackingEnabled = false;
  StepsProviderFilter _stepsProviderFilter = StepsProviderFilter.all;
  StepsSourcePolicy _stepsSourcePolicy = StepsSourcePolicy.autoDominant;
  late final SleepPermissionController _sleepPermissionController;
  late final bool _ownsSleepSyncService;
  late final bool _ownsSleepPermissionController;
  bool _isSleepImporting = false;
  bool _isSleepRawLoading = false;
  late final HealthExportService _healthExportService;
  Map<HealthExportPlatform, HealthExportPlatformStatus> _exportStatuses = {
    for (final platform in HealthExportPlatform.values)
      platform: HealthExportPlatformStatus.initial(platform),
  };
  bool _appleExportEnabled = false;
  bool _healthConnectExportEnabled = false;
  bool _isAppleExporting = false;
  bool _isHealthConnectExporting = false;
  bool _showSugarInDiaryOverview = false;

  /// Flag for parent screens to know steps settings changed and data should be refreshed.
  bool hasStepsSettingsChanged = false;

  @override
  void initState() {
    super.initState();
    _ownsSleepSyncService = widget._sleepSyncService == null;
    _sleepSyncService = widget._sleepSyncService ?? SleepSyncService();
    _ownsSleepPermissionController = widget._sleepPermissionController == null;
    _sleepPermissionController = widget._sleepPermissionController ??
        _sleepSyncService.buildPermissionController();
    _healthExportService = HealthExportService(
      adapters: [AppleHealthExportAdapter(), HealthConnectExportAdapter()],
    );
    _loadAppVersion();
    _loadStepsSettings();
    _loadSleepSettings();
    _loadHealthExportSettings();
    _loadDiaryOverviewSettings();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = "${packageInfo.version} (${packageInfo.buildNumber})";
      });
    }
  }

  Future<void> _loadStepsSettings() async {
    final enabled = await _stepsSyncService.isTrackingEnabled();
    final providerFilter = await _stepsSyncService.getProviderFilter();
    final sourcePolicy = await _stepsSyncService.getSourcePolicy();
    if (!mounted) return;
    setState(() {
      _stepsTrackingEnabled = enabled;
      _stepsProviderFilter = providerFilter;
      _stepsSourcePolicy = sourcePolicy;
    });
  }

  Future<void> _loadSleepSettings() async {
    final enabled = await _sleepSyncService.isTrackingEnabled();
    if (!mounted) return;
    setState(() => _sleepTrackingEnabled = enabled);
    await _sleepPermissionController.refresh();
  }

  Future<void> _loadHealthExportSettings() async {
    final appleEnabled = await _healthExportService.isPlatformEnabled(
      HealthExportPlatform.appleHealth,
    );
    final healthConnectEnabled = await _healthExportService.isPlatformEnabled(
      HealthExportPlatform.healthConnect,
    );
    final statuses = await _healthExportService.getStatuses();
    if (!mounted) return;
    setState(() {
      _appleExportEnabled = appleEnabled;
      _healthConnectExportEnabled = healthConnectEnabled;
      _exportStatuses = statuses;
    });
  }

  Future<void> _loadDiaryOverviewSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _showSugarInDiaryOverview =
          prefs.getBool(_showSugarInDiaryOverviewPrefKey) ?? false;
    });
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sleepNoRawImportsFound)));
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
                  style: TextStyle(fontWeight: FontWeight.bold),
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

  Future<void> _toggleHealthExport({
    required HealthExportPlatform platform,
    required bool enabled,
  }) async {
    if (enabled) {
      final permission = await _healthExportService.requestPermissions(
        platform,
      );
      if (!permission.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(permission.message ?? 'Permission denied')),
        );
      }
    } else {
      await _healthExportService.setPlatformEnabled(platform, false);
    }
    await _loadHealthExportSettings();
    hasStepsSettingsChanged = true;
  }

  Future<void> _exportNow(HealthExportPlatform platform) async {
    if (!mounted) return;
    setState(() {
      if (platform == HealthExportPlatform.appleHealth) {
        _isAppleExporting = true;
      } else {
        _isHealthConnectExporting = true;
      }
    });
    final result = await _healthExportService.exportNow(platform);
    await _loadHealthExportSettings();
    if (!mounted) return;
    setState(() {
      if (platform == HealthExportPlatform.appleHealth) {
        _isAppleExporting = false;
      } else {
        _isHealthConnectExporting = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_healthExportResultMessage(result, context))),
    );
    hasStepsSettingsChanged = true;
  }

  bool _isGerman(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'de';

  String _exportPlatformTitle(HealthExportPlatform platform, bool isGerman) {
    return switch (platform) {
      HealthExportPlatform.appleHealth =>
        isGerman ? 'Apple Health Export' : 'Apple Health export',
      HealthExportPlatform.healthConnect =>
        isGerman ? 'Health Connect Export' : 'Health Connect export',
    };
  }

  String _domainLabel(HealthExportDomain domain, bool isGerman) {
    return switch (domain) {
      HealthExportDomain.measurements =>
        isGerman ? 'Messwerte' : 'Measurements',
      HealthExportDomain.nutritionHydration =>
        isGerman ? 'Ernährung & Hydration' : 'Nutrition & hydration',
      HealthExportDomain.workouts => isGerman ? 'Workouts' : 'Workouts',
    };
  }

  String _stateLabel(HealthExportState state, bool isGerman) {
    return switch (state) {
      HealthExportState.idle => isGerman ? 'Leerlauf' : 'Idle',
      HealthExportState.exporting => isGerman ? 'Export läuft' : 'Exporting',
      HealthExportState.success => isGerman ? 'Erfolgreich' : 'Success',
      HealthExportState.failed => isGerman ? 'Fehlgeschlagen' : 'Failed',
      HealthExportState.disabled => isGerman ? 'Deaktiviert' : 'Disabled',
    };
  }

  IconData _exportStateIcon(HealthExportState state) {
    return switch (state) {
      HealthExportState.success => Icons.check_circle_outline,
      HealthExportState.exporting => Icons.sync,
      HealthExportState.failed => Icons.error_outline,
      HealthExportState.disabled => Icons.toggle_off_outlined,
      HealthExportState.idle => Icons.hourglass_empty,
    };
  }

  Color _exportStateColor(BuildContext context, HealthExportState state) {
    final scheme = Theme.of(context).colorScheme;
    return switch (state) {
      HealthExportState.success => Colors.green,
      HealthExportState.exporting => scheme.primary,
      HealthExportState.failed => scheme.error,
      HealthExportState.disabled => scheme.outline,
      HealthExportState.idle => scheme.outline,
    };
  }

  String _healthExportResultMessage(
    HealthExportResult result,
    BuildContext context,
  ) {
    if (result.success) {
      return _isGerman(context) ? 'Export abgeschlossen' : 'Export complete';
    }
    return result.message ??
        (_isGerman(context) ? 'Export fehlgeschlagen' : 'Export failed');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final isGerman = localeCode.toLowerCase() == 'de';
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final themeService = Provider.of<ThemeService>(context);
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.settingsTitle,
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(hasStepsSettingsChanged),
        ),
      ),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          _buildSectionTitle(context, l10n.settingsAppearance),
          SummaryCard(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeSystem),
                  value: ThemeMode.system,
                  groupValue: themeService.themeMode,
                  onChanged: (value) => themeService.setThemeMode(value!),
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeLight),
                  value: ThemeMode.light,
                  groupValue: themeService.themeMode,
                  onChanged: (value) => themeService.setThemeMode(value!),
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.themeDark),
                  value: ThemeMode.dark,
                  groupValue: themeService.themeMode,
                  onChanged: (value) => themeService.setThemeMode(value!),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          l10n.settingsVisualStyleTitle,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      RadioListTile<int>(
                        title: Text(
                          l10n.settingsVisualStyleStandard,
                        ), // LOKALISIERT
                        value: 0,
                        groupValue: themeService.visualStyle,
                        onChanged: (value) =>
                            themeService.setVisualStyle(value!),
                      ),
                      RadioListTile<int>(
                        title: Text(
                          l10n.settingsVisualStyleLiquid,
                        ), // LOKALISIERT
                        subtitle: Text(
                          l10n.settingsVisualStyleLiquidDesc,
                        ), // LOKALISIERT
                        value: 1,
                        groupValue: themeService.visualStyle,
                        onChanged: (value) =>
                            themeService.setVisualStyle(value!),
                      ),
                      if (isAndroid) ...[
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(Icons.palette_outlined),
                          title: Text(
                            l10n.settingsMaterialColorsTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(l10n.settingsMaterialColorsSubtitle),
                          value: themeService.materialColorsEnabled,
                          onChanged: (value) =>
                              themeService.setMaterialColorsEnabled(value),
                        ),
                      ],
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.vibration_outlined),
                        title: Text(
                          isGerman ? 'Haptisches Feedback' : 'Haptic feedback',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          isGerman
                              ? 'Leichte Vibrationen bei Bestätigungen und KI-Warten'
                              : 'Light vibrations for confirmations and AI waiting',
                        ),
                        value: themeService.hapticsEnabled,
                        onChanged: (value) =>
                            themeService.setHapticsEnabled(value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _buildSectionTitle(context, l10n.backup_and_import),
          _buildNavigationCard(
            context: context,
            icon: Icons.import_export_rounded,
            title: l10n.backup_and_import,
            subtitle: l10n.backup_and_import_description,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DataManagementScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _buildSectionTitle(context, isGerman ? 'Schritte' : 'Steps'),
          SummaryCard(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.directions_walk_rounded),
                  title: Text(
                    isGerman
                        ? 'Schritte-Tracking aktivieren'
                        : 'Enable steps tracking',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isGerman
                        ? 'Schrittdaten aus Apple Health / Health Connect lesen'
                        : 'Read step data from Apple Health / Health Connect',
                  ),
                  value: _stepsTrackingEnabled,
                  onChanged: (value) async {
                    await _stepsSyncService.setTrackingEnabled(value);
                    hasStepsSettingsChanged = true;
                    if (!mounted) return;
                    setState(() => _stepsTrackingEnabled = value);

                    // Kick off permission prompt and first sync when enabling.
                    if (value) {
                      const platform = HealthPlatformSteps();
                      final availability = await platform.getAvailability();
                      if (availability == StepsAvailability.available) {
                        await platform.requestPermissions();
                        // Trigger first sync in background.
                        _stepsSyncService.sync();
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isGerman ? 'Quellenrichtlinie' : 'Source policy',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                RadioListTile<StepsSourcePolicy>(
                  title: Text(
                    isGerman
                        ? 'Auto (dominante Quelle)'
                        : 'Auto (dominant source)',
                  ),
                  subtitle: Text(
                    isGerman
                        ? 'Empfohlen: eine Quelle pro Tag, um Doppelzählungen zu vermeiden.'
                        : 'Recommended: use one source per day to avoid overlap inflation.',
                  ),
                  value: StepsSourcePolicy.autoDominant,
                  groupValue: _stepsSourcePolicy,
                  onChanged: (value) async {
                    if (value == null) return;
                    await _stepsSyncService.setSourcePolicy(value);
                    hasStepsSettingsChanged = true;
                    if (!mounted) return;
                    setState(() => _stepsSourcePolicy = value);
                  },
                ),
                RadioListTile<StepsSourcePolicy>(
                  title: Text(
                    isGerman
                        ? 'Zusammenführen (max pro Stunde)'
                        : 'Merge (max per hour)',
                  ),
                  subtitle: Text(
                    isGerman
                        ? 'Quellen kombinieren, indem pro Stunde der höchste Wert verwendet wird.'
                        : 'Combine sources by taking the highest hourly bucket.',
                  ),
                  value: StepsSourcePolicy.maxPerHour,
                  groupValue: _stepsSourcePolicy,
                  onChanged: (value) async {
                    if (value == null) return;
                    await _stepsSyncService.setSourcePolicy(value);
                    hasStepsSettingsChanged = true;
                    if (!mounted) return;
                    setState(() => _stepsSourcePolicy = value);
                  },
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isGerman ? 'Provider-Filter' : 'Provider filter',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                RadioListTile<StepsProviderFilter>(
                  title: Text(isGerman ? 'Alle' : 'All'),
                  value: StepsProviderFilter.all,
                  groupValue: _stepsProviderFilter,
                  onChanged: (value) async {
                    if (value == null) return;
                    await _stepsSyncService.setProviderFilter(value);
                    hasStepsSettingsChanged = true;
                    if (!mounted) return;
                    setState(() => _stepsProviderFilter = value);
                  },
                ),
                RadioListTile<StepsProviderFilter>(
                  title: const Text('Apple Health'),
                  value: StepsProviderFilter.apple,
                  groupValue: _stepsProviderFilter,
                  onChanged: (value) async {
                    if (value == null) return;
                    await _stepsSyncService.setProviderFilter(value);
                    if (!mounted) return;
                    setState(() => _stepsProviderFilter = value);
                  },
                ),
                RadioListTile<StepsProviderFilter>(
                  title: const Text('Health Connect'),
                  value: StepsProviderFilter.google,
                  groupValue: _stepsProviderFilter,
                  onChanged: (value) async {
                    if (value == null) return;
                    await _stepsSyncService.setProviderFilter(value);
                    if (!mounted) return;
                    setState(() => _stepsProviderFilter = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _buildSectionTitle(context, isGerman ? 'Tagebuch' : 'Diary'),
          SummaryCard(
            child: SwitchListTile(
              secondary: const Icon(Icons.monitor_heart_outlined),
              title: Text(
                isGerman
                    ? 'Zucker in Tagebuch-Übersicht anzeigen'
                    : 'Show sugar in Diary overview',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isGerman
                    ? 'Blendet Zucker in der oberen Tagesübersicht ein'
                    : 'Shows sugar in the top daily overview section',
              ),
              value: _showSugarInDiaryOverview,
              onChanged: (value) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_showSugarInDiaryOverviewPrefKey, value);
                hasStepsSettingsChanged = true;
                if (!mounted) return;
                setState(() => _showSugarInDiaryOverview = value);
              },
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          const SizedBox(height: DesignConstants.spacingXL),
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
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(l10n.sleepEnableTrackingSubtitle),
                      value: _sleepTrackingEnabled,
                      onChanged: (value) async {
                        final wasEnabled = _sleepTrackingEnabled;
                        await _sleepSyncService.setTrackingEnabled(value);
                        hasStepsSettingsChanged = true;
                        if (value && !wasEnabled) {
                          await _sleepPermissionController.requestAccess();
                        }
                        await _sleepPermissionController.refresh();
                        if (!mounted) return;
                        setState(() => _sleepTrackingEnabled = value);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.health_and_safety_outlined),
                      title: Text(
                        l10n.sleepHealthConnectionStatusTitle,
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(l10n.sleepDataStatusSubtitle),
                      ),
                    if (permission.state == SleepPermissionState.denied ||
                        permission.state == SleepPermissionState.partial)
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: Text(
                          l10n.sleepNoPermissionTitle,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(l10n.sleepNoPermissionSubtitle),
                      ),
                    if (permission.state == SleepPermissionState.unavailable ||
                        permission.state == SleepPermissionState.notInstalled)
                      ListTile(
                        leading: const Icon(Icons.mobiledata_off_outlined),
                        title: Text(
                          l10n.sleepFeatureUnavailableTitle,
                          style: TextStyle(fontWeight: FontWeight.bold),
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _isSleepImporting
                          ? null
                          : () async {
                              setState(() => _isSleepImporting = true);
                              final result =
                                  await _sleepSyncService.importRecent(
                                // Manual import should backfill full history.
                                // Auto/periodic import remains 30 days.
                                lookbackDays: 36500,
                              );
                              if (!mounted) return;
                              setState(() => _isSleepImporting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
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
                              hasStepsSettingsChanged = true;
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _isSleepRawLoading ? null : _showRawSleepImports,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _buildSectionTitle(
            context,
            _isGerman(context) ? 'Health Export' : 'Health export',
          ),
          SummaryCard(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.favorite_outline),
                  title: Text(
                    _exportPlatformTitle(
                      HealthExportPlatform.appleHealth,
                      _isGerman(context),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _isGerman(context)
                        ? 'Einweg-Export von Hypertrack nach Apple Health'
                        : 'One-way export from Hypertrack to Apple Health',
                  ),
                  value: _appleExportEnabled,
                  onChanged: (value) => _toggleHealthExport(
                    platform: HealthExportPlatform.appleHealth,
                    enabled: value,
                  ),
                ),
                ListTile(
                  leading: Icon(
                    _exportStateIcon(
                      _exportStatuses[HealthExportPlatform.appleHealth]
                              ?.statusFor(HealthExportDomain.measurements)
                              .state ??
                          HealthExportState.idle,
                    ),
                    color: _exportStateColor(
                      context,
                      _exportStatuses[HealthExportPlatform.appleHealth]
                              ?.statusFor(HealthExportDomain.measurements)
                              .state ??
                          HealthExportState.idle,
                    ),
                  ),
                  title: Text(
                    _isGerman(context)
                        ? 'Export-Status Apple Health'
                        : 'Apple Health export status',
                  ),
                  subtitle: Text(
                    HealthExportDomain.values.map((domain) {
                      final status =
                          _exportStatuses[HealthExportPlatform.appleHealth]
                              ?.statusFor(domain);
                      return '${_domainLabel(domain, _isGerman(context))}: ${_stateLabel(status?.state ?? HealthExportState.idle, _isGerman(context))}';
                    }).join(' · '),
                  ),
                  trailing: _isAppleExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _appleExportEnabled
                      ? () => _exportNow(HealthExportPlatform.appleHealth)
                      : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.favorite_border),
                  title: Text(
                    _exportPlatformTitle(
                      HealthExportPlatform.healthConnect,
                      _isGerman(context),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _isGerman(context)
                        ? 'Einweg-Export von Hypertrack nach Health Connect'
                        : 'One-way export from Hypertrack to Health Connect',
                  ),
                  value: _healthConnectExportEnabled,
                  onChanged: (value) => _toggleHealthExport(
                    platform: HealthExportPlatform.healthConnect,
                    enabled: value,
                  ),
                ),
                ListTile(
                  leading: Icon(
                    _exportStateIcon(
                      _exportStatuses[HealthExportPlatform.healthConnect]
                              ?.statusFor(HealthExportDomain.measurements)
                              .state ??
                          HealthExportState.idle,
                    ),
                    color: _exportStateColor(
                      context,
                      _exportStatuses[HealthExportPlatform.healthConnect]
                              ?.statusFor(HealthExportDomain.measurements)
                              .state ??
                          HealthExportState.idle,
                    ),
                  ),
                  title: Text(
                    _isGerman(context)
                        ? 'Export-Status Health Connect'
                        : 'Health Connect export status',
                  ),
                  subtitle: Text(
                    HealthExportDomain.values.map((domain) {
                      final status =
                          _exportStatuses[HealthExportPlatform.healthConnect]
                              ?.statusFor(domain);
                      return '${_domainLabel(domain, _isGerman(context))}: ${_stateLabel(status?.state ?? HealthExportState.idle, _isGerman(context))}';
                    }).join(' · '),
                  ),
                  trailing: _isHealthConnectExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _healthConnectExportEnabled
                      ? () => _exportNow(HealthExportPlatform.healthConnect)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _buildSectionTitle(context, l10n.aiSettingsTitle),
          _buildNavigationCard(
            context: context,
            icon: Icons.auto_awesome,
            title: l10n.aiSettingsTitle,
            subtitle: l10n.aiSettingsDescription,
            useGradientIcon: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AiSettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _buildSectionTitle(context, l10n.about_and_legal_capslock),
          _buildNavigationCard(
            context: context,
            icon: Icons.info_outline_rounded,
            title: l10n.attribution_and_license,
            subtitle: l10n.data_from_off_and_wger,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.attribution_title),
                  content: SingleChildScrollView(
                    child: Text(l10n.attributionText),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.snackbar_button_ok),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: DesignConstants.spacingM),
          SummaryCard(
            child: ListTile(
              leading: const Icon(Icons.code_rounded),
              title: Text(
                l10n.app_version,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_appVersion),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
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

  /// AI gradient colours for the entry-point icon accent.
  static const _aiGradientColors = [
    Color(0xFFE88DCC),
    Color(0xFFF4A77A),
    Color(0xFFF7D06B),
    Color(0xFF7DDEAE),
    Color(0xFF6DC8D9),
  ];

  Widget _buildNavigationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool useGradientIcon = false,
  }) {
    Widget iconWidget = Icon(
      icon,
      size: 36,
      color: Theme.of(context).colorScheme.primary,
    );

    if (useGradientIcon) {
      iconWidget = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          colors: _aiGradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Icon(icon, size: 36),
      );
    }

    return SummaryCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 16.0,
        ),
        leading: iconWidget,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
      ),
    );
  }
}
