// lib/util/unit_convert.dart
/// Converts a [value] between different units like 'g' to 'mg' or 'ml' to 'l'.
double convert(double value, String from, String to) {
  if (from == to) return value;
  if (from == 'g' && to == 'mg') return value * 1000.0;
  if (from == 'mg' && to == 'g') return value / 1000.0;
  if (from == 'l' && to == 'ml') return value * 1000.0;
  if (from == 'ml' && to == 'l') return value / 1000.0;
  // no conversion otherwise
  return value;
}

// Recommended list of allowed units:
const allowedUnits = <String>['mg', 'g', 'IU', 'ml', 'l'];
