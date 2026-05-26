// lib/services/ai_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'ai_meal_validation.dart';
import 'ai_meal_context.dart';

part 'ai/ai_models.dart';
part 'ai/ai_prompts.dart';
part 'ai/ai_network.dart';
part 'ai/ai_parsing.dart';

typedef DynamicModelIdsLoader = Future<Set<String>?> Function(
  AiProvider provider,
);
typedef AiHttpGet = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
});

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
  static const _customBaseUrlKey = 'ai_custom_base_url';
  static const _customModelKey = 'ai_custom_model';
  static const _timeoutKey = 'ai_timeout_seconds';

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
    AiProvider.ollama: AiProviderMetadata(
      provider: AiProvider.ollama,
      displayName: 'Ollama',
      keyHint: 'Not required',
      defaultModel: 'llama3',
      rankingHints: [
        'llama3',
        'llava',
        'mistral',
        'phi3',
      ],
      emergencyFallbackModels: [
        'llama3',
        'llava',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: false,
    ),
    AiProvider.custom: AiProviderMetadata(
      provider: AiProvider.custom,
      displayName: 'Custom OpenAI Compatible',
      keyHint: 'API Key (if required)',
      defaultModel: 'custom-model',
      rankingHints: [],
      emergencyFallbackModels: [
        'custom-model',
      ],
      supportsVision: true,
      supportsDynamicModelLoading: false,
    ),
  };

  // ---------------------------------------------------------------------------
  // Custom Provider Fields (Ollama & Custom BaseURL / Custom Model)
  // ---------------------------------------------------------------------------

  /// Reads the custom base URL.
  Future<String?> getCustomBaseUrl() async {
    return _secureStorage.read(key: _customBaseUrlKey);
  }

  /// Stores the custom base URL.
  Future<void> setCustomBaseUrl(String? url) async {
    if (url == null) {
      await _secureStorage.delete(key: _customBaseUrlKey);
    } else {
      await _secureStorage.write(key: _customBaseUrlKey, value: url);
    }
  }

  /// Reads the custom model name.
  Future<String?> getCustomModel() async {
    return _secureStorage.read(key: _customModelKey);
  }

  /// Stores the custom model name.
  Future<void> setCustomModel(String? model) async {
    if (model == null) {
      await _secureStorage.delete(key: _customModelKey);
    } else {
      await _secureStorage.write(key: _customModelKey, value: model);
    }
  }

  /// Reads the AI request timeout in seconds.
  Future<int> getAiTimeoutSeconds() async {
    final value = await _secureStorage.read(key: _timeoutKey);
    if (value == null || value.isEmpty) return 60;
    return int.tryParse(value) ?? 60;
  }

  /// Stores the AI request timeout in seconds.
  Future<void> setAiTimeoutSeconds(int seconds) async {
    await _secureStorage.write(key: _timeoutKey, value: seconds.toString());
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
    if (provider == AiProvider.ollama || provider == AiProvider.custom) {
      final customModel = await getCustomModel();
      if (customModel != null && customModel.isNotEmpty) return customModel;
      return getProviderMetadata(provider).defaultModel;
    }
    final selected = await _secureStorage.read(
      key: selectedModelStorageKeyFor(provider),
    );
    final meta = getProviderMetadata(provider);
    if (selected == null || selected.isEmpty) return meta.defaultModel;
    return selected;
  }

  Future<void> setSelectedModel(AiProvider provider, String model) async {
    if (provider == AiProvider.ollama || provider == AiProvider.custom) {
      await setCustomModel(model);
      return;
    }
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
    if (provider == AiProvider.ollama || provider == AiProvider.custom) {
      return getSelectedModel(provider);
    }
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
      case AiProvider.ollama:
      case AiProvider.custom:
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

  // ---------------------------------------------------------------------------
  // Analysis
  // ---------------------------------------------------------------------------

  /// Analyzes one or more meal images and returns suggested food items.
  Future<AiMealCandidate> analyzeImages(
    List<File> images, {
    String? textHint,
    String? languageCode,
  }) async {
    final userContent =
        textHint ?? 'Analyze this meal and identify all food components.';
    final prompt = _AiPrompts.buildSystemPrompt(languageCode: languageCode);

    final raw = await _callSelectedProviderRaw(
      userContent: userContent,
      systemPrompt: prompt,
      images: images,
      temperature: 0.3,
    );

    return _parseMealCandidateFromContent(raw);
  }

  /// Analyzes a text-only meal description and returns an AI suggested meal candidate.
  Future<AiMealCandidate> analyzeText(
    String description, {
    String? languageCode,
  }) async {
    final prompt = _AiPrompts.buildSystemPrompt(languageCode: languageCode);

    final raw = await _callSelectedProviderRaw(
      userContent: description,
      systemPrompt: prompt,
      temperature: 0.3,
    );

    return _parseMealCandidateFromContent(raw);
  }

  /// Retries analysis with user feedback to refine the results.
  Future<AiMealCandidate> retry({
    required List<AiSuggestedItem> previousResults,
    required String feedback,
    List<File>? images,
    String? languageCode,
  }) async {
    final previousJson = jsonEncode(
      previousResults.map((e) => e.toJson()).toList(),
    );
    final userContent = '''
Previous analysis result:
$previousJson

User correction/feedback: $feedback

Please provide an updated analysis incorporating the user's feedback. Return the corrected JSON object containing mealContext and items.''';

    final prompt = _AiPrompts.buildSystemPrompt(languageCode: languageCode);

    final raw = await _callSelectedProviderRaw(
      userContent: userContent,
      systemPrompt: prompt,
      images: images,
      temperature: 0.3,
    );

    return _parseMealCandidateFromContent(raw);
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
  // Repair
  // ---------------------------------------------------------------------------

  Future<AiMealCandidate> repairMealCaptureCandidate({
    required AiMealCandidate candidate,
    required AiValidationResult validation,
    List<File>? images,
    String? languageCode,
    AiMealContext? mealContext,
  }) async {
    final userContent = '''
Previous meal capture candidate:
${jsonEncode(candidate.items.map((item) => {
              'name': item.name,
              'estimatedGrams': item.grams,
              if (item.confidence != null) 'confidence': item.confidence,
              if (item.stateHint != null) 'stateHint': item.stateHint,
            }).toList())}

Deterministic validation feedback:
${validation.toRepairFeedback()}

Repair the candidate. When database candidates are listed, pick the EXACT name from the list. Adjust grams to fit the meal context anchor.''';

    final raw = await _callSelectedProviderRaw(
      userContent: userContent,
      images: images,
      systemPrompt: _AiPrompts.buildRepairPrompt(
        languageCode: languageCode,
        mealContext: mealContext,
      ),
      temperature: 0.1,
    );
    final repaired = _parseItemsFromContent(raw);
    return AiMealCandidate(
      items: repaired
          .map(
            (item) => AiMealCandidateItem(
              name: item.name,
              grams: item.estimatedGrams,
              confidence: item.confidence,
              matchedBarcode: item.matchedBarcode,
            ),
          )
          .toList(growable: false),
      context: candidate.context,
    );
  }

  Future<String> _callSelectedProviderRaw({
    required String userContent,
    required String systemPrompt,
    List<File>? images,
    double temperature = 0.3,
  }) async {
    final provider = await getSelectedProvider();
    String? apiKey;
    if (provider != AiProvider.ollama) {
      apiKey = await getApiKey(provider);
      if (provider != AiProvider.custom && (apiKey == null || apiKey.isEmpty)) {
        throw const AiKeyMissingException();
      }
    }
    final model = await resolveAndPersistSelectedModel(provider);

    final imageDataList = <String>[];
    if (images != null) {
      for (final img in images) {
        final bytes = await img.readAsBytes();
        imageDataList.add(await compute(base64Encode, bytes));
      }
    }

    switch (provider) {
      case AiProvider.openai:
        return _callOpenAiRaw(
          apiKey!,
          model,
          userContent,
          imageDataList,
          systemPrompt: systemPrompt,
          temperature: temperature,
        );
      case AiProvider.ollama:
        return _callOpenAiRaw(
          '',
          model,
          userContent,
          imageDataList,
          systemPrompt: systemPrompt,
          temperature: temperature,
          baseUrlOverride: 'http://localhost:11434/v1',
          provider: provider,
        );
      case AiProvider.custom:
        final customUrl = await getCustomBaseUrl();
        return _callOpenAiRaw(
          apiKey ?? '',
          model,
          userContent,
          imageDataList,
          systemPrompt: systemPrompt,
          temperature: temperature,
          baseUrlOverride: customUrl,
          provider: provider,
        );
      case AiProvider.gemini:
        return _callGeminiRaw(
          apiKey!,
          model,
          userContent,
          imageDataList,
          systemPrompt: systemPrompt,
          temperature: temperature,
        );
      case AiProvider.anthropic:
        return _callAnthropicRaw(
          apiKey!,
          model,
          userContent,
          imageDataList,
          systemPrompt: systemPrompt,
          temperature: temperature,
        );
      case AiProvider.mistral:
        return _callMistralRaw(
          apiKey!,
          model,
          userContent,
          imageDataList,
          systemPrompt: systemPrompt,
          temperature: temperature,
        );
      case AiProvider.xai:
        return _callXaiRaw(
          apiKey!,
          model,
          userContent,
          imageDataList,
          systemPrompt: systemPrompt,
          temperature: temperature,
        );
    }
  }
}
