/// Global color constants used throughout the application.
///
/// Defines primary, secondary, and surface colors for both light and dark modes
/// to ensure visual consistency across the UI.
library;
// lib/theme/color_constants.dart

import 'package:flutter/material.dart';

/// The primary brand color for Train Libre, sourced from the app icon.
const Color brandAccentColor = Color(0xFFDDFF00);

/// A darkened version of the brand color for better contrast in Light Mode.
const Color brandAccentColorLightMode = Color(0xFF8B9E00);

/// The standard colors used for AI-related gradients and accents.
const List<Color> aiGradientColors = [
  Color(0xFFE88DCC),
  Color(0xFFF4A77A),
  Color(0xFFF7D06B),
  Color(0xFF7DDEAE),
  Color(0xFF6DC8D9),
];

/// Creates a linear gradient shader for AI-themed icons and elements.
Shader createAiGradientShader(Rect bounds) {
  return const LinearGradient(
    colors: aiGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ).createShader(bounds);
}

const Color summaryCardDarkMode = Color.fromARGB(
  255,
  40,
  40,
  40,
); // Deep gray for dark mode
const Color summaryCardWhiteMode = Color.fromARGB(
  255,
  235,
  235,
  235,
); // Very light gray for light mode
