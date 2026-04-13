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
            loaded: (journeys, userProgress) {
              if (journeys.isEmpty) {
                return const Center(child: Text('No learning journeys available right now.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: journeys.length,
                itemBuilder: (context, index) {
                  final journey = journeys[index];
                  
                  // Calculate progress for this journey
                  final journeyEpisodeIds = journey.episodes.map((e) => e.id).toSet();
                  final completedInJourney = userProgress
                      .where((p) => journeyEpisodeIds.contains(p.episodeId) && p.completed)
                      .length;
                  final totalInJourney = journey.episodes.length;
                  final isComplete = totalInJourney > 0 && completedInJourney == totalInJourney;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      onTap: () {
                        context.push('/journey/${journey.id}');
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Stack(
                            children: [
                              if (journey.thumbnailUrl != null)
                                Image.network(
                                  journey.thumbnailUrl!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                )
                              else
                                _buildPlaceholder(),
                              if (isComplete)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 16),
                                        SizedBox(width: 4),
                                        Text('Mastered', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
                                    const SizedBox(width: 16),
                                    if (totalInJourney > 0) ...[
                                      Icon(Icons.menu_book, color: Colors.deepPurple.shade300, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$completedInJourney / $totalInJourney Episodes',
                                        style: TextStyle(
                                          color: Colors.deepPurple.shade700,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    if (journey.category != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.deepPurple.shade100),
                                        ),
                                        child: Text(
                                          journey.category!,
                                          style: TextStyle(color: Colors.deepPurple.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
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
