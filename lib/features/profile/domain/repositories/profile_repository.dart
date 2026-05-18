// lib/features/profile/domain/repositories/profile_repository.dart
import 'package:flutter/material.dart';
import '../../../../data/drift_database.dart' as db;
import '../models/measurement_session.dart';
import '../../../analytics/domain/models/chart_data_point.dart';

/// Abstract contract for Profile data persistence and operations.
abstract class IProfileRepository {
  Future<db.Profile?> getUserProfile();
  Future<void> saveUserProfile({
    required String name,
    required DateTime? birthday,
    required int? height,
    required String? gender,
  });
  Future<List<MeasurementSession>> getMeasurementSessions();
  Future<DateTime?> getEarliestMeasurementDate();
  Future<void> deleteMeasurementSession(int sessionId);
  Future<void> insertMeasurementSession(MeasurementSession session);
  Future<List<ChartDataPoint>> getChartDataForTypeAndRange(String type, DateTimeRange range);
  Future<db.AppSetting?> getAppSettings();
  Future<int> getCurrentTargetStepsOrDefault();
  Future<void> saveUserGoals({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required int water,
    required int steps,
  });
}
