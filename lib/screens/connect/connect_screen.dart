import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/friends_socket_service.dart';
import 'match_celebration_screen.dart';
import 'circles_tab.dart';
import 'peerline_tab.dart';
import 'events_tab.dart';
import 'friends_tab.dart';
import '../../services/friends_api.dart';
import '../../core/services/api_service.dart';
import '../../models/friend_profile.dart';
import 'matches_tab.dart';
import '../../core/services/local_storage_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({Key? key}) : super(key: key);

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FriendsApi _friendsApi;
  FriendProfile? _friendProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _friendsApi = FriendsApi(ApiService.instance.dio);
    _loadProfile();
    
    // Listen for mutual matches
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      final profile = await _friendsApi.getProfile();
      if (mounted) {
        setState(() {
          _friendProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile in ConnectScreen: $e');
      if (mounted) setState(() => _isLoadingProfile = false);
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
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back arrow
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text(
          'Connect',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E), // Custom dark color
          ),
        ),
        actions: [
          _buildProfileMenu(),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 2,
          indicatorColor: Colors.pink, // pink underline indicator
          isScrollable: true,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
          ),
          labelColor: Colors.pink,
          unselectedLabelColor: Colors.grey.shade600,
          tabs: [
            const Tab(
              text: '🌐 Circles',
            ),
            const Tab(
              text: '💜 PeerLine',
            ),
            const Tab(
              text: '📅 Events',
            ),
            Tab(
              child: Text(
                '✨ Friends',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: <Color>[Colors.pink, Colors.purple],
                    ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListenableProvider<TabController>.value(
        value: _tabController,
        child: TabBarView(
          controller: _tabController,
          children: [
            const CirclesTab(),
            const PeerLineTab(),
            const EventsTab(),
            const FriendsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'chat':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchesTab()));
            break;
          case 'settings':
            // Since settings is logic inside FriendsTab, we might want to expose it or just navigate to FriendsTab + open sheet
            // For now, we'll navigate to MatchesTab (which has most info) or trigger a callback.
            // Actually, the user asked for "settings" in the menu.
            _showGlobalSettings();
            break;
          case 'saved':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchesTab()));
            // We could pass a parameter to MatchesTab to scroll to Saved, but it's already there.
            break;
        }
      },
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'chat',
          child: ListTile(
            leading: Icon(Icons.chat_bubble_outline, color: Colors.pink),
            title: Text('Open Chat'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'saved',
          child: ListTile(
            leading: Icon(Icons.bookmark_border, color: Colors.purple),
            title: Text('Saved Profiles'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings_outlined, color: Colors.grey),
            title: Text('Friends Settings'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: _friendProfile?.photoUrl != null ? NetworkImage(_friendProfile!.photoUrl!) : null,
          child: _friendProfile?.photoUrl == null 
            ? const Icon(Icons.person, size: 20, color: Colors.grey) 
            : null,
        ),
      ),
    );
  }

  void _showGlobalSettings() {
    // We'll show a bottom sheet similar to the one in FriendsTab
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        bool isPaused = !(_friendProfile?.isActive ?? true);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Friends Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('Pause Discovery'),
                    subtitle: const Text('You won\'t be seen by others, but your matches are safe.'),
                    value: isPaused,
                    activeThumbColor: Colors.pink,
                    activeTrackColor: Colors.pink.withOpacity(0.5),
                    onChanged: (val) async {
                      await _friendsApi.toggleDiscovery(!val);
                      setModalState(() => isPaused = val);
                      _loadProfile(); // Refresh global profile state
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete Friend Profile', style: TextStyle(color: Colors.red)),
                    onTap: () => _confirmDeleteProfile(),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _confirmDeleteProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile?'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _friendsApi.deleteProfile();
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close bottom sheet
                _loadProfile();
                // Optionally reset the flag in LocalStorageService
                final storage = Provider.of<LocalStorageService>(context, listen: false);
                await storage.setIsFriendOnboarded(false);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
