import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/widgets/voice_message_bubble.dart';
import 'package:infano_care_mobile/widgets/voice_recorder_bar.dart';
import '../bloc/chat_bloc.dart';
import '../data/chat_repository.dart';
import '../services/voice_service.dart';

class ChatScreen extends StatefulWidget {
  final String sessionId;
  const ChatScreen({super.key, this.sessionId = ''});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GigiMobileVoiceService _voiceService = GigiMobileVoiceService();

  bool _isListening = false;
  bool _isRecordingVoice = false;
  bool _isSpeaking = false;
  String? _currentlySpeakingText;
  bool _autoVoiceResponse = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _voiceService.initSpeech();
    _voiceService.initTts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.sessionId.isNotEmpty && widget.sessionId != 'new') {
        context.read<ChatBloc>().add(SelectSession(widget.sessionId));
      } else {
        context.read<ChatBloc>().add(LoadSessions());
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels <= _scrollController.position.minScrollExtent + 50) {
      context.read<ChatBloc>().add(LoadMoreHistory());
    }
  }

  @override
  void dispose() {
    _voiceService.stopSpeaking();
    _voiceService.stopListening();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleSpeak(String text) {
    if (_isSpeaking && _currentlySpeakingText == text) {
      _voiceService.stopSpeaking();
      setState(() {
        _isSpeaking = false;
        _currentlySpeakingText = null;
      });
    } else {
      setState(() {
        _currentlySpeakingText = text;
      });
      _voiceService.speak(
        text,
        onStart: () {
          if (mounted) setState(() => _isSpeaking = true);
        },
        onComplete: () {
          if (mounted) {
            setState(() {
              _isSpeaking = false;
              _currentlySpeakingText = null;
            });
          }
        },
      );
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    _voiceService.stopSpeaking();
    setState(() {
      _isSpeaking = false;
      _currentlySpeakingText = null;
    });

    await _voiceService.startListening(
      onStart: () {
        if (mounted) setState(() => _isListening = true);
      },
      onResult: (recognizedText, isFinal) {
        if (mounted) {
          _controller.text = recognizedText;
          if (isFinal && recognizedText.trim().isNotEmpty) {
            setState(() => _isListening = false);
            _handleSend();
          }
        }
      },
      onEnd: () {
        if (mounted) setState(() => _isListening = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (_isSpeaking)
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.purple, width: 2),
                    ),
                  ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.purple.withValues(alpha: 0.15), width: 1.5),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/gigi_avatar.png'),
                      fit: BoxFit.cover,
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
                  Row(
                    children: [
                      const Text(
                        'Talk to Gigi',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      if (_isSpeaking) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Speaking ✨',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.purple),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Text(
                    'Always here for you 🌸',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _autoVoiceResponse ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _autoVoiceResponse ? AppColors.purple : Colors.grey,
            ),
            tooltip: _autoVoiceResponse ? 'Voice read-aloud active' : 'Voice muted',
            onPressed: () {
              if (_isSpeaking) {
                _voiceService.stopSpeaking();
                setState(() => _isSpeaking = false);
              }
              setState(() => _autoVoiceResponse = !_autoVoiceResponse);
            },
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.purple),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is ChatSuccess && state.messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  final lastMsg = state.messages.last;
                  if (lastMsg['sender'] == 'GIGI' && _autoVoiceResponse && !state.isSending) {
                    final content = lastMsg['content'] as String? ?? '';
                    if (content.isNotEmpty && _currentlySpeakingText != content) {
                      _toggleSpeak(content);
                    }
                  }
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.purple),
                  );
                }

                if (state is ChatSuccess) {
                  if (state.messages.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: state.messages.length + (state.isSending ? 1 : 0) + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (state.isLoadingMore && index == 0) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
                            ),
                          ),
                        );
                      }

                      final adjustedIndex = state.isLoadingMore ? index - 1 : index;

                      if (adjustedIndex == state.messages.length) {
                        return _buildTypingIndicator();
                      }

                      final msg = state.messages[adjustedIndex];
                      final isMe = msg['sender'] == 'USER';
                      final isLastMessage = adjustedIndex == state.messages.length - 1;

                      if (isMe) {
                        return _buildMessageBubble(msg['content'] as String, isMe);
                      } else {
                        final parsed = _parseGigiMessage(msg['content'] as String);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMessageBubble(msg['content'] as String, isMe),
                            if (parsed.links.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: parsed.links.map((link) => _buildActionLink(link)).toList(),
                                ),
                              ),
                            ],
                            if (isLastMessage && parsed.options.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 8, bottom: 8),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: parsed.options.map((opt) => _buildOptionChip(opt.label, opt.value)).toList(),
                                ),
                              ),
                            ],
                          ],
                        );
                      }
                    },
                  );
                }

                if (state is ChatError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => context.read<ChatBloc>().add(LoadSessions()),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.purple),
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return _buildEmptyState();
              },
            ),
          ),
          if (_isListening) _buildListeningBanner(),
          _buildInputArea(),
        ],
      ),
    );
  }

  // ─── Listening Banner ───────────────────────────────────────────────────────
  Widget _buildListeningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.purple, AppColors.pink],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.mic, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Gigi is listening... speak now!',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          InkWell(
            onTap: _toggleListening,
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white, fontSize: 12, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty / Welcome State ────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.2), width: 3),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/gigi_avatar.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Hi! I\'m Gigi.',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'I\'m your safe space to vent, share, and talk about anything on your mind. How are you feeling today?',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textLight, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildQuickPrompt('😊 I need to vent', 'I need to vent about something that\'s been bothering me.'),
                  _buildQuickPrompt('😰 Feeling stressed', 'I\'m feeling really stressed today and don\'t know how to cope.'),
                  _buildQuickPrompt('💬 Just talk', 'Hi Gigi! I just want to chat. How are you?'),
                  _buildQuickPrompt('❤️ Period stuff', 'I have some questions about my period and how I\'m feeling.'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPrompt(String label, String message) {
    return InkWell(
      onTap: () {
        _controller.text = message;
        _handleSend();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(20),
          color: AppColors.purple.withValues(alpha: 0.06),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.purple, fontSize: 13),
        ),
      ),
    );
  }

  String? _extractVoiceUrl(String text) {
    if (text.startsWith('[VOICE:') && text.endsWith(']')) {
      return text.substring(7, text.length - 1);
    }
    if (text.startsWith('http://') || text.startsWith('https://')) {
      final lower = text.toLowerCase();
      if (lower.endsWith('.m4a') || lower.endsWith('.mp3') || lower.endsWith('.wav') || lower.endsWith('.aac') || lower.contains('/uploads/')) {
        return text;
      }
    }
    if (text.contains('Voice message: ')) {
      final parts = text.split('Voice message: ');
      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        final possibleUrl = parts[1].trim();
        if (possibleUrl.startsWith('http') || possibleUrl.startsWith('/')) {
          return possibleUrl;
        }
      }
    }
    return null;
  }

  // ─── Message Bubble ───────────────────────────────────────────────────────
  Widget _buildMessageBubble(String text, bool isMe) {
    final voiceUrl = _extractVoiceUrl(text);

    if (voiceUrl != null) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFFFF1F2) : const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            border: Border.all(
              color: isMe ? const Color(0xFFFEE2E2) : const Color(0xFFEDE9FE),
            ),
          ),
          child: VoiceMessageBubble(
            url: voiceUrl,
            isMe: isMe,
            primaryColor: isMe ? const Color(0xFF9F1239) : const Color(0xFF6D28D9),
          ),
        ),
      );
    }

    if (isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: BoxDecoration(
            color: AppColors.purple,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    final parsed = ParsedMessage.parse(text);
    final isSpeakingThis = _isSpeaking && _currentlySpeakingText == text;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parsed.cleanedText,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _toggleSpeak(text),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSpeakingThis
                          ? AppColors.purple.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSpeakingThis ? Icons.stop_rounded : Icons.volume_up_rounded,
                          size: 14,
                          color: isSpeakingThis ? AppColors.purple : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSpeakingThis ? 'Speaking...' : 'Listen',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSpeakingThis ? AppColors.purple : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendVoiceNote(String filePath, int durationSeconds) async {
    setState(() => _isRecordingVoice = false);
    _voiceService.stopSpeaking();
    setState(() {
      _isSpeaking = false;
      _currentlySpeakingText = null;
    });

    try {
      final repo = context.read<ChatRepository>();
      final mediaUrl = await repo.uploadMedia(filePath);
      final voicePayload = '[VOICE:$mediaUrl]';

      final state = context.read<ChatBloc>().state;
      if (state is ChatSuccess && state.sessionId != null) {
        context.read<ChatBloc>().add(SendChatMessage(voicePayload, state.sessionId!));
      } else {
        context.read<ChatBloc>().add(CreateSession(voicePayload));
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice note: $e')),
        );
      }
    }
  }

  Widget _buildActionLink(String path) {
    String label = 'Open';
    IconData icon = Icons.open_in_new_rounded;

    String targetPath = path;
    if (path == '/dashboard/learning-journeys') {
      targetPath = '/learning/journeys';
    } else if (path == '/dashboard/enrolled-programs') {
      targetPath = '/learning/programs';
    }

    final uri = Uri.parse(targetPath);
    final cleanPath = uri.path;
    final tab = uri.queryParameters['tab'];

    if (cleanPath == '/home') {
      if (tab == '1') {
        label = 'Explore Learning Journeys';
        icon = Icons.explore_outlined;
      } else if (tab == '2') {
        label = 'Go to Period Tracker';
        icon = Icons.calendar_today_rounded;
      } else if (tab == '3') {
        label = 'Daily Quests & Mindfulness';
        icon = Icons.auto_awesome_rounded;
      } else if (tab == '4') {
        label = 'PeerLine Support Circles';
        icon = Icons.people_outline_rounded;
      } else {
        label = 'Go to Home';
        icon = Icons.home_rounded;
      }
    } else if (cleanPath == '/onboarding/avatar') {
      label = 'Personalize Look';
      icon = Icons.face_retouching_natural_rounded;
    } else if (cleanPath == '/account') {
      label = 'Account Settings';
      icon = Icons.settings_rounded;
    } else if (cleanPath == '/onboarding/goals') {
      label = 'Check My Goals';
      icon = Icons.star_rounded;
    } else if (cleanPath == '/onboarding/interests') {
      label = 'Update Interests';
      icon = Icons.topic_rounded;
    } else if (cleanPath == '/tracker/log') {
      label = 'Log Mood & Symptoms';
      icon = Icons.edit_note_rounded;
    } else if (cleanPath == '/tracker/calendar') {
      label = 'View Period Calendar';
      icon = Icons.calendar_month_outlined;
    } else if (cleanPath == '/tracker/doctor-summary' || cleanPath == '/tracker/doctor-connect') {
      label = 'Doctor Connect Summary';
      icon = Icons.assignment_rounded;
    } else if (cleanPath == '/learning/programs') {
      label = 'View Learning Programs';
      icon = Icons.school_outlined;
    } else if (cleanPath == '/learning/journeys') {
      label = 'Explore Learning Journeys';
      icon = Icons.explore_outlined;
    } else if (cleanPath == '/quests') {
      label = 'Daily Quests & Mindfulness';
      icon = Icons.auto_awesome_rounded;
    } else if (targetPath == '/expert/list') {
      label = 'Talk to an Expert';
      icon = Icons.support_agent_rounded;
    }

    return InkWell(
      onTap: () => context.push(targetPath),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.purple,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  // ─── Typing Indicator ─────────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BouncingDot(delay: 0),
            SizedBox(width: 5),
            _BouncingDot(delay: 180),
            SizedBox(width: 5),
            _BouncingDot(delay: 360),
          ],
        ),
      ),
    );
  }

  // ─── Input Area ───────────────────────────────────────────────────────────
  Widget _buildInputArea() {
    if (_isRecordingVoice) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: VoiceRecorderBar(
            primaryColor: AppColors.purple,
            onRecordingFinished: _handleSendVoiceNote,
            onCancel: () => setState(() => _isRecordingVoice = false),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Voice Note Record Button (tap to record real voice note)
            GestureDetector(
              onTap: () => setState(() => _isRecordingVoice = true),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AppColors.purple,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isListening
                        ? Colors.redAccent.withValues(alpha: 0.5)
                        : AppColors.purple.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Listening to you...' : 'Message Gigi...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final isSending = state is ChatSuccess && state.isSending;
                final hasText = _controller.text.trim().isNotEmpty;

                return GestureDetector(
                  onTap: isSending
                      ? null
                      : (hasText
                          ? _handleSend
                          : () => setState(() => _isRecordingVoice = true)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isSending
                          ? AppColors.purple.withValues(alpha: 0.6)
                          : AppColors.purple,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: isSending
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Icon(
                            hasText ? Icons.send_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Send Handler ─────────────────────────────────────────────────────────
  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _voiceService.stopSpeaking();
    setState(() {
      _isSpeaking = false;
      _currentlySpeakingText = null;
    });

    final state = context.read<ChatBloc>().state;
    if (state is ChatSuccess && state.sessionId != null) {
      context.read<ChatBloc>().add(SendChatMessage(text, state.sessionId!));
    } else {
      context.read<ChatBloc>().add(CreateSession(text));
    }
    _controller.clear();
  }

  ParsedMessage _parseGigiMessage(String text) {
    return ParsedMessage.parse(text);
  }

  void _handleOptionTap(String value) {
    if (value.startsWith('/')) {
      String targetPath = value;
      if (value == '/dashboard/learning-journeys') {
        targetPath = '/learning/journeys';
      } else if (value == '/dashboard/enrolled-programs') {
        targetPath = '/learning/programs';
      }
      context.push(targetPath);
    } else {
      final state = context.read<ChatBloc>().state;
      if (state is ChatSuccess && state.sessionId != null) {
        context.read<ChatBloc>().add(SendChatMessage(value, state.sessionId!));
      } else {
        context.read<ChatBloc>().add(CreateSession(value));
      }
    }
  }

  Widget _buildOptionChip(String label, String value) {
    return InkWell(
      onTap: () => _handleOptionTap(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.purple, width: 1.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.purple,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─── Animated Bouncing Dot ────────────────────────────────────────────────────
class _BouncingDot extends StatefulWidget {
  final int delay;
  const _BouncingDot({required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Transform.translate(
        offset: Offset(0, -4 * _anim.value),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.4 + _anim.value * 0.6),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class ChatOption {
  final String label;
  final String value;
  ChatOption(this.label, this.value);
}

class ParsedMessage {
  final String cleanedText;
  final List<ChatOption> options;
  final List<String> links;

  ParsedMessage({
    required this.cleanedText,
    required this.options,
    required this.links,
  });

  static ParsedMessage parse(String text) {
    final optionRegex = RegExp(r'\[\s*option\s*:\s*([^\]]+?)\s*\]');
    final linkRegex = RegExp(r'\[\s*link\s*:\s*([^\]]+?)\s*\]');

    final options = <ChatOption>[];
    final links = <String>[];

    final optionMatches = optionRegex.allMatches(text);
    for (final match in optionMatches) {
      final raw = match.group(1)!.trim();
      final parts = raw.split('|');
      final label = parts[0].trim();
      final value = parts.length > 1 ? parts[1].trim() : label;
      options.add(ChatOption(label, value));
    }

    final linkMatches = linkRegex.allMatches(text);
    for (final match in linkMatches) {
      links.add(match.group(1)!.trim());
    }

    var cleaned = text.replaceAll(optionRegex, '').trim();
    cleaned = cleaned.replaceAll(linkRegex, '').trim();

    return ParsedMessage(
      cleanedText: cleaned,
      options: options,
      links: links,
    );
  }
}
