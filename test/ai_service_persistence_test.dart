import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/services/ai_service.dart';
import 'package:http/http.dart' as http;

class _InMemorySecureStorage extends FlutterSecureStorage {
  _InMemorySecureStorage();

  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _values.remove(key);
      return;
    }
    _values[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _values.remove(key);
  }
}

AiService _serviceWith({
  required FlutterSecureStorage storage,
  DynamicModelIdsLoader? dynamicModelIdsLoader,
  AiHttpGet? httpGet,
}) {
  return AiService.forTesting(
    secureStorage: storage,
    dynamicModelIdsLoader: dynamicModelIdsLoader,
    httpGet: httpGet,
  );
}

void main() {
  group('AiService provider persistence', () {
    test('setSelectedProvider persists and loads every provider', () async {
      final storage = _InMemorySecureStorage();
      final service = _serviceWith(storage: storage);

      for (final provider in AiProvider.values) {
        await service.setSelectedProvider(provider);
        expect(await service.getSelectedProvider(), provider);
      }
    });

    test('missing saved provider falls back to OpenAI', () async {
      final storage = _InMemorySecureStorage();
      final service = _serviceWith(storage: storage);

      expect(await service.getSelectedProvider(), AiProvider.openai);
    });

    test('invalid saved provider falls back to OpenAI', () async {
      final storage = _InMemorySecureStorage();
      final service = _serviceWith(storage: storage);
      await storage.write(
        key: AiService.selectedProviderStorageKey,
        value: 'not_a_provider',
      );

      expect(await service.getSelectedProvider(), AiProvider.openai);
    });
  });

  group('AiService model persistence and healing', () {
    test('missing saved model falls back to each provider default', () async {
      final storage = _InMemorySecureStorage();
      final service = _serviceWith(storage: storage);

      for (final provider in AiProvider.values) {
        final meta = service.getProviderMetadata(provider);
        expect(await service.getSelectedModel(provider), meta.defaultModel);
      }
    });

    test('setSelectedModel persists normalized model ids where applicable',
        () async {
      final storage = _InMemorySecureStorage();
      final service = _serviceWith(storage: storage);

      await service.setSelectedModel(AiProvider.openai, 'gpt-5.4-2026-03-01');
      await service.setSelectedModel(
        AiProvider.gemini,
        'models/gemini-flash-latest',
      );
      await service.setSelectedModel(AiProvider.anthropic, 'claude-opus-4-6');

      expect(await service.getSelectedModel(AiProvider.openai), 'gpt-5.4');
      expect(
        await service.getSelectedModel(AiProvider.gemini),
        'gemini-flash-latest',
      );
      expect(
        await service.getSelectedModel(AiProvider.anthropic),
        'claude-opus-4-6',
      );
    });

    test('stored valid model stays unchanged after resolve', () async {
      final storage = _InMemorySecureStorage();
      final service = _serviceWith(
        storage: storage,
        dynamicModelIdsLoader: (provider) async => switch (provider) {
          AiProvider.openai => {'gpt-5.4', 'gpt-4o'},
          _ => null,
        },
      );
      await service.setSelectedModel(AiProvider.openai, 'gpt-4o');

      final resolved =
          await service.resolveAndPersistSelectedModel(AiProvider.openai);

      expect(resolved, 'gpt-4o');
      expect(await service.getSelectedModel(AiProvider.openai), 'gpt-4o');
    });

    test('invalid saved model resolves to provider default when dynamic fails',
        () async {
      final storage = _InMemorySecureStorage();
      final service = _serviceWith(storage: storage);

      for (final provider in AiProvider.values) {
        await service.setSelectedModel(provider, 'totally-invalid-model');
        final resolved = await service.resolveAndPersistSelectedModel(provider);
        final meta = service.getProviderMetadata(provider);
        expect(resolved, meta.defaultModel);
        expect(await service.getSelectedModel(provider), meta.defaultModel);
      }
    });

    test('stale saved model is replaced when no longer dynamically supported',
        () async {
      final storage = _InMemorySecureStorage();
      final service = _serviceWith(
        storage: storage,
        dynamicModelIdsLoader: (provider) async => switch (provider) {
          AiProvider.openai => {'gpt-5.4', 'gpt-5.4-mini'},
          _ => null,
        },
      );
      await service.setSelectedModel(AiProvider.openai, 'gpt-4o');

      final resolved =
          await service.resolveAndPersistSelectedModel(AiProvider.openai);

      expect(resolved, 'gpt-5.4');
      expect(await service.getSelectedModel(AiProvider.openai), 'gpt-5.4');
    });

    test('saved model is isolated per provider', () async {
      final storage = _InMemorySecureStorage();
      final service = _serviceWith(storage: storage);
      await service.setSelectedModel(AiProvider.openai, 'gpt-4o');

      expect(await service.getSelectedModel(AiProvider.openai), 'gpt-4o');
      expect(
        await service.getSelectedModel(AiProvider.gemini),
        service.getProviderMetadata(AiProvider.gemini).defaultModel,
      );
    });

    test('changing provider resolves against that provider options', () async {
      final storage = _InMemorySecureStorage();
      final service = _serviceWith(
        storage: storage,
        dynamicModelIdsLoader: (provider) async => switch (provider) {
          AiProvider.openai => {'gpt-5.4', 'gpt-4o'},
          AiProvider.gemini => {'gemini-pro-latest', 'gemini-flash-latest'},
          _ => null,
        },
      );
      await service.setSelectedProvider(AiProvider.openai);
      await service.setSelectedModel(AiProvider.openai, 'gpt-4o');
      await service.setSelectedProvider(AiProvider.gemini);

      final resolvedGemini =
          await service.resolveAndPersistSelectedModel(AiProvider.gemini);

      expect(await service.getSelectedProvider(), AiProvider.gemini);
      expect(resolvedGemini, 'gemini-pro-latest');
      expect(resolvedGemini, isNot('gpt-4o'));
    });
  });

  group('AiService curated/allowed model options', () {
    late _InMemorySecureStorage storage;
    late AiService service;

    setUp(() async {
      storage = _InMemorySecureStorage();
      service = _serviceWith(
        storage: storage,
        httpGet: (uri, {headers}) async {
          if (uri.host == 'api.openai.com') {
            return http.Response(
              jsonEncode({
                'data': [
                  {'id': 'gpt-5.4-2026-03-01'},
                  {'id': 'gpt-4o'},
                  {'id': 'text-embedding-3-large'},
                  {'id': 'whisper-1'},
                ],
              }),
              200,
            );
          }
          if (uri.host == 'generativelanguage.googleapis.com') {
            return http.Response(
              jsonEncode({
                'models': [
                  {
                    'name': 'models/gemini-pro-latest',
                    'supportedGenerationMethods': ['generateContent'],
                  },
                  {
                    'name': 'models/gemini-1.5-pro-001',
                    'supportedGenerationMethods': ['batchEmbedContents'],
                  },
                  {
                    'name': 'models/gemini-flash-latest',
                    'supportedGenerationMethods': ['generateContent'],
                  },
                  {
                    'name': 'models/text-embedding-004',
                    'supportedGenerationMethods': ['generateContent'],
                  },
                ],
              }),
              200,
            );
          }
          if (uri.host == 'api.anthropic.com') {
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'id': 'claude-opus-4-6',
                    'capabilities': {
                      'image_input': {'supported': true},
                    },
                  },
                  {
                    'id': 'claude-3-haiku',
                    'capabilities': {
                      'image_input': {'supported': false},
                    },
                  },
                ],
              }),
              200,
            );
          }
          if (uri.host == 'api.mistral.ai') {
            return http.Response(
              jsonEncode({
                'data': [
                  {'id': 'mistral-large-3'},
                  {'id': 'pixtral-large-latest'},
                  {'id': 'codestral-latest'},
                ],
              }),
              200,
            );
          }
          if (uri.host == 'api.x.ai') {
            return http.Response(
              jsonEncode({
                'data': [
                  {'id': 'grok-4.20-0309-reasoning'},
                  {'id': 'grok-image-1-imagine'},
                  {'id': 'grok-4-vision-preview'},
                ],
              }),
              200,
            );
          }
          return http.Response('not found', 404);
        },
      );

      for (final provider in AiProvider.values) {
        await service.setApiKey(provider, 'test-key-${provider.name}');
      }
    });

    test('dynamic model lists are filtered and normalized per provider',
        () async {
      final openAiModels = await service.getModelOptions(AiProvider.openai);
      final geminiModels = await service.getModelOptions(AiProvider.gemini);
      final anthropicModels =
          await service.getModelOptions(AiProvider.anthropic);
      final mistralModels = await service.getModelOptions(AiProvider.mistral);
      final xaiModels = await service.getModelOptions(AiProvider.xai);

      expect(openAiModels.map((m) => m.id), contains('gpt-5.4'));
      expect(openAiModels.map((m) => m.id), contains('gpt-4o'));
      expect(
        openAiModels
            .any((m) => m.id.contains('embedding') || m.id == 'whisper-1'),
        isFalse,
      );

      expect(geminiModels.map((m) => m.id), contains('gemini-pro-latest'));
      expect(geminiModels.map((m) => m.id), contains('gemini-flash-latest'));
      expect(geminiModels.any((m) => m.id.startsWith('models/')), isFalse);
      expect(geminiModels.any((m) => m.id.contains('embedding')), isFalse);

      expect(anthropicModels.map((m) => m.id), contains('claude-opus-4-6'));
      expect(
          anthropicModels.map((m) => m.id), isNot(contains('claude-3-haiku')));

      expect(mistralModels.map((m) => m.id), contains('mistral-large-3'));
      expect(mistralModels.map((m) => m.id), contains('pixtral-large-latest'));
      expect(
          mistralModels.map((m) => m.id), isNot(contains('codestral-latest')));

      expect(xaiModels.map((m) => m.id), contains('grok-4.20-0309-reasoning'));
      expect(
          xaiModels.map((m) => m.id), isNot(contains('grok-image-1-imagine')));
    });

    test('dynamic loading failure uses conservative provider fallback',
        () async {
      final failingService = _serviceWith(
        storage: storage,
        httpGet: (uri, {headers}) async => http.Response('boom', 500),
      );

      for (final provider in AiProvider.values) {
        final options = await failingService.getModelOptions(provider);
        final meta = failingService.getProviderMetadata(provider);
        expect(options, isNotEmpty);
        expect(options.first.id, meta.defaultModel);
        expect(options.every((o) => o.isFallback), isTrue);
      }
    });
  });
}
