import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/home/bloc/dashboard_cubit.dart';
import 'package:infano_care_mobile/features/home/screens/home_screen.dart';
import 'package:infano_care_mobile/features/home/screens/learn_screen.dart';
import 'package:infano_care_mobile/features/home/screens/track_screen.dart';
import 'package:infano_care_mobile/features/home/screens/quest_screen.dart';
import 'package:infano_care_mobile/features/home/screens/connect_screen.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.storage});

  final LocalStorageService storage;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardCubit(),
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final screens = [
            const HomeScreen(),
            const LearnScreen(),
            const TrackScreen(),
            const QuestScreen(),
            const ConnectScreen(),
          ];

          return Scaffold(
            appBar: AppBar(
              title: Text('Infano.Care', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 22)),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.purple),
            ),
            drawer: _buildDrawer(context),
            body: IndexedStack(
              index: state.selectedIndex,
              children: screens,
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: state.selectedIndex,
                onTap: (index) => context.read<DashboardCubit>().setTab(index),
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
          );
        },
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppGradients.brandDiagonal,
            ),
            accountName: Text(storage.displayName ?? 'Infano User', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(storage.phone ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.3),
              child: const Text('👤', style: TextStyle(fontSize: 32)),
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
            leading: const Icon(Icons.settings_outlined, color: AppColors.purple),
            title: const Text('Profile Settings'),
            onTap: () => Navigator.pop(context),
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
      await storage.clearAll();
      if (context.mounted) {
        context.go('/splash');
      }
    }
  }
}
