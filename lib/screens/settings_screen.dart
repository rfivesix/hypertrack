import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_data_sources.dart';
import '../features/feedback_report/presentation/feedback_report_screen.dart';
import '../features/sleep/platform/permissions/sleep_permission_controller.dart';
import '../features/sleep/platform/sleep_sync_service.dart';
import '../generated/app_localizations.dart';
import '../services/app_tour_service.dart';
import '../services/off_catalog_country_service.dart';
import '../util/design_constants.dart';
import '../widgets/glass_bottom_menu.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import 'ai_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'data_management_screen.dart';
import 'health_export_settings_screen.dart';
import 'sleep_settings_screen.dart';
import 'steps_settings_screen.dart';

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
  bool _showSugarInDiaryOverview = false;
  OffCatalogCountry _activeOffCatalogCountry =
      AppDataSources.defaultOffCatalogCountry;

  late final SleepSettingsService _sleepSyncService;
  late final SleepPermissionController _sleepPermissionController;
  late final bool _ownsSleepSyncService;
  late final bool _ownsSleepPermissionController;

  bool hasStepsSettingsChanged = false;

  @override
  void initState() {
    super.initState();
    _ownsSleepSyncService = widget._sleepSyncService == null;
    _sleepSyncService = widget._sleepSyncService ?? SleepSyncService();
    _ownsSleepPermissionController = widget._sleepPermissionController == null;
    _sleepPermissionController = widget._sleepPermissionController ??
        _sleepSyncService.buildPermissionController();

    _loadAppVersion();
    _loadDiaryOverviewSettings();
    _loadOffCatalogSettings();
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

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
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

  Future<void> _loadOffCatalogSettings() async {
    final country = await OffCatalogCountryService.readActiveCountry();
    if (!mounted) return;
    setState(() => _activeOffCatalogCountry = country);
  }

  String _offCountryLabel(OffCatalogCountry country, AppLocalizations l10n) {
    return switch (country) {
      OffCatalogCountry.de => l10n.settingsFoodDbRegionGermany,
      OffCatalogCountry.us => l10n.settingsFoodDbRegionUnitedStates,
      OffCatalogCountry.uk => l10n.settingsFoodDbRegionUnitedKingdom,
    };
  }

  Future<void> _showOffCatalogRegionPicker() async {
    final l10n = AppLocalizations.of(context)!;
    final selectedCountry = await showGlassBottomMenu<OffCatalogCountry>(
      context: context,
      title: l10n.settingsFoodDbRegionDialogTitle,
      contentBuilder: (dialogContext, close) {
        var draftSelection = _activeOffCatalogCountry;
        return StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settingsFoodDbRegionDialogSubtitle),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: RadioGroup<OffCatalogCountry>(
                    groupValue: draftSelection,
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => draftSelection = value);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final country
                            in AppDataSources.supportedOffCatalogCountries)
                          RadioListTile<OffCatalogCountry>(
                            contentPadding: EdgeInsets.zero,
                            value: country,
                            title: Text(_offCountryLabel(country, l10n)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.settingsFoodDbRegionIssueHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(draftSelection),
                      child: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedCountry == null) return;
    if (selectedCountry == _activeOffCatalogCountry) return;

    await OffCatalogCountryService.writeActiveCountry(selectedCountry);
    if (!mounted) return;

    setState(() => _activeOffCatalogCountry = selectedCountry);
    hasStepsSettingsChanged = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.settingsFoodDbRegionChanged(
            _offCountryLabel(selectedCountry, l10n),
          ),
        ),
      ),
    );
  }

  Future<void> _restartAppTour() async {
    await AppTourService.instance.requestRestartFromSettings();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  bool _isGerman(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'de';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isGerman = _isGerman(context);
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

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
          _buildSectionTitle(
            context,
            isGerman ? 'App' : 'App',
            key: const Key('settings_section_app'),
          ),
          _buildNavigationCard(
            context: context,
            icon: Icons.palette_outlined,
            title: l10n.settingsAppearance,
            subtitle: isGerman
                ? 'Design, Stil und Haptik anpassen'
                : 'Adjust theme, visual style, and haptics',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AppearanceSettingsScreen(),
                ),
              );
            },
            tileKey: const Key('settings_appearance_entry'),
          ),
          SummaryCard(
            child: SwitchListTile(
              secondary: Icon(
                Icons.icecream_outlined,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
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
                if (!mounted) return;
                setState(() => _showSugarInDiaryOverview = value);
                hasStepsSettingsChanged = true;
              },
            ),
          ),
          _buildNavigationCard(
            context: context,
            icon: Icons.tour_outlined,
            title: l10n.settingsRestartAppTourTitle,
            subtitle: l10n.settingsRestartAppTourSubtitle,
            tileKey: const Key('settings_restart_app_tour_tile'),
            onTap: _restartAppTour,
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _buildSectionTitle(
            context,
            isGerman ? 'Gesundheit & Tracking' : 'Health & Tracking',
            key: const Key('settings_section_health_tracking'),
          ),
          _buildNavigationCard(
            context: context,
            icon: Icons.directions_walk_rounded,
            title: isGerman ? 'Schritte' : 'Steps',
            subtitle: isGerman
                ? 'Tracking, Quellenrichtlinie und Provider'
                : 'Tracking, source policy, and providers',
            tileKey: const Key('settings_steps_entry'),
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const StepsSettingsScreen(),
                ),
              );
              if (changed == true) {
                hasStepsSettingsChanged = true;
              }
            },
          ),
          _buildNavigationCard(
            context: context,
            icon: Icons.bedtime_outlined,
            title: l10n.sleepSettingsSectionTitle,
            subtitle: isGerman
                ? 'Import, Berechtigungen und Schlafstatus'
                : 'Import, permissions, and sleep status',
            tileKey: const Key('settings_sleep_entry'),
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => SleepSettingsScreen(
                    sleepSyncService: _sleepSyncService,
                    sleepPermissionController: _sleepPermissionController,
                  ),
                ),
              );
              if (changed == true) {
                hasStepsSettingsChanged = true;
              }
            },
          ),
          _buildNavigationCard(
            context: context,
            icon: Icons.favorite_outline,
            title: isGerman ? 'Health Export' : 'Health export',
            subtitle: isGerman
                ? 'Apple Health und Health Connect Export verwalten'
                : 'Manage Apple Health and Health Connect export',
            tileKey: const Key('settings_health_export_entry'),
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const HealthExportSettingsScreen(),
                ),
              );
              if (changed == true) {
                hasStepsSettingsChanged = true;
              }
            },
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _buildSectionTitle(
            context,
            isGerman ? 'Ernährung & Daten' : 'Nutrition & Data',
            key: const Key('settings_section_nutrition_data'),
          ),
          _buildNavigationCard(
            context: context,
            icon: Icons.auto_awesome,
            title: l10n.aiSettingsTitle,
            subtitle: l10n.aiSettingsDescription,
            useGradientIcon: true,
            tileKey: const Key('settings_ai_entry'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AiSettingsScreen(),
                ),
              );
            },
          ),
          _buildNavigationCard(
            context: context,
            icon: Icons.import_export_rounded,
            title: l10n.backup_and_import,
            subtitle: l10n.backup_and_import_description,
            tileKey: const Key('settings_backup_import_entry'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DataManagementScreen(),
                ),
              );
            },
          ),
          SummaryCard(
            child: ListTile(
              leading: Icon(
                Icons.language_rounded,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                l10n.settingsFoodDbRegionTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${l10n.settingsFoodDbRegionSubtitle}\n'
                '${l10n.settingsFoodDbRegionCurrent}: '
                '${_offCountryLabel(_activeOffCatalogCountry, l10n)}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: _showOffCatalogRegionPicker,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _buildSectionTitle(
            context,
            isGerman ? 'Support & Info' : 'Support / About',
            key: const Key('settings_section_support_about'),
          ),
          _buildNavigationCard(
            context: context,
            icon: Icons.feedback_outlined,
            title: l10n.feedbackReportSettingsEntryTitle,
            subtitle: l10n.feedbackReportSettingsEntrySubtitle,
            tileKey: const Key('settings_feedback_entry'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FeedbackReportScreen(),
                ),
              );
            },
          ),
          _buildNavigationCard(
            context: context,
            icon: Icons.info_outline_rounded,
            title: l10n.attribution_and_license,
            subtitle: l10n.data_from_off_and_wger,
            tileKey: const Key('settings_about_legal_entry'),
            onTap: () {
              showGlassBottomMenu<void>(
                context: context,
                title: l10n.attribution_title,
                contentBuilder: (ctx, close) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: SingleChildScrollView(
                        child: Text(l10n.attributionText),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(l10n.snackbar_button_ok),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SummaryCard(
            child: ListTile(
              leading: Icon(
                Icons.info_outline_rounded,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
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

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    Key? key,
  }) {
    return Padding(
      key: key,
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
    Key? tileKey,
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
        key: tileKey,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 16,
        ),
        leading: iconWidget,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
