import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_data_sources.dart';

/// Persists the active Open Food Facts country dataset selection.
class OffCatalogCountryService {
  const OffCatalogCountryService._();

  static const String preferenceKey = 'off_catalog_active_country';
  static const String legacyInstalledVersionKey = 'installed_off_version';
  static const String installedVersionKeyPrefix = 'installed_off_version_';

  static OffCatalogCountry readActiveCountryFromPrefs(SharedPreferences prefs) {
    return OffCatalogCountryCodec.parseOrDefault(
      prefs.getString(preferenceKey),
    );
  }

  static Future<OffCatalogCountry> readActiveCountry({
    SharedPreferences? prefs,
  }) async {
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    return readActiveCountryFromPrefs(resolvedPrefs);
  }

  static Future<void> writeActiveCountry(
    OffCatalogCountry country, {
    SharedPreferences? prefs,
  }) async {
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    await resolvedPrefs.setString(preferenceKey, country.code);
  }

  static OffCatalogRemoteSourceConfig activeSourceFromPrefs(
    SharedPreferences prefs,
  ) {
    final country = readActiveCountryFromPrefs(prefs);
    return AppDataSources.offCatalogForCountry(country);
  }

  static String installedVersionKeyForCountry(OffCatalogCountry country) {
    return '$installedVersionKeyPrefix${country.code}';
  }

  static String readInstalledVersionForCountryFromPrefs(
    SharedPreferences prefs,
    OffCatalogCountry country,
  ) {
    return prefs.getString(installedVersionKeyForCountry(country)) ?? '0';
  }

  static Future<void> writeInstalledVersionForCountry(
    OffCatalogCountry country, {
    required String version,
    SharedPreferences? prefs,
  }) async {
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    await resolvedPrefs.setString(
      installedVersionKeyForCountry(country),
      version.trim(),
    );
  }

  static Future<bool> bundledAssetAvailableForCountry(
    OffCatalogCountry country, {
    AssetBundle? bundle,
  }) async {
    final assetBundle = bundle ?? rootBundle;
    final assetPath = AppDataSources.offFoodsAssetDbPathForCountry(country);
    try {
      final ByteData data = await assetBundle.load(assetPath);
      return data.lengthInBytes > 0;
    } catch (_) {
      return false;
    }
  }
}
