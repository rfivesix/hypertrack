// lib/util/time_util.dart

/// Formats a [Duration] into a string like "HH:MM:SS" or "MM:SS".
String formatDuration(Duration d) {
  // .abs() ensures we do not show negative values
  // if small time inconsistencies occur.
  d = d.abs();

  var seconds = d.inSeconds;
  final hours = seconds ~/ Duration.secondsPerHour;
  seconds -= hours * Duration.secondsPerHour;
  final minutes = seconds ~/ Duration.secondsPerMinute;
  seconds -= minutes * Duration.secondsPerMinute;

  final hoursString = hours > 0 ? '${hours.toString()}:' : '';
  final minutesString = minutes.toString().padLeft(2, '0');
  final secondsString = seconds.toString().padLeft(2, '0');

  return '$hoursString$minutesString:$secondsString';
}
