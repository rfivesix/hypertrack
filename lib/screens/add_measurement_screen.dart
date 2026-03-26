// lib/screens/add_measurement_screen.dart (Final & De-Materialisiert - Korrigiert)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/measurement.dart';
import '../models/measurement_session.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart'; // HINZUGEFÜGT

/// A screen for recording new body measurements.
///
/// Provides input fields for various metrics (weight, fat percentage, circumferences)
/// and allows users to set the specific date and time for the measurement session.
class AddMeasurementScreen extends StatefulWidget {
  /// The initial date to be selected in the picker.
  final DateTime? initialDate;
  const AddMeasurementScreen({super.key, this.initialDate});

  @override
  State<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends State<AddMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  late DateTime _selectedDateTime;

  final Map<String, String> _measurementTypes = {
    'weight': 'kg',
    'fat_percent': '%',
    'waist': 'cm',
    'abdomen': 'cm',
    'hips': 'cm',
    'neck': 'cm',
    'shoulder': 'cm',
    'chest': 'cm',
    'left_bicep': 'cm',
    'right_bicep': 'cm',
    'left_forearm': 'cm',
    'right_forearm': 'cm',
    'left_thigh': 'cm',
    'right_thigh': 'cm',
    'left_calf': 'cm',
    'right_calf': 'cm',
  };

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDate ?? DateTime.now();
    for (var key in _measurementTypes.keys) {
      _controllers[key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _saveSession() async {
    final List<Measurement> measurements = [];
    _controllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        final value = double.tryParse(controller.text.replaceAll(',', '.'));
        if (value != null) {
          measurements.add(
            Measurement(
              sessionId: 0,
              type: key,
              value: value,
              unit: _measurementTypes[key]!,
            ),
          );
        }
      }
    });

    if (measurements.isNotEmpty) {
      final session = MeasurementSession(
        timestamp: _selectedDateTime,
        measurements: measurements,
      );
      await DatabaseHelper.instance.insertMeasurementSession(session);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) Navigator.of(context).pop(false);
    }
  }

  String _getLocalizedMeasurementName(String key, AppLocalizations l10n) {
    switch (key) {
      case 'weight':
        return l10n.measurementWeight;
      case 'fat_percent':
        return l10n.measurementFatPercent;
      case 'neck':
        return l10n.measurementNeck;
      case 'shoulder':
        return l10n.measurementShoulder;
      case 'chest':
        return l10n.measurementChest;
      case 'left_bicep':
        return l10n.measurementLeftBicep;
      case 'right_bicep':
        return l10n.measurementRightBicep;
      case 'left_forearm':
        return l10n.measurementLeftForearm;
      case 'right_forearm':
        return l10n.measurementRightForearm;
      case 'abdomen':
        return l10n.measurementAbdomen;
      case 'waist':
        return l10n.measurementWaist;
      case 'hips':
        return l10n.measurementHips;
      case 'left_thigh':
        return l10n.measurementLeftThigh;
      case 'right_thigh':
        return l10n.measurementRightThigh;
      case 'left_calf':
        return l10n.measurementLeftCalf;
      case 'right_calf':
        return l10n.measurementRightCalf;
      default:
        return key;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateTime) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    final formattedDate = DateFormat('dd.MM.yyyy').format(_selectedDateTime);
    final formattedTime = DateFormat.Hm().format(_selectedDateTime);
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        title: l10n.addMeasurementDialogTitle, // or whatever your l10n key is

        actions: [
          TextButton(
            onPressed: _saveSession,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: DesignConstants.cardPadding.copyWith(
          top: DesignConstants.cardPadding.top + topPadding,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datum & Uhrzeit Sektion
              Text(
                l10n.date_and_time_of_measurement,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: DesignConstants.spacingS),
              SummaryCard(
                // KORREKTUR 2: Datum/Uhrzeit in SummaryCard
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: _selectDate,
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _selectTime,
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              formattedTime,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: DesignConstants.spacingXL,
              ), // KORREKTUR 3: Abstand angepasst
              // Messwerte-Sektion
              Text(l10n.drawerMeasurements, style: textTheme.titleMedium),
              const SizedBox(height: DesignConstants.spacingS),
              ..._measurementTypes.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12.0,
                  ), // KORREKTUR 4: Padding angepasst
                  child: TextFormField(
                    controller: _controllers[key],
                    decoration: InputDecoration(
                      labelText: _getLocalizedMeasurementName(key, l10n),
                      suffixText: _measurementTypes[key],
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      // Nur validieren, wenn etwas eingegeben wurde
                      if (value != null &&
                          value.isNotEmpty &&
                          double.tryParse(value.replaceAll(',', '.')) == null) {
                        return l10n.validatorPleaseEnterNumber;
                      }
                      return null;
                    },
                  ),
                );
              }),
              const SizedBox(
                height: DesignConstants.spacingL,
              ), // Abstand zum Ende
            ],
          ),
        ),
      ),
    );
  }
}
