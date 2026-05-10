// lib/screens/scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../generated/app_localizations.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'dart:developer' as developer;
import '../services/haptic_feedback_service.dart';

/// A screen that utilizes the device camera to scan barcodes for product identification.
///
/// Uses the `flutter_zxing` package (FLOSS-compatible) to detect barcodes and
/// returns the first successfully scanned code to the calling screen.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  bool _isDone = false;
  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission(initial: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permission if returning from settings or another app
      _checkPermission();
    }
  }

  Future<void> _checkPermission({bool initial = false}) async {
    final status = await Permission.camera.status;
    if (mounted) {
      setState(() {
        _cameraPermissionStatus = status;
        if (initial) {
          _isCheckingPermission = false;
        }
      });
    }

    if (status.isDenied && !initial) {
      final result = await Permission.camera.request();
      if (mounted) {
        setState(() {
          _cameraPermissionStatus = result;
        });
      }
    }
  }

  void _openSettings() async {
    await openAppSettings();
  }

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
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isCheckingPermission) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cameraPermissionStatus.isGranted) {
      return ReaderWidget(
        onScan: (Code result) {
          if (result.isValid && result.text != null) {
            developer
                .log('Barcode detected: ${result.text} (${result.format})');
            if (!_isDone) {
              // Trigger haptic feedback if enabled in settings
              HapticFeedbackService.instance.confirmationFeedback();
              setState(() {
                _isDone = true;
              });
              Navigator.of(context).pop(result.text);
            }
          }
        },
        onControllerCreated: (controller, error) {
          if (error != null) {
            developer.log('Scanner controller error: $error', error: error);
          }
        },
        codeFormat: Format.any,
        showFlashlight: false, // Hidden to match app design
        showGallery: false,
        showToggleCamera: false,
        showScannerOverlay: true,
        // Using tryHarder and tryRotate to improve detection reliability
        // for standard barcodes like EAN-13, EAN-8, UPC-A, UPC-E.
        tryHarder: true,
        tryRotate: true,
        // Increased cropPercent for better reliability with EAN barcodes
        // which are often wider and need more context.
        cropPercent: 0.8,
        // Reduced delay for a faster, "snappier" detection feel
        scanDelay: const Duration(milliseconds: 200),
        // Balanced resolution for faster processing in the ZXing engine
        resolution: ResolutionPreset.ultraHigh,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _cameraPermissionStatus.isPermanentlyDenied
                  ? l10n.scannerPermissionPermanentlyDenied
                  : l10n.scannerPermissionRequired,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cameraPermissionStatus.isPermanentlyDenied
                  ? _openSettings
                  : _checkPermission,
              child: Text(
                _cameraPermissionStatus.isPermanentlyDenied
                    ? l10n.scannerOpenSettings
                    : l10n.scannerGrantPermission,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
