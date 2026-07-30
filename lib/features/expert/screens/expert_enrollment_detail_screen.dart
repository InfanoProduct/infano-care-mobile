import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/expert/services/expert_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpertEnrollmentDetailScreen extends StatefulWidget {
  final String enrollmentId;
  final LocalStorageService storage;

  const ExpertEnrollmentDetailScreen({
    super.key,
    required this.enrollmentId,
    required this.storage,
  });

  @override
  State<ExpertEnrollmentDetailScreen> createState() => _ExpertEnrollmentDetailScreenState();
}

class _ExpertEnrollmentDetailScreenState extends State<ExpertEnrollmentDetailScreen> {
  late final ExpertService _expertService;
  bool _loading = true;
  Map<String, dynamic>? _details;
  int? _schedulingSessionNum;
  DateTime? _pickedDate;
  TimeOfDay? _pickedTime;
  final TextEditingController _meetLinkController = TextEditingController();
  bool _saving = false;
  String? _completingId;

  @override
  void initState() {
    super.initState();
    _expertService = ExpertService(widget.storage);
    _fetchDetails();
  }

  @override
  void dispose() {
    _meetLinkController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _toMap(dynamic val) {
    if (val == null) return {};
    if (val is Map<String, dynamic>) return val;
    if (val is Map) return Map<String, dynamic>.from(val);
    return {};
  }

  Future<void> _fetchDetails() async {
    setState(() => _loading = true);
    final data = await _expertService.getEnrollmentDetails(widget.enrollmentId);
    if (mounted) {
      setState(() {
        _details = data;
        _loading = false;
      });
    }
  }

  Future<void> _handleSchedule(int sessionNumber, String userId, String programId) async {
    if (_pickedDate == null || _pickedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date and time'), backgroundColor: AppColors.error));
      return;
    }
    final meetLink = _meetLinkController.text.trim();
    if (meetLink.isEmpty || (!meetLink.startsWith('http://') && !meetLink.startsWith('https://'))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid HTTP/HTTPS URL'), backgroundColor: AppColors.error));
      return;
    }

    final scheduledDt = DateTime(
      _pickedDate!.year,
      _pickedDate!.month,
      _pickedDate!.day,
      _pickedTime!.hour,
      _pickedTime!.minute,
    );

    setState(() => _saving = true);

    final success = await _expertService.scheduleProgramSession(
      userId: userId,
      programId: programId,
      sessionNumber: sessionNumber,
      scheduledAt: scheduledDt.toIso8601String(),
      meetLink: meetLink,
    );

    if (mounted) {
      setState(() {
        _saving = false;
        _schedulingSessionNum = null;
        _pickedDate = null;
        _pickedTime = null;
        _meetLinkController.clear();
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session scheduled! ✨'), backgroundColor: AppColors.success));
        _fetchDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to schedule session'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _handleComplete(String sessionId) async {
    setState(() => _completingId = sessionId);
    final success = await _expertService.completeProgramSession(sessionId);
    if (mounted) {
      setState(() => _completingId = null);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session completed! 🎉'), backgroundColor: AppColors.success));
        _fetchDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to complete session'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _launchMeetUrl(String urlStr) async {
    final uri = Uri.parse(urlStr);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link'), backgroundColor: AppColors.error));
      }
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return DateFormat('EEE, d MMM yyyy • hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F4F7),
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text('Loading Session Details...')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }

    if (_details == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F4F7),
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text('Error')),
        body: const Center(child: Text('Enrollment not found.', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
      );
    }

    final enrollment = _toMap(_details!['enrollment']);
    final sessions = (_details!['sessions'] as List?) ?? [];
    final user = _toMap(enrollment['user']);
    final profile = _toMap(user['profile']);
    final guestName = enrollment['guestName'] as String?;
    final displayName = profile['displayName'] as String?;
    final username = user['username'] as String?;
    final rawName = (guestName ?? displayName ?? username ?? 'Student').trim();
    final studentName = rawName.isEmpty ? 'Student' : rawName;

    final program = _toMap(enrollment['program']);
    final programTitle = program['title'] as String? ?? 'Program';
    final curriculum = (program['curriculum'] as List?) ?? [];
    final totalSessions = curriculum.isNotEmpty ? curriculum.length : 8;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('$studentName\'s Sessions',
            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.purple),
            onPressed: _fetchDetails,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: _fetchDetails,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Student & Program Info Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                        child: Text(studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                            style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                            const SizedBox(height: 2),
                            Text('Program: $programTitle', style: const TextStyle(fontSize: 13, color: AppColors.purple, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text('Curriculum Session Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),

            // Curriculum sessions loop
            for (int i = 1; i <= totalSessions; i++) ...[
              _buildSessionCard(
                sessionNumber: i,
                enrollment: enrollment,
                sessions: sessions,
                curriculum: curriculum,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard({
    required int sessionNumber,
    required Map<String, dynamic> enrollment,
    required List<dynamic> sessions,
    required List<dynamic> curriculum,
  }) {
    final existingSessionData = sessions.firstWhere(
      (s) => s is Map && s['sessionNumber'] == sessionNumber,
      orElse: () => null,
    );
    final existingSession = _toMap(existingSessionData);

    final prevSessionData = sessions.firstWhere(
      (s) => s is Map && s['sessionNumber'] == sessionNumber - 1,
      orElse: () => null,
    );
    final prevSession = _toMap(prevSessionData);

    final canSchedule = sessionNumber == 1 || (prevSession.isNotEmpty && prevSession['status'] == 'COMPLETED');
    final isScheduling = _schedulingSessionNum == sessionNumber;
    final status = (existingSession['status'] as String? ?? 'NOT_SCHEDULED').toUpperCase();

    String sessionTitle = 'Session $sessionNumber';
    String sessionDesc = '';
    if (curriculum.length >= sessionNumber) {
      final curr = _toMap(curriculum[sessionNumber - 1]);
      sessionTitle = curr['title'] as String? ?? sessionTitle;
      sessionDesc = curr['description'] as String? ?? '';
    }

    Color statusColor = AppColors.textLight;
    if (status == 'COMPLETED') statusColor = AppColors.success;
    if (status == 'SCHEDULED') statusColor = AppColors.purple;

    final hasExistingSession = existingSession.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(sessionNumber.toString(),
                        style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(sessionTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                      if (sessionDesc.isNotEmpty)
                        Text(sessionDesc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(status.replaceAll('_', ' '), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            if (hasExistingSession) ...[
              const SizedBox(height: 8),
              Text(_formatDateTime(existingSession['scheduledAt'] as String?), style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              if (existingSession['meetLink'] != null && (existingSession['meetLink'] as String).isNotEmpty) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _launchMeetUrl(existingSession['meetLink']),
                  child: Row(
                    children: [
                      const Icon(Icons.video_call_rounded, color: AppColors.purple, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(existingSession['meetLink'] as String,
                            style: const TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 12),
            // Actions
            if (!hasExistingSession && !isScheduling) ...[
              if (canSchedule)
                InkWell(
                  onTap: () {
                    setState(() {
                      _schedulingSessionNum = sessionNumber;
                      _pickedDate = DateTime.now().add(const Duration(days: 1));
                      _pickedTime = const TimeOfDay(hour: 10, minute: 0);
                      _meetLinkController.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Schedule Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text('Complete Session ${sessionNumber - 1} first',
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],

            if (hasExistingSession && existingSession['status'] == 'SCHEDULED') ...[
              InkWell(
                onTap: _completingId == existingSession['id'] ? null : () => _handleComplete(existingSession['id'] as String),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(_completingId == existingSession['id'] ? 'Updating...' : 'Mark Completed ✓',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],

            // Scheduling Form
            if (isScheduling) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text('Schedule Session $sessionNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.purple)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final dt = await showDatePicker(
                          context: context,
                          initialDate: _pickedDate ?? DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (dt != null) setState(() => _pickedDate = dt);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event, size: 16, color: AppColors.purple),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _pickedDate == null ? 'Select Date' : DateFormat('d MMM yyyy').format(_pickedDate!),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _pickedTime ?? const TimeOfDay(hour: 10, minute: 0),
                        );
                        if (time != null) setState(() => _pickedTime = time);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time, size: 16, color: AppColors.purple),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _pickedTime == null ? 'Select Time' : _pickedTime!.format(context),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _meetLinkController,
                decoration: InputDecoration(
                  labelText: 'Meeting Link (Google Meet / Zoom)',
                  hintText: 'https://meet.google.com/...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _saving ? null : () => _handleSchedule(sessionNumber, enrollment['userId'] as String? ?? '', enrollment['programId'] as String? ?? ''),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _saving ? Colors.grey : AppColors.purple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(_saving ? 'Saving...' : 'Save Schedule', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() => _schedulingSessionNum = null),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
