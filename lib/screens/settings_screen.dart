// lib/screens/settings_screen.dart
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

/// A screen for configuring application-wide preferences.
///
/// Includes theme selection (light/dark/system), visual style toggles,
/// and navigation to data management (backup/import) and legal information.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = "${packageInfo.version} (${packageInfo.buildNumber})";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeService = Provider.of<ThemeService>(context);
    // profileService wird hier aktuell nicht genutzt, aber stört auch nicht
    // final profileService = Provider.of<ProfileService>(context);
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
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
                          style: Theme.of(context).textTheme.labelLarge
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
