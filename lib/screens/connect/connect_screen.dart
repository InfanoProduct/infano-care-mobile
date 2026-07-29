import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/friends_socket_service.dart';
import 'match_celebration_screen.dart';
import 'circles_tab.dart';
import 'peerline_tab.dart';
import 'events_tab.dart';
import 'friends_tab.dart';
import '../../services/friends_api.dart';
import '../../core/services/api_service.dart';
import 'my_feed_tab.dart';
import '../../services/community_api.dart';
import '../../core/theme/app_theme.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key, this.initialTab = 2});
  final int initialTab;

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}


class _ConnectScreenState extends State<ConnectScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FriendsApi _friendsApi;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _friendsApi = FriendsApi(ApiService.instance.dio);
    _loadProfile();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCircles();
      
      // Listen for mutual matches
      final friendsSocket = Provider.of<FriendsSocketService>(context, listen: false);
      friendsSocket.matchEvents.listen((matchData) {
        if (mounted) {
          showGeneralDialog(
            context: context,
            pageBuilder: (context, animation, secondaryAnimation) => MatchCelebrationScreen(matchData: matchData),
            barrierDismissible: true,
            barrierLabel: "Match Celebration",
            transitionDuration: const Duration(milliseconds: 300),
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        }
      });
    });
  }

  Future<void> _loadProfile() async {
    try {
      await _friendsApi.getProfile();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading profile in ConnectScreen: $e');
    }
  }

  Future<void> _checkCircles() async {
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      final circles = await api.getCircles();
      
      final hasJoined = circles.any((c) => c.isJoined);
      
      if (circles.isNotEmpty && !hasJoined && mounted) {
        // Automatically navigate to Circles tab (index 3) if none joined
        _tabController.animateTo(3);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join some circles to start seeing your feed!'),
            backgroundColor: Colors.pink,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking circles: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting to community: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Usually we would cancel the subscription here, but the broadcast stream is fine.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          padding: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildTabItem(0, 'Friends', Icons.people_alt_rounded),
                    const SizedBox(width: 12),
                    _buildTabItem(1, 'PeerLine', Icons.favorite_rounded),
                    const SizedBox(width: 12),
                    _buildTabItem(2, 'My Feed', Icons.newspaper_rounded),
                    const SizedBox(width: 12),
                    _buildTabItem(3, 'Circles', Icons.groups_rounded),
                    const SizedBox(width: 12),
                    _buildTabItem(4, 'Events', Icons.event_available_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      body: ListenableProvider<TabController>.value(
        value: _tabController,
        child: TabBarView(
          controller: _tabController,
          children: const [
            FriendsTab(),
            PeerLineTab(),
            MyFeedTab(),
            CirclesTab(),
            EventsTab(),
          ],
        ),
      ),
    );
  }


  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? AppColors.purple : Colors.grey.shade50,
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textMedium,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textMedium,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
