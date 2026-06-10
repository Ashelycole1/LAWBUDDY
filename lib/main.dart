import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_service.dart';
import 'services/ai_service.dart';
import 'models/article_model.dart';
import 'screens/legal_views.dart';

// Global notifier for ThemeMode configuration
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load initial theme preference
  final prefs = await SharedPreferences.getInstance();
  final themeString = prefs.getString('theme_mode') ?? 'system';
  if (themeString == 'light') {
    themeModeNotifier.value = ThemeMode.light;
  } else if (themeString == 'dark') {
    themeModeNotifier.value = ThemeMode.dark;
  } else {
    themeModeNotifier.value = ThemeMode.system;
  }

  final dbService = DatabaseService();
  await dbService.init();
  
  runApp(LawBuddyApp(dbService: dbService));
}

class LawBuddyApp extends StatelessWidget {
  final DatabaseService dbService;

  const LawBuddyApp({super.key, required this.dbService});

  @override
  Widget build(BuildContext context) {
    final baseLightText = ThemeData.light().textTheme;
    final baseDarkText = ThemeData.dark().textTheme;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Law Buddy',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // Premium Light Theme
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            useMaterial3: true,
            textTheme: GoogleFonts.plusJakartaSansTextTheme(baseLightText).copyWith(
              displayLarge: GoogleFonts.lora(textStyle: baseLightText.displayLarge, color: Colors.black, fontWeight: FontWeight.bold),
              displayMedium: GoogleFonts.lora(textStyle: baseLightText.displayMedium, color: Colors.black, fontWeight: FontWeight.bold),
              headlineMedium: GoogleFonts.lora(textStyle: baseLightText.headlineMedium, color: Colors.black, fontWeight: FontWeight.bold),
              titleLarge: GoogleFonts.lora(textStyle: baseLightText.titleLarge, color: Colors.black, fontWeight: FontWeight.bold),
              titleMedium: GoogleFonts.plusJakartaSans(textStyle: baseLightText.titleMedium, color: Colors.black, fontWeight: FontWeight.w600),
              bodyLarge: GoogleFonts.plusJakartaSans(textStyle: baseLightText.bodyLarge, color: Colors.black87),
              bodyMedium: GoogleFonts.plusJakartaSans(textStyle: baseLightText.bodyMedium, color: Colors.black87),
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1C1C1E),
              secondary: Color(0xFFC87A53), // Terracotta
              surface: Colors.white,
              background: Color(0xFFF8F9FA),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Color(0xFF1C1C1E),
              onBackground: Color(0xFF1C1C1E),
              outlineVariant: Color(0xFFE5E5EA),
            ),
          ),
          // Premium Dark Theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F0F10), // Ultra dark slate
            useMaterial3: true,
            textTheme: GoogleFonts.plusJakartaSansTextTheme(baseDarkText).copyWith(
              displayLarge: GoogleFonts.lora(textStyle: baseDarkText.displayLarge, color: const Color(0xFFF2F2F7), fontWeight: FontWeight.bold),
              displayMedium: GoogleFonts.lora(textStyle: baseDarkText.displayMedium, color: const Color(0xFFF2F2F7), fontWeight: FontWeight.bold),
              headlineMedium: GoogleFonts.lora(textStyle: baseDarkText.headlineMedium, color: const Color(0xFFF2F2F7), fontWeight: FontWeight.bold),
              titleLarge: GoogleFonts.lora(textStyle: baseDarkText.titleLarge, color: const Color(0xFFF2F2F7), fontWeight: FontWeight.bold),
              titleMedium: GoogleFonts.plusJakartaSans(textStyle: baseDarkText.titleMedium, color: const Color(0xFFF2F2F7), fontWeight: FontWeight.w600),
              bodyLarge: GoogleFonts.plusJakartaSans(textStyle: baseDarkText.bodyLarge, color: const Color(0xFFE5E5EA)),
              bodyMedium: GoogleFonts.plusJakartaSans(textStyle: baseDarkText.bodyMedium, color: const Color(0xFFD1D1D6)),
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF2F2F7),
              secondary: Color(0xFFE59866), // Muted terracotta
              surface: Color(0xFF1C1C1E), // Elevated dark container
              background: Color(0xFF0F0F10),
              onPrimary: Color(0xFF1C1C1E),
              onSecondary: Color(0xFF1C1C1E),
              onSurface: Color(0xFFF2F2F7),
              onBackground: Color(0xFFF2F2F7),
              outlineVariant: Color(0xFF2C2C2E),
            ),
          ),
          home: HomeScreen(dbService: dbService),
        );
      },
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
      _messages.add({"role": "buddy", "text": ""});
      _isLoading = true;
    });
    _chatController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    final aiService = AIService(apiKey: apiKey, dbService: widget.dbService);

    final responseStream = aiService.askLegalQuestionStream(question);

    await for (final chunk in responseStream) {
      setState(() {
        _isLoading = false;
        _messages.last["text"] = _messages.last["text"]! + chunk;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  Future<void> _toggleTheme(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      await prefs.setString('theme_mode', 'light');
    } else if (mode == ThemeMode.dark) {
      await prefs.setString('theme_mode', 'dark');
    } else {
      await prefs.setString('theme_mode', 'system');
    }
    setState(() {}); // Re-render local components
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 850;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget mainContent;
    if (_currentIndex == 0) {
      mainContent = _buildLibraryTab(isDesktop, isDark);
    } else {
      mainContent = _buildChatTab(isDesktop, isDark);
    }

    if (isDesktop) {
      // Desktop Layout: Sidebar + Main Content
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(isDark),
            VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: mainContent,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile Layout: Floating Bottom Nav Bar
      return Scaffold(
        body: Stack(
          children: [
            mainContent,
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E).withOpacity(0.85) : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                        border: Border.all(
                          color: isDark ? const Color(0xFF2C2C2E) : Colors.white, 
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMobileNavItem(0, CupertinoIcons.book_fill, 'Library'),
                          const SizedBox(width: 12),
                          _buildMobileNavItem(1, CupertinoIcons.sparkles, 'AI Buddy'),
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
  }

  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.book, color: Theme.of(context).colorScheme.secondary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Law Buddy',
                style: GoogleFonts.lora(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _buildSidebarNavItem(0, CupertinoIcons.book_fill, 'Library'),
          const SizedBox(height: 10),
          _buildSidebarNavItem(1, CupertinoIcons.sparkles, 'AI Buddy'),
          const Spacer(),
          // Theme switch card
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F0F10) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildThemeToggleOption(ThemeMode.light, CupertinoIcons.sun_max_fill),
                _buildThemeToggleOption(ThemeMode.dark, CupertinoIcons.moon_fill),
                _buildThemeToggleOption(ThemeMode.system, CupertinoIcons.device_laptop),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ugandan Constitution\nEdition v1.0',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), 
              fontSize: 12, 
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggleOption(ThemeMode mode, IconData icon) {
    final isSelected = themeModeNotifier.value == mode;
    return GestureDetector(
      onTap: () => _toggleTheme(mode),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildSidebarNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? Theme.of(context).colorScheme.onSurface : const Color(0xFF8E8E93)),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Theme.of(context).colorScheme.onSurface : const Color(0xFF8E8E93),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 22, 
              color: isSelected ? Theme.of(context).colorScheme.onSurface : const Color(0xFF8E8E93),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Theme.of(context).colorScheme.onSurface : const Color(0xFF8E8E93),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryTab(bool isDesktop, bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          pinned: true,
          expandedHeight: isDesktop ? 100 : 130,
          elevation: 0,
          scrolledUnderElevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(left: isDesktop ? 24 : 20, bottom: 16),
            title: Text(
              'Library',
              style: GoogleFonts.lora(
                fontWeight: FontWeight.bold,
                fontSize: 32,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          actions: [
            // Mobile-only theme toggle button in AppBar
            if (!isDesktop)
              IconButton(
                icon: Icon(
                  isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {
                  _toggleTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                },
              ),
            Padding(
              padding: EdgeInsets.only(right: isDesktop ? 24 : 20, top: 10),
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Icon(CupertinoIcons.book, color: Theme.of(context).colorScheme.onSurface, size: 20),
                ),
              ),
            )
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 20.0, vertical: 10.0),
            child: CupertinoSearchTextField(
              controller: _searchController,
              onChanged: _onSearch,
              backgroundColor: Theme.of(context).colorScheme.surface,
              itemColor: const Color(0xFF8E8E93),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
              placeholder: 'Search rights, land, arrest...',
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_results.isEmpty && _searchController.text.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 20.0, bottom: isDesktop ? 40 : 120),
              child: _buildEmptyLibraryState(isDesktop),
            ),
          )
        else if (_results.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No results found.',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 17),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.only(bottom: isDesktop ? 40 : 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildResultCard(_results[index], isDesktop),
                childCount: _results.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyLibraryState(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 20),
          child: Text(
            'Suggested Reading',
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 20),
          child: const Text(
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
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12),
            children: [
              _buildBookCover('Personal Liberty', 'Article 23', const Color(0xFF4A90E2), 'Liberty & Freedom', Icons.person_off),
              _buildBookCover('Right to Fair Hearing', 'Article 28', Theme.of(context).colorScheme.secondary, 'Justice', Icons.balance),
              _buildBookCover('Land Ownership', 'Article 237', const Color(0xFF7DCEA0), 'Property', Icons.landscape),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 20),
          child: Text(
            'Quick Search Topics',
            style: GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 20),
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
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
              child: Icon(icon, size: 120, color: Colors.white.withOpacity(0.15)),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.lora(
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
                      color: Colors.white.withOpacity(0.2),
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface, 
            fontSize: 14, 
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(ArticleModel article, bool isDesktop) {
    return GestureDetector(
      onTap: () => Navigator.push(context, CupertinoPageRoute(
        builder: (_) => ArticleDetailScreen(article: article),
      )),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${article.type.toUpperCase()} ${article.number}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article.title,
              style: GoogleFonts.lora(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              article.simpleSummary.isNotEmpty ? article.simpleSummary : article.officialText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), 
                fontSize: 15, 
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab(bool isDesktop, bool isDark) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Buddy',
                    style: GoogleFonts.lora(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      if (!isDesktop)
                        IconButton(
                          icon: Icon(
                            isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () {
                            _toggleTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                          },
                        ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Icon(CupertinoIcons.sparkles, color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  )
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: isDesktop ? 24 : 120,
                ),
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
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Icon(
                              CupertinoIcons.book_fill, 
                              color: Theme.of(context).colorScheme.onSurface, 
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: isUser 
                                  ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFF1C1C1E))
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(isUser ? 20 : 4),
                                bottomRight: Radius.circular(isUser ? 4 : 20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            child: Text(
                              msg["text"]!,
                              style: TextStyle(
                                color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        if (isUser) const SizedBox(width: 40),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Floating Input Area
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: isDesktop ? 24 : 95,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          )
                        ]
                      ),
                      child: TextField(
                        controller: _chatController,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFF1C1C1E),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: _isLoading
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
