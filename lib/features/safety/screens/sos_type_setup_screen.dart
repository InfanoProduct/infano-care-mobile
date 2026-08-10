import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/features/safety/data/safety_repository.dart';

const List<Map<String, dynamic>> kEmergencyTypes = [
  {
    'id': 'physical_threat',
    'label': 'Physical Threat / Harassment',
    'desc': 'Immediate danger, feeling unsafe, being followed',
    'emoji': '🚨',
    'color': Color(0xFFDC2626),
    'bgColor': Color(0xFFFFF1F2),
    'gradient': [Color(0xFFEF4444), Color(0xFFB91C1C)],
  },
  {
    'id': 'medical_emergency',
    'label': 'Medical Emergency',
    'desc': 'Injury, severe illness, accident',
    'emoji': '🚑',
    'color': Color(0xFFD97706),
    'bgColor': Color(0xFFFFFBEB),
    'gradient': [Color(0xFFF59E0B), Color(0xFFB45309)],
  },
  {
    'id': 'mental_distress',
    'label': 'Mental / Emotional Crisis',
    'desc': 'Panic attack, extreme distress, crisis support',
    'emoji': '🧠',
    'color': Color(0xFF7C3AED),
    'bgColor': Color(0xFFF5F3FF),
    'gradient': [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
  },
  {
    'id': 'safe_walk',
    'label': 'Safe Walk Check-In',
    'desc': 'Walking alone, need someone to track your path',
    'emoji': '🚶',
    'color': Color(0xFF0D9488),
    'bgColor': Color(0xFFF0FDFA),
    'gradient': [Color(0xFF14B8A6), Color(0xFF0F766E)],
  },
];

class SosTypeSetupScreen extends StatefulWidget {
  final bool fromWizard;
  const SosTypeSetupScreen({super.key, this.fromWizard = false});

  @override
  State<SosTypeSetupScreen> createState() => _SosTypeSetupScreenState();
}

class _SosTypeSetupScreenState extends State<SosTypeSetupScreen> {
  late final SafetyRepository _repo;
  String _selected = 'physical_threat';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repo = SafetyRepository(ApiService.instance.dio);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await _repo.getPreferences();
    if (mounted) {
      setState(() {
        _selected = prefs.defaultEmergencyType;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _repo.savePreferences(defaultEmergencyType: _selected);
      if (mounted) {
        if (widget.fromWizard) {
          context.push('/safety/test');
        } else {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Default alert style saved ✅'),
              backgroundColor: AppColors.purple,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWizard = widget.fromWizard;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      appBar: AppBar(
        title: Text(
          isWizard ? 'Step 2: Alert Style' : 'Default Alert Type',
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
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Alert style ambient tip
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
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
                                'Select your most likely emergency type. This is what your contacts will see first when you trigger SOS.',
                                style: GoogleFonts.nunito(
                                    fontSize: 13, color: AppColors.textMedium,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Custom selection cards
                      ...kEmergencyTypes.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final type = entry.value;
                        final isSelected = _selected == type['id'];
                        final color = type['color'] as Color;

                        return GestureDetector(
                          onTap: () => setState(() => _selected = type['id']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected ? color : Colors.white,
                                width: isSelected ? 2.5 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.15),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      )
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.015),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                            ),
                            child: Row(
                              children: [
                                // Ambient circle behind emoji
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isSelected
                                          ? (type['gradient'] as List<Color>)
                                          : [
                                              color.withOpacity(0.1),
                                              color.withOpacity(0.05)
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.25),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      type['emoji'],
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type['label'],
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        type['desc'],
                                        style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          color: AppColors.textMedium,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Select dot status indicator
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? color : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? color : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          size: 14, color: Colors.white)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fade(delay: (idx * 80).ms, duration: 350.ms)
                            .slideY(begin: 0.05);
                      }),
                    ],
                  ),
                ),

                // Premium stick bottom save button
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 24,
                        offset: const Offset(0, -8),
                      )
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isWizard ? 'Save & Continue' : 'Save Default Style',
                                  style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                                if (isWizard) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ],
                            ),
                    ),
                  ),
                ).animate().fade(delay: 300.ms),
              ],
            ),
    );
  }
}
