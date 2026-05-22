import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../../../../services/theme_service.dart';
import '../../../../theme/color_constants.dart';
import '../../../../generated/app_localizations.dart';

class RunningWorkoutOverlay extends StatelessWidget {
  final String elapsedDuration;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;

  const RunningWorkoutOverlay({
    super.key,
    required this.elapsedDuration,
    required this.onContinue,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? summaryCardDarkMode : summaryCardWhiteMode;
    final themeService = context.watch<ThemeService>();

    final Color neutralTint = (isDark ? Colors.white : Colors.black)
        .withValues(alpha: isDark ? 0.1 : 0.1);
    final Color effectiveGlass = Color.alphaBlend(
      neutralTint,
      bg.withValues(alpha: isDark ? 0.8 : 0.5),
    );

    Widget child = _RunningWorkoutRow(
      timeText: elapsedDuration,
      onContinue: onContinue,
      onDiscard: onDiscard,
      l10n: l10n,
    );

    if (themeService.visualStyle == 1) {
      double radius = 99;
      return SizedBox(
        height: 65.0,
        child: LiquidStretch(
          stretch: 0.2,
          interactionScale: 1.04,
          child: LiquidGlass.withOwnLayer(
            settings: LiquidGlassSettings(
              thickness: 30,
              blur: 0.75,
              glassColor: effectiveGlass,
              lightIntensity: 0.35,
              saturation: 1.10,
            ),
            shape: LiquidRoundedSuperellipse(borderRadius: radius),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: neutralTint),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius.toDouble()),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.20)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 1.2,
                    ),
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      );
    }
    double radius = 20;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius.toDouble()),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(radius.toDouble()),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.30)
                  : Colors.black.withValues(alpha: 0.10),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                offset: const Offset(0, 6),
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RunningWorkoutRow extends StatelessWidget {
  final String timeText;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;
  final AppLocalizations l10n;

  const _RunningWorkoutRow({
    required this.timeText,
    required this.onContinue,
    required this.onDiscard,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20),
              const SizedBox(width: 6),
              Text(
                timeText,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.9),
                  decoration: TextDecoration.none,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            minimumSize: const Size(0, 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(l10n.continue_workout_button),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onDiscard,
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
            minimumSize: const Size(0, 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(l10n.discard_button),
        ),
      ],
    );
  }
}
