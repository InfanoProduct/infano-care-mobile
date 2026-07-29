import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/mood_wheel.dart';
import 'package:intl/intl.dart';

class DailyLogScreen extends StatefulWidget {
  final DateTime date;
  const DailyLogScreen({super.key, required this.date});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _selectableDates;

  String? _flow;
  String? _vaginalDischarge;
  final Set<String> _symptoms = {};
  int _crampIntensity = 1;
  MoodState? _selectedMood;
  int _energy = 3;
  double _sleepDuration = 8.0;
  int _sleepQuality = 3;
  final List<String> _nutrition = [];
  final List<String> _activity = [];
  final TextEditingController _noteController = TextEditingController();

  bool _showAdvanced = false;
  bool _isSaving = false;
  CycleLogModel? _originalLog;
  bool _isPeriodEndToggled = false;

  final ScrollController _dateScrollController = ScrollController();

  void _loadLogForDate(DateTime date, List<CycleLogModel> logs) {
    // Reset to defaults first
    _flow = null;
    _vaginalDischarge = null;
    _symptoms.clear();
    _crampIntensity = 1;
    _selectedMood = null;
    _energy = 3;
    _sleepDuration = 8.0;
    _sleepQuality = 3;
    _nutrition.clear();
    _activity.clear();
    _noteController.clear();
    _showAdvanced = false;

    debugPrint('[DailyLog] Loading logs for date: $date (Day: ${date.day})');
    debugPrint('[DailyLog] Total logs available: ${logs.length}');

    final log = logs.firstWhereOrNull((l) {
      final logUtc = l.date.toUtc();
      final matches = logUtc.year == date.year && logUtc.month == date.month && logUtc.day == date.day;
      if (matches) {
        debugPrint('[DailyLog] Found matching log for ${logUtc.toIso8601String()}');
      }
      return matches;
    });

    _originalLog = log;

    if (log == null) {
      debugPrint('[DailyLog] No log found for date: ${date.toIso8601String()}');
    } else {
      debugPrint('[DailyLog] Log found! Flow: ${log.flow}, Symptoms: ${log.symptoms.length}');
      _flow = log.flow;
      _vaginalDischarge = log.vaginalDischarge;
      _symptoms.addAll(log.symptoms);
      _crampIntensity = log.crampIntensity ?? 1;
      _energy = log.energyLevel ?? 3;
      _sleepDuration = log.sleepHours ?? 8.0;
      _sleepQuality = log.sleepQuality ?? 3;
      _nutrition.addAll(log.nutritionTags);
      _activity.addAll(log.activityTags);
      _noteController.text = log.noteText ?? '';
      
      if (log.moodPrimary != null) {
        // Find the full MoodState from the definition list to ensure symbols/colors are correct
        _selectedMood = MoodWheel.moods.firstWhereOrNull((m) => m.id == log.moodPrimary);
      }

      if ((log.energyLevel != null && log.energyLevel != 3) || 
          (log.sleepHours != null && log.sleepHours != 8.0) || 
          (log.noteText?.isNotEmpty ?? false) ||
          _nutrition.isNotEmpty ||
          _activity.isNotEmpty) {
        _showAdvanced = true;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date;
    _noteController.addListener(_onNoteChanged);
    
    // Generate 7 days centered around the selected date (or ending at it if it's today)
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(_selectedDate, now);
    
    if (isToday) {
      _selectableDates = List.generate(7, (i) => now.subtract(Duration(days: i))).reversed.toList();
    } else {
      // Center around the selected date
      _selectableDates = List.generate(7, (i) => _selectedDate.add(Duration(days: i - 3))).toList();
      // Ensure we don't show future dates beyond today
      _selectableDates = _selectableDates.where((d) => d.isBefore(now.add(const Duration(days: 1)))).toList();
    }
    
    // Initial load from Bloc state using current state
    final state = context.read<TrackerBloc>().state;
    state.maybeWhen(
      loaded: (profile, prediction, logs, history, dailyInsights, articles, milestone, pointsEarned, isRefreshing) => _loadLogForDate(_selectedDate, logs),
      orElse: () {},
    );

    // Scroll to the rightmost (today) item after the first frame so it's always visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateScrollController.hasClients) {
        _dateScrollController.animateTo(
          _dateScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onNoteChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _symptomList = [
    {'id': 'cramps', 'name': 'Cramps', 'emoji': '😣'},
    {'id': 'bloating', 'name': 'Bloating', 'emoji': '🎈'},
    {'id': 'headache', 'name': 'Headache', 'emoji': '🤕'},
    {'id': 'fatigue', 'name': 'Fatigue', 'emoji': '🥱'},
    {'id': 'breast_tenderness', 'name': 'Breast tenderness', 'emoji': '👙'},
    {'id': 'acne', 'name': 'Acne', 'emoji': '✨'},
    {'id': 'nausea', 'name': 'Nausea', 'emoji': '🤢'},
    {'id': 'back_pain', 'name': 'Back pain', 'emoji': '🩹'},
    {'id': 'mood_swings', 'name': 'Mood swings', 'emoji': '🎭'},
    {'id': 'cravings', 'name': 'Food cravings', 'emoji': '🍩'},
  ];

  bool _showSuccessOverlay = false;
  int _pointsEarned = 0;

  void _save() {
    setState(() {
      _isSaving = true;
      // Don't show overlay yet — wait for BLoC to confirm success
    });

    final dateToSend = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 12, 0, 0);

    final data = {
      'date': dateToSend.toUtc().toIso8601String(),
      if (_flow != null) 'flow': _flow,
      'symptoms': _symptoms.toList(),
      if (_symptoms.contains('cramps')) 'crampIntensity': _crampIntensity,
      if (_selectedMood != null) 'moodPrimary': _selectedMood!.id,
      'energyLevel': _energy,
      'sleepHours': _sleepDuration,
      'sleepQuality': _sleepQuality,
      'nutritionTags': _nutrition,
      'activityTags': _activity,
      if (_noteController.text.isNotEmpty) 'noteText': _noteController.text,
      if (_vaginalDischarge != null) 'vaginalDischarge': _vaginalDischarge,
    };

    context.read<TrackerBloc>().add(TrackerEvent.logDaily(data));
  }


  Widget _buildDischargeSection() {
    const dischargeOptions = [
      {'id': 'No discharge',  'emoji': '✅'},
      {'id': 'Creamy',        'emoji': '🤍'},
      {'id': 'Watery',        'emoji': '💧'},
      {'id': 'Sticky',        'emoji': '🍯'},
      {'id': 'Egg white',     'emoji': '🥚'},
      {'id': 'Clumpy white',  'emoji': '❄️'},
      {'id': 'Spotting',      'emoji': '🩸'},
      {'id': 'Unusual',       'emoji': '⚠️'},
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5), // Soft Mint background
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA7F3D0).withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💧 Vaginal Discharge',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF065F46), // Dark mint text
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Discharge tells a lot about your cycle phase.',
                style: GoogleFonts.nunito(color: const Color(0xFF0D9488), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: dischargeOptions.map((opt) {
                  final id = opt['id']!;
                  final emoji = opt['emoji']!;
                  final isSelected = _vaginalDischarge == id;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _vaginalDischarge = isSelected ? null : id;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? AppColors.teal : const Color(0xFFA7F3D0),
                          width: isSelected ? 2.5 : 1.2,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: AppColors.teal.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            id,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppColors.teal : const Color(0xFF0D9488),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 120.ms, duration: 350.ms).slideX(begin: 0.05, end: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bloom Daily Log',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textDark),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<TrackerBloc, TrackerState>(
        listener: (context, state) {
          state.maybeWhen(
            loaded: (profile, prediction, logs, history, dailyInsights, articles, milestone, pointsEarned, isRefreshing) {
              if (_isSaving) {
                // Save confirmed by backend — show success and reload logged data
                setState(() {
                  _isSaving = false;
                  _pointsEarned = pointsEarned;
                  _showSuccessOverlay = true;
                  _loadLogForDate(_selectedDate, logs);
                });
                if (milestone == 'first_period') {
                  debugPrint('[DailyLog] Milestone! Letting milestone screen handle navigation.');
                } else {
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                }
              } else {
                // Normal reload when not saving (e.g. date switch)
                setState(() => _loadLogForDate(_selectedDate, logs));
              }
            },
            error: (message) {
              if (_isSaving) {
                setState(() => _isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not save log: $message'),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          // Derive current cycle phase from the backend prediction data.
          String currentPhase = 'waiting';
          DateTime? lastPeriodStart;
          state.maybeWhen(
            loaded: (profile, prediction, logs, history, dailyInsights, articles, milestone, pointsEarned, isRefreshing) {
              currentPhase = profile.currentPhase ?? 'waiting';
              lastPeriodStart = profile.lastPeriodStart;
            },
            orElse: () {},
          );

          final bool showFlow = currentPhase == 'menstrual' || currentPhase == 'delayed' || currentPhase == 'waiting';
          final bool showDischarge = currentPhase != 'menstrual' && currentPhase != 'delayed';

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildDateSelector(),
                  _buildHeading(),
                  if (showFlow) _buildFlowSection(currentPhase == 'menstrual', lastPeriodStart),
                  // Symptoms always visible
                  _buildSymptomsSection(),
                  _buildMoodSection(),
                  if (showDischarge) _buildDischargeSection(),
                  _buildAdvancedToggle(),
                  if (_showAdvanced) ...[
                    _buildEnergySection(),
                    _buildSleepSection(),
                    _buildNoteSection(),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
              if (!_showSuccessOverlay && _hasPendingChanges()) _buildSaveButton(),
              if (_showSuccessOverlay) _buildSuccessOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeading() {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 28),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you today?',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8), // Proper space between title and subtitle
            Text(
              "Your body has its own language. Let's record it 💜",
              style: GoogleFonts.nunito(
                color: AppColors.textMedium,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withValues(alpha: 0.9),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌸', style: TextStyle(fontSize: 80)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              _pointsEarned > 0 ? '+$_pointsEarned Points Logged!' : 'Log Saved!',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.purple),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            Text(
              _pointsEarned > 0 ? 'Gigi is so proud of you! ✨' : 'Keep tracking your cycle 💜',
              style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 16),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowSection(bool isMenstrual, DateTime? periodStart) {
    final flowOptions = ['None', 'Spotting', 'Light', 'Medium', 'Heavy', 'Ended', 'Clotting'];
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2F8), // Soft Pink background
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFBCFE8).withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🩸 Period Flow',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF9E1B4B), // Dark pink text
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: flowOptions.map((option) {
                  final isSelected = _flow == option.toLowerCase();
                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _flow = val ? option.toLowerCase() : null),
                    selectedColor: AppColors.pink,
                    labelStyle: GoogleFonts.nunito(
                      color: isSelected ? Colors.white : const Color(0xFF9E1B4B),
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected ? AppColors.pink : const Color(0xFFFBCFE8),
                        width: 1.2,
                      ),
                    ),
                    backgroundColor: Colors.white.withOpacity(0.6),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              if (isMenstrual && periodStart != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBCFE8).withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Text('🌸', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mark today as period end?',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: const Color(0xFF9E1B4B), // Dark pink text
                                    ),
                                  ),
                                  Text(
                                    'This completes your period logging',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFDB2777), // Medium pink
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isPeriodEndToggled,
                        activeColor: AppColors.pink, // Hard pink switch color
                        onChanged: (val) {
                          setState(() {
                            _isPeriodEndToggled = val;
                          });
                          if (val) {
                            _showPeriodEndConfirmation(context, periodStart);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
      ),
    );
  }

  void _showPeriodEndConfirmation(BuildContext context, DateTime startDate) {
    final endDate = _selectedDate;
    final startStr = DateFormat('MMMM d, yyyy').format(startDate);
    final endStr = DateFormat('MMMM d, yyyy').format(endDate);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFDF2F8), // Soft Pink background
              surfaceTintColor: const Color(0xFFFDF2F8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
              title: Row(
                children: [
                  const Text('🌸', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    'Confirm Period End',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: const Color(0xFF9E1B4B), // Dark pink text
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to end your period? Here is your recorded period range:',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6), // Transparent white content area
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFBCFE8).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDialogDateRow('Start Date', startStr, AppColors.pink), // Hard pink date text
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Color(0xFFFBCFE8), height: 1),
                        ),
                        _buildDialogDateRow('End Date', endStr, AppColors.pink), // Hard pink date text
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                if (!isSubmitting)
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      setState(() {
                        _isPeriodEndToggled = false;
                      });
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF9E1B4B), // Dark pink cancel button text
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    setDialogState(() {
                      isSubmitting = true;
                    });
                    await _confirmPeriodEnd(startDate, endDate, dialogCtx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pink, // Hard pink confirm button
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Confirm',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w900),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogDateRow(String label, String dateText, Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textMedium,
          ),
        ),
        Text(
          dateText,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmPeriodEnd(DateTime start, DateTime end, BuildContext dialogCtx) async {
    setState(() => _isSaving = true);
    try {
      context.read<TrackerBloc>().add(TrackerEvent.updatePeriodRange(start, end));
      
      // Give a delay for async operations / backend prediction engine to execute
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isPeriodEndToggled = false;
        });
        
        if (dialogCtx.mounted) {
          Navigator.of(dialogCtx).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Period end date confirmed! predictions updated. 🌸',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppColors.purple,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(); // Close the daily log sheet
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isPeriodEndToggled = false;
        });
        
        if (dialogCtx.mounted) {
          Navigator.of(dialogCtx).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update period end: $e',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSymptomsSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF), // Soft Indigo background
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC7D2FE).withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '😣 How does your body feel?',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF312E81), // Dark indigo text
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // "None" option
                  GestureDetector(
                    onTap: () => setState(() => _symptoms.clear()),
                    child: Column(
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: _symptoms.isEmpty ? Colors.white : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _symptoms.isEmpty ? AppColors.purple : const Color(0xFFC7D2FE),
                              width: _symptoms.isEmpty ? 2.5 : 1.2,
                            ),
                          ),
                          child: const Center(child: Text('🌈', style: TextStyle(fontSize: 28))),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'None',
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            color: _symptoms.isEmpty ? AppColors.purple : const Color(0xFF4F46E5),
                            fontWeight: _symptoms.isEmpty ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._symptomList.map((symptom) {
                    final isSelected = _symptoms.contains(symptom['id']);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (isSelected) {
                          _symptoms.remove(symptom['id']);
                        } else {
                          _symptoms.add(symptom['id']!);
                        }
                      }),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.purple : const Color(0xFFC7D2FE),
                                width: isSelected ? 2.5 : 1.2,
                              ),
                            ),
                            child: Center(child: Text(symptom['emoji']!, style: const TextStyle(fontSize: 28))),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            symptom['name']!,
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              color: isSelected ? AppColors.purple : const Color(0xFF4F46E5),
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              if (_symptoms.contains('cramps')) ...[
                const SizedBox(height: 20),
                Text(
                  'How intense are the cramps?',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF312E81),
                  ),
                ),
                Slider(
                  value: _crampIntensity.toDouble(),
                  min: 1, max: 5, divisions: 4,
                  label: _crampIntensity.toString(),
                  activeColor: AppColors.purple,
                  inactiveColor: const Color(0xFFC7D2FE),
                  onChanged: (val) => setState(() => _crampIntensity = val.round()),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildMoodSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF), // Soft Violet background
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDDD6FE).withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💜 Your emotional mood',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4C1D95), // Dark violet text
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap the wheel to select how you feel.',
                style: GoogleFonts.nunito(
                  color: const Color(0xFF7C3AED),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: MoodWheel(
                    initialMood: _selectedMood,
                    onMoodSelected: (mood) => setState(() => _selectedMood = mood),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildAdvancedToggle() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
            icon: Icon(_showAdvanced ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            label: Text(_showAdvanced ? 'Show less' : 'More health details (Energy, Sleep, Note)'),
            style: TextButton.styleFrom(foregroundColor: AppColors.purple),
          ).animate().fadeIn(delay: 400.ms),
        ),
      ),
    );
  }

  Widget _buildEnergySection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB), // Soft Amber background
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFDE68A).withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚡ Energy level',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF92400E), // Dark amber text
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(_getEnergyStatus(), style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: const Color(0xFFD97706), fontSize: 13)),
                  const Spacer(),
                  Text(_getEnergyEmoji(), style: const TextStyle(fontSize: 20)),
                ],
              ),
              Slider(
                value: _energy.toDouble(),
                min: 1, max: 5, divisions: 4,
                activeColor: const Color(0xFFD97706), // Amber slider active
                inactiveColor: const Color(0xFFFDE68A),
                onChanged: (val) => setState(() => _energy = val.round()),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }

  Widget _buildSleepSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF), // Soft Indigo background
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC7D2FE).withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '😴 Sleep duration',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF312E81), // Dark indigo text
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(_getSleepStatus(), style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: const Color(0xFF4F46E5), fontSize: 13)),
                  const Spacer(),
                  Text('${_sleepDuration.toStringAsFixed(1)}h', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: const Color(0xFF4F46E5))),
                ],
              ),
              Slider(
                value: _sleepDuration,
                min: 2, max: 12, divisions: 20,
                activeColor: const Color(0xFF4F46E5), // Indigo active slider
                inactiveColor: const Color(0xFFC7D2FE),
                onChanged: (val) => setState(() => _sleepDuration = val),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
      ),
    );
  }

  Widget _buildNoteSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDailyNoteCard(),
            const SizedBox(height: 16),
            _buildNutritionCard(),
            const SizedBox(height: 16),
            _buildActivityCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyNoteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF), // Soft Violet background
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDDD6FE).withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📝 Daily Note',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF4C1D95), // Dark violet text
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Anything else worth noting? (Only you can read this 🔒)',
              hintStyle: GoogleFonts.nunito(color: const Color(0xFF7C3AED).withOpacity(0.6), fontSize: 13),
              fillColor: Colors.white.withOpacity(0.6),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.purple, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    final options = [
      {'id': 'healthy', 'name': 'Balanced', 'emoji': '🥗'},
      {'id': 'cravings', 'name': 'Cravings', 'emoji': '🍩'},
      {'id': 'light', 'name': 'Light', 'emoji': '🍎'},
      {'id': 'heavy', 'name': 'Heavy', 'emoji': '🍝'},
      {'id': 'fast_food', 'name': 'Fast Food', 'emoji': '🍔'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5), // Soft Mint background
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA7F3D0).withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🍎 Nutrition',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF065F46), // Dark mint text
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final opt = options[index];
                final isSelected = _nutrition.contains(opt['id']);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _nutrition.remove(opt['id']);
                    } else {
                      _nutrition.add(opt['id']!);
                    }
                  }),
                  child: Column(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.teal : const Color(0xFFA7F3D0),
                            width: isSelected ? 2.5 : 1.2,
                          ),
                        ),
                        child: Center(child: Text(opt['emoji']!, style: const TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opt['name']!,
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          color: isSelected ? AppColors.teal : const Color(0xFF0D9488),
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    final options = [
      {'id': 'yoga', 'name': 'Yoga', 'emoji': '🧘'},
      {'id': 'walking', 'name': 'Walking', 'emoji': '🚶'},
      {'id': 'gym', 'name': 'Gym', 'emoji': '🏋️'},
      {'id': 'running', 'name': 'Running', 'emoji': '🏃'},
      {'id': 'rest', 'name': 'Rest Day', 'emoji': '😴'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF), // Soft Indigo background
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC7D2FE).withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏃 Activity',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF312E81), // Dark indigo text
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final opt = options[index];
                final isSelected = _activity.contains(opt['id']);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _activity.remove(opt['id']);
                    } else {
                      _activity.add(opt['id']!);
                    }
                  }),
                  child: Column(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.purple : const Color(0xFFC7D2FE),
                            width: isSelected ? 2.5 : 1.2,
                          ),
                        ),
                        child: Center(child: Text(opt['emoji']!, style: const TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opt['name']!,
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          color: isSelected ? AppColors.purple : const Color(0xFF4F46E5),
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getEnergyStatus() {
    return switch (_energy) {
      1 => 'Very Tired',
      2 => 'Low Energy',
      3 => 'Neutral',
      4 => 'Energetic',
      5 => 'Peak Performance',
      _ => 'Neutral',
    };
  }

  String _getEnergyEmoji() {
    return switch (_energy) {
      1 => '🥱',
      2 => '😑',
      3 => '😐',
      4 => '😊',
      5 => '⚡',
      _ => '😐',
    };
  }

  String _getSleepStatus() {
    if (_sleepDuration < 5) {
      return 'Restless/Short';
    }
    if (_sleepDuration < 7) {
      return 'Below Ideal';
    }
    if (_sleepDuration < 9) {
      return 'Optimal Rest ✨';
    }
    return 'Long Rest';
  }

  bool _hasPendingChanges() {
    final orig = _originalLog;
    if (orig == null) {
      // For a new log, show Save CTA only if at least one field has been modified from default values
      final bool flowChanged = _flow != null;
      final bool dischargeChanged = _vaginalDischarge != null;
      final bool symptomsChanged = _symptoms.isNotEmpty;
      final bool crampChanged = _crampIntensity != 1;
      final bool moodChanged = _selectedMood != null;
      final bool energyChanged = _energy != 3;
      final bool sleepDurationChanged = _sleepDuration != 8.0;
      final bool sleepQualityChanged = _sleepQuality != 3;
      final bool noteChanged = _noteController.text.trim().isNotEmpty;

      return flowChanged ||
          dischargeChanged ||
          symptomsChanged ||
          crampChanged ||
          moodChanged ||
          energyChanged ||
          sleepDurationChanged ||
          sleepQualityChanged ||
          noteChanged;
    } else {
      // For an existing log, check if any field is modified from the saved record
      final bool flowChanged = _flow != orig.flow;
      final bool dischargeChanged = _vaginalDischarge != orig.vaginalDischarge;
      
      // Compare sets of symptoms
      final bool symptomsChanged = !const SetEquality().equals(_symptoms, orig.symptoms.toSet());
      
      final bool crampChanged = _crampIntensity != (orig.crampIntensity ?? 1);
      final bool moodChanged = _selectedMood?.id != orig.moodPrimary;
      final bool energyChanged = _energy != (orig.energyLevel ?? 3);
      final bool sleepDurationChanged = _sleepDuration != (orig.sleepHours ?? 8.0);
      final bool sleepQualityChanged = _sleepQuality != (orig.sleepQuality ?? 3);
      final bool noteChanged = _noteController.text.trim() != (orig.noteText ?? '').trim();

      return flowChanged ||
          dischargeChanged ||
          symptomsChanged ||
          crampChanged ||
          moodChanged ||
          energyChanged ||
          sleepDurationChanged ||
          sleepQualityChanged ||
          noteChanged;
    }
  }

  Widget _buildSaveButton() {
    return Positioned(
      bottom: 40,
      left: 24, right: 24,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 5))],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          onPressed: _isSaving ? null : _save,
          child: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('Save My Log 🌸', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      sliver: SliverToBoxAdapter(
        child: SizedBox(
          height: 80,
          child: ListView.builder(
            controller: _dateScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _selectableDates.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final date = _selectableDates[index];
              final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    final state = context.read<TrackerBloc>().state;
                    state.maybeWhen(
                      loaded: (profile, prediction, logs, history, dailyInsights, articles, milestone, pointsEarned, isRefreshing) => _loadLogForDate(_selectedDate, logs),
                      orElse: () {},
                    );
                  });
                },
                child: Container(
                  width: 56,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.purple : const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.purple.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                        : [BoxShadow(color: const Color(0xFFDDD6FE).withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdays[date.weekday - 1][0],
                        style: GoogleFonts.nunito(
                          color: isSelected ? Colors.white70 : const Color(0xFF7C3AED),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: GoogleFonts.nunito(
                          color: isSelected ? Colors.white : const Color(0xFF5B21B6),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
