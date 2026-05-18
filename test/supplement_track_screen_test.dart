import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/supplements/presentation/supplement_track_screen.dart';

void main() {
  group('resolveSupplementTrackLogTimestamp', () {
    test('uses current time for today', () {
      final now = DateTime(2026, 5, 14, 16, 42, 17);

      expect(
        resolveSupplementTrackLogTimestamp(
          selectedDate: DateTime(2026, 5, 14),
          now: now,
        ),
        now,
      );
    });

    test('keeps selected day while defaulting to current hour and minute', () {
      final now = DateTime(2026, 5, 14, 16, 42, 17);

      expect(
        resolveSupplementTrackLogTimestamp(
          selectedDate: DateTime(2026, 5, 10),
          now: now,
        ),
        DateTime(2026, 5, 10, 16, 42),
      );
    });
  });
}
