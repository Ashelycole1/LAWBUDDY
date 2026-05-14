import 'package:isar/isar.dart';

part 'article_model.g.dart';

@collection
class ArticleModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String number;

  late String title;
  
  late String officialText;
  
  late String simpleSummary;
  
  late List<String> keywords;
  
  late String chapter;
  
  @Index(type: IndexType.value)
  late String type; // "article", "objective", "schedule"
}
