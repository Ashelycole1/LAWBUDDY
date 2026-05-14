import 'dart:convert';
import 'dart:io';

void main() async {
  const apiKey = "AIzaSyBezS0KLpc1noyhJK6NDbmMhFwG7KBBLo4";
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
        // Only show models that support generateContent
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
