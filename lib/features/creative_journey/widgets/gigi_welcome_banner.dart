import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import '../models/creative_journey_models.dart';

class GigiWelcomeBanner extends StatefulWidget {
  final int streakDays;
  final List<NodeProgress> progress;

  const GigiWelcomeBanner({
    super.key,
    required this.streakDays,
    required this.progress,
  });

  @override
  State<GigiWelcomeBanner> createState() => _GigiWelcomeBannerState();
}

class _GigiWelcomeBannerState extends State<GigiWelcomeBanner> {
  static const List<String> _gigiMessages = [
    "Hey girl! Remember: bodies are like flowers 🌸 — some bloom in spring, some in summer. You're right on time!",
    "Welcome back, Detective! Ready to unlock some secrets about growing up today? 🔍✨",
    "Whatever changes you're noticing, you've got a big sister in your corner! Let's explore together. 💜",
    "Fun fact: Nobody starts puberty on the exact same day! Your timeline is 100% uniquely yours. 🌱",
    "Feeling curious or a little nervous today? Both are totally normal. Take it one step at a time! 🌟",
    "You are stronger, smarter, and more amazing than you know. Let's see what your body can do! 💪✨",
    "Asking questions is a superpower! Never be afraid to wonder, explore, and learn. 💡🌸",
    "Notice a new change today? Don't worry, every stop on your timeline is completely natural. 💖",
  ];

  late int _currentMessageIndex;

  @override
  void initState() {
    super.initState();
    // Pick random message on load
    _currentMessageIndex = Random().nextInt(_gigiMessages.length);
  }

  void _nextMessage() {
    setState(() {
      _currentMessageIndex = (_currentMessageIndex + 1) % _gigiMessages.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.progress.where((p) => p.isCompleted).length;
    final totalXp = completedCount * 15;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEDE9FE), // Soft pastel lavender
            Color(0xFFFCE7F3), // Soft pastel rose
            Color(0xFFFFF1F2), // Soft pastel blush
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              // 1. Top row: Gigi Illustration + Dynamic Speech Bubble
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Gigi Illustration (Floating beanbag character)
                  SizedBox(
                    width: 115,
                    height: 135,
                    child: Image.asset(
                      'assets/images/gigi_sitting.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text('👩‍💻✨', style: TextStyle(fontSize: 48)),
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: 0, end: -5, duration: 2000.ms, curve: Curves.easeInOut),

                  const SizedBox(width: 10),

                  // Dynamic Speech Bubble Container
                  Expanded(
                    child: GestureDetector(
                      onTap: _nextMessage,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                            bottomLeft: Radius.circular(4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.purple.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header: Gigi Says + Tap chip
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F3FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('✨', style: TextStyle(fontSize: 11)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Gigi says',
                                        style: GoogleFonts.nunito(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 14,
                                  color: AppColors.textLight.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Tap tip',
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Dynamic Message with Smooth Switcher
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.1),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                _gigiMessages[_currentMessageIndex],
                                key: ValueKey(_currentMessageIndex),
                                style: GoogleFonts.nunito(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 2. Bottom Bar: Learner Progress & Streak
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // XP Tracker
                    const Text('⭐', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      '$totalXp / 145 XP',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (completedCount / 10).clamp(0.0, 1.0),
                          backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(AppColors.purple),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Streak Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.streakDays > 0 ? widget.streakDays : 1}d Streak',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
