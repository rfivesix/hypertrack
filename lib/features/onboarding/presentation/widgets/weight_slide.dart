import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';

class WeightSlide extends StatelessWidget {
  final TextEditingController weightController;

  const WeightSlide({
    super.key,
    required this.weightController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.watch<UnitService>();
    final suffix = unitService.suffixFor(UnitDimension.weight);

    return Padding(
      key: const Key('onboarding_weight_page'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${l10n.onboardingWeightTitle} ($suffix)',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0.0',
              suffixText: suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 24),
            ),
          ),
        ],
      ),
    );
  }
}
