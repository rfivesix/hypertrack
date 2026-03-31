// lib/widgets/global_app_bar.dart

import 'dart:ui';
import 'package:flutter/material.dart';

/// A standardized AppBar for the application with a frosted glass background.
///
/// Implements [PreferredSizeWidget] and provides a consistent look across screens.
class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Simple text title.
  final String? title;

  /// Custom widget for the title area; takes precedence over [title].
  final Widget? titleWidget;

  /// List of actions to display at the end of the bar.
  final List<Widget>? actions;

  /// Custom leading widget; usually a back button or menu icon.
  final Widget? leading;

  /// Whether to automatically show a back button if the route allows it.
  final bool automaticallyImplyLeading;

  /// Space between the leading widget and the title.
  final double? titleSpacing;

  const GlobalAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.titleSpacing,
  }) : assert(
         title == null || titleWidget == null,
         'Cannot provide both a title and a titleWidget',
       );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Der sichtbare Inhalt der AppBar (Titel, Icons etc.)
    final appBarContent = AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: theme.colorScheme.onSurface,
      centerTitle: false,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: titleSpacing,
      title:
          titleWidget ??
          Text(
            title ?? '',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
      actions: actions,
    );

    // Farbe für das durchscheinende "Glas"
    final Color glassColor = isDark
        ? Colors.black.withOpacity(0.5)
        : Colors.white.withOpacity(0.3);

    // Die finale Struktur mit statischem Blur
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          // Die Decoration sorgt für die Farbe und die untere Kante
          decoration: BoxDecoration(
            color: glassColor,
            //border: Border(
            //  bottom: BorderSide(color: dividerColor, width: 0.5),
            //),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(height: kToolbarHeight, child: appBarContent),
          ),
        ),
      ),
    );
  }
}
