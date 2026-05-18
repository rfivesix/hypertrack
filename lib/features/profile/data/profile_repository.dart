// lib/features/profile/data/profile_repository.dart
import 'package:flutter/material.dart';
import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart' as db;
import '../../profile/domain/models/measurement_session.dart';
import '../../analytics/domain/models/chart_data_point.dart';

class ProfileRepository {
  final DatabaseHelper _dbHelper;

  ProfileRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // Added this to expose for other services if needed
  DatabaseHelper get dbHelper => _dbHelper;

  Future<db.Profile?> getUserProfile() {
    return _dbHelper.getUserProfile();
  }

  Future<void> saveUserProfile({
    required String name,
    required DateTime? birthday,
    required int? height,
    required String? gender,
  }) {
    return _dbHelper.saveUserProfile(
      name: name,
      birthday: birthday,
      height: height,
      gender: gender,
    );
  }

  Future<List<MeasurementSession>> getMeasurementSessions() {
    return _dbHelper.getMeasurementSessions();
  }

  Future<DateTime?> getEarliestMeasurementDate() {
    return _dbHelper.getEarliestMeasurementDate();
  }

  Future<void> deleteMeasurementSession(int sessionId) {
    return _dbHelper.deleteMeasurementSession(sessionId);
  }

  Future<void> insertMeasurementSession(MeasurementSession session) {
    return _dbHelper.insertMeasurementSession(session);
  }

  Future<List<ChartDataPoint>> getChartDataForTypeAndRange(String type, DateTimeRange range) {
    return _dbHelper.getChartDataForTypeAndRange(type, range);
  }

  Future<db.AppSetting?> getAppSettings() {
    return _dbHelper.getAppSettings();
  }

  Future<int> getCurrentTargetStepsOrDefault() {
    return _dbHelper.getCurrentTargetStepsOrDefault();
  }

  Future<void> saveUserGoals({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required int water,
    required int steps,
  }) {
    return _dbHelper.saveUserGoals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      water: water,
      steps: steps,
    );
  }
}
