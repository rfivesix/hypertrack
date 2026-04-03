import 'package:flutter/material.dart';

import '../../../../widgets/summary_card.dart';

class SleepDataUnavailableCard extends StatelessWidget {
  const SleepDataUnavailableCard({
    super.key,
    required this.message,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
  });

  final String message;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
      margin: margin,
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }
}
