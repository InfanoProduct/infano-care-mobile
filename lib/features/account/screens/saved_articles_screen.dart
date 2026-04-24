import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/article_detail_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SavedArticlesScreen extends StatelessWidget {
  const SavedArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<LocalStorageService>(context);
    final savedTitles = storage.savedArticles;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F7),
      appBar: AppBar(
        title: Text('Your Library', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: AppColors.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: savedTitles.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: savedTitles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final title = savedTitles[index];
                return _buildSavedArticleCard(context, title, storage);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📚', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(
            'Your library is empty',
            style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Articles you save will appear here for quick access later.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMedium),
            ),
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildSavedArticleCard(BuildContext context, String title, LocalStorageService storage) {
    // In a real app, you'd fetch the article data by ID/Title.
    // For now, we'll recreate a simple map.
    final article = {'title': title, 'emoji': '📖', 'time': '4 min read'};

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('📖', style: TextStyle(fontSize: 24))),
        ),
        title: Text(
          title,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 15),
        ),
        subtitle: Text('Article · 4 min read', style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.bookmark, color: Color(0xFFFACC15)),
          onPressed: () => storage.toggleSavedArticle(title),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
          );
        },
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
