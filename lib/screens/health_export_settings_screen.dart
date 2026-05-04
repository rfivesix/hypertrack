import 'package:flutter/material.dart';

import '../health_export/adapters/apple_health/apple_health_export_adapter.dart';
import '../health_export/adapters/health_connect/health_connect_export_adapter.dart';
import '../health_export/export_service.dart';
import '../health_export/models/export_models.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';

class HealthExportSettingsScreen extends StatefulWidget {
  const HealthExportSettingsScreen({super.key});

  @override
  State<HealthExportSettingsScreen> createState() =>
      _HealthExportSettingsScreenState();
}

class _HealthExportSettingsScreenState
    extends State<HealthExportSettingsScreen> {
  late final HealthExportService _healthExportService;
  Map<HealthExportPlatform, HealthExportPlatformStatus> _exportStatuses = {
    for (final platform in HealthExportPlatform.values)
      platform: HealthExportPlatformStatus.initial(platform),
  };
  bool _appleExportEnabled = false;
  bool _healthConnectExportEnabled = false;
  bool _isAppleExporting = false;
  bool _isHealthConnectExporting = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _healthExportService = HealthExportService(
      adapters: [AppleHealthExportAdapter(), HealthConnectExportAdapter()],
    );
    _loadHealthExportSettings();
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

  Future<void> _toggleHealthExport({
    required HealthExportPlatform platform,
    required bool enabled,
  }) async {
    if (enabled) {
      final permission =
          await _healthExportService.requestPermissions(platform);
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
    if (!mounted) return;
    setState(() => _hasChanges = true);
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
      _hasChanges = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_healthExportResultMessage(result, context))),
    );
  }

  String _exportPlatformTitle(
    HealthExportPlatform platform,
    AppLocalizations l10n,
  ) {
    return switch (platform) {
      HealthExportPlatform.appleHealth => l10n.healthExportAppleHealthTitle,
      HealthExportPlatform.healthConnect => l10n.healthExportHealthConnectTitle,
    };
  }

  String _domainLabel(HealthExportDomain domain, AppLocalizations l10n) {
    return switch (domain) {
      HealthExportDomain.measurements => l10n.measurementsScreenTitle,
      HealthExportDomain.nutritionHydration =>
        l10n.healthExportDomainNutritionHydration,
      HealthExportDomain.workouts => l10n.healthExportDomainWorkouts,
    };
  }

  String _stateLabel(HealthExportState state, AppLocalizations l10n) {
    return switch (state) {
      HealthExportState.idle => l10n.healthExportStateIdle,
      HealthExportState.exporting => l10n.healthExportStateExporting,
      HealthExportState.success => l10n.healthExportStateSuccess,
      HealthExportState.failed => l10n.healthExportStateFailed,
      HealthExportState.disabled => l10n.healthExportStateDisabled,
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
    final l10n = AppLocalizations.of(context)!;
    if (result.success) {
      return l10n.healthExportResultComplete;
    }
    return result.message ?? l10n.healthExportResultFailed;
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
          title: l10n.healthExportTitle,
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
        ),
        body: ListView(
          padding: DesignConstants.cardPadding.copyWith(
            top: DesignConstants.cardPadding.top + topPadding,
          ),
          children: [
            _buildSectionTitle(
              context,
              l10n.healthExportTitle,
            ),
            SummaryCard(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.favorite_outline),
                    title: Text(
                      _exportPlatformTitle(
                        HealthExportPlatform.appleHealth,
                        l10n,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      l10n.healthExportAppleHealthSubtitle,
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
                      l10n.healthExportAppleHealthStatusTitle,
                    ),
                    subtitle: Text(
                      HealthExportDomain.values.map((domain) {
                        final status =
                            _exportStatuses[HealthExportPlatform.appleHealth]
                                ?.statusFor(domain);
                        return '${_domainLabel(domain, l10n)}: ${_stateLabel(status?.state ?? HealthExportState.idle, l10n)}';
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
                        l10n,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      l10n.healthExportHealthConnectSubtitle,
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
                      l10n.healthExportHealthConnectStatusTitle,
                    ),
                    subtitle: Text(
                      HealthExportDomain.values.map((domain) {
                        final status =
                            _exportStatuses[HealthExportPlatform.healthConnect]
                                ?.statusFor(domain);
                        return '${_domainLabel(domain, l10n)}: ${_stateLabel(status?.state ?? HealthExportState.idle, l10n)}';
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
          ],
        ),
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
}
