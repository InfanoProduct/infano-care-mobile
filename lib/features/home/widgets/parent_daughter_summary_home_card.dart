import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/features/account/screens/daughter_report_screen.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:provider/provider.dart';

class ParentDaughterSummaryHomeCard extends StatefulWidget {
  const ParentDaughterSummaryHomeCard({super.key});

  @override
  State<ParentDaughterSummaryHomeCard> createState() => _ParentDaughterSummaryHomeCardState();
}

class _ParentDaughterSummaryHomeCardState extends State<ParentDaughterSummaryHomeCard> {
  bool _isLoading = true;
  Map<String, dynamic>? _report;
  String? _teenId;
  String _daughterName = 'Daughter';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchDaughterData();
  }

  Future<void> _fetchDaughterData() async {
    try {
      final linksRes = await ApiService.instance.dio.get('/parent/family-links');
      final links = linksRes.data as List<dynamic>? ?? [];
      
      final activeLink = links.firstWhere(
        (l) => l['status'] == 'LINKED' && (l['teenId'] != null || l['teen'] != null),
        orElse: () => null,
      );

      if (activeLink != null) {
        final teen = activeLink['teen'] as Map<String, dynamic>?;
        final teenId = (activeLink['teenId'] ?? teen?['id'])?.toString();
        final profile = teen?['profile'] as Map<String, dynamic>?;
        final name = profile?['displayName'] ?? teen?['username'] ?? 'Daughter';
        final avatar = profile?['avatarUrl'];

        if (teenId != null) {
          _teenId = teenId;
          _daughterName = name;
          _avatarUrl = avatar;

          final reportRes = await ApiService.instance.dio.get('/parent/daughter/$teenId/report');
          if (mounted) {
            setState(() {
              _report = reportRes.data as Map<String, dynamic>?;
              _isLoading = false;
            });
            return;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _report = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.read<LocalStorageService>();
    final isTeen = storage.role?.toUpperCase() == 'TEEN';
    if (isTeen) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // If no daughter linked or no report available, do not show card on home screen
    if (_report == null || _teenId == null) {
      return const SizedBox.shrink();
    }

    final cycleData = _report!['cycleData'] as Map<String, dynamic>? ?? {};
    final journeyData = _report!['journeyData'] as Map<String, dynamic>? ?? {};
    final weeklySummary = _report!['weeklySummary'] as Map<String, dynamic>? ?? {};
    final activityStatus = _report!['activityStatus'] as Map<String, dynamic>? ?? {};

    final grade = weeklySummary['weeklyGrade']?.toString() ?? 'Balanced';
    final activeDays = weeklySummary['activeDaysThisWeek'] ?? 0;
    final parentTip = weeklySummary['parentTip']?.toString() ?? 'Offer gentle listening and positive reinforcement.';
    final wellnessScore = (_report!['wellnessScore'] as num?)?.toInt() ?? 75;

    final phase = (cycleData['currentPhase']?.toString() ?? 'Tracking');
    final isPeriodLate = cycleData['isPeriodLate'] == true;
    final daysLate = (cycleData['daysLate'] as num?)?.toInt() ?? 0;
    final daysUntilNext = cycleData['daysUntilNextPeriod'];

    final journeyTitle = journeyData['activeJourneyTitle'] ?? 'Creative Journey';
    final completedNodes = journeyData['completedNodesCount'] ?? 0;
    final totalXp = journeyData['totalXpEarned'] ?? 0;
    final daysInactive = activityStatus['daysInactive'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DaughterReportScreen(
              teenId: _teenId!,
              daughterName: _daughterName,
              avatarUrl: _avatarUrl,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
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
            // Header: Avatar + Daughter Name + Grade Badge
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
                  child: Center(
                    child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(_avatarUrl!),
                          )
                        : Text(
                            _daughterName.isNotEmpty ? _daughterName[0].toUpperCase() : 'D',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: const Color(0xFFB45309),
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
                        '$_daughterName\'s Weekly Highlights',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                          color: const Color(0xFF1E1B4B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Active $activeDays/7 days • Health Score: $wellnessScore%',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF854D0E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '🌟 $grade',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3-Tile Status Overview Grid (Distinct Soft Pastel Card)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSummaryItem(
                    '🌸 Menstrual Status',
                    isPeriodLate
                        ? '⚠️ Overdue (~$daysLate d)'
                        : (daysUntilNext != null ? 'In ~$daysUntilNext d ($phase)' : phase),
                    isAlert: isPeriodLate,
                  ),
                  const Divider(color: Color(0xFFF3F4F6), height: 12),
                  _buildSummaryItem(
                    '📚 Learning Progress',
                    '$journeyTitle ($completedNodes Modules, $totalXp XP)',
                  ),
                  const Divider(color: Color(0xFFF3F4F6), height: 12),
                  _buildSummaryItem(
                    '⚡ Routine Activity',
                    daysInactive > 1 ? '⚠️ Inactive for $daysInactive d' : 'Active Today ✅',
                    isAlert: daysInactive > 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Actionable Parent Tip (Warm Honey Glass)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      parentTip,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1B4B),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // View Full Report Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
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
                      const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'EXECUTIVE REPORT',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: const Color(0xFFB45309),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Full Report',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFFB45309)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String val, {bool isAlert = false}) {
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
