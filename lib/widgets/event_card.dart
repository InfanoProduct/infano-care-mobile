import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/models/event.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventCard extends StatefulWidget {
  final CommunityEvent event;
  final VoidCallback onTap;

  const EventCard({
    Key? key,
    required this.event,
    required this.onTap,
  }) : super(key: key);

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isReminderSet = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, hh:mm a');
    final isLive = widget.event.status == 'live';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLive ? AppColors.purple.withOpacity(0.2) : AppColors.purple.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isLive ? AppColors.purple.withOpacity(0.12) : AppColors.purple.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored Upper Part
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isLive ? AppColors.purple.withOpacity(0.08) : AppColors.purple.withOpacity(0.04),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.event.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (!isLive) _buildReminderToggle(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        widget.event.expertName ?? 'Expert',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.purple),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.blue, size: 14),
                      if (isLive) ...[
                        const Spacer(),
                        const Icon(Icons.circle, color: AppColors.error, size: 8),
                        const SizedBox(width: 6),
                        const Text('LIVE NOW', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 10)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Lower Part
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  _buildInfoBadge(
                    Icons.calendar_today_outlined, 
                    isLive ? 'Started ${DateFormat('hh:mm a').format(widget.event.startTime)}' : dateFormat.format(widget.event.startTime),
                    isLive ? AppColors.error : AppColors.textMedium,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoBadge(
                    Icons.people_outline, 
                    '${widget.event.participantsCount} girls',
                    AppColors.textMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderToggle() {
    return GestureDetector(
      onTap: () async {
        setState(() => _isReminderSet = !_isReminderSet);
        if (_isReminderSet) {
          final api = Provider.of<CommunityApi>(context, listen: false);
          await api.setEventReminder(widget.event.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isReminderSet ? AppColors.purple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _isReminderSet ? AppColors.purple : AppColors.purple.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(
              _isReminderSet ? Icons.notifications_active : Icons.notifications_none,
              size: 14,
              color: _isReminderSet ? Colors.white : AppColors.purple,
            ),
            const SizedBox(width: 4),
            Text(
              _isReminderSet ? 'Reminded' : 'Remind me',
              style: TextStyle(
                color: _isReminderSet ? Colors.white : AppColors.purple,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
