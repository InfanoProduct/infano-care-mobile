import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/models/peerline_session.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/services/community_socket_service.dart';
import 'package:infano_care_mobile/models/chat_message.dart';
import 'package:infano_care_mobile/widgets/crisis_resource_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';


class PeerLineChatScreen extends StatefulWidget {
  final String sessionId;

  const PeerLineChatScreen({super.key, required this.sessionId});

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
  CommunitySocketService? _socketService;
  StreamSubscription? _socketSubscription;
  String? _piiError;
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
        if (!mounted) return;
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
      
      final storage = Provider.of<LocalStorageService>(context, listen: false);
      storage.setPeerlineChatIntroDismissed(widget.sessionId);

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice note: $e')),
        );
      }
    }
  }


  void _setupSocket() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _socketService = Provider.of<CommunitySocketService>(context, listen: false);
      _socketService?.subscribeToConnection(widget.sessionId);
      _socketSubscription = _socketService?.chatEvents.listen(_handleSocketEvent);
    });
  }

  void _handleSocketEvent(Map<String, dynamic> event) {
    // Robust session filtering
    final String? eventSessionId = event['sessionId'] ?? event['connectionId'];
    final String type = event['type'] ?? '';

    // Always permit errors, but filter session-specific events
    if (type != 'error' && eventSessionId != null && eventSessionId != widget.sessionId) return;

    switch (type) {
      case 'message':
        final newMessage = ChatMessage.fromJson(event);
        final String? clientId = event['clientId'];
        setState(() {
          final int clientMatchIndex = clientId != null
              ? _messages.indexWhere((m) => m.id == clientId)
              : -1;
          if (clientMatchIndex != -1) {
            _messages[clientMatchIndex] = newMessage;
          } else if (!_messages.any((m) => m.id == newMessage.id)) {
            _messages.add(newMessage);
            if (_myRole != null && event['senderRole'] != _myRole) {
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
        final String senderRole = event['senderRole'] ?? '';
        if (_myRole != null && senderRole != _myRole) {
          setState(() => _isPeerTyping = event['isTyping'] ?? false);
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
      case 'connection_accepted':
        // Reload session data so the UI reflects ACTIVE status
        _loadData();
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
    _recordingTimer?.cancel();
    _socketSubscription?.cancel();
    _socketService?.unsubscribeFromConnection(widget.sessionId);
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }


  Future<void> _loadData() async {
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      final session = await api.getSession(widget.sessionId);
      List<ChatMessage> fetchedMessages = [];
      try {
        fetchedMessages = await api.getChatMessages(widget.sessionId);
      } catch (e) {
        debugPrint('Error fetching chat messages in _loadData: $e');
      }

      if (!mounted) return;
      final storage = Provider.of<LocalStorageService>(context, listen: false);
      final userId = storage.userId;
      final myRole = session.menteeId == userId ? 'mentee' : 'mentor';

      if (mounted) {
        final List<ChatMessage> allMessages =
            fetchedMessages.isNotEmpty ? fetchedMessages : session.messages;
        setState(() {
          _session = session;
          _messages.clear();
          _messages.addAll(allMessages);
          _myRole = myRole;
          _isLoading = false;
          _showIntroCard = !storage.isPeerlineChatIntroDismissed(widget.sessionId);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading chat: $e')));
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

    final storage = Provider.of<LocalStorageService>(context, listen: false);
    storage.setPeerlineChatIntroDismissed(widget.sessionId);

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

    final bool isPending = _session!.status.toUpperCase() == 'MATCHING';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: true,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                  child: Text(
                    (_myRole == 'mentor' ? 'T' : (_session?.mentorName ?? 'M')[0]),
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
                      color: isPending
                          ? Colors.orange
                          : (_isPeerTyping ? Colors.amber : Colors.green),
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
                    _myRole == 'mentor'
                        ? 'Teen'
                        : (_session?.mentorName ?? 'Peer Mentor'),
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                  Text(
                    isPending
                        ? 'Pending acceptance…'
                        : (_isPeerTyping ? 'Typing…' : 'Active'),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: isPending
                          ? Colors.orange
                          : (_isPeerTyping
                              ? Colors.amber.shade700
                              : Colors.green),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (isPending)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.orange.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top_rounded,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Waiting for the peer mentor to accept your request.',
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount:
                      _messages.length + (_isPeerTyping && !isPending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0 && _showIntroCard && !isPending) {
                      return _buildIntroCard();
                    }
                    if (index == _messages.length && _isPeerTyping) {
                      return _buildTypingIndicator();
                    }
                    final message = _messages[index];
                    final bool isMe =
                        _myRole != null && message.senderRole == _myRole;
                    return _buildMessageBubble(message, index, isMe);
                  },
                ),
              ),
              _buildInputArea(isPending: isPending),
            ],
          ),
          if (_showCrisisCard)
            CrisisResourceCard(
              onDismiss: () => setState(() {
                _showCrisisCard = false;
              }),
            ),
          if (!_showCrisisCard && _messages.any((m) => m.crisisFlag))
            Positioned(
              top: 10,
              right: 16,
              child: GestureDetector(
                onTap: () => setState(() => _showCrisisCard = true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4)
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('💜', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text('Resources',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.purple)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _dismissIntroCard() {
    setState(() {
      _showIntroCard = false;
    });
    final storage = Provider.of<LocalStorageService>(context, listen: false);
    storage.setPeerlineChatIntroDismissed(widget.sessionId);
  }

  Widget _buildIntroCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
            onPressed: _dismissIntroCard,
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

  Widget _buildInputArea({bool isPending = false}) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: math.max(12, MediaQuery.of(context).padding.bottom),
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
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_piiError!,
                  style:
                      TextStyle(color: Colors.red.shade700, fontSize: 12)),
            ),
          if (_isRecording)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Recording... ${_recordingDuration ~/ 60}:${(_recordingDuration % 60).toString().padLeft(2, '0')}',
                    style: GoogleFonts.outfit(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _stopRecording(cancel: true),
                    child: Text('Cancel',
                        style:
                            TextStyle(color: Colors.grey.shade600)),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.send_rounded, color: AppColors.purple),
                    onPressed: () => _stopRecording(),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
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
                      enabled: !isPending,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (val) {
                        _sendTyping(val.isNotEmpty);
                        if (_piiError != null) {
                          setState(() => _piiError = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: isPending
                            ? 'Waiting for mentor to accept…'
                            : 'Send a message...',
                        border: InputBorder.none,
                        counterText: "",
                        hintStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isPending)
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _messageController,
                    builder: (context, value, _) {
                      final isTextEmpty = value.text.trim().isEmpty;
                      return CircleAvatar(
                        backgroundColor: isTextEmpty
                            ? Colors.grey.shade200
                            : AppColors.purple,
                        child: isTextEmpty
                            ? GestureDetector(
                                onLongPress: _startRecording,
                                onLongPressUp: () => _stopRecording(),
                                child: IconButton(
                                  icon: const Icon(Icons.mic,
                                      color: Colors.grey),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Hold to record voice note')));
                                  },
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 20),
                                onPressed: _sendMessage,
                              ),
                      );
                    },
                  ),
              ],
            ),
          const SizedBox(height: 4),
          // Character count
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (context, value, _) {
                return Text(
                  '${value.text.length}/500',
                  style: TextStyle(
                      fontSize: 11,
                      color: value.text.length > 450
                          ? Colors.red
                          : Colors.grey.shade400),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VoiceMessageBubble extends StatefulWidget {
  final String url;
  final bool isMe;

  const VoiceMessageBubble({super.key, required this.url, required this.isMe});

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
                  inactiveTrackColor: color.withValues(alpha: 0.2),
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
                      style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.6)),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.6)),
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

