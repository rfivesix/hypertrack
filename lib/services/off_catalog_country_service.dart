import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_data_sources.dart';

/// Persists the active Open Food Facts country dataset selection.
class OffCatalogCountryService {
  const OffCatalogCountryService._();

  static const String preferenceKey = 'off_catalog_active_country';

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
}
