/// Central configuration for bundled and remote data sources.
///
/// Keep URLs, asset paths, and naming conventions here so feature logic
/// doesn't hardcode environment-specific locations.
class AppDataSources {
  const AppDataSources._();

  // Bundled assets
  static const String trainingAssetDbPath = 'assets/db/hypertrack_training.db';
  static const String baseFoodsAssetDbPath =
      'assets/db/hypertrack_base_foods.db';
  static const String offFoodsAssetDbPath = 'assets/db/hypertrack_prep_de.db';
  static const String foodCategoriesAssetDbPath =
      'assets/db/hypertrack_base_foods.db';

  // Remote training-catalog source (wger-based build output channel).
  static const exerciseCatalog = ExerciseCatalogRemoteSourceConfig(
    enabled: true,
    sourceId: 'wger_catalog',
    channel: 'stable',
    baseUrl:
        'https://github.com/rfivesix/hypertrack/releases/download/wger-catalog-stable/',
    manifestPath: 'wger_catalog_manifest.json',
    defaultDbPath: 'hypertrack_training.db',
    defaultBuildReportPath: 'wger_build_report.json',
    localCacheDirectoryName: 'catalog_refresh',
    localCacheDbFileName: 'hypertrack_training_remote.db',
    localManifestFileName: 'wger_catalog_manifest_cached.json',
    manifestTimeoutSeconds: 6,
    downloadTimeoutSeconds: 30,
    minCheckIntervalHours: 12,
    minimumExerciseRows: 50,
  );
}

class ExerciseCatalogRemoteSourceConfig {
  final bool enabled;
  final String sourceId;
  final String channel;
  final String baseUrl;
  final String manifestPath;
  final String defaultDbPath;
  final String defaultBuildReportPath;
  final String localCacheDirectoryName;
  final String localCacheDbFileName;
  final String localManifestFileName;
  final int manifestTimeoutSeconds;
  final int downloadTimeoutSeconds;
  final int minCheckIntervalHours;
  final int minimumExerciseRows;

  const ExerciseCatalogRemoteSourceConfig({
    required this.enabled,
    required this.sourceId,
    required this.channel,
    required this.baseUrl,
    required this.manifestPath,
    required this.defaultDbPath,
    required this.defaultBuildReportPath,
    required this.localCacheDirectoryName,
    required this.localCacheDbFileName,
    required this.localManifestFileName,
    required this.manifestTimeoutSeconds,
    required this.downloadTimeoutSeconds,
    required this.minCheckIntervalHours,
    required this.minimumExerciseRows,
  });

  Duration get manifestTimeout => Duration(seconds: manifestTimeoutSeconds);
  Duration get downloadTimeout => Duration(seconds: downloadTimeoutSeconds);
  Duration get minCheckInterval => Duration(hours: minCheckIntervalHours);
}
