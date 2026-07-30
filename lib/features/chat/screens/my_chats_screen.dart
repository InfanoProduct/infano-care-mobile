import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';

class MyChatsScreen extends StatefulWidget {
  const MyChatsScreen({super.key});

  @override
  State<MyChatsScreen> createState() => _MyChatsScreenState();
}

class _MyChatsScreenState extends State<MyChatsScreen> {
  bool _isLoading = true;
  List<dynamic> _chats = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService.instance.dio.get('chat/my-chats');
      if (response.data['success'] == true) {
        setState(() {
          _chats = response.data['data'] as List<dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load chats';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDark),
            onPressed: _fetchChats,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
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
              onPressed: _fetchChats,
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    if (_chats.isEmpty) {
      return const Center(
        child: Text(
          'No active chats found.',
          style: TextStyle(color: AppColors.textMedium, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchChats,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          final String name = chat['name'] ?? 'Unknown';
          final String type = chat['type'] ?? 'peer';
          final String lastMessage = chat['lastMessage'] ?? '';
          final int unreadCount = chat['unreadCount'] ?? 0;
          final String? avatarUrl = chat['avatarUrl'];

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: type == 'expert' ? AppColors.purple.withValues(alpha: 0.1) : AppColors.pink.withValues(alpha: 0.1),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Icon(
                            type == 'expert' ? Icons.medical_services : Icons.person,
                            color: type == 'expert' ? AppColors.purple : AppColors.pink,
                          )
                        : null,
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
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unreadCount > 0 ? AppColors.textDark : AppColors.textMedium,
                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              trailing: unreadCount > 0
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              onTap: () {
                if (type == 'expert') {
                  context.push('/expert/chat/${chat['id']}', extra: {'expertName': name});
                } else if (type == 'peer') {
                  context.push('/peerline/chat/${chat['id']}');
                }
              },
            ),
          );
        },
      ),
    );
  }
}
