import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/haptic_feedback_service.dart';
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasLabel = widget.label != null;
    final glassColor = Color.alphaBlend(
      cs.surfaceTint.withValues(alpha: isDark ? 0.08 : 0.04),
      cs.surface.withValues(alpha: isDark ? 0.62 : 0.72),
    );
    final rimColor = cs.onSurface.withValues(alpha: 0.08);
    final contentColor = cs.onSurface;
    final Color neutralTint = cs.onSurface.withValues(alpha: 0.08);
    final Color effectiveGlass = Color.alphaBlend(
      neutralTint,
      glassColor,
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
            color: contentColor,
          ),
          if (hasLabel) ...[
            const SizedBox(width: 12),
            Text(
              widget.label!,
              style: TextStyle(
                color: contentColor,
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
                  // PILL: width from content + padding
                  ? Container(
                      height: 65.0,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      decoration: BoxDecoration(
                        color: neutralTint, // << Base tint
                        borderRadius: BorderRadius.circular(99),
                      ),
                      foregroundDecoration: BoxDecoration(
                        // << Rim layered on top
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: rimColor,
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
                            color: contentColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.label!,
                            style: TextStyle(
                              color: contentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  // Circle: fixed 76x76
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
                          color: rimColor,
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        widget.icon,
                        size: 30,
                        color: contentColor,
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
                color: glassColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: rimColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                    color: cs.shadow.withValues(alpha: 0.16),
                  ),
                ],
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
