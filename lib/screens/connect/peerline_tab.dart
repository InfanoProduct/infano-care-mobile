import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/models/peerline_session.dart';
import 'package:infano_care_mobile/widgets/peerline_entry_card.dart';
import 'package:infano_care_mobile/widgets/mentor_dashboard.dart';

import 'package:infano_care_mobile/services/community_socket_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';

class PeerLineTab extends StatefulWidget {
  const PeerLineTab({Key? key}) : super(key: key);

  @override
  State<PeerLineTab> createState() => _PeerLineTabState();
}

class _PeerLineTabState extends State<PeerLineTab> with TickerProviderStateMixin {
  late CommunityApi _api;
  bool _isCertifiedMentor = false;
  bool _isLoadingRole = true;
  bool _viewAsMentee = false;

  Future<MentorAvailability?>? _availabilityFuture;
  Future<List<PeerLineSession>>? _sessionsFuture;
  Future<List<Map<String, dynamic>>>? _mentorsFuture;


  // Animation controllers
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  StreamSubscription? _socketSubscription;
  late TabController _sessionTabController;
  int _sessionTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _api = Provider.of<CommunityApi>(context, listen: false);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entryController.forward();
    _sessionTabController = TabController(length: 2, vsync: this);
    _sessionTabController.addListener(() {
      if (_sessionTabController.indexIsChanging) {
        setState(() => _sessionTabIndex = _sessionTabController.index);
      }
    });
    _checkUserRoleAndRefresh();
  }

  void _setupSocketListener() {
    _socketSubscription?.cancel();
    final socketService = Provider.of<CommunitySocketService>(context, listen: false);
    _socketSubscription = socketService.chatEvents.listen((event) {
      if (event['type'] == 'session_ready' && mounted) {
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('A mentor is ready to chat with you!', style: GoogleFonts.outfit())),
              ],
            ),
            backgroundColor: AppColors.purple,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Go to Chat',
              textColor: Colors.white,
              onPressed: () => context.push('/peerline/chat/${event['sessionId']}'),
            ),
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
    _sessionTabController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRoleAndRefresh() async {
    setState(() => _isLoadingRole = true);
    try {
      debugPrint('PeerLineTab: Checking mentor status...');
      final status = await _api.getMentorStatus();
      debugPrint('PeerLineTab: Status received: $status');
      
      if (mounted) {
        _isCertifiedMentor = status['is_certified'] ?? false;
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
      _availabilityFuture = _api.getPeerLineAvailability().then((avail) {
        if (mounted) {
          final socketService = Provider.of<CommunitySocketService>(context, listen: false);
          socketService.availabilityUpdates.value = avail;
        }
        return avail;
      });
      
      _sessionsFuture = _api.getPeerLineSessions(
        role: _isCertifiedMentor && !_viewAsMentee ? 'mentor' : 'mentee',
        status: null, // Fetch all sessions to show active/matching and completed
      );

      _mentorsFuture = _api.searchMentors([]); // Fetch all certified mentors
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
                PeerLineEntryCard(
                  isAvailable: (socketService.availabilityUpdates.value?.activeMentorsCount ?? 0) > 0,
                  pulseAnimation: _pulseAnimation,
                  onTapSupport: () => context.push('/peerline/request'),
                  onTapMentor: () {}, // Handled internally as removed
                ),
                const SizedBox(height: 16),
                _buildRealtimeAvailabilityHeader(),
                const SizedBox(height: 24),
                _buildTopMentorsSection(),
                const SizedBox(height: 32),
                _buildSessionsList(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
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
                  'Expert Peer Mentors',
                  style: GoogleFonts.outfit(
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
                      style: GoogleFonts.outfit(
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
              onPressed: () => context.push('/peerline/request'),
              child: Text(
                'View All',
                style: GoogleFonts.outfit(
                  color: AppColors.purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 330,
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
                    'No mentors available right now',
                    style: GoogleFonts.outfit(color: AppColors.textMedium),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: mentors.length,
                itemBuilder: (context, index) {
                  final mentor = mentors[index];
                  return _buildMentorCard(mentor);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMentorCard(Map<String, dynamic> mentor) {
    return _TopMentorCard(
      mentor: mentor,
      onRequested: () => _refreshData(),
    );
  }
  Widget _buildMentorSkeleton() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildRealtimeAvailabilityHeader() {
    final socketService = Provider.of<CommunitySocketService>(context);

    
    return RepaintBoundary(
      child: ValueListenableBuilder<MentorAvailability?>(
        valueListenable: socketService.availabilityUpdates,
        builder: (context, liveAvailability, _) {
          final count = liveAvailability?.activeMentorsCount ?? 0;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: count > 0 ? const Color(0xFF008080) : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  final offsetAnimation = animation.drive(Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ));
                  return ClipRect(
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                  );
                },
                child: Text(
                  count > 0 ? '$count mentors available now' : 'Mentors will be back soon',
                  key: ValueKey<int>(count),
                  style: GoogleFonts.outfit(
                    color: count > 0 ? const Color(0xFF008080) : Colors.orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }



  Widget _buildSessionsList() {
    if (_sessionsFuture == null) return const SizedBox.shrink();

    return FutureBuilder<List<PeerLineSession>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
        }
        
        final sessions = snapshot.data ?? [];
        final upcomingSessions = sessions.where((s) => 
          s.status.toLowerCase() == 'active' || 
          s.status.toLowerCase() == 'matching' || 
          s.status.toLowerCase() == 'queued'
        ).toList();
        
        final pastSessions = sessions.where((s) => 
          s.status.toLowerCase() == 'completed' || 
          s.status.toLowerCase() == 'cancelled'
        ).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Sessions',
              style: GoogleFonts.outfit(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your mentor conversations — fully private.',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMedium),
            ),
            const SizedBox(height: 12),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _sessionTabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                labelColor: AppColors.purple,
                unselectedLabelColor: AppColors.textMedium,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 15),
                        const SizedBox(width: 6),
                        const Text('Upcoming'),
                        if (upcomingSessions.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.purple,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${upcomingSessions.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history_rounded, size: 15),
                        const SizedBox(width: 6),
                        const Text('Past'),
                        if (pastSessions.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${pastSessions.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab content — fixed height so it doesn't fight with SingleChildScrollView
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _sessionTabIndex == 0
                ? _buildUpcomingTab(upcomingSessions)
                : _buildPastTab(pastSessions),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingTab(List<PeerLineSession> sessions) {
    if (sessions.isEmpty) {
      return Container(
        key: const ValueKey('upcoming-empty'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today_rounded, color: Colors.grey.shade300, size: 44),
            const SizedBox(height: 14),
            Text(
              'No upcoming sessions',
              style: GoogleFonts.outfit(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Request a session with a peer mentor to get started.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppColors.textMedium, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.push('/peerline/request'),
              icon: const Icon(Icons.add, size: 16),
              label: Text('Find a Mentor', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.purple,
                side: BorderSide(color: AppColors.purple),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      key: const ValueKey('upcoming-list'),
      children: sessions.map((s) => _ActiveSessionCard(session: s)).toList(),
    );
  }

  Widget _buildPastTab(List<PeerLineSession> sessions) {
    if (sessions.isEmpty) {
      return Container(
        key: const ValueKey('past-empty'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(Icons.history_rounded, color: Colors.grey.shade300, size: 44),
            const SizedBox(height: 14),
            Text(
              'No past sessions yet',
              style: GoogleFonts.outfit(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Completed sessions will appear here after you end a chat.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppColors.textMedium, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      );
    }
    return Column(
      key: const ValueKey('past-list'),
      children: sessions.map((s) => _SessionListItem(session: s)).toList(),
    );
  }
}


class _SessionListItem extends StatelessWidget {
  final PeerLineSession session;

  const _SessionListItem({Key? key, required this.session}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final rating = session.menteeRating ?? session.mentorRating;
    final note = session.menteeNote ?? session.mentorNote;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              (session.mentorName ?? 'P').substring(0, 1).toUpperCase(),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.purple, fontSize: 18),
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.mentorName ?? 'Peer Mentor',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rating.toString(),
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade700),
                          ),
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(session.createdAt),
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMedium),
                ),
                if (note != null && note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '"$note"',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textDark.withOpacity(0.7),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusBadge(session.status),
              if (session.status.toLowerCase() == 'active')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextButton(
                    onPressed: () => context.push('/peerline/chat/${session.id}'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppColors.purple,
                    ),
                    child: const Text('Open Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active': color = const Color(0xFF10B981); break;
      case 'completed': color = AppColors.purple; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}


class _ActiveSessionCard extends StatelessWidget {

  final PeerLineSession session;

  const _ActiveSessionCard({Key? key, required this.session}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isMatching = session.status.toLowerCase() == 'matching' || session.status.toLowerCase() == 'queued';
    final bool isDirectRequest = isMatching && session.mentorId != null;
    final bool isAccepted = !isMatching;
    final String mentorName = session.mentorName ?? 'Peer Mentor';

    String titleText;
    String subtitleText;
    String buttonText;
    Color cardBorderColor;
    Color buttonColor;
    Color buttonTextColor;
    IconData leadingIcon;

    if (isDirectRequest) {
      titleText = 'Waiting for $mentorName to accept';
      subtitleText = 'Request has been sent. Once the mentor accepts, you\'ll be able to chat.';
      buttonText = 'Awaiting Response';
      cardBorderColor = AppColors.purple.withOpacity(0.25);
      buttonColor = Colors.grey.shade100;
      buttonTextColor = Colors.grey.shade400;
      leadingIcon = Icons.hourglass_empty;
    } else if (isMatching) {
      titleText = 'Finding your mentor...';
      subtitleText = 'You are in the queue';
      buttonText = 'View Status';
      cardBorderColor = AppColors.purple.withOpacity(0.25);
      buttonColor = AppColors.purple;
      buttonTextColor = Colors.white;
      leadingIcon = Icons.search_rounded;
    } else {
      // ACTIVE — mentor accepted
      titleText = '$mentorName accepted your request!';
      subtitleText = 'Your mentor is ready. Tap below to start chatting.';
      buttonText = 'Initiate Chat';
      cardBorderColor = const Color(0xFF10B981).withOpacity(0.4);
      buttonColor = const Color(0xFF10B981);
      buttonTextColor = Colors.white;
      leadingIcon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: (isAccepted ? const Color(0xFF10B981) : AppColors.purple).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Mentor avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (isAccepted ? const Color(0xFF10B981) : AppColors.purple).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      mentorName.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isAccepted ? const Color(0xFF10B981) : AppColors.purple,
                      ),
                    ),
                    if (isAccepted)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 9),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textMedium,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                leadingIcon,
                color: isAccepted ? const Color(0xFF10B981) : AppColors.purple,
                size: 22,
              ),
            ],
          ),
          if (isAccepted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Mentor accepted · Session is ready',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isDirectRequest ? null : () {
                if (isMatching) {
                  context.push('/peerline/request');
                } else {
                  context.push('/peerline/chat/${session.id}');
                }
              },
              icon: isDirectRequest
                ? const SizedBox.shrink()
                : Icon(isAccepted ? Icons.chat_bubble_rounded : Icons.arrow_forward_rounded, size: 18),
              label: Text(
                buttonText,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: buttonTextColor,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                disabledBackgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: isAccepted ? 2 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopMentorCard extends StatefulWidget {
  final Map<String, dynamic> mentor;
  final VoidCallback onRequested;

  const _TopMentorCard({
    Key? key,
    required this.mentor,
    required this.onRequested,
  }) : super(key: key);

  @override
  State<_TopMentorCard> createState() => _TopMentorCardState();
}

class _TopMentorCardState extends State<_TopMentorCard> {
  bool _isLoading = false;
  bool _isRequested = false;

  Future<void> _handleRequest() async {
    if (_isLoading || _isRequested) return;

    setState(() => _isLoading = true);
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      final profile = widget.mentor['profile'] ?? {};
      final List<String> topicIds = List<String>.from(profile['certifiedTopicIds'] ?? []);
      
      // If no topics, use a fallback or show error
      if (topicIds.isEmpty) {
        throw Exception('This mentor has no certified topics.');
      }

      await api.requestPeerLineSession(
        topicIds: topicIds,
        requestedMentorId: widget.mentor['id'],
      );

      if (mounted) {
        setState(() {
          _isRequested = true;
          _isLoading = false;
        });
        widget.onRequested();
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
    final String name = widget.mentor['name'] ?? widget.mentor['profile']?['displayName'] ?? 'Peer Mentor';
    final String bio = widget.mentor['bio'] ?? widget.mentor['profile']?['bio'] ?? 'Helping girls navigate their journey with empathy and care.';
    final bool isOnline = widget.mentor['isOnline'] == true || widget.mentor['profile']?['isAvailable'] == true;
    final List certifiedTopics = widget.mentor['certifiedTopics'] ?? widget.mentor['topics'] ?? [];
    
    String category = 'Expert Mentor';
    List<String> topics = [];
    if (certifiedTopics.isNotEmpty) {
      if (certifiedTopics.first is Map) {
        category = certifiedTopics.first['category']?['name'] ?? 'Expert Mentor';
        topics = certifiedTopics.map<String>((t) => t['name'].toString()).toList();
      } else {
        topics = certifiedTopics.map<String>((t) => t.toString()).toList();
        // Use the first topic as the primary category
        category = topics.isNotEmpty ? topics.first : 'Expert Mentor';
      }
    }

    final List<Color> pastelColors = [
      const Color(0xFFF5F3FF), // Soft Lavender
      const Color(0xFFF0F9FF), // Soft Sky
      const Color(0xFFECFDF5), // Soft Mint
      const Color(0xFFFFF7ED), // Soft Orange
      const Color(0xFFFFFBEB), // Soft Amber
      const Color(0xFFFDF2F2), // Soft Rose
    ];
    
    final int colorIndex = widget.mentor['id'].toString().hashCode.abs() % pastelColors.length;
    final Color bgColor = pastelColors[colorIndex];
    final Color accentColor = Color.lerp(bgColor, Colors.black, 0.6)!; // Darker version for text

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isRequested ? null : _handleRequest,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'M',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: accentColor,
                            ),
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 19,
                                    color: const Color(0xFF1A1A2E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF9E7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.mentor['rating']?.toString() ?? '4.9',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFFFB800),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '• ${widget.mentor['experienceCount'] ?? '12'}+',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFFB800).withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: accentColor.withOpacity(0.1)),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isOnline ? 'Available to chat' : 'Offline',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Expertise in:',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4A4A6A),
                  ),
                ),
                const SizedBox(height: 10),
                // Using Wrap instead of horizontal ListView to avoid scroll conflicts
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: topics.take(3).map((topic) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withOpacity(0.05)),
                    ),
                    child: Text(
                      topic,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor.withOpacity(0.8),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  bio,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: accentColor.withOpacity(0.7),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isRequested ? null : _handleRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      disabledBackgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
                      foregroundColor: Colors.white,
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
                            color: _isRequested ? Colors.grey : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




