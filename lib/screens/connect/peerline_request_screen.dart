import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/services/community_socket_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/models/peerline_session.dart';
import 'package:google_fonts/google_fonts.dart';

enum PeerLinePhase {
  topicSelection,
  matching,
  queueCard
}

class PeerLineRequestScreen extends StatefulWidget {
  const PeerLineRequestScreen({Key? key}) : super(key: key);

  @override
  State<PeerLineRequestScreen> createState() => _PeerLineRequestScreenState();
}

class _PeerLineRequestScreenState extends State<PeerLineRequestScreen> {
  PeerLinePhase _currentPhase = PeerLinePhase.topicSelection;
  final List<String> _selectedTopics = [];
  bool _isVerifiedToggleOn = false;
  String? _sessionId;
  int _queuePosition = 0;
  int _estimatedWait = 0;
  bool _notifyMe = true;
  Timer? _matchingTimer;
  CommunitySocketService? _socketService;
  bool _isNavigating = false;
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _socketService = Provider.of<CommunitySocketService>(context, listen: false);
      _socketService?.queueUpdates.addListener(_onQueueUpdate);
    });
  }

  final List<Map<String, String>> _topics = [
    {'id': 'period', 'name': 'Period & cycle questions', 'emoji': '🩸'},
    {'id': 'mood', 'name': 'Mood & emotions', 'emoji': '🌊'},
    {'id': 'anxiety', 'name': 'Anxiety & stress', 'emoji': '💨'},
    {'id': 'body', 'name': 'Body image & confidence', 'emoji': '💪'},
    {'id': 'relations', 'name': 'Relationships & friendships', 'emoji': '🤝'},
    {'id': 'family', 'name': 'Family & cultural pressure', 'emoji': '🏠'},
    {'id': 'school', 'name': 'School & future planning', 'emoji': '📚'},
    {'id': 'other', 'name': 'Something else', 'emoji': '💜'},
  ];

  @override
  void dispose() {
    _matchingTimer?.cancel();
    _socketService?.queueUpdates.removeListener(_onQueueUpdate);
    _socketSubscription?.cancel();
    if (_sessionId != null) {
      _socketService?.unsubscribeFromSession(_sessionId!);
    }
    super.dispose();
  }

  void _onQueueUpdate() {
    final update = _socketService?.queueUpdates.value;
    if (update != null && mounted) {
      setState(() {
        _queuePosition = update['position'] ?? _queuePosition;
        _estimatedWait = update['estimated_wait_minutes'] ?? _estimatedWait;
        
        if (update['status'] == 'ACTIVE' && _sessionId != null) {
          _showReadyNotification();
        }
      });
    }
  }

  void _showReadyNotification() {
    if (_isNavigating || !mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(child: Text('Your mentor is ready to chat!')),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 15),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'CHAT NOW',
          textColor: Colors.white,
          onPressed: _navigateToChat,
        ),
      ),
    );
  }

  void _toggleTopic(String id) {
    setState(() {
      if (_selectedTopics.contains(id)) {
        _selectedTopics.remove(id);
      } else if (_selectedTopics.length < 2) {
        _selectedTopics.add(id);
      }
    });
  }

  void _handleNotSure() {
    setState(() {
      _selectedTopics.clear();
      _selectedTopics.add('other');
    });
  }

  Future<void> _startMatching() async {
    if (_selectedTopics.isEmpty) return;

    setState(() => _currentPhase = PeerLinePhase.matching);
    
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      final session = await api.requestPeerLineSession(
        topicIds: _selectedTopics,
        requestVerified: _isVerifiedToggleOn,
      );
      
      _sessionId = session.id;
      _socketService?.subscribeToSession(_sessionId!);

      // Listen for events to snap straight to chat
      _socketSubscription?.cancel();
      _socketSubscription = _socketService?.chatEvents.listen((event) {
        if (!mounted || _sessionId == null) return;
        if (event['sessionId'] != _sessionId) return;

        if (event['type'] == 'session_ready' || 
           (event['type'] == 'message' && event['senderRole'] == 'mentor')) {
          _showReadyNotification();
        }
      });

      // Simulation of matching duration (2-5 seconds)
      _matchingTimer = Timer(Duration(seconds: 3 + math.Random().nextInt(2)), () async {
        if (!mounted) return;
        
        if (_isNavigating) return;
        
        // Fetch current status to check if matching happened during animation
        final api = Provider.of<CommunityApi>(context, listen: false);
        try {
          final currentSession = await api.getSession(_sessionId!);
          final currentStatus = currentSession.status.toUpperCase();
          
          if (currentStatus == 'ACTIVE') {
            if (mounted) {
              _showReadyNotification();
              setState(() {
                _currentPhase = PeerLinePhase.queueCard;
              });
              _fetchQueueStatus();
            }
          } else {
            if (mounted) {
              setState(() {
                _currentPhase = PeerLinePhase.queueCard;
              });
              _fetchQueueStatus();
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _currentPhase = PeerLinePhase.queueCard;
            });
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _currentPhase = PeerLinePhase.topicSelection);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting match: $e')),
        );
      }
    }
  }

  void _navigateToChat() {
    if (_isNavigating || !mounted || _sessionId == null) return;
    _isNavigating = true;
    _matchingTimer?.cancel();
    context.pushReplacement('/peerline/chat/$_sessionId');
  }

  Future<void> _fetchQueueStatus() async {
    if (_sessionId == null) return;
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      final queueInfo = await api.getQueuePosition(_sessionId!);
      if (mounted) {
        setState(() {
          _queuePosition = queueInfo['position'] ?? 0;
          _estimatedWait = queueInfo['estimated_wait_minutes'] ?? 0;
          
          if (queueInfo['status'] == 'ACTIVE') {
            context.pushReplacement('/peerline/chat/$_sessionId');
          }
        });
      }
    } catch (e) {
      // Handle error quietly or retry
    }
  }

  Future<void> _cancelRequest() async {
    if (_sessionId == null) {
      setState(() => _currentPhase = PeerLinePhase.topicSelection);
      return;
    }

    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      await api.cancelPeerLineSession(_sessionId!);
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentPhase) {
      case PeerLinePhase.topicSelection:
        return _buildTopicSelection();
      case PeerLinePhase.matching:
        return _buildMatchingView();
      case PeerLinePhase.queueCard:
        return _buildQueueCard();
    }
  }

  Widget _buildTopicSelection() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What would you like support with?',
              style: GoogleFonts.outfit(
                fontSize: 24, 
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your selection is anonymous — only your matched mentor sees this',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 32),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final topic = _topics[index];
                final isSelected = _selectedTopics.contains(topic['id']);
                
                return _TopicCard(
                  topic: topic,
                  isSelected: isSelected,
                  onTap: () => _toggleTopic(topic['id']!),
                );
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: _handleNotSure,
                child: Text(
                  "I'm not sure",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.purple,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildVerifiedToggle(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedTopics.isNotEmpty ? _startMatching : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Find my mentor',
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Verified mentor',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _showVerifiedExplanation,
                      child: Icon(Icons.info_outline, size: 16, color: AppColors.purple),
                    ),
                  ],
                ),
                Text(
                  'Connect with our most experienced mentors',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          Switch(
            value: _isVerifiedToggleOn,
            onChanged: (val) => setState(() => _isVerifiedToggleOn = val),
            activeColor: AppColors.purple,
          ),
        ],
      ),
    );
  }

  void _showVerifiedExplanation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verified Mentors',
                style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Text(
                'Verified mentors have completed our full certification program and have successfully facilitated 5+ support sessions.',
                style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textMedium),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchingView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: MatchingAnimation(),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                Text(
                  'Finding your mentor...',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0),
                  child: Text(
                    'Matching you with someone who understands',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('💜', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 24),
                    Text(
                      "You're #$_queuePosition in the queue",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estimated wait: ~$_estimatedWait minutes',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Notify me when a mentor is ready',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Switch(
                          value: _notifyMe,
                          onChanged: (v) => setState(() => _notifyMe = v),
                          activeColor: AppColors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'In the meantime, you can explore...',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildExploreLink('Explore Circles', Icons.groups_outlined, () {
                context.push('/connect/circles');
              }),
              const SizedBox(height: 12),
              _buildExploreLink('Learning Journeys', Icons.auto_awesome_outlined, () {
                context.push('/home/learning');
              }),
              const Spacer(),
              TextButton(
                onPressed: _cancelRequest,
                child: Text(
                  'Cancel request',
                  style: GoogleFonts.outfit(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreLink(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.purple),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Map<String, String> topic;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopicCard({
    required this.topic,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.purple : Colors.grey.withOpacity(0.1),
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.purple.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(topic['emoji']!, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                topic['name']!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.purple : AppColors.textDark,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MatchingAnimation extends StatefulWidget {
  const MatchingAnimation({Key? key}) : super(key: key);

  @override
  State<MatchingAnimation> createState() => _MatchingAnimationState();
}

class _MatchingAnimationState extends State<MatchingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Dot> _dots = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize dots at random positions
    for (int i = 0; i < 20; i++) {
      _dots.add(Dot(
        position: Offset(math.Random().nextDouble(), math.Random().nextDouble()),
        velocity: Offset(
          (math.Random().nextDouble() - 0.5) * 0.001,
          (math.Random().nextDouble() - 0.5) * 0.001,
        ),
        radius: 2 + math.Random().nextDouble() * 3,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update positions
        for (var dot in _dots) {
          dot.position += dot.velocity;
          if (dot.position.dx < 0 || dot.position.dx > 1) dot.velocity = Offset(-dot.velocity.dx, dot.velocity.dy);
          if (dot.position.dy < 0 || dot.position.dy > 1) dot.velocity = Offset(dot.velocity.dx, -dot.velocity.dy);
        }

        return CustomPaint(
          painter: DotConnectionsPainter(_dots, AppColors.purple.withOpacity(0.2)),
        );
      },
    );
  }
}

class Dot {
  Offset position;
  Offset velocity;
  double radius;

  Dot({required this.position, required this.velocity, required this.radius});
}

class DotConnectionsPainter extends CustomPainter {
  final List<Dot> dots;
  final Color baseColor;

  DotConnectionsPainter(this.dots, this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = baseColor;
    final linePaint = Paint()..strokeWidth = 1.0;

    for (int i = 0; i < dots.length; i++) {
      final p1 = Offset(dots[i].position.dx * size.width, dots[i].position.dy * size.height);
      canvas.drawCircle(p1, dots[i].radius, paint);

      for (int j = i + 1; j < dots.length; j++) {
        final p2 = Offset(dots[j].position.dx * size.width, dots[j].position.dy * size.height);
        final distance = (p1 - p2).distance;

        if (distance < 150) {
          linePaint.color = baseColor.withOpacity((1 - distance / 150) * 0.3);
          canvas.drawLine(p1, p2, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
