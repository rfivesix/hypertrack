import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/features/analytics/domain/models/chart_data_point.dart';
import 'package:train_libre/features/profile/domain/models/measurement_session.dart';
import 'package:train_libre/features/profile/domain/repositories/profile_repository.dart';
import 'package:train_libre/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeProfileRepository implements IProfileRepository {
  db.Profile? profile;

  @override
  Future<db.Profile?> getUserProfile() async => profile;

  @override
  Future<void> saveUserProfile({
    required String name,
    required DateTime? birthday,
    required int? height,
    required String? gender,
  }) async {
    // Basic implementation for testing
  }

  @override
  Future<db.AppSetting?> getAppSettings() async => null;

  @override
  Future<void> deleteMeasurementSession(int sessionId) async {}

  @override
  Future<List<ChartDataPoint>> getChartDataForTypeAndRange(String type, DateTimeRange range) async => [];

  @override
  Future<int> getCurrentTargetStepsOrDefault() async => 8000;

  @override
  Future<DateTime?> getEarliestMeasurementDate() async => null;

  @override
  Future<List<MeasurementSession>> getMeasurementSessions() async => [];

  @override
  Future<void> insertMeasurementSession(MeasurementSession session) async {}

  @override
  Future<void> saveUserGoals({required int calories, required int protein, required int carbs, required int fat, required int water, required int steps}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = FakeProfileRepository();

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
      await service.initialize(repository);

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
      await service.initialize(repository);

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
      await service.initialize(repository);
      await service.deleteProfileImage();

      expect(service.profileImagePath, isNull);
      expect(await imageFile.exists(), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('profileImagePath'), isNull);
    });
  });
}
