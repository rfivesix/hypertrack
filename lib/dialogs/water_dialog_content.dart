// lib/dialogs/water_dialog_content.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';

// ===== App-wide modal helpers (temporary location — can be moved to a shared file) =====

enum AppSheetStyle { plain, glass }

/// Unified show function for bottom sheets. Use this everywhere to keep styling consistent.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  AppSheetStyle style = AppSheetStyle.plain,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent, // let our scaffold draw the background
    builder: (ctx) => AppSheetScaffold(style: style, child: child),
  );
}

/// Provides a consistent modal surface with rounded corners, padding, and optional "liquid glass".
class AppSheetScaffold extends StatelessWidget {
  final Widget child;
  final AppSheetStyle style;

  const AppSheetScaffold({
    super.key,
    required this.child,
    this.style = AppSheetStyle.plain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget surface = Container(
      decoration: BoxDecoration(
        color: style == AppSheetStyle.glass
            ? Colors.white.withValues(alpha: 0.20)
            : theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: style == AppSheetStyle.glass
            ? Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1)
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(
        DesignConstants.spacingL,
        DesignConstants.spacingL,
        DesignConstants.spacingL,
        DesignConstants.spacingXL, // extra bottom padding for buttons
      ),
      child: child,
    );

    if (style == AppSheetStyle.glass) {
      surface = ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: surface,
        ),
      );
    }

    return SafeArea(top: false, child: surface);
  }
}

/// A specialized dialog content widget for water logging.
///
/// Focuses specifically on hydration tracking with a simplified UI
/// for entering milliliters and timestamp.
class WaterDialogContent extends StatefulWidget {
  final int? initialQuantity;
  final DateTime? initialTimestamp;

  const WaterDialogContent({
    super.key,
    this.initialQuantity,
    this.initialTimestamp,
  });
  @override
  WaterDialogContentState createState() => WaterDialogContentState();
}

class WaterDialogContentState extends State<WaterDialogContent> {
  late final TextEditingController _textController;
  late DateTime _selectedDateTime;
  late final l10n = AppLocalizations.of(context)!;

  String get quantityText => _textController.text;
  DateTime get selectedDateTime => _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.initialQuantity?.toString() ?? '',
    );
    _selectedDateTime = widget.initialTimestamp ?? DateTime.now();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
    final formattedDate = DateFormat('dd.MM.yyyy').format(_selectedDateTime);
    final formattedTime = DateFormat.Hm().format(_selectedDateTime);
    return AppSheetScaffold(
      // Toggle between plain and glass depending on your feature flag or setting.
      style: AppSheetStyle.plain, // or AppSheetStyle.glass
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.amount_in_milliliters,
              suffixText: 'ml',
            ),
            autofocus: true,
          ),
          const SizedBox(height: DesignConstants.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _selectDate,
                child: Padding(
                  padding: DesignConstants.cardMargin,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(formattedDate, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: _selectTime,
                child: Padding(
                  padding: DesignConstants.cardMargin,
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 8),
                      Text(formattedTime, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Example launcher for this dialog using the unified sheet
Future<void> openWaterDialog(
  BuildContext context, {
  int? initialQuantity,
  DateTime? initialTimestamp,
  AppSheetStyle style = AppSheetStyle.plain,
}) {
  return showAppBottomSheet(
    context,
    style: style,
    child: WaterDialogContent(
      initialQuantity: initialQuantity,
      initialTimestamp: initialTimestamp,
    ),
  );
}
