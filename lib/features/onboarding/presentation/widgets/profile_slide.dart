import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';

class ProfileSlide extends StatelessWidget {
  final TextEditingController nameController;
  final DateTime? selectedDate;
  final TextEditingController heightController;
  final String? selectedGender;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<String?> onSelectGender;

  const ProfileSlide({
    super.key,
    required this.nameController,
    required this.selectedDate,
    required this.heightController,
    required this.selectedGender,
    required this.onSelectDate,
    required this.onSelectGender,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.watch<UnitService>();

    return SingleChildScrollView(
      key: const Key('onboarding_profile_page'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _StepTitle(title: l10n.onboardingNameTitle),
          const SizedBox(height: 16),
          TextField(
            key: const Key('onboarding_name_text_field'),
            controller: nameController,
            decoration: InputDecoration(
              labelText: l10n.onboardingNameLabel,
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 32),
          _StepTitle(title: l10n.onboardingDobTitle),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                onSelectDate(picked);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.onboardingDobLabel,
                prefixIcon: const Icon(Icons.cake_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                selectedDate == null
                    ? 'DD.MM.YYYY'
                    : DateFormat.yMMMd(
                        Localizations.localeOf(context).toString(),
                      ).format(selectedDate!),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepTitle(
                      title: l10n.onboardingHeightLabel,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('onboarding_height_text_field'),
                      controller: heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            '${l10n.onboardingHeightLabel} (${unitService.suffixFor(UnitDimension.height)})',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepTitle(
                      title: l10n.onboardingGenderLabel,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: const Key('onboarding_gender_dropdown'),
                      initialValue: selectedGender,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text(l10n.genderMale),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text(l10n.genderFemale),
                        ),
                        DropdownMenuItem(
                          value: 'diverse',
                          child: Text(l10n.genderDiverse),
                        ),
                      ],
                      onChanged: onSelectGender,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String title;
  const _StepTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
