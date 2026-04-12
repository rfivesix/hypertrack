import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/config/app_data_sources.dart';
import 'package:hypertrack/services/exercise_catalog_refresh_service.dart';

void main() {
  const config = ExerciseCatalogRemoteSourceConfig(
    enabled: true,
    sourceId: 'wger_catalog',
    channel: 'stable',
    baseUrl: 'https://example.com/root/',
    manifestPath: 'manifest.json',
    defaultDbPath: 'db/hypertrack_training.db',
    defaultBuildReportPath: 'reports/wger_build_report.json',
    localCacheDirectoryName: 'catalog_refresh',
    localCacheDbFileName: 'hypertrack_training_remote.db',
    localManifestFileName: 'wger_manifest_cached.json',
    manifestTimeoutSeconds: 5,
    downloadTimeoutSeconds: 15,
    minCheckIntervalHours: 6,
    minimumExerciseRows: 50,
  );

  group('ExerciseCatalogRefreshService.parseManifest', () {
    test('parses relative db/report paths against base url', () {
      final manifest = ExerciseCatalogRefreshService.parseManifest({
        'version': '202601010001',
        'db_path': 'artifacts/hypertrack_training.db',
        'build_report_path': 'artifacts/wger_build_report.json',
        'min_exercise_count': 123,
      }, config);

      expect(manifest, isNotNull);
      expect(
        manifest!.dbUri.toString(),
        'https://example.com/root/artifacts/hypertrack_training.db',
      );
      expect(
        manifest.buildReportUri!.toString(),
        'https://example.com/root/artifacts/wger_build_report.json',
      );
      expect(manifest.minimumExerciseRows, 123);
      expect(manifest.version, '202601010001');
    });

    test('uses absolute urls from manifest directly', () {
      final manifest = ExerciseCatalogRefreshService.parseManifest({
        'version': '202602020002',
        'db_url': 'https://cdn.example.net/catalog/training.db',
      }, config);

      expect(manifest, isNotNull);
      expect(
        manifest!.dbUri.toString(),
        'https://cdn.example.net/catalog/training.db',
      );
      expect(manifest.sourceId, 'wger_catalog');
      expect(manifest.channel, 'stable');
    });

    test('supports release-style manifest with asset_base_url and *_file keys',
        () {
      final manifest = ExerciseCatalogRefreshService.parseManifest({
        'version': '202603030003',
        'asset_base_url': 'https://github.com/org/repo/releases/download/tag/',
        'db_file': 'hypertrack_training.db',
        'build_report_file': 'wger_build_report.json',
        'expected_exercise_count': 777,
      }, config);

      expect(manifest, isNotNull);
      expect(
        manifest!.dbUri.toString(),
        'https://github.com/org/repo/releases/download/tag/hypertrack_training.db',
      );
      expect(
        manifest.buildReportUri!.toString(),
        'https://github.com/org/repo/releases/download/tag/wger_build_report.json',
      );
      expect(manifest.minimumExerciseRows, 777);
    });
  });

  group('ExerciseCatalogRefreshService version/check logic', () {
    test('detects newer remote version', () {
      expect(
        ExerciseCatalogRefreshService.isRemoteVersionNewer(
          remoteVersion: '202701010001',
          installedVersion: '202601010001',
        ),
        isTrue,
      );
      expect(
        ExerciseCatalogRefreshService.isRemoteVersionNewer(
          remoteVersion: '202601010001',
          installedVersion: '202601010001',
        ),
        isFalse,
      );
    });

    test('respects minimum remote-check interval', () {
      final now = DateTime(2026, 4, 12, 12, 0, 0);
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final sevenHoursAgo = now.subtract(const Duration(hours: 7));

      expect(
        ExerciseCatalogRefreshService.shouldCheckRemoteNow(
          now: now,
          lastCheckedEpochMs: null,
          minCheckInterval: const Duration(hours: 6),
        ),
        isTrue,
      );

      expect(
        ExerciseCatalogRefreshService.shouldCheckRemoteNow(
          now: now,
          lastCheckedEpochMs: oneHourAgo.millisecondsSinceEpoch,
          minCheckInterval: const Duration(hours: 6),
        ),
        isFalse,
      );

      expect(
        ExerciseCatalogRefreshService.shouldCheckRemoteNow(
          now: now,
          lastCheckedEpochMs: sevenHoursAgo.millisecondsSinceEpoch,
          minCheckInterval: const Duration(hours: 6),
        ),
        isTrue,
      );
    });
  });
}
