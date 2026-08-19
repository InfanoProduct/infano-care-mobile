import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/models/peerline_session.dart';
import 'package:infano_care_mobile/models/peerline_topic.dart';
import 'package:infano_care_mobile/widgets/mentor_dashboard.dart';
import 'package:infano_care_mobile/services/community_socket_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class PeerLineTab extends StatefulWidget {
  const PeerLineTab({super.key});

  @override
  State<PeerLineTab> createState() => _PeerLineTabState();
}

class _PeerLineTabState extends State<PeerLineTab> with TickerProviderStateMixin {
  late CommunityApi _api;
  bool _isCertifiedMentor = false;
  bool _isLoadingRole = true;
  bool _viewAsMentee = false;

  Future<List<PeerLineSession>>? _sessionsFuture;
  Future<List<Map<String, dynamic>>>? _mentorsFuture;

  List<PeerLineSession> _allSessions = [];
  List<PeerLineTopic> _topics = [];
  String? _selectedTopicId;

  // Animation controllers
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _api = Provider.of<CommunityApi>(context, listen: false);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entryController.forward();
    _checkUserRoleAndRefresh();
  }

  void _setupSocketListener() {
    _socketSubscription?.cancel();
    final socketService = Provider.of<CommunitySocketService>(context, listen: false);
    _socketSubscription = socketService.chatEvents.listen((event) {
      if (!mounted) return;
      final String type = event['type'] ?? '';

      if (type == 'connection_accepted') {
        _refreshData();
        final connectionId = event['connectionId'] as String?;
        if (connectionId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Your peer mentor accepted your request! 💜', style: GoogleFonts.nunito())),
                ],
              ),
              backgroundColor: AppColors.purple,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Open Chat',
                textColor: Colors.white,
                onPressed: () => context.push('/peerline/chat/$connectionId'),
              ),
            ),
          );
        }
      } else if (type == 'connection_request') {
        _refreshData();
      } else if (type == 'connection_declined') {
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your connection request was not accepted. You can try another mentor.', style: GoogleFonts.nunito()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRoleAndRefresh() async {
    setState(() => _isLoadingRole = true);
    try {
      debugPrint('PeerLineTab: Checking mentor status...');
      final status = await _api.getMentorStatus();
      debugPrint('PeerLineTab: Status received: $status');
      
      // Load available certified topics
      final topics = await _api.getPeerLineTopics();
      
      if (mounted) {
        _isCertifiedMentor = status['is_certified'] ?? false;
        _topics = topics;
        debugPrint('PeerLineTab: isCertifiedMentor = $_isCertifiedMentor');
        _refreshData();
        
        setState(() {
          _isLoadingRole = false;
        });

        _setupSocketListener();
      }
    } catch (e) {
      debugPrint("PeerLineTab: Error checking mentor status: $e");
      if (mounted) {
        _refreshData();
        setState(() => _isLoadingRole = false);
      }
    }
  }

  void _refreshData() {
    if (!mounted) return;
    setState(() {
      _api.getPeerLineAvailability().then((avail) {
        if (mounted) {
          final socketService = Provider.of<CommunitySocketService>(context, listen: false);
          socketService.availabilityUpdates.value = avail;
        }
      });
      
      _sessionsFuture = _api.getPeerLineSessions(
        role: _isCertifiedMentor && !_viewAsMentee ? 'mentor' : 'mentee',
        status: null,
      ).then((sessions) {
        if (mounted) {
          setState(() {
            _allSessions = sessions;
          });
        }
        return sessions;
      });

      final List<String> filterTopics = _selectedTopicId != null ? [_selectedTopicId!] : [];
      _mentorsFuture = _api.searchMentors(filterTopics);
    });
  }

  void _addNewSession(PeerLineSession session) {
    if (!mounted) return;
    setState(() {
      if (!_allSessions.any((s) => s.id == session.id)) {
        _allSessions = [session, ..._allSessions];
      }
      _sessionsFuture = Future.value(_allSessions);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Center(child: CircularProgressIndicator());
    }

    final socketService = Provider.of<CommunitySocketService>(context);

    if (_isCertifiedMentor && !_viewAsMentee) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: MentorDashboard(
                onSwitchToMentee: () => setState(() => _viewAsMentee = true),
              ),
            ),
          ],
        ),
      );
    }

    final isAvailable = (socketService.availabilityUpdates.value?.activeMentorsCount ?? 0) > 0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isCertifiedMentor && _viewAsMentee)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextButton.icon(
                      onPressed: () => setState(() => _viewAsMentee = false),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Back to Mentor Dashboard'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.purple,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                
                // Redesigned Header
                _PeerLineHeaderCard(
                  isAvailable: isAvailable,
                  pulseAnimation: _pulseAnimation,
                  onTapSupport: () => context.push('/peerline/request'),
                ),
                
                const SizedBox(height: 28),
                _buildTopMentorsSection(),
                
                const SizedBox(height: 28),
                _buildSessionsList(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicFilters() {
    if (_topics.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 12, bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _topics.length + 1,
        itemBuilder: (context, index) {
          final bool isAll = index == 0;
          final PeerLineTopic? topic = isAll ? null : _topics[index - 1];
          final bool isSelected = isAll ? _selectedTopicId == null : _selectedTopicId == topic?.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                isAll ? '✨ All Topics' : '${topic!.emoji} ${topic.name}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  _selectedTopicId = isAll ? null : topic?.id;
                  _refreshData();
                });
              },
              selectedColor: AppColors.purple,
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.purple : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopMentorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Peer Mentors',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      'All mentors are certified & verified',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.push('/peerline/request').then((_) => _refreshData()),
              child: Text(
                'View All',
                style: GoogleFonts.nunito(
                  color: AppColors.purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        
        // Dynamic Topic Filter Chips
        _buildTopicFilters(),
        
        SizedBox(
          height: 310,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _mentorsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) => _buildMentorSkeleton(),
                );
              }
              
              final mentors = snapshot.data ?? [];
              if (mentors.isEmpty) {
                return Center(
                  child: Text(
                    'No mentors available for this topic',
                    style: GoogleFonts.nunito(color: AppColors.textMedium),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: mentors.length,
                itemBuilder: (context, index) {
                  final mentor = mentors[index];
                  return _TopMentorCard(
                    mentor: mentor,
                    onRequested: (newSession) => _addNewSession(newSession),
                    sessions: _allSessions,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMentorSkeleton() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  Widget _buildSessionsList() {
    if (_sessionsFuture == null) return const SizedBox.shrink();

    return FutureBuilder<List<PeerLineSession>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator()));
        }

        final sessions = snapshot.data ?? [];
        
        // Active Chats (Accepted conversation is currently underway)
        final activeChats = sessions
            .where((s) => s.status.toLowerCase() == 'active')
            .toList();

        // Pending Request Chats (Finding match, direct request awaiting acceptance)
        final pendingRequests = sessions
            .where((s) =>
                s.status.toLowerCase() == 'matching' ||
                s.status.toLowerCase() == 'queued')
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Pending Section (If any)
            if (pendingRequests.isNotEmpty) ...[
              Text(
                'Pending Requests',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              ...pendingRequests.map((s) => _PendingRequestCard(
                session: s,
                onCancelled: () => _refreshData(),
              )),
              const SizedBox(height: 20),
            ],

            // 2. Active Chats Title & List
            Text(
              'Your Conversations',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chat privately with certified peer mentors.',
              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMedium),
            ),
            const SizedBox(height: 16),

            if (activeChats.isEmpty && pendingRequests.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    Icon(Icons.forum_rounded, color: Colors.grey.shade300, size: 48),
                    const SizedBox(height: 14),
                    Text(
                      'No active conversations yet',
                      style: GoogleFonts.nunito(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Search for a peer mentor above or connect with matching to start a private conversation.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: AppColors.textMedium,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/peerline/request'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        'Find a Mentor',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Active Chats list
              ...activeChats.map((s) => _ActiveChatTile(session: s)),
            ],
          ],
        );
      },
    );
  }
}

// ─── Custom UI Widgets ────────────────────────────────────────────────────────

class _PeerLineHeaderCard extends StatelessWidget {
  final bool isAvailable;
  final Animation<double>? pulseAnimation;
  final VoidCallback onTapSupport;

  const _PeerLineHeaderCard({
    required this.isAvailable,
    required this.onTapSupport,
    this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7C3AED), // Deep Violet
            Color(0xFFEC4899), // Pink
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: pulseAnimation ?? const AlwaysStoppedAnimation(1.0),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isAvailable ? const Color(0xFF10B981) : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAvailable ? 'MENTORS ONLINE' : 'MENTORS OFFLINE',
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Talk to someone\nwho gets it',
                    style: GoogleFonts.nunito(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect with a certified Peer Mentor who has been where you are. Share, get support, and talk privately.',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: onTapSupport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF7C3AED),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'I want support',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.favorite_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveChatTile extends StatelessWidget {
  final PeerLineSession session;
  const _ActiveChatTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final String mentorName = session.mentorName ?? 'Peer Mentor';
    final String initials = mentorName.isNotEmpty ? mentorName.substring(0, 1).toUpperCase() : 'M';
    final hasUnread = session.unreadCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.purple,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              mentorName,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
            Text(
              _formatDate(session.createdAt),
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Conversation Active · Tap to open chat',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.purple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasUnread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${session.unreadCount}',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
        onTap: () => context.push('/peerline/chat/${session.id}'),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat.jm().format(dt);
    }
    return DateFormat('d MMM').format(dt);
  }
}

class _PendingRequestCard extends StatelessWidget {
  final PeerLineSession session;
  final VoidCallback onCancelled;
  const _PendingRequestCard({required this.session, required this.onCancelled});

  @override
  Widget build(BuildContext context) {
    final String mentorName = session.mentorName ?? 'Peer Mentor';
    final bool isMatching = session.status.toLowerCase() == 'matching' || session.status.toLowerCase() == 'queued';
    final bool isDirectRequest = isMatching && session.mentorId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.hourglass_top_rounded, color: AppColors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDirectRequest ? 'Direct Request to $mentorName' : 'Finding a Peer Mentor...',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDirectRequest ? 'Awaiting response from mentor' : 'Waiting in matching queue',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _showCancelConfirmation(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Cancel Request',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Request', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel this connection request?', style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('No', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final api = Provider.of<CommunityApi>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await api.cancelConnection(session.id);
                onCancelled();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to cancel request: $e')),
                  );
                }
              }
            },
            child: Text('Yes, Cancel', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TopMentorCard extends StatefulWidget {
  final Map<String, dynamic> mentor;
  final Function(PeerLineSession) onRequested;
  final List<PeerLineSession> sessions;

  const _TopMentorCard({
    required this.mentor,
    required this.onRequested,
    required this.sessions,
  });

  @override
  State<_TopMentorCard> createState() => _TopMentorCardState();
}

class _TopMentorCardState extends State<_TopMentorCard> {
  bool _isLoading = false;

  Future<void> _handleRequest() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      final profile = widget.mentor['profile'] ?? {};
      final List<String> topicIds = List<String>.from(
        widget.mentor['certifiedTopicIds'] ?? profile['certifiedTopicIds'] ?? []
      );

      final newSession = await api.requestConnection(
        mentorId: widget.mentor['id'],
        topicIds: topicIds,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.onRequested(newSession);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent to ${profile['displayName'] ?? 'Mentor'}'),
            backgroundColor: AppColors.purple,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String mentorId = widget.mentor['id'] ?? '';
    final String name = widget.mentor['name'] ?? widget.mentor['profile']?['displayName'] ?? 'Peer Mentor';
    final String bio = widget.mentor['bio'] ?? widget.mentor['profile']?['bio'] ?? 'Helping girls navigate their journey with empathy and care.';
    final bool isOnline = widget.mentor['isOnline'] == true || widget.mentor['profile']?['isAvailable'] == true;
    final List certifiedTopics = widget.mentor['certifiedTopics'] ?? widget.mentor['topics'] ?? [];
    
    // Check if there is an active session or a pending request with this mentor
    PeerLineSession? activeSession;
    PeerLineSession? pendingSession;
    for (final s in widget.sessions) {
      if (s.mentorId == mentorId) {
        if (s.status.toLowerCase() == 'active') {
          activeSession = s;
        } else if (s.status.toLowerCase() == 'matching' || s.status.toLowerCase() == 'queued') {
          pendingSession = s;
        }
      }
    }

    List<String> topics = [];
    if (certifiedTopics.isNotEmpty) {
      if (certifiedTopics.first is Map) {
        topics = certifiedTopics.map<String>((t) => t['name'].toString()).toList();
      } else {
        topics = certifiedTopics.map<String>((t) => t.toString()).toList();
      }
    }

    final List<Color> pastelColors = [
      const Color(0xFFF5F3FF),
      const Color(0xFFF0F9FF),
      const Color(0xFFECFDF5),
      const Color(0xFFFFF7ED),
      const Color(0xFFFFFBEB),
      const Color(0xFFFDF2F2),
    ];
    
    final int colorIndex = mentorId.hashCode.abs() % pastelColors.length;
    final Color bgColor = pastelColors[colorIndex];
    final Color accentColor = Color.lerp(bgColor, Colors.black, 0.65)!;

    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.02), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: accentColor.withValues(alpha: 0.1), width: 1),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'M',
                              style: GoogleFonts.nunito(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                              ),
                            ),
                          ),
                          if (isOnline)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: const Color(0xFF1A1A2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 15),
                                const SizedBox(width: 3),
                                Text(
                                  widget.mentor['rating']?.toString() ?? '4.9',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFFFB800),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: topics.take(2).map((topic) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        topic,
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accentColor.withValues(alpha: 0.9),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bio,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: accentColor.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: _buildActionButton(activeSession, pendingSession),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(PeerLineSession? activeSession, PeerLineSession? pendingSession) {
    if (activeSession != null) {
      // Already accepted - change to Start Chat
      return ElevatedButton.icon(
        onPressed: () => context.push('/peerline/chat/${activeSession.id}'),
        icon: const Icon(Icons.chat_bubble_rounded, size: 16),
        label: Text(
          'Start Chat',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      );
    } else if (pendingSession != null) {
      // Pending request - change to Request Sent (disabled)
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_empty_rounded, size: 16),
        label: Text(
          'Request Sent',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          disabledBackgroundColor: Colors.grey.shade100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      );
    } else {
      // Normal Request Chat button
      return ElevatedButton(
        onPressed: _handleRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Text(
              'Request Chat',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
      );
    }
  }
}

