import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/journey_list_bloc.dart';
import 'package:go_router/go_router.dart';

class JourneyExplorerScreen extends StatefulWidget {
  const JourneyExplorerScreen({super.key});

  @override
  State<JourneyExplorerScreen> createState() => _JourneyExplorerScreenState();
}

class _JourneyExplorerScreenState extends State<JourneyExplorerScreen> {
  @override
  void initState() {
    super.initState();
    context.read<JourneyListBloc>().add(const JourneyListEvent.loadJourneys());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Journeys', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<JourneyListBloc, JourneyListState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(child: Text('Error: $message')),
            loaded: (journeys) {
              if (journeys.isEmpty) {
                return const Center(child: Text('No learning journeys available right now.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: journeys.length,
                itemBuilder: (context, index) {
                  final journey = journeys[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      onTap: () {
                        // Navigate to detail
                        context.push('/journey/${journey.id}');
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (journey.thumbnailUrl != null)
                            Image.network(
                              journey.thumbnailUrl!,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          else
                            _buildPlaceholder(),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  journey.title,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  journey.description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    Text('${journey.totalXP} XP', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    if (journey.category != null)
                                      Chip(label: Text(journey.category!, style: const TextStyle(fontSize: 12))),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 160,
      color: Colors.deepPurple.shade100,
      child: const Center(
        child: Icon(Icons.school, size: 48, color: Colors.deepPurple),
      ),
    );
  }
}
