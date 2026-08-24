import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/home/bloc/dashboard_cubit.dart';

/// MenstrualTrackerSnapshotCard
/// Premium 3D Glassmorphic snapshot card for the Menstrual Tracker on the Homepage.
/// Uses requested signature background color #DB337D with glossy glassmorphic overlay.
class MenstrualTrackerSnapshotCard extends StatefulWidget {
  const MenstrualTrackerSnapshotCard({super.key});

  @override
  State<MenstrualTrackerSnapshotCard> createState() => _MenstrualTrackerSnapshotCardState();
}

class _MenstrualTrackerSnapshotCardState extends State<MenstrualTrackerSnapshotCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrackerBloc, TrackerState>(
      builder: (context, state) {
        return state.when(
          initial: () => _buildLoadingCard(),
          loading: () => _buildLoadingCard(),
          error: (msg) => _buildNotStartedCard(context),
          notStarted: () => _buildNotStartedCard(context),
          loaded: (profile, prediction, logs, history, dailyInsights, articles, milestone, pointsEarned, isRefreshing) {
            if (profile.lastPeriodStart == null && profile.trackerMode == 'watching_waiting') {
              return _buildNotStartedCard(context);
            }
            return _buildActiveSnapshotCard(context, profile, prediction, logs);
          },
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFDB337D),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildNotStartedCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppSoundService.instance.playPop();
        context.push('/onboarding/tracker/date');
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE84E8F),
                  Color(0xFFDB337D), // Requested signature background #DB337D
                  Color(0xFFC2185B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDB337D).withValues(alpha: 0.42),
                  blurRadius: 28,
                  spreadRadius: 1,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Setup Badge Pill (Right-aligned)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🌸', style: TextStyle(fontSize: 13.5)),
                        const SizedBox(width: 5),
                        Text(
                          'SETUP TRACKER',
                          style: GoogleFonts.nunito(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFDB337D),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Main Content Row: Animated Circle Icon + Benefits Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated Pulsing Circle Icon Container
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulseVal = _pulseController.value;
                        final popScale = 1.0 + (sin(pulseVal * pi) * 0.05);

                        return Transform.scale(
                          scale: popScale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 106,
                                height: 106,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.18 * (1.0 - pulseVal * 0.3)),
                                ),
                              ),
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.14),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text('🩸', style: TextStyle(fontSize: 42)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 16),

                    // Right Column: Headline & Benefits List
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configure Period Tracker',
                            style: GoogleFonts.nunito(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Set up in 30s to unlock smart predictions & body insights!',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.92),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildBenefitRow('🩸', 'Accurate period & cycle predictions'),
                          const SizedBox(height: 3),
                          _buildBenefitRow('💖', 'Track symptoms, energy & moods'),
                          const SizedBox(height: 3),
                          _buildBenefitRow('✨', 'Personalized daily self-care tips'),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Clear 3D Prominent White CTA Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Set Up Period Tracker Now',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFDB337D),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Color(0xFFDB337D),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Glassmorphic Specular Overlay
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
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildBenefitRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.95),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSnapshotCard(
    BuildContext context,
    CycleProfileModel profile,
    PredictionResultModel? prediction,
    List<CycleLogModel> logs,
  ) {
    // Determine current day & cycle info
    int currentDay = 1;
    if (profile.lastPeriodStart != null) {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final lastStart = profile.lastPeriodStart!;
      final startDate = DateTime(lastStart.year, lastStart.month, lastStart.day);
      currentDay = todayDate.difference(startDate).inDays + 1;
      if (currentDay < 1) currentDay = 1;
    }

    final totalCycleDays = profile.avgCycleLength;
    final progressPercent = (currentDay / totalCycleDays).clamp(0.0, 1.0);

    // Dynamic phase info & colors
    final phaseInfo = _getPhaseDetails(currentDay, totalCycleDays, profile.avgPeriodDuration);

    // Prediction text
    String countdownText = 'Cycle in Progress';
    if (prediction != null) {
      final days = prediction.daysUntilPrediction;
      if (days == 0) {
        countdownText = 'Period Expected Today! 🩸';
      } else if (days > 0) {
        countdownText = 'Next period in $days days 🩸';
      } else {
        countdownText = 'Period ${days.abs()} days late';
      }
    } else if (profile.lastPeriodStart != null) {
      final nextP = profile.lastPeriodStart!.add(Duration(days: totalCycleDays));
      final diff = nextP.difference(DateTime.now()).inDays;
      if (diff >= 0) {
        countdownText = 'Next period in ~$diff days 🩸';
      }
    }

    return GestureDetector(
      onTap: () {
        AppSoundService.instance.playPop();
        try {
          context.read<DashboardCubit>().setTab(2);
        } catch (_) {
          context.push('/track');
        }
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE84E8F),
                  Color(0xFFDB337D), // Requested signature background #DB337D
                  Color(0xFFC2185B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.8),
              boxShadow: [
                // Deep 3D Ambient Drop Shadow
                BoxShadow(
                  color: const Color(0xFFDB337D).withValues(alpha: 0.42),
                  blurRadius: 28,
                  spreadRadius: 1,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Header Bar: Phase Badge Pill Shifted to RIGHT Side
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(phaseInfo.emoji, style: const TextStyle(fontSize: 13.5)),
                        const SizedBox(width: 5),
                        Text(
                          phaseInfo.title.toUpperCase(),
                          style: GoogleFonts.nunito(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFDB337D),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Middle Row: Enlarged Circle Ring + Prediction & Advice Quote
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Animated Big Circle Ring Indicator
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulseVal = _pulseController.value;
                        final popScale = 1.0 + (sin(pulseVal * pi) * 0.04);

                        return Transform.scale(
                          scale: popScale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer Ambient Glow Aura
                              Container(
                                width: 132,
                                height: 132,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.18 * (1.0 - pulseVal * 0.3)),
                                ),
                              ),

                              // Inner White Glass Background with 3D shadow
                              Container(
                                width: 112,
                                height: 112,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.14),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                              ),

                              // Circle Ring Painter
                              SizedBox(
                                width: 116,
                                height: 116,
                                child: CustomPaint(
                                  painter: _BigCycleRingPainter(
                                    progressRatio: progressPercent,
                                    accentColor: const Color(0xFFDB337D),
                                  ),
                                ),
                              ),

                              // Center Day Counter
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'DAY',
                                    style: GoogleFonts.nunito(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF9CA3AF),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  Text(
                                    '$currentDay',
                                    style: GoogleFonts.nunito(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFDB337D),
                                      height: 1.0,
                                    ),
                                  ),
                                  Text(
                                    'of $totalCycleDays',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 18),

                    // Right Side: Prediction Header & Advice Quote
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Prediction Text with Calendar Icon
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 15, color: Colors.white),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  countdownText,
                                  style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Phase Advice Quote
                          Text(
                            phaseInfo.tipQuote,
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.92),
                              height: 1.38,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3D Background Decorative Elements
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -35,
            left: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Text(
              '✨',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 14,
            child: Icon(
              Icons.star_rounded,
              color: Colors.white.withValues(alpha: 0.35),
              size: 18,
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
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  _PhaseDetails _getPhaseDetails(int day, int cycleLength, int periodLength) {
    if (day <= periodLength) {
      return _PhaseDetails(
        id: 'menstrual',
        title: 'Menstrual Phase',
        emoji: '🩸',
        tipQuote: 'Rest up, stay hydrated & embrace cozy gentle self-care today.',
      );
    } else if (day <= (cycleLength * 0.45).round()) {
      return _PhaseDetails(
        id: 'follicular',
        title: 'Follicular Phase',
        emoji: '🌸',
        tipQuote: 'Energy & mood are rising! Perfect time for learning & new ideas.',
      );
    } else if (day <= (cycleLength * 0.58).round()) {
      return _PhaseDetails(
        id: 'ovulation',
        title: 'Ovulation Window',
        emoji: '✨',
        tipQuote: 'Peak confidence & magnetic energy! Shine brightly today.',
      );
    } else {
      return _PhaseDetails(
        id: 'luteal',
        title: 'Luteal Phase',
        emoji: '🔮',
        tipQuote: 'Winding down. Listen to your body & nourish yourself with healthy snacks.',
      );
    }
  }
}

class _PhaseDetails {
  final String id;
  final String title;
  final String emoji;
  final String tipQuote;

  _PhaseDetails({
    required this.id,
    required this.title,
    required this.emoji,
    required this.tipQuote,
  });
}

/// Custom painter for big smooth ring with progress arc & current day dot indicator
class _BigCycleRingPainter extends CustomPainter {
  final double progressRatio; // 0.0 to 1.0
  final Color accentColor;

  _BigCycleRingPainter({
    required this.progressRatio,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 7;

    // Track background
    final bgPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.5;

    canvas.drawCircle(center, radius, bgPaint);

    // Active progress arc
    final activePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9.5;

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progressRatio;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );

    // Current day indicator dot
    final dotAngle = startAngle + sweepAngle;
    final dotX = center.dx + radius * cos(dotAngle);
    final dotY = center.dy + radius * sin(dotAngle);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dotX, dotY), 6.5, dotPaint);

    final dotBorderPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(dotX, dotY), 6.5, dotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _BigCycleRingPainter oldDelegate) {
    return oldDelegate.progressRatio != progressRatio || oldDelegate.accentColor != accentColor;
  }
}
