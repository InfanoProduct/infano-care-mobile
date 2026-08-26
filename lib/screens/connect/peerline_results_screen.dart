import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../services/community_api.dart';

class PeerLineResultsScreen extends StatefulWidget {
  final List<String> selectedTopics;
  const PeerLineResultsScreen({super.key, required this.selectedTopics});

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
          style: GoogleFonts.nunito(
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
                    child: Icon(Icons.search, size: 40, color: AppColors.purple),
                  ),
                ],
              ),
              const SizedBox(height: 60),
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
              const SizedBox(height: 40),
              // Status text
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final dots = (DateTime.now().millisecondsSinceEpoch / 500 % 4).toInt();
                  return Text(
                    'Scanning database${'.' * dots}',
                    style: GoogleFonts.nunito(
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
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold),
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
                  style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                Text(
                  'Matching your selected topics',
                  style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMedium),
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
    required this.mentor,
    required this.selectedTopics,
  });

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

  void _showDetailsBottomSheet(BuildContext context) {
    const Color purpleTheme = Color(0xFF644D95);
    final String name = widget.mentor['name'] ?? 'Peer Mentor';
    final String fullName = widget.mentor['fullName'] ?? (widget.mentor['name'] != null ? '${widget.mentor['name']} Sharma' : 'Peer Mentor');
    final String initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'M';
    final String headline = widget.mentor['headline'] ?? 'Certified Peer Listener & Emotional Health Coach';
    final String rating = widget.mentor['rating']?.toString() ?? '5.0';
    final String reviewsCount = widget.mentor['reviewsCount'] ?? '48 reviews';
    final String sessionsCount = widget.mentor['sessionsCount'] ?? '140+ Mentees';
    final String responseTime = widget.mentor['responseTime'] ?? '< 15 mins';
    final String languages = widget.mentor['languages'] ?? 'English, Hindi';
    final String bio = widget.mentor['bio'] ?? widget.mentor['fullBio'] ?? 'Hi there! I am a certified peer mentor passionate about creating a safe, judgment-free space for young girls. Whether you are navigating school stress, emotional highs & lows, or just need a warm listening ear, I am here to help you feel supported and heard.';
    final List<String> badges = widget.mentor['badges'] != null
        ? List<String>.from(widget.mentor['badges'])
        : (widget.mentor['topics'] != null
            ? (widget.mentor['topics'] as List).map((e) => e.toString()).toList()
            : ['Mental & Emotional Health', 'Identity & Personal Growth']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> requestFromSheet() async {
              setSheetState(() => _isLoading = true);
              setState(() => _isLoading = true);

              try {
                final api = Provider.of<CommunityApi>(context, listen: false);
                final mentorId = widget.mentor['id'] as String?;
                if (mentorId == null) throw Exception('Invalid mentor');

                await api.requestConnection(
                  mentorId: mentorId,
                  topicIds: widget.selectedTopics,
                );

                if (mounted) {
                  setState(() {
                    _isRequested = true;
                    _isLoading = false;
                  });
                  setSheetState(() {
                    _isRequested = true;
                    _isLoading = false;
                  });
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  setSheetState(() => _isLoading = false);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send request: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            }

            return Container(
              margin: const EdgeInsets.only(top: 80),
              decoration: BoxDecoration(
                color: const Color(0xFFF7EFF5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border.all(
                  color: const Color(0xFFB48BA6).withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB48BA6).withValues(alpha: 0.25),
                    blurRadius: 32,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 34),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Handle Bar
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB48BA6).withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Avatar & Verified Mentor Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: purpleTheme.withValues(alpha: 0.25),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: purpleTheme.withValues(alpha: 0.12),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: GoogleFonts.nunito(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: purpleTheme,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
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
                                    Flexible(
                                      child: Text(
                                        fullName,
                                        style: GoogleFonts.nunito(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF1E1B4B),
                                          letterSpacing: -0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 18,
                                      color: Color(0xFF059669),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  headline,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: Color(0xFFF59E0B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$rating ($reviewsCount)',
                                            style: GoogleFonts.nunito(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFFB45309),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        sessionsCount,
                                        style: GoogleFonts.nunito(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF047857),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Color(0xFFE2D4DE), thickness: 1.5),
                      const SizedBox(height: 14),

                      // Specialties & Topics Section
                      Text(
                        'SPECIALTIES & TOPICS',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF7A61AC),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: badges.map((badgeText) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: purpleTheme.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: purpleTheme,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // About Mentor Section
                      Text(
                        'ABOUT MENTOR',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF7A61AC),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bio,
                        style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Metadata Tags (Response Time & Languages)
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                size: 16,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Responds in $responseTime',
                                style: GoogleFonts.nunito(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.translate_rounded,
                                size: 15,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                languages,
                                style: GoogleFonts.nunito(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Request Sent note if requested
                      if (_isRequested) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: purpleTheme.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: purpleTheme.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.hourglass_empty_rounded, size: 20, color: purpleTheme),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Request has been sent to $name. You will be notified once connected.',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF334155),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // CTA Button
                      GestureDetector(
                        onTap: (!_isRequested && !_isLoading) ? requestFromSheet : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isRequested
                                  ? const [Color(0xFF059669), Color(0xFF047857)]
                                  : const [Color(0xFF7A61AC), purpleTheme],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (_isRequested ? const Color(0xFF059669) : purpleTheme)
                                    .withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isRequested ? Icons.check_circle_rounded : Icons.mark_email_unread_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isRequested ? 'Request Sent' : 'Send Peer Chat Request',
                                      style: GoogleFonts.nunito(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline = widget.mentor['isOnline'] == true;
    final String name = widget.mentor['name'] ?? 'Peer Mentor';
    final List topics = widget.mentor['topics'] ?? [];
    
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
                  name.substring(0, 1).toUpperCase(),
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
              '4.9',
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
            color: _isRequested ? Colors.green.shade50 : AppColors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _isRequested ? 'Requested' : 'View Profile',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _isRequested ? Colors.green.shade700 : AppColors.purple,
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

