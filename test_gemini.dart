import 'dart:convert';
import 'dart:io';

void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('No GEMINI_API_KEY found in environment');
    return;
  }

  final body = jsonEncode({
    'contents': [
      {
        'parts': [
          {
            'text':
                'Generate a meal recommendation for a fast lunch. Return ONLY JSON with meal_name, description, ingredients (name, amount_in_grams).',
          },
        ],
      },
    ],
    'generationConfig': {
      'temperature': 0.7,
      'maxOutputTokens': 2000,
      'responseMimeType': 'application/json',
    },
  });

  try {
    final client = HttpClient();
    final request = await client.postUrl(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
      ),
    );
    request.headers.set('Content-Type', 'application/json');
    request.write(body);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    print('STATUS: ${response.statusCode}');
    print('BODY: $responseBody');
  } catch (e) {
    print('Error: $e');
  }
}
