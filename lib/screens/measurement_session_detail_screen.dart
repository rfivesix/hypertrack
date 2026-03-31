// lib/screens/measurement_session_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../generated/app_localizations.dart';
import '../models/measurement_session.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';

/// A screen displaying the details of a specific measurement session.
///
/// Shows a list of all individual measurements recorded at a particular point in time.
class MeasurementSessionDetailScreen extends StatelessWidget {
  /// The measurement session to display.
  final MeasurementSession session;

  const MeasurementSessionDetailScreen({super.key, required this.session});

  // Wir kopieren die Helfer-Methode hierher, um die Namen zu übersetzen.
  String _getLocalizedMeasurementName(String key, AppLocalizations l10n) {
    switch (key) {
      case 'weight':
        return l10n.measurementWeight;
      case 'fat_percent':
        return l10n.measurementFatPercent;
      case 'neck':
        return l10n.measurementNeck;
      // ... (füge hier alle anderen 'case' Anweisungen aus dem measurements_screen.dart ein)
      case 'right_calf':
        return l10n.measurementRightCalf;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: DateFormat.yMMMMd('de_DE').format(session.timestamp),
      ),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        children: [
          ...session.measurements.map((measurement) {
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(
                  _getLocalizedMeasurementName(measurement.type, l10n),
                ),
                trailing: Text(
                  "${measurement.value.toStringAsFixed(1)} ${measurement.unit}",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
