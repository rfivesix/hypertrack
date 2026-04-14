// lib/widgets/add_menu_sheet.dart

import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';

/// A bottom sheet menu providing quick access to common entry actions.
///
/// Allows users to start a workout, add a measurement, log food, or log liquids.
class AddMenuSheet extends StatelessWidget {
  const AddMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.addMenuTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            _buildMenuOption(
              context: context,
              colorScheme: colorScheme,
              icon: Icons.fitness_center,
              title: l10n.startWorkout,
              onTap: () => Navigator.of(context).pop('start_workout'),
            ),
            const SizedBox(height: DesignConstants.spacingM),
            _buildMenuOption(
              context: context,
              colorScheme: colorScheme,
              icon: Icons.straighten_outlined,
              title: l10n.addMeasurement,
              onTap: () => Navigator.of(context).pop('add_measurement'),
            ),
            const Divider(height: 24, indent: 16, endIndent: 16),
            _buildMenuOption(
              context: context,
              colorScheme: colorScheme,
              icon: Icons.restaurant_menu,
              title: l10n.addFoodOption,
              onTap: () => Navigator.of(context).pop('add_food'),
            ),
            const SizedBox(height: DesignConstants.spacingM),
            _buildMenuOption(
              context: context,
              colorScheme: colorScheme,
              icon: Icons.local_drink,
              title: l10n.addLiquidOption,
              onTap: () => Navigator.of(context).pop('add_liquid'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required BuildContext context,
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      tileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
