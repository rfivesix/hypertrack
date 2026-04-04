// lib/screens/ai_meal_capture_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../generated/app_localizations.dart';
import '../services/ai_service.dart';
import '../widgets/global_app_bar.dart';
import 'ai_meal_review_screen.dart';
import 'ai_settings_screen.dart';

/// Screen for capturing meal input via photo(s), voice, or text before AI analysis.
///
/// Minimalist design — AI gradient is concentrated only on the primary
/// "Analyze" CTA button. All other UI elements use standard theme colours.
class AiMealCaptureScreen extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialMealType;

  const AiMealCaptureScreen({
    super.key,
    this.initialDate,
    this.initialMealType,
  });

  @override
  State<AiMealCaptureScreen> createState() => _AiMealCaptureScreenState();
}

class _AiMealCaptureScreenState extends State<AiMealCaptureScreen>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Photo state
  final List<File> _images = [];
  static const int _maxImages = 4;

  // Voice state
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _initialTextBeforeSpeech = '';
  String? _speechLocaleId;
  static const String _speechStartFailedMessage =
      'Sprachaufnahme konnte nicht gestartet werden. Bitte Mikrofonberechtigung prüfen und erneut versuchen.';

  // Analysis state
  bool _isAnalyzing = false;

  // Single animation controller for pulse (mic) and shimmer (button loading)
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (e) {
        debugPrint('speech_to_text error: ${e.errorMsg}');
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        debugPrint('speech_to_text status: $status');
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      options: Platform.isAndroid
          ? <stt.SpeechConfigOption>[stt.SpeechToText.androidNoBluetooth]
          : null,
    );
    if (available) {
      // Cache the best matching locale for the app language
      final appLang =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      final locales = await _speech.locales();
      final match =
          locales.where((l) => l.localeId.startsWith(appLang)).firstOrNull;
      _speechLocaleId = match?.localeId;
      debugPrint(
        'speech_to_text: available=true, localeId=$_speechLocaleId, all=${locales.map((l) => l.localeId).toList()}',
      );
    }
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<bool> _ensureSpeechAvailable() async {
    if (_speechAvailable) return true;
    await _initSpeech();
    return _speechAvailable;
  }

  void _showSpeechSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _showSpeechUnavailableFeedback() async {
    final hasPermission = await _speech.hasPermission;
    final message = hasPermission
        ? (Platform.isAndroid
            ? 'Spracherkennung auf diesem Android-Gerät aktuell nicht verfügbar.'
            : 'Spracherkennung ist auf diesem iOS-Gerät aktuell nicht verfügbar.')
        : (Platform.isAndroid
            ? 'Mikrofonzugriff verweigert. Bitte Mikrofon in den Android-Einstellungen erlauben.'
            : 'Mikrofonzugriff verweigert. Bitte Mikrofon in den iOS-Einstellungen erlauben.');
    _showSpeechSnackBar(message);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Photo actions
  // ---------------------------------------------------------------------------

  Future<void> _takePhoto() async {
    if (_images.length >= _maxImages) return;
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (photo != null && mounted) {
      setState(() => _images.add(File(photo.path)));
    }
  }

  Future<void> _pickFromGallery() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) return;

    final List<XFile> picked = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked.isNotEmpty && mounted) {
      setState(() {
        _images.addAll(picked.take(remaining).map((x) => File(x.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  // ---------------------------------------------------------------------------
  // Voice actions
  // ---------------------------------------------------------------------------

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      final available = await _ensureSpeechAvailable();
      if (!available) {
        await _showSpeechUnavailableFeedback();
        return;
      }

      _initialTextBeforeSpeech = _textController.text;
      try {
        final started = await _speech.listen(
          onResult: (result) {
            debugPrint(
              'speech_to_text result: ${result.recognizedWords} (final=${result.finalResult})',
            );
            if (mounted) {
              setState(() {
                final separator = _initialTextBeforeSpeech.endsWith(' ') ||
                        _initialTextBeforeSpeech.isEmpty
                    ? ''
                    : ' ';
                _textController.text =
                    '$_initialTextBeforeSpeech$separator${result.recognizedWords}'
                        .trimLeft();
                _textController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _textController.text.length),
                );
              });
            }
          },
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 10),
          localeId: _speechLocaleId,
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            cancelOnError: false,
            listenMode: stt.ListenMode.dictation,
          ),
        );

        if (!started) {
          if (mounted) setState(() => _isListening = false);
          _showSpeechSnackBar(_speechStartFailedMessage);
          return;
        }

        if (mounted) setState(() => _isListening = true);
      } catch (e) {
        debugPrint('speech_to_text listen failed: $e');
        if (mounted) setState(() => _isListening = false);
        _showSpeechSnackBar(_speechStartFailedMessage);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Analysis
  // ---------------------------------------------------------------------------

  bool get _hasInput =>
      _images.isNotEmpty || _textController.text.trim().isNotEmpty;

  Future<void> _analyze() async {
    if (!_hasInput) return;
    setState(() => _isAnalyzing = true);

    // Pass the current app language so the AI returns localised food names
    final languageCode = Localizations.localeOf(context).languageCode;

    try {
      List<AiSuggestedItem> results;
      final text = _textController.text.trim();

      if (_images.isNotEmpty) {
        results = await AiService.instance.analyzeImages(
          _images,
          textHint: text.isNotEmpty ? text : null,
          languageCode: languageCode,
        );
      } else {
        results = await AiService.instance.analyzeText(
          text,
          languageCode: languageCode,
        );
      }

      if (!mounted) return;

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AiMealReviewScreen(
            suggestions: results,
            originalImages: _images,
            initialDate: widget.initialDate,
            initialMealType: widget.initialMealType,
          ),
        ),
      );
      if (saved == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } on AiKeyMissingException {
      if (!mounted) return;
      _showKeyMissingDialog();
    } on AiServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showKeyMissingDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Key Required'),
        content: Text(l10n.aiErrorNoKey),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
              );
            },
            child: Text(l10n.aiSettingsTitle),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: GlobalAppBar(title: l10n.aiCaptureTitle),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_images.isNotEmpty) ...[
                    _buildUnifiedPhotoList(theme),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),

          // Unified Input Area
          _buildUnifiedInputArea(l10n, theme, isDark),

          // Analyze button — AI gradient CTA with inline loading
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: _AiAnalyzeButton(
              onPressed: (_hasInput && !_isAnalyzing) ? _analyze : null,
              isAnalyzing: _isAnalyzing,
              l10n: l10n,
              pulseController: _pulseController,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content: Unified View Widgets
  // ---------------------------------------------------------------------------

  Widget _buildUnifiedPhotoList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) => _buildPhotoThumbnail(i, theme),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_images.length} / $_maxImages',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(int index, ThemeData theme) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _images[index],
              width: 140,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedInputArea(
    AppLocalizations l10n,
    ThemeData theme,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            maxLines: 4,
            minLines: 1,
            onChanged: (_) => setState(() {}),
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: l10n.aiCaptureTextHint,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _images.length < _maxImages ? _takePhoto : null,
                icon: const Icon(Icons.camera_alt_rounded),
                color: theme.colorScheme.primary,
                tooltip: l10n.aiCaptureTabPhoto,
              ),
              IconButton(
                onPressed:
                    _images.length < _maxImages ? _pickFromGallery : null,
                icon: const Icon(Icons.photo_library_rounded),
                color: theme.colorScheme.primary,
                tooltip: l10n.tabFavorites,
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale =
                      _isListening ? 1.0 + (_pulseController.value * 0.1) : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: _isListening
                            ? theme.colorScheme.errorContainer
                            : theme.colorScheme.primaryContainer,
                      ),
                      onPressed: _toggleListening,
                      icon: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: _isListening
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// AI Analyze button — gradient CTA with inline animated shimmer loading
// =============================================================================

/// The AI gradient colours used for the analyze button and entry-point accents.
const _aiGradientColors = [
  Color(0xFFE88DCC),
  Color(0xFFF4A77A),
  Color(0xFFF7D06B),
  Color(0xFF7DDEAE),
  Color(0xFF6DC8D9),
];

class _AiAnalyzeButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isAnalyzing;
  final AppLocalizations l10n;
  final AnimationController pulseController;

  const _AiAnalyzeButton({
    required this.onPressed,
    required this.isAnalyzing,
    required this.l10n,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || isAnalyzing;
    final theme = Theme.of(context);

    // Base button content (icon + text)
    final buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isAnalyzing)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        else
          Icon(
            Icons.auto_awesome_rounded,
            size: 24,
            color: enabled ? Colors.white : theme.colorScheme.onSurfaceVariant,
          ),
        const SizedBox(width: 10),
        Text(
          isAnalyzing ? l10n.aiAnalyzing : l10n.aiAnalyzeButton,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: enabled ? Colors.white : theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );

    if (!enabled) {
      // Disabled state — flat, no gradient
      return GestureDetector(
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: buttonContent,
        ),
      );
    }

    // Enabled / analysing — gradient background with text on top via Stack
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (context, _) {
          final t = pulseController.value;

          return Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isAnalyzing
                  ? LinearGradient(
                      begin: Alignment(-1.0 + (t * 4.0), 0),
                      end: Alignment(1.0 + (t * 4.0), 0),
                      colors: const [
                        Color(0xFFE88DCC),
                        Color(0xFFF4A77A),
                        Color(0xFFF7D06B),
                        Color(0xFF7DDEAE),
                        Color(0xFF6DC8D9),
                        Color(0xFFE88DCC),
                      ],
                      tileMode: TileMode.repeated,
                    )
                  : const LinearGradient(
                      colors: _aiGradientColors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE88DCC).withValues(alpha: 0.30),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: buttonContent,
          );
        },
      ),
    );
  }
}
