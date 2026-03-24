import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/learning_models.dart';
import '../application/episode_player_bloc.dart';
import 'package:go_router/go_router.dart';

class EpisodePlayerScreen extends StatefulWidget {
  final Episode episode;

  const EpisodePlayerScreen({super.key, required this.episode});

  @override
  State<EpisodePlayerScreen> createState() => _EpisodePlayerScreenState();
}

class _EpisodePlayerScreenState extends State<EpisodePlayerScreen> {
  int _currentSegmentIndex = 0; // 0: Hook, 1: Story, 2: Knowledge Check, 3: Reflection, 4: Summary
  
  // Knowledge Check State
  int _correctAnswers = 0;
  int _questionsAnswered = 0;

  // Reflection State
  String _reflectionMode = 'private'; // 'private' or 'community'
  final TextEditingController _reflectionController = TextEditingController();

  void _nextSegment() {
    if (_currentSegmentIndex < 4) {
      setState(() {
        _currentSegmentIndex++;
      });
    } else {
      _completeEpisode();
    }
  }

  void _completeEpisode() {
    context.read<EpisodePlayerBloc>().add(
      EpisodePlayerEvent.completeEpisode(
        episodeId: widget.episode.id,
        knowledgeCheckAccuracy: _correctAnswers,
        reflectionMode: _reflectionMode,
        reflectionContent: _reflectionController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EpisodePlayerBloc, EpisodePlayerState>(
      listener: (context, state) {
        state.maybeWhen(
          completed: (points) {
            _showCompletionDialog(points);
          },
          error: (msg) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          },
          orElse: () {},
        );
      },
      child: Scaffold(
        body: Stack(
          children: [
            _buildCurrentSegment(),
            _buildProgressHeader(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        children: List.generate(5, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= _currentSegmentIndex 
                    ? Colors.deepPurple 
                    : Colors.deepPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentSegment() {
    switch (_currentSegmentIndex) {
      case 0: return _buildHookSegment();
      case 1: return _buildStorySegment();
      case 2: return _buildKnowledgeCheckSegment();
      case 3: return _buildReflectionSegment();
      case 4: return _buildSummarySegment();
      default: return const SizedBox.shrink();
    }
  }

  // --- Segment 1: Hook ---
  Widget _buildHookSegment() {
    final hookData = widget.episode.content['hook'] ?? {};
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black, // Dark background for immersion
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Atmospheric Background (placeholder for illustration)
          const Positioned.fill(
            child: Center(child: Icon(Icons.image, size: 100, color: Colors.white24)),
          ),
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(
              hookData['text'] ?? 'Get ready for a new journey...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            bottom: 60,
            child: TextButton(
              onPressed: _nextSegment,
              child: const Text('Tap to Start', style: TextStyle(color: Colors.white70)),
            ),
          ),
          // Skip Intro chip (appears after 10s in real app)
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            right: 16,
            child: ActionChip(
              label: const Text('Skip Intro'),
              onPressed: _nextSegment,
            ),
          ),
        ],
      ),
    );
  }

  // --- Segment 2: Story ---
  Widget _buildStorySegment() {
    final storyData = widget.episode.content['story'] ?? {};
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(storyData['title'] ?? 'The Story', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                storyData['text'] ?? 'Once upon a time...',
                style: const TextStyle(fontSize: 18, height: 1.6),
              ),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: _nextSegment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text('Continue', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  // --- Segment 3: Knowledge Check ---
  Widget _buildKnowledgeCheckSegment() {
     return Container(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(
        children: [
          const Text('Knowledge Check', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Retrieval practice: Think back to the story!'),
          const Spacer(),
          // Mock Question
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('What was the main lesson Meera learned?', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 24),
          ...['Option A', 'Option B', 'Option C'].map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              tileColor: Colors.deepPurple.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(opt),
              onTap: () {
                setState(() {
                  _questionsAnswered++;
                  _correctAnswers++; // Mocking success
                });
                if (_questionsAnswered >= 3) _nextSegment();
              },
            ),
          )),
          const Spacer(),
        ],
      ),
    );
  }

  // --- Segment 4: Reflection ---
  Widget _buildReflectionSegment() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(
        children: [
          const Text('Reflection', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('How did this make you feel?', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Private Journal'),
                  selected: _reflectionMode == 'private',
                  onSelected: (s) => setState(() => _reflectionMode = 'private'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Community'),
                  selected: _reflectionMode == 'community',
                  onSelected: (s) => setState(() => _reflectionMode = 'community'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reflectionController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Share your thoughts...',
              border: OutlineInputBorder(),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _nextSegment,
            child: const Text('Submit Reflection'),
          )
        ],
      ),
    );
  }

  // --- Segment 5: Summary ---
  Widget _buildSummarySegment() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, size: 100, color: Colors.amber),
          const SizedBox(height: 24),
          const Text('Episode Complete!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('You earned an Accuracy Bonus!', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _completeEpisode,
            child: const Text('Finish and Collect Rewards'),
          )
        ],
      ),
    );
  }

  void _showCompletionDialog(int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Amazing Work! 🌸'),
        content: const Text('Your journey continues. Check your profile for new rewards!'),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // dismiss
              context.pop(); // back to list
            },
            child: const Text('Done'),
          )
        ],
      ),
    );
  }
}
