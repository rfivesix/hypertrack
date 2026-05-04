import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/screens/diary_screen.dart';
import 'package:train_libre/util/date_util.dart';

void main() {
  group('Diary date state', () {
    test('normalizes diary dates to local calendar days', () {
      final date = DateTime(2026, 5, 4, 23, 45, 12);

      expect(normalizeDiaryDate(date), DateTime(2026, 5, 4));
      expect(date.isSameDate(DateTime(2026, 5, 4, 1)), isTrue);
      expect(date.isSameDate(DateTime(2026, 5, 5)), isFalse);
    });

    test('uses provided initial date instead of today', () {
      final initial = DateTime(2026, 5, 3, 18, 30);
      final today = DateTime(2026, 5, 4, 9);

      expect(
        resolveDiaryInitialDate(initialDate: initial, now: today),
        DateTime(2026, 5, 3),
      );
    });

    test('defaults initial diary date to today when no date is provided', () {
      final today = DateTime(2026, 5, 4, 9);

      expect(
        resolveDiaryInitialDate(now: today),
        DateTime(2026, 5, 4),
      );
    });

    test('ignores stale diary loads after quick day switches', () {
      final coordinator = DiaryLoadCoordinator();
      final first = DateTime(2026, 5, 4, 23, 30);
      final second = DateTime(2026, 5, 5, 1, 15);

      final firstGeneration = coordinator.begin(first);
      final secondGeneration = coordinator.begin(second);

      expect(coordinator.isCurrent(firstGeneration, first), isFalse);
      expect(coordinator.isCurrent(firstGeneration, second), isFalse);
      expect(coordinator.isCurrent(secondGeneration, second), isTrue);
      expect(
        coordinator.isCurrent(secondGeneration, DateTime(2026, 5, 5, 20)),
        isTrue,
      );
    });
  });
}
