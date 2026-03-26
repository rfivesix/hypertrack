// lib/widgets/glass_bottom_menu.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../generated/app_localizations.dart';
import '../services/theme_service.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';

/// Represents an action item within a [showGlassBottomMenu].
class GlassMenuAction {
  /// Optional standard material icon.
  final IconData? icon; // Jetzt nullable
  /// Optional custom widget for the icon area (e.g., initials or custom shape).
  final Widget? customIcon; // NEU: Für deine Buchstaben
  /// The main text label for the action.
  final String label;

  /// Optional secondary text providing more context.
  final String? subtitle;

  /// Callback triggered when the action is selected.
  final VoidCallback onTap;

  GlassMenuAction({
    this.icon,
    this.customIcon, // NEU
    required this.label,
    this.subtitle,
    required this.onTap,
  }) : assert(
          icon != null || customIcon != null,
          'Icon or customIcon must be provided',
        );
}

// ... (showGlassBottomMenu und _GlassBottomMenuSheet bleiben unverändert) ...
// ... BITTE DEN CODE DAZWISCHEN NICHT LÖSCHEN, NUR ÜBERSPRINGEN ...

/// Shows a premium glass-styled modal bottom sheet.
///
/// Can display either a list of [actions] or custom [contentBuilder] content.
Future<T?> showGlassBottomMenu<T>({
  required BuildContext context,
  String? title,
  List<GlassMenuAction>? actions,
  Widget Function(BuildContext, VoidCallback)? contentBuilder,
}) {
  assert(
    (actions != null && contentBuilder == null) ||
        (actions == null && contentBuilder != null),
    'Either actions OR contentBuilder must be provided',
  );

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final themeService = Provider.of<ThemeService>(context, listen: false);
  final bool isLiquid = themeService.visualStyle == 1;

  final Color barrierColor = isDark
      ? (!isLiquid
          ? Colors.grey.withOpacity(0.187)
          : Colors.black.withOpacity(0.5))
      : Colors.black.withOpacity(0.3);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor,
    builder: (ctx) {
      final kb = MediaQuery.of(ctx).viewInsets.bottom;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: kb),
        child: _GlassBottomMenuSheet(
          title: title,
          actions: actions ?? const <GlassMenuAction>[],
          contentBuilder: contentBuilder,
        ),
      );
    },
  );
}

class _GlassBottomMenuSheet extends StatelessWidget {
  const _GlassBottomMenuSheet({
    this.title,
    this.contentBuilder,
    this.actions = const <GlassMenuAction>[],
  });

  final String? title;
  final Widget Function(BuildContext, VoidCallback)? contentBuilder;
  final List<GlassMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    // ... (Dieser Teil bleibt 1:1 identisch wie in deiner aktuellen Datei) ...
    // ...
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = media.viewPadding.bottom;
    final themeService = context.watch<ThemeService>();

    final Color neutralTint = (isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.22));

    final Color effectiveGlass = Color.alphaBlend(
      neutralTint,
      theme.colorScheme.surface.withOpacity(isDark ? 0.8 : 0.5),
    );

    const double r = 24;
    const EdgeInsets outerMargin = EdgeInsets.fromLTRB(16, 0, 16, 16);

    Widget contentColumn() {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (contentBuilder != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: contentBuilder!(
                  context,
                  () => Navigator.of(context).maybePop(),
                ),
              ),
            ] else if (actions.isNotEmpty) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(actions.length, (i) {
                        final a = actions[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _GlassTile(
                            icon: a.icon,
                            customIcon: a.customIcon, // <--- NEU übergeben
                            title: a.label,
                            subtitle: a.subtitle,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.of(context).maybePop();
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => a.onTap(),
                              );
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // ... (liquidCard und plainCard bleiben identisch, hier gekürzt) ...
    Widget liquidCard() {
      return Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
            ),
          ),
          LiquidGlass.withOwnLayer(
            settings: LiquidGlassSettings(
              thickness: 30,
              blur: 8,
              glassColor: effectiveGlass,
              lightIntensity: 0.35,
              saturation: 1.10,
            ),
            shape: const LiquidRoundedSuperellipse(borderRadius: r),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: neutralTint,
                      borderRadius: BorderRadius.circular(r),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(r),
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
                contentColumn(),
              ],
            ),
          ),
        ],
      );
    }

    Widget plainCard() {
      return Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(
                    isDark ? 0.80 : 0.92,
                  ),
                ),
                child: contentColumn(),
              ),
            ),
          ),
        ],
      );
    }

    return SafeArea(
      top: false,
      bottom: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: outerMargin,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: themeService.visualStyle == 1 ? liquidCard() : plainCard(),
          ),
        ),
      ),
    );
  }
}
// In lib/widgets/glass_bottom_menu.dart

class _GlassTile extends StatelessWidget {
  const _GlassTile({
    this.icon,
    this.customIcon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData? icon;
  final Widget? customIcon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;
    final themeService = context.watch<ThemeService>();

    // Hintergrund-Tint etwas anpassen
    final Color neutralTint =
        (isDark ? Colors.white : Colors.black).withOpacity(0.05);

    final Color effectiveGlass = Color.alphaBlend(
      neutralTint,
      Colors.white.withOpacity(isDark ? 0.10 : 0.12),
    );

    final Widget leadingWidget =
        customIcon != null ? customIcon! : Icon(icon, size: 22);

    final tileContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.14 : 0.18),
                width: 1,
              ),
            ),
            child: Center(child: leadingWidget),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: textTheme.bodySmall?.color?.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );

    if (themeService.visualStyle == 1) {
      return LiquidGlass.withOwnLayer(
        settings: LiquidGlassSettings(
          // HIER GEÄNDERT: thickness 0 entfernt die Verzerrung/Verschiebung
          thickness: 0,
          blur: 5,
          glassColor: effectiveGlass,
          // HIER GEÄNDERT: Weniger Lichtintensität reduziert harte Kanten
          lightIntensity: 0.1,
          saturation: 1.10,
        ),
        shape: const LiquidRoundedSuperellipse(borderRadius: 18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    // BorderRadius hier hilft zusätzlich bei der visuellen Abgrenzung
                    decoration: BoxDecoration(
                      color: neutralTint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                tileContent,
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: tileContent),
    );
  }
}

/// Eine wiederverwendbare Lösch-Bestätigung im Glas-Design.
/// Gibt true zurück, wenn gelöscht werden soll.
Future<bool> showDeleteConfirmation(
  BuildContext context, {
  String? title,
  String? content,
  String? confirmLabel,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final effectiveTitle = title ?? l10n.deleteConfirmTitle;
  final effectiveContent = content ?? l10n.deleteConfirmContent;
  final effectiveConfirmLabel = confirmLabel ?? l10n.delete;

  final result = await showGlassBottomMenu<bool>(
    context: context,
    title: effectiveTitle,
    contentBuilder: (ctx, close) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              effectiveContent,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    close();
                    Navigator.of(ctx).pop(false);
                  },
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    close();
                    Navigator.of(ctx).pop(true);
                  },
                  child: Text(effectiveConfirmLabel),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  return result ?? false;
}
