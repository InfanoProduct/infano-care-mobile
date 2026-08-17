import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';
import '../application/episode_path_cubit.dart';

import '../models/creative_journey_models.dart';

// ── FULL EPISODE MASTER BADGE CEREMONY ────────────────────────────────────────

class BadgeCeremonyWidget extends StatefulWidget {
  final VoidCallback onDismiss;
  final String episodeTitle;
  final CreativeEpisode? nextEpisode;
  final ValueChanged<CreativeEpisode>? onExploreNextEpisode;

  const BadgeCeremonyWidget({
    super.key,
    required this.onDismiss,
    required this.episodeTitle,
    this.nextEpisode,
    this.onExploreNextEpisode,
  });

  @override
  State<BadgeCeremonyWidget> createState() => _BadgeCeremonyWidgetState();
}

class _BadgeCeremonyWidgetState extends State<BadgeCeremonyWidget> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      AppSoundService.instance.playFanfare();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanTitle = widget.episodeTitle.replaceAll(RegExp(r'^\d+\.\s*'), '');
    final nextEp = widget.nextEpisode;
    final nextTitle = nextEp != null ? nextEp.title.replaceAll(RegExp(r'^\d+\.\s*'), '') : 'Period Diaries 🩸';
    final nextDesc = nextEp?.description ?? 'Your friendly companion to understanding cycles, tracking & self-care!';
    final nextIcon = nextEp?.episodeIcon ?? '🩸';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF5F3FF), // Soft Lavender
            Color(0xFFFDF2F8), // Soft Rose
            Color(0xFFFEF3C7), // Soft Amber
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          alignment: Alignment.center,
          children: [
            // Floating Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 35,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  Color(0xFFA78BFA),
                  Color(0xFFF472B6),
                  Color(0xFFFBBF24),
                  Color(0xFF34D399),
                  Color(0xFF60A5FA),
                ],
              ),
            ),

            // Master Badge Ceremony Card
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.12),
                        blurRadius: 36,
                        spreadRadius: 4,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Assembled Master Badge Icon
                      Container(
                        width: 105,
                        height: 105,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFBBF24).withValues(alpha: 0.55),
                              blurRadius: 28,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🏆', style: TextStyle(fontSize: 50)),
                        ),
                      )
                          .animate()
                          .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut)
                          .fadeIn(duration: 300.ms),

                      const SizedBox(height: 16),

                      Text(
                        'Master Badge Assembled! 🏆',
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                      const SizedBox(height: 4),
                      Text(
                        '$cleanTitle Master Badge',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.purple,
                        ),
                      ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                      const SizedBox(height: 6),
                      Text(
                        'All 5 Badge Assets collected across every activity!\nYour completed Master Badge is now unlocked. 💛',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          color: AppColors.textMedium,
                          height: 1.45,
                        ),
                      ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                      const SizedBox(height: 14),

                      // Quest Module Collection Pill (Fixed 8.2px overflow with Flexible)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🛡️', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Added to Quest Module -> Badges Collection',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      const SizedBox(height: 18),

                      // ── NEXT EPISODE UNLOCKED POSTER CARD ────────────────────────
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF2F8), // Soft Rose Pastel
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFBCFE8),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDB2777).withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Unlocked Tag
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCE7F3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFF472B6).withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    nextEp != null ? '🔓 NEXT EPISODE UNLOCKED' : '🏆 JOURNEY MASTERED',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFBE185D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Next Episode Poster Image & Title Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCE7F3),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFFBCFE8)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(nextIcon, style: const TextStyle(fontSize: 34)),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Explore Next Episode: $nextTitle',
                                        style: GoogleFonts.nunito(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textDark,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '"$nextDesc"',
                                        style: GoogleFonts.nunito(
                                          fontSize: 11.5,
                                          color: AppColors.textMedium,
                                          height: 1.35,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 750.ms, duration: 400.ms),

                      const SizedBox(height: 20),

                      // Explore Next Episode CTA Button
                      GestureDetector(
                        onTap: () {
                          if (nextEp != null && widget.onExploreNextEpisode != null) {
                            widget.onExploreNextEpisode!(nextEp);
                          } else {
                            widget.onDismiss();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                                'Explore Next Episode',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── DISCOVERY CHEST BADGE ASSET UNBOXING SCREEN ─────────────────────────────

class DiscoveryChestScreen extends StatefulWidget {
  final ChestReward reward;
  final VoidCallback onClose;

  const DiscoveryChestScreen({
    super.key,
    required this.reward,
    required this.onClose,
  });

  @override
  State<DiscoveryChestScreen> createState() => _DiscoveryChestScreenState();
}

class _DiscoveryChestScreenState extends State<DiscoveryChestScreen> {
  bool _opened = false;

  String _getPieceEmoji(int index, ChestReward reward) {
    const defaultEmojis = ['📜', '📐', '🧭', '⭐', '🏆', '🦴', '✨', '🎁'];
    if (index == reward.currentPieceIndex - 1) {
      return reward.assetEmoji.isNotEmpty ? reward.assetEmoji : '🧩';
    }
    if (index < defaultEmojis.length) {
      return defaultEmojis[index];
    }
    return '🧩';
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.black.withValues(alpha: 0.78),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: GestureDetector(
              onTap: _opened
                  ? widget.onClose
                  : () {
                      AppSoundService.instance.playFanfare();
                      setState(() => _opened = true);
                    },
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Chest emoji / Unboxed Badge Asset Icon
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.elasticOut,
                        ),
                        child: child,
                      ),
                      child: Container(
                        key: ValueKey(_opened),
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _opened
                                ? [const Color(0xFFEDE9FE), const Color(0xFFFCE7F3)]
                                : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _opened ? AppColors.purple.withValues(alpha: 0.4) : const Color(0xFFF59E0B),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_opened ? AppColors.purple : const Color(0xFFF59E0B)).withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _opened ? reward.assetEmoji : '🎁',
                            style: const TextStyle(fontSize: 48, decoration: TextDecoration.none),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (!_opened) ...[
                      Text(
                        'Discovery Chest!',
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap to unbox your Episode Badge Asset ✨',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          color: AppColors.textMedium,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Dark Purple Open Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: AppColors.purple,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Open Chest 🎁',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        '🧩 Badge Asset Collected!',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.purple,
                          decoration: TextDecoration.none,
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

                      const SizedBox(height: 4),
                      Text(
                        reward.assetName,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          decoration: TextDecoration.none,
                        ),
                      ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                      const SizedBox(height: 6),

                      Text(
                        reward.assetDescription,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppColors.textMedium,
                          height: 1.45,
                          decoration: TextDecoration.none,
                        ),
                      ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                      const SizedBox(height: 18),

                      // ── BADGE ASSEMBLY PROGRESS GRID ────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F5FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  reward.badgeTitle,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                Text(
                                  '${reward.currentPieceIndex}/${reward.totalPieces} Pieces',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.purple,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Assembly Slots (Responsive Wrap layout)
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 6,
                              runSpacing: 6,
                              children: List.generate(reward.totalPieces, (i) {
                                final isUnlocked = i < reward.currentPieceIndex;
                                final isJustCollected = i == reward.currentPieceIndex - 1;
                                final pieceEmoji = _getPieceEmoji(i, reward);

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isUnlocked ? const Color(0xFFFEF3C7) : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isUnlocked
                                          ? const Color(0xFFFBBF24)
                                          : Colors.grey.shade300,
                                      width: isUnlocked ? 2 : 1,
                                    ),
                                    boxShadow: isJustCollected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      isUnlocked ? pieceEmoji : '${i + 1}',
                                      style: GoogleFonts.nunito(
                                        fontSize: isUnlocked ? 15 : 11,
                                        fontWeight: FontWeight.w800,
                                        color: isUnlocked ? null : AppColors.textLight,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

                      const SizedBox(height: 16),

                      // Saved to Quest Module Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🛡️', style: TextStyle(fontSize: 12, decoration: TextDecoration.none)),
                            const SizedBox(width: 6),
                            Text(
                              'Saved to Quest Module -> Badges',
                              style: GoogleFonts.nunito(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF92400E),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                      const SizedBox(height: 20),

                      // Default Dark Purple Continue Button
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: AppColors.purple,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Continue →',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
