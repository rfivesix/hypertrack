import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/features/sleep/platform/permissions/sleep_permission_controller.dart';
import 'package:train_libre/features/sleep/platform/permissions/sleep_permission_models.dart';
import 'package:train_libre/features/sleep/platform/permissions/sleep_permissions_service.dart';
import 'package:train_libre/features/sleep/platform/sleep_sync_service.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/screens/health_export_settings_screen.dart';
import 'package:train_libre/screens/pulse_settings_screen.dart';
import 'package:train_libre/screens/sleep_settings_screen.dart';
import 'package:train_libre/screens/steps_settings_screen.dart';
import 'package:train_libre/services/theme_service.dart';

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

Widget _wrapWithPushButton(WidgetBuilder builder) {
  return ChangeNotifierProvider(
    create: (_) => ThemeService(),
    child: MaterialApp(
      key: UniqueKey(),
      theme: ThemeData(platform: TargetPlatform.iOS),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          return TextButton(
            key: const Key('open_route'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: builder),
              );
            },
            child: const Text('Open'),
          );
        },
      ),
    ),
  );
}

Future<void> _expectRouteAllowsInteractivePop(
  WidgetTester tester, {
  required WidgetBuilder builder,
  required Finder screenFinder,
}) async {
  await tester.pumpWidget(_wrapWithPushButton(builder));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('open_route')));
  await tester.pumpAndSettle();

  final route = ModalRoute.of(tester.element(screenFinder));

  expect(route, isNotNull);
  expect(route!.popDisposition, isNot(RoutePopDisposition.doNotPop));
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Train Libre',
      packageName: 'com.rfivesix.trainlibre',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('normal settings sub-screens do not veto iOS route pops', (
    tester,
  ) async {
    await _expectRouteAllowsInteractivePop(
      tester,
      builder: (_) => const StepsSettingsScreen(),
      screenFinder: find.byType(StepsSettingsScreen),
    );

    await _expectRouteAllowsInteractivePop(
      tester,
      builder: (_) {
        final controller = SleepPermissionController(
          const _StubPermissionService(),
        );
        return SleepSettingsScreen(
          sleepSyncService: _FakeSleepSettingsService(controller: controller),
          sleepPermissionController: controller,
        );
      },
      screenFinder: find.byType(SleepSettingsScreen),
    );

    await _expectRouteAllowsInteractivePop(
      tester,
      builder: (_) => const PulseSettingsScreen(),
      screenFinder: find.byType(PulseSettingsScreen),
    );

    await _expectRouteAllowsInteractivePop(
      tester,
      builder: (_) => const HealthExportSettingsScreen(),
      screenFinder: find.byType(HealthExportSettingsScreen),
    );
  });
}
