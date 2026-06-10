import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'services/database_service.dart';
import 'services/ai_service.dart';
import 'models/article_model.dart';
import 'screens/legal_views.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbService = DatabaseService();
  await dbService.init();
  runApp(LawBuddyApp(dbService: dbService));
}

class LawBuddyApp extends StatelessWidget {
  final DatabaseService dbService;

  const LawBuddyApp({super.key, required this.dbService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Law Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7), // Apple's default light grey background
        fontFamily: '.SF Pro Display', // Apple system sans-serif
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF000000), // Pure black for text/accents
          secondary: Color(0xFFE59866), // Subtle warm orange/gold accent (like Apple Books)
          surface: Colors.white, 
          background: Color(0xFFF2F2F7),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Georgia', color: Colors.black, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontFamily: 'Georgia', color: Colors.black, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontFamily: 'Georgia', color: Colors.black, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontFamily: 'Georgia', color: Colors.black, fontWeight: FontWeight.bold),
        )
      ),
      home: HomeScreen(dbService: dbService),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final DatabaseService dbService;
  const HomeScreen({super.key, required this.dbService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Start on Library/Home

  List<ArticleModel> _results = [];
  final _searchController = TextEditingController();
  final _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, String>> _messages = [
    {
      "role": "buddy",
      "text": "Hello! I am your AI Law Buddy.\n\nI can answer any questions based on the 1995 Constitution of Uganda. Try asking:\n\n• What are my rights if I'm arrested?\n• Who can own land in Uganda?"
    }
  ];
  
  bool _isLoading = false;

  void _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    final results = await widget.dbService.search(query);
    setState(() => _results = results);
  }

  void _onChat(String question) async {
    if (question.trim().isEmpty) return;
    setState(() {
      _messages.add({"role": "user", "text": question});
      _messages.add({"role": "buddy", "text": ""}); // Placeholder for the stream
      _isLoading = true;
    });
    _chatController.clear();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, 
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    
    // API key injected at build time via --dart-define=GEMINI_API_KEY=...
    // For Vercel: set GEMINI_API_KEY as an Environment Variable in the dashboard.
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    final aiService = AIService(apiKey: apiKey, dbService: widget.dbService);
    
    final responseStream = aiService.askLegalQuestionStream(question);
    
    await for (final chunk in responseStream) {
      setState(() {
        _isLoading = false;
        // Append streamed text directly to the last message
        _messages.last["text"] = _messages.last["text"]! + chunk;
      });
      // Gently scroll to bottom as it streams
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              _buildLibraryTab(),
              _buildChatTab(),
            ],
          ),
          // Floating Bottom Navigation Bar (Apple Books style)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNavItem(0, CupertinoIcons.book_fill, 'Library'),
                        const SizedBox(width: 8),
                        _buildNavItem(1, CupertinoIcons.sparkles, 'AI Buddy'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5E5EA) : Colors.transparent, // Very subtle grey for selected
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: isSelected ? Colors.black : const Color(0xFF8E8E93)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.black : const Color(0xFF8E8E93),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFFF2F2F7),
          pinned: true,
          expandedHeight: 140,
          elevation: 0,
          flexibleSpace: const FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(left: 20, bottom: 16),
            title: Text(
              'Library',
              style: TextStyle(
                fontFamily: 'Georgia', // Serif font for Apple Books feel
                fontWeight: FontWeight.bold, 
                fontSize: 34, 
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20, top: 10),
              child: GestureDetector(
                onTap: () async {
                  final all = await widget.dbService.getAll();
                  if (mounted) {
                    Navigator.push(context, CupertinoPageRoute(
                      builder: (_) => ProViewScreen(allArticles: all),
                    ));
                  }
                },
                child: Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.book, color: Colors.black, size: 20),
                ),
              ),
            )
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: CupertinoSearchTextField(
              controller: _searchController,
              onChanged: _onSearch,
              backgroundColor: Colors.white,
              itemColor: const Color(0xFF8E8E93),
              style: const TextStyle(color: Colors.black, fontSize: 16),
              placeholder: 'Search rights, land, arrest...',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_results.isEmpty && _searchController.text.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 120),
              child: _buildEmptyLibraryState(),
            ),
          )
        else if (_results.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('No results found.', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 17)),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildResultCard(_results[index]),
                childCount: _results.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyLibraryState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Suggested Reading',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Explore key articles from the Constitution.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 280,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildBookCover('Personal Liberty', 'Article 23', const Color(0xFF4A90E2), 'Liberty & Freedom', Icons.person_off),
              _buildBookCover('Right to Fair Hearing', 'Article 28', const Color(0xFFE59866), 'Justice', Icons.balance),
              _buildBookCover('Land Ownership', 'Article 237', const Color(0xFF7DCEA0), 'Property', Icons.landscape),
            ],
          ),
        ),
        const SizedBox(height: 40),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Quick Search Topics',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildPillChip('Arrest'),
              _buildPillChip('Elections'),
              _buildPillChip('President'),
              _buildPillChip('Parliament'),
              _buildPillChip('Human Rights'),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildBookCover(String title, String subtitle, Color color, String category, IconData icon) {
    return GestureDetector(
      onTap: () {
        _searchController.text = subtitle;
        _onSearch(subtitle);
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(icon, size: 120, color: Colors.white.withValues(alpha: 0.15)),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toUpperCase(),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillChip(String label) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        _onSearch(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E5EA)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildResultCard(ArticleModel article) {
    return GestureDetector(
      onTap: () => Navigator.push(context, CupertinoPageRoute(
        builder: (_) => ArticleDetailScreen(article: article),
      )),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${article.type.toUpperCase()} ${article.number}',
              style: const TextStyle(color: Color(0xFFE59866), fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            Text(
              article.title,
              style: const TextStyle(fontFamily: 'Georgia', color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              article.simpleSummary.isNotEmpty ? article.simpleSummary : article.officialText,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 15, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AI Buddy',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.sparkles, color: Color(0xFFE59866)),
                )
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120), // Padding for floating nav
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isUser) ...[
                        Container(
                          width: 30, height: 30,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(CupertinoIcons.book_fill, color: Colors.black, size: 16),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: isUser ? const Color(0xFF007AFF) : Colors.white, // Apple blue for user
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isUser ? 20 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: Text(
                            msg["text"]!,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      if (isUser) const SizedBox(width: 38), // Balance for avatar
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Floating Input Area (placed above bottom nav bar)
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF2F2F7).withValues(alpha: 0.0),
                  const Color(0xFFF2F2F7),
                ],
                stops: const [0.0, 0.3],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, -2))
                      ]
                    ),
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Ask a legal question...',
                        hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _onChat,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _onChat(_chatController.text),
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF007AFF), // Apple Blue
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading 
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 20, weight: 800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
