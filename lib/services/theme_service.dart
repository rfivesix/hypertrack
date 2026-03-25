import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing the application's theme and visual style.
///
/// Persists the user's preference for light/dark mode and visual presets.
class ThemeService extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _styleKey = 'visual_style';
  static const _aiEnabledKey = 'ai_enabled';
  ThemeMode _themeMode = ThemeMode.system;
  int _visualStyle = 0; // 0 = Standard, 1 = Liquid
  bool _isAiEnabled = true;

  /// The current theme mode (light, dark, or system).
  ThemeMode get themeMode => _themeMode;

  /// The current visual style index.
  int get visualStyle => _visualStyle;

  /// Whether AI features are enabled globally.
  bool get isAiEnabled => _isAiEnabled;

  /// Creates a [ThemeService] and loads saved preferences.
  ThemeService() {
    _loadThemeMode();
    _loadVisualStyle();
    _loadAiEnabled();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  // --- NEUE METHODE ---
  Future<void> _loadVisualStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_styleKey) ?? 0;
    _visualStyle = stored == 2 ? 0 : stored;
    notifyListeners();
  }

  /// Sets the visual style and persists it to storage.
  Future<void> setVisualStyle(int style) async {
    final normalizedStyle = style == 2 ? 0 : style;
    if (normalizedStyle == _visualStyle) return;
    _visualStyle = normalizedStyle;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_styleKey, normalizedStyle);
  }

  /// Sets the theme mode and persists it to storage.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> _loadAiEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _isAiEnabled = prefs.getBool(_aiEnabledKey) ?? true;
    notifyListeners();
  }

  /// Sets whether AI features are enabled and persists it to storage.
  Future<void> setAiEnabled(bool enabled) async {
    if (enabled == _isAiEnabled) return;
    _isAiEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiEnabledKey, enabled);
  }
}
