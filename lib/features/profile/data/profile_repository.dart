// lib/features/profile/data/profile_repository.dart
import 'package:flutter/material.dart';
import '../../../data/drift_database.dart' as db;
import '../../profile/domain/models/measurement_session.dart';
import '../../analytics/domain/models/chart_data_point.dart';
import 'sources/profile_local_data_source.dart';
import '../domain/repositories/profile_repository.dart';

/// Concrete implementation of [IProfileRepository] for profile and measurement tracking.
class ProfileRepository implements IProfileRepository {
  final ProfileLocalDataSource _localDataSource;

  ProfileRepository({required ProfileLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<db.Profile?> getUserProfile() {
    return _localDataSource.getUserProfile();
  }

  @override
  Future<void> saveUserProfile({
    required String name,
    required DateTime? birthday,
    required int? height,
    required String? gender,
  }) {
    return _localDataSource.saveUserProfile(
      name: name,
      birthday: birthday,
      height: height?.toDouble(),
      gender: gender,
    );
  }

  @override
  Future<List<MeasurementSession>> getMeasurementSessions() {
    return _localDataSource.getMeasurementSessions();
  }

  @override
  Future<DateTime?> getEarliestMeasurementDate() {
    return _localDataSource.getEarliestMeasurementDate();
  }

  @override
  Future<void> deleteMeasurementSession(int sessionId) {
    return _localDataSource.deleteMeasurementSession(sessionId);
  }

  @override
  Future<void> insertMeasurementSession(MeasurementSession session) {
    return _localDataSource.insertMeasurementSession(session);
  }

  @override
  Future<List<ChartDataPoint>> getChartDataForTypeAndRange(
      String type, DateTimeRange range) async {
    final raw = await _localDataSource.getChartDataForTypeAndRange(type, range);
    return raw.map((item) {
      return ChartDataPoint(
        date: item['date'] as DateTime,
        value: (item['value'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  Future<db.AppSetting?> getAppSettings() {
    return _localDataSource.getAppSettings();
  }

  @override
  Future<int> getCurrentTargetStepsOrDefault() {
    return _localDataSource.getCurrentTargetStepsOrDefault();
  }

  @override
  Future<void> saveUserGoals({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required int water,
    required int steps,
  }) {
    return _localDataSource.saveUserGoals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      water: water,
      steps: steps,
    );
  }
}
