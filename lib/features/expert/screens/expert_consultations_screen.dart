import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/expert/services/expert_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpertConsultationsScreen extends StatefulWidget {
  final LocalStorageService storage;
  final bool isEmbedded;
  const ExpertConsultationsScreen({super.key, required this.storage, this.isEmbedded = false});

  @override
  State<ExpertConsultationsScreen> createState() => _ExpertConsultationsScreenState();
}

class _ExpertConsultationsScreenState extends State<ExpertConsultationsScreen> {
  late final ExpertService _expertService;
  bool _loading = true;
  List<dynamic> _sessions = [];
  String _statusFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _expertService = ExpertService(widget.storage);
    _fetchSessions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSessions() async {
    setState(() => _loading = true);
    final sessions = await _expertService.getDirectSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    }
  }

  List<dynamic> get _filteredSessions {
    return _sessions.where((s) {
      final status = (s['status'] as String? ?? '').toUpperCase();
      if (_statusFilter != 'ALL' && status != _statusFilter) return false;

      if (_searchQuery.isNotEmpty) {
        final user = s['user'] as Map<String, dynamic>? ?? {};
        final profile = user['profile'] as Map<String, dynamic>? ?? {};
        final name = (profile['displayName'] as String? ?? user['username'] as String? ?? '').toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _editMeetLink(Map<String, dynamic> session) async {
    final currentLink = session['meetLink'] as String? ?? '';
    final controller = TextEditingController(text: currentLink);
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Update Meeting Link 🔗', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add or update the Google Meet/Zoom link for this consultation:', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Meeting Link URL',
                  hintText: 'https://meet.google.com/...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.link_rounded, color: AppColors.purple),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter a URL';
                  if (!val.trim().startsWith('http://') && !val.trim().startsWith('https://')) {
                    return 'URL must start with http:// or https://';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final success = await _expertService.updateMeetLink(session['id'], controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx, success);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white),
            child: const Text('Save Link'),
          ),
        ],
      ),
    );

    if (updated == true) {
      _fetchSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting link updated! ✨'), backgroundColor: AppColors.success));
      }
    }
  }

  Future<void> _updateStatus(Map<String, dynamic> session, String newStatus) async {
    final success = await _expertService.updateSessionStatus(session['id'], newStatus);
    if (success) {
      _fetchSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus!'), backgroundColor: AppColors.success));
      }
    }
  }

  Future<void> _reschedule(Map<String, dynamic> session) async {
    final currentDt = DateTime.tryParse(session['scheduledAt'] ?? '') ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDt),
      );

      if (pickedTime != null) {
        final newDt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
        final success = await _expertService.rescheduleSession(session['id'], newDt.toIso8601String());
        if (success) {
          _fetchSessions();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consultation rescheduled! ✨'), backgroundColor: AppColors.success));
          }
        }
      }
    }
  }

  Future<void> _launchUrl(String urlStr) async {
    final Uri uri = Uri.parse(urlStr);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open meeting link'), backgroundColor: AppColors.error));
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
    final scheduledCount = _sessions.where((s) => (s['status'] as String? ?? '').toUpperCase() == 'SCHEDULED' || (s['status'] as String? ?? '').toUpperCase() == 'RESCHEDULED').length;
    final completedCount = _sessions.where((s) => (s['status'] as String? ?? '').toUpperCase() == 'COMPLETED').length;
    final missingLinksCount = _sessions.where((s) => s['meetLink'] == null || (s['meetLink'] as String).isEmpty).length;

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
              title: const Text('Direct Consultations', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.purple),
                  onPressed: _fetchSessions,
                ),
              ],
            ),
      body: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: _fetchSessions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats Row
            Row(
              children: [
                _buildStatTile('Total', _sessions.length.toString(), Icons.event_note_rounded, AppColors.purple),
                const SizedBox(width: 8),
                _buildStatTile('Scheduled', scheduledCount.toString(), Icons.schedule_rounded, const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _buildStatTile('Completed', completedCount.toString(), Icons.check_circle_outline_rounded, AppColors.success),
                const SizedBox(width: 8),
                _buildStatTile('Missing Link', missingLinksCount.toString(), Icons.link_off_rounded, AppColors.error),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search client name...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['ALL', 'SCHEDULED', 'COMPLETED', 'CANCELLED'].map((status) {
                  final selected = _statusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: selected,
                      label: Text(status),
                      selectedColor: AppColors.purple,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textDark,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _statusFilter = status),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Sessions List
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.purple)))
            else if (_filteredSessions.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: Colors.white,
                child: const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 48, color: AppColors.textLight),
                      SizedBox(height: 12),
                      Text('No consultations found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Direct 1:1 scheduled appointments will appear here.', style: TextStyle(color: AppColors.textLight, fontSize: 13), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            else
              ..._filteredSessions.map((session) => _buildSessionCard(session)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final user = session['user'] as Map<String, dynamic>? ?? {};
    final profile = user['profile'] as Map<String, dynamic>? ?? {};
    final clientName = (profile['displayName'] as String? ?? user['username'] as String? ?? 'Client').trim();
    final status = (session['status'] as String? ?? 'SCHEDULED').toUpperCase();
    final meetLink = session['meetLink'] as String?;
    final scheduledAt = session['scheduledAt'] as String?;

    Color statusColor = AppColors.purple;
    if (status == 'COMPLETED') statusColor = AppColors.success;
    if (status == 'CANCELLED') statusColor = AppColors.error;
    if (status == 'RESCHEDULED') statusColor = const Color(0xFFF59E0B);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name & Status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                  child: Text(clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C', style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text(_formatDateTime(scheduledAt), style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Meeting Link Bar
            if (meetLink != null && meetLink.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.video_call_rounded, color: AppColors.purple, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(meetLink, style: const TextStyle(fontSize: 12, color: AppColors.purple, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _launchUrl(meetLink),
                      icon: const Icon(Icons.launch_rounded, size: 14),
                      label: const Text('Join'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.link_off_rounded, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text('No meeting link added yet', style: TextStyle(fontSize: 12, color: AppColors.error)),
                  ],
                ),
              ),

            // Actions row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editMeetLink(session),
                    icon: const Icon(Icons.link_rounded, size: 16),
                    label: Text(meetLink == null || meetLink.isEmpty ? 'Add Link' : 'Edit Link'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.purple),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reschedule(session),
                    icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    label: const Text('Reschedule'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.textDark),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMedium),
                  onSelected: (val) => _updateStatus(session, val),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'SCHEDULED', child: Text('Mark Scheduled')),
                    const PopupMenuItem(value: 'COMPLETED', child: Text('Mark Completed')),
                    const PopupMenuItem(value: 'CANCELLED', child: Text('Mark Cancelled')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
