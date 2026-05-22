part of '../ai_service.dart';

extension AiParsing on AiService {
  /// Extracts the meal candidate (holistic context and items) from the AI response.
  AiMealCandidate _parseMealCandidateFromContent(String content) {
    var cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      cleaned = cleaned.trim();
    }

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        final contextMap = decoded['mealContext'];
        final AiMealContext? mealContext = contextMap != null && contextMap is Map<String, dynamic>
            ? AiMealContext.fromJson(contextMap)
            : null;

        final rawItems = decoded['items'];
        if (rawItems is List) {
          final items = rawItems
              .map((e) => AiMealCandidateItem(
                    name: (e['name'] as String?) ?? '',
                    grams: (e['estimatedGrams'] as num?)?.toInt() ?? 0,
                    confidence: (e['confidence'] as num?)?.toDouble(),
                    stateHint: e['stateHint'] as String?,
                  ))
              .toList();
          return AiMealCandidate(
            context: mealContext,
            items: items,
          );
        }
      }

      if (decoded is List) {
        final items = decoded
            .map((e) => AiMealCandidateItem(
                  name: (e['name'] as String?) ?? '',
                  grams: (e['estimatedGrams'] as num?)?.toInt() ?? 0,
                  confidence: (e['confidence'] as num?)?.toDouble(),
                  stateHint: e['stateHint'] as String?,
                ))
            .toList();
        return AiMealCandidate(items: items);
      }
    } catch (_) {}

    final startBracket = cleaned.indexOf('{');
    final endBracket = cleaned.lastIndexOf('}');
    if (startBracket != -1 && endBracket != -1 && endBracket > startBracket) {
      try {
        final jsonStr = cleaned.substring(startBracket, endBracket + 1);
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final contextMap = decoded['mealContext'];
        final AiMealContext? mealContext = contextMap != null && contextMap is Map<String, dynamic>
            ? AiMealContext.fromJson(contextMap)
            : null;

        final rawItems = decoded['items'];
        if (rawItems is List) {
          final items = rawItems
              .map((e) => AiMealCandidateItem(
                    name: (e['name'] as String?) ?? '',
                    grams: (e['estimatedGrams'] as num?)?.toInt() ?? 0,
                    confidence: (e['confidence'] as num?)?.toDouble(),
                    stateHint: e['stateHint'] as String?,
                  ))
              .toList();
          return AiMealCandidate(
            context: mealContext,
            items: items,
          );
        }
      } catch (_) {}
    }

    final startArray = cleaned.indexOf('[');
    final endArray = cleaned.lastIndexOf(']');
    if (startArray != -1 && endArray != -1 && endArray > startArray) {
      try {
        final jsonStr = cleaned.substring(startArray, endArray + 1);
        final List<dynamic> itemsList = jsonDecode(jsonStr) as List<dynamic>;
        final items = itemsList
            .map((e) => AiMealCandidateItem(
                  name: (e['name'] as String?) ?? '',
                  grams: (e['estimatedGrams'] as num?)?.toInt() ?? 0,
                  confidence: (e['confidence'] as num?)?.toDouble(),
                  stateHint: e['stateHint'] as String?,
                ))
            .toList();
        return AiMealCandidate(items: items);
      } catch (_) {}
    }

    throw const AiParseException('No valid JSON object or array found in response.');
  }

  /// Extracts the JSON array from the AI response text.
  List<AiSuggestedItem> _parseItemsFromContent(String content) {
    var cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      cleaned = cleaned.trim();
    }

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
}
