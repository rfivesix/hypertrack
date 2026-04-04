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
  deepseek,
  xai,
  cohere,
}

/// Provider registry metadata.
class AiProviderMetadata {
  final AiProvider provider;
  final String displayName;
  final String keyHint;
  final String defaultModel;
  final List<String> fallbackModels;
  final bool supportsVision;
  final bool supportsDynamicModelLoading;

  const AiProviderMetadata({
    required this.provider,
    required this.displayName,
    required this.keyHint,
    required this.defaultModel,
    required this.fallbackModels,
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
  AiService._();
  static final AiService instance = AiService._();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Secure storage keys per provider
  static const _keyPrefix = 'ai_api_key_';
  static const _providerKey = 'ai_selected_provider';
  static const _modelPrefix = 'ai_selected_model_';

  static const Map<AiProvider, AiProviderMetadata> _providerRegistry = {
    AiProvider.openai: AiProviderMetadata(
      provider: AiProvider.openai,
      displayName: 'OpenAI',
      keyHint: 'sk-...',
      defaultModel: 'gpt-4o',
      fallbackModels: ['gpt-4o', 'gpt-4.1-mini'],
      supportsVision: true,
      supportsDynamicModelLoading: true,
    ),
    AiProvider.gemini: AiProviderMetadata(
      provider: AiProvider.gemini,
      displayName: 'Google Gemini',
      keyHint: 'AIza...',
      defaultModel: 'gemini-2.5-flash',
      fallbackModels: ['gemini-2.5-flash', 'gemini-1.5-flash'],
      supportsVision: true,
      supportsDynamicModelLoading: true,
    ),
    AiProvider.anthropic: AiProviderMetadata(
      provider: AiProvider.anthropic,
      displayName: 'Anthropic Claude',
      keyHint: 'sk-ant-...',
      defaultModel: 'claude-3-5-sonnet-latest',
      fallbackModels: [
        'claude-3-5-sonnet-latest',
        'claude-3-5-haiku-latest',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: false,
    ),
    AiProvider.mistral: AiProviderMetadata(
      provider: AiProvider.mistral,
      displayName: 'Mistral',
      keyHint: 'mistral-...',
      defaultModel: 'pixtral-12b-2409',
      fallbackModels: ['pixtral-12b-2409', 'mistral-large-latest'],
      supportsVision: true,
      supportsDynamicModelLoading: true,
    ),
    AiProvider.deepseek: AiProviderMetadata(
      provider: AiProvider.deepseek,
      displayName: 'DeepSeek',
      keyHint: 'sk-...',
      defaultModel: 'deepseek-chat',
      fallbackModels: ['deepseek-chat'],
      supportsVision: false,
      supportsDynamicModelLoading: false,
    ),
    AiProvider.xai: AiProviderMetadata(
      provider: AiProvider.xai,
      displayName: 'xAI Grok',
      keyHint: 'xai-...',
      defaultModel: 'grok-2-vision-latest',
      fallbackModels: ['grok-2-vision-latest', 'grok-2-latest'],
      supportsVision: true,
      supportsDynamicModelLoading: true,
    ),
    AiProvider.cohere: AiProviderMetadata(
      provider: AiProvider.cohere,
      displayName: 'Cohere',
      keyHint: 'co-...',
      defaultModel: 'command-r-plus',
      fallbackModels: ['command-r-plus', 'command-r'],
      supportsVision: false,
      supportsDynamicModelLoading: false,
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
    return _secureStorage.read(key: '$_keyPrefix${provider.name}');
  }

  /// Stores the API key for the given [provider] securely.
  Future<void> setApiKey(AiProvider provider, String key) async {
    await _secureStorage.write(key: '$_keyPrefix${provider.name}', value: key);
  }

  /// Deletes the stored API key for the given [provider].
  Future<void> deleteApiKey(AiProvider provider) async {
    await _secureStorage.delete(key: '$_keyPrefix${provider.name}');
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
      key: '$_modelPrefix${provider.name}',
    );
    final meta = getProviderMetadata(provider);
    if (selected == null || selected.isEmpty) return meta.defaultModel;
    return selected;
  }

  Future<void> setSelectedModel(AiProvider provider, String model) async {
    await _secureStorage.write(key: '$_modelPrefix${provider.name}', value: model);
  }

  Future<List<AiModelOption>> getModelOptions(AiProvider provider) async {
    final meta = getProviderMetadata(provider);
    final dynamicModels = await _loadDynamicModels(provider);
    if (dynamicModels.isNotEmpty) return dynamicModels;
    return meta.fallbackModels
        .map(
          (m) => AiModelOption(
            id: m,
            label: m,
            isFallback: true,
          ),
        )
        .toList(growable: false);
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
    final model = await getSelectedModel(provider);

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
      case AiProvider.deepseek:
        return _callDeepSeek(
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
      case AiProvider.cohere:
        return _callCohere(
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
    final model = await getSelectedModel(provider);
    final prompt = _buildSystemPrompt(languageCode: languageCode);

    switch (provider) {
      case AiProvider.openai:
        return _callOpenAi(apiKey, model, description, [], systemPrompt: prompt);
      case AiProvider.gemini:
        return _callGemini(apiKey, model, description, [], systemPrompt: prompt);
      case AiProvider.anthropic:
        return _callAnthropic(
          apiKey,
          model,
          description,
          [],
          systemPrompt: prompt,
        );
      case AiProvider.mistral:
        return _callMistral(apiKey, model, description, [], systemPrompt: prompt);
      case AiProvider.deepseek:
        return _callDeepSeek(
          apiKey,
          model,
          description,
          [],
          systemPrompt: prompt,
        );
      case AiProvider.xai:
        return _callXai(apiKey, model, description, [], systemPrompt: prompt);
      case AiProvider.cohere:
        return _callCohere(apiKey, model, description, [], systemPrompt: prompt);
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
    final model = await getSelectedModel(provider);

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
      case AiProvider.deepseek:
        return _callDeepSeek(
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
      case AiProvider.cohere:
        return _callCohere(
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
      throw AiNetworkException('API returned status ${response.statusCode}');
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
      final response = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 60));

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
      throw AiNetworkException('API returned status ${response.statusCode}');
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
      if (contentList == null || contentList.isEmpty) throw const AiParseException();
      final textPart = contentList
          .cast<Map<String, dynamic>>()
          .firstWhere((e) => e['type'] == 'text', orElse: () => <String, dynamic>{});
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

  Future<List<AiSuggestedItem>> _callDeepSeek(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
  }) async {
    if (imagesBase64.isNotEmpty) {
      throw const AiUnsupportedFeatureException(
        'Selected DeepSeek model does not support image analysis in this integration.',
      );
    }
    final raw = await _callOpenAiCompatibleRaw(
      endpoint: 'https://api.deepseek.com/v1/chat/completions',
      authHeader: 'Bearer $apiKey',
      model: model,
      userContent: userContent,
      imagesBase64: const [],
      systemPrompt: systemPrompt,
    );
    return _parseItemsFromContent(raw);
  }

  Future<String> _callDeepSeekRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
  }) {
    return _callOpenAiCompatibleRaw(
      endpoint: 'https://api.deepseek.com/v1/chat/completions',
      authHeader: 'Bearer $apiKey',
      model: model,
      userContent: userContent,
      imagesBase64: const [],
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

  Future<List<AiSuggestedItem>> _callCohere(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
  }) async {
    if (imagesBase64.isNotEmpty) {
      throw const AiUnsupportedFeatureException(
        'Selected Cohere model does not support image analysis in this integration.',
      );
    }
    final raw = await _callCohereRaw(
      apiKey,
      model,
      userContent,
      imagesBase64,
      systemPrompt: systemPrompt,
    );
    return _parseItemsFromContent(raw);
  }

  Future<String> _callCohereRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
  }) async {
    final body = jsonEncode({
      'model': model,
      'message': '$systemPrompt\n\n$userContent',
      'temperature': 0.3,
    });
    try {
      final response = await http
          .post(
            Uri.parse('https://api.cohere.com/v1/chat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
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
      final text = json['text'] as String? ?? json['response'] as String?;
      if (text == null || text.isEmpty) throw const AiParseException();
      return text;
    } on SocketException {
      throw const AiNetworkException();
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiNetworkException('Request failed: $e');
    }
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

  Future<List<AiModelOption>> _loadDynamicModels(AiProvider provider) async {
    final meta = getProviderMetadata(provider);
    if (!meta.supportsDynamicModelLoading) return const [];
    final apiKey = await getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) return const [];

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
      case AiProvider.deepseek:
      case AiProvider.cohere:
        return const [];
    }
  }

  Future<List<AiModelOption>> _loadOpenAiModels(String apiKey) async {
    try {
      final response = await http
          .get(
            Uri.parse('https://api.openai.com/v1/models'),
            headers: {'Authorization': 'Bearer $apiKey'},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return const [];
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? const [];
      final ids = data
          .map((e) => (e as Map<String, dynamic>)['id'] as String? ?? '')
          .where((id) => id.startsWith('gpt-'))
          .toList()
        ..sort();
      return ids
          .map((id) => AiModelOption(id: id, label: id))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<AiModelOption>> _loadGeminiModels(String apiKey) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
            ),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return const [];
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['models'] as List<dynamic>? ?? const [];
      final ids = data
          .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
          .where((n) => n.contains('/'))
          .map((n) => n.split('/').last)
          .where((id) => id.contains('gemini'))
          .toList()
        ..sort();
      return ids
          .map((id) => AiModelOption(id: id, label: id))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<AiModelOption>> _loadMistralModels(String apiKey) async {
    try {
      final response = await http
          .get(
            Uri.parse('https://api.mistral.ai/v1/models'),
            headers: {'Authorization': 'Bearer $apiKey'},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return const [];
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? const [];
      final ids = data
          .map((e) => (e as Map<String, dynamic>)['id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList()
        ..sort();
      return ids
          .map((id) => AiModelOption(id: id, label: id))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<AiModelOption>> _loadXaiModels(String apiKey) async {
    try {
      final response = await http
          .get(
            Uri.parse('https://api.x.ai/v1/models'),
            headers: {'Authorization': 'Bearer $apiKey'},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return const [];
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? const [];
      final ids = data
          .map((e) => (e as Map<String, dynamic>)['id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList()
        ..sort();
      return ids
          .map((id) => AiModelOption(id: id, label: id))
          .toList(growable: false);
    } catch (_) {
      return const [];
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
    final model = await getSelectedModel(provider);

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
      case AiProvider.deepseek:
        rawContent = await _callDeepSeekRaw(
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
      case AiProvider.cohere:
        rawContent = await _callCohereRaw(
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
      final response = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
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
