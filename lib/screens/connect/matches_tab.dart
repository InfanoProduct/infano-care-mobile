import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/services/friends_api.dart';
import 'package:infano_care_mobile/models/friend_profile.dart';

class MatchesTab extends StatefulWidget {
  const MatchesTab({super.key});

  @override
  State<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<MatchesTab> {
  late FriendsApi _friendsApi;
  List<Map<String, dynamic>> _newMatches = [];
  List<Map<String, dynamic>> _activeChats = [];
  List<FriendProfile> _savedProfiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _friendsApi = FriendsApi(ApiService.instance.dio);
    _loadData();
  }

    Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final matches = await _friendsApi.getMatches();
      final saved = await _friendsApi.getSavedProfiles();
      
      debugPrint('Loaded ${matches.length} matches and ${saved.length} saved profiles');

      setState(() {
        _newMatches = matches.where((m) => m['last_message'] == null).toList();
        _activeChats = matches.where((m) => m['last_message'] != null).toList();
        _savedProfiles = saved;
        _isLoading = false;
      });
      
      debugPrint('Categorized into ${_newMatches.length} new matches and ${_activeChats.length} active chats');
    } catch (e) {
      debugPrint('Error loading matches tab data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unmatch(String matchId) async {
    try {
      await _friendsApi.unmatch(matchId);
      _loadData(); // Reload after unmatching
    } catch (e) {
      debugPrint('Error unmatching: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: Colors.pinkAccent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            if (_newMatches.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('New Matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _newMatches.length,
                  itemBuilder: (context, index) {
                    final match = _newMatches[index];
                    return _buildNewMatchItem(match);
                  },
                ),
              ),
              const Divider(height: 32),
            ],

            if (_activeChats.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text('Active Chats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activeChats.length,
                itemBuilder: (context, index) {
                  final match = _activeChats[index];
                  return _buildChatPreviewItem(match);
                },
              ),
            ],

            if (_savedProfiles.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Text('Saved Profiles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _savedProfiles.length,
                itemBuilder: (context, index) {
                  final profile = _savedProfiles[index];
                  return _buildSavedProfileItem(profile);
                },
              ),
            ],

            if (_newMatches.isEmpty && _activeChats.isEmpty && _savedProfiles.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    "No matches yet.\nKeep discovering to find new friends!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    ));
  }

  Widget _buildNewMatchItem(Map<String, dynamic> match) {
    final profile = match['profile'] ?? {};
    return GestureDetector(
      onTap: () => context.push('/friends/chat/${match['id']}'),
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: profile['photoUrl'] != null ? NetworkImage(profile['photoUrl']) : null,
                  child: profile['photoUrl'] == null ? const Icon(Icons.person, size: 36, color: Colors.grey) : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              profile['nickname'] ?? 'Someone',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPreviewItem(Map<String, dynamic> match) {
    final profile = match['profile'] ?? {};
    final unreadCount = match['unread_count'] ?? 0;
    final lastMessage = match['last_message'] ?? 'Start chatting...';

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: profile['photoUrl'] != null ? NetworkImage(profile['photoUrl']) : null,
        child: profile['photoUrl'] == null ? const Icon(Icons.person) : null,
      ),
      title: Text(profile['nickname'] ?? 'Someone', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: unreadCount > 0 ? Colors.black87 : Colors.grey, fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unreadCount > 0)
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.pinkAccent,
              child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatOptions(context, match['id']),
          ),
        ],
      ),
      onTap: () {
        final chatId = match['chat_id'] ?? match['id'];
        context.push('/friends/chat/$chatId');
      },
    );
  }

  void _showChatOptions(BuildContext context, String matchId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.heart_broken, color: Colors.red),
              title: const Text('Unmatch', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmUnmatch(context, matchId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUnmatch(BuildContext context, String matchId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unmatch?'),
        content: const Text('This will remove the chat history and the match.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _unmatch(matchId);
            },
            child: const Text('Unmatch', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedProfileItem(FriendProfile profile) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
        child: profile.photoUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(profile.nickname ?? 'Someone', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text('Saved profile'),
      trailing: const Icon(Icons.bookmark, color: Colors.pinkAccent),
      onTap: () {
        // Show profile dialog
      },
    );
  }
}
