import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/models/peerline_session.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/services/community_socket_service.dart';
import 'package:infano_care_mobile/models/chat_message.dart';
import 'package:infano_care_mobile/widgets/crisis_resource_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class PeerLineChatScreen extends StatefulWidget {
  final String sessionId;

  const PeerLineChatScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<PeerLineChatScreen> createState() => _PeerLineChatScreenState();
}

class _PeerLineChatScreenState extends State<PeerLineChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  PeerLineSession? _session;
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isPeerTyping = false;
  bool _showIntroCard = true;
  bool _showCrisisCard = false;
  Timer? _sessionTimer;
  Duration _sessionDuration = Duration.zero;
  CommunitySocketService? _socketService;
  StreamSubscription? _socketSubscription;
  String? _piiError;
  String? _currentUserId;
  String? _myRole;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTimer();
    _setupSocket();
  }

  void _setupSocket() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _socketService = Provider.of<CommunitySocketService>(context, listen: false);
      _socketService?.subscribeToSession(widget.sessionId);
      _socketSubscription = _socketService?.chatEvents.listen(_handleSocketEvent);
    });
  }

  void _startTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _sessionDuration += const Duration(seconds: 1);
        });
        
        // 30-minute nudge (1800 seconds)
        if (_sessionDuration.inSeconds == 1800) {
          _messages.add(ChatMessage(
            id: 'nudge-30',
            sessionId: widget.sessionId,
            senderRole: 'system',
            content: 'Taking your time is fine. If you need a break, you can pause and return 💜',
            sentAt: DateTime.now(),
          ));
          _scrollToBottom();
        }
      }
    });
  }

  void _handleSocketEvent(Map<String, dynamic> event) {
    if (event['sessionId'] != widget.sessionId && event['type'] != 'error' && event['type'] != 'message' && event['type'] != 'message_deleted') return;

    switch (event['type']) {
      case 'message':
        setState(() {
          _messages.add(ChatMessage.fromJson(event));
          if (event['senderRole'] == 'mentor') {
            _isPeerTyping = false;
          }
        });
        _scrollToBottom();
        break;
      case 'message_deleted':
        setState(() {
          _messages.removeWhere((m) => m.id == event['messageId']);
        });
        break;
      case 'peer_typing':
        if (event['senderRole'] == 'mentor') {
          setState(() => _isPeerTyping = event['isTyping'] ?? false);
          
          // Auto-hide typing indicator after 10s as per spec
          if (_isPeerTyping) {
            Timer(const Duration(seconds: 10), () {
              if (mounted) setState(() => _isPeerTyping = false);
            });
          }
        }
        break;
      case 'crisis_resource':
        setState(() => _showCrisisCard = true);
        break;
      case 'session_ended':
        _sessionTimer?.cancel();
        context.pushReplacement('/peerline/feedback/${widget.sessionId}');
        break;
      case 'session_paused':
        setState(() {
          _messages.add(ChatMessage(
            id: 'pause-${DateTime.now().millisecondsSinceEpoch}',
            sessionId: widget.sessionId,
            senderRole: 'system',
            content: 'Session paused by peer. Taking your time is fine. 💜',
            sentAt: DateTime.now(),
          ));
        });
        _scrollToBottom();
        break;
      case 'error':
        if (event['type'] == 'PII_BLOCKED') {
          setState(() => _piiError = event['message']);
        }
        break;
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _socketSubscription?.cancel();
    _socketService?.unsubscribeFromSession(widget.sessionId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  Future<void> _loadData() async {
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      final session = await api.getSession(widget.sessionId);

      final storage = Provider.of<LocalStorageService>(context, listen: false);
      final userId = storage.userId;
      final myRole = session.menteeId == userId ? 'mentee' : 'mentor';

      if (mounted) {
        setState(() {
          _session = session;
          _messages.clear();
          _messages.addAll(session.messages);
          _currentUserId = userId;
          _myRole = myRole;
          _isLoading = false;
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
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendTyping(bool isTyping) {
    if (_myRole == null) return;
    _socketService?.sendTypingIndicator(widget.sessionId, isTyping, _myRole!);
  }

  bool _scanForPII(String text) {
    final phoneRegex = RegExp(r'(\+?\d{1,4}[\s-]?)?\(?\d{3}\)?[\s-]?\d{3}[\s-]?\d{4}');
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final urlRegex = RegExp(r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)');

    return phoneRegex.hasMatch(text) || emailRegex.hasMatch(text) || urlRegex.hasMatch(text);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_scanForPII(text)) {
      setState(() => _piiError = "For safety, let's keep our conversations here in PeerLine.");
      return;
    }
    
    _messageController.clear();
    setState(() {
      _piiError = null;
      _showIntroCard = false;
    });

    try {
      _socketService?.sendMessage(widget.sessionId, text, _myRole ?? 'mentee');
      _sendTyping(false);
      _socketService?.sendTypingStop(widget.sessionId, _myRole ?? 'mentee');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    }
  }

  void _unsendMessage(String messageId) {
    _socketService?.unsendMessage(widget.sessionId, messageId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.purple.withOpacity(0.1),
                    child: Text(
                      (_session?.mentorName ?? 'M')[0],
                      style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _isPeerTyping ? Colors.amber : Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _myRole == 'mentor' ? 'Mentee' : (_session?.mentorName ?? 'Peer Mentor'),
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    Text(
                      _isPeerTyping ? 'Typing...' : 'Online',
                      style: GoogleFonts.outfit(
                        fontSize: 12, 
                        color: _isPeerTyping ? Colors.amber.shade700 : Colors.green, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _showEndSessionDialog(),
              child: Text(
                'End session', 
                style: GoogleFonts.outfit(color: AppColors.textLight.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    itemCount: _messages.length + (_isPeerTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && _showIntroCard) {
                        return _buildIntroCard();
                      }
                      
                      if (index == _messages.length && _isPeerTyping) {
                        return _buildTypingIndicator();
                      }
                      
                      final message = _messages[index];
                      final bool isMe = _myRole != null && message.senderRole == _myRole;
                      
                      return _buildMessageBubble(message, index, isMe);
                    },
                  ),
                ),
                _buildInputArea(),
              ],
            ),
            if (_showCrisisCard) 
              CrisisResourceCard(
                onDismiss: () => setState(() {
                  _showCrisisCard = false;
                  // Persist as a small pill as per spec 7.2
                }),
              ),
            if (!_showCrisisCard && _messages.any((m) => m.crisisFlag))
              Positioned(
                top: 10,
                right: 16,
                child: GestureDetector(
                  onTap: () => setState(() => _showCrisisCard = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('💜', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Text('Resources', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.purple)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
  }

  Widget _buildIntroCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text('💜', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            "You're connected with ${_session?.mentorName ?? 'a Peer Mentor'}",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "This is a peer conversation — for professional support, resources are always here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _showIntroCard = false),
            child: Text('Dismiss', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => 
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
            )
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, int index, bool isMe) {
    if (msg.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            msg.content,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      );
    }
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe ? () => _showUnsendDialog(msg.id) : null,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (index % 10 == 0 || index == 0) // Show date divider for very first message or interval
               Center(
                 child: Padding(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   child: Text(
                     DateFormat('MMM d, hh:mm a').format(msg.sentAt),
                     style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                   ),
                 ),
               ),
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isMe 
                    ? const Color(0xFFFFE4E6) // Pink for mentee
                    : const Color(0xFFF0FDFA), // Teal/Light Purple tint for mentor
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: isMe ? null : [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    msg.content,
                    style: GoogleFonts.outfit(
                      color: isMe ? const Color(0xFFE11D48) : const Color(0xFF0D9488), // Rose for mentee, Teal for mentor
                      fontSize: 15,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(height: 2),
                    Text(
                      msg.isRead ? '✓✓' : '✓', 
                      style: const TextStyle(fontSize: 10, color: Color(0xFFE11D48), fontWeight: FontWeight.bold)
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnsendDialog(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsend message?'),
        content: const Text('This will remove the message for everyone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _unsendMessage(messageId);
            },
            child: const Text('Unsend', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, 
        right: 16, 
        top: 12, 
        bottom: math.max(12, MediaQuery.of(context).padding.bottom)
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Column(
        children: [
          if (_piiError != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(_piiError!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.pause_circle_outline, color: Colors.grey),
                onPressed: () {
                  _socketService?.pauseSession(widget.sessionId);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session paused.')));
                },
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (val) {
                      _sendTyping(val.isNotEmpty);
                      if (_piiError != null) setState(() => _piiError = null);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Send a message...',
                      border: InputBorder.none,
                      counterText: "",
                      hintStyle: TextStyle(fontSize: 14),
                    ),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${_sessionDuration.inMinutes}:${(_sessionDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _messageController,
                builder: (context, value, _) {
                  return Text(
                    "${value.text.length}/500",
                    style: TextStyle(fontSize: 11, color: value.text.length > 450 ? Colors.red : Colors.grey.shade400),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEndSessionDialog() {
    final parentContext = context;
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('End Session?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to end this PeerLine support session?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              _socketService?.endSession(widget.sessionId, 'user_ended');
              try {
                final api = Provider.of<CommunityApi>(parentContext, listen: false);
                await api.endSession(widget.sessionId);
                if (mounted) parentContext.pushReplacement('/peerline/feedback/${widget.sessionId}');
              } catch (e) {
                // If the backend call fails, at least the socket event went out.
                // The socket listener will redirect if it catches the broadcast.
              }
            }, 
            child: Text('End Session', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}
