import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';

class WelcomeSlide extends StatelessWidget {
  final bool isRestoring;
  final VoidCallback onContinue;
  final VoidCallback onRestore;

  const WelcomeSlide({
    super.key,
    required this.isRestoring,
    required this.onContinue,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.waving_hand_rounded,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            l10n.onboardingWelcomeTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingWelcomeSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          // Primary CTA — continue with profile setup
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('onboarding_continue_setup_button'),
              onPressed: isRestoring ? null : onContinue,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.onboardingContinueSetup.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary CTA — restore from backup
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isRestoring ? null : onRestore,
              icon: isRestoring
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restore),
              label: Text(
                isRestoring
                    ? l10n.onboardingRestoreImporting
                    : l10n.onboardingRestoreFromBackup,
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
