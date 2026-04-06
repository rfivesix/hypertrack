enum RecommendationEstimationMode {
  heuristic,
  bayesianExperimental,
}

extension RecommendationEstimationModeKey on RecommendationEstimationMode {
  String get persistenceSuffix {
    switch (this) {
      case RecommendationEstimationMode.heuristic:
        return 'heuristic';
      case RecommendationEstimationMode.bayesianExperimental:
        return 'bayesian_experimental';
    }
  }
}
