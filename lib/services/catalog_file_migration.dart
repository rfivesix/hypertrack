import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves a Train Libre catalog path while migrating a legacy Hypertrack file
/// when only the old filename exists on disk.
class CatalogFileMigration {
  const CatalogFileMigration._();

  static Future<String> resolveCanonicalPath({
    required String directoryPath,
    required String canonicalFileName,
    String? legacyFileName,
  }) async {
    final canonicalPath = p.join(directoryPath, canonicalFileName);
    if (legacyFileName == null || legacyFileName.trim().isEmpty) {
      return canonicalPath;
    }

    final canonicalFile = File(canonicalPath);
    if (await canonicalFile.exists()) return canonicalPath;

    final legacyPath = p.join(directoryPath, legacyFileName);
    final legacyFile = File(legacyPath);
    if (!await legacyFile.exists()) return canonicalPath;

    await canonicalFile.parent.create(recursive: true);
    await legacyFile.copy(canonicalPath);

    final legacySize = await legacyFile.length();
    final canonicalSize = await canonicalFile.length();
    if (legacySize > 0 && legacySize == canonicalSize) {
      await legacyFile.delete();
    }

    return canonicalPath;
  }
}
