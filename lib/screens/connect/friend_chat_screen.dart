import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/services/friends_api.dart';
import 'package:infano_care_mobile/services/friends_socket_service.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class FriendChatScreen extends StatefulWidget {
  final String matchId;

  const FriendChatScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  State<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends State<FriendChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  Map<String, dynamic>? _matchData;
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isPeerTyping = false;
  bool _showTagsBanner = true;
  String? _safetyError;
  String? _currentUserId;
  
  FriendsSocketService? _socketService;
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupSocket();
  }

  void _setupSocket() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _socketService = Provider.of<FriendsSocketService>(context, listen: false);
      _socketService?.subscribeToChat(widget.matchId);
      _socketSubscription = _socketService?.chatEvents.listen(_handleSocketEvent);
    });
  }

  void _handleSocketEvent(Map<String, dynamic> event) {
    if (event['matchId'] != widget.matchId && event['type'] != 'error') return;

    switch (event['type']) {
      case 'message':
        setState(() {
          final String? clientId = event['clientId'];
          final int clientMatchIndex = clientId != null 
              ? _messages.indexWhere((m) => m['id'] == clientId) 
              : -1;

          if (clientMatchIndex != -1) {
            _messages[clientMatchIndex] = event;
          } else {
            _messages.add(event);
            if (event['senderId'] != _currentUserId) {
              _isPeerTyping = false;
            }
          }
          
          if (_messages.length > 3 && _showTagsBanner) {
            _showTagsBanner = false;
          }
        });
        _scrollToBottom();
        break;
      case 'peer_typing':
        setState(() => _isPeerTyping = event['isTyping'] ?? false);
        break;
      case 'safety_alert':
        setState(() => _safetyError = event['message']);
        if (event['severity'] == 'suspended') {
          // Disable input or similar?
        }
        break;
      case 'grooming_check':
        _showSafetyNudge(event['text']);
        break;
    }
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _socketService?.unsubscribeFromChat(widget.matchId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final storage = Provider.of<LocalStorageService>(context, listen: false);
      _currentUserId = storage.userId;
      
      final api = FriendsApi(ApiService.instance.dio);
      final result = await api.getChatMessages(widget.matchId);
      
      if (mounted) {
        setState(() {
          _matchData = result['match'];
          _messages.clear();
          _messages.addAll(List<Map<String, dynamic>>.from(result['messages']));
          _isLoading = false;
          _showTagsBanner = _messages.length <= 3;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading chat: $e')));
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 200,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendTyping(bool isTyping) {
    _socketService?.sendTypingIndicator(widget.matchId, isTyping);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final clientId = 'c-${DateTime.now().millisecondsSinceEpoch}';

    final tempMessage = {
      'id': clientId,
      'matchId': widget.matchId,
      'senderId': _currentUserId,
      'content': text,
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(tempMessage);
      _safetyError = null;
    });
    _scrollToBottom();

    try {
      _socketService?.sendMessage(widget.matchId, text, clientId: clientId);
      _sendTyping(false);
    } catch (e) {
      setState(() => _messages.remove(tempMessage));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  void _showSafetyNudge(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppColors.purple,
        duration: const Duration(seconds: 5),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nickname = _matchData?['nickname'] ?? 'Friend';
    final photoUrl = _matchData?['photoUrl'];
    final vibeTags = List<String>.from(_matchData?['vibeTags'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leadingWidth: 40,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.purple.withOpacity(0.1),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null ? Text(nickname[0], style: const TextStyle(color: AppColors.purple)) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nickname, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  Text(
                    _isPeerTyping ? 'Typing...' : 'Online',
                    style: TextStyle(fontSize: 12, color: _isPeerTyping ? Colors.amber.shade700 : Colors.green, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppColors.purple),
            onPressed: _showSafetyOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          if (vibeTags.isNotEmpty) _buildTagsBanner(vibeTags),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length + (_messages.isEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                if (_messages.isEmpty) return _buildIceBreakers(vibeTags);
                
                final msg = _messages[index];
                final isMe = msg['senderId'] == _currentUserId;
                return _buildMessageBubble(msg, isMe, index);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTagsBanner(List<String> tags) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showTagsBanner ? 60 : 0,
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.purple.withOpacity(0.05), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              const Text('Shared Vibes: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.purple)),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: tags.map((t) => Text('#$t', style: const TextStyle(fontSize: 12, color: AppColors.textLight))).toList(),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showTagsBanner = !_showTagsBanner),
                child: Icon(Icons.keyboard_arrow_up, size: 20, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIceBreakers(List<String> tags) {
    final starters = [
      if (tags.isNotEmpty) "Ask about their favorite thing about #${tags[0]}",
      "Say hi and share what's on your mind today! 🌸",
      if (tags.length > 1) "You both love #${tags[1]} - share a fun fact!",
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const Text('✨ Start the conversation ✨', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.purple)),
          const SizedBox(height: 20),
          ...starters.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.purple.withOpacity(0.1)),
            ),
            child: Text(s, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textLight)),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe, int index) {
    final sentAt = DateTime.parse(msg['createdAt'] ?? DateTime.now().toIso8601String());
    
    bool showTimeDivider = false;
    if (index == 0) {
      showTimeDivider = true;
    } else {
      final prevMsg = _messages[index - 1];
      final prevSentAt = DateTime.parse(prevMsg['createdAt'] ?? DateTime.now().toIso8601String());
      if (sentAt.difference(prevSentAt).inMinutes >= 10) {
        showTimeDivider = true;
      }
    }

    return Column(
      children: [
        if (showTimeDivider)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              DateFormat('MMM d, h:mm a').format(sentAt),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            ),
          ),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFFFF1F2) : const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              border: Border.all(color: isMe ? const Color(0xFFFEE2E2) : const Color(0xFFEDE9FE)),
            ),
            child: Text(
              msg['content'] ?? '',
              style: GoogleFonts.outfit(color: isMe ? const Color(0xFF9F1239) : const Color(0xFF5B21B6), fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: math.max(12, MediaQuery.of(context).padding.bottom)),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
      child: Column(
        children: [
          if (_safetyError != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(_safetyError!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(24)),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (val) {
                      _sendTyping(val.isNotEmpty);
                      if (_safetyError != null) setState(() => _safetyError = null);
                    },
                    decoration: const InputDecoration(hintText: 'Send a message...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _messageController,
                builder: (context, value, _) {
                  final canSend = value.text.trim().isNotEmpty;
                  return CircleAvatar(
                    backgroundColor: canSend ? AppColors.purple : Colors.grey.shade200,
                    child: IconButton(
                      icon: Icon(Icons.send_rounded, color: canSend ? Colors.white : Colors.grey, size: 20),
                      onPressed: canSend ? _sendMessage : null,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSafetyOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred, color: Colors.amber),
              title: const Text('Report Conversation'),
              subtitle: const Text('Flag for safety review'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Unmatch & Block'),
              subtitle: const Text('Remove from matches and stop contact'),
              onTap: () {
                Navigator.pop(context);
                _confirmBlock();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    final reasons = ['Inappropriate content', 'External contact sharing', 'Bullying/Harassment', 'Suspicious behavior', 'Other'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons.map((r) => ListTile(
              title: Text(r),
              onTap: () async {
                Navigator.pop(context);
                final api = FriendsApi(ApiService.instance.dio);
                await api.reportMatch(widget.matchId, r);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted. Thank you for keeping Infano safe.')));
                }
              },
            )).toList(),
          ),
        ),
      ),
    );
  }

  void _confirmBlock() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unmatch & Block?'),
        content: const Text('This will remove the match and they won\'t be able to contact you again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final api = FriendsApi(ApiService.instance.dio);
              await api.blockMatch(widget.matchId);
              if (mounted) context.pop();
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
