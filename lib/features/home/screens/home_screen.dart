import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/features/creative_journey/application/journey_map_cubit.dart';
import 'package:infano_care_mobile/features/creative_journey/widgets/creative_journey_home_card.dart';
import 'package:infano_care_mobile/features/home/widgets/menstrual_tracker_snapshot_card.dart';
import 'package:infano_care_mobile/widgets/notification_center_sheet.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';
import 'package:infano_care_mobile/features/home/bloc/dashboard_cubit.dart';
import 'package:infano_care_mobile/models/circle.dart';
import 'package:infano_care_mobile/models/peerline_session.dart';
import 'package:infano_care_mobile/models/peerline_topic.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/widgets/circle_details_sheet.dart';
import 'package:infano_care_mobile/widgets/peer_mentor_detail_sheet.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/article_detail_screen.dart';
import 'package:infano_care_mobile/features/home/widgets/parent_daughter_summary_home_card.dart';
import 'package:infano_care_mobile/services/community_socket_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  final GlobalKey? headerKey;
  final GlobalKey? trackerKey;
  final GlobalKey? journeyKey;

  const HomeScreen({
    super.key,
    this.headerKey,
    this.trackerKey,
    this.journeyKey,
  });

  @override
  Widget build(BuildContext context) {
    return _HomeScreenView(
      headerKey: headerKey,
      trackerKey: trackerKey,
      journeyKey: journeyKey,
    );
  }
}

class _HomeScreenView extends StatefulWidget {
  final GlobalKey? headerKey;
  final GlobalKey? trackerKey;
  final GlobalKey? journeyKey;

  const _HomeScreenView({
    this.headerKey,
    this.trackerKey,
    this.journeyKey,
  });

  @override
  State<_HomeScreenView> createState() => _HomeScreenViewState();
}

class _HomeScreenViewState extends State<_HomeScreenView> {
  static const List<String> _genZQuotes = [
    "Main character energy today, bestie! 💅✨ Your body is doing magic, keep shining!",
    "No cap, you are literally glowing today! Take it easy and slay ✨🌸",
    "Friendly reminder: You're that girl! Own your day with 100% confidence 💪🔥",
    "Big brain vibes only today! Never let anyone dim your sparkle 🧠✨",
    "It's giving unstoppable! Whatever you're working on, you've got this 🚀💖",
    "Self-care check: Hydrate, breathe, and remember you're iconic 💧👑",
    "Period or no period, you are an absolute force of nature! Slay today 🌸💫",
    "Serotonin boost activated! You are stronger and smarter than you know 🌟✨",
    "Era of body confidence unlocked! Every phase of you is beautiful 💖🏆",
    "Radiating main character confidence! Go conquer your goals today 💅🔥",
    "Soft girl aesthetic + strong mindset = unstoppable you! 🌸💪",
    "Manifesting good vibes, high energy, and pure joy for you today! ✨🌈",
    "No bad vibes allowed in your space today! Stay golden, bestie ⭐💖",
    "Your timeline, your pace! You're right where you're supposed to be 🌱✨",
  ];

  late String _dailyQuote;

  @override
  void initState() {
    super.initState();
    // Default quote calculated by day of year for smooth rotation
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    _dailyQuote = _genZQuotes[dayOfYear % _genZQuotes.length];
    _fetchDailyQuote();
    NotificationCenterSheet.fetchUnreadCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          Provider.of<CommunitySocketService>(context, listen: false).updateUnreadChatsCount();
        } catch (_) {}
      }
    });
  }

  Future<void> _fetchDailyQuote() async {
    try {
      final response = await ApiService.instance.dio.get('/parent/daily-quote');
      if (response.data != null && response.data['quote'] != null) {
        if (mounted) {
          setState(() {
            _dailyQuote = response.data['quote'].toString();
          });
        }
      }
    } catch (e) {
      debugPrint(
        '[HomeScreen] Daily quote fetch error (using local rotation): $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<LocalStorageService>();
    final rawName = storage.displayName;
    final userName =
        (rawName != null && rawName.trim().isNotEmpty)
            ? rawName.trim()
            : 'Friend';
    final isFirstTime = !storage.hasCompletedUserGuide;
    final greetingText = isFirstTime ? 'Welcome,' : 'Welcome back,';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF5FF), // Harmonious soft lavender background
        body: Column(
          children: [
            // 1. Pinned Top Action Bar (Fixed at top, does NOT pull down on scroll)
            Container(
              width: double.infinity,
              color: const Color(0xFFFAF5FF),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Hamburger Menu Icon (3 lines)
                      GestureDetector(
                        onTap: () {
                          try {
                            Scaffold.of(context).openDrawer();
                          } catch (_) {
                            context.push('/account');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5B21B6).withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.menu_rounded,
                            size: 24,
                            color: Color(0xFF2D1557),
                          ),
                        ),
                      ),

                      // Right: SOS Icon + Chat Icon + Notification Icon
                      Row(
                        children: [
                          // Emergency SOS Icon
                          GestureDetector(
                            onTap: () {
                              AppSoundService.instance.playPop();
                              context.push('/safety/sos');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFECDD3),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFE11D48,
                                    ).withValues(alpha: 0.18),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.sos_rounded,
                                size: 18,
                                color: Color(0xFFE11D48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Inbox / Chat Icon
                          GestureDetector(
                            onTap: () {
                              AppSoundService.instance.playPop();
                              context.push('/my-chats');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF5B21B6).withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Consumer<CommunitySocketService>(
                                builder: (context, socketService, _) {
                                  return ValueListenableBuilder<int>(
                                    valueListenable: socketService.totalUnreadChatsCount,
                                    builder: (context, unreadChats, _) {
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          const Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 20,
                                            color: Color(0xFF2D1557),
                                          ),
                                          if (unreadChats > 0)
                                            Positioned(
                                              right: -2,
                                              top: -2,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF7C3AED),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Notification Icon with Dynamic Badge Dot
                          GestureDetector(
                            onTap:
                                () => NotificationCenterSheet.show(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF5B21B6).withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ValueListenableBuilder<int>(
                                valueListenable:
                                    NotificationCenterSheet.unreadCountNotifier,
                                builder: (context, unreadCount, _) {
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(
                                        Icons.notifications_none_rounded,
                                        size: 22,
                                        color: Color(0xFF2D1557),
                                      ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          right: -1,
                                          top: -1,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFE11D48),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Scrollable Body Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header Card (Greeting, Quote, and 3D Character)
                    Container(
                      key: widget.headerKey,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFAF5FF), // Soft periwinkle top
                            Color(0xFFF3E8FF), // Soft lavender middle
                            Color(0xFFFCE7F3), // Soft pink blush bottom
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1A5B21B6),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Welcome Greeting Text (Left aligned)
                                Padding(
                                  padding: const EdgeInsets.only(right: 110),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        greetingText,
                                        style: GoogleFonts.nunito(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        userName,
                                        style: GoogleFonts.nunito(
                                          fontSize: 27,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF1E1B4B),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Dynamic Gen-Z Daily Motivational Quote Card (Left aligned)
                                Padding(
                                  padding: const EdgeInsets.only(right: 105),
                                  child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.95,
                                          ),
                                          borderRadius: BorderRadius.circular(22),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF5B21B6,
                                              ).withValues(alpha: 0.12),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                            BoxShadow(
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(-2, -2),
                                            ),
                                          ],
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 350,
                                          ),
                                          child: Text(
                                            '"$_dailyQuote"',
                                            key: ValueKey(_dailyQuote),
                                            style: GoogleFonts.nunito(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              fontStyle: FontStyle.italic,
                                              color: const Color(0xFF4C1D95),
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      )
                                      .animate()
                                      .fadeIn(duration: 400.ms)
                                      .slideY(begin: 0.1),
                                ),
                              ],
                            ),

                            // Transparent 3D Character Illustration on Pedestal (Right side)
                            Positioned(
                              right: 0,
                              bottom: -6,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  // 3D Floor Shadow under feet/pedestal for depth
                                  Container(
                                    height: 14,
                                    width: 75,
                                    margin: const EdgeInsets.only(bottom: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF5B21B6,
                                      ).withValues(alpha: 0.22),
                                      borderRadius: const BorderRadius.all(
                                        Radius.elliptical(75, 14),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF5B21B6,
                                          ).withValues(alpha: 0.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 3D Standing Gigi Pedestal Character with floating animation
                                  Image.asset(
                                        'assets/images/gigi_standing_pedestal_transparent.png',
                                        height: 155,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (ctx, err, stack) => Image.asset(
                                              'assets/images/gigi_avatar.png',
                                              height: 140,
                                              fit: BoxFit.contain,
                                            ),
                                      )
                                      .animate(
                                        onPlay: (c) => c.repeat(reverse: true),
                                      )
                                      .moveY(
                                        begin: 0,
                                        end: -5,
                                        duration: 2500.ms,
                                        curve: Curves.easeInOut,
                                      ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

            const SizedBox(height: 20),

            // 2. Body Section: Cards and Features (Next card starts cleanly after header)
            Builder(
              builder: (context) {
                final double screenWidth = MediaQuery.of(context).size.width;
                final double horizontalPadding =
                    screenWidth < 360 ? 14.0 : 20.0;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Actions Carousel (Placed ABOVE Period Tracker Card)
                      _buildQuickActionsHeader(context),

                      const SizedBox(height: 12),

                      _buildQuickActionsCarousel(context),

                      // Daughter Health & Activity Summary Card (for Parent users)
                      if (storage.role?.toUpperCase() != 'TEEN') ...[
                        const ParentDaughterSummaryHomeCard(),
                        const SizedBox(height: 22),
                      ],

                      // Animated Menstrual Tracker Snapshot Card
                      Container(
                        key: widget.trackerKey,
                        child: const MenstrualTrackerSnapshotCard(),
                      ),

                      const SizedBox(height: 24),

                      // Creative Journey Active Card
                      Container(
                        key: widget.journeyKey,
                        child: BlocBuilder<JourneyMapCubit, JourneyMapState>(
                          builder: (context, state) {
                            if (state is JourneyMapLoaded) {
                              return CreativeJourneyHomeCard(
                                journeys: state.journeys,
                                allProgress: state.allProgress,
                                isLoading: false,
                              );
                            } else if (state is JourneyMapLoading) {
                              return const CreativeJourneyHomeCard(
                                isLoading: true,
                              );
                            }
                            return const CreativeJourneyHomeCard();
                          },
                        ),
                      ),

                      const SizedBox(height: 44),

                      // Recommended Peer Mentors Section (Placed BELOW Learning Journey Card)
                      const RecommendedPeerMentorsSection(),

                      const SizedBox(height: 44),

                      // Community Pulse & Weekly Challenge Section
                      const CommunityPulseChallengeSection(),

                      const SizedBox(height: 44),

                      // Explore Circles Section (Placed BELOW Community Pulse)
                      const ExploreCirclesHomepageSection(),

                      const SizedBox(height: 44),

                      // Good To Know Articles Spotlight Section
                      const GoodToKnowHomepageSection(),

                      const SizedBox(height: 44),

                      // Closing Poster Footer Section
                      const HomepageFooterPosterSection(),

                      const SizedBox(height: 44),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  ],
),
),
);
  }

  Widget _buildQuickActionsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '⚡ QUICK ACTIONS',
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1E1B4B),
            letterSpacing: 0.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Instant Access 🚀',
            style: GoogleFonts.nunito(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCarousel(BuildContext context) {
    final actions = [
      (
        emoji: '⚡',
        title: 'Daily Quests',
        badge: '+50 Coins',
        bgColors: const [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
        borderColor: const Color(0xFFA5B4FC),
        textColor: const Color(0xFF4338CA),
        badgeBg: const Color(0xFFE0E7FF),
        badgeText: const Color(0xFF3730A3),
        onTap: () {
          AppSoundService.instance.playPop();
          context.push('/quests');
        },
      ),
      (
        emoji: '📓',
        title: 'Journal',
        badge: '🔥 1d Streak',
        bgColors: const [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
        borderColor: const Color(0xFFDDD6FE),
        textColor: const Color(0xFF6D28D9),
        badgeBg: const Color(0xFFEDE9FE),
        badgeText: const Color(0xFF7C3AED),
        onTap: () {
          AppSoundService.instance.playPop();
          context.push('/journal');
        },
      ),
      (
        emoji: '🤝',
        title: 'Peer Line',
        badge: '🟢 Online',
        bgColors: const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
        borderColor: const Color(0xFFA7F3D0),
        textColor: const Color(0xFF047857),
        badgeBg: const Color(0xFFD1FAE5),
        badgeText: const Color(0xFF059669),
        onTap: () {
          AppSoundService.instance.playPop();
          context.read<DashboardCubit>().setTab(4);
        },
      ),
      (
        emoji: '💡',
        title: 'Good To Know',
        badge: 'Articles',
        bgColors: const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
        borderColor: const Color(0xFF86EFAC),
        textColor: const Color(0xFF15803D),
        badgeBg: const Color(0xFFDCFCE7),
        badgeText: const Color(0xFF166534),
        onTap: () {
          AppSoundService.instance.playPop();
          try {
            context.push('/good-to-know');
          } catch (_) {
            context.read<DashboardCubit>().setTab(1);
          }
        },
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children:
            actions.asMap().entries.map((entry) {
              final item = entry.value;
              final isLast = entry.key == actions.length - 1;

              return Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 12),
                child: GestureDetector(
                  onTap: item.onTap,
                  child: Container(
                    width: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: item.bgColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: item.borderColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 6,
                          offset: const Offset(-2, -2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          // Live Background Design Element: Glowing Radial Glass Orb
                          Positioned(
                            top: -15,
                            right: -15,
                            child: Container(
                              width: 65,
                              height: 65,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.65),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Card Content Container with 3D Glass Layer
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            color: Colors.white.withValues(alpha: 0.12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.emoji,
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.badgeBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        item.badge,
                                        style: GoogleFonts.nunito(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: item.badgeText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item.title,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: item.textColor,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

/// RecommendedPeerMentorsSection
/// Styled to match the Connect module PeerLine layout cleanly with signature #644D95 and #B48BA6 theme.
class RecommendedPeerMentorsSection extends StatefulWidget {
  const RecommendedPeerMentorsSection({super.key});

  @override
  State<RecommendedPeerMentorsSection> createState() =>
      _RecommendedPeerMentorsSectionState();
}

class _RecommendedPeerMentorsSectionState
    extends State<RecommendedPeerMentorsSection> {
  int _selectedTopicIndex = 0;
  bool _isLoading = true;

  static const Color _purpleTheme = Color(0xFF644D95);

  List<PeerLineTopic> _topics = [];
  List<Map<String, dynamic>> _mentors = [];
  List<PeerLineSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = CommunityApi(ApiService.instance.dio);
      final results = await Future.wait([
        api.getPeerLineTopics(),
        api.searchMentors([]),
        api.getPeerLineSessions(role: 'mentee'),
      ]);

      if (mounted) {
        setState(() {
          _topics = results[0] as List<PeerLineTopic>;
          _mentors = results[1] as List<Map<String, dynamic>>;
          _sessions = results[2] as List<PeerLineSession>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[RecommendedPeerMentors] Error loading peer data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMentorsForTopic(String? topicId) async {
    try {
      final api = CommunityApi(ApiService.instance.dio);
      final filter = (topicId != null && topicId.isNotEmpty) ? [topicId] : <String>[];
      final mentors = await api.searchMentors(filter);
      if (mounted) {
        setState(() {
          _mentors = mentors;
        });
      }
    } catch (e) {
      debugPrint('[RecommendedPeerMentors] Error filtering mentors: $e');
    }
  }

  PeerLineSession? _findActiveConversationForMentor(Map<String, dynamic> mentor) {
    return PeerSessionHelper.findActiveSession(mentor, _sessions);
  }

  bool _isChatInitiated(Map<String, dynamic> mentor) {
    return _findActiveConversationForMentor(mentor) != null;
  }

  Future<void> _handleMentorAction(
    Map<String, dynamic> mentor, {
    BuildContext? dialogCtx,
  }) async {
    AppSoundService.instance.playPop();
    if (dialogCtx != null && Navigator.canPop(dialogCtx)) {
      Navigator.pop(dialogCtx);
    }

    final mentorName = mentor['name'] as String? ?? 'Peer Mentor';
    final existingSession = _findActiveConversationForMentor(mentor);

    if (existingSession != null) {
      // Existing active conversation found -> open chat screen immediately!
      if (mounted) {
        context.push('/peerline/chat/${existingSession.id}');
      }
      return;
    }

    try {
      final api = CommunityApi(ApiService.instance.dio);
      final rawTopics = mentor['certifiedTopicIds'] ?? mentor['topics'] ?? [];
      final List<String> topicIds = rawTopics is List ? rawTopics.map((e) => e.toString()).toList() : [];

      final session = await api.requestConnection(
        mentorId: mentor['id'] ?? '',
        topicIds: topicIds,
      );

      if (mounted) {
        setState(() {
          _sessions = [session, ..._sessions];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🌸', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Connected with $mentorName! Opening chat...',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: _purpleTheme,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        context.push('/peerline/chat/${session.id}');
      }
    } catch (e) {
      debugPrint('[RecommendedPeerMentors] Error requesting session: $e');
      if (mounted) {
        if (_sessions.isNotEmpty) {
          context.push('/peerline/chat/${_sessions.first.id}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Chat request sent to $mentorName! Opening PeerLine...',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              backgroundColor: _purpleTheme,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          context.read<DashboardCubit>().setTab(4);
        }
      }
    }
  }

  void _showMentorDetailSheet(
    BuildContext context,
    Map<String, dynamic> mentor,
  ) {
    PeerMentorDetailSheet.show(
      context: context,
      mentor: mentor,
      sessions: _sessions,
      onAction: (m) => _handleMentorAction(m),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> pastelColors = const [
      Color(0xFFF7EFF5),
      Color(0xFFF4EAF1),
      Color(0xFFFAF2F7),
      Color(0xFFF5ECF3),
    ];

    final displayTopics = [
      (emoji: '✨', title: 'All Topics', id: null as String?),
      ..._topics.map((t) => (emoji: t.emoji.isNotEmpty ? t.emoji : '🌸', title: t.name, id: t.id as String?))
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Recommended Peer Mentors',
              style: GoogleFonts.nunito(
                fontSize: 18.5,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E1B4B),
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {
                AppSoundService.instance.playPop();
                context.read<DashboardCubit>().setTab(4);
              },
              child: Text(
                'View All',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _purpleTheme,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: Color(0xFF059669),
            ),
            const SizedBox(width: 5),
            Text(
              'All mentors are certified & verified',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF059669),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children:
                displayTopics.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final topic = entry.value;
                  final isSelected = _selectedTopicIndex == idx;
                  final isLast = idx == displayTopics.length - 1;

                  return Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 8),
                    child: GestureDetector(
                      onTap: () {
                        AppSoundService.instance.playPop();
                        setState(() {
                          _selectedTopicIndex = idx;
                        });
                        _loadMentorsForTopic(topic.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8.5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? _purpleTheme
                                  : Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected
                                    ? _purpleTheme
                                    : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  isSelected
                                      ? _purpleTheme.withValues(alpha: 0.28)
                                      : Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(topic.emoji, style: const TextStyle(fontSize: 13.5)),
                            const SizedBox(width: 6),
                            Text(
                              topic.title,
                              style: GoogleFonts.nunito(
                                fontSize: 12.5,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 305,
          child: _isLoading
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 2,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 285,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(26),
                      ),
                    );
                  },
                )
              : _mentors.isEmpty
                  ? Center(
                      child: Text(
                        'No peer mentors available for this topic yet.',
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    )
                  : ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(top: 4, bottom: 18),
            itemCount: _mentors.length,
            itemBuilder: (context, index) {
              final mentor = _mentors[index];
              final isLast = index == _mentors.length - 1;
              final mentorId = (mentor['id'] as String?) ?? '$index';
              final cardBg = pastelColors[mentorId.hashCode.abs() % pastelColors.length];

              final name = mentor['name'] ?? mentor['fullName'] ?? 'Peer Mentor';
              final initial = (mentor['initial'] as String?) ?? (name.toString().isNotEmpty ? name.toString().substring(0, 1).toUpperCase() : 'P');
              final rating = (mentor['rating']?.toString()) ?? '5.0';
              final quote = mentor['quote'] ?? mentor['bio'] ?? 'Helping girls navigate their journey with empathy, warmth, and care.';

              final rawBadges = mentor['topics'] ?? mentor['certifiedTopicIds'] ?? [];
              final List<String> badges = (rawBadges is List)
                  ? rawBadges.map<String>((b) => b is Map ? (b['name']?.toString() ?? '') : b.toString()).where((s) => s.isNotEmpty).toList()
                  : ['Mental & Emotional Health'];

              return GestureDetector(
                onTap: () => _showMentorDetailSheet(context, mentor),
                child: Container(
                  width: 285,
                  margin: EdgeInsets.only(right: isLast ? 0 : 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB48BA6).withValues(alpha: 0.32),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.7),
                        blurRadius: 8,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Stack(
                      children: [
                        // Live Background Element 1: Top-Right Glowing Glass Radial Orb
                        Positioned(
                          top: -25,
                          right: -25,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.7),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Live Background Element 2: Bottom-Left Rose Watermark Motif
                        Positioned(
                          bottom: -15,
                          left: -15,
                          child: Opacity(
                            opacity: 0.05,
                            child: const Text(
                              '🌸',
                              style: TextStyle(fontSize: 90),
                            ),
                          ),
                        ),

                        // Main Card Content Container with 3D Glass Layer
                        Container(
                          padding: const EdgeInsets.all(22),
                          color: Colors.white.withValues(alpha: 0.15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            initial,
                                            style: GoogleFonts.nunito(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFF1E1B4B),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: GoogleFonts.nunito(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF1E1B4B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              size: 17,
                                              color: Color(0xFFF59E0B),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              rating,
                                              style: GoogleFonts.nunito(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w900,
                                                color: const Color(0xFFD97706),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children:
                                    badges.take(2).map((
                                      badgeText,
                                    ) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.95,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          badgeText,
                                          style: GoogleFonts.nunito(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF475569),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                              ),
                              Text(
                                quote,
                                style: GoogleFonts.nunito(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // Dynamic Chat Request / Start Chat Button
                              Builder(
                                builder: (btnCtx) {
                                  final bool hasChat = _isChatInitiated(mentor);
                                  final String cardCtaText = hasChat ? 'Start Chat' : 'Chat Request';
                                  final IconData cardCtaIcon = hasChat ? Icons.chat_bubble_rounded : Icons.send_rounded;

                                  return GestureDetector(
                                    onTap: () => _handleMentorAction(mentor),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11.5,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: hasChat
                                              ? const [Color(0xFF8B5CF6), Color(0xFF6D28D9)]
                                              : const [Color(0xFF7A61AC), _purpleTheme],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (hasChat ? const Color(0xFF7C3AED) : _purpleTheme)
                                                .withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            cardCtaIcon,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            cardCtaText,
                                            style: GoogleFonts.nunito(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
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
      ],
    );
  }
}

/// CommunityPulseChallengeSection
/// High-energy 3D glassmorphic banner showcasing active peer challenges, live participant count,
/// progress bar, and interactive coin rewards.
class CommunityPulseChallengeSection extends StatefulWidget {
  const CommunityPulseChallengeSection({super.key});

  @override
  State<CommunityPulseChallengeSection> createState() =>
      _CommunityPulseChallengeSectionState();
}

class _CommunityPulseChallengeSectionState
    extends State<CommunityPulseChallengeSection> {
  bool _isJoined = false;
  bool _isCompleted = false;
  int _currentProgressDays = 1;
  static const int _totalDays = 3;
  static const Color _purpleTheme = Color(0xFF644D95);

  void _handleChallengeAction() {
    AppSoundService.instance.playPop();

    if (!_isJoined) {
      setState(() {
        _isJoined = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('💧', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Joined "3 Days of Mindful Hydration"! Day 1 logged! 🪙 +5 Coins',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: _purpleTheme,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (!_isCompleted) {
      if (_currentProgressDays < _totalDays) {
        setState(() {
          _currentProgressDays++;
          if (_currentProgressDays == _totalDays) {
            _isCompleted = true;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(
                  _isCompleted ? '🎉' : '✨',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isCompleted
                        ? 'Challenge Completed! Earned 20 Infano Coins! 🪙'
                        : 'Day $_currentProgressDays completed! Keep the hydration vibe going! 💧',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor:
                _isCompleted ? const Color(0xFF059669) : _purpleTheme,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      context.push('/quests');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progressPercent =
        _isJoined ? (_currentProgressDays / _totalDays) : 0.33;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title & Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Community Pulse',
              style: GoogleFonts.nunito(
                fontSize: 18.5,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E1B4B),
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {
                AppSoundService.instance.playPop();
                context.push('/quests');
              },
              child: Text(
                'View Quests',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _purpleTheme,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Subtitle
        Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              'Weekly peer challenges & streak rewards',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 3D Glassmorphic Banner with #F8CAD5 Background & Live Decorative Orbs (No Outer Border)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(
              0xFFF8CAD5,
            ), // Requested #F8CAD5 background color
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8A2B5).withValues(alpha: 0.55),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Live Background Design Element 1: Glowing Radial Glass Bubble (Top-Right)
                Positioned(
                  top: -25,
                  right: -25,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.65),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Live Background Design Element 2: Soft Rose Accent Bubble (Bottom-Center)
                Positioned(
                  bottom: -40,
                  left: 40,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFE8A2B5).withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Live Background Design Element 3: Water Drop Backdrop Motif (Bottom-Left)
                Positioned(
                  bottom: -15,
                  left: -15,
                  child: Opacity(
                    opacity: 0.07,
                    child: Icon(
                      Icons.water_drop_rounded,
                      size: 110,
                      color: const Color(0xFF4A1525),
                    ),
                  ),
                ),

                // Main Banner Foreground Content inside 3D Glass Layer
                Container(
                  padding: const EdgeInsets.all(
                    24,
                  ), // Increased padding for spacious elegance
                  color: Colors.white.withValues(
                    alpha: 0.15,
                  ), // Glass tint layer
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Active Challenge Badge + Coin Reward Pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE8A2B5),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4A1525,
                                    ).withValues(alpha: 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'ACTIVE CHALLENGE',
                                      style: GoogleFonts.nunito(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF881337),
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Coin Reward Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🪙',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+20 Coins',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Title & Participant Stats Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Challenge Water Drop / Emoji Icon Container
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(
                                  0xFFF43F5E,
                                ).withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4A1525,
                                  ).withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('💧', style: TextStyle(fontSize: 28)),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '3 Days of Mindful Hydration',
                                  style: GoogleFonts.nunito(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(
                                      0xFF4A1525,
                                    ), // Deep rich plum text for contrast
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.group_rounded,
                                      size: 14,
                                      color: Color(0xFF881337),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '1,240 girls participating!',
                                      style: GoogleFonts.nunito(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF881337),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Progress Bar & Percentage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isJoined
                                ? 'Progress: $_currentProgressDays of $_totalDays Days Complete'
                                : 'Challenge Goal: 3 Days Hydration Streak',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF6B1D36),
                            ),
                          ),
                          Text(
                            '${(progressPercent * 100).toInt()}%',
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF4A1525),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Animated Progress Bar Container
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progressPercent,
                          minHeight: 9,
                          backgroundColor: Colors.white.withValues(alpha: 0.6),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFDB337D),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Join Challenge / Action CTA Button (#DB337D Signature Gradient)
                      GestureDetector(
                        onTap: _handleChallengeAction,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13.5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  _isCompleted
                                      ? const [
                                        Color(0xFF10B981),
                                        Color(0xFF059669),
                                      ]
                                      : const [
                                        Color(0xFFF43F5E),
                                        Color(0xFFDB337D),
                                      ], // Requested #DB337D Color!
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFDB337D,
                                ).withValues(alpha: 0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isCompleted
                                    ? '🎉 Challenge Completed!'
                                    : _isJoined
                                    ? 'Complete Day $_currentProgressDays 🎯'
                                    : 'Join Challenge ⚡',
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ExploreCirclesHomepageSection
/// Homepage section surfacing Circles community hubs with full Connect module functionality.
class ExploreCirclesHomepageSection extends StatefulWidget {
  const ExploreCirclesHomepageSection({super.key});

  @override
  State<ExploreCirclesHomepageSection> createState() =>
      _ExploreCirclesHomepageSectionState();
}

class _ExploreCirclesHomepageSectionState
    extends State<ExploreCirclesHomepageSection> {
  int _selectedCategoryIndex = 0;
  List<Circle> _loadedCircles = [];
  bool _isLoading = true;

  static const Color _purpleTheme = Color(0xFF644D95);

  final List<String> _categories = const [
    "All",
    "Wellness",
    "Puberty",
    "Growth",
    "Social",
  ];

  // Default curated circles as instant fallback / initial display
  final List<Circle> _fallbackCircles = [
    Circle(
      id: 'c1',
      slug: 'period-power',
      name: 'Period Power Circle',
      description:
          'Safe space to chat about period symptoms, tips, and body changes.',
      iconEmoji: '🩸',
      accentColor: '#DB337D',
      isAgeSpecific: false,
      memberCount: 4820,
      isJoined: false,
    ),
    Circle(
      id: 'c2',
      slug: 'mindful-teens',
      name: 'Mindful Teens Hub',
      description:
          'Daily mental wellness rituals, relaxation tips, and emotional balance.',
      iconEmoji: '🧘',
      accentColor: '#7C3AED',
      isAgeSpecific: false,
      memberCount: 3250,
      isJoined: false,
    ),
    Circle(
      id: 'c3',
      slug: 'body-confidence',
      name: 'Body Positivity Safe Space',
      description:
          'Embrace self-love, celebrate body growth, and boost self-esteem.',
      iconEmoji: '💖',
      accentColor: '#EC4899',
      isAgeSpecific: false,
      memberCount: 5100,
      isJoined: false,
    ),
    Circle(
      id: 'c4',
      slug: 'study-lounge',
      name: 'Study & Exam Lounge',
      description:
          'Share study hacks, defeat exam stress, and encourage each other.',
      iconEmoji: '📚',
      accentColor: '#3B82F6',
      isAgeSpecific: false,
      memberCount: 2940,
      isJoined: false,
    ),
    Circle(
      id: 'c5',
      slug: 'self-care-vibes',
      name: 'Self-Care & Daily Vibes',
      description: 'Skincare tips, cozy routines, and positive daily vibes.',
      iconEmoji: '🌸',
      accentColor: '#10B981',
      isAgeSpecific: false,
      memberCount: 6050,
      isJoined: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchCircles();
  }

  void _fetchCircles() {
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      api
          .getCircles()
          .then((circles) {
            if (mounted && circles.isNotEmpty) {
              setState(() {
                _loadedCircles = circles;
                _isLoading = false;
              });
            } else if (mounted) {
              setState(() {
                _loadedCircles = _fallbackCircles;
                _isLoading = false;
              });
            }
          })
          .catchError((_) {
            if (mounted) {
              setState(() {
                _loadedCircles = _fallbackCircles;
                _isLoading = false;
              });
            }
          });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadedCircles = _fallbackCircles;
          _isLoading = false;
        });
      }
    }
  }

  void _showCircleDetails(Circle circle) {
    AppSoundService.instance.playPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CircleDetailsSheet(circle: circle),
    ).then((joined) {
      if (joined == true) {
        _fetchCircles();
      }
    });
  }

  bool _matchesCategory(Circle circle, String category) {
    if (category == "All") return true;
    final name = circle.name.toLowerCase();
    final desc = (circle.description ?? '').toLowerCase();
    if (category == "Wellness")
      return name.contains("self-care") ||
          name.contains("mindful") ||
          desc.contains("wellness");
    if (category == "Puberty")
      return name.contains("period") ||
          name.contains("body") ||
          desc.contains("symptoms");
    if (category == "Growth")
      return name.contains("teen") ||
          name.contains("power") ||
          desc.contains("growth");
    if (category == "Social")
      return name.contains("general") ||
          name.contains("chat") ||
          name.contains("lounge");
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final displayCircles = _isLoading ? _fallbackCircles : _loadedCircles;
    final categoryName = _categories[_selectedCategoryIndex];
    final filtered =
        displayCircles.where((c) => _matchesCategory(c, categoryName)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Explore Circles',
              style: GoogleFonts.nunito(
                fontSize: 18.5,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E1B4B),
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {
                AppSoundService.instance.playPop();
                context.read<DashboardCubit>().setTab(4);
              },
              child: Text(
                'View All',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _purpleTheme,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Subtitle Badge
        Row(
          children: [
            const Text('🌸', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              'Safe, moderated peer communities for girls',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Category Filter Bar (Horizontal Scroll)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children:
                _categories.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final catName = entry.value;
                  final isSelected = _selectedCategoryIndex == idx;
                  final isLast = idx == _categories.length - 1;

                  return Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 8),
                    child: GestureDetector(
                      onTap: () {
                        AppSoundService.instance.playPop();
                        setState(() {
                          _selectedCategoryIndex = idx;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? _purpleTheme
                                  : Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected
                                    ? _purpleTheme
                                    : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  isSelected
                                      ? _purpleTheme.withValues(alpha: 0.28)
                                      : Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          catName,
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight:
                                isSelected ? FontWeight.w900 : FontWeight.w700,
                            color:
                                isSelected
                                    ? Colors.white
                                    : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),

        const SizedBox(height: 18),

        // Explore Circles Cards Carousel (Horizontal Scroll)
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final circle = filtered[index];
              final isLast = index == filtered.length - 1;

              Color accentColor;
              try {
                accentColor = Color(
                  int.parse(circle.accentColor.replaceAll('#', '0xFF')),
                );
              } catch (_) {
                accentColor = _purpleTheme;
              }

              return Container(
                width: 250,
                margin: EdgeInsets.only(right: isLast ? 0 : 14),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Live Background Element 1: Top-Right Glowing Glass Radial Orb
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.7),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Live Background Element 2: Bottom-Right Watermark Icon
                      Positioned(
                        bottom: -15,
                        right: -15,
                        child: Opacity(
                          opacity: 0.07,
                          child: Icon(
                            Icons.explore_rounded,
                            size: 85,
                            color: accentColor,
                          ),
                        ),
                      ),

                      // Main Card Content Container with 3D Glass Layer
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.white.withValues(alpha: 0.12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Row: Emoji Icon + Private Lock / Member Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.06,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      circle.iconEmoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),

                                // Member Count Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.people_alt_rounded,
                                        size: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        circle.memberCount != null
                                            ? '${circle.memberCount}'
                                            : 'Community',
                                        style: GoogleFonts.nunito(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Circle Title
                            Text(
                              circle.name,
                              style: GoogleFonts.nunito(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1E1B4B),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Description
                            Text(
                              circle.description ??
                                  'Join the conversation & connect with peers.',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 8),

                            // Full-width CTA Button: Join Circle / View Details
                            GestureDetector(
                              onTap: () => _showCircleDetails(circle),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      circle.isJoined
                                          ? 'View Circle'
                                          : 'Explore & Join',
                                      style: GoogleFonts.nunito(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// GoodToKnowHomepageSection
/// Homepage carousel showcasing Good To Know articles with large illustration cards,
/// GoodToKnowHomepageSection
/// Homepage carousel showcasing Good To Know articles matching the Good To Know module.
/// Tapping an article opens the full ArticleDetailScreen directly.
class GoodToKnowHomepageSection extends StatefulWidget {
  const GoodToKnowHomepageSection({super.key});

  @override
  State<GoodToKnowHomepageSection> createState() =>
      _GoodToKnowHomepageSectionState();
}

class _GoodToKnowHomepageSectionState extends State<GoodToKnowHomepageSection> {
  static const Color _purpleTheme = Color(0xFF644D95);

  bool _isLoading = true;
  List<Map<String, dynamic>> _articles = [];

  static const List<Map<String, dynamic>> _fallbackArticles = [
    {
      'id': 'art_1',
      'title': 'What counts as a late period?',
      'readTime': '7 min read',
      'emoji': '🩸',
      'accentColor': Color(0xFF9333EA),
      'cardBg': Color(0xFFF3E8FF),
      'phase': 'menstrual',
    },
    {
      'id': 'art_2',
      'title': '7 signs of perimenopause & body shifts',
      'readTime': '13 min read',
      'emoji': '🌸',
      'accentColor': Color(0xFF0D9488),
      'cardBg': Color(0xFFE0F2FE),
      'phase': 'follicular',
    },
    {
      'id': 'art_3',
      'title': '5 foods that relieve cramps naturally',
      'readTime': '4 min read',
      'emoji': '🥑',
      'accentColor': Color(0xFF059669),
      'cardBg': Color(0xFFECFDF5),
      'phase': 'menstrual',
    },
    {
      'id': 'art_4',
      'title': 'Teen Skincare 101: Glow Without Chemicals',
      'readTime': '3 min read',
      'emoji': '✨',
      'accentColor': Color(0xFFE11D48),
      'cardBg': Color(0xFFFFF1F2),
      'phase': 'general',
    },
    {
      'id': 'art_5',
      'title': 'Defeating exam stress with 4-7-8 breathing',
      'readTime': '3 min read',
      'emoji': '📚',
      'accentColor': Color(0xFF2563EB),
      'cardBg': Color(0xFFEFF6FF),
      'phase': 'general',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    try {
      final response = await ApiService.instance.dio.get('tracker/articles');
      if (response.statusCode == 200 && response.data is List) {
        final List raw = response.data as List;
        if (raw.isNotEmpty) {
          final List<Color> cardBgs = const [
            Color(0xFFF3E8FF),
            Color(0xFFE0F2FE),
            Color(0xFFECFDF5),
            Color(0xFFFFF1F2),
            Color(0xFFEFF6FF),
          ];
          final List<Color> accentColors = const [
            Color(0xFF9333EA),
            Color(0xFF0D9488),
            Color(0xFF059669),
            Color(0xFFE11D48),
            Color(0xFF2563EB),
          ];

          final mapped =
              raw.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value as Map;
                return {
                  'id': item['id']?.toString() ?? 'art_$idx',
                  'title': item['title']?.toString() ?? '',
                  'readTime':
                      (item['readTime'] ?? item['time'] ?? '3 min read')
                          .toString(),
                  'emoji': item['emoji']?.toString() ?? '📖',
                  'phase': item['phase']?.toString() ?? 'general',
                  'cardBg': cardBgs[idx % cardBgs.length],
                  'accentColor': accentColors[idx % accentColors.length],
                };
              }).toList();

          if (mounted) {
            setState(() {
              _articles = mapped.cast<Map<String, dynamic>>();
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[GoodToKnowHomepageSection] Error loading API articles: $e');
    }

    if (mounted) {
      setState(() {
        _articles = _fallbackArticles;
        _isLoading = false;
      });
    }
  }

  void _openArticleDetailScreen(
    BuildContext context,
    Map<String, dynamic> article,
  ) {
    AppSoundService.instance.playPop();

    final Map<String, String> mappedArt = {
      'title': article['title']?.toString() ?? '',
      'emoji': article['emoji']?.toString() ?? '📖',
      'time':
          (article['readTime'] ?? article['time'] ?? '3 min read').toString(),
      'phase': (article['phase'] ?? '').toString(),
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArticleDetailScreen(article: mappedArt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth * 0.46).clamp(165.0, 190.0);
    final double imageHeight = (cardWidth * 0.88).clamp(142.0, 160.0);
    final double listContainerHeight = imageHeight + 98.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Good To Know',
              style: GoogleFonts.nunito(
                fontSize: 18.5,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E1B4B),
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {
                AppSoundService.instance.playPop();
                try {
                  context.push('/good-to-know');
                } catch (_) {
                  context.read<DashboardCubit>().setTab(1);
                }
              },
              child: Text(
                'View All',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _purpleTheme,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Subtitle
        Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              'Essential health & wellness guide for girls',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Article Cards Horizontal Carousel
        SizedBox(
          height: listContainerHeight,
          child:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: _purpleTheme),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.only(top: 4, bottom: 18),
                    itemCount: _articles.length,
                    itemBuilder: (context, index) {
                      final article = _articles[index];
                      final isLast = index == _articles.length - 1;
                      final Color cardBg = article['cardBg'] as Color;
                      final Color accentColor = article['accentColor'] as Color;

                      return GestureDetector(
                        onTap: () => _openArticleDetailScreen(context, article),
                        child: SizedBox(
                          width: cardWidth,
                          child: Padding(
                            padding: EdgeInsets.only(right: isLast ? 0 : 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Large Top Image Container with 3D Glass & Live Radial Sparkle
                                Container(
                                  width: cardWidth,
                                  height: imageHeight,
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withValues(
                                          alpha: 0.18,
                                        ),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(-2, -2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Stack(
                                      children: [
                                        // Live Background Element 1: Glowing Glass Radial Orb
                                        Positioned(
                                          top: -20,
                                          right: -20,
                                          child: Container(
                                            width: 90,
                                            height: 90,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: RadialGradient(
                                                colors: [
                                                  Colors.white.withValues(
                                                    alpha: 0.7,
                                                  ),
                                                  Colors.white.withValues(
                                                    alpha: 0,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Live Background Element 2: Subtle Watermark Emoji
                                        Positioned(
                                          bottom: -10,
                                          right: -10,
                                          child: Opacity(
                                            opacity: 0.08,
                                            child: Text(
                                              article['emoji'] as String,
                                              style: const TextStyle(
                                                fontSize: 75,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Centered Hero Illustration Emoji / Graphic Container
                                        Center(
                                          child: Container(
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                article['emoji'] as String,
                                                style: const TextStyle(
                                                  fontSize: 34,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Title (Below Image)
                                Text(
                                  article['title'] as String,
                                  style: GoogleFonts.nunito(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E1B4B),
                                    height: 1.22,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 4),

                                // Read Time (Below Title)
                                Text(
                                  article['readTime'] as String,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
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
      ],
    );
  }
}

/// HomepageFooterPosterSection
/// Open poster section at the end of the homepage featuring a large Gigi transparent character (280px tall)
/// on the left, 60px lighter-shaded "Built with Love and Care" bold title, subtext, and official Infano logo on the right.
class HomepageFooterPosterSection extends StatelessWidget {
  const HomepageFooterPosterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = (screenWidth * 0.11).clamp(38.0, 60.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Side: Big Gigi Transparent Image (280px height - Double size)
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Floor shadow under feet
              Container(
                height: 14,
                width: 110,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF644D95).withValues(alpha: 0.18),
                  borderRadius: const BorderRadius.all(
                    Radius.elliptical(110, 14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF644D95).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),

              // Double Sized Transparent Gigi Image (~280px height)
              Image.asset(
                'assets/images/gigi_standing_purple_hoodie_transparent.png',
                height: 280,
                fit: BoxFit.contain,
                errorBuilder:
                    (ctx, err, stack) => Image.asset(
                      'assets/images/gigi_standing_pedestal_transparent.png',
                      height: 260,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (c, e, s) => Image.asset(
                            'assets/images/gigi_avatar.png',
                            height: 220,
                            fit: BoxFit.contain,
                          ),
                    ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Right Side: 60px Bold Lighter Shade Title, Subtext, and Infano Logo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Official Infano Logo (Replaces "Infano Care" text)
                Image.asset(
                  'assets/images/infano_logo.png',
                  height: 38,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (ctx, err, stack) => Text(
                        'infano.care',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFDB337D),
                        ),
                      ),
                ),

                const SizedBox(height: 12),

                // 60px Bold Lighter Shade Title ("Built with Love and Care")
                Text(
                  'Built with\nLove and Care',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w900,
                    color: const Color(
                      0xFF644D95,
                    ).withValues(alpha: 0.85), // Lighter soft purple shade
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 10),

                // Subtext in soft, lighter grey font
                Text(
                  'for every adolescent girl in the journey of girlhood to adulthood to womanhood',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B).withValues(alpha: 0.85),
                    height: 1.35,
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
