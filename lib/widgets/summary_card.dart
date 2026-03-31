import 'package:flutter/material.dart';
import '../theme/color_constants.dart';

/// A standardized card for displaying summary information with a glass aesthetic.
///
/// Automatically adapts its background color and transparency to the current theme.
class SummaryCard extends StatelessWidget {
  /// The main content to display inside the card.
  final Widget child;

  /// Internal padding for the [child].
  final EdgeInsetsGeometry padding;

  /// Optional margin for the card container.
  final EdgeInsetsGeometry margin;

  /// Optional tap handler for the card.
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12.0),
    this.margin = const EdgeInsets.symmetric(vertical: 6.0),
    this.onTap,
  });

  ///*
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final background = brightness == Brightness.dark
        ? summary_card_dark_mode
        : summary_card_white_mode;

    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        //borderRadius: BorderRadius.circular(10),
        borderRadius: BorderRadius.circular(20),
        /*
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        */
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
  }
}

//*/
/*
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // KORREKTUR: Hintergrund im Light Mode weniger transparent für besseren Kontrast
    final backgroundColor = brightness == Brightness.dark
        ? Colors.white.withOpacity(0.10)
        : Colors.white.withOpacity(0.65); // War 0.40, jetzt weniger durchsichtig

    // KORREKTUR: Randfarbe im Light Mode ist jetzt ein dunkles Grau statt Weiß
    final borderColor = brightness == Brightness.dark
        ? Colors.white.withOpacity(0.20)
        : Colors.black.withOpacity(0.12); // War Weiß, jetzt dunkles Grau mit Transparenz

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      // WICHTIG: Kein Padding mehr direkt hier, wird jetzt vom Child gesteuert
      // padding: padding, // Diese Zeile entfernen oder auskommentieren
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: const [],
      ),
      // WICHTIG: ClipRRect, damit der Blur-Effekt die Ecken respektiert
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          // Der eigentliche "Frostglas"-Effekt
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Padding(
            // Das Padding wird jetzt innerhalb des Blur-Effekts angewendet
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
*/
