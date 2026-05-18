// lib/models/tracked_supplement.dart
import 'supplement.dart';

/// A wrapper class for a [Supplement] with its total consumption for the current day.
///
/// Used in the UI to display supplement progress against goals or limits.
class TrackedSupplement {
  /// The [Supplement] being tracked.
  final Supplement supplement;

  /// The total amount of the supplement consumed today.
  final double totalDosedToday;

  /// Creates a new [TrackedSupplement] instance.
  const TrackedSupplement({
    required this.supplement,
    required this.totalDosedToday,
  });
}
