// lib/widgets/wger_attribution_widget.dart

import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// A small widget for displaying source attribution for exercise data from Wger.
///
/// Provides a clickable link to their website.
class WgerAttributionWidget extends StatelessWidget {
  /// Optional style for the attribution text.
  final TextStyle? textStyle;

  const WgerAttributionWidget({super.key, this.textStyle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currentTextStyle =
        textStyle ??
        theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]);

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2.5),
        child: GestureDetector(
          // Macht den Text klickbar
          onTap: () async {
            final uri = Uri.parse("https://wger.de/"); // <-- Geänderte URL
            try {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                throw 'Could not launch $uri';
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.snackbar_could_not_open_open_link),
                  ),
                );
              }
            }
          },
          child: Text(
            l10n.exerciseDataAttribution, // <-- Geänderter Text
            style: currentTextStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
