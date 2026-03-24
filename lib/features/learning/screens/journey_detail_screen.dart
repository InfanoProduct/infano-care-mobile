import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/summary_player_bloc.dart';
import 'package:go_router/go_router.dart';

class JourneyDetailScreen extends StatefulWidget {
  final String journeyId;

  const JourneyDetailScreen({super.key, required this.journeyId});

  @override
  State<JourneyDetailScreen> createState() => _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends State<JourneyDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SummaryPlayerBloc>().add(SummaryPlayerEvent.loadSummary(widget.journeyId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journey Details')),
      body: BlocBuilder<SummaryPlayerBloc, SummaryPlayerState>(
        builder: (context, state) {
          return state.maybeWhen(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (msg) => Center(child: Text('Error: $msg')),
            loaded: (journey) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(journey.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(journey.description),
                  const SizedBox(height: 24),
                  const Text('Available Summaries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  if (journey.summaries.isEmpty)
                    const Text('No content available for this journey yet.'),
                  ...journey.summaries.map((summary) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(summary.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(summary.description ?? '${summary.points} XP'),
                      trailing: const Icon(Icons.play_circle_fill, color: Colors.deepPurple, size: 32),
                      onTap: () {
                        // Navigate to Summary Player
                        context.push('/journey/${journey.id}/summary/${summary.id}', extra: summary);
                      },
                    ),
                  )),
                ],
              );
            },
            orElse: () => const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
