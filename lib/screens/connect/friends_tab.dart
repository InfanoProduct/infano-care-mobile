import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../widgets/friends_tab_entry_card.dart';
import '../../widgets/friend_swipe_cards.dart';
import '../../services/friends_api.dart';
import '../../models/friend_profile.dart';
import 'friend_profile_setup_screen.dart';
import '../../core/services/api_service.dart';
import '../../widgets/friend_match_dialog.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:provider/provider.dart';
import 'matches_tab.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({Key? key}) : super(key: key);

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  bool _isOptedIn = false;
  bool _isLoading = false;
  List<FriendProfile> _nearbyProfiles = [];
  late FriendsApi _friendsApi;

  @override
  void initState() {
    super.initState();
    _friendsApi = FriendsApi(ApiService.instance.dio);
    
    // Optimistic initial state based on local storage
    final storage = Provider.of<LocalStorageService>(context, listen: false);
    _isOptedIn = storage.isFriendOnboarded;
    
    _checkOptInStatus();
  }

  Future<void> _checkOptInStatus() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _friendsApi.getProfile();
      if (profile != null && profile.isActive == true && (profile.status == 'ACTIVE' || profile.status == 'PENDING_REVIEW')) {
        setState(() {
          _isOptedIn = true;
        });
        await _fetchNearbyProfiles();
      } else {
        setState(() {
          _isOptedIn = false;
        });
      }
    } catch (e) {
      print('Failed to check opt-in status: $e');
      setState(() => _isOptedIn = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStartMatching() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FriendProfileSetupScreen()),
    );

    if (result == true) {
      setState(() {
        _isOptedIn = true;
      });
      _fetchNearbyProfiles();
    }
  }

  Future<void> _handleWidenRadius() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FriendProfileSetupScreen(initialStep: 3, isWidenRadius: true),
      ),
    );

    if (result == true) {
      // Refresh profiles with new radius
      _fetchNearbyProfiles();
    }
  }

  Future<void> _fetchNearbyProfiles() async {
    try {
      final profile = await _friendsApi.getProfile();
      final radius = profile?.discoveryRadius?.toLowerCase().split(' ').last ?? 'city';
      // Map 'neighbourhood', 'city', '50km', 'country' to the backend expected values if needed
      // Current backend radiusToPrefix handles 'city', 'country', 'nearby', etc.
      
      final profiles = await _friendsApi.discoverProfiles(
        batchSize: 20, 
        radius: radius == 'neighbourhood' ? 'nearby' : (radius == 'country' ? 'country' : 'city'),
      );
      setState(() {
        _nearbyProfiles = profiles;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load nearby friends')),
      );
    }
  }

  Future<void> _handleSwipe(String targetId, String action) async {
    try {
      final result = await _friendsApi.swipeFriend(targetId, action);

      // Find the nickname of the matched user for the dialog before removing
      final matchedProfile = _nearbyProfiles.firstWhere((p) => p.id == targetId);
      final nickname = matchedProfile.nickname ?? "a new friend";

      // Remove from local list so we don't reshow it if we refresh
      setState(() {
        _nearbyProfiles.removeWhere((p) => p.id == targetId);
      });

      if (result['result'] == 'match' && result['matchId'] != null) {
        FriendMatchDialog.show(context, nickname, result['matchId']);
      }
    } catch (e) {
      // Background failure, log it
      print('Swipe failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<LocalStorageService>(context);
    final birthYear = storage.birthYear;
    final currentYear = DateTime.now().year;
    final age = birthYear != null ? currentYear - birthYear : 0;

    if (birthYear != null && age < 15) {
      return _buildSafetyRestrictedView();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.pink));
    }

    if (!_isOptedIn) {
      return SingleChildScrollView(
        child: Column(
          children: [
            FriendsTabEntryCard(
              onStartMatching: _handleStartMatching,
              nearbyCount: 25, // Mock number or fetched from an info API
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        FriendSwipeCards(
          profiles: _nearbyProfiles,
          onSwipe: _handleSwipe,
          onWidenRadius: _handleWidenRadius,
          onEmpty: () {
            // Automatically re-fetch or just let the empty state show
            setState(() {});
          },
        ),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            heroTag: 'matches_btn',
            backgroundColor: Colors.white,
            foregroundColor: Colors.pinkAccent,
            elevation: 2,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchesTab()));
            },
            child: const Icon(Icons.favorite),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyRestrictedView() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, size: 80, color: Colors.amber),
          ),
          const SizedBox(height: 32),
          const Text(
            'Safety First',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Connect+ Friends is a community discovery feature designed for users 15 and older to ensure the highest safety standards for our younger members.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          const Text(
            'What you can do instead:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildAlternativeOption(
            icon: Icons.groups,
            title: 'Explore Circles',
            subtitle: 'Join interest-based communities moderated by our team.',
            onTap: () {
              final tabController = Provider.of<TabController>(context, listen: false);
              tabController.animateTo(0);
            },
          ),
          const SizedBox(height: 16),
          _buildAlternativeOption(
            icon: Icons.support_agent,
            title: 'PeerLine Support',
            subtitle: 'Chat with trained mentors who are here to help.',
            onTap: () {
              final tabController = Provider.of<TabController>(context, listen: false);
              tabController.animateTo(1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.pink, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
