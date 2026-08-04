import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:intl/intl.dart';

class NotificationCenterSheet extends StatefulWidget {
  const NotificationCenterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationCenterSheet(),
    );
  }

  @override
  State<NotificationCenterSheet> createState() => _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends State<NotificationCenterSheet> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService.instance.dio.get('/parent/notifications');
      if (mounted) {
        setState(() {
          _notifications = res.data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notifications.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _dismissNotification(String id, String? deepLink) async {
    // Optimistic UI update
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
    });

    try {
      await ApiService.instance.dio.delete('/parent/notifications/$id');
    } catch (e) {
      debugPrint('Failed to dismiss notification: $e');
    }

    if (deepLink != null && deepLink.startsWith('infano://')) {
      final path = deepLink.replaceFirst('infano://', '/');
      if (mounted) {
        final router = GoRouter.of(context);
        Navigator.pop(context); // Close bottom sheet
        router.push(path);
      }
    }
  }

  Future<void> _clearAll() async {
    setState(() {
      _notifications.clear();
    });

    try {
      await ApiService.instance.dio.delete('/parent/notifications');
    } catch (e) {
      debugPrint('Failed to clear all notifications: $e');
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    final dt = DateTime.tryParse(timeStr)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'linkRequest':
        return Icons.person_add_outlined;
      case 'linkAcceptance':
        return Icons.link_rounded;
      case 'linkDeclined':
        return Icons.link_off_rounded;
      case 'sessionScheduled':
      case 'programSessionScheduled':
        return Icons.calendar_month_outlined;
      case 'sessionRescheduled':
      case 'programSessionRescheduled':
        return Icons.update_rounded;
      case 'sessionReminder15Min':
        return Icons.alarm_rounded;
      case 'PERIOD_PREDICTION':
        return Icons.water_drop_outlined;
      case 'DAILY_LOG_REMINDER':
        return Icons.edit_note_rounded;
      case 'STREAK_AT_RISK':
        return Icons.local_fire_department_rounded;
      case 'LATE_PERIOD':
        return Icons.warning_amber_rounded;
      case 'PHASE_CHANGE':
        return Icons.track_changes_rounded;
      case 'SYMPTOM_PATTERN':
        return Icons.insights_rounded;
      case 'DOCTOR_CONNECT':
        return Icons.medical_services_outlined;
      case 'CYCLE_MILESTONE':
        return Icons.emoji_events_outlined;
      case 'MONTHLY_INSIGHTS':
        return Icons.analytics_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'linkRequest':
      case 'linkAcceptance':
        return AppColors.purple;
      case 'linkDeclined':
        return Colors.red;
      case 'sessionScheduled':
      case 'programSessionScheduled':
      case 'sessionRescheduled':
      case 'programSessionRescheduled':
        return Colors.blue;
      case 'sessionReminder15Min':
        return Colors.orange;
      case 'PERIOD_PREDICTION':
        return Colors.pink;
      case 'DAILY_LOG_REMINDER':
        return AppColors.purple;
      case 'STREAK_AT_RISK':
        return Colors.orange;
      case 'LATE_PERIOD':
        return Colors.red;
      case 'PHASE_CHANGE':
        return Colors.green;
      case 'SYMPTOM_PATTERN':
        return Colors.indigo;
      case 'DOCTOR_CONNECT':
        return Colors.teal;
      case 'CYCLE_MILESTONE':
        return Colors.amber;
      case 'MONTHLY_INSIGHTS':
        return Colors.blue;
      default:
        return AppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height * 0.75;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                if (_notifications.isNotEmpty)
                  TextButton(
                    onPressed: _clearAll,
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: GoogleFonts.nunito(color: Colors.grey[600]),
                        ),
                      )
                    : _notifications.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            itemCount: _notifications.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];
                              final id = notification['id'].toString();
                              final type = notification['type'].toString();
                              final title = notification['title'].toString();
                              final body = notification['body'].toString();
                              final deepLink = notification['deepLink']?.toString();
                              final sentAt = notification['sentAt']?.toString();

                              final color = _getColorForType(type);
                              final icon = _getIconForType(type);

                              return InkWell(
                                onTap: () => _dismissNotification(id, deepLink),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Icon container
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(icon, color: color, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      // Text content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: GoogleFonts.nunito(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 14,
                                                      color: AppColors.textDark,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  _formatTime(sentAt),
                                                  style: GoogleFonts.nunito(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textLight,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              body,
                                              style: GoogleFonts.nunito(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textMedium,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.purple,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No new notifications at the moment.',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
