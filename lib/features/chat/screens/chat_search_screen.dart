import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/features/expert/services/expert_service.dart';
import 'package:infano_care_mobile/models/peerline_topic.dart';

class ChatSearchScreen extends StatefulWidget {
  const ChatSearchScreen({super.key});

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final ExpertService _expertService;
  late final CommunityApi _communityApi;

  bool _isLoading = true;
  String _searchQuery = "";
  List<PeerLineTopic> _topics = [];
  String? _selectedTopicId;

  List<dynamic> _existingChats = [];
  List<dynamic> _peerMentors = [];
  List<dynamic> _experts = [];

  // Track pending request states locally for optimistic UI
  final Set<String> _requestedMentorIds = {};
  final Map<String, bool> _loadingRequestIds = {};
  final Map<String, String> _newSessionIds = {};

  @override
  void initState() {
    super.initState();
    final storage = Provider.of<LocalStorageService>(context, listen: false);
    _expertService = ExpertService(storage);
    _communityApi = Provider.of<CommunityApi>(context, listen: false);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _communityApi.getPeerLineTopics(),
        _expertService.getExperts(),
        _communityApi.searchMentors([]),
        ApiService.instance.dio.get('chat/my-chats')
      ]);

      if (mounted) {
        setState(() {
          _topics = results[0] as List<PeerLineTopic>;
          _experts = results[1] as List<dynamic>;
          _peerMentors = results[2] as List<dynamic>;
          
          final chatRes = results[3] as dynamic;
          if (chatRes.data['success'] == true) {
            _existingChats = chatRes.data['data'] as List<dynamic>;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ChatSearchScreen] Error loading search data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleTopicSelect(String? topicId) async {
    setState(() {
      _selectedTopicId = topicId;
      _isLoading = true;
    });

    try {
      final List<String> topicFilter = topicId != null ? [topicId] : [];
      final mentors = await _communityApi.searchMentors(topicFilter);
      if (mounted) {
        setState(() {
          _peerMentors = mentors;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ChatSearchScreen] Error filtering mentors: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRequestChat(String mentorId, String mentorName) async {
    setState(() {
      _loadingRequestIds[mentorId] = true;
    });

    try {
      final mentor = _peerMentors.firstWhere((m) => m['id'] == mentorId);
      final profile = mentor['profile'] ?? {};
      final List<String> topicIds = List<String>.from(
        mentor['certifiedTopicIds'] ?? profile['certifiedTopicIds'] ?? []
      );

      final session = await _communityApi.requestConnection(
        mentorId: mentorId,
        topicIds: topicIds,
      );
 
      if (mounted) {
        setState(() {
          _requestedMentorIds.add(mentorId);
          _newSessionIds[mentorId] = session.id;
          _loadingRequestIds[mentorId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent to $mentorName! 💜'),
            backgroundColor: AppColors.purple,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRequestIds[mentorId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to request chat: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<dynamic> _getFilteredChats() {
    if (_searchQuery.trim().isEmpty) return [];
    return _existingChats.where((c) {
      final String name = (c['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<dynamic> _getFilteredPeers() {
    return _peerMentors.where((m) {
      final profile = m['profile'] ?? {};
      final String name = (m['name'] ?? profile['displayName'] ?? '').toString().toLowerCase();
      
      // Filter by query if search query is not empty
      if (_searchQuery.trim().isNotEmpty) {
        return name.contains(_searchQuery.toLowerCase());
      }
      // If query is empty but topic is selected, we already fetched the filtered list from server
      return true;
    }).toList();
  }

  List<dynamic> _getFilteredExperts() {
    if (_searchQuery.trim().isEmpty) return [];
    return _experts.where((e) {
      final profile = e['profile'] ?? {};
      final String name = (profile['displayName'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = _getFilteredChats();
    final filteredPeers = _getFilteredPeers();
    final filteredExperts = _getFilteredExperts();

    final bool hasNoResults = _searchQuery.trim().isNotEmpty && 
        filteredChats.isEmpty && 
        filteredPeers.isEmpty && 
        filteredExperts.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: 'Search chats, mentors, experts...',
            hintStyle: GoogleFonts.nunito(
              fontSize: 15,
              color: Colors.grey.shade400,
            ),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    },
                  )
                : null,
          ),
        ),
      ),
      body: Column(
        children: [
          // Topic chips filter row (always visible)
          if (!_isLoading) _buildTopicChips(),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
                : hasNoResults
                    ? _buildEmptyState()
                    : ListView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        children: [
                          if (filteredChats.isNotEmpty) ...[
                            _buildSectionHeader('Your Conversations'),
                            ...filteredChats.map((c) => _buildExistingChatCard(c)),
                            const SizedBox(height: 20),
                          ],
                          if (filteredExperts.isNotEmpty) ...[
                            _buildSectionHeader('Experts Available'),
                            ...filteredExperts.map((e) => _buildExpertCard(e)),
                            const SizedBox(height: 20),
                          ],
                          if (filteredPeers.isNotEmpty) ...[
                            _buildSectionHeader('Peer Mentors'),
                            ...filteredPeers.map((p) => _buildPeerCard(p)),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicChips() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _topics.length + 1,
        itemBuilder: (context, index) {
          final bool isAll = index == 0;
          final topic = isAll ? null : _topics[index - 1];
          final bool isSelected = isAll 
              ? _selectedTopicId == null 
              : _selectedTopicId == topic?.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                isAll ? 'All Mentors' : (topic?.name ?? ''),
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textMedium,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.purple,
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey.shade50,
              side: BorderSide(
                color: isSelected ? AppColors.purple : Colors.grey.shade200,
                width: 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (_) => _handleTopicSelect(isAll ? null : topic?.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textMedium,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildExistingChatCard(dynamic chat) {
    final String name = chat['name'] ?? 'Unknown';
    final String type = chat['type'] ?? 'peer';
    final String lastMessage = chat['lastMessage'] ?? '';
    final String? avatarUrl = chat['avatarUrl'];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: type == 'expert' ? AppColors.purple.withValues(alpha: 0.1) : AppColors.pink.withValues(alpha: 0.1),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Icon(
                  type == 'expert'
                      ? Icons.medical_services
                      : type == 'gigi'
                          ? Icons.smart_toy_rounded
                          : Icons.person,
                  color: type == 'expert' || type == 'gigi' ? AppColors.purple : AppColors.pink,
                  size: 20,
                )
              : null,
        ),
        title: Text(
          name,
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
        ),
        subtitle: Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMedium),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: () {
          if (type == 'expert') {
            context.push('/expert/chat/${chat['id']}', extra: {'expertName': name});
          } else if (type == 'peer') {
            context.push('/peerline/chat/${chat['id']}');
          } else if (type == 'gigi') {
            context.push('/gigi/chat/${chat['id']}');
          }
        },
      ),
    );
  }

  Widget _buildExpertCard(dynamic expert) {
    final profile = expert['profile'] ?? {};
    final String name = profile['displayName'] ?? 'Expert Helper';
    final String pronouns = profile['pronouns'] ?? 'Verified Expert';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.purple.withValues(alpha: 0.1),
          child: const Icon(Icons.verified_user_rounded, color: AppColors.purple, size: 20),
        ),
        title: Text(
          name,
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
        ),
        subtitle: Text(
          pronouns,
          style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMedium),
        ),
        trailing: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.purple),
        onTap: () async {
          final session = await _expertService.getOrCreateSession(expert['id']);
          if (session != null && mounted) {
            context.push('/expert/chat/${session['id']}', extra: {'expertName': name});
          }
        },
      ),
    );
  }

  Widget _buildPeerCard(dynamic mentor) {
    final profile = mentor['profile'] ?? {};
    final String mentorId = mentor['id'] ?? '';
    final String name = mentor['name'] ?? profile['displayName'] ?? 'Peer Mentor';
    final List certifiedTopics = mentor['certifiedTopics'] ?? mentor['topics'] ?? [];
      final existingChat = _existingChats.firstWhere(
      (c) => c['type'] == 'peer' && c['peerId'] == mentorId,
      orElse: () => null,
    );
    final String? newSessionId = _newSessionIds[mentorId];
    final String? serverSessionId = mentor['sessionId'];
    final String? targetSessionId = existingChat != null ? existingChat['id'] : (serverSessionId ?? newSessionId);
    final bool hasSession = targetSessionId != null || _requestedMentorIds.contains(mentorId) || mentor['hasPendingRequest'] == true;
    
    final bool isRequested = _requestedMentorIds.contains(mentorId) || mentor['hasPendingRequest'] == true;
    final bool isRequestLoading = _loadingRequestIds[mentorId] == true;
 
    List<String> topics = [];
    if (certifiedTopics.isNotEmpty) {
      if (certifiedTopics.first is Map) {
        topics = certifiedTopics.map<String>((t) => t['name'].toString()).toList();
      } else {
        topics = certifiedTopics.map<String>((t) => t.toString()).toList();
      }
    }
 
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.pink.withValues(alpha: 0.1),
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'M',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: AppColors.pink, fontSize: 18),
              ),
            ),
            title: Text(
              name,
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: topics.take(2).map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(t, style: GoogleFonts.nunito(fontSize: 9, color: AppColors.textMedium, fontWeight: FontWeight.bold)),
                )).toList(),
              ),
            ),
            trailing: isRequestLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple))
                : hasSession
                    ? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey)
                    : ElevatedButton(
                        onPressed: () => _handleRequestChat(mentorId, name),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          minimumSize: const Size(60, 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text('Request', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
            onTap: () {
              if (targetSessionId != null) {
                context.push('/peerline/chat/$targetSessionId');
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No results found for "$_searchQuery"',
            style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

