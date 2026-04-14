import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/haptic_feedback_service.dart';
import '../theme/color_constants.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';

/// A floating action button with a premium glass aesthetic.
///
/// Can be displayed as a circle (icon only) or a pill (icon and [label]).
class GlassFab extends StatefulWidget {
  /// Callback when the button is pressed.
  final VoidCallback onPressed;

  /// The icon to display.
  final IconData icon;

  /// Optional label to display next to the icon, turning the FAB into a pill.
  final String? label;

  const GlassFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.label,
  });

  @override
  State<GlassFab> createState() => _GlassFabState();
}

class _GlassFabState extends State<GlassFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    HapticFeedbackService.instance.lightImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? summaryCardDarkMode : summaryCardWhiteMode;
    final hasLabel = widget.label != null;
    final Color neutralTint = (isDark ? Colors.white : Colors.black)
        .withValues(alpha: isDark ? 0.1 : 0.1);
    final Color effectiveGlass = Color.alphaBlend(
      neutralTint,
      bg.withValues(alpha: isDark ? 0.8 : 0.5),
    );

    final iconAndText = Padding(
      padding: hasLabel
          ? const EdgeInsets.symmetric(horizontal: 24.0)
          : EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.icon,
            size: 30,
            color: isDark ? Colors.white : Colors.black,
          ),
          if (hasLabel) ...[
            const SizedBox(width: 12),
            Text(
              widget.label!,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ],
      ),
    );

    Widget content;

    switch (themeService.visualStyle) {
      case 1:
        final hasLabel = widget.label != null;

        content = LiquidStretch(
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
            shape: hasLabel
                ? const LiquidRoundedSuperellipse(borderRadius: 99)
                : const LiquidOval(),
            child: GlassGlow(
              glowColor: Colors.white.withValues(alpha: isDark ? 0.24 : 0.18),
              glowRadius: 1.0,
              child: hasLabel
                  // PILLE: Breite aus Inhalt + Padding
                  ? Container(
                      height: 65.0,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      decoration: BoxDecoration(
                        color: neutralTint, // << Grundtönung
                        borderRadius: BorderRadius.circular(99),
                      ),
                      foregroundDecoration: BoxDecoration(
                        // << Rim oben drauf
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.20)
                              : Colors.black.withValues(alpha: 0.08),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.icon,
                            size: 30,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.label!,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  // KREIS: feste 76×76
                  : Container(
                      height: 65.0,
                      width: 65.0,
                      decoration: BoxDecoration(
                        color: neutralTint,
                        borderRadius: BorderRadius.circular(999), // „Kreis“
                      ),
                      foregroundDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.20)
                              : Colors.black.withValues(alpha: 0.08),
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        widget.icon,
                        size: 30,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
            ),
          ),
        );
        break;

      default:
        content = ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 76,
              width: hasLabel ? null : 76,
              decoration: BoxDecoration(
                color: bg.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: iconAndText,
            ),
          ),
        );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - _controller.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: content,
      ),
    );
  }
}
