import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

import 'package:infano_care_mobile/core/services/app_sound_service.dart';

class MythBustersWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const MythBustersWidget({super.key, required this.content, required this.onCompleted});

  @override
  State<MythBustersWidget> createState() => _MythBustersWidgetState();
}

class _MythBustersWidgetState extends State<MythBustersWidget> {
  final CardSwiperController _controller = CardSwiperController();
  int _currentIndex = 0;
  final List<bool?> _results = []; // true = swiped right (TRUE), false = swiped left (MYTH)
  bool _allDone = false;

  List<Map<String, dynamic>> get cards {
    final raw = widget.content['cards'] ?? widget.content['myths'] ?? widget.content['items'];
    return List<Map<String, dynamic>>.from(raw as List? ?? []);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_allDone) return _buildResults();

    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🚫', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No myths found!',
              style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textMedium),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(children: [
            const Text('🚫', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 2),
            Text(
              widget.content['title'] as String? ?? 'True or Myth?',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
            ),
            const SizedBox(height: 2),
            Text(
              widget.content['instruction'] as String? ?? 'Swipe RIGHT for TRUE ✅ | Swipe LEFT for MYTH 🚫',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMedium),
            ),
          ]),
        ),

        // Swipe direction hints
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _DirectionHint(emoji: '🚫', label: 'MYTH', color: AppColors.error),
              Text(
                '${_currentIndex.clamp(0, cards.length - 1) + 1} / ${cards.length}',
                style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textMedium),
              ),
              const _DirectionHint(emoji: '✅', label: 'TRUE', color: AppColors.success),
            ],
          ),
        ),

        // Card swiper with pastel cards
        Expanded(
          child: CardSwiper(
            controller: _controller,
            cardsCount: cards.length,
            numberOfCardsDisplayed: cards.length.clamp(1, 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            onSwipe: (previousIndex, currentIndex, direction) {
              final swipedTrue = direction == CardSwiperDirection.right;
              if (previousIndex < cards.length) {
                final cardData = cards[previousIndex];
                final isTrue = (cardData['verdict'] == 'TRUE') || (cardData['isMyth'] == false);
                final isCorrect = swipedTrue == isTrue;
                if (isCorrect) {
                  AppSoundService.instance.playCorrect();
                } else {
                  AppSoundService.instance.playIncorrect();
                }
              }

              setState(() {
                _results.add(swipedTrue);
                _currentIndex = currentIndex ?? _currentIndex + 1;
                if (_results.length >= cards.length) {
                  _allDone = true;
                  AppSoundService.instance.playFanfare();
                }
              });
              return true;
            },
            cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
              if (index >= cards.length) return const SizedBox.shrink();
              final card = cards[index];
              return _MythCard(card: card, index: index);
            },
          ),
        ),

        // Action buttons (alternative to swipe)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _controller.swipe(CardSwiperDirection.left),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.close, color: AppColors.error, size: 18),
                    const SizedBox(width: 6),
                    Text('MYTH', style: GoogleFonts.nunito(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.error)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _controller.swipe(CardSwiperDirection.right),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.check, color: AppColors.success, size: 18),
                    const SizedBox(width: 6),
                    Text('TRUE', style: GoogleFonts.nunito(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.success)),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildResults() {
    int correct = 0;
    for (int i = 0; i < _results.length && i < cards.length; i++) {
      final isTrue = cards[i]['verdict'] == 'TRUE';
      if ((_results[i] == true) == isTrue) correct++;
    }

    final isPerfect = correct == cards.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // 1. Celebratory Hero Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Trophy Badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isPerfect ? '🏆' : '💪',
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
                ).animate().scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 14),

                Text(
                  isPerfect ? 'MythBuster Legend!' : 'Great Detective Work!',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),

                // Score Badge Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPerfect ? const Color(0xFFFEF3C7) : const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPerfect ? const Color(0xFFFBBF24) : AppColors.purple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isPerfect ? '⭐ $correct / ${cards.length} Busted!' : '🎯 $correct / ${cards.length} Correct',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isPerfect ? const Color(0xFF92400E) : AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  isPerfect
                      ? 'You successfully busted every myth! Now you have the real facts on your side. 💛'
                      : 'You\'re building real knowledge! Check the facts below to keep learning.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textMedium,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // 2. Section Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Fact Breakdown & Insights:',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Revealed Fact Cards
          ...cards.asMap().entries.map((e) {
            final card = e.value;
            final isTrue = card['verdict'] == 'TRUE';
            final userSwipedRight = _results.length > e.key ? _results[e.key] : null;
            final userWasRight = (userSwipedRight == true) == isTrue;

            final cardBg = isTrue ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F2);
            final borderColor = isTrue ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3);
            final tagColor = isTrue ? const Color(0xFF059669) : const Color(0xFFE11D48);
            final tagBg = isTrue ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: tagColor.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Pill Row: Verdict Tag + User Check
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isTrue ? '✅ TRUE FACT' : '🚫 MYTH BUSTED',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: tagColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (userWasRight)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'You got this!',
                                style: GoogleFonts.nunito(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Statement
                  Text(
                    card['statement'] as String? ?? '',
                    style: GoogleFonts.nunito(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Gigi Insight Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 15)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            card['explanation'] as String? ?? '',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: AppColors.textDark.withValues(alpha: 0.85),
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (e.key * 80).ms, duration: 300.ms);
          }),

          const SizedBox(height: 16),

          // 4. Collect XP CTA Button
          GestureDetector(
            onTap: () {
              AppSoundService.instance.playPop();
              HapticFeedback.selectionClick();
              widget.onCompleted();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue Journey • Collect 🪙 Coins',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 450.ms),
        ],
      ),
    );
  }
}

// ── Pastel Myth Card ─────────────────────────────────────────────────────────

class _MythCardTheme {
  final Color bg;
  final Color border;
  final Color pillBg;
  final Color accent;

  const _MythCardTheme({
    required this.bg,
    required this.border,
    required this.pillBg,
    required this.accent,
  });

  static const List<_MythCardTheme> themes = [
    _MythCardTheme(
      bg: Color(0xFFF5F3FF),
      border: Color(0xFFDDD6FE),
      pillBg: Color(0xFFEDE9FE),
      accent: Color(0xFF7C3AED),
    ),
    _MythCardTheme(
      bg: Color(0xFFFDF2F8),
      border: Color(0xFFFBCFE8),
      pillBg: Color(0xFFFCE7F3),
      accent: Color(0xFFEC4899),
    ),
    _MythCardTheme(
      bg: Color(0xFFF0FDF4),
      border: Color(0xFFA7F3D0),
      pillBg: Color(0xFFD1FAE5),
      accent: Color(0xFF059669),
    ),
    _MythCardTheme(
      bg: Color(0xFFFFFBEB),
      border: Color(0xFFFDE68A),
      pillBg: Color(0xFFFEF3C7),
      accent: Color(0xFFD97706),
    ),
    _MythCardTheme(
      bg: Color(0xFFEFF6FF),
      border: Color(0xFFBFDBFE),
      pillBg: Color(0xFFDBEAFE),
      accent: Color(0xFF2563EB),
    ),
  ];

  static _MythCardTheme getTheme(int index) => themes[index % themes.length];
}

class _MythCard extends StatelessWidget {
  final Map<String, dynamic> card;
  final int index;
  const _MythCard({required this.card, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = _MythCardTheme.getTheme(index);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Card Index Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.pillBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.border),
                ),
                child: Text(
                  'Card ${index + 1}',
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: theme.accent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('🤔', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                (card['statement'] as String?) ?? (card['text'] as String?) ?? (card['title'] as String?) ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe, color: AppColors.textMedium.withValues(alpha: 0.7), size: 15),
                  const SizedBox(width: 4),
                  Text(
                    'Swipe to decide! 👈 👉',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionHint extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  const _DirectionHint({required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}
