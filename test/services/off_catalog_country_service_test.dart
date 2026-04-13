import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/config/app_data_sources.dart';
import 'package:hypertrack/services/off_catalog_country_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OffCatalogCountryService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to DE when preference is unset', () async {
      final prefs = await SharedPreferences.getInstance();
      final activeCountry = OffCatalogCountryService.readActiveCountryFromPrefs(
        prefs,
      );

      expect(activeCountry, OffCatalogCountry.de);
      final config = OffCatalogCountryService.activeSourceFromPrefs(prefs);
      expect(config.releaseTag, 'off-foods-de-stable');
      expect(config.manifestPath, 'off_catalog_manifest_de.json');
    });

    test('writes and reads active country preference', () async {
      final prefs = await SharedPreferences.getInstance();

      await OffCatalogCountryService.writeActiveCountry(
        OffCatalogCountry.us,
        prefs: prefs,
      );

      expect(
        prefs.getString(OffCatalogCountryService.preferenceKey),
        'us',
      );

      final activeCountry = await OffCatalogCountryService.readActiveCountry(
        prefs: prefs,
      );
      expect(activeCountry, OffCatalogCountry.us);

      final config = OffCatalogCountryService.activeSourceFromPrefs(prefs);
      expect(config.releaseTag, 'off-foods-us-stable');
      expect(config.manifestPath, 'off_catalog_manifest_us.json');
      expect(config.sourceId, 'off_food_catalog');
      expect(config.channel, 'stable');
    });

    test('invalid stored value safely falls back to default', () async {
      SharedPreferences.setMockInitialValues({
        OffCatalogCountryService.preferenceKey: 'fr',
      });
      final prefs = await SharedPreferences.getInstance();

      final activeCountry = OffCatalogCountryService.readActiveCountryFromPrefs(
        prefs,
      );

      expect(activeCountry, OffCatalogCountry.de);
    });
  });

  group('AppDataSources OFF country mapping', () {
    test('includes DE, US, and UK channels with expected tags', () {
      final de = AppDataSources.offCatalogForCountry(OffCatalogCountry.de);
      final us = AppDataSources.offCatalogForCountry(OffCatalogCountry.us);
      final uk = AppDataSources.offCatalogForCountry(OffCatalogCountry.uk);

      expect(de.releaseTag, 'off-foods-de-stable');
      expect(us.releaseTag, 'off-foods-us-stable');
      expect(uk.releaseTag, 'off-foods-uk-stable');

      expect(de.manifestPath, 'off_catalog_manifest_de.json');
      expect(us.manifestPath, 'off_catalog_manifest_us.json');
      expect(uk.manifestPath, 'off_catalog_manifest_uk.json');

      expect(de.bundledAssetDbPath, 'assets/db/hypertrack_prep_de.db');
      expect(us.bundledAssetDbPath, 'assets/db/hypertrack_prep_us.db');
      expect(uk.bundledAssetDbPath, 'assets/db/hypertrack_prep_uk.db');
    });
  });
}
