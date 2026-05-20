import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/presentation/edit_routine_screen.dart';
import 'package:train_libre/generated/app_localizations.dart';
import 'package:train_libre/services/theme_service.dart';
import 'package:train_libre/services/unit_service.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrapWithPushButton(WidgetBuilder builder) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeService()),
      ChangeNotifierProvider(create: (_) => UnitService()),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open_route'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: builder),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(_wrapWithPushButton((_) => const EditRoutineScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_route')));
    await tester.pumpAndSettle();
  }

  testWidgets('clean state leaves immediately without sheet', (tester) async {
    await openScreen(tester);

    // Tap the back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // The screen should pop without a sheet
    expect(find.text('Unsaved Changes'), findsNothing);
    expect(find.byType(EditRoutineScreen), findsNothing);
  });

  testWidgets('dirty state shows confirmation sheet on pop attempt, discard leaves without saving', (tester) async {
    await openScreen(tester);

    // Make dirty by typing in name field
    await tester.enterText(find.byType(TextField).first, 'My Awesome Routine');
    await tester.pumpAndSettle();

    // Tap the back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // The sheet should appear
    expect(find.text('Unsaved Changes'), findsOneWidget);

    // Tap Discard
    await tester.tap(find.widgetWithText(OutlinedButton, 'Discard'));
    await tester.pumpAndSettle();

    // Sheet is gone and screen is popped
    expect(find.text('Unsaved Changes'), findsNothing);
    expect(find.byType(EditRoutineScreen), findsNothing);

    // Verify it wasn't saved to DB
    final routines = await WorkoutLocalDataSource.instance.getAllRoutines();
    expect(routines.isEmpty, true);
  });

  testWidgets('dirty state shows confirmation sheet on pop attempt, save persists and leaves', (tester) async {
    await openScreen(tester);

    // Make dirty by typing in name field
    await tester.enterText(find.byType(TextField).first, 'My Awesome Routine');
    await tester.pumpAndSettle();

    // Tap the back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // The sheet should appear
    expect(find.text('Unsaved Changes'), findsOneWidget);

    // Tap Save on the bottom sheet
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    // Sheet is gone and screen is popped
    expect(find.text('Unsaved Changes'), findsNothing);
    expect(find.byType(EditRoutineScreen), findsNothing);

    // Verify it WAS saved to DB
    final routines = await WorkoutLocalDataSource.instance.getAllRoutines();
    expect(routines.length, 1);
    expect(routines.first.name, 'My Awesome Routine');
  });
}
