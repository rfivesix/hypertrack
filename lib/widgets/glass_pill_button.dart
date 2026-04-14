import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/haptic_feedback_service.dart';
import '../theme/color_constants.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';

/// Reusable liquid-glass Pill / Bubble.
/// - Nutze [child], um beliebige Inhalte (Icon, Text, mehrere Elemente) zu platzieren.
/// - Wenn [onTap] gesetzt ist: leichter Scale-Effekt + HapticFeedback.
/// - Wenn [onTap] null ist: nur Surface, innere Widgets können eigene Gesten haben.
/// A reusable pill-shaped button with a glass aesthetic.
///
/// Supports both simple icons and complex [child] layouts with optional [onTap] feedback.
class GlassPillButton extends StatefulWidget {
  /// The content to display inside the pill.
  final Widget child;

  /// Optional callback for tap events; if null, the button is non-interactive.
  final VoidCallback? onTap;

  /// Internal padding for the [child].
  final EdgeInsetsGeometry padding;

  /// Fixed height of the pill.
  final double height;

  /// Corner radius for the pill shape.
  final double borderRadius;

  const GlassPillButton({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.height = 32,
    this.borderRadius = 99,
  });

  @override
  State<GlassPillButton> createState() => _GlassPillButtonState();
}

class _GlassPillButtonState extends State<GlassPillButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _hasTap => widget.onTap != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.10,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (_hasTap) _controller.forward();
  }

  void _onTapCancel() {
    if (_hasTap) _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    if (_hasTap) {
      _controller.reverse();
      HapticFeedbackService.instance.lightImpact();
      widget.onTap!.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? summary_card_dark_mode : summary_card_white_mode;

    final Color neutralTint =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10);
    final Color effectiveGlass = Color.alphaBlend(
      neutralTint,
      bg.withValues(alpha: isDark ? 0.8 : 0.5),
    );

    // Adaptive border radius: round if not Row, pill if Row
    final bool isCircle = widget.child is! Row;
    final double effectiveRadius =
        isCircle ? widget.height / 2 : widget.borderRadius;

    Widget surface;

    if (themeService.visualStyle == 1) {
      // Liquid-Style (mit LiquidStretch)
      surface = LiquidStretch(
        stretch: 0.55,
        interactionScale: 1.04,
        child: LiquidGlass.withOwnLayer(
          settings: LiquidGlassSettings(
            thickness: 25,
            blur: 5,
            glassColor: effectiveGlass,
            lightIntensity: 0.35,
            saturation: 1.10,
          ),
          shape: LiquidRoundedSuperellipse(borderRadius: effectiveRadius),
          child: GlassGlow(
            glowColor: Colors.white.withValues(alpha: isDark ? 0.24 : 0.18),
            glowRadius: 1.0,
            child: Container(
              // height and width removed here; enforced outside with SizedBox
              padding: isCircle ? EdgeInsets.zero : widget.padding,
              decoration: BoxDecoration(
                color: neutralTint,
                borderRadius: BorderRadius.circular(effectiveRadius),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(effectiveRadius),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.20)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1.2,
                ),
              ),
              child: Center(child: widget.child),
            ),
          ),
        ),
      );
    } else {
      // Fallback-Glass
      surface = ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            // height and width removed here; enforced outside with SizedBox
            padding: isCircle ? EdgeInsets.zero : widget.padding,
            decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(effectiveRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.30)
                    : Colors.black.withValues(alpha: 0.10),
                width: 1.5,
              ),
            ),
            child: Center(child: widget.child),
          ),
        ),
      );
    }

    // Wrap the surface in a SizedBox to enforce height and width
    final Widget constrainedSurface = SizedBox(
      height: widget.height,
      width: isCircle ? widget.height : null,
      child: surface,
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _hasTap ? _onTapDown : null,
      onTapUp: _hasTap ? _onTapUp : null,
      onTapCancel: _hasTap ? _onTapCancel : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - _controller.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: constrainedSurface,
      ),
    );
  }
}
