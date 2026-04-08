import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/expert/services/expert_service.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class ExpertChatScreen extends StatefulWidget {
  final String sessionId;
  final String expertName;
  final LocalStorageService storage;

  const ExpertChatScreen({
    super.key,
    required this.sessionId,
    required this.expertName,
    required this.storage,
  });

  @override
  State<ExpertChatScreen> createState() => _ExpertChatScreenState();
}

class _ExpertChatScreenState extends State<ExpertChatScreen> {
  late final ExpertService _expertService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _expertService = ExpertService(widget.storage);
    
    // Mark messages as read when opening the chat
    _expertService.markAsRead(widget.sessionId);
    
    _loadHistory();
    _expertService.connectToChat(widget.sessionId, (message) {
      if (mounted) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
        // If we receive a message while the screen is open, mark it read immediately
        _expertService.markAsRead(widget.sessionId);
      }
    });
  }

  Future<void> _loadHistory() async {
    final history = await _expertService.getMessages(widget.sessionId);
    if (mounted) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(history);
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      _expertService.sendMessage(widget.sessionId, content);
      _messageController.clear();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _expertService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = widget.storage.userId ?? '';
    
    // Source of Truth: Always try to get the most accurate ID from the current token
    if (widget.storage.authToken != null) {
      try {
        final Map<String, dynamic> decodedToken = JwtDecoder.decode(widget.storage.authToken!);
        final tokenUserId = (decodedToken['sub'] ?? decodedToken['id'] ?? '').toString();
        if (tokenUserId.isNotEmpty) {
          currentUserId = tokenUserId;
          // Silently sync to storage if different
          if (widget.storage.userId != tokenUserId) {
            widget.storage.setUserId(tokenUserId);
          }
        }
      } catch (e) {
        debugPrint('[ExpertChat] Identity verification error: $e');
      }
    }
    
    debugPrint('[ExpertChat] Verified ID for alignment: $currentUserId');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.purple.withValues(alpha: 0.1),
              child: Text(widget.expertName.isNotEmpty ? widget.expertName.substring(0, 1).toUpperCase() : 'E', 
                style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.expertName, 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark)),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: _expertService.connectionStatus,
                        builder: (context, isOnline, _) {
                          return Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                if (isOnline) BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _expertService.connectionStatus,
                    builder: (context, isOnline, _) {
                      return Text(
                        isOnline ? 'Online' : 'Connecting...',
                        style: TextStyle(
                          fontSize: 12, 
                          color: isOnline ? Colors.green : AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final senderId = msg['senderId']?.toString() ?? '';
                      final isMe = senderId == currentUserId && currentUserId.isNotEmpty;
                      
                      debugPrint('DEBUG: index=$index senderId=[$senderId] currentUserId=[$currentUserId] isMe=$isMe');

                      return _buildMessageBubble(msg['content'], isMe, msg['createdAt'], senderId);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isMe, String timestamp, String senderId) {
    final timeStr = timestamp.toString();
    String time = '...';
    try {
      time = DateFormat('hh:mm a').format(DateTime.parse(timeStr).toLocal());
    } catch (_) {}
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              color: isMe ? AppColors.purple : AppColors.surfaceCard,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe) Text('Sender: ...${senderId.split('-').first}', 
                  style: TextStyle(fontSize: 10, color: AppColors.textLight.withOpacity(0.5))),
                Text(
                  content, 
                  style: TextStyle(
                    color: isMe ? Colors.white : AppColors.textDark,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(time, style: TextStyle(fontSize: 10, color: AppColors.textLight)),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.purple.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppColors.purple,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x667C3AED),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
