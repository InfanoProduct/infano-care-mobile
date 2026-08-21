import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'package:infano_care_mobile/core/services/notification_service.dart';
import 'package:infano_care_mobile/widgets/notification_center_sheet.dart';
import 'package:infano_care_mobile/widgets/coin_badge.dart';
import 'package:infano_care_mobile/features/home/screens/quest_screen.dart';
import 'package:infano_care_mobile/screens/connect/connect_screen.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/quest_repository.dart';
import 'package:infano_care_mobile/features/tracker/bloc/quest_bloc.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/features/learning/screens/learn_hub_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/services/community_socket_service.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.storage, this.initialTab = 0, this.initialSubTab = 1});

  final LocalStorageService storage;
  final int initialTab;
  final int initialSubTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}



class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  bool _isExpanded = true;
  StreamSubscription? _peerlineSocketSub;
  StreamSubscription? _fcmMessageSub;
  Timer? _collapseTimer;
  bool _hasUnreadNotifications = false;

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

    // Register lifecycle observer — refetch badge when app comes to foreground
    WidgetsBinding.instance.addObserver(this);

    // Initial fetch once on load
    _checkUnreadNotifications();

    // Listen to foreground FCM messages — update badge instantly when a push arrives
    _fcmMessageSub = FirebaseMessaging.onMessage.listen((_) {
      if (mounted) _checkUnreadNotifications();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socket = Provider.of<CommunitySocketService>(context, listen: false);

      // Listen to socket 'notification:new' event — badge updates with zero latency
      socket.notificationNewCount.addListener(_checkUnreadNotifications);

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
    if (state == AppLifecycleState.resumed) {
      _checkUnreadNotifications();
    }
  }

  void _showSessionReadyDialog(String sessionId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_rounded, color: AppColors.purple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mentor Connected!',
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'A peer mentor has accepted your chat request and is waiting for you in chat.',
          style: GoogleFonts.nunito(color: Colors.grey.shade700, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Dismiss', style: GoogleFonts.nunito(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/peerline/chat/$sessionId');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text('Join Chat Now', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
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

  Future<void> _checkUnreadNotifications() async {
    final authToken = widget.storage.authToken;
    if (authToken == null) return;

    try {
      final res = await ApiService.instance.dio.get('/parent/notifications');
      final list = res.data as List<dynamic>;
      if (mounted) {
        setState(() {
          _hasUnreadNotifications = list.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('[DashboardScreen] Error checking notifications: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Remove socket badge listener
    final socket = context.read<CommunitySocketService>();
    socket.notificationNewCount.removeListener(_checkUnreadNotifications);
    _peerlineSocketSub?.cancel();
    _fcmMessageSub?.cancel();
    _collapseTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncProfile() async {
    debugPrint('[DashboardScreen] Starting background profile sync. Current local displayName: "${widget.storage.displayName}"');
    try {
      final repo = AuthRepository(widget.storage);
      await repo.syncProfile();
      debugPrint('[DashboardScreen] Background profile sync completed successfully ✅ Stored displayName after sync: "${widget.storage.displayName}"');
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
          create: (context) => QuestBloc(QuestRepository(ApiService.instance.dio))..add(const QuestEvent.load()),
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
              const QuestScreen(),
              ConnectScreen(initialTab: widget.initialSubTab),
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
            appBar: (state.selectedIndex != 0) 
              ? null // Hide main AppBar for Learning Journey, Track, Quest, and Connect modules
              : AppBar(
                  title: const Text('Infano.Care', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 22)),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: AppColors.purple),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: CoinBadge(
                        coins: storage.totalCoins,
                        onTap: () => context.push('/account'),
                      ),
                    ),
                    Consumer<CommunitySocketService>(
                      builder: (context, socketService, _) {
                        return ValueListenableBuilder<int>(
                          valueListenable: socketService.totalUnreadChatsCount,
                          builder: (context, count, _) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  tooltip: 'My Chats',
                                  onPressed: () => context.push('/my-chats'),
                                ),
                                if (count > 0)
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_outlined),
                          onPressed: () async {
                            await NotificationCenterSheet.show(context);
                            _checkUnreadNotifications();
                          },
                        ),
                        if (_hasUnreadNotifications)
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
            drawer: (state.selectedIndex != 0) ? null : _buildDrawer(context, storage),
            body: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollUpdateNotification) {
                  if (scrollNotification.scrollDelta != null && scrollNotification.scrollDelta! > 2.0) {
                    if (_isExpanded) {
                      setState(() {
                        _isExpanded = false;
                      });
                    }
                  } else if (scrollNotification.scrollDelta != null && scrollNotification.scrollDelta! < -2.0) {
                    if (!_isExpanded) {
                      setState(() {
                        _isExpanded = true;
                      });
                    }
                  }
                }
                return false;
              },
              child: SafeArea(
                child: screens[state.selectedIndex],
              ),
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
                    activeIcon: _buildTrackIcon(state.isPeriodImminent, true),
                    label: 'Track',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildBadgeIcon(
                      icon: Icons.military_tech_outlined,
                      badgeCount: state.questBadgeCount,
                    ),
                    activeIcon: _buildBadgeIcon(
                      icon: Icons.military_tech,
                      badgeCount: state.questBadgeCount,
                    ),
                    label: 'Quest',
                  ),
                  BottomNavigationBarItem(
                    icon: _buildBadgeIcon(
                      icon: Icons.people_outline,
                      showRedDot: state.hasConnectNotification,
                    ),
                    activeIcon: _buildBadgeIcon(
                      icon: Icons.people,
                      showRedDot: state.hasConnectNotification,
                    ),
                    label: 'Connect',
                  ),
                ],
              ),
            ),
            floatingActionButton: (state.selectedIndex == 2 || state.selectedIndex == 3 || state.selectedIndex == 4) 
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
                              colors: [Color(0xFFE9D5FF), Color(0xFFFBCFE8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 2.seconds, curve: Curves.easeOut)
                        .fadeOut(duration: 2.seconds),
                      ),
                    
                    // Main Gigi floating button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.fastOutSlowIn,
                      clipBehavior: Clip.antiAlias, // Clip the sliding text!
                      height: 56,
                      width: _isExpanded ? 160 : 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE9D5FF), Color(0xFFFBCFE8)], // from-purple-200 to-pink-200
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD8B4FE).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFD8B4FE).withValues(alpha: 0.3),
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
                                  left: 6, // 6px padding on left matches center position when collapsed: (56-44)/2 = 6
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
                                      child: _isExpanded
                                          ? Image.asset(
                                              'assets/images/gigi_avatar.png',
                                              fit: BoxFit.cover,
                                            )
                                          : Image.asset(
                                              'assets/images/gigi_avatar.png',
                                              fit: BoxFit.cover,
                                            )
                                            .animate(onPlay: (controller) => controller.repeat())
                                            .shake(delay: 3.seconds, duration: 800.ms, hz: 4),
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
                                        color: Color(0xFF4C1D95), // text-purple-950
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
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .slideY(begin: 0.0, end: -0.12, duration: 1500.ms, curve: Curves.easeInOut),
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
    final icon = Icon(isActive ? Icons.calendar_today : Icons.calendar_today_outlined);
    if (!isImminent) return icon;

    return icon
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(begin: 1.0, end: 1.15, duration: 1000.ms, curve: Curves.easeInOut)
        .then()
        .scaleXY(begin: 1.15, end: 1.0, duration: 1000.ms);
  }

  Widget _buildDrawer(BuildContext context, LocalStorageService storage) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.purple,
            ),
            accountName: Text(storage.displayName ?? 'Infano User', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(storage.phone ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              backgroundImage: storage.avatarUrl != null ? NetworkImage(storage.avatarUrl!) : null,
              child: storage.avatarUrl == null
                  ? const Text('👤', style: TextStyle(fontSize: 32))
                  : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.purple),
            title: const Text('Account Details'),
            onTap: () {
              Navigator.pop(context);
              context.push('/account');
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_stories_outlined, color: AppColors.purple),
            title: const Text('My Journal ✨'),
            subtitle: const Text('Private • always safe', style: TextStyle(fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              context.push('/journal');
            },
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined, color: AppColors.purple),
            title: const Text('AI Assistant (Gigi)'),
            onTap: () {
              Navigator.pop(context);
              context.push('/chat');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined, color: AppColors.purple),
            title: Text(storage.role == 'TEEN' ? 'Link Parent' : (storage.role == 'PARENT' || storage.role == 'GUARDIAN' ? 'Link Daughter' : 'Link Family')),
            onTap: () {
              Navigator.pop(context);
              context.push('/account/family');
            },
          ),

          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined, color: AppColors.purple),
            title: const Text('Enrolled Programs'),
            onTap: () {
              Navigator.pop(context);
              context.push('/learning/programs');
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined, color: AppColors.purple),
            title: const Text('Good To Know'),
            onTap: () {
              Navigator.pop(context);
              context.push('/good-to-know');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.purple),
            title: const Text('My Orders'),
            onTap: () {
              Navigator.pop(context);
              context.push('/orders');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: AppColors.purple),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.purple),
            title: const Text('Help & Support'),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
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

