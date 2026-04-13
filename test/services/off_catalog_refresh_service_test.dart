import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hypertrack/config/app_data_sources.dart';
import 'package:hypertrack/services/off_catalog_country_service.dart';
import 'package:hypertrack/services/off_catalog_refresh_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const config = OffCatalogRemoteSourceConfig(
    enabled: true,
    sourceId: 'off_food_catalog',
    countryCode: 'us',
    channel: 'stable',
    releaseTag: 'off-foods-us-stable',
    baseUrl: 'https://example.com/root/',
    manifestPath: 'off_catalog_manifest_us.json',
    defaultDbPath: 'hypertrack_off_us.db',
    defaultBuildReportPath: 'off_build_report_us.json',
    bundledAssetDbPath: 'assets/db/hypertrack_prep_us.db',
    minimumProductRows: 50,
    manifestTimeoutSeconds: 5,
    downloadTimeoutSeconds: 15,
    minCheckIntervalHours: 6,
    localCacheDirectoryName: 'off_catalog_refresh',
    localCacheDbFileName: 'hypertrack_off_us_remote.db',
    localManifestFileName: 'off_catalog_manifest_us_cached.json',
  );

  group('OffCatalogRefreshService.parseManifest', () {
    test('parses valid manifest with absolute db url', () {
      final manifest = OffCatalogRefreshService.parseManifest({
        'source_id': 'off_food_catalog',
        'country_code': 'us',
        'channel': 'stable',
        'version': '202604130001',
        'db_url': 'https://cdn.example.net/off/hypertrack_off_us.db',
        'db_sha256':
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'product_count': 120000,
        'min_product_count': 5000,
      }, config);

      expect(manifest, isNotNull);
      expect(manifest!.countryCode, 'us');
      expect(manifest.productCount, 120000);
      expect(manifest.minimumProductCount, 5000);
      expect(
        manifest.dbUri.toString(),
        'https://cdn.example.net/off/hypertrack_off_us.db',
      );
    });

    test('rejects wrong source_id', () {
      final manifest = OffCatalogRefreshService.parseManifest({
        'source_id': 'wrong_source',
        'country_code': 'us',
        'channel': 'stable',
        'version': '202604130001',
        'db_url': 'https://cdn.example.net/off/hypertrack_off_us.db',
        'db_sha256':
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        'product_count': 120000,
        'min_product_count': 5000,
      }, config);

      expect(manifest, isNull);
    });

    test('rejects wrong country_code', () {
      final manifest = OffCatalogRefreshService.parseManifest({
        'source_id': 'off_food_catalog',
        'country_code': 'de',
        'channel': 'stable',
        'version': '202604130001',
        'db_url': 'https://cdn.example.net/off/hypertrack_off_us.db',
        'db_sha256':
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'product_count': 120000,
        'min_product_count': 5000,
      }, config);

      expect(manifest, isNull);
    });

    test('rejects product_count smaller than min_product_count', () {
      final manifest = OffCatalogRefreshService.parseManifest({
        'source_id': 'off_food_catalog',
        'country_code': 'us',
        'channel': 'stable',
        'version': '202604130001',
        'db_url': 'https://cdn.example.net/off/hypertrack_off_us.db',
        'db_sha256':
            'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
        'product_count': 4999,
        'min_product_count': 5000,
      }, config);

      expect(manifest, isNull);
    });
  });

  group('OffCatalogRefreshService remote adoption safety', () {
    late Directory tempRoot;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        OffCatalogCountryService.preferenceKey: 'us',
      });
      tempRoot = await Directory.systemTemp.createTemp('off_refresh_test_');
    });

    tearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('checksum mismatch prevents adoption and returns null candidate',
        () async {
      final manifestPayload = {
        'source_id': 'off_food_catalog',
        'country_code': 'us',
        'channel': 'stable',
        'version': '202604130001',
        'db_url': 'https://example.com/root/hypertrack_off_us.db',
        'db_sha256':
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'product_count': 120000,
        'min_product_count': 5000,
      };

      final client = MockClient((request) async {
        if (request.url.toString() ==
            'https://example.com/root/off_catalog_manifest_us.json') {
          return http.Response(
            jsonEncode(manifestPayload),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.toString() ==
            'https://example.com/root/hypertrack_off_us.db') {
          return http.Response.bytes(
            utf8.encode('this-is-not-the-expected-binary'),
            200,
          );
        }
        return http.Response('not found', 404);
      });

      final service = OffCatalogRefreshService.forTesting(
        httpClient: client,
        configResolver: (_) => config,
        nowProvider: () => DateTime(2026, 4, 13, 12, 0, 0),
        supportDirectoryProvider: () async => tempRoot,
        tempDirectoryProvider: () async => tempRoot,
        prefsProvider: SharedPreferences.getInstance,
      );

      final candidate = await service.prepareUpdateCandidate(
        installedVersion: '0',
        force: true,
      );

      expect(candidate, isNull);

      final snapshot = await service.readSnapshot(installedVersion: '0');
      expect(snapshot.country, OffCatalogCountry.us);
      expect(snapshot.lastError, contains('checksum mismatch'));
    });
  });
}
