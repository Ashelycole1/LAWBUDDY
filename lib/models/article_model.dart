/// A plain Dart model for a constitution article/objective.
/// No native DB annotations — works on web, mobile and desktop.
class ArticleModel {
  final String number;
  final String title;
  final String officialText;
  final String simpleSummary;
  final List<String> keywords;
  final String chapter;
  final String type; // "article", "objective", "schedule"

  ArticleModel({
    required this.number,
    required this.title,
    required this.officialText,
    required this.simpleSummary,
    required this.keywords,
    required this.chapter,
    required this.type,
  });
}
