import 'package:flutter/material.dart';

import '../../../../util/design_constants.dart';
import '../../../../widgets/global_app_bar.dart';
import '../../../../widgets/summary_card.dart';
import 'sleep_data_unavailable_card.dart';

class SleepDetailPageShell extends StatelessWidget {
  const SleepDetailPageShell({
    super.key,
    required this.title,
    required this.value,
    required this.statusLabel,
    required this.children,
    this.subtitle,
    this.statusColor,
  });

  final String title;
  final String value;
  final String statusLabel;
  final String? subtitle;
  final Color? statusColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final color = statusColor ?? Theme.of(context).colorScheme.outline;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: title),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top:
              DesignConstants.cardPadding.top +
              MediaQuery.of(context).padding.top +
              kToolbarHeight +
              16,
        ),
        children: [
          SummaryCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(statusLabel),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class SleepDetailUnavailablePage extends StatelessWidget {
  const SleepDetailUnavailablePage({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: title),
      body: ListView(
        padding: DesignConstants.cardPadding.copyWith(
          top:
              DesignConstants.cardPadding.top +
              MediaQuery.of(context).padding.top +
              kToolbarHeight +
              16,
        ),
        children: [SleepDataUnavailableCard(message: message)],
      ),
    );
  }
}
