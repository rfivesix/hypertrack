import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';
import '../theme/color_constants.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';

/// A premium glass-styled navigation bar with haptic feedback and fluid animations.
///
/// Supports standard [items] and a custom [onFabTap] for a central action button.
class GlassBottomNavBar extends StatelessWidget {
  /// The index of the currently active tab.
  final int currentIndex;

  /// Callback when a tab is tapped.
  final ValueChanged<int> onTap;

  /// Callback when the floating action area is tapped.
  final VoidCallback onFabTap;

  /// The list of navigation items to display.
  final List<BottomNavigationBarItem> items;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
    required this.items,
  });

  Widget _buildNavItem(
    BuildContext context,
    BottomNavigationBarItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDarkLocal = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? cs.primary
        : (isDarkLocal ? Colors.white : Colors.black);
    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme(
                  data: IconThemeData(color: color, size: 18),
                  child: item.icon,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label ?? '',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mappt eine lokale X-Position (0..width) auf den Tab-Index.
  int _indexFromDx(double dx, double width, int itemCount) {
    if (width <= 0 || itemCount <= 0) return 0;
    final frac = (dx / width).clamp(0.0, 0.9999);
    final idx = (frac * itemCount).floor();
    return idx.clamp(0, itemCount - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? summary_card_dark_mode : summary_card_white_mode;
    final themeService = context.watch<ThemeService>();

    final navItemsRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == currentIndex;
          return _buildNavItem(context, item, isSelected, () => onTap(index));
        }),
      ],
    );

    final double barHeight = themeService.visualStyle == 1 ? 65 : 76.0;

    switch (themeService.visualStyle) {
      case 1:
        // neutrale Tönung ableiten (funktioniert auf Weiß & Schwarz)
        final Color neutralTint = (isDark ? Colors.white : Colors.black)
            .withOpacity(isDark ? 0.1 : 0.1);

        // smarteres Glas: bg-Color + neutraler Tint "verheiraten"
        final Color effectiveGlass = Color.alphaBlend(
          neutralTint,
          bg.withOpacity(isDark ? 0.8 : 0.5),
        );

        // Drag-to-select + Release-to-activate: über GestureDetector
        return LayoutBuilder(
          builder: (context, constraints) {
            double? lastDx;
            int? lastHoverIndex;
            final barWidth = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) {
                final idx = _indexFromDx(
                  details.localPosition.dx,
                  barWidth,
                  items.length,
                );
                onTap(idx);
                HapticFeedback.lightImpact(); // Feedback bei einfachem Tap
              },
              onPanStart: (details) {
                lastDx = details.localPosition.dx;
                final idx = _indexFromDx(lastDx!, barWidth, items.length);
                lastHoverIndex = idx;
                HapticFeedback.selectionClick(); // leichtes Feedback beim ersten Kontakt
              },
              onPanUpdate: (details) {
                lastDx = details.localPosition.dx;
                final idx = _indexFromDx(lastDx!, barWidth, items.length);
                if (idx != lastHoverIndex) {
                  lastHoverIndex = idx;
                  HapticFeedback.lightImpact(); // leichtes Feedback beim Wechseln der Zone
                }
              },
              onPanEnd: (_) {
                if (lastHoverIndex != null) {
                  onTap(lastHoverIndex!);
                }
                lastDx = null;
                lastHoverIndex = null;
              },
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
                  shape: const LiquidRoundedSuperellipse(borderRadius: 99),
                  child: GlassGlow(
                    glowColor: Colors.white.withOpacity(isDark ? 0.24 : 0.18),
                    glowRadius: 1.0,
                    child: SizedBox(
                      height: barHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: neutralTint),
                            ),
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: navItemsRow,
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.20)
                                        : Colors.black.withOpacity(0.08),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );

      default:
        // Standard: bisheriger Backdrop-Filter
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: barHeight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: bg.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.30)
                      : Colors.black.withOpacity(0.10),
                  width: 1.5,
                ),
              ),
              child: navItemsRow,
            ),
          ),
        );
    }
  }
}
