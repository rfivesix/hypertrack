import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'haptic_feedback_service.dart';
import 'base_food_language_service.dart';

/// Service responsible for managing the application's theme and visual style.
///
/// Persists the user's preference for light/dark mode and visual presets.
class ThemeService extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _styleKey = 'visual_style';
  static const _aiEnabledKey = 'ai_enabled';
  static const _materialColorsEnabledKey = 'material_colors_enabled';
  static const _hapticsEnabledKey = 'haptics_enabled';
  ThemeMode _themeMode = ThemeMode.system;
  int _visualStyle = 1; // 1 = Liquid (Standard), 0 = Frosted
  bool _isAiEnabled = false;
  bool _materialColorsEnabled = false;
  bool _hapticsEnabled = true;
  BaseFoodLanguage _baseFoodLanguage = BaseFoodLanguage.auto;

  /// The current theme mode (light, dark, or system).
  ThemeMode get themeMode => _themeMode;

  /// The current visual style index.
  int get visualStyle => _visualStyle;

  /// Whether AI features are enabled globally.
  bool get isAiEnabled => _isAiEnabled;

  /// Whether Android dynamic Material colors are enabled.
  bool get materialColorsEnabled => _materialColorsEnabled;

  /// Whether haptic feedback is enabled globally.
  bool get hapticsEnabled => _hapticsEnabled;

  /// The user's preferred display language for base foods.
  BaseFoodLanguage get baseFoodLanguage => _baseFoodLanguage;

  /// Creates a [ThemeService] and loads saved preferences.
  ThemeService() {
    _loadThemeMode();
    _loadVisualStyle();
    _loadAiEnabled();
    _loadMaterialColorsEnabled();
    _loadHapticsEnabled();
    _loadBaseFoodLanguage();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  // --- New method ---
  Future<void> _loadVisualStyle() async {
    final prefs = await SharedPreferences.getInstance();
    _visualStyle = prefs.getInt(_styleKey) ?? 1;
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
    _isAiEnabled = prefs.getBool(_aiEnabledKey) ?? false;
    notifyListeners();
  }

  Future<void> _loadMaterialColorsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _materialColorsEnabled = prefs.getBool(_materialColorsEnabledKey) ?? false;
    notifyListeners();
  }

  Future<void> _loadHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticsEnabled = prefs.getBool(_hapticsEnabledKey) ?? true;
    HapticFeedbackService.instance.setEnabled(_hapticsEnabled);
    notifyListeners();
  }

  Future<void> _loadBaseFoodLanguage() async {
    _baseFoodLanguage = await BaseFoodLanguageService.readChoice();
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

  /// Sets whether haptic feedback should be used across the app.
  Future<void> setHapticsEnabled(bool enabled) async {
    if (enabled == _hapticsEnabled) return;
    _hapticsEnabled = enabled;
    HapticFeedbackService.instance.setEnabled(enabled);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsEnabledKey, enabled);
  }

  /// Sets the base food display language and persists it to storage.
  Future<void> setBaseFoodLanguage(BaseFoodLanguage language) async {
    if (language == _baseFoodLanguage) return;
    _baseFoodLanguage = language;
    notifyListeners();
    await BaseFoodLanguageService.writeChoice(language);
  }
}
