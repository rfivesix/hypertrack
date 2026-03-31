import 'package:flutter/material.dart';

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
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).cardColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
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
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
