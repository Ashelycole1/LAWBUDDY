import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/article_model.dart';

class ArticleDetailScreen extends StatelessWidget {
  final ArticleModel article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${article.type.toUpperCase()} ${article.number}',
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 30),
            if (article.simpleSummary.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(CupertinoIcons.info_circle_fill, color: Color(0xFFE59866), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'CITIZEN SUMMARY',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE59866),
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      article.simpleSummary,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
            
            const Text(
              'Official Text',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              article.officialText,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 18,
                height: 1.7,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class ProViewScreen extends StatefulWidget {
  final List<ArticleModel> allArticles;
  const ProViewScreen({super.key, required this.allArticles});

  @override
  State<ProViewScreen> createState() => _ProViewScreenState();
}

class _ProViewScreenState extends State<ProViewScreen> {
  ArticleModel? leftArticle;
  ArticleModel? rightArticle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PRO VIEW',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Row(
        children: [
          Expanded(child: _buildSelector(true)),
          Container(width: 1, color: const Color(0xFFE5E5EA)),
          Expanded(child: _buildSelector(false)),
        ],
      ),
    );
  }

  Widget _buildSelector(bool isLeft) {
    final selected = isLeft ? leftArticle : rightArticle;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5EA))),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ArticleModel>(
                value: selected,
                hint: const Text('Select Article', style: TextStyle(color: Color(0xFF8E8E93))),
                isExpanded: true,
                icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                items: widget.allArticles.map((a) {
                  return DropdownMenuItem(value: a, child: Text('Art ${a.number} - ${a.title}', overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (val) => setState(() {
                  if (isLeft) leftArticle = val; else rightArticle = val;
                }),
              ),
            ),
          ),
          if (selected != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  selected.officialText,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 16,
                    height: 1.6,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Icon(CupertinoIcons.book, size: 40, color: Color(0xFFE5E5EA)),
              ),
            )
        ],
      ),
    );
  }
}
