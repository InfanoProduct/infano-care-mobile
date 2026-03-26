import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/journey_detail_bloc.dart';
import '../models/learning_models.dart';
import 'package:go_router/go_router.dart';

class JourneyDetailScreen extends StatefulWidget {
  final String journeyId;

  const JourneyDetailScreen({super.key, required this.journeyId});

  @override
  State<JourneyDetailScreen> createState() => _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends State<JourneyDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journey Details')),
      body: BlocBuilder<JourneyDetailBloc, JourneyDetailState>(
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
                  const Text('Available Episodes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  if (journey.episodes.isEmpty)
                    const Text('No content available for this journey yet.'),
                  ...journey.episodes.map((episode) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(episode.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(episode.description ?? '${episode.points} XP'),
                      trailing: const Icon(Icons.play_circle_fill, color: Colors.deepPurple, size: 40),
                      onTap: () {
                        // Navigate to Episode Player with the episode object
                        context.push('/journey/${journey.id}/episode/${episode.id}', extra: episode);
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
