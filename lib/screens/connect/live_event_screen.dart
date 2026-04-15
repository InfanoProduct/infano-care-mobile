import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/models/event.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/services/community_socket_service.dart';
import 'dart:async';

class LiveEventScreen extends StatefulWidget {
  final CommunityEvent event;
  const LiveEventScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<LiveEventScreen> createState() => _LiveEventScreenState();
}

class _LiveEventScreenState extends State<LiveEventScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<EventQuestion> _questions = [];
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  bool _isExpertCardExpanded = true;
  int _answeredCount = 0;
  
  late CommunitySocketService _socketService;
  StreamSubscription? _socketSubscription;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _socketService = Provider.of<CommunitySocketService>(context, listen: false);
    _setupSocket();
    _loadInitialQuestions();
    _startTimer();
    _answeredCount = widget.event.questionCount;
  }

  void _setupSocket() {
    _socketService.subscribeToEvent(widget.event.id);
    _socketSubscription = _socketService.liveEvents.listen((event) {
      debugPrint('[LiveEventScreen] Received socket event: ${event['type']}');
      if (event['type'] == 'new_question') {
        final newQ = EventQuestion.fromJson(event['data']);
        setState(() {
          // Prevent duplicates if already added locally
          if (!_questions.any((q) => q.id == newQ.id)) {
            _questions.insert(0, newQ);
            _answeredCount++;
            debugPrint('[LiveEventScreen] Question added from socket: ${newQ.id}');
          }
        });
        _scrollToTop();
      }
    });

    _socketService.liveEventQuestionCount.addListener(_onCountUpdate);
  }

  void _onCountUpdate() {
    setState(() {
      _answeredCount = _socketService.liveEventQuestionCount.value;
    });
  }

  void _startTimer() {
    _elapsed = DateTime.now().difference(widget.event.startTime);
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.event.startTime);
      });
    });
  }

  Future<void> _loadInitialQuestions() async {
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      final questions = await api.getEventQuestions(widget.event.id);
      setState(() {
        _questions = questions.reversed.toList();
      });
    } catch (e) {
      debugPrint('Error loading initial questions: $e');
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _socketService.unsubscribeFromEvent(widget.event.id);
    _socketSubscription?.cancel();
    _socketService.liveEventQuestionCount.removeListener(_onCountUpdate);
    _elapsedTimer?.cancel();
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitQuestion() async {
    final content = _questionController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      final newQuestion = await api.submitEventQuestion(widget.event.id, content, isAnonymous: _isAnonymous);
      
      if (mounted) {
        setState(() {
          // Add locally for immediate feedback
          if (!_questions.any((q) => q.id == newQuestion.id)) {
            _questions.insert(0, newQuestion);
            _answeredCount++;
            debugPrint('[LiveEventScreen] Question added locally. Total: ${_questions.length}');
          }
          _questionController.clear();
        });
        _scrollToTop();
      }
    } catch (e) {
      if (mounted) {
        debugPrint('[LiveEventScreen] Error submitting question: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSubmissionConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.purple, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Question Submitted!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your question has been submitted. The 💜 moderator will review it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Great!'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Live AMA', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 16)),
            Text(
              '${_elapsed.inMinutes.toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')} elapsed',
              style: const TextStyle(fontSize: 10, color: AppColors.textMedium),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildStickyNotification(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _questions.length + 3, // Expert card, header, spacer, and questions
              itemBuilder: (context, index) {
                if (index == 0) return _buildExpertCard();
                if (index == 1) return const SizedBox(height: 24);
                if (index == 2) return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildQAHeader(),
                );
                
                final question = _questions[index - 3];
                return _buildQuestionCard(question);
              },
            ),
          ),
          _buildQuestionInput(),
        ],
      ),
    );
  }

  Widget _buildStickyNotification() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: AppColors.error.withOpacity(0.1),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, color: AppColors.error, size: 8),
          SizedBox(width: 8),
          Text(
            'You are in the live event',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.purple.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpertCardExpanded = !_isExpertCardExpanded),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.purple.withOpacity(0.1),
                  backgroundImage: widget.event.expertPhotoUrl != null ? NetworkImage(widget.event.expertPhotoUrl!) : null,
                  child: widget.event.expertPhotoUrl == null ? const Icon(Icons.person, color: AppColors.purple) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(widget.event.expertName ?? 'Expert', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 14),
                        ],
                      ),
                      Text(widget.event.expertCredentials ?? 'Verified Expert', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    ],
                  ),
                ),
                Icon(_isExpertCardExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
              ],
            ),
          ),
          if (_isExpertCardExpanded) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              widget.event.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              widget.event.description,
              style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQAHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Live Q&A Stream', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$_answeredCount questions answered',
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(EventQuestion q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Part
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Q:', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.purple, fontSize: 15)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.content, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text('- ${q.authorName}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Answer Part
          if (q.answer != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${q.expertName}:',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.purple),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    q.answer!,
                    style: const TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.4),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _questionController,
                        maxLength: 200,
                        decoration: InputDecoration(
                          hintText: 'Ask ${widget.event.expertName?.split(' ').first ?? 'Expert'} anything...',
                          counterText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isSubmitting ? null : _submitQuestion,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _isAnonymous,
                      onChanged: (val) => setState(() => _isAnonymous = val ?? false),
                      activeColor: AppColors.purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Ask Anonymously', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                  const Spacer(),
                  const Text('Moderated Room 💜', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.purple)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
