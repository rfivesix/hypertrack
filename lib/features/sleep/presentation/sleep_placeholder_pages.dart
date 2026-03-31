import 'package:flutter/material.dart';

import '../../../widgets/global_app_bar.dart';
import '../../../widgets/summary_card.dart';

class SleepPlaceholderPage extends StatelessWidget {
  const SleepPlaceholderPage({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBar(title: title),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SummaryCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(message),
          ),
        ),
      ),
    );
  }
}
