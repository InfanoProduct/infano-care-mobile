import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
    "You are stronger, smarter, and more amazing than you know. Let's see what your body can do! 💪✨",
    "Hey girl! Remember: bodies are like flowers 🌸 — some bloom in spring, some in summer. You're right on time!",
    "Welcome back, Detective! Ready to unlock some secrets about growing up today? 🔍✨",
    "Whatever changes you're noticing, you've got a big sister in your corner! Let's explore together. 💜",
    "Fun fact: Nobody starts puberty on the exact same day! Your timeline is 100% uniquely yours. 🌱",
    "Feeling curious or a little nervous today? Both are totally normal. Take it one step at a time! 🌟",
    "Asking questions is a superpower! Never be afraid to wonder, explore, and learn. 💡🌸",
  ];

  late int _currentMessageIndex;

  @override
  void initState() {
    super.initState();
    _currentMessageIndex = 0;
  }

  void _nextMessage() {
    setState(() {
      _currentMessageIndex = (_currentMessageIndex + 1) % _gigiMessages.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.progress.where((p) => p.isCompleted).length;
    final totalCoins = max(855, completedCount * 50);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 1. Top Section: 3D Speech Bubble (Left) + Standing 3D Character on Pedestal (Right)
          SizedBox(
            height: 185,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Left 3D Speech Bubble Card
                Positioned(
                  left: 0,
                  top: 8,
                  bottom: 8,
                  right: 110,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFF0F5), // Soft pastel blush
                          Color(0xFFFCE7F3), // Soft pastel rose
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC4B5FD).withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 6,
                          offset: const Offset(-3, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pill Header: ✨ Gigi says + Tap tip
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFDDD6FE)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('✨', style: TextStyle(fontSize: 10)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Gigi says',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF6D28D9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _nextMessage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFDDD6FE)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.refresh_rounded, size: 12, color: Color(0xFF6D28D9)),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Tap tip',
                                      style: GoogleFonts.nunito(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF6D28D9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Animated Quote Text
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) => FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                              child: Text(
                                _gigiMessages[_currentMessageIndex],
                                key: ValueKey(_currentMessageIndex),
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2D1557),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right 3D Standing Character on Pedestal
                Positioned(
                  right: -6,
                  top: -8,
                  bottom: 0,
                  width: 135,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // 3D Cylindrical Pedestal Platform
                      Container(
                        height: 28,
                        width: 105,
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFDDD6FE), Color(0xFFC4B5FD)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.all(Radius.elliptical(105, 28)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5B21B6).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),

                      // Standing 3D Character Illustration
                      Positioned(
                        bottom: 8,
                        child: SizedBox(
                          height: 165,
                          child: Image.asset(
                            'assets/images/gigi_avatar.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/images/gigi_sitting.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(begin: 0, end: -4, duration: 2500.ms, curve: Curves.easeInOut),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 2. Middle 3D Neumorphic Coins Progress & Streak Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF9FAFB),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B21B6).withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 4,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 3D Glowing Gold Coin Icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x40D97706),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🪙', style: TextStyle(fontSize: 20)),
                  ),
                ),

                const SizedBox(width: 10),

                // Coin Counter & 3D Progress Bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalCoins / 500 Coins',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 8,
                          color: const Color(0xFFEDE9FE),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (totalCoins / 500).clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // 3D Flame Streak Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.streakDays > 0 ? widget.streakDays : 1}d Streak',
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
    );
  }
}
