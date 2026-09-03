import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';
import 'package:infano_care_mobile/features/creative_journey/widgets/creative_certificate_dialog.dart';

/// Fixed final node — mood tap + recap carousel + badge ceremony lead-in
class ReflectionRewardScreen extends StatefulWidget {
  final Map<String, dynamic> content;
  final String episodeTitle;
  final VoidCallback onCompleted;

  const ReflectionRewardScreen({
    super.key,
    required this.content,
    required this.episodeTitle,
    required this.onCompleted,
  });

  @override
  State<ReflectionRewardScreen> createState() => _ReflectionRewardScreenState();
}

class _ReflectionRewardScreenState extends State<ReflectionRewardScreen> {
  late final ConfettiController _confettiCtrl;
  int? _selectedMood;
  final PageController _recapController = PageController();
  int _recapPage = 0;
  bool _recapDone = false;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _recapController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get moodQ {
    final raw = widget.content['moodQuestion'];
    if (raw is Map<String, dynamic> && raw.isNotEmpty) return raw;
    return {
      'prompt': widget.content['prompt'] as String? ?? 'How are you feeling after completing ${widget.episodeTitle}?',
      'options': [
        {
          'emoji': '💪',
          'label': 'Empowered',
          'gigiResponse': 'Awesome! You have gained fantastic body wisdom and strength today!',
        },
        {
          'emoji': '🌸',
          'label': 'Reassured',
          'gigiResponse': 'Remember, every change in your body is completely natural, safe, and beautiful!',
        },
        {
          'emoji': '✨',
          'label': 'Confident',
          'gigiResponse': 'Your self-belief and knowledge will guide you through every milestone!',
        },
        {
          'emoji': '🧠',
          'label': 'Wise',
          'gigiResponse': 'Knowledge is your greatest superpower! Keep shining brightly!',
        },
      ],
    };
  }

  List<Map<String, dynamic>> get moodOptions =>
      List<Map<String, dynamic>>.from(moodQ['options'] as List? ?? []);

  List<Map<String, dynamic>> get recapCards {
    final raw = widget.content['recapCards'] as List?;
    if (raw != null && raw.isNotEmpty) {
      return List<Map<String, dynamic>>.from(raw);
    }
    // Default recap cards fallback
    return [
      {
        'emoji': '🌱',
        'text': 'Milestone 1: Every growth phase is a natural signal of your body flourishing.',
      },
      {
        'emoji': '💡',
        'text': 'Milestone 2: Understanding your body replaces worry with confidence.',
      },
      {
        'emoji': '🎒',
        'text': 'Milestone 3: You are equipped with practical tips and care routines.',
      },
      {
        'emoji': '👑',
        'text': 'Milestone 4: Celebrate your uniqueness and embrace your personal journey!',
      },
    ];
  }

  Map<String, dynamic> get closingMessage {
    final raw = widget.content['closingMessage'];
    if (raw is Map<String, dynamic> && raw.isNotEmpty) return raw;
    return {
      'character': 'Gigi',
      'text': 'Thank you for exploring ${widget.episodeTitle} with me! You are fully prepared, wise, and empowered!',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            children: [
              // Trophy header
              const Text('🏆', style: TextStyle(fontSize: 64))
                  .animate().scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 8),
              Text(
                'You reached the end!',
                style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              const SizedBox(height: 4),
              Text(
                widget.episodeTitle,
                style: GoogleFonts.nunito(fontSize: 14, color: AppColors.purple, fontWeight: FontWeight.w700),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // Mood question
              if (_selectedMood == null) _buildMoodSection(),

              // Gigi response
              if (_selectedMood != null && !_recapDone) ...[
                _buildGigiResponse(),
                const SizedBox(height: 20),
                _buildRecapCarousel(),
              ],

              // Closing message + CTA
              if (_recapDone) _buildClosingCTA(),
            ],
          ),
        ),

        // Screen Confetti Overlay
        ConfettiWidget(
          confettiController: _confettiCtrl,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            Color(0xFFA78BFA),
            Color(0xFFF472B6),
            Color(0xFF34D399),
            Color(0xFF60A5FA),
            Color(0xFFFBBF24),
          ],
        ),
      ],
    );
  }

  Widget _buildMoodSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
          ),
          child: Column(children: [
            Text(
              moodQ['prompt'] as String? ?? 'How are you feeling?',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: moodOptions.asMap().entries.map((e) {
                final option = e.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMood = e.key),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(option['emoji'] as String? ?? '😊', style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: 6),
                        Text(
                          option['label'] as String? ?? '',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMedium),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (e.key * 100).ms, duration: 400.ms),
                );
              }).toList(),
            ),
          ]),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildGigiResponse() {
    final mood = _selectedMood;
    if (mood == null || mood >= moodOptions.length) return const SizedBox.shrink();
    final response = moodOptions[mood]['gigiResponse'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF3E8FF), Color(0xFFFDF2F8)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.15),
                blurRadius: 6,
              ),
            ],
          ),
          child: const Center(child: Text('🌸', style: TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Gigi says:', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.purple)),
            const SizedBox(height: 4),
            Text(response, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textDark, height: 1.5, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildRecapCarousel() {
    if (recapCards.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _recapDone = true));
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Text('📋 Your Journey Recap', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 12),
        SizedBox(
          height: 175,
          child: PageView.builder(
            controller: _recapController,
            onPageChanged: (p) => setState(() => _recapPage = p),
            itemCount: recapCards.length,
            itemBuilder: (context, index) {
              final card = recapCards[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
                      [const Color(0xFFFDF2F8), const Color(0xFFFCE7F3)],
                      [const Color(0xFFF0FDFA), const Color(0xFFDCFCE7)],
                      [const Color(0xFFE0F2FE), const Color(0xFFF0F9FF)],
                      [const Color(0xFFF5F3FF), const Color(0xFFFDF2F8)],
                    ][index % 5],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(card['emoji'] as String? ?? '💡', style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 8),
                        Text(
                          card['text'] as String? ?? '',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicators + next button
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ...List.generate(recapCards.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _recapPage ? 16 : 6, height: 6,
            decoration: BoxDecoration(
              color: i == _recapPage ? AppColors.purple : AppColors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ]),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () {
            if (_recapPage < recapCards.length - 1) {
              _recapController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            } else {
              setState(() => _recapDone = true);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.purple,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _recapPage < recapCards.length - 1 ? 'Next →' : 'See Badge Ceremony 🏆',
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  Widget _buildClosingCTA() {
    final character = closingMessage['character'] as String? ?? 'Mira';
    final text = closingMessage['text'] as String? ?? 'Thanks for walking the road with me!';

    return Column(
      children: [
        // Mira's closing
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFDF2F8), Color(0xFFFFE4E6)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.pink.withValues(alpha: 0.3)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.pink, AppColors.purple])),
              child: Center(child: Text(character[0], style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(character, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textLight)),
              const SizedBox(height: 4),
              Text(text, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textDark, height: 1.5, fontStyle: FontStyle.italic)),
            ])),
          ]),
        ).animate().fadeIn(duration: 500.ms),
        const SizedBox(height: 20),
        // Special Graduation Certificate CTA (Pastel Styling + Confetti Trigger!)
        GestureDetector(
          onTap: () {
            _confettiCtrl.play();
            AppSoundService.instance.playFanfare();
            CreativeCertificateDialog.show(
              context,
              certificate: CreativeCertificate(
                id: 'INF-CERT-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                journeyId: 'cj_my_changing_body',
                journeyTitle: 'My Changing Body',
                recipientName: 'Young Explorer',
                issueDate: 'August 21, 2026',
                totalEpisodes: 6,
                totalNodes: 58,
                gigiQuote: 'Embrace your unique growth with courage, body gratitude, and wisdom!',
              ),
              onClaimed: () {
                AppSoundService.instance.playBunchOfCoinsSound();
                widget.onCompleted();
              },
            );
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)], // Dreamy Pastel Lavender to Soft Rose!
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFC4B5FD),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA78BFA).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🎓', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Claim Graduation Certificate 🎓✨',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF5B21B6), // Deep Royal Pastel Purple Text!
                ),
              ),
            ]),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.elasticOut),

        GestureDetector(
          onTap: () {
            AppSoundService.instance.playBunchOfCoinsSound();
            widget.onCompleted();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🏆', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Claim Your Badge & Collect 🪙 Coins!',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ]),
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms).scaleXY(begin: 0.9, end: 1.0, curve: Curves.elasticOut),
      ],
    );
  }
}
