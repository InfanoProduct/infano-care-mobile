import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/article_detail_screen.dart';

class AllArticlesScreen extends StatefulWidget {
  final List<Map<String, String>>? articles;

  const AllArticlesScreen({super.key, this.articles});

  @override
  State<AllArticlesScreen> createState() => _AllArticlesScreenState();
}

class _LearnHubArticleGrid extends StatelessWidget {
  final List<dynamic> articles;

  const _LearnHubArticleGrid({required this.articles});

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No articles in this category.',
            style: GoogleFonts.nunito(
              color: AppColors.textMedium,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final art = articles[index];

        final backgrounds = [
          const Color(0xFFEEF2FF), // Soft Indigo
          const Color(0xFFFDF2F8), // Soft Pink
          const Color(0xFFECFDF5), // Soft Mint
          const Color(0xFFFFFBEB), // Soft Amber
          const Color(0xFFF5F3FF), // Soft Violet
        ];
        
        final borders = [
          const Color(0xFFC7D2FE),
          const Color(0xFFFBCFE8),
          const Color(0xFFA7F3D0),
          const Color(0xFFFDE68A),
          const Color(0xFFDDD6FE),
        ];

        final colorIndex = index % backgrounds.length;
        final bgColor = backgrounds[colorIndex];
        final borderColor = borders[colorIndex];

        final title = art['title']?.toString() ?? '';
        final emoji = art['emoji']?.toString() ?? '📖';
        final readTime = (art['readTime'] ?? art['time'] ?? '3 min read').toString();

        return GestureDetector(
          onTap: () {
            // Map the API fields to the format expected by ArticleDetailScreen
            final Map<String, String> mappedArt = {
              'title': title,
              'emoji': emoji,
              'time': readTime,
              'phase': (art['phase'] ?? '').toString(),
            };
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArticleDetailScreen(article: mappedArt),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: Colors.white.withValues(alpha: 0.4),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: AppColors.textMedium,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            readTime,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AllArticlesScreenState extends State<AllArticlesScreen> {
  bool _isLoading = true;
  List<dynamic> _loadedArticles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.articles != null && widget.articles!.isNotEmpty) {
      _loadedArticles = widget.articles!;
      _isLoading = false;
    } else {
      _fetchArticles();
    }
  }

  Future<void> _fetchArticles() async {
    try {
      final response = await ApiService.instance.dio.get('tracker/articles');
      if (mounted) {
        setState(() {
          _loadedArticles = response.data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[AllArticlesScreen] Error fetching articles: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load articles.';
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> _getArticlesForPhase(String phase) {
    return _loadedArticles.where((a) {
      final String p = (a['phase'] ?? '').toString().toLowerCase();
      if (phase == 'general') {
        return p == 'waiting' || p == 'delayed' || p == 'general' || p.isEmpty;
      }
      return p == phase;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Good to Know 📖',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 18),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Good to Know 📖',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 18),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error!, style: GoogleFonts.nunito(color: AppColors.error, fontSize: 15)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _fetchArticles();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F4F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Good to Know 📖',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              fontSize: 18,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.purple,
            unselectedLabelColor: AppColors.textMedium,
            indicatorColor: AppColors.purple,
            labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.nunito(fontSize: 13),
            tabs: const [
              Tab(text: 'Period'),
              Tab(text: 'Follicular'),
              Tab(text: 'Ovulation'),
              Tab(text: 'Luteal'),
              Tab(text: 'General'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LearnHubArticleGrid(articles: _getArticlesForPhase('menstrual')),
            _LearnHubArticleGrid(articles: _getArticlesForPhase('follicular')),
            _LearnHubArticleGrid(articles: _getArticlesForPhase('ovulation')),
            _LearnHubArticleGrid(articles: _getArticlesForPhase('luteal')),
            _LearnHubArticleGrid(articles: _getArticlesForPhase('general')),
          ],
        ),
      ),
    );
  }
}
