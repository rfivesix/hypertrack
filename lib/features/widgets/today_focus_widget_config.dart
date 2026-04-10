import 'package:shared_preferences/shared_preferences.dart';

import 'today_focus_widget_models.dart';

class TodayFocusWidgetConfig {
  const TodayFocusWidgetConfig({
    required this.enabled,
    required this.maxVisibleItems,
    required this.selectedMetrics,
  });

  static const String enabledKey = 'todayFocusWidgetEnabled';
  static const String maxVisibleItemsKey = 'todayFocusWidgetMaxVisibleItems';
  static const String selectedMetricsKey = 'todayFocusWidgetSelectedMetrics';

  static const int defaultMaxVisibleItems = 6;

  static const List<TodayFocusMetricType> defaultSelectedMetrics =
      TodayFocusMetricTypeX.stableOrder;

  final bool enabled;
  final int maxVisibleItems;
  final List<TodayFocusMetricType> selectedMetrics;

  static Future<TodayFocusWidgetConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(enabledKey) ?? true;
    final maxVisibleItems =
        (prefs.getInt(maxVisibleItemsKey) ?? defaultMaxVisibleItems)
            .clamp(1, 12);
    final rawMetricKeys = prefs.getStringList(selectedMetricsKey) ??
        defaultSelectedMetrics.map((metric) => metric.key).toList();

    final selected = <TodayFocusMetricType>[];
    for (final raw in rawMetricKeys) {
      final type = TodayFocusMetricTypeX.fromKey(raw);
      if (type != null && !selected.contains(type)) {
        selected.add(type);
      }
    }

    final normalized = <TodayFocusMetricType>[];
    for (final metric in TodayFocusMetricTypeX.stableOrder) {
      if (selected.contains(metric)) {
        normalized.add(metric);
      }
    }

    return TodayFocusWidgetConfig(
      enabled: enabled,
      maxVisibleItems: maxVisibleItems,
      selectedMetrics: normalized.isEmpty ? defaultSelectedMetrics : normalized,
    );
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, enabled);
    await prefs.setInt(maxVisibleItemsKey, maxVisibleItems.clamp(1, 12));
    await prefs.setStringList(
      selectedMetricsKey,
      selectedMetrics.map((metric) => metric.key).toList(),
    );
  }

  TodayFocusWidgetConfig copyWith({
    bool? enabled,
    int? maxVisibleItems,
    List<TodayFocusMetricType>? selectedMetrics,
  }) {
    return TodayFocusWidgetConfig(
      enabled: enabled ?? this.enabled,
      maxVisibleItems: (maxVisibleItems ?? this.maxVisibleItems).clamp(1, 12),
      selectedMetrics: selectedMetrics ?? this.selectedMetrics,
    );
  }
}
