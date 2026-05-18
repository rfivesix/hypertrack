// lib/features/diary/domain/models/daily_goal.dart

/// Framework-agnostic pure domain model representing daily fitness and nutrition goals.
class DailyGoal {
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFat;
  final int targetWater;
  final int targetSteps;
  final DateTime createdAt;

  const DailyGoal({
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.targetWater,
    required this.targetSteps,
    required this.createdAt,
  });
}
