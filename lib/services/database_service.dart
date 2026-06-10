import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/article_model.dart';

/// Web-compatible database service.
/// Loads the constitution JSON from assets into memory at startup.
/// No native DB — works on Flutter Web, Android, iOS & Desktop.
class DatabaseService {
  List<ArticleModel> _articles = [];

  Future<void> init() async {
    await _hydrate();
  }

  Future<void> _hydrate() async {
    final String response =
        await rootBundle.loadString('assets/data/constitution_enriched.json');
    final data = json.decode(response) as Map<String, dynamic>;

    final List<ArticleModel> allEntries = [];

    // --- Load Articles ---
    if (data['articles'] != null) {
      final articlesJson = data['articles'] as List;
      for (final j in articlesJson) {
        allEntries.add(ArticleModel(
          number: (j['number'] ?? '').toString(),
          title: (j['title'] ?? 'Untitled').toString(),
          officialText: (j['official_text'] ?? '').toString(),
          simpleSummary: (j['simple_summary'] ?? '').toString(),
          keywords: j['keywords'] != null
              ? List<String>.from(j['keywords'])
              : <String>[],
          chapter: (j['chapter'] ?? 'Unknown').toString(),
          type: (j['type'] ?? 'article').toString(),
        ));
      }
    }

    // --- Load National Objectives ---
    if (data['objectives'] != null) {
      final objectivesJson = data['objectives'] as List;
      for (final j in objectivesJson) {
        final id = (j['id'] ?? '').toString();
        final title = (j['title'] ?? 'Untitled').toString();
        allEntries.add(ArticleModel(
          number: 'Obj.$id',
          title: title,
          officialText: (j['official_text'] ?? '').toString(),
          simpleSummary: 'National Objective $id: $title',
          keywords: ['national objective', title.toLowerCase(), id],
          chapter: 'National Objectives',
          type: (j['type'] ?? 'objective').toString(),
        ));
      }
    }

    _articles = allEntries;
  }

  /// Keyword-based search across title, summary, full text and keywords
  Future<List<ArticleModel>> search(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final allArticles = await getAll();

    // Check if it's specifically asking for an article number
    final articleMatch = RegExp(r'article\s+(\d+)').firstMatch(cleanQuery);
    String? explicitArticleNumber = articleMatch?.group(1);

    // Ignore common stop words
    final stopWords = {
      'what', 'how', 'why', 'when', 'who', 'the', 'and', 'for',
      'with', 'that', 'this', 'have', 'been', 'should', 'does', 'say'
    };

    // Keep numbers and words > 2 chars
    final words = cleanQuery.split(' ').where((w) {
      if (stopWords.contains(w)) return false;
      if (w.length > 2) return true;
      if (int.tryParse(w) != null) return true;
      return false;
    }).toList();

    if (words.isEmpty) words.add(cleanQuery);

    final scored = allArticles.map((a) {
      int score = 0;
      final searchableText =
          '${a.title} ${a.simpleSummary} ${a.officialText} ${a.keywords.join(" ")}'
              .toLowerCase();

      // Explicit article number match gets massive boost
      if (explicitArticleNumber != null &&
          a.number == explicitArticleNumber &&
          a.type == 'article') {
        score += 500;
      }

      if (searchableText.contains(cleanQuery)) {
        score += 100;
      }

      for (final word in words) {
        if (searchableText.contains(word)) {
          score += 10;
        }
      }
      return {'article': a, 'score': score};
    }).where((map) => (map['score'] as int) > 0).toList();

    scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return scored.take(5).map((map) => map['article'] as ArticleModel).toList();
  }

  /// Get all articles for browsing
  Future<List<ArticleModel>> getAll() async {
    return List.unmodifiable(_articles);
  }

  /// Get a single article by number (e.g. "23")
  Future<ArticleModel?> getByNumber(String number) async {
    try {
      return _articles.firstWhere((a) => a.number == number);
    } catch (_) {
      return null;
    }
  }
}
