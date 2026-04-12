import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../config/app_data_sources.dart';

class ExerciseCatalogManifest {
  final String version;
  final Uri dbUri;
  final Uri? buildReportUri;
  final String sourceId;
  final String channel;
  final DateTime? generatedAt;
  final int? minimumExerciseRows;

  const ExerciseCatalogManifest({
    required this.version,
    required this.dbUri,
    required this.buildReportUri,
    required this.sourceId,
    required this.channel,
    required this.generatedAt,
    required this.minimumExerciseRows,
  });
}

class ExerciseCatalogUpdateCandidate {
  final String version;
  final String localDbPath;
  final Uri manifestUri;
  final Uri dbUri;
  final bool fromCache;

  const ExerciseCatalogUpdateCandidate({
    required this.version,
    required this.localDbPath,
    required this.manifestUri,
    required this.dbUri,
    required this.fromCache,
  });
}

class ExerciseCatalogRefreshSnapshot {
  final String installedVersion;
  final String? cachedVersion;
  final String? lastKnownRemoteVersion;
  final DateTime? lastCheckedAt;
  final String? lastError;

  const ExerciseCatalogRefreshSnapshot({
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

/// Handles remote exercise-catalog update discovery, download, and validation.
///
/// The service keeps network/source details in central config and degrades
/// gracefully by returning `null` on any remote failure.
class ExerciseCatalogRefreshService {
  ExerciseCatalogRefreshService._({
    http.Client? httpClient,
    ExerciseCatalogRemoteSourceConfig? config,
    NowProvider? nowProvider,
    SupportDirectoryProvider? supportDirectoryProvider,
    TempDirectoryProvider? tempDirectoryProvider,
    PrefsProvider? prefsProvider,
  })  : _httpClient = httpClient ?? http.Client(),
        _config = config ?? AppDataSources.exerciseCatalog,
        _nowProvider = nowProvider ?? DateTime.now,
        _supportDirectoryProvider =
            supportDirectoryProvider ?? getApplicationSupportDirectory,
        _tempDirectoryProvider = tempDirectoryProvider ?? getTemporaryDirectory,
        _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  static final ExerciseCatalogRefreshService instance =
      ExerciseCatalogRefreshService._();

  @visibleForTesting
  factory ExerciseCatalogRefreshService.forTesting({
    http.Client? httpClient,
    ExerciseCatalogRemoteSourceConfig? config,
    NowProvider? nowProvider,
    SupportDirectoryProvider? supportDirectoryProvider,
    TempDirectoryProvider? tempDirectoryProvider,
    PrefsProvider? prefsProvider,
  }) {
    return ExerciseCatalogRefreshService._(
      httpClient: httpClient,
      config: config,
      nowProvider: nowProvider,
      supportDirectoryProvider: supportDirectoryProvider,
      tempDirectoryProvider: tempDirectoryProvider,
      prefsProvider: prefsProvider,
    );
  }

  final http.Client _httpClient;
  final ExerciseCatalogRemoteSourceConfig _config;
  final NowProvider _nowProvider;
  final SupportDirectoryProvider _supportDirectoryProvider;
  final TempDirectoryProvider _tempDirectoryProvider;
  final PrefsProvider _prefsProvider;

  static const String _keyLastRemoteVersion =
      'exercise_catalog_last_remote_version';
  static const String _keyLastCheckedAtMs = 'exercise_catalog_last_checked_at';
  static const String _keyCachedCatalogVersion =
      'exercise_catalog_cached_version';
  static const String _keyLastError = 'exercise_catalog_last_error';

  static const Set<String> _requiredTables = {'exercises', 'metadata'};
  static const Set<String> _requiredExerciseColumns = {
    'id',
    'name_de',
    'name_en',
    'description_de',
    'description_en',
    'category_name',
    'muscles_primary',
    'muscles_secondary',
  };

  Future<ExerciseCatalogUpdateCandidate?> prepareUpdateCandidate({
    required String installedVersion,
    bool force = false,
  }) async {
    if (!_config.enabled) {
      return null;
    }

    final prefs = await _prefsProvider();
    final cachePath = await _cachedDbPath();
    final manifestUri = _resolveUrlOrPath(
      _config.baseUrl,
      _config.manifestPath,
    );

    // If a valid cached catalog exists and is newer than installed, use it.
    final cachedVersion = prefs.getString(_keyCachedCatalogVersion);
    if (cachedVersion != null &&
        isRemoteVersionNewer(
          remoteVersion: cachedVersion,
          installedVersion: installedVersion,
        )) {
      final cachedValidation = await _validateCatalogDb(
        dbPath: cachePath,
        expectedVersion: cachedVersion,
        minimumRows: _config.minimumExerciseRows,
      );
      if (cachedValidation.isValid) {
        return ExerciseCatalogUpdateCandidate(
          version: cachedVersion,
          localDbPath: cachePath,
          manifestUri: manifestUri,
          dbUri: Uri.file(cachePath),
          fromCache: true,
        );
      }
    }

    final now = _nowProvider();
    final lastCheckedMs = prefs.getInt(_keyLastCheckedAtMs);
    if (!force &&
        !shouldCheckRemoteNow(
          now: now,
          lastCheckedEpochMs: lastCheckedMs,
          minCheckInterval: _config.minCheckInterval,
        )) {
      return null;
    }
    await prefs.setInt(_keyLastCheckedAtMs, now.millisecondsSinceEpoch);

    try {
      final manifest = await _fetchManifest(manifestUri);
      if (manifest == null) {
        await prefs.setString(
          _keyLastError,
          'Manifest fetch failed or invalid payload.',
        );
        return null;
      }

      await prefs.setString(_keyLastRemoteVersion, manifest.version);

      final shouldDownload = force ||
          isRemoteVersionNewer(
            remoteVersion: manifest.version,
            installedVersion: installedVersion,
          );
      if (!shouldDownload) {
        await prefs.remove(_keyLastError);
        return null;
      }

      final tempDir = await _tempDirectoryProvider();
      final tempDbPath = p.join(
        tempDir.path,
        'hypertrack_training_remote_${now.millisecondsSinceEpoch}.db',
      );

      final downloaded = await _downloadFile(
        manifest.dbUri,
        tempDbPath,
        timeout: _config.downloadTimeout,
      );
      if (!downloaded) {
        await prefs.setString(
          _keyLastError,
          'Download failed for ${manifest.dbUri}',
        );
        return null;
      }

      final validated = await _validateCatalogDb(
        dbPath: tempDbPath,
        expectedVersion: manifest.version,
        minimumRows:
            manifest.minimumExerciseRows ?? _config.minimumExerciseRows,
      );
      if (!validated.isValid) {
        await prefs.setString(
          _keyLastError,
          validated.error ?? 'Downloaded DB validation failed.',
        );
        await _deleteIfExists(tempDbPath);
        return null;
      }

      await File(cachePath).parent.create(recursive: true);
      await _deleteIfExists(cachePath);
      await File(tempDbPath).copy(cachePath);
      await _deleteIfExists(tempDbPath);

      await prefs.setString(_keyCachedCatalogVersion, manifest.version);
      await prefs.remove(_keyLastError);

      await _cacheManifestJson(
        manifestUri: manifestUri,
        manifest: manifest,
      );

      return ExerciseCatalogUpdateCandidate(
        version: manifest.version,
        localDbPath: cachePath,
        manifestUri: manifestUri,
        dbUri: manifest.dbUri,
        fromCache: false,
      );
    } catch (e) {
      await prefs.setString(_keyLastError, e.toString());
      debugPrint('Exercise catalog refresh skipped (safe fallback): $e');
      return null;
    }
  }

  Future<ExerciseCatalogRefreshSnapshot> readSnapshot({
    required String installedVersion,
  }) async {
    final prefs = await _prefsProvider();
    final lastCheckedMs = prefs.getInt(_keyLastCheckedAtMs);
    return ExerciseCatalogRefreshSnapshot(
      installedVersion: installedVersion,
      cachedVersion: prefs.getString(_keyCachedCatalogVersion),
      lastKnownRemoteVersion: prefs.getString(_keyLastRemoteVersion),
      lastCheckedAt: lastCheckedMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastCheckedMs),
      lastError: prefs.getString(_keyLastError),
    );
  }

  Future<String> _cachedDbPath() async {
    final supportDir = await _supportDirectoryProvider();
    final cacheDir = Directory(
      p.join(supportDir.path, _config.localCacheDirectoryName),
    );
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return p.join(cacheDir.path, _config.localCacheDbFileName);
  }

  Future<void> _cacheManifestJson({
    required Uri manifestUri,
    required ExerciseCatalogManifest manifest,
  }) async {
    final supportDir = await _supportDirectoryProvider();
    final cacheDir = Directory(
      p.join(supportDir.path, _config.localCacheDirectoryName),
    );
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final manifestFile = File(
      p.join(cacheDir.path, _config.localManifestFileName),
    );
    final map = {
      'source_id': manifest.sourceId,
      'channel': manifest.channel,
      'version': manifest.version,
      'generated_at': manifest.generatedAt?.toIso8601String(),
      'db_url': manifest.dbUri.toString(),
      'build_report_url': manifest.buildReportUri?.toString(),
      'manifest_url': manifestUri.toString(),
      'minimum_exercise_rows': manifest.minimumExerciseRows,
      'cached_at': _nowProvider().toIso8601String(),
    };
    await manifestFile.writeAsString(
      jsonEncode(map),
      flush: true,
    );
  }

  Future<ExerciseCatalogManifest?> _fetchManifest(Uri manifestUri) async {
    final response = await _httpClient.get(manifestUri, headers: const {
      'Accept': 'application/json'
    }).timeout(_config.manifestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return parseManifest(decoded, _config);
  }

  static ExerciseCatalogManifest? parseManifest(
    Map<String, dynamic> json,
    ExerciseCatalogRemoteSourceConfig config,
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

    final sourceId =
        _firstNonBlankString([json['source_id'], build['source_id']]) ??
            config.sourceId;
    final channel = _firstNonBlankString([json['channel'], build['channel']]) ??
        config.channel;
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
    if (dbUri == null) {
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
        json['report_path'],
      ]),
      fallbackPath: config.defaultBuildReportPath,
    );

    final generatedAtRaw =
        _firstNonBlankString([json['generated_at'], build['generated_at']]);
    final generatedAt =
        generatedAtRaw != null ? DateTime.tryParse(generatedAtRaw) : null;

    final minimumRows = _parseInt(json['minimum_exercise_rows']) ??
        _parseInt(json['min_exercise_count']) ??
        _parseInt(json['expected_exercise_count']) ??
        _parseInt(json['min_rows']);

    return ExerciseCatalogManifest(
      version: version,
      dbUri: dbUri,
      buildReportUri: buildReportUri,
      sourceId: sourceId,
      channel: channel,
      generatedAt: generatedAt,
      minimumExerciseRows: minimumRows,
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

  Future<_CatalogDbValidationResult> _validateCatalogDb({
    required String dbPath,
    required String expectedVersion,
    required int minimumRows,
  }) async {
    if (!await File(dbPath).exists()) {
      return const _CatalogDbValidationResult(
        isValid: false,
        error: 'Catalog DB file is missing.',
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
        return const _CatalogDbValidationResult(
          isValid: false,
          error: 'Catalog DB missing required tables.',
        );
      }

      final pragmaRows = await db.rawQuery('PRAGMA table_info(exercises)');
      final columns = pragmaRows
          .map((row) => row['name']?.toString())
          .whereType<String>()
          .toSet();
      if (!_requiredExerciseColumns.every(columns.contains)) {
        return const _CatalogDbValidationResult(
          isValid: false,
          error: 'Catalog DB missing required exercise columns.',
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
        return const _CatalogDbValidationResult(
          isValid: false,
          error: 'Catalog DB metadata.version is missing.',
        );
      }
      if (expectedVersion.isNotEmpty && version != expectedVersion) {
        return _CatalogDbValidationResult(
          isValid: false,
          error:
              'Catalog DB version mismatch. expected=$expectedVersion actual=$version',
        );
      }

      final countRows =
          await db.rawQuery('SELECT COUNT(*) as c FROM exercises');
      final rowCount = sqflite.Sqflite.firstIntValue(countRows) ?? 0;
      if (rowCount < minimumRows) {
        return _CatalogDbValidationResult(
          isValid: false,
          error:
              'Catalog DB row count too low. count=$rowCount minimum=$minimumRows',
        );
      }

      return _CatalogDbValidationResult(
        isValid: true,
        version: version,
        rowCount: rowCount,
      );
    } catch (e) {
      return _CatalogDbValidationResult(
        isValid: false,
        error: 'Catalog DB validation failed: $e',
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
}

class _CatalogDbValidationResult {
  final bool isValid;
  final String? version;
  final int? rowCount;
  final String? error;

  const _CatalogDbValidationResult({
    required this.isValid,
    this.version,
    this.rowCount,
    this.error,
  });
}
