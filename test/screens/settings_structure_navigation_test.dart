import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/sleep/platform/permissions/sleep_permission_controller.dart';
import 'package:hypertrack/features/sleep/platform/permissions/sleep_permission_models.dart';
import 'package:hypertrack/features/sleep/platform/permissions/sleep_permissions_service.dart';
import 'package:hypertrack/features/sleep/platform/sleep_sync_service.dart';
import 'package:hypertrack/generated/app_localizations.dart';
import 'package:hypertrack/screens/appearance_settings_screen.dart';
import 'package:hypertrack/screens/settings_screen.dart';
import 'package:hypertrack/screens/sleep_settings_screen.dart';
import 'package:hypertrack/screens/pulse_settings_screen.dart';
import 'package:hypertrack/screens/steps_settings_screen.dart';
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
      version: '0.8.11',
      buildNumber: '80021',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('main settings shows new section structure and entry rows', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller =
        SleepPermissionController(const _StubPermissionService());

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          sleepSyncService: _FakeSleepSettingsService(controller: controller),
          sleepPermissionController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings_section_app')), findsOneWidget);
    expect(
      find.byKey(const Key('settings_section_health_tracking')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings_section_nutrition_data')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings_section_support_about')),
      findsOneWidget,
    );

    expect(find.byKey(const Key('settings_appearance_entry')), findsOneWidget);
    expect(find.byKey(const Key('settings_steps_entry')), findsOneWidget);
    expect(find.byKey(const Key('settings_sleep_entry')), findsOneWidget);
    expect(find.byKey(const Key('settings_pulse_entry')), findsOneWidget);
    expect(
      find.byKey(const Key('settings_health_export_entry')),
      findsOneWidget,
    );
  });

  testWidgets('appearance entry opens appearance settings sub-screen', (
    tester,
  ) async {
    final controller =
        SleepPermissionController(const _StubPermissionService());

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          sleepSyncService: _FakeSleepSettingsService(controller: controller),
          sleepPermissionController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings_appearance_entry')));
    await tester.pumpAndSettle();

    expect(find.byType(AppearanceSettingsScreen), findsOneWidget);
  });

  testWidgets('steps entry opens steps settings sub-screen', (tester) async {
    final controller =
        SleepPermissionController(const _StubPermissionService());

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          sleepSyncService: _FakeSleepSettingsService(controller: controller),
          sleepPermissionController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings_steps_entry')));
    await tester.pumpAndSettle();

    expect(find.byType(StepsSettingsScreen), findsOneWidget);
  });

  testWidgets('sleep entry opens sleep settings sub-screen', (tester) async {
    final controller =
        SleepPermissionController(const _StubPermissionService());

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          sleepSyncService: _FakeSleepSettingsService(controller: controller),
          sleepPermissionController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final sleepEntry = find.byKey(const Key('settings_sleep_entry'));
    await tester.scrollUntilVisible(
      sleepEntry,
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(sleepEntry);
    await tester.pumpAndSettle();

    expect(find.byType(SleepSettingsScreen), findsOneWidget);
  });

  testWidgets('pulse entry opens pulse settings sub-screen', (tester) async {
    final controller =
        SleepPermissionController(const _StubPermissionService());

    await tester.pumpWidget(
      _wrap(
        SettingsScreen(
          sleepSyncService: _FakeSleepSettingsService(controller: controller),
          sleepPermissionController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pulseEntry = find.byKey(const Key('settings_pulse_entry'));
    await tester.scrollUntilVisible(
      pulseEntry,
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(pulseEntry);
    await tester.pumpAndSettle();

    expect(find.byType(PulseSettingsScreen), findsOneWidget);
  });

  testWidgets(
    'restart app tour tile remains in app section and appears before health section',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller =
          SleepPermissionController(const _StubPermissionService());

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            sleepSyncService: _FakeSleepSettingsService(controller: controller),
            sleepPermissionController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final restartTile =
          find.byKey(const Key('settings_restart_app_tour_tile'));
      final healthSection =
          find.byKey(const Key('settings_section_health_tracking'));
      final diaryText = find.text('Show sugar in Diary overview');

      expect(restartTile, findsOneWidget);
      expect(healthSection, findsOneWidget);
      expect(diaryText, findsOneWidget);

      final restartTop = tester.getTopLeft(restartTile).dy;
      final healthTop = tester.getTopLeft(healthSection).dy;
      final diaryTop = tester.getTopLeft(diaryText).dy;

      expect(diaryTop, lessThan(restartTop));
      expect(restartTop, lessThan(healthTop));
    },
  );
}
