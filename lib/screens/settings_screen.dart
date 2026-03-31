// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

  /// Flag for parent screens to know steps settings changed and data should be refreshed.
  bool hasStepsSettingsChanged = false;

  @override
  void initState() {
    super.initState();
    _ownsSleepSyncService = widget._sleepSyncService == null;
    _sleepSyncService = widget._sleepSyncService ?? SleepSyncService();
    _ownsSleepPermissionController = widget._sleepPermissionController == null;
    _sleepPermissionController =
        widget._sleepPermissionController ??
            _sleepSyncService.buildPermissionController();
    _loadAppVersion();
    _loadStepsSettings();
    _loadSleepSettings();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeService = Provider.of<ThemeService>(context);
    // profileService wird hier aktuell nicht genutzt, aber stört auch nicht
    // final profileService = Provider.of<ProfileService>(context);
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(hasStepsSettingsChanged);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlobalAppBar(title: l10n.settingsTitle),
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
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
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
            _buildSectionTitle(context, 'Health Steps (Alpha)'),
            SummaryCard(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.directions_walk_rounded),
                    title: const Text(
                      'Enable steps tracking',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Read step data from Apple Health / Health Connect',
                    ),
                    value: _stepsTrackingEnabled,
                    onChanged: (value) async {
                      await _stepsSyncService.setTrackingEnabled(value);
                      hasStepsSettingsChanged = true;
                      if (!mounted) return;
                      setState(() => _stepsTrackingEnabled = value);

                      // Issue 2 Fix: When enabling, immediately request permissions & sync
                      if (value) {
                        const platform = HealthPlatformSteps();
                        final availability = await platform.getAvailability();
                        if (availability == StepsAvailability.available) {
                          await platform.requestPermissions();
                          // Trigger first sync in background
                          _stepsSyncService.sync();
                        }
                      }
                    },
                  ),
                  const Divider(height: 1),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Source policy',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  RadioListTile<StepsSourcePolicy>(
                    title: const Text('Auto (dominant source)'),
                    subtitle: const Text(
                      'Recommended: use one source per day to avoid overlap inflation.',
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
                    title: const Text('Merge (max per hour)'),
                    subtitle: const Text(
                      'Combine sources by taking the highest hourly bucket.',
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Provider filter',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  RadioListTile<StepsProviderFilter>(
                    title: const Text('All'),
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
            _buildSectionTitle(context, 'Sleep (Batch 2)'),
            ValueListenableBuilder<SleepPermissionStatus>(
              valueListenable: _sleepPermissionController.state,
              builder: (context, permission, _) {
                return SummaryCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.bedtime_outlined),
                        title: const Text(
                          'Enable sleep tracking',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Read sleep and overnight heart rate from Health Connect / HealthKit',
                        ),
                        value: _sleepTrackingEnabled,
                        onChanged: (value) async {
                          await _sleepSyncService.setTrackingEnabled(value);
                          hasStepsSettingsChanged = true;
                          if (!mounted) return;
                          setState(() => _sleepTrackingEnabled = value);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.health_and_safety_outlined),
                        title: const Text(
                          'Health connection status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(_sleepStatusSubtitle(permission)),
                        trailing: Icon(
                          _sleepStatusIcon(permission.state),
                          color: _sleepStatusColor(context, permission.state),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_open_outlined),
                        title: const Text('Request access'),
                        subtitle: const Text(
                          'Request or re-request sleep/heart-rate permissions',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await _sleepPermissionController.requestAccess();
                          if (!mounted) return;
                          setState(() {});
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.sync),
                        title: const Text('Import sleep data now'),
                        subtitle: const Text('Import the last 30 days for testing'),
                        trailing: _isSleepImporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _isSleepImporting
                            ? null
                            : () async {
                                setState(() => _isSleepImporting = true);
                                final result =
                                    await _sleepSyncService.importRecent();
                                if (!mounted) return;
                                setState(() => _isSleepImporting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result.success
                                          ? 'Sleep import finished (${result.importedSessions} sessions).'
                                          : (result.message ??
                                              'Sleep import unavailable. Check permissions.'),
                                    ),
                                  ),
                                );
                                await _sleepPermissionController.refresh();
                                hasStepsSettingsChanged = true;
                              },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            _buildSectionTitle(context, l10n.aiSettingsTitle),
            SummaryCard(
              child: SwitchListTile(
                secondary: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: _aiGradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Icon(Icons.auto_awesome, size: 28),
                ),
                title: Text(
                  l10n.aiEnableTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(l10n.aiEnableSubtitle),
                value: themeService.isAiEnabled,
                onChanged: (value) => themeService.setAiEnabled(value),
              ),
            ),
            if (themeService.isAiEnabled) ...[
              const SizedBox(height: DesignConstants.spacingM),
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
            ],
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
      ), // closes PopScope
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

  String _sleepStatusSubtitle(SleepPermissionStatus status) {
    final custom = status.message;
    if (custom != null && custom.isNotEmpty) return custom;
    return switch (status.state) {
      SleepPermissionState.loading => 'Checking permission status…',
      SleepPermissionState.ready => 'Ready',
      SleepPermissionState.denied => 'Denied',
      SleepPermissionState.partial => 'Partial access',
      SleepPermissionState.unavailable => 'Unavailable on this device',
      SleepPermissionState.notInstalled => 'Health Connect not installed',
      SleepPermissionState.technicalError => 'Technical error',
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
