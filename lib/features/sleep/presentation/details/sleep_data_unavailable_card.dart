import 'package:flutter/material.dart';

class SleepDataUnavailableCard extends StatelessWidget {
  const SleepDataUnavailableCard({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
      ),
      child: Text(message),
    );
  }
}
