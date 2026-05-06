import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:train_libre/services/catalog_file_migration.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('catalog_migration_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('returns canonical path when no legacy file exists', () async {
    final path = await CatalogFileMigration.resolveCanonicalPath(
      directoryPath: tempDir.path,
      canonicalFileName: 'train_libre_training.db',
      legacyFileName: 'hypertrack_training.db',
    );

    expect(path, p.join(tempDir.path, 'train_libre_training.db'));
    expect(File(path).existsSync(), isFalse);
  });

  test('copies verified legacy file to canonical name and removes old file',
      () async {
    final legacyFile = File(p.join(tempDir.path, 'hypertrack_training.db'));
    await legacyFile.writeAsBytes([1, 2, 3, 4, 5], flush: true);

    final path = await CatalogFileMigration.resolveCanonicalPath(
      directoryPath: tempDir.path,
      canonicalFileName: 'train_libre_training.db',
      legacyFileName: 'hypertrack_training.db',
    );

    final canonicalFile = File(path);
    expect(await canonicalFile.readAsBytes(), [1, 2, 3, 4, 5]);
    expect(await legacyFile.exists(), isFalse);
  });

  test('does not overwrite an existing canonical file', () async {
    final canonicalFile = File(p.join(tempDir.path, 'train_libre_training.db'));
    final legacyFile = File(p.join(tempDir.path, 'hypertrack_training.db'));
    await canonicalFile.writeAsBytes([9], flush: true);
    await legacyFile.writeAsBytes([1, 2, 3], flush: true);

    final path = await CatalogFileMigration.resolveCanonicalPath(
      directoryPath: tempDir.path,
      canonicalFileName: 'train_libre_training.db',
      legacyFileName: 'hypertrack_training.db',
    );

    expect(path, canonicalFile.path);
    expect(await canonicalFile.readAsBytes(), [9]);
    expect(await legacyFile.exists(), isTrue);
  });
}
