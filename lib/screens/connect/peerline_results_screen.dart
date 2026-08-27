import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../models/peerline_session.dart';
import '../../services/community_api.dart';
import '../../widgets/peer_mentor_detail_sheet.dart';

class PeerLineResultsScreen extends StatefulWidget {
  final List<String> selectedTopics;
  const PeerLineResultsScreen({super.key, required this.selectedTopics});

  @override
  State<PeerLineResultsScreen> createState() => _PeerLineResultsScreenState();
}

class _PeerLineResultsScreenState extends State<PeerLineResultsScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _dataFuture;
  late AnimationController _animationController;
  List<PeerLineSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _loadData();
  }

  void _loadData() {
    final api = Provider.of<CommunityApi>(context, listen: false);
    _dataFuture = Future.wait([
      api.searchMentors(widget.selectedTopics),
      api.getPeerLineSessions(role: 'mentee'),
      api.getPeerLineSessions(role: 'mentor'),
    ]).then((results) {
      final mentors = results[0] as List<Map<String, dynamic>>;
      final menteeSessions = results[1] as List<PeerLineSession>;
      final mentorSessions = results[2] as List<PeerLineSession>;

      final uniqueSessions = <String, PeerLineSession>{};
      for (final s in [...menteeSessions, ...mentorSessions]) {
        uniqueSessions[s.id] = s;
      }
      final sessionList = uniqueSessions.values.toList();
      if (mounted) {
        setState(() {
          _sessions = sessionList;
        });
      }

      return {
        'mentors': mentors,
        'sessions': sessionList,
      };
    });
  }

  void _addSession(PeerLineSession session) {
    if (!mounted) return;
    setState(() {
      _sessions = [session, ..._sessions.where((s) => s.id != session.id)];
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mentors Matched',
          style: GoogleFonts.nunito(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSearchingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final data = snapshot.data ?? {};
          final mentors = (data['mentors'] as List<Map<String, dynamic>>?) ?? [];

          if (mentors.isEmpty) {
            return _buildEmptyState();
          }

          return _buildMentorList(mentors);
        },
      ),
    );
  }

  Widget _buildSearchingState() {
    return Stack(
      children: [
        // Background UX Animation
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: SearchingBackgroundPainter(
                  animationValue: _animationController.value,
                  color: AppColors.purple.withValues(alpha: 0.15),
                ),
              );
            },
          ),
        ),
        
        // Content
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing rings
                  ...List.generate(3, (index) {
                    final delay = index * 0.33;
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        double value = (_animationController.value + delay) % 1.0;
                        return Container(
                          width: 100 + (100 * value),
                          height: 100 + (100 * value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.purple.withValues(alpha: 0.2 * (1 - value)),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  
                  // Center Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.search_rounded,
                        size: 48,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Text(
                'Searching for the right mentors for you',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please wait while we match you with peer mentors who can help.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: AppColors.textMedium,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {
                _loadData();
              }),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          Text(
            'No mentors found',
            style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try selecting different topics or check back in a few minutes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: AppColors.textMedium),
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Change Topics', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorList(List<Map<String, dynamic>> mentors) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: mentors.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peer Mentors',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'Matching your selected topics',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          );
        }
        final mentor = mentors[index - 1];
        return _MentorCardWidget(
          mentor: mentor,
          selectedTopics: widget.selectedTopics,
          sessions: _sessions,
          onSessionUpdated: (s) => _addSession(s),
        );
      },
    );
  }
}

class _MentorCardWidget extends StatefulWidget {
  final Map<String, dynamic> mentor;
  final List<String> selectedTopics;
  final List<PeerLineSession> sessions;
  final Function(PeerLineSession) onSessionUpdated;

  const _MentorCardWidget({
    required this.mentor,
    required this.selectedTopics,
    required this.sessions,
    required this.onSessionUpdated,
  });

  @override
  State<_MentorCardWidget> createState() => _MentorCardWidgetState();
}

class _MentorCardWidgetState extends State<_MentorCardWidget> {
  void _showDetailsBottomSheet(BuildContext context) {
    final activeSession = PeerSessionHelper.findActiveSession(widget.mentor, widget.sessions);
    final pendingSession = PeerSessionHelper.findPendingSession(widget.mentor, widget.sessions);

    PeerMentorDetailSheet.show(
      context: context,
      mentor: widget.mentor,
      sessions: widget.sessions,
      activeSession: activeSession,
      pendingSession: pendingSession,
      onAction: (m) async {
        final existingSession = PeerSessionHelper.findActiveSession(widget.mentor, widget.sessions);
        if (existingSession != null) {
          if (context.mounted) {
            context.push('/peerline/chat/${existingSession.id}');
          }
          return;
        }

        try {
          final api = Provider.of<CommunityApi>(context, listen: false);
          final mentorId = widget.mentor['id'] as String?;
          if (mentorId == null) throw Exception('Invalid mentor');

          final rawTopics = widget.mentor['certifiedTopicIds'] ?? widget.mentor['topics'] ?? [];
          final List<String> topicIds = widget.selectedTopics.isNotEmpty
              ? widget.selectedTopics
              : (rawTopics is List ? rawTopics.map((e) => e.toString()).toList() : []);

          final newSession = await api.requestConnection(
            mentorId: mentorId,
            topicIds: topicIds,
          );

          if (context.mounted) {
            widget.onSessionUpdated(newSession);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chat request sent successfully!'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
            context.push('/peerline/chat/${newSession.id}');
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send request: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = PeerSessionHelper.findActiveSession(widget.mentor, widget.sessions);
    final pendingSession = PeerSessionHelper.findPendingSession(widget.mentor, widget.sessions);

    final bool isOnline = widget.mentor['isOnline'] == true;
    final String name = widget.mentor['name'] ?? widget.mentor['fullName'] ?? 'Peer Mentor';
    final String initial = (widget.mentor['initial'] as String?) ??
        (name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P');
    final String rating = widget.mentor['rating']?.toString() ?? '5.0';
    final List rawTopics = widget.mentor['topics'] ?? [];
    final List<String> topics = rawTopics
        .map((t) => t is Map ? (t['name']?.toString() ?? '') : t.toString())
        .where((t) => t.isNotEmpty)
        .toList();

    final bool hasChat = activeSession != null;
    final bool isPending = pendingSession != null && !hasChat;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Icon(Icons.star, size: 14, color: Colors.amber.shade600),
            const SizedBox(width: 4),
            Text(
              rating,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            topics.isNotEmpty ? topics.take(2).join(', ') : 'Peer Mentor',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPending
                ? Colors.green.shade50
                : (hasChat
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                    : AppColors.purple.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isPending ? 'Requested' : 'View Profile',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isPending
                  ? Colors.green.shade700
                  : (hasChat ? const Color(0xFF7C3AED) : AppColors.purple),
            ),
          ),
        ),
        onTap: () => _showDetailsBottomSheet(context),
      ),
    );
  }
}

class SearchingBackgroundPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  SearchingBackgroundPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    // Draw Grid
    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw scanning line
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, color.withValues(alpha: 0.5), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, (animationValue * size.height) - 50, size.width, 100));
    
    canvas.drawRect(
      Rect.fromLTWH(0, (animationValue * size.height) - 50, size.width, 100),
      scanPaint,
    );

    // Draw particles
    final random = math.Random(42);
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final particleSize = random.nextDouble() * 4 + 1;
      final opacity = (math.sin(animationValue * math.pi * 2 + i) + 1) / 2;
      
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        Paint()..color = color.withValues(alpha: opacity * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SearchingBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
