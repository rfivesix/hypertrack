import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing the application's theme and visual style.
///
/// Persists the user's preference for light/dark mode and visual presets.
class ThemeService extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _styleKey = 'visual_style';
  static const _aiEnabledKey = 'ai_enabled';
  static const _materialColorsEnabledKey = 'material_colors_enabled';
  ThemeMode _themeMode = ThemeMode.system;
  int _visualStyle = 0; // 0 = Standard, 1 = Liquid
  bool _isAiEnabled = true;
  bool _materialColorsEnabled = false;

  /// The current theme mode (light, dark, or system).
  ThemeMode get themeMode => _themeMode;

  /// The current visual style index.
  int get visualStyle => _visualStyle;

  /// Whether AI features are enabled globally.
  bool get isAiEnabled => _isAiEnabled;

  /// Whether Android dynamic Material colors are enabled.
  bool get materialColorsEnabled => _materialColorsEnabled;

  /// Creates a [ThemeService] and loads saved preferences.
  ThemeService() {
    _loadThemeMode();
    _loadVisualStyle();
    _loadAiEnabled();
    _loadMaterialColorsEnabled();
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
    _visualStyle = prefs.getInt(_styleKey) ?? 0;
    notifyListeners();
  }

  /// Sets the visual style and persists it to storage.
  Future<void> setVisualStyle(int style) async {
    if (style == _visualStyle) return;
    _visualStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_styleKey, style);
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

  Future<void> _loadMaterialColorsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _materialColorsEnabled = prefs.getBool(_materialColorsEnabledKey) ?? false;
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

  /// Sets whether Android dynamic Material colors should be used.
  Future<void> setMaterialColorsEnabled(bool enabled) async {
    if (enabled == _materialColorsEnabled) return;
    _materialColorsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_materialColorsEnabledKey, enabled);
  }
}
