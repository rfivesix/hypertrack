import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileService persistence behavior', () {
    test('initialize keeps saved image path when file exists', () async {
      final tempDir = await Directory.systemTemp.createTemp('profile_service_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final imageFile = File('${tempDir.path}/profile.jpg');
      await imageFile.writeAsString('image-data');

      SharedPreferences.setMockInitialValues(<String, Object>{
        'profileImagePath': imageFile.path,
      });

      final service = ProfileService();
      await service.initialize();

      expect(service.profileImagePath, imageFile.path);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('profileImagePath'), imageFile.path);
    });

    test('initialize clears stale image path when file is missing', () async {
      final missingPath =
          '${Directory.systemTemp.path}/does_not_exist_profile_image.jpg';
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profileImagePath': missingPath,
      });

      final service = ProfileService();
      await service.initialize();

      expect(service.profileImagePath, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('profileImagePath'), isNull);
    });

    test('deleteProfileImage clears prefs/state and deletes file', () async {
      final tempDir = await Directory.systemTemp.createTemp('profile_service_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final imageFile = File('${tempDir.path}/profile.jpg');
      await imageFile.writeAsString('image-data');
      SharedPreferences.setMockInitialValues(<String, Object>{
        'profileImagePath': imageFile.path,
      });

      final service = ProfileService();
      await service.initialize();
      await service.deleteProfileImage();

      expect(service.profileImagePath, isNull);
      expect(await imageFile.exists(), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('profileImagePath'), isNull);
    });
  });
}
