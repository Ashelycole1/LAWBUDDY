import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/article_model.dart';

class DatabaseService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ArticleModelSchema],
      directory: dir.path,
    );

    // Hydrate database if empty
    if (await isar.articleModels.count() == 0) {
      await _hydrate();
    }
  }

  Future<void> _hydrate() async {
    final String response =
        await rootBundle.loadString('assets/data/constitution_enriched.json');
    final data = json.decode(response) as Map<String, dynamic>;

    final List<ArticleModel> allEntries = [];

    // --- Load Articles ---
    if (data['articles'] != null) {
      final articlesJson = data['articles'] as List;
      final articles = articlesJson.map((j) {
        return ArticleModel()
          ..number = (j['number'] ?? '').toString()
          ..title = (j['title'] ?? 'Untitled').toString()
          ..officialText = (j['official_text'] ?? '').toString()
          ..simpleSummary = (j['simple_summary'] ?? '').toString()
          ..keywords = j['keywords'] != null
              ? List<String>.from(j['keywords'])
              : <String>[]
          ..chapter = (j['chapter'] ?? 'Unknown').toString()
          ..type = (j['type'] ?? 'article').toString();
      }).toList();
      allEntries.addAll(articles);
    }

    // --- Load National Objectives ---
    if (data['objectives'] != null) {
      final objectivesJson = data['objectives'] as List;
      final objectives = objectivesJson.map((j) {
        final id = (j['id'] ?? '').toString();
        final title = (j['title'] ?? 'Untitled').toString();
        return ArticleModel()
          ..number = 'Obj.$id'
          ..title = title
          ..officialText = (j['official_text'] ?? '').toString()
          ..simpleSummary = 'National Objective $id: $title'
          ..keywords = ['national objective', title.toLowerCase(), id]
          ..chapter = 'National Objectives'
          ..type = (j['type'] ?? 'objective').toString();
      }).toList();
      allEntries.addAll(objectives);
    }

    await isar.writeTxn(() async {
      await isar.articleModels.putAll(allEntries);
    });
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
    final stopWords = {'what', 'how', 'why', 'when', 'who', 'the', 'and', 'for', 'with', 'that', 'this', 'have', 'been', 'should', 'does', 'say'};
    
    // Keep numbers and words > 2 chars
    final words = cleanQuery.split(' ').where((w) {
      if (stopWords.contains(w)) return false;
      if (w.length > 2) return true;
      if (int.tryParse(w) != null) return true; // keep numbers like "53"
      return false;
    }).toList();
    
    if (words.isEmpty) words.add(cleanQuery);

    final scored = allArticles.map((a) {
      int score = 0;
      final searchableText = '${a.title} ${a.simpleSummary} ${a.officialText} ${a.keywords.join(" ")}'.toLowerCase();
      
      // Explicit article number match gets massive boost
      if (explicitArticleNumber != null && a.number == explicitArticleNumber && a.type == 'article') {
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

  /// Get all articles for chapter browsing
  Future<List<ArticleModel>> getAll() async {
    return await isar.articleModels.where().findAll();
  }

  /// Get a single article by number (e.g. "23")
  Future<ArticleModel?> getByNumber(String number) async {
    return await isar.articleModels
        .filter()
        .numberEqualTo(number)
        .findFirst();
  }
}
