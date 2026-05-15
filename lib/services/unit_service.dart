import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UnitSystem { metric, imperial }

enum UnitDimension { weight, height, liquid }

/// Centralizes the user's preferred unit system and conversions.
class UnitService extends ChangeNotifier {
  static const String _unitSystemKey = 'unit_system';

  UnitSystem _unitSystem = UnitSystem.metric;

  UnitService() {
    _loadUnitSystem();
  }

  UnitSystem get unitSystem => _unitSystem;

  bool get isMetric => _unitSystem == UnitSystem.metric;

  bool get isImperial => _unitSystem == UnitSystem.imperial;

  Future<void> _loadUnitSystem() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getString(_unitSystemKey);
    final loadedSystem = storedValue == UnitSystem.imperial.name
        ? UnitSystem.imperial
        : UnitSystem.metric;
    if (_unitSystem == loadedSystem) return;
    _unitSystem = loadedSystem;
    notifyListeners();
  }

  Future<void> setUnitSystem(UnitSystem value) async {
    if (value == _unitSystem) return;
    _unitSystem = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitSystemKey, value.name);
  }

  Future<void> toggleUnitSystem() {
    return setUnitSystem(isMetric ? UnitSystem.imperial : UnitSystem.metric);
  }

  double convertDisplayValue(double metricValue, UnitDimension dimension) {
    return switch (dimension) {
      UnitDimension.weight => isMetric ? metricValue : kgToLbs(metricValue),
      UnitDimension.height => isMetric ? metricValue : cmToInches(metricValue),
      UnitDimension.liquid =>
        isMetric ? metricValue : mlToFluidOunces(metricValue),
    };
  }

  double convertToMetric(double displayValue, UnitDimension dimension) {
    return switch (dimension) {
      UnitDimension.weight => isMetric ? displayValue : lbsToKg(displayValue),
      UnitDimension.height =>
        isMetric ? displayValue : inchesToCm(displayValue),
      UnitDimension.liquid =>
        isMetric ? displayValue : fluidOuncesToMl(displayValue),
    };
  }

  String suffixFor(UnitDimension dimension) {
    return switch (dimension) {
      UnitDimension.weight => isMetric ? 'kg' : 'lbs',
      UnitDimension.height => isMetric ? 'cm' : 'in',
      UnitDimension.liquid => isMetric ? 'ml' : 'fl oz',
    };
  }

  String metricSuffixFor(UnitDimension dimension) {
    return switch (dimension) {
      UnitDimension.weight => 'kg',
      UnitDimension.height => 'cm',
      UnitDimension.liquid => 'ml',
    };
  }

  static double kgToLbs(double value) => value * 2.20462;

  static double lbsToKg(double value) => value / 2.20462;

  static double cmToInches(double value) => value * 0.393701;

  static double inchesToCm(double value) => value / 0.393701;

  static double mlToFluidOunces(double value) => value * 0.033814;

  static double fluidOuncesToMl(double value) => value / 0.033814;
}
