import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/learning/repositories/learning_repository.dart';
import 'package:infano_care_mobile/features/learning/screens/program_sessions_screen.dart';
import 'package:infano_care_mobile/features/creative_journey/screens/creative_journey_hub_screen.dart';

class LearnHubScreen extends StatefulWidget {
  const LearnHubScreen({super.key, required this.storage});

  final LocalStorageService storage;

  @override
  State<LearnHubScreen> createState() => _LearnHubScreenState();
}

class _LearnHubScreenState extends State<LearnHubScreen> {
  @override
  Widget build(BuildContext context) {
    return const CreativeJourneyHubScreen();
  }
}

class LearningProgramsScreen extends StatelessWidget {
  const LearningProgramsScreen({super.key, required this.storage});

  final LocalStorageService storage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Enrolled Programs',
          style: TextStyle(
            color: AppColors.purple,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.purple),
      ),
      body: ProgramsTab(storage: storage),
    );
  }
}

class ProgramsTab extends StatefulWidget {
  const ProgramsTab({super.key, required this.storage});

  final LocalStorageService storage;

  @override
  State<ProgramsTab> createState() => _ProgramsTabState();
}

class _ProgramsTabState extends State<ProgramsTab> {
  late Future<List<dynamic>> _dataFuture;
  late final LearningRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = LearningRepository(ApiService.instance.dio);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = Future.wait([
        _repository.listActivePrograms(),
        _repository.getMyProgramEnrollments(),
      ]);
    });
  }

  Color _getProgramColor(String title) {
    final t = title.toUpperCase();
    if (t.contains('SPARK')) return const Color(0xFFF43F5E); // Rose
    if (t.contains('RISE')) return const Color(0xFF8B5CF6); // Violet
    if (t.contains('BLOOM')) return const Color(0xFF10B981); // Emerald
    if (t.contains('IGNITE')) return const Color(0xFFD946EF); // Fuchsia
    if (t.contains('UNSTOPPABLE')) return const Color(0xFFF59E0B); // Amber
    return AppColors.purple;
  }

  Color _getProgramBgColor(String title) {
    final t = title.toUpperCase();
    if (t.contains('SPARK')) return const Color(0xFFFFF0F2);
    if (t.contains('RISE')) return const Color(0xFFF5F2FF);
    if (t.contains('BLOOM')) return const Color(0xFFECFDF5);
    if (t.contains('IGNITE')) return const Color(0xFFFDF2FF);
    if (t.contains('UNSTOPPABLE')) return const Color(0xFFFFFDF0);
    return Colors.white;
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

  String _formatScheduledTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${DateFormat('EEE, MMM d, yyyy').format(dt)} at ${DateFormat('h:mm a').format(dt)}';
    } catch (_) {
      return isoString;
    }
  }

  bool _isSessionExpired(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateTime.now().isAfter(dt.add(const Duration(hours: 2)));
    } catch (_) {
      return false;
    }
  }

  void _showBookDemoBottomSheet(Map<String, dynamic> program) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: _DemoBookingForm(
            program: program,
            storage: widget.storage,
            repository: _repository,
            onSuccess: () {
              Navigator.pop(context);
              _loadData();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F7),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
          await _dataFuture;
        },
        child: FutureBuilder<List<dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.purple));
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        snapshot.hasError
                            ? 'Failed to load programs.\n${snapshot.error}'
                            : 'No data found.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          minimumSize: const Size(120, 44),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final dataList = snapshot.data!;
            final activePrograms = (dataList.isNotEmpty ? dataList[0] : []) as List<dynamic>? ?? [];
            final enrollments = (dataList.length > 1 ? dataList[1] : []) as List<dynamic>? ?? [];

            final enrolledProgramIds = enrollments.map((e) => e['programId']).toSet();
            final availablePrograms = activePrograms
                .where((p) => !enrolledProgramIds.contains(p['id']))
                .toList();

            return ListView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
              children: [
                // 1. My Enrolled / Purchased Programs
                if (enrollments.isNotEmpty) ...[
                  const Text(
                    'My Enrolled Programs',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 10),
                  ...enrollments.map((enr) {
                    final prog = enr['program'];
                    final color = _getProgramColor(prog['title'] ?? '');
                    final enrUser = enr['user'];
                    final enrolledByTeen = enrUser != null && enrUser['role'] == 'TEEN';
                    final hasUserBadge = enrUser != null && enrUser['id'] != widget.storage.userId;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProgramSessionsScreen(
                              enrollment: enr,
                              storage: widget.storage,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.workspace_premium, color: color),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          prog['title'] ?? 'Program',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          (enr['status'] ?? 'ACTIVE').toString().toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hasUserBadge) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: enrolledByTeen ? const Color(0xFFF3E8FF) : const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: enrolledByTeen ? const Color(0xFFE9D5FF) : const Color(0xFFBFDBFE),
                                        ),
                                      ),
                                      child: Text(
                                        'Enrolled by: ${enrolledByTeen ? "Daughter" : "Parent"}',
                                        style: TextStyle(
                                          color: enrolledByTeen ? const Color(0xFF7E22CE) : const Color(0xFF1D4ED8),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prog['tagline'] ?? 'Cohort program',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Class Band: ${prog['classRange']}',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
                                  ),
                                  
                                  // Consultations listing (if present)
                                  if (prog['consultations'] != null && (prog['consultations'] as List).isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 14, color: AppColors.purple),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Included: ${(prog['consultations'] as List).map((c) => c['title']).join(', ')}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.purple,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  const Divider(height: 24),
                                  Builder(
                                    builder: (context) {
                                      final curriculum = prog['curriculum'] as List<dynamic>?;
                                      final sessionsList = prog['sessionsList'] as List<dynamic>?;
                                      final List<dynamic> rawSessions = (curriculum != null && curriculum.isNotEmpty)
                                          ? curriculum
                                          : (sessionsList != null && sessionsList.isNotEmpty)
                                              ? sessionsList
                                              : [];
                                      final totalCount = rawSessions.isNotEmpty ? rawSessions.length : 8;
                                      final dbSessions = enr['user']?['scheduledSessions'] as List<dynamic>? ?? [];
                                      final completedCount = dbSessions.where((s) => s['status']?.toString().toUpperCase() == 'COMPLETED' && s['programId'] == enr['programId']).length;
                                      final progressPct = totalCount > 0 ? (completedCount / totalCount) : 0.0;

                                      final scheduledSession = dbSessions.firstWhere(
                                        (s) => s['status']?.toString().toLowerCase() == 'scheduled' && s['programId'] == enr['programId'],
                                        orElse: () => null,
                                      );

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${(progressPct * 100).round()}% Completed',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMedium),
                                              ),
                                              Text(
                                                '$completedCount/$totalCount',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMedium),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: progressPct,
                                              backgroundColor: const Color(0xFFE5E7EB),
                                              valueColor: AlwaysStoppedAnimation<Color>(color),
                                              minHeight: 6,
                                            ),
                                          ),

                                          // Upcoming Live Session Block (If Scheduled)
                                          if (scheduledSession != null) ...[
                                            const SizedBox(height: 16),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF3E8FF),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: const Color(0xFFE9D5FF)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFFAF5FF),
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(color: const Color(0xFFD8B4FE)),
                                                        ),
                                                        child: const Text(
                                                          'Upcoming Live',
                                                          style: TextStyle(
                                                            color: Color(0xFF7E22CE),
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          _formatScheduledTime(scheduledSession['scheduledAt']),
                                                          style: const TextStyle(
                                                            color: Color(0xFF5B21B6),
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    scheduledSession['sessionName'] ?? 'Next Cohort Live Session',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.textDark,
                                                    ),
                                                  ),
                                                  if (scheduledSession['meetingLink'] != null || scheduledSession['meetLink'] != null) ...[
                                                    const SizedBox(height: 10),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton.icon(
                                                        onPressed: _isSessionExpired(scheduledSession['scheduledAt'])
                                                            ? null
                                                            : () {
                                                                final link = scheduledSession['meetingLink'] ?? scheduledSession['meetLink'];
                                                                _launchMeeting(link);
                                                              },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFF8B5CF6),
                                                          foregroundColor: Colors.white,
                                                          disabledBackgroundColor: Colors.grey[300],
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                                        ),
                                                        icon: const Icon(Icons.play_arrow, size: 16),
                                                        label: Text(
                                                          _isSessionExpired(scheduledSession['scheduledAt']) ? 'Class Expired' : 'Join Live Class',
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],

                // 2. Available Catalog (Curated Learning Programs matching Web UI)
                if (availablePrograms.isNotEmpty) ...[
                  const Text(
                    'Curated Learning Programs',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enroll in specialized expert cohorts designed to empower growth',
                    style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 12),
                  ...availablePrograms.map((prog) {
                    final accentColor = _getProgramColor(prog['title'] ?? '');
                    final cardBgColor = _getProgramBgColor(prog['title'] ?? '');
                    final consultations = prog['consultations'] as List<dynamic>?;
                    final topics = prog['topics'] as List<dynamic>?;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: accentColor.withValues(alpha: 0.2)),
                      ),
                      color: cardBgColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (prog['thumbnailUrl'] != null)
                            Image.network(
                              prog['thumbnailUrl'],
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 140,
                                color: accentColor.withValues(alpha: 0.1),
                                child: Icon(Icons.school, size: 48, color: accentColor),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        prog['title'] ?? 'Program Title',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        prog['classRange'] ?? 'Cohort',
                                        style: TextStyle(
                                          color: accentColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '"${prog['tagline'] ?? prog['description'] ?? ''}"',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Web-parity Metabar
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: accentColor.withValues(alpha: 0.1)),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        Icon(Icons.book_outlined, size: 14, color: accentColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${prog['curriculum']?.length ?? prog['sessionsList']?.length ?? 8} Sessions',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMedium),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(width: 1, height: 12, color: Colors.grey[200]),
                                        const SizedBox(width: 8),
                                        Icon(Icons.calendar_today_outlined, size: 14, color: accentColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          prog['duration'] ?? '8 weeks',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMedium),
                                        ),
                                        if (consultations != null && consultations.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(width: 1, height: 12, color: Colors.grey[200]),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.auto_awesome, size: 14, color: Colors.purple),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${consultations.length} Free ${consultations.length == 1 ? "Consultation" : "Consultations"}',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // Cover Topics
                                if (topics != null && topics.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'What she will cover:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...topics.take(5).map((topic) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: accentColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                           child: Icon(Icons.check, size: 10, color: accentColor),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            topic.toString(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],

                                const Divider(height: 24),
                                
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: () => _showBookDemoBottomSheet(prog),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Book Free Demo',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        SizedBox(width: 6),
                                        Icon(Icons.arrow_forward, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DemoBookingForm extends StatefulWidget {
  const _DemoBookingForm({
    required this.program,
    required this.storage,
    required this.repository,
    required this.onSuccess,
  });

  final Map<String, dynamic> program;
  final LocalStorageService storage;
  final LearningRepository repository;
  final VoidCallback onSuccess;

  @override
  State<_DemoBookingForm> createState() => _DemoBookingFormState();
}

class _DemoBookingFormState extends State<_DemoBookingForm> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isSubmitting = false;
  bool _isSuccess = false;

  final List<String> _timeSlots = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 03:00 PM',
    '03:00 PM - 04:00 PM',
    '04:00 PM - 05:00 PM',
    '05:00 PM - 06:00 PM',
    '06:00 PM - 07:00 PM',
  ];

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.purple,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date for the demo.')),
      );
      return;
    }
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final bookingData = {
        'parentName': widget.storage.displayName ?? 'User',
        'phone': widget.storage.phone ?? '',
        'email': null,
        'classRange': widget.program['classRange'] ?? '',
        'confidence': '',
        'interests': [],
        'hasMentor': '',
        'challenges': [],
        'learningPref': '1:1 Private Mentoring',
        'parentInvolvement': '',
        'suggestedPrograms': [widget.program['title'] ?? ''],
        'slotDate': dateStr,
        'slotTime': _selectedTimeSlot,
      };

      final res = await widget.repository.bookDemoSession(bookingData);
      if (res['success'] == true) {
        setState(() {
          _isSuccess = true;
        });
        await Future.delayed(const Duration(milliseconds: 1500));
        widget.onSuccess();
      } else {
        throw res['message'] ?? 'Failed to book demo session';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking demo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Demo Booked Successfully!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We have received your demo request for ${widget.program['title']}. We will contact you soon.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Form Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Book Free Demo Session',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Program: ${widget.program['title']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stored Profile Details
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200] ?? const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Profile Details:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.storage.displayName ?? "User"} • ${widget.storage.phone ?? ""}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Select Date Field
                  const Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200] ?? const Color(0xFFEEEEEE)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                            style: TextStyle(
                              color: _selectedDate == null ? Colors.grey[500] : AppColors.textDark,
                              fontSize: 14,
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.purple),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Select Time Slot Field
                  const Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200] ?? const Color(0xFFEEEEEE)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTimeSlot,
                        hint: const Text('Select Time Slot'),
                        isExpanded: true,
                        items: _timeSlots.map((slot) {
                          return DropdownMenuItem(
                            value: slot,
                            child: Text(slot, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedTimeSlot = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Book Free Demo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
