import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_data_sources.dart';
import '../features/feedback_report/presentation/feedback_report_screen.dart';
import '../features/sleep/platform/permissions/sleep_permission_controller.dart';
import '../features/sleep/platform/sleep_sync_service.dart';
import '../generated/app_localizations.dart';
import '../services/app_tour_service.dart';
import '../theme/color_constants.dart';
import '../services/base_food_language_service.dart';
import '../services/off_catalog_country_service.dart';
import '../services/unit_service.dart';
import '../util/design_constants.dart';
import '../widgets/glass_bottom_menu.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import 'ai_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'data_management_screen.dart';
import 'health_export_settings_screen.dart';
import 'pulse_settings_screen.dart';
import 'sleep_settings_screen.dart';
import 'steps_settings_screen.dart';
import '../services/local_app_data_reset_service.dart';
import '../services/workout_session_manager.dart';
import '../widgets/analytics_section_header.dart';
import 'app_initializer_screen.dart';
import 'package:provider/provider.dart';

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

  bool _showSugarInDiaryOverview = false;
  OffCatalogCountry _activeOffCatalogCountry =
      AppDataSources.defaultOffCatalogCountry;
  BaseFoodLanguage _baseFoodLanguage = BaseFoodLanguage.auto;

  late final SleepSettingsService _sleepSyncService;
  late final SleepPermissionController _sleepPermissionController;
  late final bool _ownsSleepSyncService;
  late final bool _ownsSleepPermissionController;

  bool hasStepsSettingsChanged = false;
  bool _isLocalResetRunning = false;

  @override
  void initState() {
    super.initState();
    _ownsSleepSyncService = widget._sleepSyncService == null;
    _sleepSyncService = widget._sleepSyncService ?? SleepSyncService();
    _ownsSleepPermissionController = widget._sleepPermissionController == null;
    _sleepPermissionController = widget._sleepPermissionController ??
        _sleepSyncService.buildPermissionController();

    _loadDiaryOverviewSettings();
    _loadOffCatalogSettings();
    _loadBaseFoodLanguage();
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

  Future<void> _loadBaseFoodLanguage() async {
    final choice = await BaseFoodLanguageService.readChoice();
    if (!mounted) return;
    setState(() => _baseFoodLanguage = choice);
  }

  String _baseFoodLanguageLabel(
    BaseFoodLanguage language,
    AppLocalizations l10n,
  ) {
    return switch (language) {
      BaseFoodLanguage.auto => l10n.settingsBaseFoodLanguageFollowApp,
      BaseFoodLanguage.en => l10n.settingsBaseFoodLanguageEnglish,
      BaseFoodLanguage.de => l10n.settingsBaseFoodLanguageGerman,
    };
  }

  Future<void> _showBaseFoodLanguagePicker() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showGlassBottomMenu<BaseFoodLanguage>(
      context: context,
      title: l10n.settingsBaseFoodLanguageTitle,
      contentBuilder: (dialogContext, close) {
        var draft = _baseFoodLanguage;
        return StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settingsBaseFoodLanguageSubtitle),
              const SizedBox(height: 12),
              RadioGroup<BaseFoodLanguage>(
                groupValue: draft,
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => draft = value);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final lang in BaseFoodLanguage.values)
                      RadioListTile<BaseFoodLanguage>(
                        contentPadding: EdgeInsets.zero,
                        value: lang,
                        title: Text(_baseFoodLanguageLabel(lang, l10n)),
                      ),
                  ],
                ),
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
                      onPressed: () => Navigator.of(dialogContext).pop(draft),
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

    if (!mounted || selected == null) return;
    if (selected == _baseFoodLanguage) return;

    await BaseFoodLanguageService.writeChoice(selected);
    // Force a base-food re-import on next startup so both name columns
    // are populated according to the new preference.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('installed_food_version');
    if (!mounted) return;
    setState(() => _baseFoodLanguage = selected);
    hasStepsSettingsChanged = true;

    final l10nNow = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10nNow.settingsFoodDbRegionChanged(
          _baseFoodLanguageLabel(selected, l10nNow),
        )),
      ),
    );
  }

  String _offCountryLabel(OffCatalogCountry country, AppLocalizations l10n) {
    return switch (country) {
      OffCatalogCountry.de => l10n.settingsFoodDbRegionGermany,
      OffCatalogCountry.ch => l10n.settingsFoodDbRegionSwitzerland,
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

  bool _settingsChildMayHaveChanged(bool? result) {
    // iOS interactive back-swipe completes a route with a null result. These
    // settings sub-screens are safe to swipe away from, so refresh
    // conservatively instead of blocking the native gesture with PopScope.
    return result == true ||
        (result == null && Theme.of(context).platform == TargetPlatform.iOS);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.watch<UnitService>();
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
            l10n.settingsSectionApp,
            key: const Key('settings_section_app'),
          ),
          _buildNavigationCard(
            context: context,
            icon: Icons.palette_outlined,
            title: l10n.settingsAppearance,
            subtitle: l10n.settingsAppearanceSubtitle,
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
                l10n.settingsShowSugarInDiaryOverviewTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                l10n.settingsShowSugarInDiaryOverviewSubtitle,
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
          SummaryCard(
            child: SwitchListTile(
              secondary: Icon(
                Icons.straighten_rounded,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text(
                'Unit System',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                unitService.isMetric
                    ? 'Metric (kg, cm, ml)'
                    : 'Imperial (lbs, in, fl oz)',
              ),
              value: unitService.isImperial,
              onChanged: (value) {
                unitService.setUnitSystem(
                  value ? UnitSystem.imperial : UnitSystem.metric,
                );
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
            l10n.settingsSectionHealthTracking,
            key: const Key('settings_section_health_tracking'),
          ),
          _buildNavigationCard(
            context: context,
            icon: Icons.directions_walk_rounded,
            title: l10n.steps,
            subtitle: l10n.settingsStepsSubtitle,
            tileKey: const Key('settings_steps_entry'),
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const StepsSettingsScreen(),
                ),
              );
              if (_settingsChildMayHaveChanged(changed)) {
                hasStepsSettingsChanged = true;
              }
            },
          ),
          _buildNavigationCard(
            context: context,
            icon: Icons.bedtime_outlined,
            title: l10n.sleepSettingsSectionTitle,
            subtitle: l10n.settingsSleepSubtitle,
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
              if (_settingsChildMayHaveChanged(changed)) {
                hasStepsSettingsChanged = true;
              }
            },
          ),
          _buildNavigationCard(
            context: context,
            icon: Icons.favorite_border_rounded,
            title: l10n.pulseTitle,
            subtitle: l10n.settingsPulseSubtitle,
            tileKey: const Key('settings_pulse_entry'),
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const PulseSettingsScreen(),
                ),
              );
              if (_settingsChildMayHaveChanged(changed)) {
                hasStepsSettingsChanged = true;
              }
            },
          ),
          _buildNavigationCard(
            context: context,
            icon: Icons.favorite_outline,
            title: l10n.healthExportTitle,
            subtitle: l10n.settingsHealthExportSubtitle,
            tileKey: const Key('settings_health_export_entry'),
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const HealthExportSettingsScreen(),
                ),
              );
              if (_settingsChildMayHaveChanged(changed)) {
                hasStepsSettingsChanged = true;
              }
            },
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _buildSectionTitle(
            context,
            l10n.settingsSectionNutritionAndData,
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
          _buildNavigationCard(
            context: context,
            icon: Icons.sync,
            title: l10n.settingsUpdateFoodDatabase,
            subtitle: l10n.settingsUpdateFoodDatabaseSubtitle,
            tileKey: const Key('settings_sync_off_database'),
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AppInitializerScreen(
                    forceUpdate: true,
                    isModal: true,
                  ),
                ),
              );

              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.settingsUpdateFoodDatabaseSuccess)),
                );
              }
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
          SummaryCard(
            child: ListTile(
              leading: Icon(
                Icons.translate_rounded,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                l10n.settingsBaseFoodLanguageTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _baseFoodLanguageLabel(_baseFoodLanguage, l10n),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showBaseFoodLanguagePicker,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          _buildSectionTitle(
            context,
            l10n.settingsSectionSupportAbout,
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
          const SizedBox(height: DesignConstants.spacingXL),
          _buildSectionTitle(
            context,
            l10n.localDataDeletionCardTitle,
            key: const Key('settings_section_reset'),
          ),
          SummaryCard(
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.localDataDeletionCardTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                  Text(
                    l10n.localDataDeletionCardDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: DesignConstants.spacingL),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('delete_all_local_app_data_button'),
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: Text(l10n.deleteAllLocalAppData),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      onPressed: _isLocalResetRunning
                          ? null
                          : _confirmAndDeleteLocalData,
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
    return AnalyticsSectionHeader(
      key: key,
      title: title.toUpperCase(),
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
      final resetter = LocalAppDataResetService();
      await resetter.deleteAllLocalAppData();
      await sessionManager?.clearLocalSessionState();

      if (!mounted) return;
      setState(() => _isLocalResetRunning = false);

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
                ),
                const SizedBox(height: 16),
                TextField(
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
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: canConfirm
                            ? () => Navigator.of(ctx).pop(true)
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
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
        shaderCallback: (bounds) => createAiGradientShader(bounds),
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
