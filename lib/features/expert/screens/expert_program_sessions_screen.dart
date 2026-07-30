import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/expert/services/expert_service.dart';
import 'package:intl/intl.dart';

class ExpertProgramSessionsScreen extends StatefulWidget {
  final LocalStorageService storage;
  final bool isEmbedded;
  const ExpertProgramSessionsScreen({super.key, required this.storage, this.isEmbedded = false});

  @override
  State<ExpertProgramSessionsScreen> createState() => _ExpertProgramSessionsScreenState();
}

class _ExpertProgramSessionsScreenState extends State<ExpertProgramSessionsScreen> {
  late final ExpertService _expertService;
  bool _loading = true;
  List<dynamic> _enrollments = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _expertService = ExpertService(widget.storage);
    _fetchEnrollments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _toMap(dynamic val) {
    if (val == null) return {};
    if (val is Map<String, dynamic>) return val;
    if (val is Map) return Map<String, dynamic>.from(val);
    return {};
  }

  Future<void> _fetchEnrollments() async {
    setState(() => _loading = true);
    final data = await _expertService.getEnrollments();
    if (mounted) {
      setState(() {
        _enrollments = data;
        _loading = false;
      });
    }
  }

  List<dynamic> get _filteredEnrollments {
    if (_searchQuery.isEmpty) return _enrollments;
    final q = _searchQuery.toLowerCase();
    return _enrollments.where((e) {
      final item = _toMap(e);
      final user = _toMap(item['user']);
      final profile = _toMap(user['profile']);
      final program = _toMap(item['program']);

      final guestName = item['guestName'] as String?;
      final displayName = profile['displayName'] as String?;
      final username = user['username'] as String?;

      final name = (guestName ?? displayName ?? username ?? '').toLowerCase();
      final programTitle = (program['title'] as String? ?? '').toLowerCase();

      return name.contains(q) || programTitle.contains(q);
    }).toList();
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return DateFormat('d MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F7),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Program Sessions Workspace',
                  style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.purple),
                  onPressed: _fetchEnrollments,
                ),
              ],
            ),
      body: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: _fetchEnrollments,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.layers_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Program Sessions Workspace',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage learning program curriculums, schedule 1:1 sessions, and set meet links per student.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search input
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search student or program...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Enrollments list
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.purple)))
            else if (_filteredEnrollments.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: Colors.white,
                child: const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.layers_clear_outlined, size: 48, color: AppColors.textLight),
                      SizedBox(height: 12),
                      Text('No active enrollments found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('When students enroll in 1:1 learning programs, they will appear here.',
                          style: TextStyle(color: AppColors.textLight, fontSize: 13), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            else
              ..._filteredEnrollments.map((enrollment) => _buildEnrollmentCard(enrollment)),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentCard(dynamic rawEnrollment) {
    final enrollment = _toMap(rawEnrollment);
    final user = _toMap(enrollment['user']);
    final profile = _toMap(user['profile']);
    final program = _toMap(enrollment['program']);

    final guestName = enrollment['guestName'] as String?;
    final displayName = profile['displayName'] as String?;
    final username = user['username'] as String?;
    final rawName = (guestName ?? displayName ?? username ?? 'Student').trim();
    final studentName = rawName.isEmpty ? 'Student' : rawName;

    final guestEmail = enrollment['guestEmail'] as String?;
    final programTitle = program['title'] as String? ?? 'Program';
    final createdAt = enrollment['createdAt'] as String?;
    final enrollmentId = enrollment['id'] as String? ?? '';

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
                CircleAvatar(
                  backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                  child: Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                    style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        studentName, 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                      ),
                      if (guestEmail != null && guestEmail.isNotEmpty)
                        Text(
                          guestEmail, 
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('1:1 PRIVATE', style: TextStyle(color: AppColors.purple, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        programTitle, 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Enrolled: ${_formatDate(createdAt)}', 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => context.push('/expert/enrollment-details/$enrollmentId'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Manage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
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
}
