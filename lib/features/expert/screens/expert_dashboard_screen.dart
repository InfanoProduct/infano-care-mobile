import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/notification_service.dart';
import 'package:infano_care_mobile/features/auth/repository/auth_repository.dart';
import 'package:infano_care_mobile/features/expert/services/expert_service.dart';
import 'package:infano_care_mobile/features/expert/screens/expert_consultations_screen.dart';
import 'package:infano_care_mobile/features/expert/screens/expert_calendar_screen.dart';
import 'package:infano_care_mobile/features/learning/screens/learn_hub_screen.dart';
import 'package:infano_care_mobile/features/home/screens/track_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ── Expert Home Tab ───────────────────────────────────────────────────────────
class _ExpertHomeTab extends StatefulWidget {
  final LocalStorageService storage;
  const _ExpertHomeTab({required this.storage});

  @override
  State<_ExpertHomeTab> createState() => _ExpertHomeTabState();
}

class _ExpertHomeTabState extends State<_ExpertHomeTab> {
  late ExpertService _expertService;
  late Future<List<dynamic>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _expertService = ExpertService(widget.storage);
    _sessionsFuture = _expertService.getMySessions();
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '';
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.storage.displayName ?? 'Expert';
    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: () async => setState(() {
        _sessionsFuture = _expertService.getMySessions();
      }),
      child: CustomScrollView(
        slivers: [
          // ── Greeting header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          gradient: AppGradients.brand,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'E',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Good ${_greeting()}, 👋', style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                            Text(name, style: const TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 20),
                  // Expert stat cards
                  FutureBuilder<List<dynamic>>(
                    future: _sessionsFuture,
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Row(
                        children: [
                          _StatCard(label: 'Active\nConsultations', value: count.toString(), icon: Icons.chat_bubble_outline_rounded, color: AppColors.purple),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Available\nStatus', value: 'Online', icon: Icons.circle, color: AppColors.success),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Today\'s\nSessions', value: '0', icon: Icons.calendar_today_outlined, color: const Color(0xFFEC4899)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Expert Management Quick Action Cards
                  Column(
                    children: [
                      // Program Sessions Banner Card
                      InkWell(
                        onTap: () => context.push('/expert/program-sessions'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                                child: Icon(Icons.layers_rounded, color: Colors.white, size: 20),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Program Sessions Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                    SizedBox(height: 2),
                                    Text('Curriculum timelines & session meet links', style: TextStyle(fontSize: 11, color: Colors.white70)),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => context.push('/expert/consultations'),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.purple.withValues(alpha: 0.12), AppColors.purple.withValues(alpha: 0.05)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.video_call_rounded, color: AppColors.purple, size: 22),
                                        Spacer(),
                                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.purple),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text('1:1 Consultations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                                    SizedBox(height: 2),
                                    Text('Manage links & schedule', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => context.push('/expert/calendar'),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [const Color(0xFFEC4899).withValues(alpha: 0.12), const Color(0xFFEC4899).withValues(alpha: 0.05)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.2)),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_month_rounded, color: Color(0xFFEC4899), size: 22),
                                        Spacer(),
                                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFEC4899)),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text('My Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                                    SizedBox(height: 2),
                                    Text('Set slots & block dates', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Active Consultations', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  const Text('Users who have reached out to you', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Sessions list ──────────────────────────────────────────────────
          FutureBuilder<List<dynamic>>(
            future: _sessionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: AppColors.purple),
                    ),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyConsultations(onRefresh: () => setState(() {
                    _sessionsFuture = _expertService.getMySessions();
                  })),
                );
              }

              final sessions = snapshot.data!;
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final session = sessions[index];
                      final user = session['user'] ?? {};
                      final profile = user['profile'] ?? {};
                      final userName = (profile['displayName'] != null && (profile['displayName'] as String).isNotEmpty)
                          ? profile['displayName'] as String
                          : 'Anonymous User';
                      final messages = session['messages'] as List?;
                      final scheduledAt = session['scheduledAt'] as String?;
                      final lastMsg = (messages != null && messages.isNotEmpty)
                          ? messages[0]['content'] as String? ?? 'Consultation started'
                          : (scheduledAt != null ? '1:1 Scheduled Appointment' : 'Consultation started');
                      final lastTime = (messages != null && messages.isNotEmpty)
                          ? _formatTime(messages[0]['createdAt'] as String?)
                          : _formatTime(scheduledAt);
                      return _SessionCard(
                        userName: userName,
                        lastMessage: lastMsg,
                        lastTime: lastTime,
                        unreadCount: session['unreadCount'] as int? ?? 0,
                        onTap: () => context.push('/expert/consultations'),
                      );
                    },
                    childCount: sessions.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

// ── Expert Dashboard Shell ────────────────────────────────────────────────────
class ExpertDashboardScreen extends StatefulWidget {
  final LocalStorageService storage;
  const ExpertDashboardScreen({super.key, required this.storage});

  @override
  State<ExpertDashboardScreen> createState() => _ExpertDashboardScreenState();
}

class _ExpertDashboardScreenState extends State<ExpertDashboardScreen> {
  int _selectedIndex = 0;
  bool _isExpanded = true;
  Timer? _collapseTimer;

  @override
  void initState() {
    super.initState();
    _startCollapseTimer();
    // Background profile sync
    AuthRepository(widget.storage).syncProfile().catchError((_) {});
  }

  void _startCollapseTimer() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _isExpanded = false);
    });
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<LocalStorageService>();

    final screens = [
      _ExpertHomeTab(storage: storage),
      LearnHubScreen(storage: storage),
      ExpertConsultationsScreen(storage: storage, isEmbedded: true), // CENTER TAB!
      const TrackScreen(),
      ExpertCalendarScreen(storage: storage),
    ];

    final tabLabels = ['Home', 'Learn', 'Consultations', 'Track', 'Availability'];
    final tabIcons = [
      Icons.home_outlined,
      Icons.auto_stories_outlined,
      Icons.video_call_outlined,
      Icons.calendar_today_outlined,
      Icons.schedule_outlined,
    ];
    final tabActiveIcons = [
      Icons.home,
      Icons.auto_stories,
      Icons.video_call,
      Icons.calendar_today,
      Icons.schedule,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Infano.Care',
            style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(context, storage),
      body: SafeArea(child: screens[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) {
            setState(() {
              _selectedIndex = i;
              _isExpanded = true;
            });
            _startCollapseTimer();
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.purple,
          unselectedItemColor: AppColors.textLight,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: List.generate(tabLabels.length, (i) {
            return BottomNavigationBarItem(
              icon: Icon(tabIcons[i]),
              activeIcon: Icon(tabActiveIcons[i]),
              label: tabLabels[i],
            );
          }),
        ),
      ),
      // Gigi floating button — on Home and Learn tabs (hide on Consultations, Track, Availability)
      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 1)
          ? Stack(
              alignment: Alignment.bottomRight,
              clipBehavior: Clip.none,
              children: [
                if (!_isExpanded)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 56, height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFE9D5FF), Color(0xFFFBCFE8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 2.seconds, curve: Curves.easeOut)
                    .fadeOut(duration: 2.seconds),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn,
                  clipBehavior: Clip.antiAlias,
                  height: 56,
                  width: _isExpanded ? 160 : 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE9D5FF), Color(0xFFFBCFE8)],
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
                    border: Border.all(color: const Color(0xFFD8B4FE).withValues(alpha: 0.3), width: 1),
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
                            Positioned(
                              left: 6,
                              child: Container(
                                width: 44, height: 44,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                                child: ClipOval(child: Image.asset('assets/images/gigi_avatar.png', fit: BoxFit.cover)),
                              ),
                            ),
                            if (_isExpanded)
                              const Positioned(
                                left: 58,
                                child: Text('Talk to Gigi',
                                  style: TextStyle(color: Color(0xFF4C1D95), fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .slideY(begin: 0.0, end: -0.12, duration: 1500.ms, curve: Curves.easeInOut)
          : null,
    );
  }

  Widget _buildDrawer(BuildContext context, LocalStorageService storage) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(gradient: AppGradients.brandDiagonal),
            accountName: Text(storage.displayName ?? 'Expert',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(storage.phone ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              backgroundImage: storage.avatarUrl != null ? NetworkImage(storage.avatarUrl!) : null,
              child: storage.avatarUrl == null ? const Text('👤', style: TextStyle(fontSize: 32)) : null,
            ),
          ),
          // Expert badge
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 16, color: AppColors.purple),
                const SizedBox(width: 6),
                const Text('Verified Expert', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: const Icon(Icons.layers_outlined, color: AppColors.purple),
            title: const Text('Program Sessions Workspace'),
            onTap: () { Navigator.pop(context); context.push('/expert/program-sessions'); },
          ),
          ListTile(
            leading: const Icon(Icons.video_call_outlined, color: AppColors.purple),
            title: const Text('1:1 Direct Consultations'),
            onTap: () { Navigator.pop(context); context.push('/expert/consultations'); },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined, color: AppColors.purple),
            title: const Text('Calendar & Availability'),
            onTap: () { Navigator.pop(context); context.push('/expert/calendar'); },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.purple),
            title: const Text('My Profile'),
            onTap: () { Navigator.pop(context); context.push('/account'); },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline, color: AppColors.purple),
            title: const Text('My Chats'),
            onTap: () { Navigator.pop(context); context.push('/my-chats'); },
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined, color: AppColors.purple),
            title: const Text('AI Assistant (Gigi)'),
            onTap: () { Navigator.pop(context); context.push('/chat'); },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: AppColors.purple),
            title: const Text('Settings'),
            onTap: () { Navigator.pop(context); context.push('/settings'); },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.purple),
            title: const Text('Help & Support'),
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: () => _handleLogout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try { await NotificationService().unregisterToken(); } catch (_) {}
      await widget.storage.clearAll();
      if (context.mounted) context.go('/splash');
    }
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textLight, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String userName;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final VoidCallback onTap;
  const _SessionCard({required this.userName, required this.lastMessage, required this.lastTime, required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        onTap: onTap,
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.purple.withValues(alpha: 0.12), AppColors.purple.withValues(alpha: 0.06)]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(userName[0].toUpperCase(),
              style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark), overflow: TextOverflow.ellipsis)),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(10)),
                child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('ACTIVE', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Expanded(child: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMedium, fontSize: 13))),
              if (lastTime.isNotEmpty)
                Text(lastTime, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyConsultations extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyConsultations({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.purple.withValues(alpha: 0.08), AppColors.purple.withValues(alpha: 0.03)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 44, color: AppColors.purple),
            ),
            const SizedBox(height: 16),
            const Text('Patiently Waiting 🌸',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text(
              'No active consultations yet.\nWhen a user reaches out, they\'ll appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.5),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.purple,
                side: const BorderSide(color: AppColors.purple),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0, duration: 600.ms),
      ),
    );
  }
}
