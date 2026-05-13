// lib/screens/initial_consent_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../generated/app_localizations.dart';
import '../widgets/summary_card.dart';
import 'legal_screen.dart';

class InitialConsentScreen extends StatefulWidget {
  final Widget nextScreen;

  const InitialConsentScreen({super.key, required this.nextScreen});

  @override
  State<InitialConsentScreen> createState() => _InitialConsentScreenState();
}

class _InitialConsentScreenState extends State<InitialConsentScreen> {
  bool _isAgreed = false;

  Future<void> _acceptAndProceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasAcceptedConsent', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => widget.nextScreen,
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Blurred background with app icon or placeholder
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Center(
                child: Opacity(
                  opacity: 0.2,
                  child: SvgPicture.asset(
                    'assets/icon/train-libre_icon_dark_green_no_bg.svg',
                    width: 200,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),
          // Consent Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: SummaryCard(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.welcome_privacy_title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.welcome_privacy_body,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    // Links
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const LegalScreen()),
                        ),
                        child: Text(
                            '${l10n.legal_notice} & ${l10n.privacy_policy}'),
                      ),
                    ),
                    const Divider(),
                    CheckboxListTile(
                      value: _isAgreed,
                      onChanged: (val) =>
                          setState(() => _isAgreed = val ?? false),
                      title: Text(
                        l10n.i_agree_to_privacy_policy,
                        style: theme.textTheme.bodySmall,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isAgreed ? _acceptAndProceed : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(l10n.accept_and_get_started),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
