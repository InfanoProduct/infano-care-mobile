import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/learning_models.dart';
import '../application/summary_player_bloc.dart';
import 'package:go_router/go_router.dart';

class SummaryPlayerScreen extends StatefulWidget {
  final Summary summary;

  const SummaryPlayerScreen({super.key, required this.summary});

  @override
  State<SummaryPlayerScreen> createState() => _SummaryPlayerScreenState();
}

class _SummaryPlayerScreenState extends State<SummaryPlayerScreen> {
  int _currentIndex = 0;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    if (widget.summary.content is List) {
      _items = widget.summary.content as List<dynamic>;
    }
  }

  void _nextItem() {
    if (_currentIndex < _items.length - 1) {
      // Record progress for current item
      _recordItemProgress();
      setState(() {
        _currentIndex++;
      });
    } else {
      _recordItemProgress();
      // Submit full summary
      context.read<SummaryPlayerBloc>().add(SummaryPlayerEvent.submitSummary(widget.summary.id));
    }
  }

  void _recordItemProgress() {
    if (_items.isEmpty) return;
    final item = _items[_currentIndex];
    context.read<SummaryPlayerBloc>().add(
      SummaryPlayerEvent.completeItem(
        item['id'] ?? 'item_$_currentIndex',
        {'completed': true},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SummaryPlayerBloc, SummaryPlayerState>(
      listener: (context, state) {
        state.maybeWhen(
          completed: () {
            // Show success dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: const Text('Summary Completed! 🎉'),
                content: Text('You earned ${widget.summary.points} XP!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      context.pop(); // dismiss dialog
                      context.pop(); // go back to journey detail
                    },
                    child: const Text('Awesome!'),
                  )
                ],
              )
            );
          },
          orElse: () {},
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.summary.title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: _items.isEmpty ? 1.0 : (_currentIndex + 1) / _items.length,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation(Colors.deepPurple),
            ),
          )
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildCurrentItem(),
              ),
              ElevatedButton(
                onPressed: _nextItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_currentIndex < _items.length - 1 ? 'Next' : 'Finish'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentItem() {
    if (_items.isEmpty) {
      return const Center(child: Text('No content found in this summary.'));
    }

    final item = _items[_currentIndex];
    final type = item['type'] as String? ?? 'unknown';
    final title = item['title'] as String? ?? '';
    final content = item['content'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 24),
          if (type == 'story_hook') ...[
            Text(
              content['text'] ?? '',
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
          ] else if (type == 'knowledge_check') ...[
            Text(
              'Question:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            if (content['questions'] != null && content['questions'].isNotEmpty)
              Text(
                content['questions'][0]['question'] ?? '',
                style: const TextStyle(fontSize: 20),
              ),
            const SizedBox(height: 24),
            // Mock options
            if (content['questions'] != null && content['questions'].isNotEmpty)
              ...List.generate(
                (content['questions'][0]['options'] as List).length,
                (i) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurple.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RadioListTile<int>(
                    value: i,
                    groupValue: -1, // Mock unselected
                    onChanged: (v) {},
                    title: Text(content['questions'][0]['options'][i]),
                  ),
                ),
              ),
          ] else if (type == 'learning_cards') ...[
            if (content['cards'] != null && content['cards'].isNotEmpty)
               ...List.generate(
                (content['cards'] as List).length,
                (i) => Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.deepPurple.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content['cards'][i]['title'] ?? '',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          content['cards'][i]['content'] ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  )
                )
               )
          ] else ...[
            Text('Unsupported content type: $type', style: const TextStyle(color: Colors.red)),
            Text(content.toString())
          ]
        ],
      ),
    );
  }
}
