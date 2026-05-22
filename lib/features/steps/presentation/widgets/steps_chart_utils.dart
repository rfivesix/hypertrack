

const double chartTopInset = 8;
const double chartBottomInset = 28;
const double chartLeftInset = 30;
const double weekChartTopInset = 36;

String compactAxisLabel(int value) {
  if (value >= 10000) {
    return '${(value / 1000).round()}k';
  }
  if (value >= 1000) {
    final short = (value / 1000).toStringAsFixed(1);
    return short.endsWith('.0')
        ? '${short.substring(0, short.length - 2)}k'
        : '${short}k';
  }
  return value.toString();
}
