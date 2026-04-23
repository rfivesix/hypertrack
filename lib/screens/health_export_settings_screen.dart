import 'package:flutter/material.dart';

import '../health_export/adapters/apple_health/apple_health_export_adapter.dart';
import '../health_export/adapters/health_connect/health_connect_export_adapter.dart';
import '../health_export/export_service.dart';
import '../health_export/models/export_models.dart';
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
    final isGerman = _isGerman(context);
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
          title: isGerman ? 'Health Export' : 'Health export',
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
              isGerman ? 'Health Export' : 'Health export',
            ),
            SummaryCard(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.favorite_outline),
                    title: Text(
                      _exportPlatformTitle(
                        HealthExportPlatform.appleHealth,
                        isGerman,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isGerman
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
                      isGerman
                          ? 'Export-Status Apple Health'
                          : 'Apple Health export status',
                    ),
                    subtitle: Text(
                      HealthExportDomain.values.map((domain) {
                        final status =
                            _exportStatuses[HealthExportPlatform.appleHealth]
                                ?.statusFor(domain);
                        return '${_domainLabel(domain, isGerman)}: ${_stateLabel(status?.state ?? HealthExportState.idle, isGerman)}';
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
                        isGerman,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isGerman
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
                      isGerman
                          ? 'Export-Status Health Connect'
                          : 'Health Connect export status',
                    ),
                    subtitle: Text(
                      HealthExportDomain.values.map((domain) {
                        final status =
                            _exportStatuses[HealthExportPlatform.healthConnect]
                                ?.statusFor(domain);
                        return '${_domainLabel(domain, isGerman)}: ${_stateLabel(status?.state ?? HealthExportState.idle, isGerman)}';
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
