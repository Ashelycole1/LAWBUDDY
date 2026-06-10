import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/article_model.dart';

class ArticleDetailScreen extends StatelessWidget {
  final ArticleModel article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${article.type.toUpperCase()} ${article.number}',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF8E8E93),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: GoogleFonts.lora(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 30),
                if (article.simpleSummary.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F0F10) : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(CupertinoIcons.info_circle_fill, color: Theme.of(context).colorScheme.secondary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'CITIZEN SUMMARY',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 12,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          article.simpleSummary,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            height: 1.6,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
                
                Text(
                  'Official Text',
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  article.officialText,
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    height: 1.7,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PRO COMPARISON VIEW',
          style: GoogleFonts.plusJakartaSans(
            color: Theme.of(context).colorScheme.onSurface, 
            fontWeight: FontWeight.bold, 
            fontSize: 16,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
      ),
      body: Row(
        children: [
          Expanded(child: _buildSelector(true, isDark)),
          Container(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
          Expanded(child: _buildSelector(false, isDark)),
        ],
      ),
    );
  }

  Widget _buildSelector(bool isLeft, bool isDark) {
    final selected = isLeft ? leftArticle : rightArticle;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ArticleModel>(
                value: selected,
                dropdownColor: Theme.of(context).colorScheme.surface,
                hint: Text(
                  'Select Article',
                  style: GoogleFonts.plusJakartaSans(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), 
                    fontSize: 15,
                  ),
                ),
                isExpanded: true,
                icon: Icon(CupertinoIcons.chevron_down, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                items: widget.allArticles.map((a) {
                  return DropdownMenuItem(
                    value: a,
                    child: Text(
                      'Art ${a.number} - ${a.title}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, 
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected.title,
                      style: GoogleFonts.lora(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selected.officialText,
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        height: 1.65,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Icon(
                  CupertinoIcons.book, 
                  size: 48, 
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                ),
              ),
            )
        ],
      ),
    );
  }
}
