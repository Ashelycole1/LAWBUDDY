import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/article_model.dart';
import 'database_service.dart';

class AIService {
  final String apiKey;
  final DatabaseService dbService;
  late GenerativeModel model;

  AIService({required this.apiKey, required this.dbService}) {
    model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  /// The RAG (Retrieval-Augmented Generation) Pipeline - STREAMING
  Stream<String> askLegalQuestionStream(String question) async* {
    // 1. Retrieve relevant articles from in-memory DB
    final List<ArticleModel> contextArticles = await dbService.search(question);
    
    if (contextArticles.isEmpty) {
      yield "I couldn't find specific articles related to that in the Constitution. Please try rephrasing.";
      return;
    }

    // 2. Construct the context string
    final contextText = contextArticles.map((a) => 
      "Article ${a.number}: ${a.title}\nText: ${a.officialText}\nSummary: ${a.simpleSummary}"
    ).join("\n\n");

    // 3. Build the System Prompt
    final prompt = [
      Content.text('''
You are "Law Buddy," a premium expert legal assistant for the Ugandan Constitution and general legal rights.
Your primary goal is to explain the law simply, accurately, and empathetically.

CRITICAL RULES:
1. Always base your primary answer on the provided Constitution text below if it's relevant.
2. If the user asks a general legal question that isn't specifically in the Constitution, you MAY use your general AI knowledge, but clarify that it is general legal knowledge and not explicitly stated in the 1995 Constitution.
3. If you use the provided context, cite the Article numbers in your response.
4. ABSOLUTELY NO MARKDOWN. Do not use asterisks (*). Do not use bolding. Use standard plain text with simple dashes (-) for bullet points.
5. AT THE END of every response, you MUST append this exact legal disclaimer on a new line:
"Disclaimer: This is AI-generated advice based on the Constitution and general knowledge. It does not constitute formal legal counsel. Please consult a qualified attorney for specific legal issues."

CONSTITUTION CONTEXT:
$contextText

USER QUESTION:
$question
''')
    ];

    // 4. Generate Streaming Response
    try {
      final responseStream = model.generateContentStream(prompt);
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          // Strip any markdown asterisks that the AI might forcefully include
          yield chunk.text!.replaceAll('*', '');
        }
      }
    } catch (e) {
      yield "Error connecting to AI: $e";
    }
  }
}
