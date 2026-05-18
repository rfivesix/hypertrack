// lib/models/timeline_entry.dart

import '../../../diary/domain/models/tracked_food_item.dart';
import '../../../diary/domain/models/water_entry.dart';

// DOC: This is an "abstract" class. It serves as the shared
// template for all entry types in the diary.
// Every timeline item must have a timestamp so we can sort it.
/// Base class for all entries displayed in the daily timeline.
///
/// Ensures every timeline item has a [timestamp] for chronological sorting.
abstract class TimelineEntry {
  /// The time associated with this timeline entry.
  DateTime get timestamp;
}

/// A timeline entry representing a food intake event.
class FoodTimelineEntry extends TimelineEntry {
  /// The [TrackedFoodItem] containing the food and entry details.
  final TrackedFoodItem trackedItem;

  /// Creates a new [FoodTimelineEntry] instance.
  FoodTimelineEntry(this.trackedItem);

  @override
  DateTime get timestamp => trackedItem.entry.timestamp;
}

/// A timeline entry representing a water intake event.
class WaterTimelineEntry extends TimelineEntry {
  /// The [WaterEntry] containing the intake details.
  final WaterEntry waterEntry;

  /// Creates a new [WaterTimelineEntry] instance.
  WaterTimelineEntry(this.waterEntry);

  @override
  DateTime get timestamp => waterEntry.timestamp;
}
