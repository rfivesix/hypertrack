// lib/services/ai_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Enums & Data Models
// ---------------------------------------------------------------------------

/// Supported AI providers for meal analysis.
enum AiProvider {
  openai,
  gemini,
  anthropic,
  mistral,
  xai,
}

/// Provider registry metadata.
class AiProviderMetadata {
  final AiProvider provider;
  final String displayName;
  final String keyHint;
  final String defaultModel;
  final List<String> rankingHints;
  final List<String> emergencyFallbackModels;
  final bool supportsVision;
  final bool supportsDynamicModelLoading;

  const AiProviderMetadata({
    required this.provider,
    required this.displayName,
    required this.keyHint,
    required this.defaultModel,
    required this.rankingHints,
    required this.emergencyFallbackModels,
    required this.supportsVision,
    required this.supportsDynamicModelLoading,
  });
}

/// Model option for settings selection.
class AiModelOption {
  final String id;
  final String label;
  final bool isFallback;

  const AiModelOption({
    required this.id,
    required this.label,
    this.isFallback = false,
  });
}

typedef DynamicModelIdsLoader = Future<Set<String>?> Function(
  AiProvider provider,
);
typedef AiHttpGet = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
});

/// A single food component suggested by the AI.
class AiSuggestedItem {
  /// Display name of the detected food component.
  String name;

  /// Estimated weight in grams.
  int estimatedGrams;

  /// Confidence score between 0.0 and 1.0.
  double confidence;

  /// Barcode of a matched product in the local database (filled after fuzzy matching).
  String? matchedBarcode;

  AiSuggestedItem({
    required this.name,
    required this.estimatedGrams,
    required this.confidence,
    this.matchedBarcode,
  });

  factory AiSuggestedItem.fromJson(Map<String, dynamic> json) {
    return AiSuggestedItem(
      name: json['name'] as String? ?? 'Unknown',
      estimatedGrams: (json['estimatedGrams'] as num?)?.toInt() ?? 100,
      confidence:
          (json['confidence'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'estimatedGrams': estimatedGrams,
        'confidence': confidence,
      };
}

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

/// Base exception for AI service errors.
sealed class AiServiceException implements Exception {
  final String message;
  const AiServiceException(this.message);
  @override
  String toString() => message;
}

class AiKeyMissingException extends AiServiceException {
  const AiKeyMissingException()
      : super('No API key configured for the selected provider.');
}

class AiAuthException extends AiServiceException {
  const AiAuthException([
    super.msg = 'Authentication failed. Please check your API key.',
  ]);
}

class AiNetworkException extends AiServiceException {
  const AiNetworkException([
    super.msg = 'Network error. Please check your connection.',
  ]);
}

class AiParseException extends AiServiceException {
  const AiParseException([super.msg = 'Could not parse the AI response.']);
}

class AiRateLimitException extends AiServiceException {
  const AiRateLimitException([
    super.msg = 'Rate limit exceeded. Please wait a moment.',
  ]);
}

class AiUnsupportedFeatureException extends AiServiceException {
  const AiUnsupportedFeatureException([super.msg = 'Feature not supported.']);
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Provider-agnostic AI service for meal analysis.
///
/// Uses a BYOK architecture with per-provider API keys stored in native
/// encrypted storage (Keychain / Keystore) via [FlutterSecureStorage].
class AiService {
  AiService._({
    FlutterSecureStorage? secureStorage,
    DynamicModelIdsLoader? dynamicModelIdsLoader,
    AiHttpGet? httpGet,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _dynamicModelIdsLoader = dynamicModelIdsLoader,
        _httpGet = httpGet ?? http.get;
  static final AiService instance = AiService._();

  @visibleForTesting
  factory AiService.forTesting({
    FlutterSecureStorage? secureStorage,
    DynamicModelIdsLoader? dynamicModelIdsLoader,
    AiHttpGet? httpGet,
  }) {
    return AiService._(
      secureStorage: secureStorage,
      dynamicModelIdsLoader: dynamicModelIdsLoader,
      httpGet: httpGet,
    );
  }

  final FlutterSecureStorage _secureStorage;
  final DynamicModelIdsLoader? _dynamicModelIdsLoader;
  final AiHttpGet _httpGet;

  // Secure storage keys per provider
  static const _keyPrefix = 'ai_api_key_';
  static const _providerKey = 'ai_selected_provider';
  static const _modelPrefix = 'ai_selected_model_';

  static const selectedProviderStorageKey = _providerKey;

  static String selectedModelStorageKeyFor(AiProvider provider) =>
      '$_modelPrefix${provider.name}';

  static String apiKeyStorageKeyFor(AiProvider provider) =>
      '$_keyPrefix${provider.name}';

  static const Map<AiProvider, AiProviderMetadata> _providerRegistry = {
    AiProvider.openai: AiProviderMetadata(
      provider: AiProvider.openai,
      displayName: 'OpenAI',
      keyHint: 'sk-...',
      defaultModel: 'gpt-5.4',
      rankingHints: [
        'gpt-5.4',
        'gpt-5.4-pro',
        'gpt-5.4-mini',
        'gpt-5.4-nano',
        'gpt-5-mini',
        'gpt-5',
        'gpt-4.1',
        'gpt-4o',
      ],
      emergencyFallbackModels: [
        'gpt-5.4',
        'gpt-5.4-mini',
        'gpt-4.1',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: true,
    ),
    AiProvider.gemini: AiProviderMetadata(
      provider: AiProvider.gemini,
      displayName: 'Google Gemini',
      keyHint: 'AIza...',
      defaultModel: 'gemini-pro-latest',
      rankingHints: [
        'gemini-pro-latest',
        'gemini-flash-latest',
        'gemini-flash-lite-latest',
        'gemini-2.5-pro',
        'gemini-2.5-flash',
      ],
      emergencyFallbackModels: [
        'gemini-pro-latest',
        'gemini-flash-latest',
        'gemini-2.5-flash',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: true,
    ),
    AiProvider.anthropic: AiProviderMetadata(
      provider: AiProvider.anthropic,
      displayName: 'Anthropic Claude',
      keyHint: 'sk-ant-...',
      defaultModel: 'claude-opus-4-6',
      rankingHints: [
        'claude-opus-4-6',
        'claude-sonnet-4-6',
        'claude-haiku-4-5',
      ],
      emergencyFallbackModels: [
        'claude-opus-4-6',
        'claude-sonnet-4-6',
        'claude-3-7-sonnet-latest',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: true,
    ),
    AiProvider.mistral: AiProviderMetadata(
      provider: AiProvider.mistral,
      displayName: 'Mistral',
      keyHint: 'mistral-...',
      defaultModel: 'mistral-large-3',
      rankingHints: [
        'mistral-large-3',
        'mistral-medium-3.1',
        'mistral-small-4',
        'pixtral-large-latest',
      ],
      emergencyFallbackModels: [
        'mistral-large-3',
        'mistral-medium-3.1',
        'pixtral-large-latest',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: true,
    ),
    AiProvider.xai: AiProviderMetadata(
      provider: AiProvider.xai,
      displayName: 'xAI Grok',
      keyHint: 'xai-...',
      defaultModel: 'grok-4.20-0309-reasoning',
      rankingHints: [
        'grok-4.20-0309-reasoning',
        'grok-4.20-0309-non-reasoning',
        'grok-4-1-fast-reasoning',
        'grok-4-1-fast-non-reasoning',
      ],
      emergencyFallbackModels: [
        'grok-4.20-0309-reasoning',
        'grok-4-1-fast-reasoning',
        'grok-2-vision-latest',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: true,
    ),
  };

  /// Builds the system prompt, optionally localised to [languageCode].
  static String _buildSystemPrompt({String? languageCode}) {
    final langRule = (languageCode != null && languageCode.isNotEmpty)
        ? '\n5. IMPORTANT: All food "name" values MUST be in the "$languageCode" language '
            '(e.g. use "Apfel" instead of "Apple" when language is "de"). '
            'Never mix languages.'
        : '';

    return '''
You are a nutrition analysis assistant. Analyze the provided meal image(s) or description.

CRITICAL RULES:
1. Break down EVERY meal into its individual, atomic, loggable food components.
   For example, "Cheeseburger with fries" must become: burger bun, beef patty, cheese slice, lettuce, tomato, ketchup, french fries — each as a separate item with its own estimated weight.
2. Do NOT return composite meal names. Always decompose into individual ingredients.
3. Estimate weights in grams as accurately as possible based on visual cues or typical serving sizes.
4. Set confidence between 0.0 and 1.0 based on how certain you are about each item and its quantity.
5. CONSOLIDATE duplicate items: if the user mentions or you detect multiple quantities of the same food (e.g. "4 eggs"), return ONE single entry with the total combined weight. Never return duplicate rows for the same food item.
6. Do NOT estimate, guess, or return any nutritional data (calories, protein, fat, carbs, etc.). Your job is ONLY to identify the food name and estimate the realistic total portion weight in grams. The app will look up nutritional values from its own database.
7. Use SIMPLE, SHORT base food names only. For example, use "Banane" not "Reife Banane", "Ei" not "Gekochtes Ei", "Apfel" not "Grüner Apfel". Keep names as generic and simple as possible to maximize database matching.$langRule

Respond ONLY with a valid JSON array. No markdown, no explanation, no extra text.
Each element must have exactly these fields:
- "name": string (individual food component name)
- "estimatedGrams": integer (estimated weight in grams)
- "confidence": number (0.0 to 1.0)

Example response:
[{"name": "Egg", "estimatedGrams": 240, "confidence": 0.9}, {"name": "Butter", "estimatedGrams": 10, "confidence": 0.7}]
''';
  }

  // ---------------------------------------------------------------------------
  // Key Management
  // ---------------------------------------------------------------------------

  /// Reads the stored API key for the given [provider].
  Future<String?> getApiKey(AiProvider provider) async {
    return _secureStorage.read(key: apiKeyStorageKeyFor(provider));
  }

  /// Stores the API key for the given [provider] securely.
  Future<void> setApiKey(AiProvider provider, String key) async {
    await _secureStorage.write(key: apiKeyStorageKeyFor(provider), value: key);
  }

  /// Deletes the stored API key for the given [provider].
  Future<void> deleteApiKey(AiProvider provider) async {
    await _secureStorage.delete(key: apiKeyStorageKeyFor(provider));
  }

  List<AiProviderMetadata> getSupportedProviders() =>
      _providerRegistry.values.toList(growable: false);

  AiProviderMetadata getProviderMetadata(AiProvider provider) =>
      _providerRegistry[provider]!;

  /// Returns the currently selected provider (default: OpenAI).
  Future<AiProvider> getSelectedProvider() async {
    final value = await _secureStorage.read(key: _providerKey);
    if (value == null || value.isEmpty) return AiProvider.openai;
    for (final provider in AiProvider.values) {
      if (provider.name == value) return provider;
    }
    return AiProvider.openai;
  }

  /// Persists the selected provider.
  Future<void> setSelectedProvider(AiProvider provider) async {
    await _secureStorage.write(key: _providerKey, value: provider.name);
  }

  Future<String> getSelectedModel(AiProvider provider) async {
    final selected = await _secureStorage.read(
      key: selectedModelStorageKeyFor(provider),
    );
    final meta = getProviderMetadata(provider);
    if (selected == null || selected.isEmpty) return meta.defaultModel;
    return selected;
  }

  Future<void> setSelectedModel(AiProvider provider, String model) async {
    final resolvedModel = switch (provider) {
      AiProvider.openai => _normalizeOpenAiModelId(model),
      AiProvider.gemini => _normalizeGeminiModelId(model),
      _ => model,
    };
    await _secureStorage.write(
      key: selectedModelStorageKeyFor(provider),
      value: resolvedModel,
    );
  }

  Future<List<AiModelOption>> getModelOptions(AiProvider provider) async {
    // Live provider model APIs are the primary source of truth.
    // Hardcoded metadata is used only for family/ranking hints + tiny fallback.
    final dynamicIds = await _loadDynamicModelIds(provider);
    if (dynamicIds != null && dynamicIds.isNotEmpty) {
      final ranked = _rankProviderModels(
        provider: provider,
        dynamicModels: dynamicIds.toList(growable: false),
      );
      final capped = ranked.take(10).toList(growable: false);
      if (capped.isNotEmpty) {
        return capped
            .map((m) => AiModelOption(id: m, label: m))
            .toList(growable: false);
      }
    }

    // Emergency fallback only: keep this small and intentionally conservative.
    final fallback = _safeEmergencyFallback(provider);
    return fallback
        .map(
          (m) => AiModelOption(
            id: m,
            label: m,
            isFallback: true,
          ),
        )
        .toList(growable: false);
  }

  /// Resolves persisted model selection against the final allowed model list
  /// (dynamic if available, otherwise emergency fallback) and auto-heals storage.
  Future<String> resolveAndPersistSelectedModel(AiProvider provider) async {
    final options = await getModelOptions(provider);
    final selected = await getSelectedModel(provider);
    if (options.isNotEmpty && options.any((m) => m.id == selected)) {
      return selected;
    }
    final meta = getProviderMetadata(provider);
    final resolved = options.isNotEmpty ? options.first.id : meta.defaultModel;
    await setSelectedModel(provider, resolved);
    return resolved;
  }

  List<String> _safeEmergencyFallback(AiProvider provider) {
    final meta = getProviderMetadata(provider);
    final fallback = meta.emergencyFallbackModels;
    if (fallback.isEmpty) return [meta.defaultModel];
    return fallback;
  }

  List<String> _rankProviderModels({
    required AiProvider provider,
    required List<String> dynamicModels,
  }) {
    final uniqueModels = dynamicModels.toSet().toList(growable: false);
    uniqueModels.sort((a, b) {
      final scoreA = _providerModelScore(provider, a);
      final scoreB = _providerModelScore(provider, b);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      // tie-break: lexical descending tends to keep newer semantic/date variants first
      return b.compareTo(a);
    });

    return uniqueModels;
  }

  int _providerModelScore(AiProvider provider, String modelId) {
    final id = modelId.toLowerCase();
    int score = 0;
    final hints = getProviderMetadata(provider).rankingHints;
    final hintIndex = hints.indexWhere((h) => h.toLowerCase() == id);
    if (hintIndex != -1) {
      // Family/ranking hints: strong boost, but live availability still decides.
      score += 1200 - (hintIndex * 15);
    }

    // Penalize legacy/preview-looking entries to keep stale models lower.
    if (id.contains('deprecated') ||
        id.contains('legacy') ||
        id.contains('preview')) {
      score -= 40;
    }

    // Provider-specific alias/latest behavior is intentionally explicit.
    switch (provider) {
      case AiProvider.openai:
        if (_looksLikeDatedSnapshot(id)) score -= 160;
        if (id == 'gpt-5.4') score += 1000;
        if (id == 'gpt-5.4-pro') score += 980;
        if (id == 'gpt-5.4-mini') score += 960;
        if (id == 'gpt-5.4-nano') score += 940;
        if (id.startsWith('gpt-5')) score += 900;
        if (id.startsWith('gpt-4.1')) score += 700;
        if (id.startsWith('gpt-4o')) score += 600;
        break;
      case AiProvider.gemini:
        if (id == 'gemini-pro-latest') score += 1000;
        if (id == 'gemini-flash-latest') score += 980;
        if (id == 'gemini-flash-lite-latest') score += 950;
        if (id.contains('pro')) score += 800;
        if (id.contains('flash')) score += 760;
        if (id.contains('-latest')) score += 120;
        break;
      case AiProvider.anthropic:
        if (id.startsWith('claude-opus-4')) score += 1000;
        if (id.startsWith('claude-sonnet-4')) score += 950;
        if (id.startsWith('claude-haiku-4')) score += 900;
        if (id.contains('-latest')) score += 80;
        break;
      case AiProvider.mistral:
        if (id.startsWith('mistral-large')) score += 1000;
        if (id.startsWith('mistral-medium')) score += 900;
        if (id.startsWith('mistral-small')) score += 820;
        if (id.startsWith('pixtral')) score += 760;
        if (id.contains('-latest')) score += 120;
        break;
      case AiProvider.xai:
        if (id.contains('-reasoning')) score += 920;
        if (id.contains('-non-reasoning')) score += 860;
        if (id.contains('-latest')) score += 120;
        break;
    }

    // Generic numeric freshness boost (keeps newer versions above older ones).
    score += _numericFreshnessScore(id);
    return score;
  }

  int _numericFreshnessScore(String id) {
    final numbers = RegExp(r'\d+')
        .allMatches(id)
        .map((m) => int.tryParse(m.group(0)!) ?? 0)
        .toList();
    if (numbers.isEmpty) return 0;
    final take = numbers.take(4).toList(growable: false);
    var bonus = 0;
    for (var i = 0; i < take.length; i++) {
      final normalized = take[i] > 99 ? 0 : take[i];
      bonus += normalized * (4 - i);
    }
    return bonus;
  }

  bool _looksLikeDatedSnapshot(String id) {
    return RegExp(r'-\d{4}-\d{2}-\d{2}$').hasMatch(id);
  }

  String _normalizeOpenAiModelId(String modelId) {
    final lower = modelId.toLowerCase();
    final match =
        RegExp(r'^(gpt-[a-z0-9.\-]+)-\d{4}-\d{2}-\d{2}$').firstMatch(lower);
    if (match != null) return match.group(1)!;
    return modelId;
  }

  String _normalizeGeminiModelId(String modelId) {
    if (modelId.startsWith('models/')) {
      return modelId.substring('models/'.length);
    }
    return modelId;
  }

  Map<String, dynamic> _openAiTokenParams(String modelId) {
    final id = modelId.toLowerCase();
    if (id.startsWith('gpt-5') || RegExp(r'^o[0-9]').hasMatch(id)) {
      return const {'max_completion_tokens': 2000};
    }
    return const {'max_tokens': 2000};
  }

  String? _extractProviderErrorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'] as String?;
        if (message != null && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      // Keep null if provider response isn't JSON.
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Analysis
  // ---------------------------------------------------------------------------

  /// Analyzes one or more meal images and returns suggested food items.
  ///
  /// Optionally accepts a [textHint] describing the meal for better accuracy.
  /// Pass [languageCode] (e.g. 'de') to get food names in that language.
  Future<List<AiSuggestedItem>> analyzeImages(
    List<File> images, {
    String? textHint,
    String? languageCode,
  }) async {
    final provider = await getSelectedProvider();
    final apiKey = await getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) throw const AiKeyMissingException();
    final model = await resolveAndPersistSelectedModel(provider);

    // Encode images to base64
    final imageDataList = <String>[];
    for (final img in images) {
      final bytes = await img.readAsBytes();
      imageDataList.add(await compute(base64Encode, bytes));
    }

    final userContent =
        textHint ?? 'Analyze this meal and identify all food components.';
    final prompt = _buildSystemPrompt(languageCode: languageCode);

    switch (provider) {
      case AiProvider.openai:
        return _callOpenAi(
          apiKey,
          model,
          userContent,
          imageDataList,
          systemPrompt: prompt,
        );
      case AiProvider.gemini:
        return _callGemini(
          apiKey,
          model,
          userContent,
          imageDataList,
          systemPrompt: prompt,
        );
      case AiProvider.anthropic:
        return _callAnthropic(
          apiKey,
          model,
          userContent,
          imageDataList,
          systemPrompt: prompt,
        );
      case AiProvider.mistral:
        return _callMistral(
          apiKey,
          model,
          userContent,
          imageDataList,
          systemPrompt: prompt,
        );
      case AiProvider.xai:
        return _callXai(
          apiKey,
          model,
          userContent,
          imageDataList,
          systemPrompt: prompt,
        );
    }
  }

  /// Analyzes a text-only meal description and returns suggested food items.
  ///
  /// Pass [languageCode] (e.g. 'de') to get food names in that language.
  Future<List<AiSuggestedItem>> analyzeText(
    String description, {
    String? languageCode,
  }) async {
    final provider = await getSelectedProvider();
    final apiKey = await getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) throw const AiKeyMissingException();
    final model = await resolveAndPersistSelectedModel(provider);
    final prompt = _buildSystemPrompt(languageCode: languageCode);

    switch (provider) {
      case AiProvider.openai:
        return _callOpenAi(apiKey, model, description, [],
            systemPrompt: prompt);
      case AiProvider.gemini:
        return _callGemini(apiKey, model, description, [],
            systemPrompt: prompt);
      case AiProvider.anthropic:
        return _callAnthropic(
          apiKey,
          model,
          description,
          [],
          systemPrompt: prompt,
        );
      case AiProvider.mistral:
        return _callMistral(apiKey, model, description, [],
            systemPrompt: prompt);
      case AiProvider.xai:
        return _callXai(apiKey, model, description, [], systemPrompt: prompt);
    }
  }

  /// Retries analysis with user feedback to refine the results.
  ///
  /// Pass [languageCode] (e.g. 'de') to get food names in that language.
  Future<List<AiSuggestedItem>> retry({
    required List<AiSuggestedItem> previousResults,
    required String feedback,
    List<File>? images,
    String? languageCode,
  }) async {
    final provider = await getSelectedProvider();
    final apiKey = await getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) throw const AiKeyMissingException();
    final model = await resolveAndPersistSelectedModel(provider);

    final previousJson = jsonEncode(
      previousResults.map((e) => e.toJson()).toList(),
    );
    final userContent = '''
Previous analysis result:
$previousJson

User correction/feedback: $feedback

Please provide an updated analysis incorporating the user's feedback. Return the corrected JSON array.''';

    // Re-encode images if provided
    final imageDataList = <String>[];
    if (images != null) {
      for (final img in images) {
        final bytes = await img.readAsBytes();
        imageDataList.add(await compute(base64Encode, bytes));
      }
    }
    final prompt = _buildSystemPrompt(languageCode: languageCode);

    switch (provider) {
      case AiProvider.openai:
        return _callOpenAi(
          apiKey,
          model,
          userContent,
          imageDataList,
          systemPrompt: prompt,
        );
      case AiProvider.gemini:
        return _callGemini(
          apiKey,
          model,
          userContent,
          imageDataList,
          systemPrompt: prompt,
        );
      case AiProvider.anthropic:
        return _callAnthropic(
          apiKey,
          model,
          userContent,
          imageDataList,
          systemPrompt: prompt,
        );
      case AiProvider.mistral:
        return _callMistral(
          apiKey,
          model,
          userContent,
          imageDataList,
          systemPrompt: prompt,
        );
      case AiProvider.xai:
        return _callXai(
          apiKey,
          model,
          userContent,
          imageDataList,
          systemPrompt: prompt,
        );
    }
  }

  /// Tests whether the API key is valid by sending a minimal request.
  Future<bool> testConnection() async {
    try {
      await analyzeText(
        'Test: reply with [{"name":"Test","estimatedGrams":1,"confidence":1.0}]',
      );
      return true;
    } on AiServiceException {
      rethrow;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Provider-specific HTTP calls
  // ---------------------------------------------------------------------------

  Future<List<AiSuggestedItem>> _callOpenAi(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
  }) async {
    final effectiveModel = _normalizeOpenAiModelId(model);
    final contentParts = <Map<String, dynamic>>[];

    // Add image parts
    for (final img64 in imagesBase64) {
      contentParts.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,$img64', 'detail': 'low'},
      });
    }

    // Add text part
    contentParts.add({'type': 'text', 'text': userContent});

    final body = jsonEncode({
      'model': effectiveModel,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': contentParts},
      ],
      ..._openAiTokenParams(effectiveModel),
      'temperature': 0.3,
    });

    try {
      final response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));

      return _handleOpenAiResponse(response);
    } on SocketException {
      throw const AiNetworkException();
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiNetworkException('Request failed: $e');
    }
  }

  List<AiSuggestedItem> _handleOpenAiResponse(http.Response response) {
    if (response.statusCode == 401) throw const AiAuthException();
    if (response.statusCode == 429) throw const AiRateLimitException();
    if (response.statusCode != 200) {
      final message = _extractProviderErrorMessage(response.body);
      throw AiNetworkException(
        message != null
            ? 'API returned status ${response.statusCode}: $message'
            : 'API returned status ${response.statusCode}',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) throw const AiParseException();

      final messageContent = choices[0]['message']['content'] as String? ?? '';
      return _parseItemsFromContent(messageContent);
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw const AiParseException();
    }
  }

  Future<List<AiSuggestedItem>> _callGemini(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
  }) async {
    final parts = <Map<String, dynamic>>[];

    // Add image parts
    for (final img64 in imagesBase64) {
      parts.add({
        'inlineData': {'mimeType': 'image/jpeg', 'data': img64},
      });
    }

    // Add text parts (system prompt + user content combined)
    parts.add({'text': '$systemPrompt\n\n$userContent'});

    final body = jsonEncode({
      'contents': [
        {'parts': parts},
      ],
      'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 8192},
    });

    try {
      final response = await _postGeminiGenerateContent(
        apiKey: apiKey,
        model: model,
        body: body,
      );
      return _handleGeminiResponse(response);
    } on SocketException {
      throw const AiNetworkException();
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiNetworkException('Request failed: $e');
    }
  }

  List<AiSuggestedItem> _handleGeminiResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AiAuthException();
    }
    if (response.statusCode == 429) throw const AiRateLimitException();
    if (response.statusCode != 200) {
      final message = _extractProviderErrorMessage(response.body);
      throw AiNetworkException(
        message != null
            ? 'API returned status ${response.statusCode}: $message'
            : 'API returned status ${response.statusCode}',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const AiParseException();
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) throw const AiParseException();

      final text = parts[0]['text'] as String? ?? '';
      return _parseItemsFromContent(text);
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw const AiParseException();
    }
  }

  List<String> _geminiModelCandidates(String model) {
    final normalized = _normalizeGeminiModelId(model);
    final candidates = <String>[normalized];

    // Provider-specific alias handling for Gemini only.
    // We only try explicit fallback aliases, not generic wildcard logic.
    const aliasFallbacks = <String, List<String>>{
      'gemini-flash-latest': ['gemini-2.5-flash', 'gemini-2.0-flash'],
      'gemini-pro-latest': ['gemini-2.5-pro', 'gemini-1.5-pro'],
      'gemini-flash-lite-latest': ['gemini-2.5-flash-lite'],
    };
    final mapped = aliasFallbacks[normalized];
    if (mapped != null) candidates.addAll(mapped);

    // Last local fallback for some keys/projects that don't expose latest aliases.
    if (normalized.endsWith('-latest')) {
      candidates.add(normalized.replaceFirst(RegExp(r'-latest$'), ''));
    }

    return candidates.toSet().toList(growable: false);
  }

  Future<http.Response> _postGeminiGenerateContent({
    required String apiKey,
    required String model,
    required String body,
  }) async {
    http.Response? lastResponse;
    final candidates = _geminiModelCandidates(model);

    for (final candidate in candidates) {
      for (final version in const ['v1beta', 'v1']) {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/$version/models/$candidate:generateContent?key=$apiKey',
        );
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) return response;
        lastResponse = response;

        // Don't continue retrying for auth/rate errors.
        if (response.statusCode == 401 ||
            response.statusCode == 403 ||
            response.statusCode == 429) {
          return response;
        }
      }
    }

    return lastResponse ??
        http.Response(
          '{"error":{"message":"Gemini request failed before any response was received."}}',
          400,
        );
  }

  Future<List<AiSuggestedItem>> _callAnthropic(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
  }) async {
    final raw = await _callAnthropicRaw(
      apiKey,
      model,
      userContent,
      imagesBase64,
      systemPrompt: systemPrompt,
    );
    return _parseItemsFromContent(raw);
  }

  Future<String> _callAnthropicRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
  }) async {
    final content = <Map<String, dynamic>>[];
    for (final img64 in imagesBase64) {
      content.add({
        'type': 'image',
        'source': {'type': 'base64', 'media_type': 'image/jpeg', 'data': img64},
      });
    }
    content.add({'type': 'text', 'text': userContent});

    final body = jsonEncode({
      'model': model,
      'system': systemPrompt,
      'max_tokens': 2000,
      'messages': [
        {'role': 'user', 'content': content},
      ],
    });

    try {
      final response = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AiAuthException();
      }
      if (response.statusCode == 429) throw const AiRateLimitException();
      if (response.statusCode != 200) {
        throw AiNetworkException('API returned status ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final contentList = json['content'] as List<dynamic>?;
      if (contentList == null || contentList.isEmpty) {
        throw const AiParseException();
      }
      final textPart = contentList.cast<Map<String, dynamic>>().firstWhere(
          (e) => e['type'] == 'text',
          orElse: () => <String, dynamic>{});
      final text = textPart['text'] as String?;
      if (text == null || text.isEmpty) throw const AiParseException();
      return text;
    } on SocketException {
      throw const AiNetworkException();
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiNetworkException('Request failed: $e');
    }
  }

  Future<List<AiSuggestedItem>> _callMistral(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
  }) async {
    final raw = await _callOpenAiCompatibleRaw(
      endpoint: 'https://api.mistral.ai/v1/chat/completions',
      authHeader: 'Bearer $apiKey',
      model: model,
      userContent: userContent,
      imagesBase64: imagesBase64,
      systemPrompt: systemPrompt,
    );
    return _parseItemsFromContent(raw);
  }

  Future<String> _callMistralRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
  }) {
    return _callOpenAiCompatibleRaw(
      endpoint: 'https://api.mistral.ai/v1/chat/completions',
      authHeader: 'Bearer $apiKey',
      model: model,
      userContent: userContent,
      imagesBase64: imagesBase64,
      systemPrompt: systemPrompt,
    );
  }

  Future<List<AiSuggestedItem>> _callXai(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
  }) async {
    final raw = await _callOpenAiCompatibleRaw(
      endpoint: 'https://api.x.ai/v1/chat/completions',
      authHeader: 'Bearer $apiKey',
      model: model,
      userContent: userContent,
      imagesBase64: imagesBase64,
      systemPrompt: systemPrompt,
    );
    return _parseItemsFromContent(raw);
  }

  Future<String> _callXaiRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
  }) {
    return _callOpenAiCompatibleRaw(
      endpoint: 'https://api.x.ai/v1/chat/completions',
      authHeader: 'Bearer $apiKey',
      model: model,
      userContent: userContent,
      imagesBase64: imagesBase64,
      systemPrompt: systemPrompt,
    );
  }

  Future<String> _callOpenAiCompatibleRaw({
    required String endpoint,
    required String authHeader,
    required String model,
    required String userContent,
    required List<String> imagesBase64,
    required String systemPrompt,
  }) async {
    final contentParts = <Map<String, dynamic>>[];
    for (final img64 in imagesBase64) {
      contentParts.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,$img64', 'detail': 'low'},
      });
    }
    contentParts.add({'type': 'text', 'text': userContent});

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': contentParts},
      ],
      'max_tokens': 2000,
      'temperature': 0.3,
    });

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': authHeader,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AiAuthException();
      }
      if (response.statusCode == 429) throw const AiRateLimitException();
      if (response.statusCode != 200) {
        throw AiNetworkException('API returned status ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) throw const AiParseException();
      return choices[0]['message']['content'] as String? ?? '';
    } on SocketException {
      throw const AiNetworkException();
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiNetworkException('Request failed: $e');
    }
  }

  Future<Set<String>?> _loadDynamicModelIds(AiProvider provider) async {
    if (_dynamicModelIdsLoader != null) {
      return _dynamicModelIdsLoader!(provider);
    }
    final meta = getProviderMetadata(provider);
    if (!meta.supportsDynamicModelLoading) return null;
    final apiKey = await getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) return null;

    switch (provider) {
      case AiProvider.openai:
        return _loadOpenAiModels(apiKey);
      case AiProvider.gemini:
        return _loadGeminiModels(apiKey);
      case AiProvider.mistral:
        return _loadMistralModels(apiKey);
      case AiProvider.xai:
        return _loadXaiModels(apiKey);
      case AiProvider.anthropic:
        return _loadAnthropicModels(apiKey);
    }
  }

  Future<Set<String>?> _loadOpenAiModels(String apiKey) async {
    try {
      final response = await _httpGet(
        Uri.parse('https://api.openai.com/v1/models'),
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? const [];
      final ids = data
          .map((e) => (e as Map<String, dynamic>)['id'] as String? ?? '')
          .where(
            (id) => id.startsWith('gpt-'),
          )
          .where((id) => !id.contains('embedding'))
          .where((id) => !id.contains('audio'))
          .where((id) => !id.contains('realtime'))
          .where((id) => !id.contains('transcribe'))
          .where((id) => !id.contains('search'))
          .where((id) => !id.contains('moderation'))
          .where((id) => !id.contains('tts'))
          .where((id) => !id.contains('whisper'))
          .where((id) => !id.contains('image'))
          .where((id) => !id.contains('codex'))
          .where((id) => !id.contains('deep-research'))
          .where((id) => !id.contains('search-preview'))
          .where((id) => !id.contains('computer-use'))
          .where((id) => !id.contains('chat-latest'))
          .map(_normalizeOpenAiModelId)
          .toSet();
      return ids;
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>?> _loadGeminiModels(String apiKey) async {
    try {
      final response = await _httpGet(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
        ),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['models'] as List<dynamic>? ?? const [];
      final ids = data
          .map((e) => e as Map<String, dynamic>)
          .where(
            (model) => (model['supportedGenerationMethods'] as List<dynamic>? ??
                    const [])
                .contains('generateContent'),
          )
          .map((model) => model['name'] as String? ?? '')
          .where((n) => n.startsWith('models/'))
          .map((n) => n.substring('models/'.length))
          .where((id) => id.contains('gemini'))
          .where((id) => id.contains('pro') || id.contains('flash'))
          .where((id) => !id.contains('embedding'))
          .where((id) => !id.contains('aqa'))
          .where((id) => !id.contains('tts'))
          .where((id) => !id.contains('audio'))
          .where((id) => !id.contains('transcribe'))
          .where((id) => !id.contains('realtime'))
          .where((id) => !id.contains('image-generation'))
          .where((id) => !id.contains('learnlm'))
          .toSet();
      return ids;
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>?> _loadMistralModels(String apiKey) async {
    try {
      final response = await _httpGet(
        Uri.parse('https://api.mistral.ai/v1/models'),
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? const [];
      final ids = data
          .map((e) => (e as Map<String, dynamic>)['id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .where(
            (id) =>
                id.startsWith('mistral-') ||
                id.startsWith('pixtral-') ||
                id.startsWith('magistral-') ||
                id.startsWith('ministral-'),
          )
          .where((id) => !id.contains('embed'))
          .where((id) => !id.contains('moderation'))
          .where((id) => !id.contains('audio'))
          .where((id) => !id.contains('asr'))
          .where((id) => !id.contains('ocr'))
          .where((id) => !id.contains('tts'))
          .where((id) => !id.contains('voxtral'))
          .where((id) => !id.contains('codestral'))
          .where((id) => !id.contains('devstral'))
          .where((id) => !id.contains('leanstral'))
          .toSet();
      return ids;
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>?> _loadXaiModels(String apiKey) async {
    try {
      final response = await _httpGet(
        Uri.parse('https://api.x.ai/v1/models'),
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? const [];
      final ids = data
          .map((e) => (e as Map<String, dynamic>)['id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .where((id) => id.startsWith('grok-'))
          .where((id) => !id.contains('embedding'))
          .where((id) => !id.contains('audio'))
          .where((id) => !id.contains('tts'))
          .where((id) => !id.contains('transcribe'))
          .where((id) => !id.contains('realtime'))
          .where((id) => !id.contains('imagine'))
          .toSet();
      return ids;
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>?> _loadAnthropicModels(String apiKey) async {
    try {
      final response = await _httpGet(
        Uri.parse('https://api.anthropic.com/v1/models'),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? const [];
      final ids = data
          .map((e) => e as Map<String, dynamic>)
          .where((model) => (model['id'] as String?)?.isNotEmpty ?? false)
          .where((model) => model['id'].toString().startsWith('claude-'))
          .where((model) {
            final capabilities = model['capabilities'] as Map<String, dynamic>?;
            final imageInput =
                capabilities?['image_input'] as Map<String, dynamic>?;
            return imageInput?['supported'] == true;
          })
          .map((model) => model['id'] as String)
          .toSet();
      return ids;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // JSON Parsing
  // ---------------------------------------------------------------------------

  /// Extracts the JSON array from the AI response text.
  ///
  /// Handles cases where the AI wraps JSON in markdown code fences.
  List<AiSuggestedItem> _parseItemsFromContent(String content) {
    // Strip markdown code fences if present
    var cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      cleaned = cleaned.trim();
    }

    // Find JSON array boundaries
    final startIdx = cleaned.indexOf('[');
    final endIdx = cleaned.lastIndexOf(']');
    if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
      throw const AiParseException('No JSON array found in response.');
    }

    final jsonStr = cleaned.substring(startIdx, endIdx + 1);
    final List<dynamic> items = jsonDecode(jsonStr) as List<dynamic>;

    if (items.isEmpty) {
      throw const AiParseException('AI returned an empty list.');
    }

    return items
        .map((e) => AiSuggestedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Meal Recommendation
  // ---------------------------------------------------------------------------

  /// Generates a personalised meal recommendation based on dietary preferences,
  /// and recent eating history.
  ///
  ///   - [targetMacros] The calculated macros the AI should aggressively aim to fill for *this* meal.
  ///   - [preferences] User dietary/situational preferences.
  Future<AiMealRecommendation> generateMealRecommendation({
    required Map<String, int> targetMacros,
    required List<String> preferences,
    required String recentHistory,
    required String mealTypeLabel,
    String? customRequest,
    String? languageCode,
  }) async {
    final provider = await getSelectedProvider();
    final apiKey = await getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) throw const AiKeyMissingException();
    final model = await resolveAndPersistSelectedModel(provider);

    final systemPrompt = _buildRecommendationPrompt(languageCode: languageCode);

    // Map UI preferences to strict prompt constraints
    final refinedPreferences = preferences.map((p) {
      if (p == 'On the go') {
        return 'ON THE GO: The meal MUST be instantly edible from a supermarket (e.g., protein bar, pre-made sandwich, fruit, skyr). NO cooking, NO microwave, NO utensils required. DO NOT suggest raw meat, lentils, rice, or anything needing prep.';
      } else if (p == 'No cooking') {
        return 'NO COOKING: The meal MUST be cold and require NO stove/microwave (e.g., salad, cottage cheese with nuts, sandwich). DO NOT suggest raw meat, pasta, or foods needing heat.';
      } else if (p == 'Cooking allowed') {
        return 'WITH COOKING: Full kitchen available. Feel free to suggest meals requiring a stove/oven (e.g., cooked meat, rice, cooked veggies).';
      }
      return p;
    }).toList();

    final userContent = '''
Target Meal: $mealTypeLabel

Target macros for THIS meal:
- Calories: ${targetMacros['kcal']} kcal
- Protein: ${targetMacros['protein']}g
- Carbs: ${targetMacros['carbs']}g
- Fat: ${targetMacros['fat']}g

User constraints (Dietary/Situation): ${refinedPreferences.isEmpty ? 'None' : refinedPreferences.join('\n- ')}

Custom user request: ${customRequest != null && customRequest.trim().isNotEmpty ? customRequest.trim() : 'None'}

Recent meals (last 7 days): ${recentHistory.isEmpty ? 'No history available' : recentHistory}

Suggest ONE meal for $mealTypeLabel that fits the user constraints and fills the target macros for THIS meal as accurately as possible.''';

    String rawContent;
    switch (provider) {
      case AiProvider.openai:
        rawContent = await _callOpenAiRaw(
          apiKey,
          model,
          userContent,
          [],
          systemPrompt: systemPrompt,
        );
        break;
      case AiProvider.gemini:
        rawContent = await _callGeminiRaw(
          apiKey,
          model,
          userContent,
          [],
          systemPrompt: systemPrompt,
        );
        break;
      case AiProvider.anthropic:
        rawContent = await _callAnthropicRaw(
          apiKey,
          model,
          userContent,
          [],
          systemPrompt: systemPrompt,
        );
        break;
      case AiProvider.mistral:
        rawContent = await _callMistralRaw(
          apiKey,
          model,
          userContent,
          [],
          systemPrompt: systemPrompt,
        );
        break;
      case AiProvider.xai:
        rawContent = await _callXaiRaw(
          apiKey,
          model,
          userContent,
          [],
          systemPrompt: systemPrompt,
        );
        break;
    }

    return _parseRecommendationFromContent(rawContent);
  }

  /// System prompt for meal recommendations.
  static String _buildRecommendationPrompt({String? languageCode}) {
    final langRule = (languageCode != null && languageCode.isNotEmpty)
        ? '\n- IMPORTANT: All food/ingredient names MUST be in the "$languageCode" language.'
        : '';

    return '''
You are a personal nutrition coach. The user wants a meal suggestion for a specific meal (Breakfast, Lunch, Dinner, or Snack).

CRITICAL RULES:
1. PORTION SCALING: The provided macros are exactly what you should aim to fill for THIS SINGLE MEAL. Do NOT leave 'space' or hold back calories/macros for future meals. The user wants a meal recommendation whose nutrition matches the provided targets as optimally as possible.
2. USER CONSTRAINTS: You must STRICTLY respect the user's constraints (Dietary/Situation). The user might give very strict situational limits (like "NO COOKING" or "ON THE GO"). Adhere to them exactly! Dietary limits (e.g. Vegan) must also be strictly followed.
3. Suggest ONE highly appropriate meal.
4. Avoid repeating exact meals from the user's recent history.
5. Use SIMPLE, SHORT base food names for ingredients (e.g. "Reis" not "Langkorn-Basmatireis"), to maximize database matching.
6. Estimate realistic ingredient amounts in grams.$langRule

Respond ONLY with a valid JSON object. No markdown, no explanation, no extra text.
The JSON must have exactly these fields:
- "meal_name": string (short name of the suggested meal)
- "description": string (1-2 sentences explaining why this meal fits)
- "ingredients": array of objects, each with:
  - "name": string (simple ingredient name)
  - "amount_in_grams": integer (estimated weight in grams)

Example:
{"meal_name": "Chicken Rice Bowl", "description": "High protein, moderate carbs to meet your remaining goals.", "ingredients": [{"name": "Chicken breast", "amount_in_grams": 200}, {"name": "Rice", "amount_in_grams": 150}, {"name": "Broccoli", "amount_in_grams": 100}]}
''';
  }

  /// Calls OpenAI and returns the raw content string (for recommendation parsing).
  Future<String> _callOpenAiRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
  }) async {
    final effectiveModel = _normalizeOpenAiModelId(model);
    final contentParts = <Map<String, dynamic>>[];
    for (final img64 in imagesBase64) {
      contentParts.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,$img64', 'detail': 'low'},
      });
    }
    contentParts.add({'type': 'text', 'text': userContent});

    final body = jsonEncode({
      'model': effectiveModel,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': contentParts},
      ],
      ..._openAiTokenParams(effectiveModel),
      'temperature': 0.3,
    });

    try {
      final response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 401) throw const AiAuthException();
      if (response.statusCode == 429) throw const AiRateLimitException();
      if (response.statusCode != 200) {
        final message = _extractProviderErrorMessage(response.body);
        throw AiNetworkException(
          message != null
              ? 'API returned status ${response.statusCode}: $message'
              : 'API returned status ${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) throw const AiParseException();
      return choices[0]['message']['content'] as String? ?? '';
    } on SocketException {
      throw const AiNetworkException();
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiNetworkException('Request failed: $e');
    }
  }

  /// Calls Gemini and returns the raw content string (for recommendation parsing).
  Future<String> _callGeminiRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
  }) async {
    final parts = <Map<String, dynamic>>[];
    for (final img64 in imagesBase64) {
      parts.add({
        'inlineData': {'mimeType': 'image/jpeg', 'data': img64},
      });
    }
    parts.add({'text': '$systemPrompt\n\n$userContent'});

    final body = jsonEncode({
      'contents': [
        {'parts': parts},
      ],
      'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 8192},
    });

    try {
      final response = await _postGeminiGenerateContent(
        apiKey: apiKey,
        model: model,
        body: body,
      );
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AiAuthException();
      }
      if (response.statusCode == 429) throw const AiRateLimitException();
      if (response.statusCode != 200) {
        final message = _extractProviderErrorMessage(response.body);
        throw AiNetworkException(
          message != null
              ? 'API returned status ${response.statusCode}: $message'
              : 'API returned status ${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const AiParseException();
      }
      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final allParts = content?['parts'] as List<dynamic>?;
      if (allParts == null || allParts.isEmpty) throw const AiParseException();

      // Gemini 2.5 Flash may return thinking/reasoning in separate parts.
      // Concatenate only text parts (skip thought parts).
      final buffer = StringBuffer();
      for (final p in allParts) {
        final partMap = p as Map<String, dynamic>;
        // Skip "thought" parts (Gemini thinking mode)
        if (partMap.containsKey('thought') && partMap['thought'] == true) {
          continue;
        }
        if (partMap.containsKey('text')) {
          buffer.write(partMap['text'] as String);
        }
      }
      return buffer.toString();
    } on SocketException {
      throw const AiNetworkException();
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiNetworkException('Request failed: $e');
    }
  }

  /// Parses the AI's JSON object response into an [AiMealRecommendation].
  AiMealRecommendation _parseRecommendationFromContent(String content) {
    var cleaned = content.trim();

    // Strip markdown code fences (```json ... ```)
    final fenceRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final fenceMatch = fenceRegex.firstMatch(cleaned);
    if (fenceMatch != null) {
      cleaned = fenceMatch.group(1)?.trim() ?? cleaned;
    }

    // Find the JSON object that contains "meal_name" to avoid
    // matching stray braces in thinking/reasoning text.
    int startIdx = -1;
    int braceDepth = 0;
    int? objStart;

    for (int i = 0; i < cleaned.length; i++) {
      if (cleaned[i] == '{') {
        if (braceDepth == 0) objStart = i;
        braceDepth++;
      } else if (cleaned[i] == '}') {
        braceDepth--;
        if (braceDepth == 0 && objStart != null) {
          final candidate = cleaned.substring(objStart, i + 1);
          if (candidate.contains('"meal_name"') ||
              candidate.contains('"ingredients"')) {
            startIdx = objStart;
            break;
          }
          objStart = null;
        }
      }
    }

    if (startIdx == -1) {
      // Fallback: try basic indexOf
      startIdx = cleaned.indexOf('{');
    }
    final endIdx = cleaned.lastIndexOf('}');
    if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
      throw AiParseException('No JSON object found in response. Raw: $cleaned');
    }

    final jsonStr = cleaned.substring(startIdx, endIdx + 1);
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw AiParseException('JSON decode failed: $e\nRaw: $cleaned');
    }

    final mealName = json['meal_name'] as String? ?? 'Meal';
    final description = json['description'] as String? ?? '';
    final ingredientsRaw = json['ingredients'] as List<dynamic>? ?? [];

    final ingredients = ingredientsRaw
        .map(
          (e) => AiRecommendedIngredient(
            name: (e as Map<String, dynamic>)['name'] as String? ?? '',
            amountInGrams: (e['amount_in_grams'] as num?)?.toInt() ?? 100,
          ),
        )
        .toList();

    if (ingredients.isEmpty) {
      throw const AiParseException('No ingredients found in recommendation.');
    }

    return AiMealRecommendation(
      mealName: mealName,
      description: description,
      ingredients: ingredients,
    );
  }
}

// ---------------------------------------------------------------------------
// Meal Recommendation Data Models
// ---------------------------------------------------------------------------

/// A single ingredient in an AI-recommended meal.
class AiRecommendedIngredient {
  final String name;
  final int amountInGrams;

  const AiRecommendedIngredient({
    required this.name,
    required this.amountInGrams,
  });
}

/// Complete meal recommendation from the AI.
class AiMealRecommendation {
  final String mealName;
  final String description;
  final List<AiRecommendedIngredient> ingredients;

  const AiMealRecommendation({
    required this.mealName,
    required this.description,
    required this.ingredients,
  });
}
