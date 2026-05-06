import 'package:flutter/foundation.dart';

class PerfDebugTimer {
  const PerfDebugTimer._();

  static const int _dbLogThresholdMs = 16;
  static const int _dbRowThreshold = 100;

  static Future<T> time<T>({
    required String area,
    required String label,
    required Future<T> Function() action,
    String? metric,
    Map<String, Object?> fields = const {},
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await action();
    } finally {
      stopwatch.stop();
      logDuration(
        area: area,
        label: label,
        elapsed: stopwatch.elapsed,
        metric: metric,
        fields: fields,
      );
    }
  }

  static void logDuration({
    required String area,
    required String label,
    required Duration elapsed,
    String? metric,
    Map<String, Object?> fields = const {},
  }) {
    if (!kDebugMode) return;
    if (!_shouldLog(area: area, elapsed: elapsed, fields: fields)) return;

    final buffer = StringBuffer('[perf][$area] ');
    if (metric == null) {
      buffer.write('$label=${elapsed.inMilliseconds}ms');
    } else {
      buffer.write('$label $metric=${elapsed.inMilliseconds}ms');
    }

    for (final entry in fields.entries) {
      final value = entry.value;
      if (value == null) continue;
      buffer.write(' ${entry.key}=$value');
    }

    debugPrint(buffer.toString());
  }

  static bool _shouldLog({
    required String area,
    required Duration elapsed,
    required Map<String, Object?> fields,
  }) {
    if (area != 'db') return true;
    if (elapsed.inMilliseconds >= _dbLogThresholdMs) return true;
    return fields.values
        .any((value) => value is num && value >= _dbRowThreshold);
  }
}
