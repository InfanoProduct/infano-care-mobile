import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';

class DaughterReportScreen extends StatefulWidget {
  const DaughterReportScreen({
    super.key,
    required this.teenId,
    required this.daughterName,
    this.avatarUrl,
  });

  final String teenId;
  final String daughterName;
  final String? avatarUrl;

  @override
  State<DaughterReportScreen> createState() => _DaughterReportScreenState();
}

class _DaughterReportScreenState extends State<DaughterReportScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService.instance.dio.get(
        '/parent/daughter/${widget.teenId}/report',
      );
      if (mounted) {
        setState(() {
          _report = res.data as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load daughter activity and period report. Please check your connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.purple.withValues(alpha: 0.15),
              backgroundImage: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                  ? Text(
                      widget.daughterName.isNotEmpty ? widget.daughterName[0].toUpperCase() : 'D',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.purple,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${widget.daughterName}\'s Report',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.purple, size: 22),
            tooltip: 'Refresh Report',
            onPressed: _fetchReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            )
          : _error != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _fetchReport,
                  color: AppColors.purple,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                    child: _buildReportContent(),
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 50),
            const SizedBox(height: 14),
            Text(
              _error ?? 'Failed to load report',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchReport,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    if (_report == null) return const SizedBox.shrink();

    final activityStatus = _report!['activityStatus'] as Map<String, dynamic>? ?? {};
    final isInactiveWarning = activityStatus['isInactiveWarning'] == true;
    final statusText = activityStatus['statusText']?.toString() ?? 'Active';
    final daysInactive = activityStatus['daysInactive'] ?? 0;

    final todayActivity = _report!['todayActivity'] as Map<String, dynamic>? ?? {};
    final wellnessScore = (_report!['wellnessScore'] as num?)?.toInt() ?? 75;
    final cycleData = _report!['cycleData'] as Map<String, dynamic>? ?? {};
    final journeyData = _report!['journeyData'] as Map<String, dynamic>? ?? {};
    final programData = _report!['programData'] as Map<String, dynamic>? ?? {};
    final moodData = _report!['moodData'] as Map<String, dynamic>? ?? {};
    final reflections = _report!['reflections'] as List<dynamic>? ?? [];
    final weeklySummary = _report!['weeklySummary'] as Map<String, dynamic>? ?? {};
    final recentCrisisAlert = _report!['recentCrisisAlert'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 0. Urgent Safety Alert (if distress recorded)
        if (recentCrisisAlert != null) ...[
          _buildCrisisAlertBanner(recentCrisisAlert),
          const SizedBox(height: 12),
        ],

        // 1. Inactivity Alert Banner (if inactive >= 2 days)
        if (isInactiveWarning) ...[
          _buildInactivityWarningCard(daysInactive),
          const SizedBox(height: 12),
        ],

        // 2. White Profile & Wellness Card
        _buildHeroScoreCard(wellnessScore, statusText, isInactiveWarning),
        const SizedBox(height: 12),

        // 3. Today's Live Activity Checklist (White Card)
        _buildTodayActivityCard(todayActivity),
        const SizedBox(height: 12),

        // 4. Menstrual & Period Tracking (White Card)
        _buildMenstrualCard(cycleData),
        const SizedBox(height: 12),

        // 5. Learning Journey & Quests (White Card)
        _buildLearningJourneyCard(journeyData),
        const SizedBox(height: 12),

        // 6. Enrolled Programs & Sessions (White Card)
        _buildProgramsCard(programData),
        const SizedBox(height: 12),

        // 7. Mood & Emotional Trends (White Card with Real Progress Bars & Timeline)
        _buildMoodCard(moodData),
        const SizedBox(height: 12),

        // 8. Recent Journal & Ask Gigi Reflections (White Card)
        if (reflections.isNotEmpty) ...[
          _buildReflectionsCard(reflections),
          const SizedBox(height: 12),
        ],

        // 9. 🌟 Attractive Light Pastel Summary Report Card (No Overflow)
        _buildExecutiveAllInOneSummaryCard(
          summary: weeklySummary,
          cycleData: cycleData,
          journeyData: journeyData,
          todayActivity: todayActivity,
          wellnessScore: wellnessScore,
          daysInactive: daysInactive,
        ),
      ],
    );
  }

  Widget _buildCrisisAlertBanner(Map<String, dynamic> alert) {
    final body = alert['body']?.toString() ?? 'Safety distress detected recently.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF87171), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Urgent Safety Alert 🚨',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    color: const Color(0xFFB91C1C),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactivityWarningCard(dynamic daysInactive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFEA580C), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Needs Check-in (Inactive for $daysInactive days)',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: const Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.daughterName} hasn\'t logged cycle symptoms or learning activity for $daysInactive days. A gentle conversation or reminder can help her re-engage.',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    color: const Color(0xFFC2410C),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroScoreCard(int score, String statusText, bool isInactive) {
    const accentColor = Color(0xFF644D95);
    final scoreColor = score >= 80 ? const Color(0xFF10B981) : (score >= 60 ? accentColor : const Color(0xFFF59E0B));
    final scoreLabel = score >= 80 ? 'Thriving' : (score >= 60 ? 'Balanced' : 'Needs Support');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(widget.avatarUrl!),
                        )
                      : Text(
                          widget.daughterName.isNotEmpty ? widget.daughterName[0].toUpperCase() : 'D',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: accentColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.daughterName,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1E1B4B),
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isInactive ? const Color(0xFFFFF7ED) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isInactive ? const Color(0xFFFDBA74) : const Color(0xFFA7F3D0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isInactive ? Icons.access_time_filled : Icons.check_circle_rounded,
                            size: 11,
                            color: isInactive ? const Color(0xFFEA580C) : const Color(0xFF059669),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                              color: isInactive ? const Color(0xFFC2410C) : const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Score badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEDE9FE)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '$score%',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      scoreLabel,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Sub score indicators
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE9FE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeroSubMetric('Learning', '📚 High'),
                _buildHeroMetricDivider(),
                _buildHeroSubMetric('Tracking', '🌸 Active'),
                _buildHeroMetricDivider(),
                _buildHeroSubMetric('Guidance', '✨ Enrolled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSubMetric(String title, String val) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: GoogleFonts.nunito(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E1B4B),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroMetricDivider() {
    return Container(
      width: 1,
      height: 20,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildTodayActivityCard(Map<String, dynamic> todayActivity) {
    const accentColor = Color(0xFF10B981); // Emerald Green (Self-Care & Daily Vibes Circle)
    final loggedTracker = todayActivity['loggedTrackerToday'] == true;
    final completedLearning = todayActivity['completedLearningToday'] == true;
    final checkinDone = todayActivity['checkinCompletedToday'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('⚡', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Activity & Check-ins',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: const Color(0xFF1E1B4B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live daily engagement status',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTodayCheckinBadge(
                  'Cycle Log',
                  loggedTracker ? 'Logged ✅' : 'Pending ⏳',
                  loggedTracker,
                  Icons.favorite_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTodayCheckinBadge(
                  'Learning',
                  completedLearning ? 'Completed 🎯' : 'Pending ⏳',
                  completedLearning,
                  Icons.school_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTodayCheckinBadge(
                  'Check-in',
                  checkinDone ? 'Done ✨' : 'Pending ⏳',
                  checkinDone,
                  Icons.chat_bubble_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCheckinBadge(String title, String status, bool isDone, IconData icon) {
    final bg = isDone ? Colors.white : Colors.white.withValues(alpha: 0.85);
    final border = isDone ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0);
    final text = isDone ? const Color(0xFF047857) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: text),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: GoogleFonts.nunito(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMenstrualCard(Map<String, dynamic> cycleData) {
    const accentColor = Color(0xFFDB337D); // Vibrant Rose (Period Power Circle)
    final phase = (cycleData['currentPhase']?.toString() ?? 'Waiting').toUpperCase();
    final cycleDay = cycleData['currentCycleDay'];
    final streak = cycleData['currentLogStreak'] ?? 0;
    final daysInactive = cycleData['daysInactive'] ?? 0;
    final daysUntilNextPeriod = cycleData['daysUntilNextPeriod'];
    final isPeriodLate = cycleData['isPeriodLate'] == true;
    final daysLate = (cycleData['daysLate'] as num?)?.toInt() ?? 0;
    final avgCycleLength = cycleData['avgCycleLength'] ?? 28;
    final avgPeriodDuration = cycleData['avgPeriodDuration'] ?? 5;
    final aiCycleInsight = cycleData['aiCycleInsight']?.toString() ?? '';
    final lastPeriodStart = cycleData['lastPeriodStart'];
    final predictedNextStart = cycleData['predictedNextStart'];
    final recentLogs = cycleData['recentLogs'] as List<dynamic>? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🩸', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menstrual & Period Tracking',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: const Color(0xFF1E1B4B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cycle status & AI predictions',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF9D174D),
                      ),
                    ),
                  ],
                ),
              ),
              if (streak > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFBCFE8)),
                  ),
                  child: Text(
                    '🔥 $streak d',
                    style: GoogleFonts.nunito(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFBE185D),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              _buildInactivityChip(daysInactive, 'Tracker'),
            ],
          ),
          const SizedBox(height: 14),

          // LATE PERIOD ALERT (If period is overdue)
          if (isPeriodLate && daysLate > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Period is $daysLate ${daysLate == 1 ? 'Day' : 'Days'} Late',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          predictedNextStart != null
                              ? 'Was expected on ${DateFormat('d MMM yyyy').format(DateTime.parse(predictedNextStart))}. Teenage cycle delays are common due to stress, growth, or tiredness. Ask gently if she has logged.'
                              : 'Period is past expected cycle duration (~$avgCycleLength days). Remind her to log when started.',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: const Color(0xFFB91C1C),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // NOT LOGGED IN PERIOD TRACKER WARNING (If inactive in tracker >= 2 days)
          if (daysInactive >= 2) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_calendar_rounded, color: Color(0xFFD97706), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No period tracker logs for $daysInactive days',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Period Prediction & Countdown Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPeriodLate ? const Color(0xFFFED7AA) : const Color(0xFFFBCFE8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.water_drop_rounded,
                  color: isPeriodLate ? const Color(0xFFEA580C) : const Color(0xFFE11D48),
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPeriodLate
                            ? 'Period Overdue (~$daysLate Days)'
                            : (daysUntilNextPeriod != null
                                ? (daysUntilNextPeriod <= 0 ? 'Period Window Active' : 'Period Expected in ~$daysUntilNextPeriod Days')
                                : 'Cycle Tracking Active'),
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: isPeriodLate ? const Color(0xFFC2410C) : const Color(0xFF9F1239),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastPeriodStart != null
                            ? 'Last Period: ${DateFormat('d MMM yyyy').format(DateTime.parse(lastPeriodStart))} (~$avgPeriodDuration days duration)'
                            : 'Regular Cycle: ~$avgCycleLength days average',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: isPeriodLate ? const Color(0xFF9A3412) : const Color(0xFFBE123C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Phase & Cycle Day Indicators
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  'Current Phase',
                  isPeriodLate ? 'LATE / OVERDUE' : phase,
                  icon: Icons.bubble_chart_rounded,
                  color: isPeriodLate ? const Color(0xFFEF4444) : const Color(0xFFEC4899),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoTile(
                  'Cycle Day',
                  cycleDay != null ? 'Day $cycleDay' : 'Day 12 (~$avgCycleLength d)',
                  icon: Icons.calendar_month_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // AI Menstrual Guidance for Parent
          if (aiCycleInsight.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF5D0FE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFC026D3), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Parent Cycle Guidance',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                            color: const Color(0xFF86198F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          aiCycleInsight,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF701A75),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Recent Logs & Symptoms
          if (recentLogs.isNotEmpty) ...[
            Text(
              'Recent Cycle Logs & Symptoms',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF831843),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: recentLogs.take(4).map((log) {
                final dateStr = log['date'] != null
                    ? DateFormat('E, d MMM').format(DateTime.parse(log['date']))
                    : 'Recent';
                final mood = log['moodPrimary'] ?? 'Normal';
                final flow = log['flow'];
                final label = flow != null && flow.toString().isNotEmpty ? '$dateStr • $flow flow ($mood)' : '$dateStr • $mood';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFBCFE8), width: 1),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFBE185D),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLearningJourneyCard(Map<String, dynamic> journeyData) {
    const accentColor = Color(0xFF3B82F6); // Sky Blue (Study & Exam Lounge Circle)
    final title = journeyData['activeJourneyTitle'] ?? 'Creative Learning Journey';
    final completedNodes = journeyData['completedNodesCount'] ?? 0;
    final todayNodes = journeyData['todayNodesCount'] ?? 0;
    final xp = journeyData['totalXpEarned'] ?? 0;
    final coins = journeyData['totalCoinsEarned'] ?? 0;
    final daysInactive = journeyData['daysInactive'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('📚', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Journey & Modules',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: const Color(0xFF1E1B4B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Growth quests & interactive modules',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
              _buildInactivityChip(daysInactive, 'Modules'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildBadgePill('⭐ $xp XP', Colors.white, const Color(0xFFB45309)),
              _buildBadgePill('🪙 $coins Coins', Colors.white, const Color(0xFF1D4ED8)),
              _buildBadgePill('🎯 $completedNodes Done', Colors.white, const Color(0xFF047857)),
              if (todayNodes > 0)
                _buildBadgePill('🔥 $todayNodes Done Today', Colors.white, const Color(0xFFC2410C)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgramsCard(Map<String, dynamic> programData) {
    const accentColor = Color(0xFFF59E0B); // Amber / Orange
    final programs = programData['enrolledPrograms'] as List<dynamic>? ?? [];
    final nextSession = programData['nextSession'] as Map<String, dynamic>?;
    final totalCompleted = programData['totalCompletedSessions'] ?? 0;
    final daysInactive = programData['daysInactive'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎓', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enrolled Programs & Sessions',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: const Color(0xFF1E1B4B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live webinars & 1-on-1 expert coaching',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              if (daysInactive != null)
                _buildInactivityChip(daysInactive, 'Sessions'),
            ],
          ),
          const SizedBox(height: 12),
          if (programs.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: programs.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.toString(),
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: const Color(0xFF1E1B4B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            )
          else
            Text(
              'No active program subscriptions at this moment.',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: const Color(0xFF78350F),
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          if (nextSession != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Session: ${DateFormat('EEE, d MMM - hh:mm a').format(DateTime.parse(nextSession['scheduledAt']))}',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                        Text(
                          'With ${nextSession['expertName']}',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (totalCompleted > 0) ...[
            Text(
              'Completed $totalCompleted sessions to date.',
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF047857),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodCard(Map<String, dynamic> moodData) {
    const accentColor = Color(0xFF7C3AED); // Royal Violet (Mindful Teens Hub Circle)
    final moodCounts = moodData['moodCounts'] as Map<String, dynamic>? ?? {};
    final totalMoodLogs = (moodData['totalMoodLogs'] as num?)?.toInt() ?? 0;
    final aiMoodInsight = moodData['aiMoodInsight']?.toString() ?? '';
    final recentTimeline = moodData['recentTimeline'] as List<dynamic>? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🧘', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood & Emotional Trends (30 Days)',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: const Color(0xFF1E1B4B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Emotional wellness logs & timeline',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6D28D9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // AI Emotional Insight
          if (aiMoodInsight.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDD6FE)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aiMoodInsight,
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4C1D95),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Mood Distribution Progress Bars
          if (moodCounts.isNotEmpty) ...[
            Text(
              'Mood Frequency Distribution',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5B21B6),
              ),
            ),
            const SizedBox(height: 8),
            ...moodCounts.entries.map((entry) {
              final count = (entry.value as num).toInt();
              final pct = totalMoodLogs > 0 ? (count / totalMoodLogs) : 0.0;
              final emoji = _getMoodEmoji(entry.key);
              final moodName = '${entry.key[0].toUpperCase()}${entry.key.substring(1)}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEDE9FE)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$emoji $moodName',
                            style: GoogleFonts.nunito(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1B4B),
                            ),
                          ),
                          Text(
                            '$count logs (${(pct * 100).toInt()}%)',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF6B21A8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFF1F5F9),
                          color: _getMoodColor(entry.key),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ] else
            Text(
              'No mood logs recorded yet in the past 30 days.',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: const Color(0xFF6D28D9),
                fontWeight: FontWeight.w600,
              ),
            ),

          // Day-by-Day Timeline Chips
          if (recentTimeline.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Day-by-Day Timeline',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5B21B6),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: recentTimeline.take(6).map((log) {
                final dateStr = log['date'] != null
                    ? DateFormat('E, d MMM').format(DateTime.parse(log['date']))
                    : 'Recent';
                final mood = log['mood'] ?? 'Normal';
                final energy = log['energy'];
                final emoji = _getMoodEmoji(mood.toString());

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Text(
                    '$dateStr • $emoji $mood${energy != null ? ' (⚡$energy)' : ''}',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1B4B),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReflectionsCard(List<dynamic> reflections) {
    const accentColor = Color(0xFF06B6D4); // Teal / Cyan (Creative Vibes)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('📖', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Journal & Gigi Prompts',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: const Color(0xFF1E1B4B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Daughter thoughts & daily reflections',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0E7490),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reflections.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final ref = reflections[idx];
              final prompt = ref['promptText'] ?? 'Journal Prompt';
              final entry = ref['entryText'] ?? '';
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCFFAFE)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        color: const Color(0xFF0891B2),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '"$entry"',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: const Color(0xFF1E1B4B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 🌟 ATTRACTIVE LIGHT PASTEL EXECUTIVE ALL-IN-ONE OVERALL SUMMARY CARD (Zero Overflow)
  Widget _buildExecutiveAllInOneSummaryCard({
    required Map<String, dynamic> summary,
    required Map<String, dynamic> cycleData,
    required Map<String, dynamic> journeyData,
    required Map<String, dynamic> todayActivity,
    required int wellnessScore,
    required dynamic daysInactive,
  }) {
    final grade = summary['weeklyGrade']?.toString() ?? 'Balanced';
    final activeDays = summary['activeDaysThisWeek'] ?? 0;
    final highlights = summary['highlights'] as List<dynamic>? ?? [];
    final parentTip = summary['parentTip']?.toString() ?? 'Offer gentle listening and positive reinforcement.';

    final phase = (cycleData['currentPhase']?.toString() ?? 'Tracking');
    final isPeriodLate = cycleData['isPeriodLate'] == true;
    final daysLate = (cycleData['daysLate'] as num?)?.toInt() ?? 0;
    final daysUntilNext = cycleData['daysUntilNextPeriod'];

    final journeyTitle = journeyData['activeJourneyTitle'] ?? 'Creative Journey';
    final completedNodes = journeyData['completedNodesCount'] ?? 0;
    final totalXp = journeyData['totalXpEarned'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFBEB), // Soft Champagne Warm Ivory
            Color(0xFFFFF1F2), // Soft Rose Petal Blush
            Color(0xFFFAF5FF), // Soft Pearlescent Lilac
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Sparkle Badge & "Balanced" / Grade Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 14),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'EXECUTIVE SUMMARY',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                            letterSpacing: 0.7,
                            color: const Color(0xFFB45309),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Grade Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '🌟 $grade',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 11.5,
                    color: const Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            '${widget.daughterName}\'s 7-Day Performance & Wellness Highlights',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 15.5,
              color: const Color(0xFF1E1B4B),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Active on $activeDays of 7 days this week • Health Score: $wellnessScore%',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF854D0E),
            ),
          ),
          const SizedBox(height: 14),

          // 3-Tile Status Overview Grid (3 Distinct Pastel Micro-Cards)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFDE68A)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPastelSummaryRowItem(
                  '🌸 Menstrual Status',
                  isPeriodLate
                      ? '⚠️ Overdue (~$daysLate d)'
                      : (daysUntilNext != null ? 'In ~$daysUntilNext d ($phase)' : phase),
                  isAlert: isPeriodLate,
                ),
                const Divider(color: Color(0xFFF3F4F6), height: 14),
                _buildPastelSummaryRowItem(
                  '📚 Learning Progress',
                  '$journeyTitle ($completedNodes Nodes, $totalXp XP)',
                ),
                const Divider(color: Color(0xFFF3F4F6), height: 14),
                _buildPastelSummaryRowItem(
                  '⚡ Routine Activity',
                  daysInactive > 1 ? '⚠️ Inactive for $daysInactive d' : 'Active Today ✅',
                  isAlert: daysInactive > 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Bulleted Weekly Highlights
          if (highlights.isNotEmpty) ...[
            Text(
              'Weekly Key Milestones',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: const Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 6),
            ...highlights.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.stars_rounded, size: 15, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      h.toString(),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1B4B),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 10),
          ],

          // Actionable Parenting Advice Box (Warm Honey Gold)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parent Tip for the Week',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        parentTip,
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1B4B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastelSummaryRowItem(String title, String val, {bool isAlert = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            val,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF1E1B4B),
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInactivityChip(dynamic daysInactive, String sectionName) {
    final d = (daysInactive as num?)?.toInt() ?? 0;
    if (d == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Text(
          '🟢 Active today',
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF047857),
          ),
        ),
      );
    } else if (d == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          'Active yesterday',
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: Text(
          '⚠️ Inactive for $d days',
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFC2410C),
          ),
        ),
      );
    }
  }

  Widget _buildInfoTile(String title, String val, {required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  val,
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgePill(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
    );
  }

  Color _getMoodColor(String mood) {
    final m = mood.toLowerCase();
    if (m.contains('happy') || m.contains('great')) return const Color(0xFF10B981);
    if (m.contains('calm') || m.contains('peace')) return const Color(0xFF8B5CF6);
    if (m.contains('energetic') || m.contains('excited')) return const Color(0xFFF59E0B);
    if (m.contains('tired') || m.contains('exhausted')) return const Color(0xFF64748B);
    if (m.contains('sad') || m.contains('down')) return const Color(0xFF3B82F6);
    if (m.contains('anxious') || m.contains('stress')) return const Color(0xFFEC4899);
    if (m.contains('angry') || m.contains('irrit')) return const Color(0xFFEF4444);
    return const Color(0xFF8B5CF6);
  }

  String _getMoodEmoji(String mood) {
    final m = mood.toLowerCase();
    if (m.contains('happy') || m.contains('great')) return '😊';
    if (m.contains('calm') || m.contains('peace')) return '😌';
    if (m.contains('energetic') || m.contains('excited')) return '⚡';
    if (m.contains('tired') || m.contains('exhausted')) return '😴';
    if (m.contains('sad') || m.contains('down')) return '😢';
    if (m.contains('anxious') || m.contains('stress')) return '😟';
    if (m.contains('angry') || m.contains('irrit')) return '😠';
    return '🌸';
  }
}
