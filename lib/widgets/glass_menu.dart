import 'dart:ui';
import 'package:flutter/material.dart';
import '../util/design_constants.dart';

/// Model for an item within the [GlassMenu].
class GlassMenuItem {
  /// The icon representing the menu item.
  final IconData icon;

  /// The text label for the menu item.
  final String label;

  /// Callback when the menu item is tapped.
  final VoidCallback onTap;

  GlassMenuItem({required this.icon, required this.label, required this.onTap});
}

/// A full-screen glass-styled menu overlay with animating items.
class GlassMenu extends StatefulWidget {
  /// The list of items to display in the menu.
  final List<GlassMenuItem> items;

  /// Callback triggered when the menu should be dismissed.
  final VoidCallback onDismiss;

  const GlassMenu({super.key, required this.items, required this.onDismiss});

  @override
  State<GlassMenu> createState() => _GlassMenuState();
}

class _GlassMenuState extends State<GlassMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.4),
        body: Center(
          child: Wrap(
            spacing: 24,
            runSpacing: 24,
            children: List.generate(widget.items.length, (index) {
              final item = widget.items[index];
              final intervalStart = index * 0.1;
              final intervalEnd = intervalStart + 0.5;

              final animation = CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  intervalStart,
                  intervalEnd,
                  curve: Curves.easeOutBack,
                ),
              );

              return ScaleTransition(
                scale: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: GestureDetector(
                    onTap: () {
                      item.onTap();
                      widget.onDismiss();
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildGlassIcon(item.icon),
                        const SizedBox(height: DesignConstants.spacingM),
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIcon(IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, size: 34, color: Colors.white),
        ),
      ),
    );
  }
}
