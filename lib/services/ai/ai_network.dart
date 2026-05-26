part of '../ai_service.dart';

extension AiNetwork on AiService {
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
    } catch (_) {}
    return null;
  }

  List<String> _geminiModelCandidates(String model) {
    final normalized = _normalizeGeminiModelId(model);
    final candidates = <String>[normalized];

    const aliasFallbacks = <String, List<String>>{
      'gemini-flash-latest': ['gemini-2.5-flash', 'gemini-2.0-flash'],
      'gemini-pro-latest': ['gemini-2.5-pro', 'gemini-1.5-pro'],
      'gemini-flash-lite-latest': ['gemini-2.5-flash-lite'],
    };
    final mapped = aliasFallbacks[normalized];
    if (mapped != null) candidates.addAll(mapped);

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
        final timeoutSeconds = await getAiTimeoutSeconds();
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(Duration(seconds: timeoutSeconds));

        if (response.statusCode == 200) return response;
        lastResponse = response;

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

  Future<String> _callAnthropicRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
    double temperature = 0.3,
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
      'temperature': temperature,
      'messages': [
        {'role': 'user', 'content': content},
      ],
    });

    try {
      final timeoutSeconds = await getAiTimeoutSeconds();
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
          .timeout(Duration(seconds: timeoutSeconds));
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

  Future<String> _callMistralRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
    double temperature = 0.3,
  }) {
    return _callOpenAiCompatibleRaw(
      endpoint: 'https://api.mistral.ai/v1/chat/completions',
      authHeader: 'Bearer $apiKey',
      model: model,
      userContent: userContent,
      imagesBase64: imagesBase64,
      systemPrompt: systemPrompt,
      temperature: temperature,
    );
  }

  Future<String> _callXaiRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
    double temperature = 0.3,
  }) {
    return _callOpenAiCompatibleRaw(
      endpoint: 'https://api.x.ai/v1/chat/completions',
      authHeader: 'Bearer $apiKey',
      model: model,
      userContent: userContent,
      imagesBase64: imagesBase64,
      systemPrompt: systemPrompt,
      temperature: temperature,
    );
  }

  Future<String> _callOpenAiCompatibleRaw({
    required String endpoint,
    required String authHeader,
    required String model,
    required String userContent,
    required List<String> imagesBase64,
    required String systemPrompt,
    double temperature = 0.3,
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
      'temperature': temperature,
    });

    try {
      final timeoutSeconds = await getAiTimeoutSeconds();
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': authHeader,
            },
            body: body,
          )
          .timeout(Duration(seconds: timeoutSeconds));
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
      case AiProvider.ollama:
      case AiProvider.custom:
        return null;
    }
  }

  Future<Set<String>?> _loadOpenAiModels(String apiKey) async {
    try {
      final timeoutSeconds = await getAiTimeoutSeconds();
      final response = await _httpGet(
        Uri.parse('https://api.openai.com/v1/models'),
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(Duration(seconds: timeoutSeconds));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? const [];
      final ids = data
          .map((e) => (e as Map<String, dynamic>)['id'] as String? ?? '')
          .where((id) => id.startsWith('gpt-'))
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
      final timeoutSeconds = await getAiTimeoutSeconds();
      final response = await _httpGet(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
        ),
      ).timeout(Duration(seconds: timeoutSeconds));
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
      final timeoutSeconds = await getAiTimeoutSeconds();
      final response = await _httpGet(
        Uri.parse('https://api.mistral.ai/v1/models'),
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(Duration(seconds: timeoutSeconds));
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
      final timeoutSeconds = await getAiTimeoutSeconds();
      final response = await _httpGet(
        Uri.parse('https://api.x.ai/v1/models'),
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(Duration(seconds: timeoutSeconds));
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
      final timeoutSeconds = await getAiTimeoutSeconds();
      final response = await _httpGet(
        Uri.parse('https://api.anthropic.com/v1/models'),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
      ).timeout(Duration(seconds: timeoutSeconds));
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

  Future<String> _callOpenAiRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
    double temperature = 0.3,
    String? baseUrlOverride,
    AiProvider provider = AiProvider.openai,
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
      'temperature': temperature,
    });

    final endpoint = baseUrlOverride != null && baseUrlOverride.isNotEmpty
        ? '${baseUrlOverride.replaceAll(RegExp(r'/+$'), '')}/chat/completions'
        : 'https://api.openai.com/v1/chat/completions';

    try {
      final timeoutSeconds = await getAiTimeoutSeconds();
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
            },
            body: body,
          )
          .timeout(Duration(seconds: timeoutSeconds));

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
    } on SocketException catch (e) {
      if (provider == AiProvider.ollama) {
        throw const AiNetworkException(
          'Ollama is offline. Please make sure the Ollama server is running at http://localhost:11434',
        );
      } else if (provider == AiProvider.custom) {
        throw const AiNetworkException(
          'Custom AI provider is offline. Please verify your Base URL and server status.',
        );
      }
      throw AiNetworkException('Network error: ${e.message}');
    } catch (e) {
      if (e is AiServiceException) rethrow;
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('connection refused') || errStr.contains('connection timed out')) {
        if (provider == AiProvider.ollama) {
          throw const AiNetworkException(
            'Ollama is offline. Please make sure the Ollama server is running at http://localhost:11434',
          );
        } else if (provider == AiProvider.custom) {
          throw const AiNetworkException(
            'Custom AI provider is offline. Please verify your Base URL and server status.',
          );
        }
      }
      throw AiNetworkException('Request failed: $e');
    }
  }

  Future<String> _callGeminiRaw(
    String apiKey,
    String model,
    String userContent,
    List<String> imagesBase64, {
    required String systemPrompt,
    double temperature = 0.3,
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
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': 8192,
      },
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

      final buffer = StringBuffer();
      for (final p in allParts) {
        final partMap = p as Map<String, dynamic>;
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
}
