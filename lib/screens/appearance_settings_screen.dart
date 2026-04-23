import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../generated/app_localizations.dart';
import '../services/theme_service.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isGerman = Localizations.localeOf(context).languageCode == 'de';
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final themeService = Provider.of<ThemeService>(context);
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.settingsAppearance),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          _buildSectionTitle(context, l10n.settingsAppearance),
          SummaryCard(
            child: Column(
              children: [
                RadioGroup<ThemeMode>(
                  groupValue: themeService.themeMode,
                  onChanged: (value) {
                    if (value == null) return;
                    themeService.setThemeMode(value);
                  },
                  child: Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: Text(l10n.themeSystem),
                        value: ThemeMode.system,
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text(l10n.themeLight),
                        value: ThemeMode.light,
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text(l10n.themeDark),
                        value: ThemeMode.dark,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
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
                      RadioGroup<int>(
                        groupValue: themeService.visualStyle,
                        onChanged: (value) {
                          if (value == null) return;
                          themeService.setVisualStyle(value);
                        },
                        child: Column(
                          children: [
                            RadioListTile<int>(
                              title: Text(l10n.settingsVisualStyleStandard),
                              value: 0,
                            ),
                            RadioListTile<int>(
                              title: Text(l10n.settingsVisualStyleLiquid),
                              subtitle:
                                  Text(l10n.settingsVisualStyleLiquidDesc),
                              value: 1,
                            ),
                          ],
                        ),
                      ),
                      if (isAndroid) ...[
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(Icons.palette_outlined),
                          title: Text(
                            l10n.settingsMaterialColorsTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
        ],
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
