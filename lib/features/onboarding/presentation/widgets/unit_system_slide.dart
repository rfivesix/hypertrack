import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';

class UnitSystemSlide extends StatelessWidget {
  final UnitSystem selectedSystem;
  final ValueChanged<UnitSystem> onSelectSystem;

  const UnitSystemSlide({
    super.key,
    required this.selectedSystem,
    required this.onSelectSystem,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.onboardingUnitSystemTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingUnitSystemSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          _UnitSystemChoiceCard(
            title: l10n.onboardingUnitMetric,
            subtitle: l10n.onboardingUnitMetricSubtitle,
            icon: Icons.straighten_rounded,
            selected: selectedSystem == UnitSystem.metric,
            onTap: () => onSelectSystem(UnitSystem.metric),
          ),
          const SizedBox(height: 16),
          _UnitSystemChoiceCard(
            title: l10n.onboardingUnitImperial,
            subtitle: l10n.onboardingUnitImperialSubtitle,
            icon: Icons.public_rounded,
            selected: selectedSystem == UnitSystem.imperial,
            onTap: () => onSelectSystem(UnitSystem.imperial),
          ),
        ],
      ),
    );
  }
}

class _UnitSystemChoiceCard extends StatelessWidget {
  const _UnitSystemChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: cs.surface.withValues(alpha: selected ? 0.96 : 0.82),
            border: Border.all(
              color:
                  selected ? cs.primary : cs.onSurface.withValues(alpha: 0.10),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: cs.shadow.withValues(alpha: 0.14),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 34, color: selected ? cs.primary : cs.onSurface),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
