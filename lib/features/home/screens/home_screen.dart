import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _buildWelcomeBanner(context),
        const SizedBox(height: 20),
        _buildJournalCard(context),
        const SizedBox(height: 16),
        _buildQuickActionRow(context),
        const SizedBox(height: 24),
        Text('Your Space 🌸',
          style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 12),
        _buildFeatureGrid(context),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome back! 🌟', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Your journey, your power.', style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70)),
        ])),
        const Text('🌸', style: TextStyle(fontSize: 52))
            .animate(onPlay: (c) => c.repeat())
            .scaleXY(begin: 0.9, end: 1.1, duration: 2000.ms, curve: Curves.easeInOut)
            .then().scaleXY(begin: 1.1, end: 0.9, duration: 2000.ms),
      ]),
    );
  }

  Widget _buildJournalCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/journal'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('📖 My Journal', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 10),
              Text('How are you feeling today?',
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text('Tap to write, doodle, record, or just drop a mood.',
                style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMedium, height: 1.3)),
              const SizedBox(height: 12),
              Wrap(spacing: 6, children: const ['✏️', '🎨', '🎤', '🌈', '✨', '📸', '💌']
                  .map((e) => Text(e, style: const TextStyle(fontSize: 20))).toList()),
            ]),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
          ),
        ]),
      )
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .tint(color: AppColors.purple.withValues(alpha: 0.0), duration: 3000.ms)
      .then()
      .tint(color: AppColors.purple.withValues(alpha: 0.02), duration: 3000.ms),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildQuickActionRow(BuildContext context) {
    final actions = [
      ('✏️', 'Write', '/journal/compose', {'mode': 'free_write'}),
      ('🎨', 'Doodle', '/journal/compose', {'mode': 'doodle'}),
      ('🎤', 'Voice', '/journal/compose', {'mode': 'voice_note'}),
      ('🌈', 'Mood', '/journal/compose', {'mode': 'mood_color'}),
    ];
    return Row(
      children: actions.asMap().entries.map((e) {
        final (emoji, label, path, extra) = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key < actions.length - 1 ? 10 : 0),
            child: GestureDetector(
              onTap: () => context.push(path, extra: extra),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                ),
                child: Column(children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMedium)),
                ]),
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _FeatureCard(
            emoji: '🔥',
            title: 'Journal Streak',
            subtitle: 'Keep the flame alive',
            gradient: const [Color(0xFFF97316), Color(0xFFFBBF24)],
            onTap: () => context.push('/journal'),
          )),
          const SizedBox(width: 12),
          Expanded(child: _FeatureCard(
            emoji: '🎯',
            title: 'Daily Quest',
            subtitle: 'Earn your Sparks',
            gradient: const [Color(0xFF7C3AED), Color(0xFFA855F7)],
            onTap: () {},
          )),
        ]),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: gradient.first.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          Text(subtitle, style: GoogleFonts.nunito(color: Colors.white70, fontSize: 11)),
        ]),
      ),
    );
  }
}
