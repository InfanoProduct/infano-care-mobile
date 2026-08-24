import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:infano_care_mobile/features/auth/repository/auth_repository.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/home/bloc/dashboard_cubit.dart';
import 'package:infano_care_mobile/features/home/screens/home_screen.dart';

import 'package:infano_care_mobile/features/home/screens/track_screen.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/screens/connect/connect_screen.dart';
import 'package:infano_care_mobile/screens/connect/circle_screen.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/quest_repository.dart';
import 'package:infano_care_mobile/features/tracker/bloc/quest_bloc.dart';
import 'package:infano_care_mobile/features/learning/screens/learn_hub_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/services/community_socket_service.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.storage,
    this.initialTab = 0,
    this.initialSubTab = 1,
  });

  final LocalStorageService storage;
  final int initialTab;
  final int initialSubTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  bool _isExpanded = true;
  StreamSubscription? _peerlineSocketSub;
  StreamSubscription? _fcmMessageSub;
  Timer? _collapseTimer;

  final List<int> _tabHistory = [];
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    // Ensure native splash is removed if we land here directly
    FlutterNativeSplash.remove();
    _syncProfile();
    _startCollapseTimer();

    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socket = Provider.of<CommunitySocketService>(
        context,
        listen: false,
      );

      _peerlineSocketSub = socket.chatEvents.listen((event) {
        if (event['type'] == 'session_ready' && mounted) {
          final sessionId = event['sessionId']?.toString();
          if (sessionId != null) {
            _showSessionReadyDialog(sessionId);
          }
        }
      });
    });
  }

  /// Refetch notification badge whenever the app returns to the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {}
  }

  void _showSessionReadyDialog(String sessionId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.forum_rounded,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mentor Connected!',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'A peer mentor has accepted your chat request and is waiting for you in chat.',
              style: GoogleFonts.nunito(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Dismiss',
                  style: GoogleFonts.nunito(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/peerline/chat/$sessionId');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Join Chat Now',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  void _startCollapseTimer() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isExpanded = false;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _peerlineSocketSub?.cancel();
    _fcmMessageSub?.cancel();
    _collapseTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncProfile() async {
    debugPrint(
      '[DashboardScreen] Starting background profile sync. Current local displayName: "${widget.storage.displayName}"',
    );
    try {
      final repo = AuthRepository(widget.storage);
      await repo.syncProfile();
      debugPrint(
        '[DashboardScreen] Background profile sync completed successfully ✅ Stored displayName after sync: "${widget.storage.displayName}"',
      );
    } catch (e) {
      debugPrint('[DashboardScreen] Background profile sync failed ❌: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<LocalStorageService>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DashboardCubit(initialIndex: widget.initialTab),
        ),
        BlocProvider(
          create:
              (context) =>
                  QuestBloc(QuestRepository(ApiService.instance.dio))
                    ..add(const QuestEvent.load()),
        ),
      ],
      child: BlocListener<DashboardCubit, DashboardState>(
        listener: (context, state) {
          if (state.selectedIndex == 3) {
            context.read<QuestBloc>().add(const QuestEvent.refresh());
          }
        },
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            final screens = [
              const HomeScreen(),
              LearnHubScreen(storage: storage),
              const TrackScreen(),
              const ConnectScreen(),
              CircleScreen(initialTab: widget.initialSubTab),
            ];

            final selectedIndex = state.selectedIndex;
            if (_currentTab != selectedIndex) {
              _tabHistory.remove(selectedIndex);
              _tabHistory.add(_currentTab);
              _currentTab = selectedIndex;
            }

            return PopScope(
              canPop: _tabHistory.isEmpty,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                if (_tabHistory.isNotEmpty) {
                  final prev = _tabHistory.removeLast();
                  _currentTab = prev;
                  if (context.mounted) {
                    context.read<DashboardCubit>().setTab(prev);
                  }
                }
              },
              child: Scaffold(
                backgroundColor: const Color(0xFFF5F4F7),
                appBar: null,
                drawer: _buildDrawer(context, storage),
                body: NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification is ScrollUpdateNotification) {
                      if (scrollNotification.scrollDelta != null &&
                          scrollNotification.scrollDelta! > 2.0) {
                        if (_isExpanded) {
                          setState(() {
                            _isExpanded = false;
                          });
                        }
                      } else if (scrollNotification.scrollDelta != null &&
                          scrollNotification.scrollDelta! < -2.0) {
                        if (!_isExpanded) {
                          setState(() {
                            _isExpanded = true;
                          });
                        }
                      }
                    }
                    return false;
                  },
                  child: SafeArea(child: screens[state.selectedIndex]),
                ),
                bottomNavigationBar: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: BottomNavigationBar(
                    currentIndex: state.selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _isExpanded = true;
                      });
                      _startCollapseTimer();
                      context.read<DashboardCubit>().setTab(index);
                    },
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: Colors.white,
                    selectedItemColor: AppColors.purple,
                    unselectedItemColor: AppColors.textLight,
                    selectedFontSize: 12,
                    unselectedFontSize: 12,
                    elevation: 0,
                    items: [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined),
                        activeIcon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: _buildBadgeIcon(
                          icon: Icons.auto_stories_outlined,
                          showRedDot: state.hasLearnNotification,
                        ),
                        activeIcon: _buildBadgeIcon(
                          icon: Icons.auto_stories,
                          showRedDot: state.hasLearnNotification,
                        ),
                        label: 'Learn',
                      ),
                      BottomNavigationBarItem(
                        icon: _buildTrackIcon(state.isPeriodImminent, false),
                        activeIcon: _buildTrackIcon(
                          state.isPeriodImminent,
                          true,
                        ),
                        label: 'Track',
                      ),
                      BottomNavigationBarItem(
                        icon: _buildBadgeIcon(
                          icon: Icons.favorite_outline,
                          showRedDot: state.hasConnectNotification,
                        ),
                        activeIcon: _buildBadgeIcon(
                          icon: Icons.favorite_rounded,
                          showRedDot: state.hasConnectNotification,
                        ),
                        label: 'Connect',
                      ),
                      BottomNavigationBarItem(
                        icon: _buildBadgeIcon(
                          icon: Icons.groups_outlined,
                          showRedDot: false,
                        ),
                        activeIcon: _buildBadgeIcon(
                          icon: Icons.groups_rounded,
                          showRedDot: false,
                        ),
                        label: 'Circle',
                      ),
                    ],
                  ),
                ),
                floatingActionButton:
                    (state.selectedIndex != 0)
                        ? null
                        : Stack(
                              alignment: Alignment.bottomRight,
                              clipBehavior: Clip.none,
                              children: [
                                // Pulse ring behind the button (only shown when collapsed)
                                if (!_isExpanded)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                          width: 56,
                                          height: 56,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFFE9D5FF),
                                                Color(0xFFFBCFE8),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                        )
                                        .animate(
                                          onPlay:
                                              (controller) =>
                                                  controller.repeat(),
                                        )
                                        .scale(
                                          begin: const Offset(1, 1),
                                          end: const Offset(1.5, 1.5),
                                          duration: 2.seconds,
                                          curve: Curves.easeOut,
                                        )
                                        .fadeOut(duration: 2.seconds),
                                  ),

                                // Main Gigi floating button
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.fastOutSlowIn,
                                  clipBehavior:
                                      Clip.antiAlias, // Clip the sliding text!
                                  height: 56,
                                  width: _isExpanded ? 160 : 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFE9D5FF),
                                        Color(0xFFFBCFE8),
                                      ], // from-purple-200 to-pink-200
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFD8B4FE,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: const Color(
                                        0xFFD8B4FE,
                                      ).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => context.push('/chat'),
                                      borderRadius: BorderRadius.circular(28),
                                      child: SizedBox.expand(
                                        child: Stack(
                                          alignment: Alignment.centerLeft,
                                          children: [
                                            // 1. Avatar Image
                                            Positioned(
                                              left:
                                                  6, // 6px padding on left matches center position when collapsed: (56-44)/2 = 6
                                              child: Container(
                                                width: 44,
                                                height: 44,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: 2,
                                                      offset: Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipOval(
                                                  child:
                                                      _isExpanded
                                                          ? Image.asset(
                                                            'assets/images/gigi_avatar.png',
                                                            fit: BoxFit.cover,
                                                          )
                                                          : Image.asset(
                                                                'assets/images/gigi_avatar.png',
                                                                fit:
                                                                    BoxFit
                                                                        .cover,
                                                              )
                                                              .animate(
                                                                onPlay:
                                                                    (
                                                                      controller,
                                                                    ) =>
                                                                        controller
                                                                            .repeat(),
                                                              )
                                                              .shake(
                                                                delay:
                                                                    3.seconds,
                                                                duration:
                                                                    800.ms,
                                                                hz: 4,
                                                              ),
                                                ),
                                              ),
                                            ),

                                            // 2. Text (only visible when expanded)
                                            if (_isExpanded)
                                              const Positioned(
                                                left: 58,
                                                child: Text(
                                                  'Talk to Gigi',
                                                  style: TextStyle(
                                                    color: Color(
                                                      0xFF4C1D95,
                                                    ), // text-purple-950
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                            .animate(
                              onPlay:
                                  (controller) =>
                                      controller.repeat(reverse: true),
                            )
                            .slideY(
                              begin: 0.0,
                              end: -0.12,
                              duration: 1500.ms,
                              curve: Curves.easeInOut,
                            ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBadgeIcon({
    required IconData icon,
    bool showRedDot = false,
    int badgeCount = 0,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showRedDot)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
        if (badgeCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.purple,
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrackIcon(bool isImminent, bool isActive) {
    final icon = Icon(
      isActive ? Icons.calendar_today : Icons.calendar_today_outlined,
    );
    if (!isImminent) return icon;

    return icon
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(
          begin: 1.0,
          end: 1.15,
          duration: 1000.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .scaleXY(begin: 1.15, end: 1.0, duration: 1000.ms);
  }

  Widget _buildDrawer(BuildContext context, LocalStorageService storage) {
    final displayName = storage.displayName ?? 'Infano User';
    final userRole = storage.role ?? 'MEMBER';
    final roleLabel =
        userRole == 'TEEN'
            ? 'Teen Member'
            : (userRole == 'PARENT' || userRole == 'GUARDIAN'
                ? 'Parent Care'
                : (userRole == 'EXPERT' ? 'Expert Partner' : 'Bloom Member'));
    final phoneOrEmail =
        storage.phone?.isNotEmpty == true
            ? storage.phone!
            : (storage.pronouns?.isNotEmpty == true
                ? storage.pronouns!
                : 'Infano Community');
    final points = storage.points;
    final displayCoins = points > 0 ? points : 150;
    final badgeCount = points > 0 ? (points ~/ 30).clamp(4, 18) : 8;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Light Profile Header ──────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              18,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFEDE9FE), width: 1.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Profile Avatar with border and soft glow
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child:
                            storage.avatarUrl != null
                                ? Image.network(
                                  storage.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) =>
                                          _buildAvatarFallback(displayName),
                                )
                                : _buildAvatarFallback(displayName),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            phoneOrEmail,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  size: 13,
                                  color: AppColors.purple,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  roleLabel,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.purple,
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
              ],
            ),
          ),

          // ── Coins & Achievements Showcase Card ───────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE9FE)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Coins column
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/quests');
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFD97706),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$displayCoins',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const Text(
                                'Bloom Coins',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: const Color(0xFFF1F5F9),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // Achievements column
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/account');
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.purple,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$badgeCount Badges',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const Text(
                                'Achievements',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textLight,
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
            ),
          ),

          // ── Aligned Menu List ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                _buildDrawerSectionTitle('CARE & ACTIVITIES'),
                _buildDrawerItem(
                  icon: Icons.person_outline_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  title: 'Account Details',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/account');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.auto_stories_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'My Journal',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/journal');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people_alt_outlined,
                  iconColor: const Color(0xFF06B6D4),
                  title:
                      storage.role == 'TEEN'
                          ? 'Link Parent'
                          : (storage.role == 'PARENT' ||
                                  storage.role == 'GUARDIAN'
                              ? 'Link Daughter'
                              : 'Link Family'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/account/family');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.workspace_premium_outlined,
                  iconColor: const Color(0xFFEC4899),
                  title: 'Enrolled Programs',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/learning/programs');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.menu_book_outlined,
                  iconColor: const Color(0xFF10B981),
                  title: 'Good To Know',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/good-to-know');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_bag_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'My Orders',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/orders');
                  },
                ),

                const SizedBox(height: 8),
                _buildDrawerSectionTitle('PREFERENCES'),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  iconColor: const Color(0xFF64748B),
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline_rounded,
                  iconColor: const Color(0xFF64748B),
                  title: 'Help & Support',
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Professional Clean Footer ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: const Center(
              child: Text(
                'Infano Care • v1.0.4',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFC084FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textLight,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout?'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      if (context.mounted) {
        // If mentor, clear availability on server before clearing local storage
        try {
          final api = Provider.of<CommunityApi>(context, listen: false);
          final status = await api.getMentorStatus();
          if (status['is_certified'] == true) {
            await api.updateMentorAvailability(false);
          }
        } catch (e) {
          debugPrint('Logout: Could not clear availability: $e');
        }

        // Unregister FCM token from backend so logged out users don't receive notifications
        try {
          await NotificationService().unregisterToken();
        } catch (e) {
          debugPrint('Logout: Could not unregister FCM token: $e');
        }

        await widget.storage.clearAll();
        if (context.mounted) {
          context.go('/splash');
        }
      }
    }
  }
}
