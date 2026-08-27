import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _isCrisisDismissed = false;
  bool _isInactivityDismissed = false;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isCrisisDismissed = false;
      _isInactivityDismissed = false;
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
    final weeklySummary = _report!['weeklySummary'] as Map<String, dynamic>? ?? {};
    final recentCrisisAlert = _report!['recentCrisisAlert'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 0. Urgent Safety Alert (if distress recorded)
        if (recentCrisisAlert != null && !_isCrisisDismissed) ...[
          _buildCrisisAlertBanner(recentCrisisAlert),
          const SizedBox(height: 12),
        ],

        // 1. Inactivity Alert Banner (if inactive >= 2 days)
        if (isInactiveWarning && !_isInactivityDismissed) ...[
          _buildInactivityWarningCard(daysInactive),
          const SizedBox(height: 12),
        ],

        // 2. Profile & Wellness Card
        _buildHeroScoreCard(wellnessScore, statusText, isInactiveWarning),
        const SizedBox(height: 16),

        // 3. 🌟 Attractive Executive Summary Report Card
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
    return Dismissible(
      key: const ValueKey('crisis_alert_banner'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        setState(() {
          _isCrisisDismissed = true;
        });
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withValues(alpha: 0.08),
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
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Urgent Safety Alert 🚨',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isCrisisDismissed = true;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
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
      ),
    );
  }

  Widget _buildInactivityWarningCard(dynamic daysInactive) {
    return Dismissible(
      key: const ValueKey('inactivity_warning_banner'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        setState(() {
          _isInactivityDismissed = true;
        });
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.orange.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Needs Check-in (Inactive for $daysInactive days)',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: const Color(0xFF9A3412),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isInactivityDismissed = true;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                      ),
                    ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.purple.withValues(alpha: 0.15),
                  backgroundImage: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                      ? NetworkImage(widget.avatarUrl!)
                      : null,
                  child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                      ? Text(
                          widget.daughterName.isNotEmpty ? widget.daughterName[0].toUpperCase() : 'D',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: AppColors.purple,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.daughterName,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: const Color(0xFF1E1B4B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isInactive ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isInactive ? 'Inactive recently' : statusText,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isInactive ? const Color(0xFFD97706) : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Big Wellness Score Ring / Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '$score%',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      scoreLabel,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sub-bar with quick highlights
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeroSubMetric('Cycle Regularity', 'Normal'),
                _buildHeroMetricDivider(),
                _buildHeroSubMetric('Journey XP', '${_report?['journeyData']?['totalXpEarned'] ?? 0}'),
                _buildHeroMetricDivider(),
                _buildHeroSubMetric('Weekly Active', '${_report?['weeklySummary']?['activeDaysThisWeek'] ?? 0}/7 d'),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
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
}
