import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import '../../repositories/creative_journey_repository.dart';

class _GigiChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _GigiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AskGigiWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final String episodeId;
  final String nodeId;
  final CreativeJourneyRepository repo;
  final VoidCallback onCompleted;

  const AskGigiWidget({
    super.key,
    required this.content,
    required this.episodeId,
    required this.nodeId,
    required this.repo,
    required this.onCompleted,
  });

  @override
  State<AskGigiWidget> createState() => _AskGigiWidgetState();
}

class _AskGigiWidgetState extends State<AskGigiWidget> {
  final TextEditingController _textController = TextEditingController();
  final List<_GigiChatMessage> _messages = [];

  /// Conversation history sent to the AI for multi-turn continuity.
  /// Each entry: { 'sender': 'USER' | 'GIGI', 'content': '...' }
  final List<Map<String, String>> _conversationHistory = [];

  int _questionCount = 0;
  bool _isLoadingAi = false;
  bool _limitReached = false;

  static const int _maxQuestions = 2;

  /// Episode title extracted from node content (e.g. "Skin Stories")
  String? get _episodeTitle {
    final raw = widget.content['episodeTitle'] as String?;
    if (raw != null && raw.isNotEmpty) return raw;
    // Node title from parent (passed via content map as 'nodeTitle')
    return widget.content['nodeTitle'] as String?;
  }

  /// Comma-separated list of topics covered in this episode
  String? get _episodeTopics => widget.content['episodeTopics'] as String?;

  Future<void> _submitQuestion() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoadingAi || _limitReached) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add(_GigiChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoadingAi = true;
    });

    // Save entry to DB
    try {
      await widget.repo.saveGigiEntry(
        episodeId: widget.episodeId,
        nodeId: widget.nodeId,
        entryText: text,
      );
    } catch (_) {}

    // Build history snapshot before this turn (so Gigi has previous context)
    final historySnapshot = List<Map<String, String>>.from(_conversationHistory);

    // Call Gigi AI with episode context and conversation history
    final aiResponse = await widget.repo.askGigiAi(
      text,
      episodeTitle: _episodeTitle,
      episodeTopics: _episodeTopics,
      history: historySnapshot,
    );

    if (!mounted) return;

    // Update conversation history with this exchange for future turns
    _conversationHistory.add({'sender': 'USER', 'content': text});
    _conversationHistory.add({'sender': 'GIGI', 'content': aiResponse});

    setState(() {
      _messages.add(_GigiChatMessage(
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isLoadingAi = false;
      _questionCount++;

      if (_questionCount >= _maxQuestions) {
        _limitReached = true;
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF9C3), Color(0xFFFDE68A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Gigi Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Image.asset(
                      'assets/images/gigi_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text('🌸', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).moveY(
                      begin: 0,
                      end: -3,
                      duration: 1400.ms,
                    ).then().moveY(
                      begin: -3,
                      end: 0,
                      duration: 1400.ms,
                    ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Ask Gigi AI',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_questionCount / $_maxQuestions Asked',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.content['privacyNote'] as String? ?? '🔒 Private & Safe — Ask Gigi anything on your mind.',
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          color: const Color(0xFF92400E).withValues(alpha: 0.8),
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Messages Thread
          if (_messages.isNotEmpty) ...[
            ..._messages.map((msg) => _buildMessageBubble(msg)),
            const SizedBox(height: 12),
          ],

          // AI Loading Indicator
          if (_isLoadingAi) ...[
            _buildAiTypingIndicator(),
            const SizedBox(height: 16),
          ],

          // Input area (shown if questions remaining and not limit reached)
          if (!_limitReached) ...[
            if (_messages.isEmpty) ...[
              Text(
                widget.content['prompt'] as String? ?? 'Got a question about puberty or your body? Type it here to ask Gigi!',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
            ],

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                maxLines: 4,
                minLines: 2,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: widget.content['placeholder'] as String? ?? 'What\'s on your mind? 💭',
                  hintStyle: GoogleFonts.nunito(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoadingAi ? null : _submitQuestion,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Ask Gigi ✨',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_messages.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => setState(() => _limitReached = true),
                    child: Text(
                      'I\'m Done ✨',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            if (_messages.isEmpty) ...[
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: widget.onCompleted,
                  child: Text(
                    'Skip this activity →',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],

          // Limit Reached Wrap-Up Card
          if (_limitReached) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5F3FF), Color(0xFFFDF2F8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('🌸💬', style: TextStyle(fontSize: 40))
                      .animate()
                      .scale(duration: 400.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 12),
                  Text(
                    'Gigi is your trusted friend!',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _episodeTitle != null
                        ? 'You\'ve used your 2 quick questions in the $_episodeTitle episode! For anything else — moods, relationships, school stress — Gigi is always a message away in the Talk to Gigi chat on your home screen. 💬'
                        : 'You\'ve used your 2 quick questions in this episode. Gigi is always here for you! You can chat with Gigi anytime using the Talk to Gigi feature on your home screen.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      color: AppColors.textDark,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Collect XP Button
                  GestureDetector(
                    onTap: widget.onCompleted,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Collect XP ⭐',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Talk to Gigi Home Feature Link
                  GestureDetector(
                    onTap: () {
                      try {
                        context.push('/chat');
                      } catch (_) {
                        widget.onCompleted();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.purple.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.purple, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Open Talk to Gigi 💬',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_GigiChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'You asked:',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                msg.text,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🌸', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  'Gigi says:',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              msg.text,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildAiTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Gigi is thinking... ✨',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }
}
