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

    test('coalesces identical in-flight diary loads without queuing by default',
        () {
      final coordinator = DiaryLoadCoordinator();
      final day = DateTime(2026, 5, 4, 9);

      coordinator.markInFlight(day);

      expect(
        coordinator.coalesceIfInFlight(
          DateTime(2026, 5, 4, 21),
          forceStepsRefresh: false,
          queueIfInFlight: false,
        ),
        isTrue,
      );
      expect(coordinator.hasPendingReload, isFalse);
    });

    test('queues one same-day reload after water mutation during refresh', () {
      final coordinator = DiaryLoadCoordinator();
      final day = DateTime(2026, 5, 4, 9);

      coordinator.markInFlight(day);

      expect(
        coordinator.coalesceIfInFlight(
          DateTime(2026, 5, 4, 21),
          forceStepsRefresh: false,
          queueIfInFlight: true,
        ),
        isTrue,
      );
      expect(coordinator.hasPendingReload, isTrue);
      expect(coordinator.pendingForceStepsRefresh, isFalse);

      coordinator.clearPendingReload();
      expect(coordinator.hasPendingReload, isFalse);
    });

    test('keeps forced refresh intent when coalescing an in-flight load', () {
      final coordinator = DiaryLoadCoordinator();
      final day = DateTime(2026, 5, 4, 9);

      coordinator.markInFlight(day);

      coordinator.coalesceIfInFlight(
        day,
        forceStepsRefresh: true,
        queueIfInFlight: false,
      );

      expect(coordinator.hasPendingReload, isTrue);
      expect(coordinator.pendingForceStepsRefresh, isTrue);
    });

    test('does not coalesce a different selected diary date', () {
      final coordinator = DiaryLoadCoordinator();
      final first = DateTime(2026, 5, 4, 9);
      final second = DateTime(2026, 5, 5, 9);

      coordinator.markInFlight(first);

      expect(
        coordinator.coalesceIfInFlight(
          second,
          forceStepsRefresh: false,
          queueIfInFlight: true,
        ),
        isFalse,
      );
      expect(coordinator.hasPendingReload, isFalse);
    });
  });
}
