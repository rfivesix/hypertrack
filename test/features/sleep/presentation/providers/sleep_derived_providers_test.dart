import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/sleep/data/repository/sleep_query_repository.dart';
import 'package:train_libre/features/sleep/domain/derived/nightly_sleep_analysis.dart';
import 'package:train_libre/features/sleep/domain/sleep_enums.dart';
import 'package:train_libre/features/sleep/presentation/providers/sleep_derived_providers.dart';

class FakeSleepQueryRepository implements SleepQueryRepository {
  NightlySleepAnalysis? mockAnalysis;
  List<NightlySleepAnalysis> mockAnalysesInRange = [];
  bool throwError = false;

  DateTime? lastQueryDay;
  DateTime? lastQueryFrom;
  DateTime? lastQueryTo;

  @override
  Future<NightlySleepAnalysis?> getNightlyAnalysisByDate(DateTime day) async {
    lastQueryDay = day;
    if (throwError) throw Exception('Query error');
    return mockAnalysis;
  }

  @override
  Future<List<NightlySleepAnalysis>> getAnalysesInRange({
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) async {
    lastQueryFrom = fromInclusive;
    lastQueryTo = toInclusive;
    if (throwError) throw Exception('Query range error');
    return mockAnalysesInRange;
  }
}

void main() {
  group('SleepDerivedProvider Unit Tests', () {
    late FakeSleepQueryRepository mockRepository;
    late SleepDerivedProvider provider;

    setUp(() {
      mockRepository = FakeSleepQueryRepository();
      provider = SleepDerivedProvider(mockRepository);
    });

    NightlySleepAnalysis createMockAnalysis(DateTime date) {
      return NightlySleepAnalysis(
        id: 'analysis-1',
        sessionId: 'session-1',
        nightDate: date,
        analysisVersion: 'v1',
        normalizationVersion: 'n1',
        analyzedAtUtc: date.toUtc(),
        score: 80,
        sleepQuality: SleepQualityBucket.good,
      );
    }

    test('initial states are loading == false and empty', () {
      expect(provider.day.isLoading, isFalse);
      expect(provider.day.analysis, isNull);
      expect(provider.day.errorMessage, isNull);

      expect(provider.week.isLoading, isFalse);
      expect(provider.week.items, isEmpty);
      expect(provider.week.errorMessage, isNull);

      expect(provider.month.isLoading, isFalse);
      expect(provider.month.items, isEmpty);
      expect(provider.month.errorMessage, isNull);
    });

    group('loadDay', () {
      test('successfully loads day and updates state', () async {
        final date = DateTime(2026, 6, 15);
        final mockAnalysis = createMockAnalysis(date);
        mockRepository.mockAnalysis = mockAnalysis;

        final future = provider.loadDay(date);

        // Verify intermediate loading state
        expect(provider.day.isLoading, isTrue);
        expect(provider.day.analysis, isNull);
        expect(provider.day.errorMessage, isNull);

        await future;

        expect(provider.day.isLoading, isFalse);
        expect(provider.day.analysis, mockAnalysis);
        expect(provider.day.errorMessage, isNull);
        expect(mockRepository.lastQueryDay, date);
      });

      test('handles exception and populates day error message', () async {
        final date = DateTime(2026, 6, 15);
        mockRepository.throwError = true;

        await provider.loadDay(date);

        expect(provider.day.isLoading, isFalse);
        expect(provider.day.analysis, isNull);
        expect(provider.day.errorMessage, 'Failed to load sleep day.');
      });
    });

    group('loadWeek', () {
      test('correctly calculates week boundaries (Monday to Sunday) and loads successfully', () async {
        // Wednesday, June 17, 2026
        final anchor = DateTime(2026, 6, 17);
        // Expect Monday June 15 to Sunday June 21
        final expectedStart = DateTime(2026, 6, 15);
        final expectedEnd = DateTime(2026, 6, 21);

        final mockAnalyses = [createMockAnalysis(expectedStart)];
        mockRepository.mockAnalysesInRange = mockAnalyses;

        final future = provider.loadWeek(anchor);

        // Verify intermediate loading state
        expect(provider.week.isLoading, isTrue);
        expect(provider.week.items, isEmpty);

        await future;

        expect(provider.week.isLoading, isFalse);
        expect(provider.week.items, mockAnalyses);
        expect(provider.week.errorMessage, isNull);

        expect(mockRepository.lastQueryFrom, expectedStart);
        expect(mockRepository.lastQueryTo, expectedEnd);
      });

      test('handles loadWeek errors and populates week error message', () async {
        final anchor = DateTime(2026, 6, 17);
        mockRepository.throwError = true;

        await provider.loadWeek(anchor);

        expect(provider.week.isLoading, isFalse);
        expect(provider.week.items, isEmpty);
        expect(provider.week.errorMessage, 'Failed to load sleep week.');
      });
    });

    group('loadMonth', () {
      test('correctly calculates month boundaries and loads successfully', () async {
        // June 15, 2026
        final anchor = DateTime(2026, 6, 15);
        final expectedStart = DateTime(2026, 6, 1);
        final expectedEnd = DateTime(2026, 7, 0); // Last day of June is June 30

        final mockAnalyses = [createMockAnalysis(anchor)];
        mockRepository.mockAnalysesInRange = mockAnalyses;

        final future = provider.loadMonth(anchor);

        // Verify intermediate loading state
        expect(provider.month.isLoading, isTrue);
        expect(provider.month.items, isEmpty);

        await future;

        expect(provider.month.isLoading, isFalse);
        expect(provider.month.items, mockAnalyses);
        expect(provider.month.errorMessage, isNull);

        expect(mockRepository.lastQueryFrom, expectedStart);
        expect(mockRepository.lastQueryTo, expectedEnd);
      });

      test('handles loadMonth errors and populates month error message', () async {
        final anchor = DateTime(2026, 6, 15);
        mockRepository.throwError = true;

        await provider.loadMonth(anchor);

        expect(provider.month.isLoading, isFalse);
        expect(provider.month.items, isEmpty);
        expect(provider.month.errorMessage, 'Failed to load sleep month.');
      });
    });
  });
}
