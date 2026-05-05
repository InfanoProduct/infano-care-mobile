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
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';


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

  
  // Voice recording state
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  Timer? _recordingTimer;
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTimer();
    _setupSocket();
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getTemporaryDirectory();
        _recordingPath = '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        const config = RecordConfig();
        await _audioRecorder.start(config, path: _recordingPath!);
        
        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });
        
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingDuration++;
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required to record voice notes.')),
        );
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    try {
      _recordingTimer?.cancel();
      final path = await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
      });

      if (!cancel && path != null) {
        _sendVoiceNote(path);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _sendVoiceNote(String path) async {
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      
      // Show optimistic UI for voice note
      final String clientId = 'client-voice-${DateTime.now().millisecondsSinceEpoch}';
      final tempMessage = ChatMessage(
        id: clientId,
        sessionId: widget.sessionId,
        senderRole: _myRole ?? 'mentee',
        messageType: 'VOICE',
        mediaUrl: path, // Local path for now
        sentAt: DateTime.now(),
      );

      setState(() {
        _messages.add(tempMessage);
        _showIntroCard = false;
      });
      _scrollToBottom();

      // Upload file
      final mediaUrl = await api.uploadMedia(path);
      
      // Send via socket
      _socketService?.sendMessage(
        widget.sessionId,
        null,
        _myRole ?? 'mentee',
        messageType: 'VOICE',
        mediaUrl: mediaUrl,
        clientId: clientId,
      );
    } catch (e) {
      debugPrint('Error sending voice note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send voice note: $e')),
      );
    }
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
    // Robust session filtering
    final String? eventSessionId = event['sessionId'];
    final String type = event['type'] ?? '';
    
    // Always permit errors, but filter session-specific events
    if (type != 'error' && eventSessionId != null && eventSessionId != widget.sessionId) return;

    switch (type) {
      case 'message':
        final newMessage = ChatMessage.fromJson(event);
        final String? clientId = event['clientId'];
        
        setState(() {
          // Check if we have an optimistic message matching this clientId
          final int existingIndex = clientId != null 
              ? _messages.indexWhere((m) => m.id.startsWith('temp-') && m.content == newMessage.content) // Fallback content match if ID system differs
              : -1;

          // More reliable: if we have clientId, find and replace
          final int clientMatchIndex = clientId != null 
              ? _messages.indexWhere((m) => m.id == clientId) 
              : -1;

          if (clientMatchIndex != -1) {
            // Replace optimistic message with real one from server
            _messages[clientMatchIndex] = newMessage;
          } else if (!_messages.any((m) => m.id == newMessage.id)) {
            // Standard add for messages from the other peer
            _messages.add(newMessage);
            if (event['senderRole'] == 'mentor') {
              _isPeerTyping = false;
            }
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
        if (mounted) {
          _showSessionEndedBanner();
        }
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
    
    // Explicit unique clientId for deduplication
    final String clientId = 'client-${DateTime.now().millisecondsSinceEpoch}-${math.Random().nextInt(1000)}';

    // Optimistic UI: Add message locally first
    final tempMessage = ChatMessage(
      id: clientId, // Use clientId as temp ID
      sessionId: widget.sessionId,
      senderRole: _myRole ?? 'mentee',
      content: text,
      sentAt: DateTime.now(),
    );

    setState(() {
      _messages.add(tempMessage);
      _piiError = null;
      _showIntroCard = false;
    });
    _scrollToBottom();

    try {
      _socketService?.sendMessage(
        widget.sessionId, 
        text, 
        _myRole ?? 'mentee', 
        clientId: clientId // Pass to server
      );
      _sendTyping(false);
      _socketService?.sendTypingStop(widget.sessionId, _myRole ?? 'mentee');
    } catch (e) {
      // Remove optimistic message on failure
      setState(() => _messages.remove(tempMessage));
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
                      _isPeerTyping 
                          ? 'Typing...' 
                          : (_session?.mentorId == null && _myRole == 'mentee' ? 'Finding your mentor...' : 'Online'),
                      style: GoogleFonts.outfit(
                        fontSize: 12, 
                        color: _isPeerTyping ? Colors.amber.shade700 : (_session?.mentorId == null && _myRole == 'mentee' ? Colors.grey : Colors.green), 
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
            msg.content ?? "",
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
            if (index % 10 == 0 || index == 0) 
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
                    ? const Color(0xFFFFF1F2)
                    : const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isMe ? 22 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 22),
                ),
                border: Border.all(
                  color: isMe ? const Color(0xFFFEE2E2) : const Color(0xFFEDE9FE),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (msg.messageType == 'VOICE' && msg.mediaUrl != null)
                    VoiceMessageBubble(url: msg.mediaUrl!, isMe: isMe)
                  else
                    Text(
                      msg.content ?? "",
                      style: GoogleFonts.outfit(
                        color: isMe ? const Color(0xFF9F1239) : const Color(0xFF5B21B6), 
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(msg.sentAt),
                        style: TextStyle(
                          fontSize: 9, 
                          color: isMe ? const Color(0xFFFDA4AF) : const Color(0xFFC4B5FD),
                          fontWeight: FontWeight.w500
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead ? Icons.done_all : Icons.done,
                          size: 11,
                          color: const Color(0xFFFDA4AF),
                        ),
                      ]
                    ],
                  ),
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
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Recording... ${_recordingDuration ~/ 60}:${(_recordingDuration % 60).toString().padLeft(2, '0')}',
                    style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _stopRecording(cancel: true),
                    child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.purple),
                    onPressed: () => _stopRecording(),
                  ),
                ],
              ),
            )
          else
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
                    final isTextEmpty = value.text.trim().isEmpty;
                    return CircleAvatar(
                      backgroundColor: isTextEmpty ? Colors.grey.shade200 : AppColors.purple,
                      child: isTextEmpty
                        ? GestureDetector(
                            onLongPress: _startRecording,
                            onLongPressUp: () => _stopRecording(),
                            child: IconButton(
                              icon: const Icon(Icons.mic, color: Colors.grey),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Hold to record voice note')),
                                );
                              },
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            onPressed: _sendMessage,
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

  void _showSessionEndedBanner() {
    int selectedRating = 0;
    final TextEditingController noteController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 28,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Emoji + title
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Text('💜', style: TextStyle(fontSize: 36))),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Session Complete!',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How was your session with ${_session?.mentorName ?? 'your mentor'}?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textMedium, height: 1.4),
                    ),
                    const SizedBox(height: 28),

                    // Star rating
                    Text(
                      'Rate your experience',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final starIndex = i + 1;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedRating = starIndex),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Icon(
                              starIndex <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 44,
                              color: starIndex <= selectedRating ? Colors.amber : Colors.grey.shade300,
                            ),
                          ),
                        );
                      }),
                    ),
                    if (selectedRating > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        ['', 'Not helpful', 'It was okay', 'Pretty good', 'Really helpful', 'Amazing! 🌟'][selectedRating],
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selectedRating >= 4 ? const Color(0xFF10B981) : AppColors.purple,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Optional note
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: noteController,
                        maxLines: 3,
                        maxLength: 200,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.outfit(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Share any thoughts (optional)…',
                          hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          counterStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (selectedRating == 0 || isSubmitting) ? null : () async {
                          setSheetState(() => isSubmitting = true);
                          try {
                            final api = Provider.of<CommunityApi>(context, listen: false);
                            await api.submitPeerLineFeedback(
                              sessionId: widget.sessionId,
                              role: _myRole ?? 'mentee',
                              rating: selectedRating,
                              note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                            );
                          } catch (_) {
                            // Feedback failure is non-blocking
                          }
                          if (mounted) {
                            Navigator.pop(sheetContext);
                            context.go('/home?tab=4&subtab=1');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          disabledBackgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: isSubmitting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              selectedRating == 0 ? 'Select a rating to continue' : 'Submit & Go Home',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: selectedRating == 0 ? Colors.grey.shade400 : Colors.white,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Skip link
                    TextButton(
                      onPressed: isSubmitting ? null : () {
                        Navigator.pop(sheetContext);
                        context.go('/home?tab=4&subtab=1');
                      },

                      child: Text(
                        'Skip for now',
                        style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                if (mounted) {
                  _showSessionEndedBanner();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text('Could not end session: ${e.toString()}')),
                  );
                }
              }
            }, 
            child: Text('End Session', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}

class VoiceMessageBubble extends StatefulWidget {
  final String url;
  final bool isMe;

  const VoiceMessageBubble({Key? key, required this.url, required this.isMe}) : super(key: key);

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _playerSub;

  @override
  void initState() {
    super.initState();
    _setupPlayer();
  }

  void _setupPlayer() {
    _durationSub = _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _positionSub = _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _playerSub = _player.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playerSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      if (widget.url.startsWith('http')) {
        await _player.play(UrlSource(widget.url));
      } else {
        await _player.play(DeviceFileSource(widget.url));
      }
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? const Color(0xFF9F1239) : const Color(0xFF5B21B6);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: color, size: 32),
          onPressed: _togglePlay,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: color,
                  inactiveTrackColor: color.withOpacity(0.2),
                  thumbColor: color,
                ),
                child: Slider(
                  value: _position.inMilliseconds.toDouble(),
                  max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                  onChanged: (val) => _player.seek(Duration(milliseconds: val.toInt())),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(fontSize: 10, color: color.withOpacity(0.6)),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(fontSize: 10, color: color.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

