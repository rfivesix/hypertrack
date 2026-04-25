import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/pulse/application/pulse_tracking_service.dart';
import 'package:hypertrack/generated/app_localizations.dart';
import 'package:hypertrack/screens/pulse_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePulseTrackingService implements PulseTrackingSettingsService {
  bool enabled = false;
  int permissionRequests = 0;

  @override
  Future<bool> isTrackingEnabled() async => enabled;

  @override
  Future<bool> requestPermissions() async {
    permissionRequests += 1;
    return true;
  }

  @override
  Future<void> setTrackingEnabled(bool enabled) async {
    this.enabled = enabled;
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
      'pulse tracking setting is opt-in and requests permission on enable',
      (tester) async {
    final service = _FakePulseTrackingService();

    await tester.pumpWidget(
      _wrap(PulseSettingsScreen(trackingService: service)),
    );
    await tester.pumpAndSettle();

    final toggle = tester.widget<SwitchListTile>(
      find.byKey(const Key('pulse_tracking_toggle')),
    );
    expect(toggle.value, isFalse);

    await tester.tap(find.byKey(const Key('pulse_tracking_toggle')));
    await tester.pumpAndSettle();

    expect(service.enabled, isTrue);
    expect(service.permissionRequests, 1);
  });
}
