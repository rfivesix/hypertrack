import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';

enum BodyFatGuidanceSex {
  male,
  female,
}

class BodyFatGuidanceEntry {
  final int percent;
  final String description;

  const BodyFatGuidanceEntry({
    required this.percent,
    required this.description,
  });
}

Future<void> showBodyFatGuidanceSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _BodyFatGuidanceSheet(),
  );
}

class _BodyFatGuidanceSheet extends StatefulWidget {
  const _BodyFatGuidanceSheet();

  @override
  State<_BodyFatGuidanceSheet> createState() => _BodyFatGuidanceSheetState();
}

class _BodyFatGuidanceSheetState extends State<_BodyFatGuidanceSheet> {
  BodyFatGuidanceSex _selectedSex = BodyFatGuidanceSex.male;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final entries = _entriesForSex(l10n, _selectedSex);

    return SafeArea(
      child: ConstrainedBox(
        key: const Key('body_fat_guidance_sheet'),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.bodyFatGuidanceTitle,
                key: const Key('body_fat_guidance_title'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.bodyFatGuidanceIntro,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.bodyFatGuidanceDisclaimer,
                key: const Key('body_fat_guidance_disclaimer'),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.bodyFatGuidanceSexLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('body_fat_guidance_sex_male'),
                    label: Text(l10n.genderMale),
                    selected: _selectedSex == BodyFatGuidanceSex.male,
                    onSelected: (selected) {
                      if (!selected) return;
                      setState(() {
                        _selectedSex = BodyFatGuidanceSex.male;
                      });
                    },
                  ),
                  ChoiceChip(
                    key: const Key('body_fat_guidance_sex_female'),
                    label: Text(l10n.genderFemale),
                    selected: _selectedSex == BodyFatGuidanceSex.female,
                    onSelected: (selected) {
                      if (!selected) return;
                      setState(() {
                        _selectedSex = BodyFatGuidanceSex.female;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  key: const Key('body_fat_guidance_list'),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _BodyFatGuidanceRow(
                      key: Key(
                        'body_fat_guidance_entry_${_selectedSex.name}_${entry.percent}',
                      ),
                      percentLabel: l10n.bodyFatGuidancePercent(entry.percent),
                      description: entry.description,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<BodyFatGuidanceEntry> _entriesForSex(
  AppLocalizations l10n,
  BodyFatGuidanceSex sex,
) {
  switch (sex) {
    case BodyFatGuidanceSex.male:
      return [
        BodyFatGuidanceEntry(
            percent: 10, description: l10n.bodyFatGuidanceMale10),
        BodyFatGuidanceEntry(
            percent: 15, description: l10n.bodyFatGuidanceMale15),
        BodyFatGuidanceEntry(
            percent: 20, description: l10n.bodyFatGuidanceMale20),
        BodyFatGuidanceEntry(
            percent: 25, description: l10n.bodyFatGuidanceMale25),
        BodyFatGuidanceEntry(
            percent: 30, description: l10n.bodyFatGuidanceMale30),
        BodyFatGuidanceEntry(
            percent: 35, description: l10n.bodyFatGuidanceMale35),
        BodyFatGuidanceEntry(
            percent: 40, description: l10n.bodyFatGuidanceMale40),
      ];
    case BodyFatGuidanceSex.female:
      return [
        BodyFatGuidanceEntry(
          percent: 15,
          description: l10n.bodyFatGuidanceFemale15,
        ),
        BodyFatGuidanceEntry(
          percent: 20,
          description: l10n.bodyFatGuidanceFemale20,
        ),
        BodyFatGuidanceEntry(
          percent: 25,
          description: l10n.bodyFatGuidanceFemale25,
        ),
        BodyFatGuidanceEntry(
          percent: 30,
          description: l10n.bodyFatGuidanceFemale30,
        ),
        BodyFatGuidanceEntry(
          percent: 35,
          description: l10n.bodyFatGuidanceFemale35,
        ),
        BodyFatGuidanceEntry(
          percent: 40,
          description: l10n.bodyFatGuidanceFemale40,
        ),
      ];
  }
}

class _BodyFatGuidanceRow extends StatelessWidget {
  final String percentLabel;
  final String description;

  const _BodyFatGuidanceRow({
    super.key,
    required this.percentLabel,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Text(
            percentLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            description,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
