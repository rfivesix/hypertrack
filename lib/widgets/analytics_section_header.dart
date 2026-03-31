import 'package:flutter/material.dart';

class AnalyticsSectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry padding;

  const AnalyticsSectionHeader({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.only(left: 4, bottom: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
