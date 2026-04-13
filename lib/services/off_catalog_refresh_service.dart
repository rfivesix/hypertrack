import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../config/app_data_sources.dart';
import 'off_catalog_country_service.dart';

class OffCatalogManifest {
  final String version;
  final Uri dbUri;
  final Uri? buildReportUri;
  final Uri? diffReportUri;
  final String sourceId;
  final String channel;
  final String countryCode;
  final DateTime? generatedAt;
  final int productCount;
  final int minimumProductCount;
  final String dbSha256;

  const OffCatalogManifest({
    required this.version,
    required this.dbUri,
    required this.buildReportUri,
    required this.diffReportUri,
    required this.sourceId,
    required this.channel,
    required this.countryCode,
    required this.generatedAt,
    required this.productCount,
    required this.minimumProductCount,
    required this.dbSha256,
  });
}

class OffCatalogUpdateCandidate {
  final OffCatalogCountry country;
  final String version;
  final String localDbPath;
  final Uri manifestUri;
  final Uri dbUri;
  final bool fromCache;

  const OffCatalogUpdateCandidate({
    required this.country,
    required this.version,
    required this.localDbPath,
    required this.manifestUri,
    required this.dbUri,
    required this.fromCache,
  });
}

class OffCatalogRefreshSnapshot {
  final OffCatalogCountry country;
  final String installedVersion;
  final String? cachedVersion;
  final String? lastKnownRemoteVersion;
  final DateTime? lastCheckedAt;
  final String? lastError;

  const OffCatalogRefreshSnapshot({
    required this.country,
    required this.installedVersion,
    required this.cachedVersion,
    required this.lastKnownRemoteVersion,
    required this.lastCheckedAt,
    required this.lastError,
  });
}

typedef NowProvider = DateTime Function();
typedef SupportDirectoryProvider = Future<Directory> Function();
typedef TempDirectoryProvider = Future<Directory> Function();
typedef PrefsProvider = Future<SharedPreferences> Function();
typedef OffConfigResolver = OffCatalogRemoteSourceConfig Function(
  OffCatalogCountry country,
);

/// Handles remote OFF catalog update discovery, download, and validation.
///
/// This service is country-aware and reads the active OFF country from
/// [OffCatalogCountryService]. It returns `null` on any remote failure to keep
/// startup behavior safe and non-destructive.
class OffCatalogRefreshService {
  OffCatalogRefreshService._({
    http.Client? httpClient,
    OffConfigResolver? configResolver,
    NowProvider? nowProvider,
    SupportDirectoryProvider? supportDirectoryProvider,
    TempDirectoryProvider? tempDirectoryProvider,
    PrefsProvider? prefsProvider,
  })  : _httpClient = httpClient ?? http.Client(),
        _configResolver = configResolver ?? AppDataSources.offCatalogForCountry,
        _nowProvider = nowProvider ?? DateTime.now,
        _supportDirectoryProvider =
            supportDirectoryProvider ?? getApplicationSupportDirectory,
        _tempDirectoryProvider = tempDirectoryProvider ?? getTemporaryDirectory,
        _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  static final OffCatalogRefreshService instance = OffCatalogRefreshService._();

  @visibleForTesting
  factory OffCatalogRefreshService.forTesting({
    http.Client? httpClient,
    OffConfigResolver? configResolver,
    NowProvider? nowProvider,
    SupportDirectoryProvider? supportDirectoryProvider,
    TempDirectoryProvider? tempDirectoryProvider,
    PrefsProvider? prefsProvider,
  }) {
    return OffCatalogRefreshService._(
      httpClient: httpClient,
      configResolver: configResolver,
      nowProvider: nowProvider,
      supportDirectoryProvider: supportDirectoryProvider,
      tempDirectoryProvider: tempDirectoryProvider,
      prefsProvider: prefsProvider,
    );
  }

  final http.Client _httpClient;
  final OffConfigResolver _configResolver;
  final NowProvider _nowProvider;
  final SupportDirectoryProvider _supportDirectoryProvider;
  final TempDirectoryProvider _tempDirectoryProvider;
  final PrefsProvider _prefsProvider;

  static const String _keyLastRemoteVersionPrefix =
      'off_catalog_last_remote_version_';
  static const String _keyLastCheckedAtMsPrefix =
      'off_catalog_last_checked_at_';
  static const String _keyCachedCatalogVersionPrefix =
      'off_catalog_cached_version_';
  static const String _keyLastErrorPrefix = 'off_catalog_last_error_';

  static const Set<String> _requiredTables = {'products', 'metadata'};
  static const Set<String> _requiredProductColumns = {
    'barcode',
    'name',
    'brand',
    'calories',
    'protein',
    'carbs',
    'fat',
    'sugar',
    'fiber',
    'salt',
  };

  Future<OffCatalogUpdateCandidate?> prepareUpdateCandidate({
    required String installedVersion,
    bool force = false,
  }) async {
    final prefs = await _prefsProvider();
    final activeCountry = OffCatalogCountryService.readActiveCountryFromPrefs(
      prefs,
    );
    final config = _configResolver(activeCountry);

    if (!config.enabled) {
      return null;
    }

    final countryCode = activeCountry.code;
    final cachePath = await _cachedDbPath(config);
    final manifestUri = _resolveUrlOrPath(config.baseUrl, config.manifestPath);

    final cachedVersion = prefs.getString(
      _countryScopedKey(_keyCachedCatalogVersionPrefix, countryCode),
    );
    if (cachedVersion != null &&
        isRemoteVersionNewer(
          remoteVersion: cachedVersion,
          installedVersion: installedVersion,
        )) {
      final cachedValidation = await _validateCatalogDb(
        dbPath: cachePath,
        expectedVersion: cachedVersion,
        expectedCountryCode: config.countryCode,
        minimumRows: config.minimumProductRows,
      );
      if (cachedValidation.isValid) {
        return OffCatalogUpdateCandidate(
          country: activeCountry,
          version: cachedVersion,
          localDbPath: cachePath,
          manifestUri: manifestUri,
          dbUri: Uri.file(cachePath),
          fromCache: true,
        );
      }
    }

    final now = _nowProvider();
    final lastCheckedMs = prefs.getInt(
      _countryScopedKey(_keyLastCheckedAtMsPrefix, countryCode),
    );
    if (!force &&
        !shouldCheckRemoteNow(
          now: now,
          lastCheckedEpochMs: lastCheckedMs,
          minCheckInterval: config.minCheckInterval,
        )) {
      return null;
    }

    await prefs.setInt(
      _countryScopedKey(_keyLastCheckedAtMsPrefix, countryCode),
      now.millisecondsSinceEpoch,
    );

    String? tempDbPath;

    try {
      final manifest = await _fetchManifest(
        manifestUri,
        config,
      );
      if (manifest == null) {
        await prefs.setString(
          _countryScopedKey(_keyLastErrorPrefix, countryCode),
          'Manifest fetch failed or invalid payload.',
        );
        return null;
      }

      await prefs.setString(
        _countryScopedKey(_keyLastRemoteVersionPrefix, countryCode),
        manifest.version,
      );

      final shouldDownload = force ||
          isRemoteVersionNewer(
            remoteVersion: manifest.version,
            installedVersion: installedVersion,
          );
      if (!shouldDownload) {
        await prefs.remove(_countryScopedKey(_keyLastErrorPrefix, countryCode));
        return null;
      }

      final tempDir = await _tempDirectoryProvider();
      tempDbPath = p.join(
        tempDir.path,
        'hypertrack_off_${countryCode}_remote_${now.millisecondsSinceEpoch}.db',
      );

      final downloaded = await _downloadFile(
        manifest.dbUri,
        tempDbPath,
        timeout: config.downloadTimeout,
      );
      if (!downloaded) {
        await prefs.setString(
          _countryScopedKey(_keyLastErrorPrefix, countryCode),
          'Download failed for ${manifest.dbUri}',
        );
        return null;
      }

      final actualDbSha256 = await _computeFileSha256(tempDbPath);
      if (!_sha256Equals(actualDbSha256, manifest.dbSha256)) {
        await prefs.setString(
          _countryScopedKey(_keyLastErrorPrefix, countryCode),
          'Downloaded OFF DB checksum mismatch. expected=${manifest.dbSha256} actual=$actualDbSha256',
        );
        await _deleteIfExists(tempDbPath);
        return null;
      }

      final validated = await _validateCatalogDb(
        dbPath: tempDbPath,
        expectedVersion: manifest.version,
        expectedCountryCode: config.countryCode,
        minimumRows: manifest.minimumProductCount,
      );
      if (!validated.isValid) {
        await prefs.setString(
          _countryScopedKey(_keyLastErrorPrefix, countryCode),
          validated.error ?? 'Downloaded OFF DB validation failed.',
        );
        await _deleteIfExists(tempDbPath);
        return null;
      }

      await File(cachePath).parent.create(recursive: true);
      await _deleteIfExists(cachePath);
      await File(tempDbPath).copy(cachePath);
      await _deleteIfExists(tempDbPath);

      await prefs.setString(
        _countryScopedKey(_keyCachedCatalogVersionPrefix, countryCode),
        manifest.version,
      );
      await prefs.remove(_countryScopedKey(_keyLastErrorPrefix, countryCode));

      await _cacheManifestJson(
        manifestUri: manifestUri,
        config: config,
        manifest: manifest,
      );

      return OffCatalogUpdateCandidate(
        country: activeCountry,
        version: manifest.version,
        localDbPath: cachePath,
        manifestUri: manifestUri,
        dbUri: manifest.dbUri,
        fromCache: false,
      );
    } catch (e) {
      await prefs.setString(
        _countryScopedKey(_keyLastErrorPrefix, countryCode),
        e.toString(),
      );
      debugPrint('OFF catalog refresh skipped (safe fallback): $e');
      return null;
    } finally {
      if (tempDbPath != null) {
        await _deleteIfExists(tempDbPath);
      }
    }
  }

  Future<OffCatalogRefreshSnapshot> readSnapshot({
    required String installedVersion,
  }) async {
    final prefs = await _prefsProvider();
    final activeCountry = OffCatalogCountryService.readActiveCountryFromPrefs(
      prefs,
    );
    final countryCode = activeCountry.code;
    final lastCheckedMs = prefs.getInt(
      _countryScopedKey(_keyLastCheckedAtMsPrefix, countryCode),
    );

    return OffCatalogRefreshSnapshot(
      country: activeCountry,
      installedVersion: installedVersion,
      cachedVersion: prefs.getString(
        _countryScopedKey(_keyCachedCatalogVersionPrefix, countryCode),
      ),
      lastKnownRemoteVersion: prefs.getString(
        _countryScopedKey(_keyLastRemoteVersionPrefix, countryCode),
      ),
      lastCheckedAt: lastCheckedMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastCheckedMs),
      lastError: prefs.getString(
        _countryScopedKey(_keyLastErrorPrefix, countryCode),
      ),
    );
  }

  Future<String> _cachedDbPath(OffCatalogRemoteSourceConfig config) async {
    final supportDir = await _supportDirectoryProvider();
    final cacheDir = Directory(
      p.join(supportDir.path, config.localCacheDirectoryName),
    );
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return p.join(cacheDir.path, config.localCacheDbFileName);
  }

  Future<void> _cacheManifestJson({
    required Uri manifestUri,
    required OffCatalogRemoteSourceConfig config,
    required OffCatalogManifest manifest,
  }) async {
    final supportDir = await _supportDirectoryProvider();
    final cacheDir = Directory(
      p.join(supportDir.path, config.localCacheDirectoryName),
    );
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final manifestFile = File(
      p.join(cacheDir.path, config.localManifestFileName),
    );

    final map = {
      'source_id': manifest.sourceId,
      'channel': manifest.channel,
      'country_code': manifest.countryCode,
      'version': manifest.version,
      'generated_at': manifest.generatedAt?.toIso8601String(),
      'db_url': manifest.dbUri.toString(),
      'db_sha256': manifest.dbSha256,
      'build_report_url': manifest.buildReportUri?.toString(),
      'diff_report_url': manifest.diffReportUri?.toString(),
      'manifest_url': manifestUri.toString(),
      'product_count': manifest.productCount,
      'min_product_count': manifest.minimumProductCount,
      'cached_at': _nowProvider().toIso8601String(),
    };

    await manifestFile.writeAsString(
      jsonEncode(map),
      flush: true,
    );
  }

  Future<OffCatalogManifest?> _fetchManifest(
    Uri manifestUri,
    OffCatalogRemoteSourceConfig config,
  ) async {
    final response = await _httpClient.get(manifestUri, headers: const {
      'Accept': 'application/json'
    }).timeout(config.manifestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return parseManifest(decoded, config);
  }

  static OffCatalogManifest? parseManifest(
    Map<String, dynamic> json,
    OffCatalogRemoteSourceConfig config,
  ) {
    final build = json['build'] is Map<String, dynamic>
        ? json['build'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final version = _firstNonBlankString([
      json['version'],
      json['db_version'],
      build['db_version'],
    ]);
    if (version == null) {
      return null;
    }

    final sourceId = _firstNonBlankString([
      json['source_id'],
      build['source_id'],
    ]);
    if (sourceId == null || sourceId != config.sourceId) {
      return null;
    }

    final countryCode = _firstNonBlankString([
      json['country_code'],
      build['country_code'],
    ]);
    if (countryCode == null ||
        countryCode.toLowerCase() != config.countryCode) {
      return null;
    }

    final channel = _firstNonBlankString([
      json['channel'],
      build['channel'],
    ]);
    if (channel == null || channel != config.channel) {
      return null;
    }

    final dbSha256 = _firstNonBlankString([
      json['db_sha256'],
    ]);
    if (dbSha256 == null || !_isValidSha256(dbSha256)) {
      return null;
    }

    final productCount = _parseInt(json['product_count']);
    final minimumProductCount = _parseInt(json['min_product_count']);
    if (productCount == null || minimumProductCount == null) {
      return null;
    }
    if (productCount <= 0 || minimumProductCount <= 0) {
      return null;
    }
    if (productCount < minimumProductCount) {
      return null;
    }

    final hasDbLocator = _firstNonBlankString([
          json['db_url'],
          json['database_url'],
          json['db_path'],
          json['database_path'],
          json['db_file'],
        ]) !=
        null;
    if (!hasDbLocator) {
      return null;
    }

    final effectiveBaseUrl = _firstNonBlankString([
          json['asset_base_url'],
          json['download_base_url'],
          json['base_url'],
        ]) ??
        config.baseUrl;

    final dbUri = _resolveFromManifest(
      baseUrl: effectiveBaseUrl,
      urlValue: _firstNonBlankString([
        json['db_url'],
        json['database_url'],
      ]),
      pathValue: _firstNonBlankString([
        json['db_path'],
        json['database_path'],
        json['db_file'],
      ]),
      fallbackPath: config.defaultDbPath,
    );
    if (dbUri == null || !_isSecureRemoteUri(dbUri)) {
      return null;
    }

    final buildReportUri = _resolveFromManifest(
      baseUrl: effectiveBaseUrl,
      urlValue: _firstNonBlankString([
        json['build_report_url'],
        json['report_url'],
      ]),
      pathValue: _firstNonBlankString([
        json['build_report_file'],
        json['build_report_path'],
      ]),
      fallbackPath: config.defaultBuildReportPath,
    );
    if (buildReportUri != null && !_isSecureRemoteUri(buildReportUri)) {
      return null;
    }

    final diffReportUri = _resolveFromManifest(
      baseUrl: effectiveBaseUrl,
      urlValue: _firstNonBlankString([
        json['diff_report_url'],
      ]),
      pathValue: _firstNonBlankString([
        json['diff_report_file'],
      ]),
      fallbackPath: '',
    );
    if (diffReportUri != null && !_isSecureRemoteUri(diffReportUri)) {
      return null;
    }

    final generatedAtRaw = _firstNonBlankString([
      json['generated_at'],
      build['generated_at'],
    ]);
    final generatedAt =
        generatedAtRaw != null ? DateTime.tryParse(generatedAtRaw) : null;

    return OffCatalogManifest(
      version: version,
      dbUri: dbUri,
      buildReportUri: buildReportUri,
      diffReportUri: diffReportUri,
      sourceId: sourceId,
      channel: channel,
      countryCode: countryCode,
      generatedAt: generatedAt,
      productCount: productCount,
      minimumProductCount: minimumProductCount,
      dbSha256: dbSha256.toLowerCase(),
    );
  }

  static bool isRemoteVersionNewer({
    required String remoteVersion,
    required String installedVersion,
  }) {
    final normalizedRemote = remoteVersion.trim();
    final normalizedInstalled = installedVersion.trim();
    if (normalizedRemote.isEmpty) return false;
    if (normalizedInstalled.isEmpty) return true;
    return normalizedRemote.compareTo(normalizedInstalled) > 0;
  }

  static bool shouldCheckRemoteNow({
    required DateTime now,
    required int? lastCheckedEpochMs,
    required Duration minCheckInterval,
  }) {
    if (lastCheckedEpochMs == null) return true;
    final lastChecked = DateTime.fromMillisecondsSinceEpoch(lastCheckedEpochMs);
    return now.difference(lastChecked) >= minCheckInterval;
  }

  Future<bool> _downloadFile(
    Uri uri,
    String destinationPath, {
    required Duration timeout,
  }) async {
    final response = await _httpClient.get(uri).timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    final file = File(destinationPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return true;
  }

  Future<_OffCatalogDbValidationResult> _validateCatalogDb({
    required String dbPath,
    required String expectedVersion,
    required String expectedCountryCode,
    required int minimumRows,
  }) async {
    if (!await File(dbPath).exists()) {
      return const _OffCatalogDbValidationResult(
        isValid: false,
        error: 'OFF catalog DB file is missing.',
      );
    }

    sqflite.Database? db;
    try {
      db = await sqflite.openDatabase(dbPath, readOnly: true);
      final tableRows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      final tables = tableRows
          .map((row) => row['name']?.toString())
          .whereType<String>()
          .toSet();
      if (!_requiredTables.every(tables.contains)) {
        return const _OffCatalogDbValidationResult(
          isValid: false,
          error: 'OFF catalog DB missing required tables.',
        );
      }

      final pragmaRows = await db.rawQuery('PRAGMA table_info(products)');
      final columns = pragmaRows
          .map((row) => row['name']?.toString())
          .whereType<String>()
          .toSet();
      if (!_requiredProductColumns.every(columns.contains)) {
        return const _OffCatalogDbValidationResult(
          isValid: false,
          error: 'OFF catalog DB missing required product columns.',
        );
      }

      final versionRows = await db.query(
        'metadata',
        where: 'key = ?',
        whereArgs: ['version'],
      );
      final version = versionRows.isNotEmpty
          ? (versionRows.first['value']?.toString().trim() ?? '')
          : '';
      if (version.isEmpty) {
        return const _OffCatalogDbValidationResult(
          isValid: false,
          error: 'OFF catalog DB metadata.version is missing.',
        );
      }
      if (expectedVersion.isNotEmpty && version != expectedVersion) {
        return _OffCatalogDbValidationResult(
          isValid: false,
          error:
              'OFF catalog DB version mismatch. expected=$expectedVersion actual=$version',
        );
      }

      final countryRows = await db.query(
        'metadata',
        where: 'key = ?',
        whereArgs: ['country_code'],
      );
      if (countryRows.isNotEmpty) {
        final dbCountry =
            (countryRows.first['value']?.toString().trim().toLowerCase() ?? '');
        if (dbCountry.isNotEmpty && dbCountry != expectedCountryCode) {
          return _OffCatalogDbValidationResult(
            isValid: false,
            error:
                'OFF catalog DB country mismatch. expected=$expectedCountryCode actual=$dbCountry',
          );
        }
      }

      final countRows = await db.rawQuery('SELECT COUNT(*) as c FROM products');
      final rowCount = sqflite.Sqflite.firstIntValue(countRows) ?? 0;
      if (rowCount < minimumRows) {
        return _OffCatalogDbValidationResult(
          isValid: false,
          error:
              'OFF catalog DB row count too low. count=$rowCount minimum=$minimumRows',
        );
      }

      return _OffCatalogDbValidationResult(
        isValid: true,
        version: version,
        rowCount: rowCount,
      );
    } catch (e) {
      return _OffCatalogDbValidationResult(
        isValid: false,
        error: 'OFF catalog DB validation failed: $e',
      );
    } finally {
      await db?.close();
    }
  }

  Future<void> _deleteIfExists(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> _computeFileSha256(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return sha256.convert(bytes).toString();
  }

  static bool _sha256Equals(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  static Uri _resolveUrlOrPath(String baseUrl, String value) {
    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }

    final base = Uri.parse(baseUrl);
    return base.resolve(value);
  }

  static Uri? _resolveFromManifest({
    required String baseUrl,
    required String? urlValue,
    required String? pathValue,
    required String fallbackPath,
  }) {
    final preferred = urlValue?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      final uri = Uri.tryParse(preferred);
      if (uri != null && uri.hasScheme) return uri;
      return _resolveUrlOrPath(baseUrl, preferred);
    }

    final path = (pathValue?.trim().isNotEmpty ?? false)
        ? pathValue!.trim()
        : fallbackPath;
    if (path.isEmpty) return null;

    return _resolveUrlOrPath(baseUrl, path);
  }

  static String? _firstNonBlankString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _isSecureRemoteUri(Uri uri) {
    return uri.hasScheme && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  static bool _isValidSha256(String value) {
    return RegExp(r'^[A-Fa-f0-9]{64}$').hasMatch(value.trim());
  }

  static String _countryScopedKey(String prefix, String countryCode) {
    return '$prefix$countryCode';
  }
}

class _OffCatalogDbValidationResult {
  final bool isValid;
  final String? version;
  final int? rowCount;
  final String? error;

  const _OffCatalogDbValidationResult({
    required this.isValid,
    this.version,
    this.rowCount,
    this.error,
  });
}
