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
  _StubPermissionService(this._status, this._requestedStatus);

  final SleepPermissionOutcome _status;
  final SleepPermissionOutcome _requestedStatus;

  @override
  Future<SleepPermissionOutcome> checkStatus() async => _status;

  @override
  Future<SleepPermissionOutcome> requestAccess() async => _requestedStatus;
}

class _FakeSleepSettingsService implements SleepSettingsService {
  _FakeSleepSettingsService({required this.controller});

  final SleepPermissionController controller;
  bool enabled = false;
  late SleepSyncResult importResult;
  int importCalls = 0;

  @override
  SleepPermissionController buildPermissionController() => controller;

  @override
  Future<bool> isTrackingEnabled() async => enabled;

  @override
  Future<void> setTrackingEnabled(bool value) async {
    enabled = value;
  }

  @override
  Future<SleepSyncResult> importRecent({int lookbackDays = 30}) async {
    importCalls += 1;
    return importResult;
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'HyperTrack',
      packageName: 'com.rfivesix.hypertrack',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders sleep settings section and permission status', (
    tester,
  ) async {
    final controller = SleepPermissionController(
      _StubPermissionService(
        const SleepPermissionOutcome.state(SleepPermissionState.partial),
        const SleepPermissionOutcome.state(SleepPermissionState.partial),
      ),
    );
    final service = _FakeSleepSettingsService(controller: controller);
    service.importResult = const SleepSyncResult(
      success: true,
      permissionState: SleepPermissionState.ready,
      importedSessions: 1,
    );
    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          sleepSyncService: service,
          sleepPermissionController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('SLEEP'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('SLEEP'), findsOneWidget);
    expect(find.text('Enable sleep tracking'), findsOneWidget);
    expect(find.text('Health connection status'), findsOneWidget);
    expect(find.text('Partial access'), findsOneWidget);
  });

  testWidgets('tapping request access updates permission state label', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = SleepPermissionController(
      _StubPermissionService(
        const SleepPermissionOutcome.state(SleepPermissionState.denied),
        const SleepPermissionOutcome.ready(),
      ),
    );
    final service = _FakeSleepSettingsService(controller: controller);
    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          sleepSyncService: service,
          sleepPermissionController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final requestAccessTile = find.widgetWithText(ListTile, 'Request access');
    await tester.scrollUntilVisible(
      requestAccessTile,
      500,
    );
    expect(find.text('Denied'), findsOneWidget);
    await tester.ensureVisible(requestAccessTile);
    await tester.tap(requestAccessTile);
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('tapping import sleep data triggers orchestration', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = SleepPermissionController(
      _StubPermissionService(
        const SleepPermissionOutcome.ready(),
        const SleepPermissionOutcome.ready(),
      ),
    );
    final service = _FakeSleepSettingsService(controller: controller);
    service.importResult = const SleepSyncResult(
      success: true,
      permissionState: SleepPermissionState.ready,
      importedSessions: 1,
    );
    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          sleepSyncService: service,
          sleepPermissionController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final importTile = find.widgetWithText(ListTile, 'Import sleep data now');
    await tester.scrollUntilVisible(
      importTile,
      500,
    );
    await tester.ensureVisible(importTile);
    await tester.tap(importTile);
    await tester.pumpAndSettle();
    expect(service.importCalls, 1);
  });

  testWidgets('renders not-installed permission state text', (tester) async {
    final controller = SleepPermissionController(
      _StubPermissionService(
        const SleepPermissionOutcome.state(SleepPermissionState.notInstalled),
        const SleepPermissionOutcome.state(SleepPermissionState.notInstalled),
      ),
    );
    final service = _FakeSleepSettingsService(controller: controller);
    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          sleepSyncService: service,
          sleepPermissionController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Health connection status'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Health Connect not installed'), findsOneWidget);
  });
}
