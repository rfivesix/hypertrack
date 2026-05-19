import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart' hide SupplementLog, Supplement;
import 'package:train_libre/features/supplements/data/sources/supplement_local_data_source.dart';
import 'package:train_libre/features/supplements/data/supplement_repository_impl.dart';
import 'package:train_libre/features/supplements/domain/models/supplement.dart';
import 'package:train_libre/features/supplements/domain/models/supplement_log.dart';
import 'package:train_libre/features/supplements/domain/repositories/supplement_repository.dart';
import 'package:train_libre/features/supplements/presentation/supplements_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reactive Supplements Module Migration Pass', () {
    late AppDatabase database;
    late SupplementLocalDataSource localDataSource;
    late SupplementRepository repository;
    late SupplementsViewModel viewModel;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      localDataSource = SupplementLocalDataSource(database);
      repository = SupplementRepositoryImpl(localDataSource: localDataSource);
      viewModel = SupplementsViewModel(repository: repository);
      await localDataSource.ensureStandardSupplements();
    });

    tearDown(() async {
      viewModel.dispose();
      await database.close();
    });

    test('SupplementLocalDataSource.watchAllSupplements propagates updates reactively', () async {
      // 1. Establish the stream expectation
      final stream = localDataSource.watchAllSupplements();

      // Creatine, Protein, Caffeine are standard supplements
      expectLater(
        stream,
        emitsInOrder([
          hasLength(3), // Initial empty/standard
          hasLength(4), // Emitted after we insert Vitamin D
        ]),
      );

      // 2. Perform insert
      await localDataSource.insertSupplement(
        Supplement(
          name: 'Vitamin D',
          defaultDose: 1000.0,
          unit: 'IU',
          isTracked: true,
        ),
      );
    });

    test('SupplementLocalDataSource.watchSupplementLogsForDate propagates writes reactively', () async {
      final date = DateTime(2026, 5, 19);
      final stream = localDataSource.watchSupplementLogsForDate(date);

      expectLater(
        stream,
        emitsInOrder([
          isEmpty, // Initial
          hasLength(1), // Emitted after logging a supplement dose
        ]),
      );

      final supplements = await localDataSource.getAllSupplements();
      final creatine = supplements.firstWhere((s) => s.name == 'Creatine');

      await localDataSource.insertSupplementLog(
        SupplementLog(
          supplementId: creatine.id!,
          dose: 5.0,
          unit: 'g',
          timestamp: date,
        ),
      );
    });

    test('SupplementsViewModel updates state automatically without manual loadData reload triggers', () async {
      final date = DateTime(2026, 5, 19);
      viewModel.setSelectedDate(date);

      // Wait for initial emissions to complete
      await Future.delayed(const Duration(milliseconds: 100));

      expect(viewModel.todaysLogs, isEmpty);

      final creatine = viewModel.supplementsById.values.firstWhere((s) => s.name == 'Creatine');

      // Log a dose on the view model - note this does NOT trigger manual loadData() in our reactive VM
      await viewModel.logSupplementDose(creatine, 5.0, date);

      // Give the reactive Drift stream a brief moment to push values to the listener
      await Future.delayed(const Duration(milliseconds: 100));

      expect(viewModel.todaysLogs, hasLength(1));
      expect(viewModel.todaysLogs.first.dose, 5.0);
      expect(viewModel.tracked.firstWhere((ts) => ts.supplement.name == 'Creatine').totalDosedToday, 5.0);
    });

    test('SupplementsViewModel subscription cleans up and updates cleanly on date selection switch', () async {
      final dateA = DateTime(2026, 5, 19);
      final dateB = DateTime(2026, 5, 20);

      viewModel.setSelectedDate(dateA);
      await Future.delayed(const Duration(milliseconds: 50));

      final creatine = viewModel.supplementsById.values.firstWhere((s) => s.name == 'Creatine');

      // Log dose on Date A
      await viewModel.logSupplementDose(creatine, 5.0, dateA);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(viewModel.todaysLogs, hasLength(1));

      // Navigate / switch to Date B
      viewModel.setSelectedDate(dateB);
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Should be empty for Date B
      expect(viewModel.todaysLogs, isEmpty);
    });
  });
}
