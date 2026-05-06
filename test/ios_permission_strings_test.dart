import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const permissionKeys = {
    'NSCameraUsageDescription',
    'NSMicrophoneUsageDescription',
    'NSHealthShareUsageDescription',
    'NSHealthUpdateUsageDescription',
    'NSPhotoLibraryUsageDescription',
    'NSSpeechRecognitionUsageDescription',
  };

  test('English InfoPlist permission strings exist for every iOS usage key',
      () async {
    final plist = await File('ios/Runner/Info.plist').readAsString();
    final englishStrings =
        await File('ios/Runner/en.lproj/InfoPlist.strings').readAsString();

    for (final key in permissionKeys) {
      expect(plist, contains('<key>$key</key>'));
      expect(englishStrings, contains('"$key" = "Train Libre '));
    }
  });

  test('German InfoPlist permission strings mirror existing iOS usage keys',
      () async {
    final germanStrings =
        await File('ios/Runner/de.lproj/InfoPlist.strings').readAsString();

    for (final key in permissionKeys) {
      expect(germanStrings, contains('"$key" = "Train Libre '));
    }
  });
}
