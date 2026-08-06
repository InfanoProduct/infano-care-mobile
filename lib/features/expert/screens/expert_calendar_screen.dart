import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/expert/services/expert_service.dart';
import 'package:intl/intl.dart';

class ExpertCalendarScreen extends StatefulWidget {
  final LocalStorageService storage;
  const ExpertCalendarScreen({super.key, required this.storage});

  @override
  State<ExpertCalendarScreen> createState() => _ExpertCalendarScreenState();
}

class _ExpertCalendarScreenState extends State<ExpertCalendarScreen> with SingleTickerProviderStateMixin {
  late final ExpertService _expertService;
  late TabController _tabController;
  bool _loading = true;
  bool _saving = false;

  // Settings
  String _timezone = 'Asia/Kolkata';
  String _reschedulePolicy = '24 hours prior';
  int _bookingPeriodMonths = 2;

  // Schedule
  static const List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  Map<String, List<Map<String, String>>> _defaultAvailability = {};
  List<String> _blockDates = [];

  @override
  void initState() {
    super.initState();
    _expertService = ExpertService(widget.storage);
    _tabController = TabController(length: 2, vsync: this);
    _fetchSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    setState(() => _loading = true);
    final data = await _expertService.getCalendarSettings();
    if (mounted) {
      setState(() {
        _loading = false;
        if (data.isNotEmpty) {
          _timezone = data['timezone'] as String? ?? 'Asia/Kolkata';
          _reschedulePolicy = data['reschedulePolicy'] as String? ?? '24 hours prior';
          _bookingPeriodMonths = (data['bookingPeriodMonths'] as num?)?.toInt() ?? 2;
          
          final rawAvail = data['defaultAvailability'] as Map<String, dynamic>?;
          if (rawAvail != null) {
            _defaultAvailability = rawAvail.map((day, slots) {
              final slotList = (slots as List<dynamic>?)?.map((s) {
                final map = s as Map<String, dynamic>;
                return {
                  'start': (map['start'] as String?) ?? '09:00',
                  'end': (map['end'] as String?) ?? '17:00',
                };
              }).toList() ?? [];
              return MapEntry(day, slotList);
            });
          }

          final rawBlocks = data['blockDates'] as List<dynamic>?;
          if (rawBlocks != null) {
            _blockDates = rawBlocks.map((e) => e.toString()).toList();
          }
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    final payload = {
      'timezone': _timezone,
      'reschedulePolicy': _reschedulePolicy,
      'bookingPeriodMonths': _bookingPeriodMonths,
      'defaultAvailability': _defaultAvailability,
      'blockDates': _blockDates,
    };

    final success = await _expertService.updateCalendarSettings(payload);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Calendar settings saved successfully! ✨' : 'Failed to save settings.'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _addSlot(String day) {
    setState(() {
      final slots = _defaultAvailability[day] ?? [];
      slots.add({'start': '09:00', 'end': '17:00'});
      _defaultAvailability[day] = slots;
    });
  }

  void _removeSlot(String day, int index) {
    setState(() {
      final slots = _defaultAvailability[day] ?? [];
      if (index < slots.length) {
        slots.removeAt(index);
        _defaultAvailability[day] = slots;
      }
    });
  }

  Future<void> _selectTime(BuildContext context, String day, int index, bool isStart) async {
    final slots = _defaultAvailability[day] ?? [];
    if (index >= slots.length) return;
    
    final currentStr = isStart ? slots[index]['start']! : slots[index]['end']!;
    final parts = currentStr.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );

    final picked = await showTimePicker(context: context, initialTime: initialTime);
    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          slots[index]['start'] = formatted;
        } else {
          slots[index]['end'] = formatted;
        }
      });
    }
  }

  Future<void> _addBlockDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final str = DateFormat('yyyy-MM-dd').format(picked);
      if (!_blockDates.contains(str)) {
        setState(() {
          _blockDates.add(str);
          _blockDates.sort();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Calendar & Availability',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _saving ? null : _saveSettings,
              icon: _saving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple))
                  : const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: AppColors.purple),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.purple,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.purple,
          tabs: const [
            Tab(text: 'Weekly Schedule'),
            Tab(text: 'Block Dates & Settings'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildScheduleTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildScheduleTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _days.length,
      itemBuilder: (context, index) {
        final day = _days[index];
        final slots = _defaultAvailability[day] ?? [];

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                    ),
                    TextButton.icon(
                      onPressed: () => _addSlot(day),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Slot', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.purple),
                    ),
                  ],
                ),
                if (slots.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Unavailable on this day', style: TextStyle(color: AppColors.textLight, fontSize: 13, fontStyle: FontStyle.italic)),
                  )
                else
                  Column(
                    children: List.generate(slots.length, (slotIndex) {
                      final slot = slots[slotIndex];
                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 16, color: AppColors.purple),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _selectTime(context, day, slotIndex, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                child: Text(slot['start']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('to', style: TextStyle(color: AppColors.textLight)),
                            ),
                            InkWell(
                              onTap: () => _selectTime(context, day, slotIndex, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                child: Text(slot['end']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                              onPressed: () => _removeSlot(day, slotIndex),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Block dates card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.event_busy_rounded, color: AppColors.purple, size: 20),
                        SizedBox(width: 8),
                        Text('Block-out Dates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _addBlockDate,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Date'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_blockDates.isEmpty)
                  const Text('No blocked dates added.', style: TextStyle(color: AppColors.textLight, fontSize: 13))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _blockDates.map((dateStr) {
                      return Chip(
                        backgroundColor: AppColors.error.withValues(alpha: 0.08),
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.2)),
                        label: Text(dateStr, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13)),
                        deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.error),
                        onDeleted: () {
                          setState(() => _blockDates.remove(dateStr));
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // General settings card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('General Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                
                // Timezone
                const Text('Timezone', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _timezone,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Asia/Kolkata', child: Text('Asia/Kolkata (IST)')),
                    DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                    DropdownMenuItem(value: 'America/New_York', child: Text('America/New_York (EST)')),
                    DropdownMenuItem(value: 'Europe/London', child: Text('Europe/London (GMT)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _timezone = val);
                  },
                ),
                const SizedBox(height: 16),

                // Reschedule Policy
                const Text('Reschedule Policy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _reschedulePolicy,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: '24 hours prior', child: Text('24 hours prior')),
                    DropdownMenuItem(value: '12 hours prior', child: Text('12 hours prior')),
                    DropdownMenuItem(value: '48 hours prior', child: Text('48 hours prior')),
                    DropdownMenuItem(value: 'Flexible', child: Text('Flexible (Anytime)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _reschedulePolicy = val);
                  },
                ),
                const SizedBox(height: 16),

                // Booking Period
                const Text('Booking Window (Months ahead)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: _bookingPeriodMonths,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 Month ahead')),
                    DropdownMenuItem(value: 2, child: Text('2 Months ahead')),
                    DropdownMenuItem(value: 3, child: Text('3 Months ahead')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _bookingPeriodMonths = val);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
