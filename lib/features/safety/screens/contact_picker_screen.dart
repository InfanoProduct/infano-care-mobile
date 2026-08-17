import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/features/safety/data/safety_repository.dart';

const List<Map<String, String>> kRelations = [
  {'label': 'Parent', 'emoji': '👨‍👩‍👧'},
  {'label': 'Sibling', 'emoji': '👫'},
  {'label': 'Friend', 'emoji': '👯'},
  {'label': 'Teacher', 'emoji': '📚'},
  {'label': 'Relative', 'emoji': '👪'},
  {'label': 'Other', 'emoji': '🤝'},
];

class ContactPickerScreen extends StatefulWidget {
  final bool fromWizard;
  const ContactPickerScreen({super.key, this.fromWizard = false});

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  late final SafetyRepository _repo;
  List<dynamic> _contacts = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repo = SafetyRepository(ApiService.instance.dio);
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final contacts = await _repo.getTrustedContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load contacts: $e')),
        );
      }
    }
  }

  Future<void> _pickFromPhoneContacts() async {
    if (_contacts.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 5 trusted contacts.')),
      );
      return;
    }

    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Contacts permission denied. Grant it in Settings to pick contacts.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    try {
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null || !mounted) return;

      final full = await FlutterContacts.getContact(contact.id,
          withProperties: true);
      if (full == null || full.phones.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${full?.displayName ?? 'Contact'} has no phone number saved.')),
          );
        }
        return;
      }

      String? selectedPhone;
      if (full.phones.length == 1) {
        selectedPhone = full.phones.first.number.replaceAll(' ', '');
      } else {
        selectedPhone = await _showPhonePickerDialog(
          full.displayName,
          full.phones.map((p) => p.number.replaceAll(' ', '')).toList(),
        );
      }

      if (selectedPhone == null || !mounted) return;

      String normalizedPhone = selectedPhone;
      if (!normalizedPhone.startsWith('+')) {
        if (normalizedPhone.length == 10) {
          normalizedPhone = '+91$normalizedPhone';
        } else if (normalizedPhone.startsWith('0')) {
          normalizedPhone = '+91${normalizedPhone.substring(1)}';
        }
      }

      await _showConfirmContactSheet(
        name: full.displayName,
        phone: normalizedPhone,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open contacts: $e')),
        );
      }
    }
  }

  Future<String?> _showPhonePickerDialog(
      String name, List<String> phones) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Choose Phone Number',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: phones
              .map((phone) => ListTile(
                    leading: const Icon(Icons.phone_outlined,
                        color: AppColors.purple),
                    title: Text(
                      phone,
                      style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => Navigator.pop(ctx, phone),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold, color: AppColors.textMedium),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmContactSheet({
    required String name,
    required String phone,
    bool isManual = false,
  }) async {
    final nameCtrl = TextEditingController(text: name);
    final phoneCtrl =
        TextEditingController(text: isManual ? '' : phone);
    String selectedRelation = 'Friend';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  isManual ? 'Add Manually' : 'Confirm Contact Details',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'They will receive an SMS notifying them they are set up to protect you.',
                  style: GoogleFonts.nunito(
                      fontSize: 14, color: AppColors.textMedium),
                ),
                const SizedBox(height: 24),

                // Name field
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                  ),
                ),
                const SizedBox(height: 16),

                // Phone field
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  readOnly: !isManual,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_android_rounded),
                    filled: true,
                    fillColor: isManual
                        ? const Color(0xFFF9FAFB)
                        : Colors.grey.shade100,
                    helperText: isManual
                        ? 'Include country code, e.g. +91XXXXXXXXXX'
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                // Relation chips
                Text(
                  'THEIR RELATION TO YOU',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: AppColors.textLight,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kRelations.map((rel) {
                    final isSelected = selectedRelation == rel['label'];
                    return GestureDetector(
                      onTap: () => setSheetState(
                          () => selectedRelation = rel['label']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
                              : null,
                          color: isSelected ? null : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.purple.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          '${rel['emoji']} ${rel['label']}',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: isSelected ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final finalName = nameCtrl.text.trim();
                      final finalPhone = isManual
                          ? phoneCtrl.text.trim()
                          : phone;

                      if (finalName.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Please enter a name.')),
                        );
                        return;
                      }
                      if (finalPhone.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter a phone number.')),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      await _saveContact(finalName, finalPhone, selectedRelation);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(
                      'Add Contact & Notify Them 🚀',
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _saveContact(
      String name, String phone, String relation) async {
    setState(() => _isSaving = true);
    try {
      await _repo.addTrustedContact(name, phone, relation);
      await _loadContacts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added! They\'ve been notified via SMS 📬'),
            backgroundColor: AppColors.purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add contact: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteContact(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Remove Contact?',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
        ),
        content: Text(
          '$name will no longer receive emergency alerts from you.',
          style: GoogleFonts.nunito(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold, color: AppColors.textMedium),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _repo.deleteTrustedContact(id);
      await _loadContacts();
    }
  }

  String _consentBadge(String status, DateTime? sentAt) {
    switch (status) {
      case 'ACCEPTED':
        return '✅ Accepted';
      case 'DECLINED':
        return '❌ Declined';
      default:
        return sentAt != null ? '📬 Notified' : '⏳ Pending';
    }
  }

  Color _consentColor(String status) {
    switch (status) {
      case 'ACCEPTED':
        return Colors.green;
      case 'DECLINED':
        return AppColors.error;
      default:
        return AppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWizard = widget.fromWizard;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      appBar: AppBar(
        title: Text(
          isWizard ? 'Add Trusted People' : 'Trusted Contacts',
          style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900, color: AppColors.textDark),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.purple.withOpacity(0.1),
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isSaving
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Adding contact & sending notification...'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Premium Ambient Tip Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.purple.withOpacity(0.08),
                            AppColors.pink.withOpacity(0.05)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.purple.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'When you press SOS, these people get an instant alert with your live location. Add up to ${5 - _contacts.length} more.',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppColors.textMedium,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Modern Selection Cards
                    if (_contacts.length < 5)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _AddOptionCard(
                                emoji: '📱',
                                label: 'Import Phone',
                                sublabel: 'Pick from book',
                                color: AppColors.purple,
                                onTap: _pickFromPhoneContacts,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AddOptionCard(
                                emoji: '✏️',
                                label: 'Manual Add',
                                sublabel: 'Type detail',
                                color: const Color(0xFF0D9488),
                                onTap: () => _showConfirmContactSheet(
                                  name: '',
                                  phone: '',
                                  isManual: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade(duration: 350.ms).slideY(begin: 0.1),

                    // Contacts List Panel
                    Expanded(
                      child: _contacts.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _contacts.length,
                              itemBuilder: (context, index) {
                                final c = _contacts[index];
                                final name = c['name'] as String;
                                final phone = c['phone'] as String;
                                final relation =
                                    c['relation'] as String? ?? 'Friend';
                                final consentStatus =
                                    c['consentStatus'] as String? ?? 'PENDING';
                                final consentSentAt = c['consentSentAt'] != null
                                    ? DateTime.parse(c['consentSentAt'])
                                    : null;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.purple.withOpacity(0.08)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Contact Icon Avatar
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: AppColors.purple
                                            .withOpacity(0.08),
                                        child: Text(
                                          name.substring(0, 1).toUpperCase(),
                                          style: GoogleFonts.nunito(
                                            color: AppColors.purple,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            Text(
                                              '$relation • $phone',
                                              style: GoogleFonts.nunito(
                                                fontSize: 13,
                                                color: AppColors.textMedium,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            // Glassmorphic status dot indicator
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _consentColor(consentStatus)
                                                    .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: _consentColor(
                                                          consentStatus),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _consentBadge(consentStatus,
                                                        consentSentAt),
                                                    style: GoogleFonts.nunito(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w900,
                                                      color: _consentColor(
                                                          consentStatus),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.error,
                                          size: 22,
                                        ),
                                        onPressed: () =>
                                            _deleteContact(c['id'], name),
                                      ),
                                    ],
                                  ),
                                )
                                    .animate()
                                    .fade(delay: (index * 80).ms)
                                    .slideX(begin: 0.05);
                              },
                            ),
                    ),

                    // Setup wizard continue button
                    if (isWizard && _contacts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => context.push('/safety/setup-type?wizard=true'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue to Step 2',
                                  style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fade(delay: 200.ms),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👥', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'No Contacts Added Yet',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add at least one person who should\nbe notified during an emergency.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 14, color: AppColors.textMedium, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFromPhoneContacts,
                  icon: const Icon(Icons.contacts_rounded, size: 18),
                  label: const Text('From Phone'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showConfirmContactSheet(
                      name: '', phone: '', isManual: true),
                  icon: const Icon(Icons.edit_note_rounded,
                      size: 20, color: AppColors.purple),
                  label: const Text('Manual Entry',
                      style: TextStyle(color: AppColors.purple)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.purple, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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

// ─── Add Option Card widget ───────────────────────────────────────────────────

class _AddOptionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _AddOptionCard({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
