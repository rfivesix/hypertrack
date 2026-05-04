import 'package:flutter/material.dart';

import '../features/pulse/application/pulse_tracking_service.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';

class PulseSettingsScreen extends StatefulWidget {
  const PulseSettingsScreen({
    super.key,
    PulseTrackingSettingsService? trackingService,
  }) : _trackingService = trackingService;

  final PulseTrackingSettingsService? _trackingService;

  @override
  State<PulseSettingsScreen> createState() => _PulseSettingsScreenState();
}

class _PulseSettingsScreenState extends State<PulseSettingsScreen> {
  late final PulseTrackingSettingsService _trackingService;
  bool _enabled = false;
  bool _requesting = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _trackingService = widget._trackingService ?? PulseTrackingService();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _trackingService.isTrackingEnabled();
    if (!mounted) return;
    setState(() => _enabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final copy = _PulseSettingsCopy(context);
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
          title: copy.title,
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
        ),
        body: ListView(
          padding: DesignConstants.cardPadding.copyWith(
            top: DesignConstants.cardPadding.top + topPadding,
          ),
          children: [
            _buildSectionTitle(context, copy.title),
            SummaryCard(
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('pulse_tracking_toggle'),
                    secondary: const Icon(Icons.favorite_outline),
                    title: Text(
                      copy.enableTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(copy.enableSubtitle),
                    value: _enabled,
                    onChanged: _requesting ? null : _setEnabled,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_open_outlined),
                    title: Text(copy.permissionTitle),
                    subtitle: Text(copy.permissionSubtitle),
                    trailing: _requesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _requesting ? null : _requestAccess,
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(copy.honestTitle),
                    subtitle: Text(copy.honestSubtitle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setEnabled(bool value) async {
    setState(() => _requesting = value);
    await _trackingService.setTrackingEnabled(value);
    var granted = true;
    if (value) {
      granted = await _trackingService.requestPermissions();
    }
    if (!mounted) return;
    setState(() {
      _enabled = value;
      _requesting = false;
      _hasChanges = true;
    });
    if (value && !granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_PulseSettingsCopy(context).permissionFailed)),
      );
    }
  }

  Future<void> _requestAccess() async {
    setState(() => _requesting = true);
    final granted = await _trackingService.requestPermissions();
    if (!mounted) return;
    setState(() => _requesting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? _PulseSettingsCopy(context).permissionGranted
              : _PulseSettingsCopy(context).permissionFailed,
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

class _PulseSettingsCopy {
  _PulseSettingsCopy(BuildContext context)
      : l10n = AppLocalizations.of(context)!;

  final AppLocalizations l10n;

  String get title => l10n.pulseTitle;
  String get enableTitle => l10n.pulseSettingsEnableTitle;
  String get enableSubtitle => l10n.pulseSettingsEnableSubtitle;
  String get permissionTitle => l10n.pulseSettingsPermissionTitle;
  String get permissionSubtitle => l10n.pulseSettingsPermissionSubtitle;
  String get honestTitle => l10n.analysis;
  String get honestSubtitle => l10n.pulseSettingsAnalysisSubtitle;
  String get permissionGranted => l10n.pulseSettingsPermissionGranted;
  String get permissionFailed => l10n.pulseSettingsPermissionFailed;
}
