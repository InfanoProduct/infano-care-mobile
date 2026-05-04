import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../services/community_api.dart';

class PeerLineResultsScreen extends StatefulWidget {
  final List<String> selectedTopics;
  const PeerLineResultsScreen({Key? key, required this.selectedTopics}) : super(key: key);

  @override
  State<PeerLineResultsScreen> createState() => _PeerLineResultsScreenState();
}

class _PeerLineResultsScreenState extends State<PeerLineResultsScreen> with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _mentorsFuture;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final api = Provider.of<CommunityApi>(context, listen: false);
    _mentorsFuture = Future.delayed(const Duration(seconds: 3), () => api.searchMentors(widget.selectedTopics));
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
          style: GoogleFonts.outfit(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _mentorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSearchingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final mentors = snapshot.data ?? [];

          if (mentors.isEmpty) {
            return _buildEmptyState();
          }

          return _buildMentorList(mentors);
        }
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
                  color: AppColors.purple.withOpacity(0.15),
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
                              color: AppColors.purple.withOpacity(0.2 * (1 - value)),
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
                          color: AppColors.purple.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(Icons.search, size: 40, color: AppColors.purple),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Text(
                'Searching for the right mentors for you',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please wait while we match you with experts who can help.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: AppColors.textMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Status text
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final dots = (DateTime.now().millisecondsSinceEpoch / 500 % 4).toInt();
                  return Text(
                    'Scanning database${'.' * dots}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
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
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {
                final api = Provider.of<CommunityApi>(context, listen: false);
                _mentorsFuture = api.searchMentors(widget.selectedTopics);
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
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try selecting different topics or check back in a few minutes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppColors.textMedium),
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
                  'Expert Mentors',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                Text(
                  'Matching your selected topics',
                  style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textMedium),
                ),
              ],
            ),
          );
        }
        final mentor = mentors[index - 1];
        return _MentorCardWidget(
          mentor: mentor,
          selectedTopics: widget.selectedTopics,
        );
      },
    );
  }
}

class _MentorCardWidget extends StatefulWidget {
  final Map<String, dynamic> mentor;
  final List<String> selectedTopics;

  const _MentorCardWidget({
    Key? key,
    required this.mentor,
    required this.selectedTopics,
  }) : super(key: key);

  @override
  State<_MentorCardWidget> createState() => _MentorCardWidgetState();
}

class _MentorCardWidgetState extends State<_MentorCardWidget> {
  late bool _isRequested;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isRequested = widget.mentor['hasPendingRequest'] == true;
  }

  Future<void> _requestSession() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      final mentorId = widget.mentor['id'] as String?;
      
      await api.requestPeerLineSession(
        topicIds: widget.selectedTopics,
        requestedMentorId: mentorId,
      );
      
      if (mounted) {
        setState(() {
          _isRequested = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline = widget.mentor['isOnline'] == true;
    final String name = widget.mentor['name'] ?? 'Peer Mentor';
    final String bio = widget.mentor['bio'] ?? 'Helping girls navigate their journey with empathy and care.';
    final List topics = widget.mentor['topics'] ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 28,
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
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '4.9',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOnline ? 'Available to chat' : 'Unavailable',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: isOnline ? const Color(0xFF10B981) : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: topics.take(2).map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            t.toString(),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppColors.purple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ),
          if (_isRequested) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.purple.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty, size: 20, color: AppColors.purple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Request has been sent to the mentor, once they accept you will be able to connect and chat with the mentor.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: (isOnline && !_isRequested && !_isLoading) ? _requestSession : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                disabledBackgroundColor: _isRequested ? Colors.green.shade50 : Colors.grey.shade100,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    _isRequested ? 'Request Sent' : 'Request Session',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: _isRequested ? Colors.green.shade700 : (isOnline ? Colors.white : Colors.grey.shade400),
                      fontSize: 16,
                    ),
                  ),
            ),
          ),
        ],
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
        colors: [Colors.transparent, color.withOpacity(0.5), Colors.transparent],
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
        Paint()..color = color.withOpacity(opacity * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SearchingBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
