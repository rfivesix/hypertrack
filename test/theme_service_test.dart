import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitForThemeServiceInit() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeService defaults and persistence', () {
    test('loads defaults when no preferences are saved', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final service = ThemeService();
      await _waitForThemeServiceInit();

      expect(service.themeMode, ThemeMode.system);
      expect(service.visualStyle, 1);
      expect(service.isAiEnabled, false);
      expect(service.aiCustomInstructions, '');
      expect(service.materialColorsEnabled, false);
    });

    test('loads saved preferences on initialization', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_mode': ThemeMode.dark.index,
        'visual_style': 1,
        'ai_enabled': true,
        'ai_custom_instructions': 'No peanuts',
        'material_colors_enabled': true,
      });

      final service = ThemeService();
      await _waitForThemeServiceInit();

      expect(service.themeMode, ThemeMode.dark);
      expect(service.visualStyle, 1);
      expect(service.isAiEnabled, true);
      expect(service.aiCustomInstructions, 'No peanuts');
      expect(service.materialColorsEnabled, true);
    });

    test('setters persist changed values and update observable state',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = ThemeService();
      await _waitForThemeServiceInit();

      await service.setThemeMode(ThemeMode.light);
      await service.setVisualStyle(0); // Changed from 1 to 0
      await service.setAiEnabled(true);
      await service.setAiCustomInstructions('Vegan');
      await service.setMaterialColorsEnabled(true);

      final prefs = await SharedPreferences.getInstance();
      expect(service.themeMode, ThemeMode.light);
      expect(service.visualStyle, 0); // Changed from 1 to 0
      expect(service.isAiEnabled, true);
      expect(service.aiCustomInstructions, 'Vegan');
      expect(service.materialColorsEnabled, true);
      expect(prefs.getInt('theme_mode'), ThemeMode.light.index);
      expect(prefs.getInt('visual_style'), 0); // Changed from 1 to 0
      expect(prefs.getBool('ai_enabled'), true);
      expect(prefs.getString('ai_custom_instructions'), 'Vegan');
      expect(prefs.getBool('material_colors_enabled'), true);
    });

    test('setters are no-ops when assigning existing values', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_mode': ThemeMode.dark.index,
        'visual_style': 1,
        'ai_enabled': true,
        'ai_custom_instructions': 'Vegan',
        'material_colors_enabled': true,
      });

      final service = ThemeService();
      await _waitForThemeServiceInit();
      var notifications = 0;
      service.addListener(() {
        notifications++;
      });

      await service.setThemeMode(ThemeMode.dark);
      await service.setVisualStyle(1);
      await service.setAiEnabled(true);
      await service.setAiCustomInstructions('Vegan');
      await service.setMaterialColorsEnabled(true);

      expect(notifications, 0);
    });
  });
}
