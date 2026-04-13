/// Central configuration for bundled and remote data sources.
///
/// Keep URLs, asset paths, and naming conventions here so feature logic
/// does not hardcode environment-specific locations.
class AppDataSources {
  const AppDataSources._();

  // Bundled assets
  static const String trainingAssetDbPath = 'assets/db/hypertrack_training.db';
  static const String baseFoodsAssetDbPath =
      'assets/db/hypertrack_base_foods.db';
  static const String offFoodsAssetDbPath =
      'assets/db/hypertrack_prep_de.db'; // Legacy default (DE)
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

  static const OffCatalogCountry defaultOffCatalogCountry =
      OffCatalogCountry.de;

  static const List<OffCatalogCountry> supportedOffCatalogCountries = [
    OffCatalogCountry.de,
    OffCatalogCountry.us,
    OffCatalogCountry.uk,
  ];

  /// OFF release-channel/manifest expectations per supported country.
  static const Map<OffCatalogCountry, OffCatalogRemoteSourceConfig>
      offCatalogs = {
    OffCatalogCountry.de: OffCatalogRemoteSourceConfig(
      enabled: true,
      sourceId: 'off_food_catalog',
      countryCode: 'de',
      channel: 'stable',
      releaseTag: 'off-foods-de-stable',
      baseUrl:
          'https://github.com/rfivesix/hypertrack/releases/download/off-foods-de-stable/',
      manifestPath: 'off_catalog_manifest_de.json',
      defaultDbPath: 'hypertrack_off_de.db',
      defaultBuildReportPath: 'off_build_report_de.json',
      bundledAssetDbPath: 'assets/db/hypertrack_prep_de.db',
      minimumProductRows: 5000,
      manifestTimeoutSeconds: 6,
      downloadTimeoutSeconds: 45,
      minCheckIntervalHours: 12,
      localCacheDirectoryName: 'off_catalog_refresh',
      localCacheDbFileName: 'hypertrack_off_de_remote.db',
      localManifestFileName: 'off_catalog_manifest_de_cached.json',
    ),
    OffCatalogCountry.us: OffCatalogRemoteSourceConfig(
      enabled: true,
      sourceId: 'off_food_catalog',
      countryCode: 'us',
      channel: 'stable',
      releaseTag: 'off-foods-us-stable',
      baseUrl:
          'https://github.com/rfivesix/hypertrack/releases/download/off-foods-us-stable/',
      manifestPath: 'off_catalog_manifest_us.json',
      defaultDbPath: 'hypertrack_off_us.db',
      defaultBuildReportPath: 'off_build_report_us.json',
      bundledAssetDbPath: 'assets/db/hypertrack_prep_us.db',
      minimumProductRows: 5000,
      manifestTimeoutSeconds: 6,
      downloadTimeoutSeconds: 45,
      minCheckIntervalHours: 12,
      localCacheDirectoryName: 'off_catalog_refresh',
      localCacheDbFileName: 'hypertrack_off_us_remote.db',
      localManifestFileName: 'off_catalog_manifest_us_cached.json',
    ),
    OffCatalogCountry.uk: OffCatalogRemoteSourceConfig(
      enabled: true,
      sourceId: 'off_food_catalog',
      countryCode: 'uk',
      channel: 'stable',
      releaseTag: 'off-foods-uk-stable',
      baseUrl:
          'https://github.com/rfivesix/hypertrack/releases/download/off-foods-uk-stable/',
      manifestPath: 'off_catalog_manifest_uk.json',
      defaultDbPath: 'hypertrack_off_uk.db',
      defaultBuildReportPath: 'off_build_report_uk.json',
      bundledAssetDbPath: 'assets/db/hypertrack_prep_uk.db',
      minimumProductRows: 5000,
      manifestTimeoutSeconds: 6,
      downloadTimeoutSeconds: 45,
      minCheckIntervalHours: 12,
      localCacheDirectoryName: 'off_catalog_refresh',
      localCacheDbFileName: 'hypertrack_off_uk_remote.db',
      localManifestFileName: 'off_catalog_manifest_uk_cached.json',
    ),
  };

  static OffCatalogRemoteSourceConfig offCatalogForCountry(
    OffCatalogCountry country,
  ) {
    return offCatalogs[country]!;
  }

  static String offFoodsAssetDbPathForCountry(OffCatalogCountry country) {
    return offCatalogForCountry(country).bundledAssetDbPath;
  }
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

enum OffCatalogCountry {
  de,
  us,
  uk,
}

extension OffCatalogCountryX on OffCatalogCountry {
  String get code => switch (this) {
        OffCatalogCountry.de => 'de',
        OffCatalogCountry.us => 'us',
        OffCatalogCountry.uk => 'uk',
      };

  String get upperCode => code.toUpperCase();
}

class OffCatalogCountryCodec {
  const OffCatalogCountryCodec._();

  static OffCatalogCountry parseOrDefault(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    for (final country in AppDataSources.supportedOffCatalogCountries) {
      if (country.code == normalized) {
        return country;
      }
    }
    return AppDataSources.defaultOffCatalogCountry;
  }
}

class OffCatalogRemoteSourceConfig {
  final bool enabled;
  final String sourceId;
  final String countryCode;
  final String channel;
  final String releaseTag;
  final String baseUrl;
  final String manifestPath;
  final String defaultDbPath;
  final String defaultBuildReportPath;
  final String bundledAssetDbPath;
  final int minimumProductRows;
  final int manifestTimeoutSeconds;
  final int downloadTimeoutSeconds;
  final int minCheckIntervalHours;
  final String localCacheDirectoryName;
  final String localCacheDbFileName;
  final String localManifestFileName;

  const OffCatalogRemoteSourceConfig({
    required this.enabled,
    required this.sourceId,
    required this.countryCode,
    required this.channel,
    required this.releaseTag,
    required this.baseUrl,
    required this.manifestPath,
    required this.defaultDbPath,
    required this.defaultBuildReportPath,
    required this.bundledAssetDbPath,
    required this.minimumProductRows,
    required this.manifestTimeoutSeconds,
    required this.downloadTimeoutSeconds,
    required this.minCheckIntervalHours,
    required this.localCacheDirectoryName,
    required this.localCacheDbFileName,
    required this.localManifestFileName,
  });

  Duration get manifestTimeout => Duration(seconds: manifestTimeoutSeconds);
  Duration get downloadTimeout => Duration(seconds: downloadTimeoutSeconds);
  Duration get minCheckInterval => Duration(hours: minCheckIntervalHours);
}
