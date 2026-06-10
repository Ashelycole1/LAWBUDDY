import 'dart:convert';
import 'dart:io';

void main() async {
  // API key is injected via --dart-define=GEMINI_API_KEY=...
  // Never hardcode secrets here.
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');

  if (apiKey.isEmpty) {
    print('Error: GEMINI_API_KEY not set. Run with --dart-define=GEMINI_API_KEY=YOUR_KEY');
    exit(1);
  }

  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  
  try {
    final request = await HttpClient().getUrl(url);
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = json.decode(responseBody);
      final models = data['models'] as List;
      
      print('Available Models:');
      for (var model in models) {
        final methods = model['supportedGenerationMethods'] as List?;
        if (methods != null && methods.contains('generateContent')) {
          print('- ${model['name']}');
        }
      }
    } else {
      print('Failed to list models. Status Code: ${response.statusCode}');
      final responseBody = await response.transform(utf8.decoder).join();
      print(responseBody);
    }
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
