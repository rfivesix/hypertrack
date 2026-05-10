// lib/screens/scanner_screen.dart

import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

/// A screen that utilizes the device camera to scan barcodes for product identification.
///
/// Uses the `flutter_zxing` package (FLOSS-compatible) to detect barcodes and
/// returns the first successfully scanned code to the calling screen.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isDone = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          l10n.scann_barcode_capslock,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: ReaderWidget(
        onScan: (Code result) {
          if (!_isDone && result.isValid && result.text != null) {
            setState(() {
              _isDone = true;
            });
            Navigator.of(context).pop(result.text);
          }
        },
        showFlashlight: true,
        showGallery: false,
        showToggleCamera: false,
        showScannerOverlay: true,
        cropPercent: 0.6, // Balanced crop for barcodes
        scanDelay: const Duration(milliseconds: 500),
      ),
    );
  }
}
