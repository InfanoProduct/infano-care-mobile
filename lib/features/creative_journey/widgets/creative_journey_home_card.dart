import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';
import '../models/creative_journey_models.dart';

/// CreativeJourneyHomeCard
/// Premium 3D Glassmorphic banner card displayed on the Home dashboard showing real-time learning progress.
/// Features a glossy specular glass finish, multi-layered deep 3D elevation shadows,
/// signature #59CDEE ocean cyan sky background, creative 3D pattern design, high-contrast deep navy typography,
/// and smooth progress bar (Journey icon removed).
class CreativeJourneyHomeCard extends StatelessWidget {
  final List<CreativeJourney> journeys;
  final List<NodeProgress> allProgress;
  final bool isLoading;

  const CreativeJourneyHomeCard({
    super.key,
    this.journeys = const [],
    this.allProgress = const [],
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildSkeletonCard();
    }

    // Determine current active journey dynamically based on real-time user progress
    CreativeJourney? activeJourney;

    for (int jIdx = 0; jIdx < journeys.length; jIdx++) {
      final journey = journeys[jIdx];

      // Check if journey is unlocked (Journey 0 is unlocked by default, or prev journey 100% completed)
      bool isJourneyUnlocked = jIdx == 0;
      if (jIdx > 0) {
        final prevJ = journeys[jIdx - 1];
        final prevNodeIds = prevJ.episodes.expand((e) => e.nodes).map((n) => n.nodeId).toSet();
        final completedInPrev = allProgress
            .where((p) => p.isCompleted && prevNodeIds.contains(p.nodeId))
            .length;
        isJourneyUnlocked = prevNodeIds.isNotEmpty && completedInPrev >= prevNodeIds.length;
      }

      if (isJourneyUnlocked) {
        final jNodeIds = journey.episodes.expand((e) => e.nodes).map((n) => n.nodeId).toSet();
        final completedInJ = allProgress
            .where((p) => p.isCompleted && jNodeIds.contains(p.nodeId))
            .length;

        // If this unlocked journey has uncompleted nodes, this is the user's active target journey!
        if (jNodeIds.isEmpty || completedInJ < jNodeIds.length) {
          activeJourney = journey;
          break;
        }
      }
    }

    // Fallback: If all unlocked journeys are 100% completed, target the last unlocked journey
    activeJourney ??= journeys.isNotEmpty ? journeys.last : null;

    // Calculate real-time node progress across active journey
    int totalNodesInJourney = 0;
    int completedNodesInJourney = 0;
    CreativeEpisode? nextEpisode;
    int completedEpisodesCount = 0;
    int totalEpisodesCount = activeJourney?.episodes.length ?? 7;

    if (activeJourney != null) {
      for (final ep in activeJourney.episodes) {
        final epTotalNodes = ep.nodes.isNotEmpty ? ep.nodes.length : 10;
        totalNodesInJourney += epTotalNodes;

        final epCompletedCount = allProgress
            .where((p) =>
                (p.episodeId == ep.id || p.nodeId.startsWith(_getPrefix(ep.id))) &&
                p.isCompleted)
            .length;
        completedNodesInJourney += min(epCompletedCount, epTotalNodes);

        if (epCompletedCount >= epTotalNodes && epTotalNodes > 0) {
          completedEpisodesCount++;
        } else {
          nextEpisode ??= ep;
        }
      }
      // If all episodes are complete, target last episode
      nextEpisode ??= activeJourney.episodes.isNotEmpty ? activeJourney.episodes.last : null;
    }

    final hasStartedAny = completedNodesInJourney > 0;

    // Fallbacks for display
    final journeyTitle = activeJourney?.title ?? 'My Changing Body 🌸';
    final episodeTitle = nextEpisode?.title ?? '1. The Body Timeline 🗺️';

    // Calculate precise progress percentage from real backend data
    double progressRatio = 0.0;
    if (totalNodesInJourney > 0) {
      progressRatio = (completedNodesInJourney / totalNodesInJourney).clamp(0.0, 1.0);
    } else if (totalEpisodesCount > 0) {
      progressRatio = (completedEpisodesCount / totalEpisodesCount).clamp(0.0, 1.0);
    }
    final progressPercent = (progressRatio * 100).toInt();

    // CTA Label & Badge based on exact user state
    final String badgeText;
    final String ctaText;

    if (!hasStartedAny && journeys.isEmpty) {
      badgeText = '🚀 TAKE THE FIRST STEP';
      ctaText = 'Take the first step ✨';
    } else if (!hasStartedAny) {
      badgeText = '✨ READY TO BEGIN';
      ctaText = 'Start now 🚀';
    } else {
      badgeText = '🔥 IN PROGRESS';
      ctaText = 'In progress • Resume Episode ➔';
    }

    return GestureDetector(
      onTap: () {
        AppSoundService.instance.playPop();
        if (activeJourney != null) {
          context.push('/creative-journey/journey/${activeJourney.id}');
        } else {
          context.push('/creative-journey');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          color: const Color(0xFFE2CBFA),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.85),
              blurRadius: 6,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Live Element 1: Glowing Glass Specular Radial Orb (Top-Right)
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.85),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Live Element 2: Soft Watermark Motif (Bottom-Right)
              Positioned(
                right: -15,
                bottom: -15,
                child: Opacity(
                  opacity: 0.08,
                  child: const Text(
                    '🌸',
                    style: TextStyle(fontSize: 110),
                  ),
                ),
              ),

              // Animated Sparkle Highlights
              Positioned(
                top: 14,
                right: 20,
                child: const Text('✨', style: TextStyle(fontSize: 20))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.2, 1.2), duration: 1500.ms),
              ),

              // Main Foreground Content
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Badge Text
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.nunito(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF6D28D9),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Journey Title
                    Text(
                      journeyTitle,
                      style: GoogleFonts.nunito(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF3B0764),
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Next Episode Subtitle
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          size: 16,
                          color: Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Next: $episodeTitle',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF6D28D9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Progress Bar Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              hasStartedAny
                                  ? '$completedNodesInJourney of $totalNodesInJourney Nodes Complete ($completedEpisodesCount / $totalEpisodesCount Ep)'
                                  : '10 Interactive Activity Nodes',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3B0764),
                              ),
                            ),
                            Text(
                              '$progressPercent%',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Progress Bar Track
                        Stack(
                          children: [
                            // Track Background
                            Container(
                              height: 10,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),

                            // Filled Progress Bar
                            FractionallySizedBox(
                              widthFactor: progressRatio == 0 ? 0.03 : progressRatio,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED),
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // CTA Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ctaText,
                            style: GoogleFonts.nunito(
                              fontSize: 15,
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

              // Glassmorphic Glossy Specular Highlight Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.32),
                          Colors.white.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  static String _getPrefix(String episodeId) {
    switch (episodeId) {
      case 'ce_body_timeline':
        return 'bt_';
      case 'ce_growing_pains':
        return 'gp_';
      case 'ce_skin_stories':
        return 'ss_';
      case 'ce_period_preview':
        return 'pp_';
      case 'ce_bra_basics':
        return 'bb_';
      case 'ce_body_image':
        return 'bi_';
      case 'ce_cycle_basics':
        return 'cb_';
      default:
        return episodeId.replaceAll('ce_', '');
    }
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF59CDEE),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

// ── CREATIVE 3D CYAN PATTERN PAINTER (#59CDEE Creative Design) ─────────────────
class _Creative3DCyanPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Glossy 3D Glowing Glass Bubbles
    _draw3DGlassBubble(canvas, Offset(size.width * 0.92, size.height * 0.18), 54, Colors.white.withValues(alpha: 0.2));
    _draw3DGlassBubble(canvas, Offset(size.width * 0.08, size.height * 0.85), 44, Colors.white.withValues(alpha: 0.15));
    _draw3DGlassBubble(canvas, Offset(size.width * 0.82, size.height * 0.85), 32, Colors.white.withValues(alpha: 0.12));

    // 2. Vector Heart & Sparkle Accents
    _drawHeart(canvas, Offset(size.width * 0.76, size.height * 0.24), 11, Colors.white.withValues(alpha: 0.3));
    _drawHeart(canvas, Offset(size.width * 0.14, size.height * 0.25), 9, Colors.white.withValues(alpha: 0.25));

    // 3. Sparkle Star Elements
    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    _drawStar(canvas, Offset(size.width * 0.32, size.height * 0.88), 6, starPaint);
    _drawStar(canvas, Offset(size.width * 0.85, size.height * 0.58), 5, starPaint);
  }

  void _draw3DGlassBubble(Canvas canvas, Offset center, double radius, Color baseColor) {
    final bubblePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.6),
          baseColor,
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.65, 1.0],
        center: const Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, bubblePaint);

    // Specular highlight arc
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.75),
      -pi * 0.8,
      pi * 0.5,
      false,
      highlightPaint,
    );
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.4);
    path.cubicTo(
      center.dx - size * 0.8, center.dy - size * 0.4,
      center.dx - size * 0.4, center.dy - size * 1.1,
      center.dx, center.dy - size * 0.4,
    );
    path.cubicTo(
      center.dx + size * 0.4, center.dy - size * 1.1,
      center.dx + size * 0.8, center.dy - size * 0.4,
      center.dx, center.dy + size * 0.4,
    );
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      double angle = i * pi / 2;
      double dx = center.dx + radius * cos(angle);
      double dy = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
