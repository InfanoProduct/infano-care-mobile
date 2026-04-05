import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/mood_wheel.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';

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

  void _loadLogForDate(DateTime date, List<CycleLogModel> logs) {
    // Reset to defaults first
    _flow = null;
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

    final log = logs.firstWhereOrNull((l) {
      // Comparison: We want to match the CALENDAR DAY.
      // Since our backend stores logs at 00:00:00 UTC for the target day,
      // we check if the UTC year/month/day components match the device's selected year/month/day.
      final logUtc = l.date.toUtc();
      return logUtc.year == date.year && logUtc.month == date.month && logUtc.day == date.day;
    });

    if (log != null) {
      _flow = log.flow;
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
    _selectableDates = List.generate(7, (i) => DateTime.now().subtract(Duration(days: i))).reversed.toList();
    
    // Initial load from Bloc state using current state
    final state = context.read<TrackerBloc>().state;
    state.maybeWhen(
      loaded: (_, __, logs, ____, ___) => _loadLogForDate(_selectedDate, logs),
      orElse: () {},
    );
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

  void _save() {
    setState(() {
      _isSaving = true;
      _showSuccessOverlay = true;
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
    };

    context.read<TrackerBloc>().add(TrackerEvent.logDaily(data));
    
    // Check if we should pop or wait for milestone navigation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        final state = context.read<TrackerBloc>().state;
        bool hasMilestone = false;
        state.maybeWhen(
          loaded: (_, __, ___, ____, milestone) {
            debugPrint('[DailyLog] Save check. Milestone: $milestone');
            hasMilestone = (milestone == 'first_period');
          },
          orElse: () => debugPrint('[DailyLog] Save check. State is not loaded.'),
        );
        
        if (!hasMilestone) {
          debugPrint('[DailyLog] No milestone detected, popping screen.');
          Navigator.pop(context);
        } else {
          debugPrint('[DailyLog] Milestone detected, NOT popping. Letting listener handle it.');
        }
      }
    });
  }

  Widget _buildPeriodStartedToggle(bool isWw) {
    if (!isWw) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.pink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.pink.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Text('🌸', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Text('My period has started!', 
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.pink, fontSize: 16),
                ),
              ),
              Switch(
                value: _flow != null && _flow != 'none',
                activeColor: AppColors.pink,
                onChanged: (val) {
                  if (val && isWw) {
                    // Immediate navigation to milestone screen for First Period entry
                    debugPrint('[DailyLog] First period toggle enabled. Navigating to milestone...');
                    context.go('/tracker/milestone/first-period');
                    return;
                  }
                  setState(() {
                    if (val) {
                      _flow = 'light'; // Default to light when switched
                    } else {
                      _flow = 'none';
                    }
                  });
                },
              ),
            ],
          ),
        ).animate().fadeIn(delay: 50.ms),
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
            loaded: (profile, _, logs, ____, milestone) {
              // We only update if we are not currently saving to avoid jumpy UI
              if (!_isSaving) {
                setState(() => _loadLogForDate(_selectedDate, logs));
              }
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          bool isWw = false;
          state.maybeWhen(
            loaded: (profile, _, _, ____, ___) {
              if (profile.trackerMode == 'watching_waiting') {
                isWw = true;
              }
            },
            orElse: () {},
          );

          // If WW mode and period has started, we show everything else
          bool hideMenses = isWw && (_flow == null || _flow == 'none');

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildDateSelector(),
                  _buildHeading(),
                  _buildPeriodStartedToggle(isWw),
                  if (!hideMenses) _buildFlowSection(),
                  if (!hideMenses) _buildSymptomsSection(),
                  _buildMoodSection(),
                  _buildAdvancedToggle(),
                  if (_showAdvanced) ...[
                    _buildEnergySection(),
                    _buildSleepSection(),
                    _buildNoteSection(),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
              if (!_showSuccessOverlay) _buildSaveButton(),
              if (_showSuccessOverlay) _buildSuccessOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeading() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How are you today?', style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.textDark)),
            Text('Your body has its own language. Let\'s record it 💜', style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 14)),
          ],
        ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withOpacity(0.9),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌸', style: TextStyle(fontSize: 80)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              '+30 Points Logged!',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.purple),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            Text(
              'Gigi is so proud of you! ✨',
              style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 16),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowSection() {
    final flowOptions = ['None', 'Spotting', 'Light', 'Medium', 'Heavy', 'Ended', 'Clotting'];
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text('🩸 Period Flow', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: flowOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final option = flowOptions[index];
                  final isSelected = _flow == option.toLowerCase();
                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _flow = val ? option.toLowerCase() : null),
                    selectedColor: AppColors.pink,
                    labelStyle: GoogleFonts.nunito(
                      color: isSelected ? Colors.white : AppColors.textMedium,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: StadiumBorder(side: BorderSide(color: isSelected ? AppColors.pink : Colors.grey[200]!)),
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildSymptomsSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('😣 How does your body feel?', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark)),
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
                          color: _symptoms.isEmpty ? AppColors.purple.withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _symptoms.isEmpty ? AppColors.purple : Colors.grey[200]!, width: 2),
                        ),
                        child: const Center(child: Text('🌈', style: TextStyle(fontSize: 28))),
                      ),
                      const SizedBox(height: 4),
                      Text('None', style: GoogleFonts.nunito(fontSize: 10, color: _symptoms.isEmpty ? AppColors.purple : AppColors.textMedium, fontWeight: _symptoms.isEmpty ? FontWeight.w800 : FontWeight.w600)),
                    ],
                  ),
                ),
                ..._symptomList.map((symptom) {
                  final isSelected = _symptoms.contains(symptom['id']);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) _symptoms.remove(symptom['id']);
                      else _symptoms.add(symptom['id']!);
                    }),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.purple.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? AppColors.purple : Colors.grey[200]!, width: 2),
                          ),
                          child: Center(child: Text(symptom['emoji']!, style: const TextStyle(fontSize: 28))),
                        ),
                        const SizedBox(height: 4),
                        Text(symptom['name']!, style: GoogleFonts.nunito(fontSize: 10, color: isSelected ? AppColors.purple : AppColors.textMedium, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
                      ],
                    ),
                  );
                }),
              ],
            ),
            if (_symptoms.contains('cramps')) ...[
              const SizedBox(height: 20),
              Text('How intense are the cramps?', style: Theme.of(context).textTheme.bodyMedium),
              Slider(
                value: _crampIntensity.toDouble(),
                min: 1, max: 5, divisions: 4,
                label: _crampIntensity.toString(),
                activeColor: AppColors.purple,
                onChanged: (val) => setState(() => _crampIntensity = val.round()),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildMoodSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💜 Your emotional mood', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text('Tap the wheel to select how you feel.', style: Theme.of(context).textTheme.bodySmall),
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
            const SizedBox(height: 32),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text('⚡ Energy level', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(_getEnergyStatus(), style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppColors.purple, fontSize: 13)),
                const Spacer(),
                Text(_getEnergyEmoji(), style: const TextStyle(fontSize: 20)),
              ],
            ),
            Slider(
              value: _energy.toDouble(),
              min: 1, max: 5, divisions: 4,
              activeColor: AppColors.purple,
              inactiveColor: AppColors.purple.withOpacity(0.1),
              onChanged: (val) => setState(() => _energy = val.round()),
            ),
            const SizedBox(height: 32),
          ],
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }

  Widget _buildSleepSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('😴 Sleep duration', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(_getSleepStatus(), style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppColors.purple, fontSize: 13)),
                const Spacer(),
                Text('${_sleepDuration.toStringAsFixed(1)}h', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: AppColors.purple)),
              ],
            ),
            Slider(
              value: _sleepDuration,
              min: 2, max: 12, divisions: 20,
              activeColor: AppColors.purple,
              inactiveColor: AppColors.purple.withOpacity(0.1),
              onChanged: (val) => setState(() => _sleepDuration = val),
            ),
            const SizedBox(height: 32),
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
      ),
    );
  }

  Widget _buildNoteSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📝 Daily Note', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Anything else worth noting? (Only you can read this 🔒)',
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 32),
            _buildNutritionSection(),
            const SizedBox(height: 32),
            _buildActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionSection() {
    final options = [
      {'id': 'healthy', 'name': 'Balanced', 'emoji': '🥗'},
      {'id': 'cravings', 'name': 'Cravings', 'emoji': '🍩'},
      {'id': 'light', 'name': 'Light', 'emoji': '🍎'},
      {'id': 'heavy', 'name': 'Heavy', 'emoji': '🍝'},
      {'id': 'fast_food', 'name': 'Fast Food', 'emoji': '🍔'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🍎 Nutrition', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final opt = options[index];
              final isSelected = _nutrition.contains(opt['id']);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) _nutrition.remove(opt['id']);
                  else _nutrition.add(opt['id']!);
                }),
                child: Column(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.purple.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? AppColors.purple : Colors.grey[200]!, width: 2),
                      ),
                      child: Center(child: Text(opt['emoji']!, style: const TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(height: 4),
                    Text(opt['name']!, style: TextStyle(fontSize: 10, color: isSelected ? AppColors.purple : AppColors.textMedium)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    final options = [
      {'id': 'yoga', 'name': 'Yoga', 'emoji': '🧘'},
      {'id': 'walking', 'name': 'Walking', 'emoji': '🚶'},
      {'id': 'gym', 'name': 'Gym', 'emoji': '🏋️'},
      {'id': 'running', 'name': 'Running', 'emoji': '🏃'},
      {'id': 'rest', 'name': 'Rest Day', 'emoji': '😴'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🏃 Activity', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final opt = options[index];
              final isSelected = _activity.contains(opt['id']);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) _activity.remove(opt['id']);
                  else _activity.add(opt['id']!);
                }),
                child: Column(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.purple.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? AppColors.purple : Colors.grey[200]!, width: 2),
                      ),
                      child: Center(child: Text(opt['emoji']!, style: const TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(height: 4),
                    Text(opt['name']!, style: TextStyle(fontSize: 10, color: isSelected ? AppColors.purple : AppColors.textMedium)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
    if (_sleepDuration < 5) return 'Restless/Short';
    if (_sleepDuration < 7) return 'Below Ideal';
    if (_sleepDuration < 9) return 'Optimal Rest ✨';
    return 'Long Rest';
  }

  Widget _buildSaveButton() {
    return Positioned(
      bottom: 40,
      left: 24, right: 24,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))],
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
                      loaded: (_, __, logs, ____, ___) => _loadLogForDate(_selectedDate, logs),
                      orElse: () {},
                    );
                  });
                },
                child: Container(
                  width: 56,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.purple : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppColors.purple : Colors.grey[200]!),
                    boxShadow: isSelected ? [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdays[date.weekday - 1][0],
                        style: GoogleFonts.nunito(
                          color: isSelected ? Colors.white70 : AppColors.textMedium,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: GoogleFonts.nunito(
                          color: isSelected ? Colors.white : AppColors.textDark,
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
