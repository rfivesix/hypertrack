import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Native/adaptive bottom navigation bar powered by `adaptive_platform_ui`.
///
/// - iOS 26+: `IOS26NativeTabBar` (native UITabBar)
/// - iOS <26: `CupertinoTabBar`
/// - Android: `NavigationBar`
class AdaptiveBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const AdaptiveBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  static const Map<IconData, String> _sfSymbolMap = {
    Icons.book_outlined: 'book',
    Icons.book: 'book',
    Icons.fitness_center_outlined: 'figure.strengthtraining.traditional',
    Icons.fitness_center: 'figure.strengthtraining.traditional',
    Icons.bar_chart_outlined: 'chart.bar',
    Icons.bar_chart: 'chart.bar',
    Icons.restaurant_menu_rounded: 'fork.knife',
    Icons.restaurant: 'fork.knife',
    Icons.restaurant_menu: 'fork.knife',
  };

  IconData _toIconData(Widget widget) {
    if (widget is Icon && widget.icon != null) {
      return widget.icon!;
    }
    return Icons.circle;
  }

  String _toSfSymbol(IconData icon) {
    return _sfSymbolMap[icon] ?? 'circle';
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26NativeTabBar(
        destinations: items
            .map(
              (item) => AdaptiveNavigationDestination(
                icon: _toSfSymbol(_toIconData(item.icon)),
                selectedIcon: item.activeIcon != null
                    ? _toSfSymbol(_toIconData(item.activeIcon!))
                    : null,
                label: item.label ?? '',
              ),
            )
            .toList(),
        selectedIndex: currentIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          onTap(index);
        },
      );
    }

    if (PlatformInfo.isIOS) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          onTap(index);
        },
        items: items
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(_toIconData(item.icon)),
                activeIcon: item.activeIcon != null
                    ? Icon(_toIconData(item.activeIcon!))
                    : null,
                label: item.label,
              ),
            )
            .toList(),
      );
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        HapticFeedback.lightImpact();
        onTap(index);
      },
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: Icon(_toIconData(item.icon)),
              selectedIcon: item.activeIcon != null
                  ? Icon(_toIconData(item.activeIcon!))
                  : null,
              label: item.label ?? '',
            ),
          )
          .toList(),
    );
  }
}
