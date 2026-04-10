import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/widgets/today_focus_widget_config.dart';
import 'package:hypertrack/features/widgets/today_focus_widget_models.dart';
import 'package:hypertrack/generated/app_localizations.dart';

void main() {
  test('stable metric order starts with calories and ends with sleep', () {
    expect(
        TodayFocusMetricTypeX.stableOrder.first, TodayFocusMetricType.calories);
    expect(TodayFocusMetricTypeX.stableOrder.last, TodayFocusMetricType.sleep);
  });

  test('copyWith clamps max item count', () {
    const config = TodayFocusWidgetConfig(
      enabled: true,
      maxVisibleItems: 6,
      selectedMetrics: TodayFocusWidgetConfig.defaultSelectedMetrics,
    );

    final clampedLow = config.copyWith(maxVisibleItems: 0);
    final clampedHigh = config.copyWith(maxVisibleItems: 999);

    expect(clampedLow.maxVisibleItems, 1);
    expect(clampedHigh.maxVisibleItems, 12);
  });

  test('labels resolve through app localizations', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final de = lookupAppLocalizations(const Locale('de'));

    expect(
      TodayFocusMetricType.calories.localizedLabel(en),
      'Calories',
    );
    expect(
      TodayFocusMetricType.calories.localizedLabel(de),
      'Kalorien',
    );
  });
}
