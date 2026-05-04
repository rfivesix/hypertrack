import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/backup_manager.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('backup JSON helpers preserve nested payloads off the main isolate',
      () async {
    final payload = <String, dynamic>{
      'appName': BackupManager.currentBackupAppName,
      'schemaVersion': BackupManager.currentSchemaVersion,
      'items': [
        {'barcode': 'a', 'quantity': 125},
        {'barcode': 'b', 'quantity': 250},
      ],
    };

    final encoded = await encodeBackupJsonPayloadForTesting(payload);
    final decoded = await decodeBackupJsonPayloadForTesting(encoded);

    expect(decoded, payload);
  });

  test(
    'resolveWritableBackupDirectory uses explicit writable directory',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'hypertrack_backup_manager_test_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });

      final chosen = Directory(p.join(root.path, 'chosen'));
      final resolved = await BackupManager.resolveWritableBackupDirectory(
        docsDir: root,
        dirPath: chosen.path,
        savedDir: null,
      );

      expect(resolved.path, chosen.path);
      expect(await resolved.exists(), isTrue);
    },
  );

  test(
    'resolveWritableBackupDirectory falls back to docs Backups when explicit path is invalid',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'hypertrack_backup_manager_test_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });

      final invalidAsFile = File(p.join(root.path, 'not_a_directory'));
      await invalidAsFile.writeAsString('block directory creation');

      final expectedFallback = p.join(root.path, 'Backups');
      final resolved = await BackupManager.resolveWritableBackupDirectory(
        docsDir: root,
        dirPath: invalidAsFile.path,
        savedDir: null,
      );

      expect(resolved.path, expectedFallback);
      expect(await Directory(expectedFallback).exists(), isTrue);
    },
  );
}
