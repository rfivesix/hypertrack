// lib/util/mapping_prefs.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility for managing exercise name mappings between external apps and Train Libre.
///
/// Persists user-defined mappings in [SharedPreferences] to handle CSV imports.
class MappingPrefs {
  static const _kKey = 'exercise_name_mappings_v1';

  /// Loads all current name mappings from persistence.
  static Future<Map<String, String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final Map<String, dynamic> m = jsonDecode(raw);
      return m.map((k, v) => MapEntry(_norm(k), (v as String?)?.trim() ?? ''));
    } catch (_) {
      return {};
    }
  }

  // Fügt/aktualisiert Einträge und speichert als JSON-String.
  static Future<void> upsert(Map<String, String> entries) async {
    if (entries.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    entries.forEach((k, v) {
      final key = _norm(k);
      final val = (v).trim();
      if (val.isNotEmpty) current[key] = val;
    });
    await prefs.setString(_kKey, jsonEncode(current));
  }

  // Holt eine Zielzuordnung, falls vorhanden.
  static Future<String?> lookup(String externalName) async {
    final m = await load();
    return m[_norm(externalName)];
  }

  static String _norm(String s) => s.trim().toLowerCase();
}
