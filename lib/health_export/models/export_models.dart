import 'dart:convert';

enum HealthExportPlatform { appleHealth, healthConnect }

enum HealthExportDomain { measurements, nutritionHydration, workouts }

enum HealthExportState { idle, exporting, success, failed, disabled }

enum ExportMeasurementType { weight, bodyFatPercentage, bmi }

enum ExportWorkoutType { strength, running, walking, cycling, yoga, other }

class ExportMeasurementRecord {
  const ExportMeasurementRecord({
    required this.idempotencyKey,
    required this.timestampUtc,
    required this.type,
    required this.value,
  });

  final String idempotencyKey;
  final DateTime timestampUtc;
  final ExportMeasurementType type;
  final double value;

  Map<String, dynamic> toMap() => {
        'idempotencyKey': idempotencyKey,
        'timestampUtcIso': timestampUtc.toUtc().toIso8601String(),
        'type': type.name,
        'value': value,
      };
}

class ExportNutritionRecord {
  const ExportNutritionRecord({
    required this.idempotencyKey,
    required this.timestampUtc,
    this.caloriesKcal,
    this.proteinGrams,
    this.carbsGrams,
    this.fatGrams,
    this.fiberGrams,
    this.sugarGrams,
    this.sodiumGrams,
  });

  final String idempotencyKey;
  final DateTime timestampUtc;
  final double? caloriesKcal;
  final double? proteinGrams;
  final double? carbsGrams;
  final double? fatGrams;
  final double? fiberGrams;
  final double? sugarGrams;
  final double? sodiumGrams;

  bool get hasAnyValue =>
      caloriesKcal != null ||
      proteinGrams != null ||
      carbsGrams != null ||
      fatGrams != null ||
      fiberGrams != null ||
      sugarGrams != null ||
      sodiumGrams != null;

  Map<String, dynamic> toMap() => {
        'idempotencyKey': idempotencyKey,
        'timestampUtcIso': timestampUtc.toUtc().toIso8601String(),
        'caloriesKcal': caloriesKcal,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
        'fiberGrams': fiberGrams,
        'sugarGrams': sugarGrams,
        'sodiumGrams': sodiumGrams,
      };
}

class ExportHydrationRecord {
  const ExportHydrationRecord({
    required this.idempotencyKey,
    required this.timestampUtc,
    required this.volumeLiters,
  });

  final String idempotencyKey;
  final DateTime timestampUtc;
  final double volumeLiters;

  Map<String, dynamic> toMap() => {
        'idempotencyKey': idempotencyKey,
        'timestampUtcIso': timestampUtc.toUtc().toIso8601String(),
        'volumeLiters': volumeLiters,
      };
}

class ExportWorkoutRecord {
  const ExportWorkoutRecord({
    required this.idempotencyKey,
    required this.startUtc,
    required this.endUtc,
    required this.workoutType,
    this.caloriesBurnedKcal,
    this.title,
    this.notes,
  });

  final String idempotencyKey;
  final DateTime startUtc;
  final DateTime endUtc;
  final ExportWorkoutType workoutType;
  final double? caloriesBurnedKcal;
  final String? title;
  final String? notes;

  Map<String, dynamic> toMap() => {
        'idempotencyKey': idempotencyKey,
        'startUtcIso': startUtc.toUtc().toIso8601String(),
        'endUtcIso': endUtc.toUtc().toIso8601String(),
        'workoutType': workoutType.name,
        'caloriesBurnedKcal': caloriesBurnedKcal,
        'title': title,
        'notes': notes,
      };
}

class HealthExportDomainStatus {
  const HealthExportDomainStatus({
    required this.state,
    this.lastSuccessfulExportAtUtc,
    this.lastError,
  });

  final HealthExportState state;
  final DateTime? lastSuccessfulExportAtUtc;
  final String? lastError;

  static HealthExportDomainStatus idle() =>
      const HealthExportDomainStatus(state: HealthExportState.idle);

  Map<String, dynamic> toMap() => {
        'state': state.name,
        'lastSuccessfulExportAtUtcIso':
            lastSuccessfulExportAtUtc?.toUtc().toIso8601String(),
        'lastError': lastError,
      };

  factory HealthExportDomainStatus.fromMap(Map<String, dynamic> map) {
    final stateRaw = (map['state'] as String?) ?? HealthExportState.idle.name;
    final state = HealthExportState.values.firstWhere(
      (candidate) => candidate.name == stateRaw,
      orElse: () => HealthExportState.idle,
    );
    final lastSuccessIso = map['lastSuccessfulExportAtUtcIso'] as String?;
    return HealthExportDomainStatus(
      state: state,
      lastSuccessfulExportAtUtc:
          lastSuccessIso == null ? null : DateTime.tryParse(lastSuccessIso),
      lastError: map['lastError'] as String?,
    );
  }
}

class HealthExportPlatformStatus {
  const HealthExportPlatformStatus({
    required this.platform,
    required this.byDomain,
  });

  final HealthExportPlatform platform;
  final Map<HealthExportDomain, HealthExportDomainStatus> byDomain;

  HealthExportDomainStatus statusFor(HealthExportDomain domain) =>
      byDomain[domain] ?? HealthExportDomainStatus.idle();

  Map<String, dynamic> toMap() => {
        'platform': platform.name,
        'byDomain': {
          for (final entry in byDomain.entries)
            entry.key.name: entry.value.toMap(),
        },
      };

  factory HealthExportPlatformStatus.initial(HealthExportPlatform platform) {
    return HealthExportPlatformStatus(
      platform: platform,
      byDomain: {
        for (final domain in HealthExportDomain.values)
          domain: HealthExportDomainStatus.idle(),
      },
    );
  }

  factory HealthExportPlatformStatus.fromMap(Map<String, dynamic> map) {
    final platformRaw =
        (map['platform'] as String?) ?? HealthExportPlatform.appleHealth.name;
    final platform = HealthExportPlatform.values.firstWhere(
      (candidate) => candidate.name == platformRaw,
      orElse: () => HealthExportPlatform.appleHealth,
    );
    final rawByDomain =
        (map['byDomain'] as Map?)?.cast<String, dynamic>() ?? const {};
    final byDomain = <HealthExportDomain, HealthExportDomainStatus>{
      for (final domain in HealthExportDomain.values)
        domain: rawByDomain[domain.name] is Map
            ? HealthExportDomainStatus.fromMap(
                (rawByDomain[domain.name] as Map).cast<String, dynamic>(),
              )
            : HealthExportDomainStatus.idle(),
    };
    return HealthExportPlatformStatus(platform: platform, byDomain: byDomain);
  }
}

String encodePlatformStatusMap(
  Map<HealthExportPlatform, HealthExportPlatformStatus> statuses,
) {
  final jsonMap = {
    for (final entry in statuses.entries) entry.key.name: entry.value.toMap(),
  };
  return jsonEncode(jsonMap);
}

Map<HealthExportPlatform, HealthExportPlatformStatus> decodePlatformStatusMap(
  String? raw,
) {
  if (raw == null || raw.isEmpty) {
    return {
      for (final platform in HealthExportPlatform.values)
        platform: HealthExportPlatformStatus.initial(platform),
    };
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Invalid status payload');
    }
    final map = decoded.cast<String, dynamic>();
    return {
      for (final platform in HealthExportPlatform.values)
        platform: map[platform.name] is Map
            ? HealthExportPlatformStatus.fromMap(
                (map[platform.name] as Map).cast<String, dynamic>(),
              )
            : HealthExportPlatformStatus.initial(platform),
    };
  } catch (_) {
    return {
      for (final platform in HealthExportPlatform.values)
        platform: HealthExportPlatformStatus.initial(platform),
    };
  }
}
