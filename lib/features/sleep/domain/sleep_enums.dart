/// Canonical sleep stage taxonomy used by domain and canonical persistence.
enum CanonicalSleepStage {
  awake,
  light,
  deep,
  rem,
  asleepUnspecified,
  inBedOnly,
  outOfBed,
  unknown,
}

/// Session classification used for normalization and nightly selection.
enum SleepSessionType { mainSleep, nap, unknown }

/// Confidence level for stage timeline quality.
enum SleepStageConfidence { high, medium, low, unknown }

/// Confidence level for heart-rate signal quality.
enum HeartRateConfidence { high, medium, low, unknown }

/// Confidence level for overall session reliability.
enum SleepOverallConfidence { high, medium, low, unknown }

/// Coarse sleep quality bucket intended for derived analysis output.
enum SleepQualityBucket { good, average, poor, unavailable }
