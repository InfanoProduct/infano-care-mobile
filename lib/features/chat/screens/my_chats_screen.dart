import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/services/community_socket_service.dart';

class MyChatsScreen extends StatefulWidget {
  const MyChatsScreen({super.key});

  @override
  State<MyChatsScreen> createState() => _MyChatsScreenState();
}

class _MyChatsScreenState extends State<MyChatsScreen> {
  bool _isLoading = true;
  List<dynamic> _chats = [];
  String? _error;
  StreamSubscription? _socketSub;

  // Search & Filter State
  String _searchQuery = "";
  String _selectedTab = "All"; // "All", "Mentors", "Experts"

  @override
  void initState() {
    super.initState();
    _fetchChats();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socket = Provider.of<CommunitySocketService>(context, listen: false);
      _socketSub = socket.chatEvents.listen((event) {
        if (mounted) {
          final type = event['type'];
          if (type == 'session_ready' || type == 'message' || type == 'session_ended') {
            // Fetch silently in background on socket event to prevent flicker
            _fetchChats(isSilent: true);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchChats({bool isSilent = false}) async {
    if (!isSilent && _chats.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final response = await ApiService.instance.dio.get('chat/my-chats');
      if (response.data['success'] == true && mounted) {
        setState(() {
          _chats = response.data['data'] as List<dynamic>;
          _isLoading = false;
          _error = null;
        });
      } else if (mounted) {
        setState(() {
          _error = 'Failed to load chats';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> _getFilteredChats() {
    return _chats.where((chat) {
      final String name = (chat['name'] ?? '').toString().toLowerCase();
      final String type = chat['type'] ?? 'peer';
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      
      if (_selectedTab == "Mentors") {
        return matchesSearch && type == 'peer';
      } else if (_selectedTab == "Experts") {
        return matchesSearch && type == 'expert';
      }
      return matchesSearch;
    }).toList();
  }

  int _getTotalUnreadCount() {
    return _chats.fold<int>(0, (sum, chat) => sum + ((chat['unreadCount'] ?? 0) as int));
  }

  int _getActiveChatsCount() {
    return _chats.where((chat) => chat['isActive'] == true || chat['status'] == 'ACTIVE').length;
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = _getFilteredChats();
    final totalUnread = _getTotalUnreadCount();
    final activeCount = _getActiveChatsCount();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'My Inbox', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppColors.textDark)
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textDark),
            onPressed: () => context.push('/my-chats/search'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textDark),
            onPressed: () => _fetchChats(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stat Cards (Summary Row)
          if (!_isLoading && _error == null && _chats.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Active Chats',
                      value: '$activeCount',
                      icon: Icons.chat_bubble_rounded,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Unread Messages',
                      value: '$totalUnread',
                      icon: Icons.mark_chat_unread_rounded,
                      color: AppColors.pink,
                    ),
                  ),
                ],
              ),
            ),
          
          // Search & Filter Row
          if (!_isLoading && _error == null && _chats.isNotEmpty) ...[
            GestureDetector(
              onTap: () => context.push('/my-chats/search'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  readOnly: true,
                  onTap: () => context.push('/my-chats/search'),
                  decoration: InputDecoration(
                    hintText: 'Search conversations, mentors...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.purple.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ),
            ),
            
            // Tab Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTabChip("All"),
                  const SizedBox(width: 8),
                  _buildTabChip("Mentors"),
                  const SizedBox(width: 8),
                  _buildTabChip("Experts"),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          Expanded(
            child: _buildBody(filteredChats),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label) {
    final bool isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.purple : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<dynamic> filteredChats) {
    if (_isLoading && _chats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchChats(),
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No active chats found.',
              style: GoogleFonts.outfit(color: AppColors.textMedium, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (filteredChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No matches found.',
              style: GoogleFonts.outfit(color: AppColors.textMedium, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchChats(isSilent: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredChats.length,
        itemBuilder: (context, index) {
          final chat = filteredChats[index];
          final String name = chat['name'] ?? 'Unknown';
          final String type = chat['type'] ?? 'peer';
          final String lastMessage = chat['lastMessage'] ?? '';
          final int unreadCount = chat['unreadCount'] ?? 0;
          final String? avatarUrl = chat['avatarUrl'];
          final bool isActive = chat['isActive'] == true || chat['status'] == 'ACTIVE' || chat['status'] == 'MATCHING';
          final bool isOnline = chat['isOnline'] == true || type == 'gigi';
          final String statusStr = (chat['status'] ?? '').toString().toUpperCase();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: unreadCount > 0 ? AppColors.purple.withValues(alpha: 0.25) : Colors.grey.shade100,
                width: unreadCount > 0 ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Stack(
                children: [
                   CircleAvatar(
                    radius: 26,
                    backgroundColor: type == 'expert'
                        ? AppColors.purple.withValues(alpha: 0.1)
                        : type == 'gigi'
                            ? AppColors.purple.withValues(alpha: 0.15)
                            : AppColors.pink.withValues(alpha: 0.1),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Icon(
                            type == 'expert'
                                ? Icons.medical_services
                                : type == 'gigi'
                                    ? Icons.smart_toy_rounded
                                    : Icons.person,
                            color: type == 'expert' || type == 'gigi' ? AppColors.purple : AppColors.pink,
                          )
                        : null,
                  ),
                  if (isOnline)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  if (type == 'expert')
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified, color: AppColors.success, size: 14),
                      ),
                    ),
                ],
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (statusStr == 'MATCHING')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'CONNECTING',
                        style: GoogleFonts.outfit(
                          color: Colors.orange.shade800,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: unreadCount > 0 ? AppColors.textDark : AppColors.textMedium,
                    fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isActive ? AppColors.purple : Colors.grey.shade400,
                    ),
                ],
              ),
              onTap: () {
                if (type == 'expert') {
                  context.push('/expert/chat/${chat['id']}', extra: {'expertName': name});
                } else if (type == 'peer') {
                  context.push('/peerline/chat/${chat['id']}').then((_) => _fetchChats(isSilent: true));
                } else if (type == 'gigi') {
                  context.push('/gigi/chat/${chat['id']}');
                }
              },
            ),
          );
        },
      ),
    );
  }
}
