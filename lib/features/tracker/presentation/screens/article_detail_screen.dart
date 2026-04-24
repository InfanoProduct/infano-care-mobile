import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Map<String, String> article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<LocalStorageService>(context);
    final isSaved = storage.isArticleSaved(article['title'] ?? '');

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, isSaved, storage),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryPill(),
                  const SizedBox(height: 16),
                  _buildTitle(),
                  const SizedBox(height: 24),
                  _buildDoctorReviewCard(),
                  const SizedBox(height: 32),
                  _buildContent(),
                  const SizedBox(height: 48),
                  _buildActionButtons(context, isSaved, storage),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isSaved, LocalStorageService storage) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.purple,
      leading: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.3),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.3),
          child: IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => _shareArticle(article),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.3),
          child: IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border, 
              color: isSaved ? const Color(0xFFFACC15) : Colors.white
            ),
            onPressed: () => _toggleSave(context, storage),
          ),
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'article_${article['title']}',
          child: Container(
            color: AppColors.purpleLight.withOpacity(0.2),
            child: Center(
              child: Text(article['emoji'] ?? '📖', style: const TextStyle(fontSize: 100)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'HEALTH & WELLNESS',
        style: GoogleFonts.nunito(
          color: AppColors.purple,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildTitle() {
    return Text(
      article['title'] ?? 'Article Title',
      style: GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: AppColors.textDark,
        height: 1.2,
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDoctorReviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.purpleLight,
            child: Text('👩‍⚕️', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reviewed by Dr. Sarah Jenkins',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textDark),
                ),
                Text(
                  'OB-GYN, 12+ years experience',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified, color: Colors.blue, size: 20),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildContent() {
    return Text(
      'Managing your health during different cycle phases is crucial for overall well-being. This article explores practical tips and expert advice tailored for you.\n\n'
      'Proper nutrition and gentle exercise can significantly reduce discomfort and boost your energy levels. Research suggests that aligning your diet with your hormones leads to better results.\n\n'
      'Whether it is iron-rich foods during your period or high-intensity workouts during your follicular phase, understanding these patterns helps you live in harmony with your body.\n\n'
      'Always consult with your healthcare provider before making significant changes to your health routine.',
      style: GoogleFonts.nunito(
        fontSize: 16,
        height: 1.8,
        color: AppColors.textDark.withOpacity(0.8),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildActionButtons(BuildContext context, bool isSaved, LocalStorageService storage) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _toggleSave(context, storage),
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_add_outlined),
            label: Text(isSaved ? 'Saved to Library' : 'Save to Library'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSaved ? const Color(0xFF10B981) : AppColors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textDark),
            onPressed: () => _shareArticle(article),
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Future<void> _shareArticle(Map<String, String> article) async {
    final title = article['title'] ?? 'Interesting Health Article';
    final articleId = title.toLowerCase().replaceAll(' ', '-');
    final shareUrl = 'https://infano.care/articles/$articleId';
    
    final text = 'Check out this article on Infano.Care: "$title"\n\nRead more here: $shareUrl\n\nDownload Infano.Care for a personalized health journey! 🌸';

    try {
      // To show a thumbnail immediately in apps like WhatsApp without a live website,
      // we share the actual image file along with the text.
      
      // 1. Load the brand logo from assets
      final byteData = await rootBundle.load('assets/logo_padded.png');
      
      // 2. Save to a temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/shared_article_thumb.png');
      await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

      // 3. Share the file + text
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: title,
      );
    } catch (e) {
      await Share.share(text, subject: title);
    }
  }

  void _toggleSave(BuildContext context, LocalStorageService storage) {
    final title = article['title'] ?? '';
    storage.toggleSavedArticle(title);
    
    final isNowSaved = storage.isArticleSaved(title);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isNowSaved ? 'Article saved to your library! ✨' : 'Article removed from library'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: isNowSaved ? const Color(0xFF10B981) : AppColors.textDark,
      ),
    );
  }
}
