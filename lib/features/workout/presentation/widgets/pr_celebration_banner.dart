import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium, glassmorphic sliding banner that celebrates personal records (PRs).
class PrCelebrationBanner extends StatelessWidget {
  /// The slide-in transition animation.
  final Animation<Offset> slideAnimation;

  /// The name of the exercise achieved.
  final String exerciseName;

  /// The localized description of the record type (e.g., "Best Max Weight").
  final String localizedRecordType;

  /// The formatted achievement value (e.g., "100 kg").
  final String achievementText;

  /// The optional difference text compared to the previous PR (e.g., "(+5 kg)").
  final String diffText;

  const PrCelebrationBanner({
    super.key,
    required this.slideAnimation,
    required this.exerciseName,
    required this.localizedRecordType,
    required this.achievementText,
    required this.diffText,
  });

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = isLightMode
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.8);
    final borderColor = isLightMode
        ? Colors.grey.withValues(alpha: 0.3)
        : Colors.amber.withValues(alpha: 0.4);
    final primaryTextColor = isLightMode ? Colors.black : Colors.white;
    final secondaryTextColor = isLightMode ? Colors.black87 : Colors.white70;

    return SlideTransition(
      position: slideAnimation,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      exerciseName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                              children: [
                                TextSpan(text: "$localizedRecordType - "),
                                TextSpan(
                                  text: achievementText,
                                  style: const TextStyle(color: Colors.amber),
                                ),
                                if (diffText.isNotEmpty)
                                  TextSpan(
                                    text: diffText,
                                    style: TextStyle(
                                      color: Colors.amber.withValues(alpha: 0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
