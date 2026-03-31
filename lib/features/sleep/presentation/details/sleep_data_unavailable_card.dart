import 'package:flutter/material.dart';

import '../../../../widgets/summary_card.dart';

class SleepDataUnavailableCard extends StatelessWidget {
  const SleepDataUnavailableCard({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message),
      ),
    );
  }
}
