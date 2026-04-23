import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/services/community_socket_service.dart';
import 'package:infano_care_mobile/models/peerline_session.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:infano_care_mobile/core/router/app_router.dart';
import 'package:dio/dio.dart';

class MentorDashboard extends StatefulWidget {
  final VoidCallback? onSwitchToMentee;
  const MentorDashboard({Key? key, this.onSwitchToMentee}) : super(key: key);

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> with SingleTickerProviderStateMixin {
  bool _isAvailable = false;
  Map<String, dynamic>? _mentorStatus;
  Map<String, dynamic>? _stats;
  List<PeerLineSession> _activeSessions = [];
  bool _isLoading = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _refreshTimer;
  StreamSubscription? _socketSub;
  final Map<String, int> _localUnread = {};
  CommunitySocketService? _socketService;
  final Set<String> _subscribedSessions = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _loadStats();
    _startRefreshTimer();
    // Wire up socket for real-time message notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _socketService = Provider.of<CommunitySocketService>(context, listen: false);
      _socketService?.subscribeToMentorUpdates();
      _socketSub = _socketService?.chatEvents.listen(_onSocketEvent);
    });
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isLoading) {
        _loadStats();
      }
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _socketService?.unsubscribeFromMentorUpdates();
    // Unsubscribe all sessions on dispose
    for (final id in _subscribedSessions) {
      _socketService?.unsubscribeFromSession(id);
    }
    _pulseController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _onSocketEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final type = event['type'];
    final sessionId = event['sessionId']?.toString();
    if (type == 'message' && sessionId != null) {
      setState(() {
        _localUnread[sessionId] = (_localUnread[sessionId] ?? 0) + 1;
      });
    } else if (type == 'session_ended' && sessionId != null) {
      _loadStats();
    } else if (type == 'queue_count_changed') {
      debugPrint('MentorDashboard: Queue changed, refreshing stats...');
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      final results = await Future.wait([
        api.getMentorStats(),
        api.getMentorStatus(),
      ]);
      
      final stats = results[0] as Map<String, dynamic>;
      final status = results[1] as Map<String, dynamic>;
      
      PeerLineSession? activeSession;
      if (status['active_session_id'] != null) {
        try {
          activeSession = await api.getSession(status['active_session_id']);
        } catch (e) {
          debugPrint('Failed to load active session details: $e');
        }
      }

      if (mounted) {
        setState(() {
          _stats = stats;
          _mentorStatus = status;
          _activeSessions = (stats['activeSessions'] as List? ?? [])
              .map((s) => PeerLineSession.fromJson(s as Map<String, dynamic>))
              .toList();
          _isAvailable = status['is_available'] ?? false;
          _isLoading = false;
        });

        // Subscribe to each active session for real-time notifications
        for (final session in _activeSessions) {
          if (!_subscribedSessions.contains(session.id)) {
            _socketService?.subscribeToSession(session.id);
            _subscribedSessions.add(session.id);
          }
          // Clear local unread if backend says 0 (e.g. after opening chat)
          if (session.unreadCount == 0) {
            _localUnread.remove(session.id);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    final originalValue = _isAvailable;
    setState(() => _isAvailable = value);
    
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      await api.updateMentorAvailability(value);
      _loadStats();
    } catch (e) {
      if (mounted) {
        setState(() => _isAvailable = originalValue);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  Future<void> _claimNext() async {
    try {
      setState(() => _isLoading = true);
      final api = Provider.of<CommunityApi>(context, listen: false);
      final session = await api.claimNextSession();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connected with a mentee!')));
        _loadStats();
        context.push('/peerline/chat/${session.id}').then((_) => _loadStats());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String message = 'Failed to claim session';
        
        if (e is DioException) {
          final backendError = e.response?.data?['error'];
          if (backendError != null) {
            if (backendError == 'NO_MATCHING_SESSIONS') {
              message = 'No matching mentees in queue right now.';
            } else if (backendError == 'UNAUTHORIZED_NOT_CERTIFIED') {
              message = 'You are not certified to claim sessions.';
            } else if (backendError == 'MENTOR_NOT_AVAILABLE') {
              message = 'Please toggle "Available" before connecting.';
            } else {
              message = 'Error: $backendError';
            }
          } else {
            message = 'Failed to claim session: ${e.message}';
          }
        } else {
          message = 'Failed to claim session: $e';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: message.contains('No matching') ? Colors.blueGrey : Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Mentor Dashboard',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.purple,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onSwitchToMentee != null)
                  TextButton.icon(
                    onPressed: widget.onSwitchToMentee,
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('I need support too'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.purple,
                      textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAvailabilityToggle(),
            const SizedBox(height: 24),
            if (_isAvailable) ...[
              _buildQueueIndicator(),
              const SizedBox(height: 32),
            ],
            _buildStatsGrid(),
            const SizedBox(height: 32),
            _buildActiveSessionsList(),
            const SizedBox(height: 32),
            _buildHistoryList(),
            const SizedBox(height: 32),
            _buildResourcesSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: _isAvailable 
          ? LinearGradient(
              colors: [AppColors.purple, AppColors.purple.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: [Colors.grey.shade100, Colors.grey.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        boxShadow: [
          if (_isAvailable) BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isAvailable ? Icons.online_prediction_rounded : Icons.pause_circle_rounded,
              color: _isAvailable ? Colors.white : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAvailable ? 'I\'m available' : 'Taking a break',
                  style: GoogleFonts.outfit(
                    color: _isAvailable ? Colors.white : Colors.grey.shade700,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isAvailable ? 'Mentees can see you now' : 'Toggle on to start matching',
                  style: GoogleFonts.outfit(
                    color: _isAvailable ? Colors.white.withOpacity(0.8) : Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isAvailable,
            onChanged: _toggleAvailability,
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueIndicator() {
    final status = _mentorStatus;
    final stats = _stats;
    final queueCount = status?['queue_count'] ?? stats?['queueCount'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Live Queue', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              ScaleTransition(
                scale: queueCount > 0 ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: queueCount > 0 ? AppColors.purple.withOpacity(0.1) : Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$queueCount',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: queueCount > 0 ? AppColors.purple : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              Text(
                queueCount == 0 
                  ? 'No mentees waiting right now'
                  : (queueCount == 1 ? '1 mentee waiting' : '$queueCount mentees waiting'),
                style: GoogleFonts.outfit(
                  color: queueCount > 0 ? AppColors.purple : Colors.grey.shade600, 
                  fontWeight: FontWeight.bold,
                  fontSize: 16
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 240,
                height: 54,
                child: ElevatedButton(
                  onPressed: queueCount > 0 ? _claimNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: queueCount > 0 ? 8 : 0,
                    shadowColor: AppColors.purple.withOpacity(0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (queueCount > 0) 
                        const Icon(Icons.flash_on_rounded, size: 18),
                      if (queueCount > 0)
                        const SizedBox(width: 8),
                      Text(
                        'Connect Now', 
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)
                      ),
                    ],
                  ),
                ),
              ),
              if (queueCount == 0) ...[
                const SizedBox(height: 12),
                Text(
                  'We\'ll notify you when someone needs help',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSessionsList() {
    if (_activeSessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(Icons.forum_outlined, color: Colors.grey.shade300, size: 48),
            const SizedBox(height: 16),
            Text(
              'No active support requests',
              style: GoogleFonts.outfit(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Chats', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ..._activeSessions.map((s) => Column(
          children: [
            _buildSessionItem(s),
            const SizedBox(height: 12),
          ],
        )).toList(),
      ],
    );
  }

  Widget _buildHistoryList() {
    final List history = _stats?['completedSessions'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Session History', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Your conversations stay here after a session — fully private.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Icon(Icons.history_rounded, size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No history yet', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildHistoryItem(history[index]),
          ),
      ],
    );
  }

  Widget _buildHistoryItem(dynamic session) {
    final dateStr = session['createdAt'] ?? session['date'] ?? '';
    final date = dateStr.isNotEmpty ? DateTime.parse(dateStr) : DateTime.now();
    final List topics = session['topicIds'] ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(date),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              if (session['menteeName'] != null)
                Text(
                  'Mentee: ${session['menteeName']}',
                  style: TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              Row(
                children: [
                  Text('${session['menteeRating'] ?? 5}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: topics.map((t) => Chip(
              label: Text(t.toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.purple.withOpacity(0.05),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(PeerLineSession session) {
    final unread = (session.unreadCount) + (_localUnread[session.id] ?? 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: unread > 0 ? AppColors.purple : AppColors.purple.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.forum_rounded, color: AppColors.purple),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text(
                            '$unread',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                      Text(
                        session.menteeName != null ? 'Chat with ${session.menteeName}' : 'Active Support session',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: session.topicIds.map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t.toUpperCase(),
                            style: TextStyle(color: AppColors.purple, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/peerline/chat/${session.id}').then((_) => _loadStats()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      session.status.toUpperCase() == 'MATCHING' ? 'Start Chat' : 'Return to Chat',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Impact', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Sessions this week', _stats?['sessionsThisWeek']?.toString() ?? '0', Icons.auto_graph_rounded),
            _buildStatCard('Average Rating', '${_stats?['avgMenteeRating'] ?? '5.0'} ⭐', Icons.star_rounded),
            _buildStatCard('Total Sessions', _stats?['sessionsTotal']?.toString() ?? '0', Icons.history_rounded),
            _buildStatCard('Badge Tier', _stats?['badgeTier'] ?? 'Bronze', Icons.verified_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.purple),
              const SizedBox(width: 4),
              Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }


  Widget _buildResourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resources & Training', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildResourceItem('Mentor Handbook', Icons.menu_book_rounded),
        _buildResourceItem('Refresh training', Icons.refresh_rounded),
        _buildResourceItem('Mentor community', Icons.groups_rounded),
      ],
    );
  }

  Widget _buildResourceItem(String title, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.purple, size: 20),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }
}
