import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/article_detail_screen.dart';

class AllArticlesScreen extends StatelessWidget {
  final List<Map<String, String>> articles;

  const AllArticlesScreen({super.key, required this.articles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
      ),
      body: articles.isEmpty
          ? Center(
              child: Text(
                'No articles available.',
                style: GoogleFonts.nunito(
                  color: AppColors.textMedium,
                  fontSize: 14,
                ),
              ),
            )
          : GridView.builder(
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

                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailScreen(article: art),
                    ),
                  ),
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
                                  art['emoji'] ?? '📖',
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
                                art['title'] ?? '',
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
                                    art['time'] ?? '3 min read',
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
            ),
    );
  }
}
