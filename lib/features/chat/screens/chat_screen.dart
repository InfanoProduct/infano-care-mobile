import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import '../bloc/chat_bloc.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // If scrolled to the top (with a 50px threshold)
    if (_scrollController.hasClients &&
        _scrollController.position.pixels <= _scrollController.position.minScrollExtent + 50) {
      context.read<ChatBloc>().add(LoadMoreHistory());
    }
  }

  @override
  void dispose() {
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          final sessions =
              state is ChatSuccess ? state.sessions : const <dynamic>[];
          return _SessionsDrawer(
            sessions: sessions,
            currentSessionId: state is ChatSuccess ? state.sessionId : null,
            onNewChat: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(StartNewSession());
            },
            onSelectSession: (id) {
              Navigator.pop(context);
              context.read<ChatBloc>().add(SelectSession(id));
            },
          );
        },
      ),
      appBar: AppBar(
        title: Row(
          children: [
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
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Talk to Gigi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Always here for you',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.purple),
        actions: [
          // New chat button — only shown when inside an active session
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state is ChatSuccess && state.sessionId != null) {
                return IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'New conversation',
                  onPressed: () =>
                      context.read<ChatBloc>().add(StartNewSession()),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Expert button — connects to real human experts
          IconButton(
            icon: const Icon(Icons.support_agent_rounded),
            tooltip: 'Talk to an Expert',
            onPressed: () => context.push('/expert/list'),
            color: AppColors.purple,
          ),
          // History button — shows the sessions drawer
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              final hasSessions =
                  state is ChatSuccess && state.sessions.isNotEmpty;
              return IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Past conversations',
                onPressed: hasSessions
                    ? () => _scaffoldKey.currentState?.openEndDrawer()
                    : null,
                color: hasSessions ? AppColors.purple : AppColors.textLight,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is ChatSuccess && state.messages.isNotEmpty) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
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
                              width: 24, height: 24,
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
                            _buildMessageBubble(parsed.cleanedText, isMe),
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
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () =>
                                context.read<ChatBloc>().add(LoadSessions()),
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.purple),
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
          _buildInputArea(),
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
              // Quick-start prompts
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildQuickPrompt('😊 I need to vent',
                      'I need to vent about something that\'s been bothering me.'),
                  _buildQuickPrompt('😰 Feeling stressed',
                      'I\'m feeling really stressed today and don\'t know how to cope.'),
                  _buildQuickPrompt('💬 Just talk',
                      'Hi Gigi! I just want to chat. How are you?'),
                  _buildQuickPrompt('❤️ Period stuff',
                      'I have some questions about my period and how I\'m feeling.'),
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

  // ─── Message Bubble ───────────────────────────────────────────────────────

  Widget _buildMessageBubble(String text, bool isMe) {
    if (isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
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

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints:
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
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
            child: Text(
              parsed.cleanedText,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          if (parsed.links.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: parsed.links.map((link) => _buildActionLink(link)).toList(),
              ),
            ),
          ],
          if (parsed.options.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: parsed.options.map((opt) => _buildOptionButton(opt)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton(ChatOption opt) {
    return InkWell(
      onTap: () => _handleOptionTap(opt.value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(20),
          color: AppColors.purple.withValues(alpha: 0.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              opt.label,
              style: const TextStyle(
                color: AppColors.purple,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: AppColors.purple,
            ),
          ],
        ),
      ),
    );
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
    }

    return InkWell(
      onTap: () => context.push(targetPath),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.2)),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Message Gigi...',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
            const SizedBox(width: 10),
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final isSending = state is ChatSuccess && state.isSending;
                return GestureDetector(
                  onTap: isSending ? null : _handleSend,
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
                                  color: Colors.white, strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
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

  void _sendOption(String optionValue) {
    final state = context.read<ChatBloc>().state;
    if (state is ChatSuccess && state.sessionId != null) {
      context.read<ChatBloc>().add(SendChatMessage(optionValue, state.sessionId!));
    } else {
      context.read<ChatBloc>().add(CreateSession(optionValue));
    }
  }

  Widget _buildOptionChip(String label, String value) {
    return InkWell(
      onTap: () => _handleOptionTap(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─── Sessions Drawer ──────────────────────────────────────────────────────────

class _SessionsDrawer extends StatelessWidget {
  final List<dynamic> sessions;
  final String? currentSessionId;
  final VoidCallback onNewChat;
  final void Function(String sessionId) onSelectSession;

  const _SessionsDrawer({
    required this.sessions,
    required this.currentSessionId,
    required this.onNewChat,
    required this.onSelectSession,
  });

  String _relativeTime(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🌟', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Conversations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            // New Chat Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                onPressed: onNewChat,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('New Conversation'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            // Session list
            if (sessions.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('💬', style: TextStyle(fontSize: 36)),
                      SizedBox(height: 12),
                      Text(
                        'No past conversations',
                        style: TextStyle(
                            color: AppColors.textLight, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const Divider(
                      height: 1, indent: 72, endIndent: 16),
                  itemBuilder: (context, i) {
                    final s = sessions[i];
                    final id = s['id'] as String;
                    final title = (s['title'] as String?) ??
                        'Conversation ${i + 1}';
                    final lastMsgAt =
                        s['lastMsgAt'] as String?;
                    final isActive = id == currentSessionId;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.purple
                              : AppColors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('🌟', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isActive
                              ? AppColors.purple
                              : AppColors.textDark,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: lastMsgAt != null
                          ? Text(
                              _relativeTime(lastMsgAt),
                              style: const TextStyle(
                                  color: AppColors.textLight, fontSize: 12),
                            )
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textLight),
                        onPressed: () {
                          context.read<ChatBloc>().add(DeleteSessionEvent(id));
                        },
                      ),
                      selected: isActive,
                      selectedTileColor:
                          AppColors.purple.withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      onTap: () => onSelectSession(id),
                    );
                  },
                ),
              ),
            // Clear All Button
            if (sessions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Clear All History?'),
                        content: const Text('This will permanently delete all your past conversations with Gigi. This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.textDark)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              context.read<ChatBloc>().add(DeleteAllSessionsEvent());
                            },
                            child: const Text('Delete All', style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_forever, color: AppColors.error, size: 18),
                  label: const Text('Clear All History', style: TextStyle(color: AppColors.error)),
                ),
              ),
          ],
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

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _anim =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay),
        () { if (mounted) _ctrl.repeat(reverse: true); });
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

    // Find options
    final optionMatches = optionRegex.allMatches(text);
    for (final match in optionMatches) {
      final raw = match.group(1)!.trim();
      final parts = raw.split('|');
      final label = parts[0].trim();
      final value = parts.length > 1 ? parts[1].trim() : label;
      options.add(ChatOption(label, value));
    }

    // Find links
    final linkMatches = linkRegex.allMatches(text);
    for (final match in linkMatches) {
      links.add(match.group(1)!.trim());
    }

    // Clean text by removing option patterns and link patterns
    var cleaned = text.replaceAll(optionRegex, '').trim();
    cleaned = cleaned.replaceAll(linkRegex, '').trim();

    return ParsedMessage(
      cleanedText: cleaned,
      options: options,
      links: links,
    );
  }
}

class ParsedMessage {
  final String cleanedText;
  final List<ChatOption> options;
  ParsedMessage(this.cleanedText, this.options);
}

>>>>>>> Stashed changes
