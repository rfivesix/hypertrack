import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/platform/permissions/sleep_permission_controller.dart';
import 'package:hypertrack/features/sleep/platform/permissions/sleep_permission_models.dart';
import 'package:hypertrack/features/sleep/platform/permissions/sleep_permissions_service.dart';
import 'package:hypertrack/features/sleep/platform/sleep_sync_service.dart';
import 'package:hypertrack/generated/app_localizations.dart';
import 'package:hypertrack/screens/settings_screen.dart';
import 'package:hypertrack/services/theme_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubPermissionService implements SleepPermissionsService {
  const _StubPermissionService();

  @override
  Future<SleepPermissionOutcome> checkStatus() async =>
      const SleepPermissionOutcome.ready();

  @override
  Future<SleepPermissionOutcome> requestAccess() async =>
      const SleepPermissionOutcome.ready();
}

class _FakeSleepSettingsService implements SleepSettingsService {
  _FakeSleepSettingsService({required this.controller});

  final SleepPermissionController controller;

  @override
  SleepPermissionController buildPermissionController() => controller;

  @override
  Future<bool> isTrackingEnabled() async => false;

  @override
  Future<void> setTrackingEnabled(bool value) async {}

  @override
  Future<SleepSyncResult> importRecent({int lookbackDays = 30}) async {
    return const SleepSyncResult(
      success: true,
      permissionState: SleepPermissionState.ready,
      importedSessions: 0,
    );
  }

  @override
  Future<SleepSyncResult?> importRecentIfDue({
    int lookbackDays = 30,
    Duration minInterval = const Duration(hours: 6),
    bool force = false,
  }) async {
    return null;
  }

  @override
  Future<void> dispose() async {}
}

Widget _wrap(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => ThemeService(),
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'HyperTrack',
      packageName: 'com.rfivesix.hypertrack',
      version: '0.8.6',
      buildNumber: '80014',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('settings shows feedback entry and opens feedback report screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller =
        SleepPermissionController(const _StubPermissionService());
    final sleepService = _FakeSleepSettingsService(controller: controller);

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          sleepSyncService: sleepService,
          sleepPermissionController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final feedbackTile = find.widgetWithText(ListTile, 'Send feedback');
    await tester.scrollUntilVisible(
      feedbackTile,
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(feedbackTile, findsOneWidget);
    await tester.tap(feedbackTile);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feedback_report_screen')), findsOneWidget);
  });
}
