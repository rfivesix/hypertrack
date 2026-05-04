import 'package:flutter/material.dart';

import '../generated/app_localizations.dart';
import '../services/health/health_models.dart';
import '../services/health/health_platform_steps.dart';
import '../services/health/steps_sync_service.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';

class StepsSettingsScreen extends StatefulWidget {
  const StepsSettingsScreen({super.key});

  @override
  State<StepsSettingsScreen> createState() => _StepsSettingsScreenState();
}

class _StepsSettingsScreenState extends State<StepsSettingsScreen> {
  final StepsSyncService _stepsSyncService = StepsSyncService();
  bool _stepsTrackingEnabled = true;
  StepsProviderFilter _stepsProviderFilter = StepsProviderFilter.all;
  StepsSourcePolicy _stepsSourcePolicy = StepsSourcePolicy.autoDominant;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadStepsSettings();
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
          title: l10n.steps,
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
        ),
        body: ListView(
          padding: DesignConstants.cardPadding.copyWith(
            top: DesignConstants.cardPadding.top + topPadding,
          ),
          children: [
            _buildSectionTitle(context, l10n.steps),
            SummaryCard(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.directions_walk_rounded),
                    title: Text(
                      l10n.stepsSettingsEnableTrackingTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(l10n.stepsSettingsEnableTrackingSubtitle),
                    value: _stepsTrackingEnabled,
                    onChanged: (value) async {
                      await _stepsSyncService.setTrackingEnabled(value);
                      if (!mounted) return;
                      setState(() {
                        _stepsTrackingEnabled = value;
                        _hasChanges = true;
                      });

                      if (value) {
                        const platform = HealthPlatformSteps();
                        final availability = await platform.getAvailability();
                        if (availability == StepsAvailability.available) {
                          await platform.requestPermissions();
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
                        l10n.stepsSettingsSourcePolicyTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  RadioGroup<StepsSourcePolicy>(
                    groupValue: _stepsSourcePolicy,
                    onChanged: (value) async {
                      if (value == null) return;
                      await _stepsSyncService.setSourcePolicy(value);
                      if (!mounted) return;
                      setState(() {
                        _stepsSourcePolicy = value;
                        _hasChanges = true;
                      });
                    },
                    child: Column(
                      children: [
                        RadioListTile<StepsSourcePolicy>(
                          title: Text(
                            l10n.stepsSettingsSourcePolicyAutoDominant,
                          ),
                          subtitle: Text(
                            l10n.stepsSettingsSourcePolicyAutoDominantSubtitle,
                          ),
                          value: StepsSourcePolicy.autoDominant,
                        ),
                        RadioListTile<StepsSourcePolicy>(
                          title: Text(
                            l10n.stepsSettingsSourcePolicyMaxPerHour,
                          ),
                          subtitle: Text(
                            l10n.stepsSettingsSourcePolicyMaxPerHourSubtitle,
                          ),
                          value: StepsSourcePolicy.maxPerHour,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.stepsSettingsProviderFilterTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  RadioGroup<StepsProviderFilter>(
                    groupValue: _stepsProviderFilter,
                    onChanged: (value) async {
                      if (value == null) return;
                      await _stepsSyncService.setProviderFilter(value);
                      if (!mounted) return;
                      setState(() {
                        _stepsProviderFilter = value;
                        _hasChanges = true;
                      });
                    },
                    child: Column(
                      children: [
                        RadioListTile<StepsProviderFilter>(
                          title: Text(l10n.filterAll),
                          value: StepsProviderFilter.all,
                        ),
                        RadioListTile<StepsProviderFilter>(
                          title: const Text('Apple Health'),
                          value: StepsProviderFilter.apple,
                        ),
                        RadioListTile<StepsProviderFilter>(
                          title: const Text('Health Connect'),
                          value: StepsProviderFilter.google,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
