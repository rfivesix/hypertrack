import 'package:intl/intl.dart';

final _timeFormattingAnchorDate = DateTime(2020, 1, 1);

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

String formatBedtimeMinutes(int minutes) {
  final normalized = ((minutes % 1440) + 1440) % 1440;
  final hour = normalized ~/ 60;
  final minute = normalized % 60;
  return DateFormat('HH:mm').format(
    DateTime(
      _timeFormattingAnchorDate.year,
      _timeFormattingAnchorDate.month,
      _timeFormattingAnchorDate.day,
      hour,
      minute,
    ),
  );
}
