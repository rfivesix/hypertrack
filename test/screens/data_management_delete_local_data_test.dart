import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/features/settings/presentation/data_management_screen.dart';
import 'package:train_libre/services/local_app_data_reset_service.dart';
import 'package:train_libre/services/theme_service.dart';

class _FakeResetter implements LocalAppDataResetter {
  int calls = 0;

  @override
  Future<LocalAppDataResetReport> deleteAllLocalAppData() async {
    calls += 1;
    return const LocalAppDataResetReport(
      clearedStores: ['test store'],
      preservedStores: ['test preserved store'],
    );
  }
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
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    _FakeResetter resetter, {
    VoidCallback? onResetComplete,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        DataManagementScreen(
          localDataResetter: resetter,
          onResetComplete: onResetComplete,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('delete all local app data option is visible', (tester) async {
    final resetter = _FakeResetter();
    await pumpScreen(tester, resetter);

    expect(find.text('Delete all local app data'), findsOneWidget);
    expect(
      find.byKey(const Key('delete_all_local_app_data_button')),
      findsOneWidget,
    );
  });

  testWidgets('confirmation is required before deleting', (tester) async {
    final resetter = _FakeResetter();
    await pumpScreen(tester, resetter);

    await tester.tap(find.byKey(const Key('delete_all_local_app_data_button')));
    await tester.pumpAndSettle();

    expect(find.text('Delete all local app data?'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('confirm_delete_local_data_button')),
          )
          .onPressed,
      isNull,
    );
    expect(resetter.calls, 0);
  });

  testWidgets('cancel does not delete local app data', (tester) async {
    final resetter = _FakeResetter();
    await pumpScreen(tester, resetter);

    await tester.tap(find.byKey(const Key('delete_all_local_app_data_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancel_delete_local_data_button')));
    await tester.pumpAndSettle();

    expect(resetter.calls, 0);
  });

  testWidgets('confirm calls the reset service', (tester) async {
    final resetter = _FakeResetter();
    var completed = false;
    await pumpScreen(
      tester,
      resetter,
      onResetComplete: () => completed = true,
    );

    await tester.tap(find.byKey(const Key('delete_all_local_app_data_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('delete_local_data_confirmation_field')),
      'DELETE',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm_delete_local_data_button')));
    await tester.pumpAndSettle();

    expect(resetter.calls, 1);
    expect(completed, isTrue);
  });

  testWidgets('warning copy mentions Health exports are not deleted', (
    tester,
  ) async {
    final resetter = _FakeResetter();
    await pumpScreen(tester, resetter);

    await tester.tap(find.byKey(const Key('delete_all_local_app_data_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Apple Health'), findsOneWidget);
    expect(find.textContaining('Health Connect'), findsOneWidget);
    expect(find.textContaining('does not delete data already exported'),
        findsOneWidget);
  });
}
