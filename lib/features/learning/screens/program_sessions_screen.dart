import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';

class ProgramSessionsScreen extends StatefulWidget {
  const ProgramSessionsScreen({
    super.key,
    required this.enrollment,
    required this.storage,
  });

  final Map<String, dynamic> enrollment;
  final LocalStorageService storage;

  @override
  State<ProgramSessionsScreen> createState() => _ProgramSessionsScreenState();
}

class _ProgramSessionsScreenState extends State<ProgramSessionsScreen> {
  Color _getProgramColor(String title) {
    final t = title.toUpperCase();
    if (t.contains('SPARK')) return const Color(0xFFF43F5E); // Rose
    if (t.contains('RISE')) return const Color(0xFF8B5CF6); // Violet
    if (t.contains('BLOOM')) return const Color(0xFF10B981); // Emerald
    if (t.contains('IGNITE')) return const Color(0xFFD946EF); // Fuchsia
    if (t.contains('UNSTOPPABLE')) return const Color(0xFFF59E0B); // Amber
    return AppColors.purple;
  }



  Future<void> _launchMeeting(String url) async {
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }
    final uri = Uri.parse(formattedUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prog = widget.enrollment['program'] as Map<String, dynamic>? ?? {};
    final title = prog['title'] ?? 'Program';
    final color = _getProgramColor(title);


    final curriculum = prog['curriculum'] as List<dynamic>?;
    final sessionsList = prog['sessionsList'] as List<dynamic>?;

    final List<dynamic> rawSessions = (curriculum != null && curriculum.isNotEmpty)
        ? curriculum
        : (sessionsList != null && sessionsList.isNotEmpty)
            ? sessionsList
            : [];

    final List<Map<String, dynamic>> displaySessions = rawSessions.isNotEmpty
        ? rawSessions.map((s) => {
            'title': s['title'] ?? 'Session',
            'description': s['description'] ?? 'Cohort topic discussion led by certified experts.',
            'week': s['week'] ?? s['sessionNumber'] ?? '',
            'thumbnailUrl': s['thumbnailUrl'] ?? '',
          }).toList()
        : List.generate(8, (i) => {
            'title': 'Session ${i + 1}: Live Interaction',
            'description': 'Dynamic developmental topic course lesson ${i + 1} led by verified guides.',
            'week': i + 1,
            'thumbnailUrl': '',
          });

    final dbSessions = widget.enrollment['user']?['scheduledSessions'] as List<dynamic>? ?? [];

    final sessionsWithStatus = displaySessions.map((session) {
      final sessionIndex = displaySessions.indexOf(session);
      final sessionNum = sessionIndex + 1;

      final dbSession = dbSessions.firstWhere(
        (s) => s['sessionNumber'] == sessionNum && s['programId'] == widget.enrollment['programId'],
        orElse: () => null,
      );

      String status = 'not-scheduled';
      String formattedDate = 'TBD';
      String formattedTime = 'TBD';
      String meetLink = '';
      bool isExpired = false;

      if (dbSession != null) {
        status = (dbSession['status'] ?? 'SCHEDULED').toString().toLowerCase();
        try {
          final t = DateTime.parse(dbSession['scheduledAt']).toLocal();
          formattedDate = '${t.day}/${t.month}/${t.year}';
          final hour = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
          final period = t.hour >= 12 ? 'PM' : 'AM';
          final min = t.minute.toString().padLeft(2, '0');
          formattedTime = '$hour:$min $period';
          meetLink = dbSession['meetLink'] ?? '';
          isExpired = DateTime.now().isAfter(t.add(const Duration(hours: 2)));
        } catch (_) {}
      }

      return {
        ...session,
        'status': status,
        'formattedDate': formattedDate,
        'formattedTime': formattedTime,
        'meetLink': meetLink,
        'isExpired': isExpired,
        'thumbnailUrl': (session['thumbnailUrl'] != null && session['thumbnailUrl'] != '')
            ? session['thumbnailUrl']
            : (prog['thumbnailUrl'] ?? ''),
      };
    }).toList();



    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F7),
      appBar: AppBar(
        title: Text(
          '$title Program Detail',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.enrollment['batch'] != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      'Assigned Batch: ${widget.enrollment['batch']['name']}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Sessions List
            ...sessionsWithStatus.map((session) {
              final isCompleted = session['status'] == 'completed';
              final isScheduled = session['status'] == 'scheduled';
              final isExpired = session['isExpired'] == true;
              final meetLink = session['meetLink']?.toString() ?? '';
              final sessionThumbnailUrl = session['thumbnailUrl']?.toString() ?? '';

              Color cardBgColor = Colors.white;
              Color iconBgColor = const Color(0xFFF3F4F6);
              Color iconColor = AppColors.textLight;
              IconData icon = Icons.lock_outline;

              if (isCompleted) {
                cardBgColor = Colors.white;
                iconBgColor = const Color(0xFFD1FAE5);
                iconColor = AppColors.success;
                icon = Icons.check_circle;
              } else if (isScheduled) {
                cardBgColor = const Color(0xFFF3E8FF);
                iconBgColor = Colors.purple;
                iconColor = Colors.white;
                icon = Icons.play_arrow;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      if (sessionThumbnailUrl.isNotEmpty)
                        Positioned.fill(
                          child: Image.network(
                            sessionThumbnailUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (sessionThumbnailUrl.isNotEmpty)
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                            child: Container(
                              color: isScheduled
                                  ? const Color(0xFFF3E8FF).withValues(alpha: 0.85)
                                  : Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: iconBgColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(icon, color: iconColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isCompleted
                                                  ? AppColors.success.withValues(alpha: 0.1)
                                                  : (isScheduled ? Colors.purple.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1)),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isCompleted
                                                  ? 'COMPLETED'
                                                  : (isScheduled ? 'UPCOMING LIVE' : 'NOT SCHEDULED'),
                                              style: TextStyle(
                                                color: isCompleted
                                                    ? AppColors.success
                                                    : (isScheduled ? Colors.purple : AppColors.textMedium),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (isScheduled) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${session['formattedDate']} at ${session['formattedTime']}',
                                                style: const TextStyle(
                                                  color: Colors.purple,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ] else if (isCompleted) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'on ${session['formattedDate']}',
                                                style: const TextStyle(
                                                  color: AppColors.textMedium,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        session['title'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        session['description'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMedium,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isScheduled) ...[
                            const Divider(height: 1, color: Color(0xFFE9D5FF)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.purple, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Prepare workbook',
                                        style: TextStyle(
                                          color: Colors.purple,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (meetLink.isNotEmpty) ...[
                                    if (isExpired)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Link Expired',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else
                                      ElevatedButton.icon(
                                        onPressed: () => _launchMeeting(meetLink),
                                        icon: const Icon(Icons.play_circle_outline, size: 16),
                                        label: const Text('Join Live Class'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(120, 36),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                  ] else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Link coming soon',
                                        style: TextStyle(
                                          color: Colors.purple,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
