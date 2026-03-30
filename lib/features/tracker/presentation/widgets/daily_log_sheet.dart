import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import 'package:infano_care_mobile/features/tracker/presentation/widgets/mood_wheel.dart';

class DailyLogSheet extends StatefulWidget {
  final DateTime date;
  const DailyLogSheet({super.key, required this.date});

  @override
  State<DailyLogSheet> createState() => _DailyLogSheetState();
}

class _DailyLogSheetState extends State<DailyLogSheet> {
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

  void _save() {
    setState(() => _isSaving = true);
    
    final data = {
      'date': widget.date.toIso8601String(),
      if (_flow != null) 'flow': _flow,
      'symptoms': _symptoms.toList(),
      if (_symptoms.contains('cramps')) 'crampIntensity': _crampIntensity,
      if (_selectedMood != null) 'mood': _selectedMood!.id,
      'energy': _energy,
      'sleepDuration': _sleepDuration,
      'sleepQuality': _sleepQuality,
      'nutrition': _nutrition,
      'activity': _activity,
      if (_noteController.text.isNotEmpty) 'noteText': _noteController.text,
    };

    context.read<TrackerBloc>().add(TrackerEvent.logDaily(data));
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildHeader(),
              _buildFlowSection(),
              _buildSymptomsSection(),
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
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How are you today?', style: Theme.of(context).textTheme.headlineMedium),
                  Text('Every log builds your cycle story 💜', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              if (_isSaving)
                const Icon(Icons.check_circle, color: AppColors.success, size: 28).animate().scale().fadeIn()
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFlowSection() {
    final flowOptions = ['None', 'Spotting', 'Light', 'Medium', 'Heavy', 'Ended'];
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🩸 Period Flow', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
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
                  selectedColor: AppColors.purple,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textMedium, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  shape: StadiumBorder(borderSide: BorderSide(color: isSelected ? AppColors.purple : Colors.grey[200]!)),
                  backgroundColor: Colors.white,
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSymptomsSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('😣 How does your body feel?', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _symptomList.map((symptom) {
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
                    Text(symptom['name']!, style: TextStyle(fontSize: 10, color: isSelected ? AppColors.purple : AppColors.textMedium, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              );
            }).toList(),
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
      ),
    );
  }

  Widget _buildMoodSection() {
    return SliverToBoxAdapter(
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
              child: MoodWheel(onMoodSelected: (mood) => setState(() => _selectedMood = mood)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAdvancedToggle() {
    return SliverToBoxAdapter(
      child: Center(
        child: TextButton.icon(
          onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
          icon: Icon(_showAdvanced ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
          label: Text(_showAdvanced ? 'Show less' : 'More health details (Energy, Sleep, Note)'),
          style: TextButton.styleFrom(foregroundColor: AppColors.purple),
        ),
      ),
    );
  }

  Widget _buildEnergySection() {
    final energyIcons = ['🥱', '😑', '🙂', '😊', '⚡'];
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('⚡ Energy level', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final isSelected = _energy == index + 1;
              return GestureDetector(
                onTap: () => setState(() => _energy = index + 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.purple : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: isSelected ? [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                  ),
                  child: Text(energyIcons[index], style: const TextStyle(fontSize: 24)),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSleepSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('😴 Sleep duration', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _sleepDuration,
                  min: 2, max: 12, divisions: 20,
                  activeColor: AppColors.purple,
                  onChanged: (val) => setState(() => _sleepDuration = val),
                ),
              ),
              Text('${_sleepDuration.toStringAsFixed(1)}h', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purple)),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNoteSection() {
    return SliverToBoxAdapter(
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
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Positioned(
      bottom: 40,
      left: 0, right: 0,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        child: _isSaving 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('Save My Log 🌸'),
      ),
    );
  }
}
