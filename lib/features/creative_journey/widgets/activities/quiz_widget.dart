import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';

class QuizWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback onCompleted;

  const QuizWidget({
    super.key,
    required this.content,
    required this.onCompleted,
  });

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  int _currentQ = 0;
  final Map<int, int?> _answers = {};
  bool _showResult = false;
  int _currentStreak = 0;
  int _maxStreak = 0;

  List<Map<String, dynamic>> get questions =>
      List<Map<String, dynamic>>.from(widget.content['questions'] as List? ?? []);

  int get correctCount => _answers.entries
      .where((e) {
        if (e.key >= questions.length) return false;
        final q = questions[e.key];
        return e.value == q['correctIndex'];
      })
      .length;

  double get accuracy => questions.isEmpty ? 0 : correctCount / questions.length;

  String get quizTitle => widget.content['title'] as String? ?? 'Trivia Quiz 🧠';

  void _onOptionSelected(int qIdx, int optionIdx, int correctIdx) {
    if (_answers.containsKey(qIdx)) return;

    final isCorrect = optionIdx == correctIdx;
    if (isCorrect) {
      AppSoundService.instance.playCorrect();
      _currentStreak++;
      if (_currentStreak > _maxStreak) {
        _maxStreak = _currentStreak;
      }
    } else {
      AppSoundService.instance.playIncorrect();
      _currentStreak = 0;
    }

    setState(() {
      _answers[qIdx] = optionIdx;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Center(
        child: Text(
          'No questions available!',
          style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textMedium),
        ),
      );
    }

    if (_showResult) return _buildResults();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(_currentQ),
        child: _buildQuestion(questions[_currentQ], _currentQ),
      ),
    );
  }

  // ── ❓ GAMIFIED QUESTION SCREEN ────────────────────────────────────────────
  Widget _buildQuestion(Map<String, dynamic> q, int idx) {
    final options = List<String>.from(q['options'] as List? ?? []);
    final selected = _answers[idx];
    final correct = q['correctIndex'] as int? ?? 0;
    final isAnswered = selected != null;

    final optionPrefixes = ['A', 'B', 'C', 'D', 'E', 'F'];
    final optionColors = [
      const Color(0xFFF5F3FF), // Soft Purple
      const Color(0xFFFDF2F8), // Soft Pink
      const Color(0xFFFFFBEB), // Soft Amber
      const Color(0xFFEFF6FF), // Soft Blue
    ];

    return SingleChildScrollView(
      key: ValueKey<int>(idx),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏆 TOP STATUS BAR (Question Badge + Streak Counter)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'QUESTION ${idx + 1} OF ${questions.length}',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              if (_currentStreak > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '$_currentStreak STREAK',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
            ],
          ),
          const SizedBox(height: 12),

          // 📊 MULTI-SEGMENT PROGRESS CAPS
          Row(
            children: List.generate(questions.length, (i) {
              final isCurrent = i == idx;
              final isDone = _answers.containsKey(i);
              final isCorrectDone = isDone && _answers[i] == questions[i]['correctIndex'];

              Color barColor = const Color(0xFFE5E7EB);
              if (isDone) {
                barColor = isCorrectDone ? AppColors.success : const Color(0xFFEF4444);
              } else if (isCurrent) {
                barColor = AppColors.purple;
              }

              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 6,
                  margin: EdgeInsets.only(right: i < questions.length - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isCurrent || isDone
                        ? [
                            BoxShadow(
                              color: barColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // 🧠 QUESTION CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        quizTitle.toUpperCase(),
                        style: GoogleFonts.nunito(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF7C3AED),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  (q['text'] as String?) ?? (q['question'] as String?) ?? (q['statement'] as String?) ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E1B4B),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05),
          const SizedBox(height: 20),

          // 🎴 CREATIVE OPTIONS LIST (A, B, C, D)
          ...options.asMap().entries.map((e) {
            final optIdx = e.key;
            final optText = e.value;
            final prefix = optionPrefixes[optIdx % optionPrefixes.length];
            final defaultBg = optionColors[optIdx % optionColors.length];

            Color bg = defaultBg;
            Color borderColor = AppColors.purple.withValues(alpha: 0.25);
            Color prefixBg = Colors.white;
            Color prefixTextColor = AppColors.purple;
            Widget? statusBadge;

            if (isAnswered) {
              if (optIdx == correct) {
                bg = const Color(0xFFECFDF5);
                borderColor = AppColors.success;
                prefixBg = AppColors.success;
                prefixTextColor = Colors.white;
                statusBadge = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'CORRECT',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (optIdx == selected) {
                bg = const Color(0xFFFEF2F2);
                borderColor = const Color(0xFFEF4444);
                prefixBg = const Color(0xFFEF4444);
                prefixTextColor = Colors.white;
                statusBadge = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'YOUR ANSWER',
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }

            return GestureDetector(
              onTap: () => _onOptionSelected(idx, optIdx, correct),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: isAnswered && (optIdx == correct || optIdx == selected) ? 2 : 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: isAnswered && optIdx == correct
                          ? AppColors.success.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Option Letter Badge (A, B, C, D)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: prefixBg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          prefix,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: prefixTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Option Text
                    Expanded(
                      child: Text(
                        optText,
                        style: GoogleFonts.nunito(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          height: 1.35,
                        ),
                      ),
                    ),

                    if (statusBadge != null) ...[
                      const SizedBox(width: 8),
                      statusBadge,
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (optIdx * 60).ms, duration: 300.ms).slideX(begin: 0.05);
          }),

          // 💬 EXPLANATION / FEEDBACK BUBBLE
          if (isAnswered) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected == correct ? const Color(0xFFECFDF5) : const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected == correct ? AppColors.success.withValues(alpha: 0.4) : AppColors.purple.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected == correct ? '✨' : '👩‍⚕️',
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected == correct ? 'Gigi Explains:' : 'Dr. Bloom Says:',
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: selected == correct ? const Color(0xFF047857) : AppColors.purple,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          (q['explanation'] as String?) ??
                          (q['feedback'] as String?) ??
                          (q['gigiResponse'] as String?) ??
                          (q['gigiInsight'] as String?) ??
                          (q['doctorSays'] as String?) ?? '',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected == correct ? const Color(0xFF065F46) : AppColors.textDark,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
            const SizedBox(height: 20),

            // NEXT QUESTION / FINISH CTA BUTTON
            GestureDetector(
              onTap: () {
                if (_currentQ < questions.length - 1) {
                  setState(() => _currentQ++);
                } else {
                  AppSoundService.instance.playFanfare();
                  setState(() => _showResult = true);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(18),
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
                      _currentQ < questions.length - 1 ? 'Next Question' : 'See Results',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _currentQ < questions.length - 1 ? Icons.arrow_forward_rounded : Icons.stars_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ],
      ),
    );
  }

  // ── 🏆 GAMIFIED RESULTS SCREEN ─────────────────────────────────────────────
  Widget _buildResults() {
    final passed = accuracy >= 0.6;
    final maxCoins = widget.content['coinsReward'] as int? ?? widget.content['xpReward'] as int? ?? 10;
    final totalXp = passed ? (accuracy * maxCoins).round().clamp(1, maxCoins) : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Big Animated Emoji Badge
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: passed
                    ? [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)]
                    : [const Color(0xFFF5F3FF), const Color(0xFFDDD6FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (passed ? const Color(0xFFFDBA74) : AppColors.purple).withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(passed ? '👑' : '💪', style: const TextStyle(fontSize: 48)),
            ),
          ).animate().scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut),

          const SizedBox(height: 20),
          Text(
            passed ? 'Quiz Mastered!' : 'Great Effort!',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),

          // Score Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: passed ? const Color(0xFFECFDF5) : const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: passed ? AppColors.success : AppColors.purple),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  passed ? Icons.emoji_events_rounded : Icons.psychology_rounded,
                  color: passed ? AppColors.success : AppColors.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$correctCount / ${questions.length} Correct (${(accuracy * 100).round()}%)',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: passed ? const Color(0xFF047857) : AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // XP Earned Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFDBA74)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '+$totalXp COINS EARNED! 🪙',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF9A3412),
                      ),
                    ),
                    if (_maxStreak > 1)
                      Text(
                        'Max Streak: $_maxStreak in a row 🔥',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFC2410C),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 20),

          // Message Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.06),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Text(
              passed
                  ? 'Fantastic work! You\'ve shown a deep understanding of your body and skin science. Wear your knowledge with total pride! 🌟'
                  : 'Great practice! Every question helps build your understanding. The science is yours to keep forever! 💛',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
          const SizedBox(height: 28),

          // COLLECT XP BUTTON
          GestureDetector(
            onTap: () {
              AppSoundService.instance.playPop();
              HapticFeedback.selectionClick();
              widget.onCompleted();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(18),
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
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}
