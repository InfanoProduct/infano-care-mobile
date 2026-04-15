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
        status: _isCertifiedMentor && !_viewAsMentee ? null : 'completed',
      );
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
                  onTapMentor: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mentor application coming soon!')),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildRealtimeAvailabilityHeader(),
                const SizedBox(height: 24),
                _buildSessionsList(),
                const Divider(height: 40),
                const Text(
                  'Resources for You',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildResourceItem(
                  icon: Icons.auto_stories_outlined,
                  title: 'Mind Matters series',
                  subtitle: 'Not ready to chat? Browse our Learning Journey',
                  onTap: () => context.push('/learning'),
                ),
                _buildResourceItem(
                  icon: Icons.emergency_outlined,
                  title: 'Crisis Support',
                  subtitle: 'Available 24/7 if you need urgent help',
                  onTap: () => context.push('/crisis'),
                  isCrisis: true,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
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
                  style: TextStyle(
                    color: count > 0 ? const Color(0xFF008080) : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResourceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isCrisis = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCrisis ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isCrisis ? Colors.red : Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: const Icon(Icons.chevron_right, size: 20),
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
        final activeSessions = sessions.where((s) => 
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
            if (activeSessions.isNotEmpty) ...[
              Text(
                'Active Session',
                style: GoogleFonts.outfit(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: AppColors.purple
                ),
              ),
              const SizedBox(height: 12),
              ...activeSessions.map((s) => _ActiveSessionCard(session: s)).toList(),
              const SizedBox(height: 32),
            ],
            
            Text(
              'Your Recent Sessions',
              style: GoogleFonts.outfit(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your conversations stay here after a session — fully private.',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMedium),
            ),
            const SizedBox(height: 16),
            
            if (pastSessions.isEmpty && activeSessions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history_rounded, color: Colors.grey.shade300, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'No past sessions yet.',
                      style: GoogleFonts.outfit(
                        color: Colors.grey.shade500, 
                        fontSize: 14, 
                        fontStyle: FontStyle.italic
                      ),
                    ),
                  ],
                ),
              )
            else
              ...pastSessions.map((s) => _SessionListItem(session: s)).toList(),
          ],
        );
      },
    );
  }
}

class _SessionListItem extends StatelessWidget {
  final PeerLineSession session;

  const _SessionListItem({Key? key, required this.session}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return GestureDetector(
      onTap: () {
        if (session.status == 'ACTIVE' || session.status == 'active') {
          context.push('/peerline/chat/${session.id}');
        }
      },
      child: Container(
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
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getStatusColor(session.status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(session.status),
                color: _getStatusColor(session.status),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.mentorName ?? (session.status == 'MATCHING' ? 'Finding Mentor...' : 'Connected'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (session.topicIds.isNotEmpty && (session.status == 'ACTIVE' || session.status == 'active'))
                    Wrap(
                      spacing: 4,
                      children: session.topicIds.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      )).toList(),
                    )
                  else
                    Text(
                      dateFormat.format(session.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
            if (session.menteeRating != null) ...[
              Row(
                children: [
                  Text(session.menteeRating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Icon(Icons.star, color: Colors.orange, size: 14),
                ],
              ),
              const SizedBox(width: 12),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(session.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                session.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(session.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
      case 'matching':
      case 'queued':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.chat;
      case 'pending':
      case 'matching':
      case 'queued':
        return Icons.hourglass_empty;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.history;
    }
  }
}

class _ActiveSessionCard extends StatelessWidget {
  final PeerLineSession session;

  const _ActiveSessionCard({Key? key, required this.session}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isMatching = session.status.toLowerCase() == 'matching' || session.status.toLowerCase() == 'queued';
    
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.purple.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMatching ? Icons.search_rounded : Icons.chat_bubble_rounded,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMatching ? 'Finding your mentor...' : 'Connected with ${session.mentorName ?? 'Peer Mentor'}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      isMatching ? 'You are in the queue' : 'Your session is active now',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (isMatching) {
                  context.push('/peerline/request');
                } else {
                  context.push('/peerline/chat/${session.id}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                isMatching ? 'View Status' : 'Enter Chat Room',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
