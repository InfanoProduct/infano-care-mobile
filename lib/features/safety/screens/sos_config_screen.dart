import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/features/safety/data/safety_repository.dart';

class SosConfigScreen extends StatefulWidget {
  const SosConfigScreen({super.key});

  @override
  State<SosConfigScreen> createState() => _SosConfigScreenState();
}

class _SosConfigScreenState extends State<SosConfigScreen> {
  final SafetyRepository _repository = SafetyRepository(ApiService.instance.dio);
  List<dynamic> _contacts = [];
  bool _isLoading = true;

  // Emergency Categories definition
  final List<Map<String, dynamic>> _emergencies = [
    {
      'id': 'physical_threat',
      'title': 'Physical Threat / Harassment',
      'icon': '🚨',
      'color': Colors.red,
      'desc': 'For immediate danger, stalking, or feeling unsafe.',
    },
    {
      'id': 'medical_emergency',
      'title': 'Medical Emergency',
      'icon': '🚑',
      'color': Colors.orange,
      'desc': 'For severe physical illness, injury, or accident.',
    },
    {
      'id': 'mental_distress',
      'title': 'Mental Distress Crisis',
      'icon': '🧠',
      'color': Colors.purple,
      'desc': 'For panic attacks or extreme mental distress.',
    },
    {
      'id': 'safe_walk',
      'title': 'Follow Me / Safe Walk',
      'icon': '🚶‍♀️',
      'color': Colors.teal,
      'desc': 'For walking alone at night and needing active check-ins.',
    },
  ];

  // Mapping of emergencyId -> List of contactIds
  Map<String, List<String>> _configMapping = {
    'physical_threat': [],
    'medical_emergency': [],
    'mental_distress': [],
    'safe_walk': [],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load contacts
      final contacts = await _repository.getTrustedContacts();
      
      // Reset config mapping
      _configMapping = {
        'physical_threat': [],
        'medical_emergency': [],
        'mental_distress': [],
        'safe_walk': [],
      };

      // Populate config mapping from backend-driven contact.emergencyTypes
      for (var contact in contacts) {
        final contactId = contact['id'] as String;
        final List<dynamic> types = contact['emergencyTypes'] ?? [];
        for (var type in types) {
          if (_configMapping[type] != null) {
            _configMapping[type]!.add(contactId);
          }
        }
      }

      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load SOS configuration: $e')),
        );
      }
    }
  }

  Future<void> _saveConfiguration() async {
    setState(() => _isLoading = true);
    try {
      // Save configuration by calling updateContactEmergencies for each contact
      for (var contact in _contacts) {
        final contactId = contact['id'] as String;
        final List<String> assignedTypes = [];
        _configMapping.forEach((emergId, contactIds) {
          if (contactIds.contains(contactId)) {
            assignedTypes.add(emergId);
          }
        });
        await _repository.updateContactEmergencies(contactId, assignedTypes);
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS Configuration Saved Successfully! ✅'),
            backgroundColor: AppColors.purple,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save configuration: $e')),
        );
      }
    }
  }

  void _toggleContactForEmergency(String emergencyId, String contactId) {
    setState(() {
      final currentList = _configMapping[emergencyId] ?? [];
      if (currentList.contains(contactId)) {
        currentList.remove(contactId);
      } else {
        currentList.add(contactId);
      }
      _configMapping[emergencyId] = currentList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'SOS Configuration',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: AppColors.purple),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.purple),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (!_isLoading && _contacts.isNotEmpty)
            TextButton(
              onPressed: _saveConfiguration,
              child: Text(
                'Save',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.purple,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '👥',
                          style: TextStyle(fontSize: 64),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Trusted Contacts Found',
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please add at least one trusted contact before configuring your emergency SOS settings.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            color: AppColors.textMedium,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/safety/contacts').then((_) => _loadData()),
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                          label: const Text('Add Trusted Contacts'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Text('🛡️', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personalized Emergency Contacts',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Choose which trusted contacts get notified for each type of emergency crisis.',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: AppColors.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._emergencies.map((emerg) {
                      final emergencyId = emerg['id'] as String;
                      final mappedContactIds = _configMapping[emergencyId] ?? [];

                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        margin: const EdgeInsets.only(bottom: 20),
                        child: ExpansionTile(
                          shape: const Border(),
                          leading: CircleAvatar(
                            backgroundColor: (emerg['color'] as Color).withValues(alpha: 0.1),
                            child: Text(
                              emerg['icon'],
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            emerg['title'],
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.textDark,
                            ),
                          ),
                          subtitle: Text(
                            emerg['desc'],
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: AppColors.textMedium,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.all(16),
                          initiallyExpanded: true,
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Text(
                              'Select contacts to notify:',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textMedium,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._contacts.map((contact) {
                              final contactId = contact['id'] as String;
                              final isSelected = mappedContactIds.contains(contactId);

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (_) => _toggleContactForEmergency(emergencyId, contactId),
                                activeColor: AppColors.purple,
                                title: Text(
                                  contact['name'],
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${contact['relation'] ?? 'Friend'} • ${contact['phone']}',
                                  style: GoogleFonts.nunito(fontSize: 12),
                                ),
                                contentPadding: EdgeInsets.zero,
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveConfiguration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save SOS Configuration',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
    );
  }
}
